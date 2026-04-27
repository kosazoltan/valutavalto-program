package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.ExchangeRateDistribution.DistributionStatus;
import hu.puzzleir.valuta.entity.ExchangeRateMaster.MasterRateStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
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
import java.util.*;

/**
 * Árfolyam törzs szolgáltatás.
 *
 * A főértéktáros által beállított árfolyamok kezelése:
 * 1. Törzs árfolyam létrehozása (DRAFT)
 * 2. Jóváhagyás (APPROVED)
 * 3. Publikálás és automatikus elosztás a pénztáraknak (PUBLISHED)
 * 4. Visszavonás (REVOKED) vagy archiválás (ARCHIVED)
 *
 * Legacy: ARFREG + ARFTMK + SETRATE modulok funkcionalitása
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ExchangeRateMasterService {

    private final ExchangeRateMasterRepository masterRepository;
    private final ExchangeRateDistributionRepository distributionRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final RateWorkgroupRepository workgroupRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final AuditLogService auditLogService;

    /**
     * Törzs árfolyam létrehozása (DRAFT állapotban).
     * A főértéktáros készíti az árfolyamot.
     */
    @Transactional(rollbackFor = Exception.class)
    public ExchangeRateMaster createMasterRate(CreateMasterRateRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        hu.puzzleir.valuta.entity.Currency currency = currencyRepository.findById(request.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Valuta nem található: " + request.getCurrencyId()));

        // Validáció: eladási árfolyam > vételi árfolyam
        if (request.getBaseBuyRate().compareTo(request.getBaseSellRate()) >= 0) {
            throw new ValidationException(
                "Az eladási árfolyamnak nagyobbnak kell lennie a vételinél!");
        }

        // Verzió meghatározás: meglévő aktív ráta verzió + 1
        int nextVersion = masterRepository.findActivePublishedByCurrency(companyId, currency.getId())
                .stream()
                .mapToInt(ExchangeRateMaster::getVersionNumber)
                .max()
                .orElse(0) + 1;

        ExchangeRateMaster master = ExchangeRateMaster.builder()
                .companyId(companyId)
                .currencyId(currency.getId())
                .baseBuyRate(request.getBaseBuyRate())
                .baseSellRate(request.getBaseSellRate())
                .officialRate(request.getOfficialRate())
                .limit1Amount(request.getLimit1Amount())
                .limit1BuyRate(request.getLimit1BuyRate())
                .limit1SellRate(request.getLimit1SellRate())
                .limit2Amount(request.getLimit2Amount())
                .limit2BuyRate(request.getLimit2BuyRate())
                .limit2SellRate(request.getLimit2SellRate())
                .limit3Amount(request.getLimit3Amount())
                .limit3BuyRate(request.getLimit3BuyRate())
                .limit3SellRate(request.getLimit3SellRate())
                .status(MasterRateStatus.DRAFT)
                .versionNumber(nextVersion)
                .createdBy(workerId)
                .notes(request.getNotes())
                .build();

        master = masterRepository.save(master);
        log.info("Törzs árfolyam létrehozva: {} v{} - vétel: {}, eladás: {}",
                currency.getCode(), nextVersion,
                master.getBaseBuyRate(), master.getBaseSellRate());

        return master;
    }

    /**
     * Törzs árfolyam jóváhagyása.
     * Csak DRAFT állapotú árfolyamot lehet jóváhagyni.
     */
    @Transactional(rollbackFor = Exception.class)
    public ExchangeRateMaster approveMasterRate(UUID masterRateId) {
        ExchangeRateMaster master = masterRepository.findById(masterRateId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Törzs árfolyam nem található: " + masterRateId));

        if (master.getStatus() != MasterRateStatus.DRAFT) {
            throw new ValidationException(
                "Csak DRAFT állapotú árfolyamot lehet jóváhagyni! Jelenlegi: " + master.getStatus());
        }

        master.setStatus(MasterRateStatus.APPROVED);
        master.setApprovedBy(SecurityUtils.getCurrentWorkerId());
        master.setApprovedAt(LocalDateTime.now());

        master = masterRepository.save(master);
        log.info("Törzs árfolyam jóváhagyva: {}", masterRateId);
        auditLogService.log("RATE_APPROVE",
                String.format("Arfolyam jovahagyva: currencyId=%d v%d", master.getCurrencyId(), master.getVersionNumber()),
                masterRateId.toString());

        return master;
    }

    /**
     * Törzs árfolyam publikálása és automatikus elosztása a pénztáraknak.
     *
     * Ez a KULCS funkció: a főértéktáros által jóváhagyott árfolyamot
     * kiküldi az összes releváns pénztárnak (vagy munkacsoport pénztárainak).
     *
     * Legacy: ARFTMK modul - FTP + pk binary fájlok → REST API + WebSocket push
     *
     * @param masterRateId a törzs árfolyam ID
     * @param workgroupId opcionális munkacsoport - ha null, akkor az összes aktív pénztárnak
     */
    @Transactional(rollbackFor = Exception.class)
    public ExchangeRateMaster publishAndDistribute(UUID masterRateId, UUID workgroupId) {
        ExchangeRateMaster master = masterRepository.findById(masterRateId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Törzs árfolyam nem található: " + masterRateId));

        if (master.getStatus() != MasterRateStatus.APPROVED
                && master.getStatus() != MasterRateStatus.DRAFT) {
            throw new ValidationException(
                "Csak DRAFT vagy APPROVED állapotú árfolyamot lehet publikálni! Jelenlegi: "
                + master.getStatus());
        }

        // Lokális final referenciák a lambda-khoz (master lentebb reassigned)
        final Long currencyId = master.getCurrencyId();
        final UUID companyIdForLookup = master.getCompanyId();

        hu.puzzleir.valuta.entity.Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Valuta nem található: " + currencyId));

        Company company = companyRepository.findById(companyIdForLookup)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Cég nem található: " + companyIdForLookup));

        // Korábbi aktív törzs árfolyamok inaktiválása ugyanerre a valutára
        List<ExchangeRateMaster> oldMasters = masterRepository.findOtherActiveRates(
                master.getCompanyId(), master.getCurrencyId(), master.getId());
        for (ExchangeRateMaster old : oldMasters) {
            old.setIsActive(false);
            old.setStatus(MasterRateStatus.ARCHIVED);
            old.setValidUntil(LocalDateTime.now());
            masterRepository.save(old);
        }

        // Státusz frissítése PUBLISHED-re
        master.setStatus(MasterRateStatus.PUBLISHED);
        master.setValidFrom(LocalDateTime.now());
        if (master.getApprovedBy() == null) {
            master.setApprovedBy(SecurityUtils.getCurrentWorkerId());
            master.setApprovedAt(LocalDateTime.now());
        }
        master = masterRepository.save(master);

        // Célpénztárak meghatározása
        Set<Branch> targetBranches = resolveTargetBranches(workgroupId, company.getId());

        if (targetBranches.isEmpty()) {
            log.warn("Nincs célpénztár az árfolyam elosztáshoz! workgroupId={}", workgroupId);
            // Codex AI P2: audit log akkor is kell, ha 0 penztar kapott — a status valtozas (PUBLISHED) megtortent
            auditLogService.log("RATE_PUBLISH",
                    String.format("Arfolyam publikalva: %s v%d -> 0 penztar (no target branches)",
                            currency.getCode(), master.getVersionNumber()),
                    masterRateId.toString());
            return master;
        }

        // Árfolyamok létrehozása és elosztása minden célpénztárnak
        int successCount = 0;
        int failCount = 0;

        for (Branch branch : targetBranches) {
            try {
                ExchangeRate rate = createExchangeRateForBranch(master, currency, company, branch);
                ExchangeRateDistribution distribution = ExchangeRateDistribution.builder()
                        .masterRateId(master.getId())
                        .branchId(branch.getId())
                        .exchangeRateId(rate.getId())
                        .status(DistributionStatus.DISTRIBUTED)
                        .build();
                distributionRepository.save(distribution);
                successCount++;
            } catch (Exception e) {
                log.error("Árfolyam elosztás hiba: branch={}, error={}", branch.getCode(), e.getMessage());
                ExchangeRateDistribution distribution = ExchangeRateDistribution.builder()
                        .masterRateId(master.getId())
                        .branchId(branch.getId())
                        .status(DistributionStatus.FAILED)
                        .errorMessage(e.getMessage())
                        .build();
                distributionRepository.save(distribution);
                failCount++;
            }
        }

        // WebSocket értesítés küldése
        broadcastRateDistribution(master, currency, targetBranches.size(), workgroupId);

        log.info("Árfolyam publikálva és elosztva: {} v{} - {} pénztárnak sikeresen, {} hibával",
                currency.getCode(), master.getVersionNumber(), successCount, failCount);

        auditLogService.log("RATE_PUBLISH",
                String.format("Arfolyam publikalva: %s v%d -> %d penztar (%d OK, %d hiba)",
                        currency.getCode(), master.getVersionNumber(), targetBranches.size(), successCount, failCount),
                masterRateId.toString());

        return master;
    }

    /**
     * Törzs árfolyam visszavonása.
     */
    @Transactional(rollbackFor = Exception.class)
    public ExchangeRateMaster revokeMasterRate(UUID masterRateId) {
        ExchangeRateMaster master = masterRepository.findById(masterRateId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Törzs árfolyam nem található: " + masterRateId));

        if (master.getStatus() == MasterRateStatus.ARCHIVED) {
            throw new ValidationException("Archivált árfolyamot nem lehet visszavonni!");
        }

        master.setStatus(MasterRateStatus.REVOKED);
        master.setIsActive(false);
        master.setValidUntil(LocalDateTime.now());
        master = masterRepository.save(master);

        log.info("Törzs árfolyam visszavonva: {}", masterRateId);
        auditLogService.log("RATE_REVOKE",
                String.format("Arfolyam visszavonva: currencyId=%d v%d", master.getCurrencyId(), master.getVersionNumber()),
                masterRateId.toString());
        return master;
    }

    /**
     * Összes aktív törzs árfolyam lekérése.
     */
    @Transactional(readOnly = true)
    public List<ExchangeRateMaster> getActivePublishedRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return masterRepository.findActivePublished(companyId);
    }

    /**
     * Összes törzs árfolyam lekérése (minden státusz).
     */
    @Transactional(readOnly = true)
    public List<ExchangeRateMaster> getAllMasterRates() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return masterRepository.findAllByCompany(companyId);
    }

    /**
     * Státusz szerinti lekérdezés.
     */
    @Transactional(readOnly = true)
    public List<ExchangeRateMaster> getMasterRatesByStatus(MasterRateStatus status) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return masterRepository.findByCompanyIdAndStatusOrderByCreatedAtDesc(companyId, status);
    }

    /**
     * Elosztás állapotának lekérdezése egy törzs árfolyamhoz.
     */
    @Transactional(readOnly = true)
    public List<ExchangeRateDistribution> getDistributionStatus(UUID masterRateId) {
        return distributionRepository.findByMasterRateId(masterRateId);
    }

    /**
     * Pénztár visszaigazolás (acknowledge) regisztrálása.
     */
    @Transactional(rollbackFor = Exception.class)
    public void acknowledgeDistribution(UUID distributionId) {
        ExchangeRateDistribution dist = distributionRepository.findById(distributionId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Elosztás nem található: " + distributionId));

        dist.setStatus(DistributionStatus.ACKNOWLEDGED);
        dist.setAcknowledgedAt(LocalDateTime.now());
        distributionRepository.save(dist);
    }

    // ============ BELSŐ SEGÉD METÓDUSOK ============

    /**
     * Célpénztárak meghatározása munkacsoport vagy teljes cég alapján.
     */
    private Set<Branch> resolveTargetBranches(UUID workgroupId, UUID companyId) {
        Set<Branch> targetBranches = new LinkedHashSet<>();

        if (workgroupId != null) {
            // Munkacsoport pénztárai
            RateWorkgroup workgroup = workgroupRepository.findById(workgroupId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                        "Munkacsoport nem található: " + workgroupId));
            if (workgroup.getBranches() != null) {
                targetBranches.addAll(workgroup.getBranches());
            }
        } else {
            // Az összes aktív pénztár a cégben
            List<Branch> allBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
            targetBranches.addAll(allBranches);
        }

        return targetBranches;
    }

    /**
     * ExchangeRate rekord létrehozása egy adott pénztárnak a törzs árfolyam alapján.
     * Inaktiválja a korábbi árfolyamokat.
     */
    private ExchangeRate createExchangeRateForBranch(
            ExchangeRateMaster master, hu.puzzleir.valuta.entity.Currency currency, Company company, Branch branch) {

        // Korábbi árfolyamok inaktiválása ennél a pénztárnál
        List<ExchangeRate> oldRates = exchangeRateRepository.findCurrentRate(
                company.getId(), currency.getId(), branch.getId());
        for (ExchangeRate oldRate : oldRates) {
            oldRate.setActive(false);
            exchangeRateRepository.save(oldRate);
        }

        // Új árfolyam létrehozása
        ExchangeRate rate = ExchangeRate.builder()
                .company(company)
                .branch(branch)
                .currency(currency)
                .validDate(LocalDate.now())
                .validTime(LocalTime.now())
                .baseBuyRate(master.getBaseBuyRate())
                .baseSellRate(master.getBaseSellRate())
                .officialRate(master.getOfficialRate())
                .limit1Amount(master.getLimit1Amount())
                .limit1BuyRate(master.getLimit1BuyRate())
                .limit1SellRate(master.getLimit1SellRate())
                .limit2Amount(master.getLimit2Amount())
                .limit2BuyRate(master.getLimit2BuyRate())
                .limit2SellRate(master.getLimit2SellRate())
                .limit3Amount(master.getLimit3Amount())
                .limit3BuyRate(master.getLimit3BuyRate())
                .limit3SellRate(master.getLimit3SellRate())
                .active(true)
                .createdBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        return exchangeRateRepository.save(rate);
    }

    /**
     * WebSocket értesítés küldése az árfolyam frissítésről.
     */
    private void broadcastRateDistribution(
            ExchangeRateMaster master, hu.puzzleir.valuta.entity.Currency currency, int branchCount, UUID workgroupId) {
        try {
            Map<String, Object> message = new LinkedHashMap<>();
            message.put("type", "RATE_DISTRIBUTED");
            message.put("currencyId", master.getCurrencyId());
            message.put("currencyCode", currency.getCode());
            message.put("baseBuyRate", master.getBaseBuyRate());
            message.put("baseSellRate", master.getBaseSellRate());
            message.put("officialRate", master.getOfficialRate());
            message.put("versionNumber", master.getVersionNumber());
            message.put("affectedBranches", branchCount);
            message.put("publishedAt", LocalDateTime.now().toString());

            // Globális értesítés
            // Spring Boot 4 / Spring Messaging 7: convertAndSend overload ambiguity
            // a Map payload + Map<String,Object> headers kozott. Explicit (Object) cast
            // a String destination overload-ot valasztja.
            messagingTemplate.convertAndSend("/topic/rate-updates", (Object) message);

            // Munkacsoport-specifikus értesítés
            if (workgroupId != null) {
                messagingTemplate.convertAndSend("/topic/rate-updates/" + workgroupId, (Object) message);
            }

            log.debug("WebSocket árfolyam elosztás értesítés küldve: {} - {} pénztárnak",
                    currency.getCode(), branchCount);
        } catch (Exception e) {
            log.warn("WebSocket értesítés sikertelen: {}", e.getMessage());
        }
    }

    // ============ REQUEST DTO ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CreateMasterRateRequest {
        private Long currencyId;
        private BigDecimal baseBuyRate;
        private BigDecimal baseSellRate;
        private BigDecimal officialRate;
        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;
        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;
        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;
        private String notes;
    }
}
