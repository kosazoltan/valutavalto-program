package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.ratehistory.RateHistoryDto;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RatePublishService {

    private final RateTemplateRepository templateRepository;
    private final RateWorkgroupRepository workgroupRepository;
    private final RatePublicationRepository publicationRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final RateHistoryService rateHistoryService;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Publish approved rate templates for a workgroup.
     *
     * Üzleti logika (régi Delphi rendszer alapján):
     * 1. Template APPROVED/DRAFT → PUBLISHED státuszra állítás
     * 2. Munkacsoport irodáinak meghatározása
     * 3. Minden iroda + valuta kombinációra ExchangeRate rekord létrehozása
     * 4. Árfolyam történet (RateHistory) rögzítése
     * 5. WebSocket broadcast a pénztáraknak
     */
    @Transactional
    public RatePublication publish(UUID workgroupId, List<UUID> templateIds, String notes) {
        RateWorkgroup workgroup = workgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        List<RateTemplate> templates = new ArrayList<>();
        for (UUID templateId : templateIds) {
            RateTemplate template = templateRepository.findById(templateId)
                    .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

            if (template.getStatus() != RateTemplate.RateTemplateStatus.APPROVED
                    && template.getStatus() != RateTemplate.RateTemplateStatus.DRAFT) {
                throw new ValidationException("Csak DRAFT vagy APPROVED sablon publikálható: " + templateId);
            }

            template.setStatus(RateTemplate.RateTemplateStatus.PUBLISHED);
            template.setPublishedAt(LocalDateTime.now());
            templateRepository.save(template);
            templates.add(template);
        }

        // Create ExchangeRate records for each branch in the workgroup
        Set<Branch> branches = workgroup.getBranches();
        int affectedBranches = branches != null ? branches.size() : 0;
        int ratesCreated = 0;

        if (branches != null && !branches.isEmpty()) {
            for (RateTemplate template : templates) {
                ratesCreated += createExchangeRatesFromTemplate(template, branches);
            }
        }

        // Create publication record
        RatePublication publication = RatePublication.builder()
                .workgroupId(workgroupId)
                .publishedBy(SecurityUtils.getCurrentWorkerId())
                .affectedBranches(affectedBranches)
                .notes(notes)
                .build();

        if (!templateIds.isEmpty()) {
            publication.setTemplateId(templateIds.get(0));
        }

        publication = publicationRepository.save(publication);

        // WebSocket broadcast
        broadcastRateUpdate(workgroupId, templates);

        log.info("Árfolyamok publikálva: workgroup={}, templates={}, branches={}, rates_created={}",
                workgroup.getCode(), templates.size(), affectedBranches, ratesCreated);

        return publication;
    }

    /**
     * Create ExchangeRate records from a published template for all branches in the workgroup.
     *
     * Legacy: arfolyamkarbantarto (arftmk DLL) — a főértéktáros által készített
     * árfolyamok kiküldése a pénztáraknak (irodáknak).
     */
    private int createExchangeRatesFromTemplate(RateTemplate template, Set<Branch> branches) {
        Currency currency = currencyRepository.findById(template.getCurrencyId())
                .orElse(null);
        if (currency == null) {
            log.warn("Valuta nem található template-hez: currencyId={}", template.getCurrencyId());
            return 0;
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található: " + companyId));

        BigDecimal buyRate = template.getBaseBuyRate().add(
                template.getBuySpread() != null ? template.getBuySpread() : BigDecimal.ZERO);
        BigDecimal sellRate = template.getBaseSellRate().add(
                template.getSellSpread() != null ? template.getSellSpread() : BigDecimal.ZERO);

        // Validate: sell rate must be greater than buy rate
        if (sellRate.compareTo(buyRate) <= 0) {
            throw new ValidationException(
                    "Eladási árfolyam (" + sellRate + ") nagyobb kell legyen a vételinél (" + buyRate + ") - "
                    + currency.getCode());
        }

        int created = 0;
        LocalDateTime now = LocalDateTime.now();
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();

        for (Branch branch : branches) {
            // Deactivate old rates for this branch + currency
            List<ExchangeRate> oldRates = exchangeRateRepository.findCurrentRate(
                    companyId, currency.getId(), branch.getId());
            for (ExchangeRate oldRate : oldRates) {
                oldRate.setActive(false);
                exchangeRateRepository.save(oldRate);
            }

            // Create new ExchangeRate record
            ExchangeRate newRate = ExchangeRate.builder()
                    .company(company)
                    .branch(branch)
                    .currency(currency)
                    .validDate(LocalDate.now())
                    .validTime(LocalTime.now())
                    .baseBuyRate(buyRate)
                    .baseSellRate(sellRate)
                    .officialRate(template.getBaseBuyRate()) // MNB/base rate as official
                    .active(true)
                    .createdBy(SecurityUtils.getCurrentWorkerCode())
                    .build();

            exchangeRateRepository.save(newRate);
            created++;

            // Record rate history
            RateHistoryDto historyDto = RateHistoryDto.builder()
                    .currencyCode(currency.getCode())
                    .buyRate(buyRate)
                    .sellRate(sellRate)
                    .mnbRate(template.getBaseBuyRate())
                    .effectiveFrom(now)
                    .setBy(currentWorkerId)
                    .branchId(branch.getId())
                    .companyId(companyId)
                    .build();

            rateHistoryService.recordRateChange(historyDto);
        }

        log.info("ExchangeRate rekordok létrehozva: currency={}, branches={}, count={}",
                currency.getCode(), branches.size(), created);

        return created;
    }

    /**
     * Broadcast rate update via WebSocket.
     */
    private void broadcastRateUpdate(UUID workgroupId, List<RateTemplate> templates) {
        List<RateUpdateMessage.RateEntry> entries = templates.stream()
                .map(t -> RateUpdateMessage.RateEntry.builder()
                        .currencyId(t.getCurrencyId())
                        .buyRate(t.getBaseBuyRate().add(
                                t.getBuySpread() != null ? t.getBuySpread() : BigDecimal.ZERO))
                        .sellRate(t.getBaseSellRate().add(
                                t.getSellSpread() != null ? t.getSellSpread() : BigDecimal.ZERO))
                        .roundingRule(t.getRoundingRule())
                        .build())
                .toList();

        RateUpdateMessage message = RateUpdateMessage.builder()
                .workgroupId(workgroupId)
                .publishedAt(LocalDateTime.now())
                .rates(entries)
                .build();

        try {
            messagingTemplate.convertAndSend("/topic/rate-updates/" + workgroupId, message);
            log.debug("WebSocket rate update küldve: workgroup={}", workgroupId);
        } catch (Exception e) {
            log.warn("WebSocket rate update sikertelen: {}", e.getMessage());
        }
    }

    /**
     * Get publication history.
     */
    @Transactional(readOnly = true)
    public List<RatePublication> getPublicationHistory(UUID workgroupId) {
        if (workgroupId != null) {
            return publicationRepository.findByWorkgroupIdOrderByPublishedAtDesc(workgroupId);
        }
        return publicationRepository.findTop20ByOrderByPublishedAtDesc();
    }
}
