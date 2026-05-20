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

        List<RateTemplate> templates = new ArrayList<>();
        for (UUID templateId : templateIds) {
            RateTemplate template = templateRepository.findById(templateId)
                    .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

            // State machine = egyetlen igazságforrás (VV-ELVI v2 5.2): publikálás DRAFT vagy APPROVED→PUBLISHED.
            // A status oszlop nullable (DEFAULT 'DRAFT'), ezért NULL-t is kezelünk (nem publikálható).
            RateTemplate.RateTemplateStatus currentStatus = template.getStatus();
            if (currentStatus == null || !currentStatus.canTransitionTo(RateTemplate.RateTemplateStatus.PUBLISHED)) {
                throw new ValidationException("Csak DRAFT vagy APPROVED sablon publikálható: " + templateId
                        + " (jelenlegi állapot: " + currentStatus + ")");
            }

            template.setStatus(RateTemplate.RateTemplateStatus.PUBLISHED);
            template.setPublishedAt(LocalDateTime.now());
            templateRepository.save(template);
            templates.add(template);
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
}
