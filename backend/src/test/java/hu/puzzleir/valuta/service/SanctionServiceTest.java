package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionMatch;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.SanctionEntry;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.repository.SanctionScreeningLogRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SanctionScreeningService UNIT tesztek — Mockito.
 *
 * Szankciós szűrés: exact match, fuzzy match (Levenshtein), XML import.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class SanctionServiceTest {

    @InjectMocks
    private SanctionScreeningService service;

    @Mock
    private SanctionEntryRepository sanctionEntryRepository;

    @Mock
    private SanctionScreeningLogRepository screeningLogRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @Spy
    private FatfCountryRiskService fatfCountryRiskService = new FatfCountryRiskService();

    /**
     * Segéd: SanctionEntry létrehozása.
     */
    private SanctionEntry createEntry(String fullName, String aliases) {
        return SanctionEntry.builder()
                .id(UUID.randomUUID())
                .fullName(fullName)
                .aliases(aliases)
                .active(true)
                .listType("UN")
                .build();
    }

    // =====================================================================
    // Nincs találat → CLEAR
    // =====================================================================
    @Test
    @DisplayName("Szűrés: nincs találat → CLEAR kockázati szint")
    void testScreen_noMatch_pass() {
        // Arrange — üres lista, nincs egyezés
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(Collections.emptyList());
        when(sanctionEntryRepository.findByDocumentNumber(any())).thenReturn(Collections.emptyList());

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "Kiss János", "123456AB", null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert
        assertThat(result.isMatched()).isFalse();
        assertThat(result.getMatches()).isEmpty();
        assertThat(result.getRiskLevel()).isEqualTo("CLEAR");
    }

    // =====================================================================
    // Exact match → CONFIRMED
    // =====================================================================
    @Test
    @DisplayName("Szűrés: pontos egyezés → CONFIRMED kockázati szint")
    void testScreen_exactMatch_fail() {
        // Arrange — pontosan ugyanaz a név a szankciós listán
        SanctionEntry entry = createEntry("John Smith", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "John Smith", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — EXACT match → CONFIRMED
        assertThat(result.isMatched()).isTrue();
        assertThat(result.getRiskLevel()).isEqualTo("CONFIRMED");
        assertThat(result.getMatches()).isNotEmpty();
        assertThat(result.getMatches().get(0).getMatchType()).isEqualTo("EXACT");
        assertThat(result.getMatches().get(0).getScore()).isEqualTo(1.0);
    }

    // =====================================================================
    // Fuzzy match: Levenshtein ≤ 2 → POSSIBLE
    // =====================================================================
    @Test
    @DisplayName("Szűrés: fuzzy match (Levenshtein ≤ 2) → POSSIBLE kockázati szint")
    void testScreen_fuzzyMatch_levenshtein2() {
        // Arrange — "Jon" vs "Jan" (Levenshtein = 1) → fuzzy match
        SanctionEntry entry = createEntry("Jon", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act — "Jan" vs "Jon" = Levenshtein 1
        SanctionScreeningResult result = service.screenCustomer(
                "Jan", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — fuzzy match → POSSIBLE
        assertThat(result.isMatched()).isTrue();
        assertThat(result.getRiskLevel()).isEqualTo("POSSIBLE");
        assertThat(result.getMatches()).isNotEmpty();
    }

    // =====================================================================
    // A5 / b8 FR-3: alias-score differenciálás
    // =====================================================================
    @Test
    @DisplayName("Alias: PONTOS alias-egyezés → ALIAS típus, 0.9 score (spec)")
    void testScreen_exactAliasMatch_score09() {
        // Arrange — a keresett név pontosan egy aliasszal egyezik
        SanctionEntry entry = createEntry("Osama bin Laden", "[\"Abu Abdallah\"]");
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "Abu Abdallah", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — pontos alias-egyezés → ALIAS, 0.9
        assertThat(result.isMatched()).isTrue();
        var aliasMatch = result.getMatches().stream()
                .filter(m -> "ALIAS".equals(m.getMatchType())).findFirst().orElseThrow();
        assertThat(aliasMatch.getScore()).isEqualTo(0.9);
    }

    @Test
    @DisplayName("Alias: FUZZY (elgépelt) alias-találat → PARTIAL típus (távolság-alapú), NEM flat ALIAS/0.9")
    void testScreen_fuzzyAliasMatch_notExactAliasType() {
        // Arrange — alias "Abu Abdallah", keresett "Abu Abdallat" (Levenshtein = 1, NEM pontos egyezés)
        SanctionEntry entry = createEntry("Osama bin Laden", "[\"Abu Abdallah\"]");
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "Abu Abdallat", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — a blokkolás megmarad (matched), de a fuzzy alias NEM kap "ALIAS" típust:
        // a 0.9/"ALIAS" a PONTOS alias-egyezésé, a fuzzy a fő-ággal megegyezően "PARTIAL".
        assertThat(result.isMatched()).isTrue();
        assertThat(result.getMatches()).isNotEmpty();
        assertThat(result.getMatches()).noneSatisfy(m ->
                assertThat(m.getMatchType()).isEqualTo("ALIAS"));
        assertThat(result.getMatches()).anySatisfy(m ->
                assertThat(m.getMatchType()).isEqualTo("PARTIAL"));
    }

    @Test
    @DisplayName("Alias: pontos alias-egyezés overlap-esetben (a fullName is tartalmazza) → ALIAS/0.9, NEM PARTIAL/0.8")
    void testScreen_exactAliasOverlapsFullName_prefersAlias() {
        // Arrange — a fullName tartalmazza az aliast; a keresett név PONTOSAN az alias (P3 overlap-eset)
        SanctionEntry entry = createEntry("Abu Abdallah al-Muhajir", "[\"Abu Abdallah\"]");
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "Abu Abdallah", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — a pontos alias-egyezés (ALIAS/0.9) elsőbbséget élvez a részleges teljes-név (PARTIAL/0.8) felett
        assertThat(result.isMatched()).isTrue();
        var match = result.getMatches().get(0);
        assertThat(match.getMatchType()).isEqualTo("ALIAS");
        assertThat(match.getScore()).isEqualTo(0.9);
    }

    // =====================================================================
    // XML import: sikeres
    // =====================================================================
    @Test
    @DisplayName("XML import: ENSZ szankciós lista feldolgozás")
    void testImportXml_success() {
        // Arrange — minimális UN XML formátum
        String xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <CONSOLIDATED_LIST>
                    <INDIVIDUAL>
                        <FIRST_NAME>Ahmed</FIRST_NAME>
                        <SECOND_NAME>Ali</SECOND_NAME>
                        <THIRD_NAME/>
                        <DATE_OF_BIRTH>1970-01-01</DATE_OF_BIRTH>
                        <NATIONALITY>SY</NATIONALITY>
                        <REFERENCE_NUMBER>QDi.001</REFERENCE_NUMBER>
                        <INDIVIDUAL_ALIAS>
                            <ALIAS_NAME>Abu Ahmed</ALIAS_NAME>
                        </INDIVIDUAL_ALIAS>
                    </INDIVIDUAL>
                    <INDIVIDUAL>
                        <FIRST_NAME>Fatima</FIRST_NAME>
                        <SECOND_NAME>Hassan</SECOND_NAME>
                        <THIRD_NAME/>
                        <DATE_OF_BIRTH/>
                        <NATIONALITY/>
                        <REFERENCE_NUMBER>QDi.002</REFERENCE_NUMBER>
                    </INDIVIDUAL>
                </CONSOLIDATED_LIST>
                """;

        InputStream xmlStream = new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // Act
        int importedCount = service.importSanctionList(xmlStream);

        // Assert — 2 bejegyzés importálva
        assertThat(importedCount).isEqualTo(2);
        verify(sanctionEntryRepository, times(2)).save(any(SanctionEntry.class));
    }

    // ── EU FSF v1.1 XML import tesztek ──

    @Test
    @DisplayName("importEuSanctionList — happy path: 2 sanctionEntity importalva")
    void testImportEuSanctionList_happyPath() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-1234">
                    <nameAlias wholeName="Ivan Petrov" />
                    <nameAlias wholeName="Ivan P." />
                    <birthdate birthdate="1975-03-15" />
                  </sanctionEntity>
                  <sanctionEntity euReferenceNumber="EU-5678">
                    <nameAlias wholeName="Sergei Volkov" />
                    <birthdate year="1980" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(2);

        ArgumentCaptor<SanctionEntry> captor = ArgumentCaptor.forClass(SanctionEntry.class);
        verify(sanctionEntryRepository, times(2)).save(captor.capture());

        SanctionEntry first = captor.getAllValues().get(0);
        assertThat(first.getFullName()).isEqualTo("Ivan Petrov");
        assertThat(first.getListType()).isEqualTo("EU");
        assertThat(first.getListReference()).isEqualTo("EU-1234");
        assertThat(first.getDateOfBirth()).isEqualTo("1975-03-15");
        assertThat(first.getAliases()).contains("Ivan P.");

        SanctionEntry second = captor.getAllValues().get(1);
        assertThat(second.getFullName()).isEqualTo("Sergei Volkov");
        assertThat(second.getDateOfBirth()).isEqualTo("1980");
    }

    @Test
    @DisplayName("importEuSanctionList — blank name entity kihagyva")
    void testImportEuSanctionList_blankNameSkipped() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-0001">
                    <nameAlias wholeName="" />
                  </sanctionEntity>
                  <sanctionEntity euReferenceNumber="EU-0002">
                    <nameAlias wholeName="Valid Name" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(1);
        verify(sanctionEntryRepository, times(1)).save(any(SanctionEntry.class));
    }

    @Test
    @DisplayName("importEuSanctionList — birthdate year fallback")
    void testImportEuSanctionList_yearFallback() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-9999">
                    <nameAlias wholeName="Test Person" />
                    <birthdate year="1965" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(1);
        ArgumentCaptor<SanctionEntry> captor = ArgumentCaptor.forClass(SanctionEntry.class);
        verify(sanctionEntryRepository).save(captor.capture());
        assertThat(captor.getValue().getDateOfBirth()).isEqualTo("1965");
    }

    // =====================================================================
    // NFD diakritika-normalizálás: "Milošević" (š,ć) == "Milosevic" (ASCII)
    // A régi kézzel sorolt lista nem tartalmazta š/ć/ž-t → false-negative volt.
    // =====================================================================
    @Test
    @DisplayName("Szűrés: NFD-normalizálás — diakritikus szankciós név egyezik ASCII-vel")
    void testScreen_diacriticNormalization_match() {
        SanctionEntry entry = createEntry("Slobodan Milošević", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        SanctionScreeningResult result = service.screenCustomer(
                "Slobodan Milosevic", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        assertThat(result.isMatched()).isTrue();
        assertThat(result.getMatches()).isNotEmpty();
        assertThat(result.getMatches().get(0).getMatchType()).isEqualTo("EXACT");
    }

    // =====================================================================
    // Üres-név false-positive guard: tisztán cirill/nem-latin név NEM
    // egyezhet minden bejegyzéssel (a régi contains("") MINDENRE igaz volt).
    // =====================================================================
    @Test
    @DisplayName("Szűrés: tisztán nem-latin (cirill) név → nincs false-positive találat")
    void testScreen_nonLatinName_noFalsePositive() {
        SanctionEntry entry = createEntry("John Smith", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        SanctionScreeningResult result = service.screenCustomer(
                "Иванов Иван", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        assertThat(result.isMatched()).isFalse();
        assertThat(result.getMatches()).isEmpty();
        assertThat(result.getRiskLevel()).isEqualTo("CLEAR");
    }

    // =====================================================================
    // ENTITY import: szankcionált szervezetek is bekerülnek az ENSZ listából.
    // =====================================================================
    @Test
    @DisplayName("XML import: ENSZ lista INDIVIDUAL + ENTITY (szervezet) együtt")
    void testImportXml_entityImported() {
        String xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <CONSOLIDATED_LIST>
                    <INDIVIDUALS>
                        <INDIVIDUAL>
                            <FIRST_NAME>Ahmed</FIRST_NAME>
                            <SECOND_NAME>Ali</SECOND_NAME>
                            <REFERENCE_NUMBER>QDi.001</REFERENCE_NUMBER>
                        </INDIVIDUAL>
                    </INDIVIDUALS>
                    <ENTITIES>
                        <ENTITY>
                            <FIRST_NAME>Al-Qaida Network</FIRST_NAME>
                            <REFERENCE_NUMBER>QDe.001</REFERENCE_NUMBER>
                            <ENTITY_ALIAS>
                                <ALIAS_NAME>AQ Network</ALIAS_NAME>
                            </ENTITY_ALIAS>
                        </ENTITY>
                    </ENTITIES>
                </CONSOLIDATED_LIST>
                """;

        InputStream xmlStream = new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8));
        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int importedCount = service.importSanctionList(xmlStream);

        // 1 INDIVIDUAL + 1 ENTITY = 2
        assertThat(importedCount).isEqualTo(2);
        ArgumentCaptor<SanctionEntry> captor = ArgumentCaptor.forClass(SanctionEntry.class);
        verify(sanctionEntryRepository, times(2)).save(captor.capture());
        assertThat(captor.getAllValues())
                .anyMatch(e -> "Al-Qaida Network".equals(e.getFullName()));
    }

    // =====================================================================
    // G4: FATF ország-kockázat integráció a szűrésbe
    // =====================================================================
    @Test
    @DisplayName("G4: FATF ország-kockázat — Észak-Korea állampolgár → fatfTier TIER_1A")
    void testScreen_fatfCountryHighRisk() {
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(Collections.emptyList());
        when(sanctionEntryRepository.findByDocumentNumber(any())).thenReturn(Collections.emptyList());

        SanctionScreeningResult result = service.screenCustomer(
                "Kim Test", null, null, "Észak-Korea",
                "W001", "Teszt Pénztáros", "BP01");

        assertThat(result.getFatfTier()).isEqualTo("TIER_1A_COUNTERMEASURE");
        assertThat(result.getFatfRiskCountry()).isEqualTo("Észak-Korea");
    }

    @Test
    @DisplayName("G4: nem-listás ország → fatfTier NONE, nincs risk-country")
    void testScreen_fatfCountryNone() {
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(Collections.emptyList());
        when(sanctionEntryRepository.findByDocumentNumber(any())).thenReturn(Collections.emptyList());

        SanctionScreeningResult result = service.screenCustomer(
                "Kiss János", null, null, "Magyarország",
                "W001", "Teszt Pénztáros", "BP01");

        assertThat(result.getFatfTier()).isEqualTo("NONE");
        assertThat(result.getFatfRiskCountry()).isNull();
    }
}
