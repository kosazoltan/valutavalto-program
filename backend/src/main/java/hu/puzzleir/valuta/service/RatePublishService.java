package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.RatePublication;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.entity.SyncOutboxEvent;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.RatePublicationRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.repository.SyncOutboxRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RatePublishService {

    private final RateTemplateRepository templateRepository;
    private final RateWorkgroupRepository workgroupRepository;
    private final RatePublicationRepository publicationRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final SyncOutboxRepository syncOutboxRepository;
    private final ObjectMapper objectMapper;

    /**
     * Publish approved rate templates for a workgroup.
     */
    @Transactional(rollbackFor = Exception.class)
    public RatePublication publish(UUID workgroupId, List<UUID> templateIds, String notes) {
        return publish(workgroupId, templateIds, notes, null);
    }

    /**
     * Publish approved rate templates for a workgroup with external client audit metadata.
     */
    @Transactional(rollbackFor = Exception.class)
    public RatePublication publish(UUID workgroupId,
                                   List<UUID> templateIds,
                                   String notes,
                                   PublicationMetadata metadata) {
        RateWorkgroup workgroup = workgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        if (workgroup.getBranches() == null || workgroup.getBranches().isEmpty()) {
            throw new ValidationException(
                    "A munkacsoporthoz nincs aktív iroda rendelve, ezért az árfolyam nem küldhető ki.");
        }

        // 1) Beolvasás + status-check (mutáció nélkül) — hogy a teljes batch validálható legyen
        //    MIELŐTT bármit módosítunk (PUBLISHED-re állítás csak az FK-04/E.2 protection-check után).
        // Codex #899 P2: a templateId-kat DEDUPÁLJUK — különben a "beolvas-mind-aztán-mutál"
        // átszervezés miatt egy duplikált id kétszer kerülne a listába és kétszer publikálódna
        // (duplikált exchange_rate + outbox). A régi (loop-on-belüli mutáció) ezt a status-check-en
        // bukta el; a sorrend-csere után explicit distinct kell.
        List<UUID> uniqueTemplateIds = templateIds.stream().distinct().collect(Collectors.toList());
        List<RateTemplate> templates = new ArrayList<>();
        for (UUID templateId : uniqueTemplateIds) {
            RateTemplate template = templateRepository.findById(templateId)
                    .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

            // State machine = egyetlen igazságforrás (VV-ELVI v2 5.2): publikálás DRAFT vagy APPROVED→PUBLISHED.
            // A status oszlop nullable (DEFAULT 'DRAFT'), ezért NULL-t is kezelünk (nem publikálható).
            RateTemplate.RateTemplateStatus currentStatus = template.getStatus();
            if (currentStatus == null || !currentStatus.canTransitionTo(RateTemplate.RateTemplateStatus.PUBLISHED)) {
                throw new ValidationException("Csak DRAFT vagy APPROVED sablon publikálható: " + templateId
                        + " (jelenlegi állapot: " + currentStatus + ")");
            }
            templates.add(template);
        }

        // 2) FK-04/E.2 árfolyamvédelem — ha a workgroup védelme be van kapcsolva, ellenőrzés
        //    MIELŐTT bármilyen sablon-mutáció történne. A magyar hibaüzenet egzakt formátum:
        //    "X-es csoport EUR vétel nem lehet magasabb az elszámolónál".
        validateRateProtection(workgroup, templates);

        // 3) Status-set + save (csak miután a teljes batch átment a validáción)
        LocalDateTime publishedAt = LocalDateTime.now();
        for (RateTemplate template : templates) {
            template.setStatus(RateTemplate.RateTemplateStatus.PUBLISHED);
            template.setPublishedAt(publishedAt);
            templateRepository.save(template);
        }

        // Create publication record
        int affectedBranches = workgroup.getBranches().size();
        RatePublication publication = RatePublication.builder()
                .companyId(SecurityUtils.getCurrentCompanyId())
                .workgroupId(workgroupId)
                .publishedBy(SecurityUtils.getCurrentWorkerId())
                .affectedBranches(affectedBranches)
                .notes(notes)
                .build();
        applyPublicationMetadata(publication, metadata);

        if (!templateIds.isEmpty()) {
            publication.setTemplateId(templateIds.get(0));
        }

        int publishedRateCount = applyTemplatesToExchangeRates(workgroup, templates);
        publication = publicationRepository.save(publication);

        // Outbox alapú terítés (idempotens, retry-képes kézbesítés).
        enqueueRateUpdateOutboxEvent(publication.getId(), workgroupId, workgroup.getBranches(), templates);

        log.info("Árfolyamok publikálva: workgroup={}, templates={}, branches={}, persistedRates={}",
                workgroup.getCode(), templates.size(), affectedBranches, publishedRateCount);

        return publication;
    }

    public record PublicationMetadata(
            String source,
            String clientPackageId,
            String clientPackageHash,
            String clientVersion,
            String clientDeviceId) {
    }

    private void applyPublicationMetadata(RatePublication publication, PublicationMetadata metadata) {
        if (metadata == null) {
            return;
        }

        publication.setSource(blankToDefault(metadata.source(), "LOCAL_RATE_MAKER"));
        publication.setClientPackageId(blankToNull(metadata.clientPackageId()));
        publication.setClientPackageHash(blankToNull(metadata.clientPackageHash()));
        publication.setClientVersion(blankToNull(metadata.clientVersion()));
        publication.setClientDeviceId(blankToNull(metadata.clientDeviceId()));
    }

    private String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void enqueueRateUpdateOutboxEvent(UUID publicationId,
                                              UUID workgroupId,
                                              Set<Branch> branches,
                                              List<RateTemplate> templates) {
        RateUpdateMessage message = buildRateUpdateMessage(workgroupId, branches, templates);

        String payload;
        try {
            payload = objectMapper.writeValueAsString(message);
        } catch (JsonProcessingException e) {
            throw new ValidationException("Nem sikerült serializálni a RATE_PUBLISHED payloadot: " + e.getMessage());
        }

        SyncOutboxEvent outboxEvent = SyncOutboxEvent.builder()
                .aggregateType("RATE_PUBLICATION")
                .aggregateId(publicationId.toString())
                .eventType("RATE_PUBLISHED")
                .idempotencyKey(UUID.randomUUID().toString())
                .payload(payload)
                .status(SyncOutboxEvent.SyncOutboxStatus.PENDING)
                .build();

        syncOutboxRepository.save(outboxEvent);
    }

    private RateUpdateMessage buildRateUpdateMessage(UUID workgroupId,
                                                     Set<Branch> branches,
                                                     List<RateTemplate> templates) {
        Map<Long, Currency> currenciesById = resolveCurrencies(templates);
        List<RateUpdateMessage.RateEntry> entries = templates.stream()
                .map(t -> RateUpdateMessage.RateEntry.builder()
                        .currencyId(t.getCurrencyId())
                        .currencyCode(resolveCurrencyCode(currenciesById, t.getCurrencyId()))
                        .buyRate(t.getBaseBuyRate().add(t.getBuySpread()))
                        .sellRate(t.getBaseSellRate().add(t.getSellSpread()))
                        .roundingRule(t.getRoundingRule())
                        .officialRate(t.getOfficialRate())
                        .limit1Amount(t.getLimit1Amount())
                        .limit1BuyRate(t.getLimit1BuyRate())
                        .limit1SellRate(t.getLimit1SellRate())
                        .limit2Amount(t.getLimit2Amount())
                        .limit2BuyRate(t.getLimit2BuyRate())
                        .limit2SellRate(t.getLimit2SellRate())
                        .limit3Amount(t.getLimit3Amount())
                        .limit3BuyRate(t.getLimit3BuyRate())
                        .limit3SellRate(t.getLimit3SellRate())
                        .build())
                .filter(e -> e.getCurrencyCode() != null)
                .toList();

        List<String> branchCodes = branches == null
                ? List.of()
                : branches.stream()
                .map(Branch::getCode)
                .toList();

        RateUpdateMessage message = RateUpdateMessage.builder()
                .workgroupId(workgroupId)
                .branchCodes(branchCodes)
                .publishedAt(LocalDateTime.now())
                .rates(entries)
                .build();

        return message;
    }

    /**
     * A publikált sablonokat az éles exchange_rate törzsbe írja munkacsoportonként.
     */
    private int applyTemplatesToExchangeRates(RateWorkgroup workgroup, List<RateTemplate> templates) {
        if (workgroup.getBranches() == null || workgroup.getBranches().isEmpty() || templates.isEmpty()) {
            return 0;
        }

        Map<Long, Currency> currenciesById = resolveCurrencies(templates);
        // FK-04/E.2 #899-edge: a pre-pass validateRateProtection a NULL officialRate-ű template-eket
        // kihagyja, de a publish ezekre fallback-J-t rendel (resolveOfficialRate). A védelem ezért
        // megkerülhető lenne → a hurokban a RESOLVED (mentett) J ellen is ellenőrzünk, per-branch.
        boolean protectionOn = Boolean.TRUE.equals(workgroup.getProtectionEnabled());
        Integer protGroupNum = workgroup.getLegacyGroupNumber();
        String protGroupLabel = protGroupNum != null
                ? protGroupNum + "-es csoport"
                : "(" + workgroup.getCode() + ") csoport";
        LocalDate validDate = LocalDate.now();
        LocalTime validTime = LocalTime.now();
        int createdCount = 0;

        for (Branch branch : workgroup.getBranches()) {
            for (RateTemplate template : templates) {
                Currency currency = currenciesById.get(template.getCurrencyId());
                if (currency == null) {
                    log.warn("Publikálás átugorva: currency nem található sablonhoz, templateId={}, currencyId={}",
                            template.getId(), template.getCurrencyId());
                    continue;
                }

                List<ExchangeRate> currentRates = exchangeRateRepository.findCurrentRate(
                        branch.getCompany().getId(),
                        currency.getId(),
                        branch.getId());

                ExchangeRate latestRate = currentRates.isEmpty() ? null : currentRates.get(0);

                List<ExchangeRate> branchRates = exchangeRateRepository.findActiveBranchRates(
                        branch.getCompany().getId(),
                        currency.getId(),
                        branch.getId());
                for (ExchangeRate currentRate : branchRates) {
                    currentRate.setActive(false);
                    exchangeRateRepository.save(currentRate);
                }

                BigDecimal buyRate = mergeRate(template.getBaseBuyRate(), template.getBuySpread());
                BigDecimal sellRate = mergeRate(template.getBaseSellRate(), template.getSellSpread());

                ExchangeRate newRate = ExchangeRate.builder()
                        .company(branch.getCompany())
                        .branch(branch)
                        .currency(currency)
                        .validDate(validDate)
                        .validTime(validTime)
                        .baseBuyRate(buyRate)
                        .baseSellRate(sellRate)
                        .limit1Amount(template.getLimit1Amount())
                        .limit1BuyRate(template.getLimit1BuyRate())
                        .limit1SellRate(template.getLimit1SellRate())
                        .limit2Amount(template.getLimit2Amount())
                        .limit2BuyRate(template.getLimit2BuyRate())
                        .limit2SellRate(template.getLimit2SellRate())
                        .limit3Amount(template.getLimit3Amount())
                        .limit3BuyRate(template.getLimit3BuyRate())
                        .limit3SellRate(template.getLimit3SellRate())
                        .officialRate(template.getOfficialRate() != null
                                ? template.getOfficialRate()
                                : resolveOfficialRate(latestRate, buyRate, sellRate))
                        .active(true)
                        .createdBy(resolveCreatedBy())
                        .build();

                // FK-04/E.2 #899-edge: a fallback-J esetén (template.officialRate == null) a pre-pass
                // nem ellenőrzött; itt a VÉGLEGES resolved-J ellen tesszük, hogy a védelem ne legyen
                // megkerülhető. Sértésnél ValidationException → @Transactional(rollbackFor) atomi rollback,
                // így nincs részleges publikálás. (A nem-null J-t a pre-pass már fedte — itt skip.)
                if (protectionOn && template.getOfficialRate() == null) {
                    BigDecimal resolvedJ = newRate.getOfficialRate();
                    String protCode = currency.getCode();
                    checkBuyRate(buyRate, resolvedJ, protGroupLabel, protCode, "L vétel");
                    checkBuyRate(template.getLimit1BuyRate(), resolvedJ, protGroupLabel, protCode, "N vétel");
                    checkBuyRate(template.getLimit2BuyRate(), resolvedJ, protGroupLabel, protCode, "P vétel");
                    checkBuyRate(template.getLimit3BuyRate(), resolvedJ, protGroupLabel, protCode, "R vétel");
                    checkSellRate(sellRate, resolvedJ, protGroupLabel, protCode, "M eladás");
                    checkSellRate(template.getLimit1SellRate(), resolvedJ, protGroupLabel, protCode, "O eladás");
                    checkSellRate(template.getLimit2SellRate(), resolvedJ, protGroupLabel, protCode, "Q eladás");
                    checkSellRate(template.getLimit3SellRate(), resolvedJ, protGroupLabel, protCode, "S eladás");
                }

                exchangeRateRepository.save(newRate);
                createdCount++;
            }
        }

        return createdCount;
    }

    private Map<Long, Currency> resolveCurrencies(List<RateTemplate> templates) {
        List<Long> currencyIds = templates.stream()
                .map(RateTemplate::getCurrencyId)
                .distinct()
                .toList();

        return currencyRepository.findAllById(currencyIds).stream()
                .collect(Collectors.toMap(Currency::getId, c -> c, (a, b) -> a, LinkedHashMap::new));
    }

    private String resolveCurrencyCode(Map<Long, Currency> currenciesById, Long currencyId) {
        Currency currency = currenciesById.get(currencyId);
        return currency != null ? currency.getCode() : null;
    }

    private BigDecimal mergeRate(BigDecimal baseRate, BigDecimal spread) {
        BigDecimal safeSpread = spread != null ? spread : BigDecimal.ZERO;
        return baseRate.add(safeSpread).setScale(4, RoundingMode.HALF_UP);
    }

    private BigDecimal resolveOfficialRate(ExchangeRate latestRate, BigDecimal buyRate, BigDecimal sellRate) {
        if (latestRate != null && latestRate.getOfficialRate() != null) {
            return latestRate.getOfficialRate();
        }
        return buyRate.add(sellRate)
                .divide(new BigDecimal("2"), 4, RoundingMode.HALF_UP);
    }

    private String resolveCreatedBy() {
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        return workerCode != null && !workerCode.isBlank() ? workerCode : "RATE_PUBLISH";
    }

    /**
     * Get publication history.
     */
    @Transactional(readOnly = true)
    public List<RatePublication> getPublicationHistory(UUID workgroupId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (workgroupId != null) {
            return publicationRepository.findByCompanyIdAndWorkgroupIdOrderByPublishedAtDesc(companyId, workgroupId);
        }
        return publicationRepository.findTop20ByCompanyIdOrderByPublishedAtDesc(companyId);
    }

    /**
     * FK-04/E.2 árfolyamvédelem-validáció publish-time.
     *
     * <p>Ha a workgroup {@code protection_enabled} flag-je {@code TRUE} (csempe jobb felső
     * checkbox), a publikálás elutasít minden olyan rátát, amelyben:
     * <ul>
     *   <li><b>Vételi</b> oszlopok (L=baseBuyRate, N=limit1BuyRate, P=limit2BuyRate, R=limit3BuyRate)
     *       érték {@literal >} J (officialRate / elszámoló).</li>
     *   <li><b>Eladási</b> oszlopok (M=baseSellRate, O=limit1SellRate, Q=limit2SellRate, S=limit3SellRate)
     *       érték {@literal <} J.</li>
     * </ul>
     *
     * <p>A hibaüzenet pontos formátuma (Kasza Helga spec, FK-04 E pont):
     * <i>„X-es csoport EUR vétel nem lehet magasabb az elszámolónál"</i>.</p>
     *
     * <p>NULL J (officialRate hiányzik) → a védelem nem érvényesít az adott rátára (mert
     * a referencia ismeretlen); ezt külön kötelezőség-szabály kell hogy lefedje, ha kell.</p>
     */
    private void validateRateProtection(RateWorkgroup workgroup, List<RateTemplate> templates) {
        if (workgroup.getProtectionEnabled() == null || !workgroup.getProtectionEnabled()) {
            return;
        }
        Integer groupNum = workgroup.getLegacyGroupNumber();
        String groupLabel = groupNum != null ? groupNum + "-es csoport" : "(" + workgroup.getCode() + ") csoport";

        // Sourcery/Copilot P2: a valutakódokat EGY batch-lekérdezéssel töltjük be (NEM
        // template-enkénti findById → N+1). currencyId → kód térkép a hibaüzenetekhez.
        List<Long> currencyIds = templates.stream()
                .filter(t -> t.getOfficialRate() != null)
                .map(RateTemplate::getCurrencyId)
                .distinct()
                .toList();
        Map<Long, String> codeById = new LinkedHashMap<>();
        for (Currency c : currencyRepository.findAllById(currencyIds)) {
            codeById.put(c.getId(), c.getCode());
        }

        for (RateTemplate t : templates) {
            BigDecimal j = t.getOfficialRate();
            if (j == null) {
                continue; // nincs elszámoló → ezt a rátát itt nem ellenőrizzük (külön szabály tárgya)
            }
            String code = codeById.getOrDefault(t.getCurrencyId(), "ID=" + t.getCurrencyId());

            // Codex #899 P2: az ALAP vételi/eladási (L/M) PUBLIKÁLT értéke base+spread
            // (applyTemplatesToExchangeRates → mergeRate), ezért a védelmet az EFFEKTÍV
            // rátára kell futtatni, különben pozitív spread átcsúszhat a J-n. A kedvezmény-
            // sávok (N/O/P/Q/R/S) spread nélkül, közvetlenül publikálódnak → változatlanul.
            BigDecimal effBuy = addSpread(t.getBaseBuyRate(), t.getBuySpread());
            BigDecimal effSell = addSpread(t.getBaseSellRate(), t.getSellSpread());

            // Vételi (L, N, P, R) ≤ J
            checkBuyRate(effBuy, j, groupLabel, code, "L vétel");
            checkBuyRate(t.getLimit1BuyRate(), j, groupLabel, code, "N vétel");
            checkBuyRate(t.getLimit2BuyRate(), j, groupLabel, code, "P vétel");
            checkBuyRate(t.getLimit3BuyRate(), j, groupLabel, code, "R vétel");

            // Eladási (M, O, Q, S) ≥ J
            checkSellRate(effSell, j, groupLabel, code, "M eladás");
            checkSellRate(t.getLimit1SellRate(), j, groupLabel, code, "O eladás");
            checkSellRate(t.getLimit2SellRate(), j, groupLabel, code, "Q eladás");
            checkSellRate(t.getLimit3SellRate(), j, groupLabel, code, "S eladás");
        }
    }

    /**
     * Az alap-ráta effektív (publikált) értéke = base + spread, a publikálással AZONOS 4-tizedes
     * kerekítéssel (mergeRate setScale(4, HALF_UP)) — Codex #909 P2: különben egy sub-4-tizedes
     * eltérés (pl. 400.00004 vs J=400.0000) hibásan elutasítaná a védelmet, holott a publikált
     * (kerekített) érték 400.0000 = szabályos. base==null → null (a check skippel).
     */
    private BigDecimal addSpread(BigDecimal base, BigDecimal spread) {
        if (base == null) return null;
        return base.add(spread == null ? BigDecimal.ZERO : spread).setScale(4, RoundingMode.HALF_UP);
    }

    /**
     * FK-04/E.2: vételi {@literal >} J esetén ValidationException magyar üzenettel.
     * A 0/üres érték „nem beállított" (a frontend {@code workgroupProtection.isSet} ugyanígy
     * skippeli) — a kötelező-ráta külön szabály tárgya, nem a védelemé (signum-skip = parity).
     */
    private void checkBuyRate(BigDecimal buy, BigDecimal j, String groupLabel, String code, String label) {
        if (buy != null && buy.signum() != 0 && buy.compareTo(j) > 0) {
            throw new ValidationException(
                    groupLabel + " " + code + " " + label + " nem lehet magasabb az elszámolónál ("
                            + buy + " > " + j + ").");
        }
    }

    /** FK-04/E.2: eladási {@literal <} J esetén ValidationException magyar üzenettel (0/üres = nem beállított, skip). */
    private void checkSellRate(BigDecimal sell, BigDecimal j, String groupLabel, String code, String label) {
        if (sell != null && sell.signum() != 0 && sell.compareTo(j) < 0) {
            throw new ValidationException(
                    groupLabel + " " + code + " " + label + " nem lehet alacsonyabb az elszámolónál ("
                            + sell + " < " + j + ").");
        }
    }
}
