package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionMatch;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.SanctionEntry;
import hu.puzzleir.valuta.entity.SanctionScreeningLog;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.repository.SanctionScreeningLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import java.io.InputStream;
import java.time.LocalDate;
import java.util.*;

/**
 * Szankciós szűrés szolgáltatás — ENSZ/EU/OFAC listákkal.
 *
 * Jogszabályi kötelezettség: minden tranzakció előtt KÖTELEZŐ szűrni!
 *
 * Fuzzy matching: Levenshtein-távolság ≤2 VAGY contains → POSSIBLE.
 * Exact match → CONFIRMED.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class SanctionScreeningService {

    private static final int MAX_LEVENSHTEIN_DISTANCE = 2;
    private static final double EXACT_MATCH_SCORE = 1.0;
    private static final double PARTIAL_MATCH_SCORE = 0.7;
    private static final double ALIAS_MATCH_SCORE = 0.5;
    /** #4: e fölött a helyi szankciós lista elavultnak (degradált) minősül. */
    private static final int MAX_SANCTION_LIST_AGE_DAYS = 7;

    private final SanctionEntryRepository sanctionEntryRepository;
    private final SanctionScreeningLogRepository screeningLogRepository;
    private final ObjectMapper objectMapper;

    /**
     * Ügyfél szűrés — név + okmányszám + születési dátum alapján.
     */
    @Transactional(rollbackFor = Exception.class)
    public SanctionScreeningResult screenCustomer(
            String name,
            String documentNumber,
            String dateOfBirth,
            String workerId,
            String workerName,
            String branchCode
    ) {
        if (name == null || name.isBlank()) {
            return SanctionScreeningResult.builder()
                    .matched(false)
                    .matches(Collections.emptyList())
                    .riskLevel("CLEAR")
                    .build();
        }

        List<SanctionMatch> allMatches = new ArrayList<>();

        // 1. Név alapú szűrés
        List<SanctionMatch> nameMatches = screenName(name);
        allMatches.addAll(nameMatches);

        // 2. Okmányszám alapú szűrés
        if (documentNumber != null && !documentNumber.isBlank()) {
            List<SanctionEntry> docMatches = sanctionEntryRepository.findByDocumentNumber(documentNumber);
            for (SanctionEntry entry : docMatches) {
                boolean alreadyFound = allMatches.stream()
                        .anyMatch(m -> m.getEntryId().equals(entry.getId()));
                if (!alreadyFound) {
                    allMatches.add(toMatch(entry, "EXACT", EXACT_MATCH_SCORE));
                }
            }
        }

        // Kockázati szint meghatározása
        String riskLevel = determineRiskLevel(allMatches);
        boolean matched = !allMatches.isEmpty();

        // Audit naplózás — KÖTELEZŐ
        logScreening(name, documentNumber, dateOfBirth, riskLevel, allMatches, workerId, workerName, branchCode);

        log.info("[SanctionScreening] Szűrés: név='{}', okmány='{}', eredmény={}, találatok={}",
                name, documentNumber, riskLevel, allMatches.size());

        // #4 offline cache fallback: ha a helyi lista elavult/üres, a szűrés akkor is lefut
        // (cache-ből), de explicit jelezzük a degradált módot (a hívó/UI figyelmeztethet).
        // Az aktív bejegyzések számát EGYSZER kérdezzük le (nem dupla count-query) — Copilot #729.
        long activeCount = getActiveCount();
        Integer listAgeDays = computeSanctionListAgeDays();
        boolean stale = isSanctionListStale(listAgeDays, activeCount);
        if (stale) {
            log.warn("[SanctionScreening] DEGRADÁLT MÓD: a helyi szankciós lista elavult/üres "
                    + "(kor={} nap, aktív bejegyzés={}). A szűrés a cache-ből futott — frissítés szükséges!",
                    listAgeDays, activeCount);
        }

        return SanctionScreeningResult.builder()
                .matched(matched)
                .matches(allMatches)
                .riskLevel(riskLevel)
                .staleData(stale)
                .listAgeDays(listAgeDays)
                .build();
    }

    /**
     * Név alapú szűrés — fuzzy matching.
     */
    public List<SanctionMatch> screenName(String name) {
        if (name == null || name.isBlank()) {
            return Collections.emptyList();
        }

        String normalizedInput = normalizeName(name);
        // Üres normalizált input (pl. tisztán nem-latin írásrendszerű név) esetén tilos
        // szűrni: az üres-string contains() MINDEN bejegyzésre igaz lenne → false-positive
        // robbanás. Ilyenkor a név-alapú szűrés nem értelmezhető → üres találatlista.
        if (normalizedInput.isBlank()) {
            return Collections.emptyList();
        }
        List<SanctionEntry> activeEntries = sanctionEntryRepository.findByActiveTrue();
        List<SanctionMatch> matches = new ArrayList<>();

        for (SanctionEntry entry : activeEntries) {
            String normalizedEntry = normalizeName(entry.getFullName());

            // Csak nem-üres entry-nevet hasonlítunk (üres contains() false-positive véd).
            if (!normalizedEntry.isBlank()) {
                // Exact match
                if (normalizedInput.equals(normalizedEntry)) {
                    matches.add(toMatch(entry, "EXACT", EXACT_MATCH_SCORE));
                    continue;
                }

                // Contains match
                if (normalizedEntry.contains(normalizedInput) || normalizedInput.contains(normalizedEntry)) {
                    matches.add(toMatch(entry, "PARTIAL", PARTIAL_MATCH_SCORE));
                    continue;
                }

                // Levenshtein fuzzy match
                int distance = levenshteinDistance(normalizedInput, normalizedEntry);
                if (distance <= MAX_LEVENSHTEIN_DISTANCE) {
                    double score = 1.0 - ((double) distance / Math.max(normalizedInput.length(), normalizedEntry.length()));
                    matches.add(toMatch(entry, "PARTIAL", Math.max(score, 0.3)));
                    continue;
                }
            }

            // Alias match
            if (entry.getAliases() != null && !entry.getAliases().isBlank()) {
                try {
                    List<String> aliases = objectMapper.readValue(entry.getAliases(), new TypeReference<>() {});
                    for (String alias : aliases) {
                        String normalizedAlias = normalizeName(alias);
                        if (normalizedAlias.isBlank()) continue;
                        if (normalizedInput.equals(normalizedAlias) ||
                            normalizedAlias.contains(normalizedInput) ||
                            normalizedInput.contains(normalizedAlias) ||
                            levenshteinDistance(normalizedInput, normalizedAlias) <= MAX_LEVENSHTEIN_DISTANCE) {
                            matches.add(toMatch(entry, "ALIAS", ALIAS_MATCH_SCORE));
                            break;
                        }
                    }
                } catch (Exception e) {
                    log.warn("Alias JSON parse hiba: entryId={}, aliases='{}'", entry.getId(), entry.getAliases());
                }
            }
        }

        return matches;
    }

    /**
     * ENSZ XML szankciós lista importálása.
     * Formátum: UN Consolidated List XML (https://scsanctions.un.org/resources/xml/en/consolidated.xml)
     */
    @Transactional(rollbackFor = Exception.class)
    public int importSanctionList(InputStream xmlData) {
        int importedCount = 0;

        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            // XXE védelme
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(xmlData);
            doc.getDocumentElement().normalize();

            NodeList individuals = doc.getElementsByTagName("INDIVIDUAL");

            for (int i = 0; i < individuals.getLength(); i++) {
                Element individual = (Element) individuals.item(i);

                String firstName = getElementText(individual, "FIRST_NAME");
                String secondName = getElementText(individual, "SECOND_NAME");
                String thirdName = getElementText(individual, "THIRD_NAME");

                String fullName = buildFullName(firstName, secondName, thirdName);
                if (fullName.isBlank()) continue;

                String dateOfBirth = getElementText(individual, "DATE_OF_BIRTH");
                String nationality = getElementText(individual, "NATIONALITY");
                String reference = getElementText(individual, "REFERENCE_NUMBER");

                // Alias-ok gyűjtése
                List<String> aliases = new ArrayList<>();
                NodeList aliasNodes = individual.getElementsByTagName("INDIVIDUAL_ALIAS");
                for (int j = 0; j < aliasNodes.getLength(); j++) {
                    Element aliasEl = (Element) aliasNodes.item(j);
                    String aliasName = getElementText(aliasEl, "ALIAS_NAME");
                    if (!aliasName.isBlank()) aliases.add(aliasName);
                }

                String aliasesJson = aliases.isEmpty() ? null : objectMapper.writeValueAsString(aliases);

                SanctionEntry entry = SanctionEntry.builder()
                        .fullName(fullName)
                        .aliases(aliasesJson)
                        .dateOfBirth(dateOfBirth.isBlank() ? null : dateOfBirth)
                        .nationality(nationality.isBlank() ? null : nationality)
                        .listType("UN")
                        .listReference(reference.isBlank() ? null : reference)
                        .addedDate(LocalDate.now())
                        .lastUpdated(LocalDate.now())
                        .active(true)
                        .build();

                sanctionEntryRepository.save(entry);
                importedCount++;
            }

            // Szankcionált SZERVEZETEK (ENTITY) — a terror-szervezetek / cégek eddig kimaradtak.
            NodeList entities = doc.getElementsByTagName("ENTITY");
            for (int i = 0; i < entities.getLength(); i++) {
                Element entityEl = (Element) entities.item(i);

                String firstName = getElementText(entityEl, "FIRST_NAME");
                String secondName = getElementText(entityEl, "SECOND_NAME");
                String thirdName = getElementText(entityEl, "THIRD_NAME");

                String fullName = buildFullName(firstName, secondName, thirdName);
                if (fullName.isBlank()) continue;

                String reference = getElementText(entityEl, "REFERENCE_NUMBER");

                List<String> aliases = new ArrayList<>();
                NodeList aliasNodes = entityEl.getElementsByTagName("ENTITY_ALIAS");
                for (int j = 0; j < aliasNodes.getLength(); j++) {
                    Element aliasEl = (Element) aliasNodes.item(j);
                    String aliasName = getElementText(aliasEl, "ALIAS_NAME");
                    if (!aliasName.isBlank()) aliases.add(aliasName);
                }
                String aliasesJson = aliases.isEmpty() ? null : objectMapper.writeValueAsString(aliases);

                SanctionEntry entry = SanctionEntry.builder()
                        .fullName(fullName)
                        .aliases(aliasesJson)
                        .listType("UN")
                        .listReference(reference.isBlank() ? null : reference)
                        .addedDate(LocalDate.now())
                        .lastUpdated(LocalDate.now())
                        .active(true)
                        .build();

                sanctionEntryRepository.save(entry);
                importedCount++;
            }

            log.info("[SanctionImport] {} bejegyzés importálva az ENSZ listából", importedCount);

        } catch (Exception e) {
            log.error("[SanctionImport] XML import hiba: {}", e.getMessage(), e);
            throw new BusinessException("Szankciós lista import hiba: " + e.getMessage(), "SANCTION_IMPORT_FAILED");
        }

        return importedCount;
    }

    /**
     * EU Financial Sanctions XML (FSF v1.1) importalasa.
     * Formatum: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content
     * Schema: sanctionEntity → nameAlias/wholeName, identification, birthdate
     */
    @Transactional(rollbackFor = Exception.class)
    public int importEuSanctionList(InputStream xmlData) {
        int importedCount = 0;

        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(xmlData);
            doc.getDocumentElement().normalize();

            NodeList entities = doc.getElementsByTagName("sanctionEntity");

            for (int i = 0; i < entities.getLength(); i++) {
                Element entity = (Element) entities.item(i);
                String euRef = entity.getAttribute("euReferenceNumber");

                // Nev: nameAlias → wholeName
                String fullName = "";
                List<String> aliases = new ArrayList<>();
                NodeList nameAliases = entity.getElementsByTagName("nameAlias");
                for (int j = 0; j < nameAliases.getLength(); j++) {
                    Element na = (Element) nameAliases.item(j);
                    String wholeName = na.getAttribute("wholeName");
                    if (wholeName != null && !wholeName.isBlank()) {
                        if (fullName.isEmpty()) {
                            fullName = wholeName;
                        } else {
                            aliases.add(wholeName);
                        }
                    }
                }

                if (fullName.isBlank()) continue;

                // Szuletesi datum
                String dateOfBirth = "";
                NodeList birthDates = entity.getElementsByTagName("birthdate");
                if (birthDates.getLength() > 0) {
                    Element bd = (Element) birthDates.item(0);
                    dateOfBirth = bd.getAttribute("birthdate");
                    if (dateOfBirth == null || dateOfBirth.isBlank()) {
                        dateOfBirth = bd.getAttribute("year");
                    }
                }

                String aliasesJson = aliases.isEmpty() ? null : objectMapper.writeValueAsString(aliases);

                SanctionEntry entry = SanctionEntry.builder()
                        .fullName(fullName)
                        .aliases(aliasesJson)
                        .dateOfBirth(dateOfBirth != null && !dateOfBirth.isBlank() ? dateOfBirth : null)
                        .listType("EU")
                        .listReference(euRef != null && !euRef.isBlank() ? euRef : null)
                        .addedDate(LocalDate.now())
                        .lastUpdated(LocalDate.now())
                        .active(true)
                        .build();

                sanctionEntryRepository.save(entry);
                importedCount++;
            }

            log.info("[SanctionImport] {} bejegyzes importalva az EU listabol", importedCount);

        } catch (Exception e) {
            log.error("[SanctionImport] EU XML import hiba: {}", e.getMessage(), e);
            throw new BusinessException("EU szankcios lista import hiba: " + e.getMessage(), "EU_SANCTION_IMPORT_FAILED");
        }

        return importedCount;
    }

    /**
     * Utolsó frissítés dátuma.
     */
    public LocalDate getLastUpdateDate() {
        return sanctionEntryRepository.findLastUpdateDate().orElse(null);
    }

    /**
     * Aktív bejegyzések száma.
     */
    public long getActiveCount() {
        return sanctionEntryRepository.countByActiveTrue();
    }

    // ── Belső segédmetódusok ─────────────────────────────────────────────

    /** #4: a helyi szankciós lista kora napokban (null, ha még sosem importálták). */
    private Integer computeSanctionListAgeDays() {
        LocalDate last = getLastUpdateDate();
        if (last == null) return null;
        return (int) java.time.temporal.ChronoUnit.DAYS.between(last, LocalDate.now());
    }

    /**
     * #4: a helyi szankciós lista elavult/degradált-e — ha üres (sosem importált),
     * vagy a kora meghaladja a {@value #MAX_SANCTION_LIST_AGE_DAYS} napot.
     */
    private boolean isSanctionListStale(Integer ageDays, long activeCount) {
        if (activeCount == 0) return true;
        if (ageDays == null) return true;
        return ageDays > MAX_SANCTION_LIST_AGE_DAYS;
    }

    private String determineRiskLevel(List<SanctionMatch> matches) {
        if (matches.isEmpty()) return "CLEAR";

        boolean hasExact = matches.stream().anyMatch(m -> "EXACT".equals(m.getMatchType()));
        if (hasExact) return "CONFIRMED";

        return "POSSIBLE";
    }

    private SanctionMatch toMatch(SanctionEntry entry, String matchType, double score) {
        return SanctionMatch.builder()
                .entryId(entry.getId())
                .fullName(entry.getFullName())
                .aliases(entry.getAliases())
                .dateOfBirth(entry.getDateOfBirth())
                .nationality(entry.getNationality())
                .documentNumber(entry.getDocumentNumber())
                .listType(entry.getListType())
                .listReference(entry.getListReference())
                .matchType(matchType)
                .score(score)
                .build();
    }

    private void logScreening(
            String name, String documentNumber, String dateOfBirth,
            String riskLevel, List<SanctionMatch> matches,
            String workerId, String workerName, String branchCode
    ) {
        String matchDetailsJson = null;
        try {
            if (!matches.isEmpty()) {
                matchDetailsJson = objectMapper.writeValueAsString(matches);
            }
        } catch (Exception e) {
            log.warn("Match details JSON hiba: {}", e.getMessage());
        }

        SanctionScreeningLog logEntry = SanctionScreeningLog.builder()
                .screenedName(name)
                .screenedDocumentNumber(documentNumber)
                .screenedDateOfBirth(dateOfBirth)
                .result(riskLevel)
                .matchCount(matches.size())
                .matchDetails(matchDetailsJson)
                .workerId(workerId)
                .workerName(workerName)
                .branchCode(branchCode)
                .build();

        screeningLogRepository.save(logEntry);
    }

    /**
     * Név normalizálás: kisbetű, ékezet eltávolítás, felesleges szóközök.
     */
    private String normalizeName(String name) {
        if (name == null) return "";
        // Unicode NFD dekompozíció: minden latin diakritikus jel általánosan kezelt
        // (š, ž, č, ć, ā, ł részben stb.), nem kézzel sorolt halmaz — false-negative AML
        // találatok elkerülése (pl. "Milošević" → "milosevic").
        String decomposed = java.text.Normalizer.normalize(name, java.text.Normalizer.Form.NFD);
        return decomposed.toLowerCase(java.util.Locale.ROOT)  // determinisztikus (török I/İ ellen)
                .replaceAll("\\p{M}+", "")              // kombináló diakritikus jelek
                .replaceAll("[^\\p{L}\\p{Nd}\\s]", "")  // csak írásjel törlése; a nem-latin
                                                        // betűket MEGTARTJUK → azonos
                                                        // írásrendszerű (cirill/görög) egyezés
                                                        // is működik, nincs üres-string esés
                .replaceAll("\\s+", " ")
                .trim();
    }

    /**
     * Levenshtein-távolság két string között.
     */
    private int levenshteinDistance(String a, String b) {
        int lenA = a.length();
        int lenB = b.length();
        int[][] dp = new int[lenA + 1][lenB + 1];

        for (int i = 0; i <= lenA; i++) dp[i][0] = i;
        for (int j = 0; j <= lenB; j++) dp[0][j] = j;

        for (int i = 1; i <= lenA; i++) {
            for (int j = 1; j <= lenB; j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(
                        Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                        dp[i - 1][j - 1] + cost
                );
            }
        }

        return dp[lenA][lenB];
    }

    private String getElementText(Element parent, String tagName) {
        NodeList nodes = parent.getElementsByTagName(tagName);
        if (nodes.getLength() > 0 && nodes.item(0).getTextContent() != null) {
            return nodes.item(0).getTextContent().trim();
        }
        return "";
    }

    private String buildFullName(String... parts) {
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (part != null && !part.isBlank()) {
                if (sb.length() > 0) sb.append(' ');
                sb.append(part.trim());
            }
        }
        return sb.toString();
    }
}
