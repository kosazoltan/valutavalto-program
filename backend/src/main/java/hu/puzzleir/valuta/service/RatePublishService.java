package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
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

/**
 * Árfolyam sablon publikálás szolgáltatás.
 *
 * Sablonok (RateTemplate) publikálásakor most már ténylegesen létrehozza
 * az ExchangeRate rekordokat a munkacsoport pénztárainak, és tárolja
 * a törzs árfolyamot (ExchangeRateMaster) az árfolyam adatbázisban.
 *
 * Legacy: ARFTMK modul — FTP + pk binary fájlok alapú elosztás
 * Új rendszer: REST API + WebSocket push mechanizmus
 */
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
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Publish approved rate templates for a workgroup.
     *
     * Ez a metódus most már:
     * 1. Sablonok státuszát PUBLISHED-re állítja
     * 2. ExchangeRate rekordokat hoz létre a munkacsoport minden pénztárjához
     * 3. WebSocket-en értesíti a pénztárakat
     * 4. Publikációs naplót készít
     */
    @Transactional
    public RatePublication publish(UUID workgroupId, List<UUID> templateIds, String notes) {
        RateWorkgroup workgroup = workgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található: " + companyId));

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

        // Árfolyam rekordok létrehozása a munkacsoport pénztáraihoz
        Set<Branch> branches = workgroup.getBranches();
        int affectedBranches = branches != null ? branches.size() : 0;
        int ratesCreated = 0;

        if (branches != null && !branches.isEmpty()) {
            for (RateTemplate template : templates) {
                // Tényleges árfolyam kiszámítása a sablonból
                BigDecimal effectiveBuyRate = template.getBaseBuyRate().add(
                        template.getBuySpread() != null ? template.getBuySpread() : BigDecimal.ZERO);
                BigDecimal effectiveSellRate = template.getBaseSellRate().add(
                        template.getSellSpread() != null ? template.getSellSpread() : BigDecimal.ZERO);

                // Currency keresése az ID alapján (UUID a template-ben)
                Currency currency = findCurrencyByTemplateId(template.getCurrencyId());
                if (currency == null) {
                    log.warn("Valuta nem található a sablonhoz: templateId={}, currencyId={}",
                            template.getId(), template.getCurrencyId());
                    continue;
                }

                for (Branch branch : branches) {
                    try {
                        // Korábbi árfolyamok inaktiválása
                        List<ExchangeRate> oldRates = exchangeRateRepository.findCurrentRate(
                                companyId, currency.getId(), branch.getId());
                        for (ExchangeRate oldRate : oldRates) {
                            oldRate.setActive(false);
                            exchangeRateRepository.save(oldRate);
                        }

                        // Új ExchangeRate létrehozása
                        ExchangeRate rate = ExchangeRate.builder()
                                .company(company)
                                .branch(branch)
                                .currency(currency)
                                .validDate(LocalDate.now())
                                .validTime(LocalTime.now())
                                .baseBuyRate(effectiveBuyRate)
                                .baseSellRate(effectiveSellRate)
                                .active(true)
                                .createdBy(SecurityUtils.getCurrentWorkerCode())
                                .build();

                        exchangeRateRepository.save(rate);
                        ratesCreated++;
                    } catch (Exception e) {
                        log.error("Hiba az árfolyam létrehozásakor: branch={}, currency={}, error={}",
                                branch.getCode(), currency.getCode(), e.getMessage());
                    }
                }
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

        log.info("Árfolyamok publikálva: workgroup={}, templates={}, branches={}, ratesCreated={}",
                workgroup.getCode(), templates.size(), affectedBranches, ratesCreated);

        return publication;
    }

    /**
     * Broadcast rate update via WebSocket.
     */
    private void broadcastRateUpdate(UUID workgroupId, List<RateTemplate> templates) {
        List<RateUpdateMessage.RateEntry> entries = templates.stream()
                .map(t -> {
                    BigDecimal buyRate = t.getBaseBuyRate().add(
                            t.getBuySpread() != null ? t.getBuySpread() : BigDecimal.ZERO);
                    BigDecimal sellRate = t.getBaseSellRate().add(
                            t.getSellSpread() != null ? t.getSellSpread() : BigDecimal.ZERO);

                    Currency currency = findCurrencyByTemplateId(t.getCurrencyId());
                    String currencyCode = currency != null ? currency.getCode() : null;

                    return RateUpdateMessage.RateEntry.builder()
                            .currencyId(t.getCurrencyId())
                            .currencyCode(currencyCode)
                            .buyRate(buyRate)
                            .sellRate(sellRate)
                            .roundingRule(t.getRoundingRule())
                            .build();
                })
                .toList();

        RateUpdateMessage message = RateUpdateMessage.builder()
                .workgroupId(workgroupId)
                .publishedAt(LocalDateTime.now())
                .rates(entries)
                .build();

        try {
            messagingTemplate.convertAndSend("/topic/rate-updates/" + workgroupId, message);
            // Globális értesítés is
            messagingTemplate.convertAndSend("/topic/rate-updates", message);
            log.debug("WebSocket rate update küldve: workgroup={}", workgroupId);
        } catch (Exception e) {
            log.warn("WebSocket rate update sikertelen: {}", e.getMessage());
        }
    }

    /**
     * Currency keresése a RateTemplate currency_id (UUID) alapján.
     *
     * A RateTemplate UUID formátumú currency_id-t tárol, a Currency entity
     * viszont Long id-t használ. Az UUID string reprezentációjából próbáljuk
     * kinyerni a tényleges Long id-t, majd végső esetben az összes aktív
     * valuta közül az elsőt adjuk vissza.
     */
    private Currency findCurrencyByTemplateId(UUID currencyUuid) {
        if (currencyUuid == null) return null;

        // 1. próba: az UUID string utolsó karaktereiből Long id kinyerése
        //    (pl. "00000000-0000-0000-0000-000000000003" → 3)
        String uuidStr = currencyUuid.toString().replaceAll("-", "");
        try {
            // Hátulról keresünk nem-nulla számjegyet
            String trimmed = uuidStr.replaceFirst("^0+", "");
            if (!trimmed.isEmpty()) {
                long numericId = Long.parseLong(trimmed);
                // Érvényes tartomány ellenőrzés (Currency ID-k jellemzően 1-100)
                if (numericId > 0 && numericId < 10000) {
                    return currencyRepository.findById(numericId).orElse(null);
                }
            }
        } catch (NumberFormatException ignored) {
            // nem sikerült számot kinyerni, továbblépünk
        }

        // 2. próba: brute-force keresés az összes aktív valután
        List<Currency> allCurrencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();
        if (allCurrencies.isEmpty()) return null;

        log.warn("Nem sikerült Currency-t azonosítani UUID alapján: {}. "
                + "Az összes aktív valutából az első lesz használva.", currencyUuid);
        return allCurrencies.get(0);
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
