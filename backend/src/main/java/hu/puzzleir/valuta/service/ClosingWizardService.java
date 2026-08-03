package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import tools.jackson.core.JacksonException;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStatusDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStepDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.DailyClosingService.ClosingWizardResult;
import hu.puzzleir.valuta.service.DailyClosingService.ClosingStepResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Zárási varázsló szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ClosingWizardService {

    private final ClosingWizardRepository closingWizardRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DailySessionRepository dailySessionRepository;
    private final TransactionRepository transactionRepository;
    private final DailyClosingService dailyClosingService;
    private final ObjectMapper objectMapper;
    // Issue #117: countDenominations most mar menti a DenominationBalance rekordokat.
    private final DenominationRepository denominationRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final SystemParameterService systemParameterService;
    /** FK-066: pénznemenkénti zárás-tolerancia közös forrása (FR-6) — a puha kapu ebből olvas. */
    private final ClosingToleranceService closingToleranceService;
    // FK-065: beragadt munkamenet auto-lejárat + megszakítás auditja.
    private final AuditLogService auditLogService;

    /** G3: a zárás-eltérés magyarázat-kötelezettség feature-flag SystemParameter kulcsa. */
    static final String CLOSING_DISCREPANCY_PARAM = "CLOSING_DISCREPANCY_EXPLANATION_REQUIRED";
    // FK-066: a korábbi hardkódolt DISCREPANCY_TOLERANCE_HUF konstans megszűnt — a
    // toleranciát pénznemenként a ClosingToleranceService adja (explicit sor vagy
    // kód-fallback), a blokkolási operátor a ClosingTolerance.blocks()-ban dől el.
    /** FK-065: az auto-lejárat küszöbének (perc) SystemParameter kulcsa. */
    static final String AUTO_EXPIRE_MINUTES_PARAM = "CLOSING_WIZARD_AUTO_EXPIRE_MINUTES";
    /** FK-065: default lejárati küszöb percben, ha a paraméter hiányzik/érvénytelen. */
    private static final int DEFAULT_AUTO_EXPIRE_MINUTES = 120;
    /** FK-065 MEDIUM-fix: a küszöb megengedett tartománya (perc) — ezen kívül clamp. */
    private static final int AUTO_EXPIRE_MIN_MINUTES = 30;
    private static final int AUTO_EXPIRE_MAX_MINUTES = 1440;

    /**
     * Zárási varázsló indítása
     */
    public ClosingWizardDto startWizard(UUID branchId, UUID cashDeskId, String closingTypeStr, Long workerId) {
        Branch branch = findBranchInCurrentCompany(branchId);

        Worker worker = findWorkerInCurrentCompany(workerId);

        // Ellenőrzés: nincs-e már MA aktív varázsló ehhez az irodához.
        // Korábbi napról beragadt IN_PROGRESS rekord nem blokkolhat (stale lock) —
        // azt csak figyelmeztetésként naplózzuk, nem módosítjuk.
        LocalDate today = LocalDate.now();
        List<ClosingWizard> activeToday = closingWizardRepository
                .findByBranchIdAndStatusAndClosingDate(branchId, WizardStatus.IN_PROGRESS, today);
        if (!activeToday.isEmpty()) {
            throw new ValidationException("Már van aktív zárási varázsló ehhez az irodához a mai napra!");
        }
        List<ClosingWizard> staleActive = closingWizardRepository
                .findByBranchIdAndStatus(branchId, WizardStatus.IN_PROGRESS);
        if (!staleActive.isEmpty()) {
            log.warn("Beragadt (korábbi napi) IN_PROGRESS zárási varázsló(k) az irodához: branchId={}, ids={}",
                    branchId,
                    staleActive.stream().map(w -> w.getId() + "@" + w.getClosingDate()).collect(Collectors.toList()));
        }

        ClosingType closingType = ClosingType.valueOf(closingTypeStr);
        int totalSteps = getStepCount(closingType);

        ClosingWizard wizard = ClosingWizard.builder()
                .branch(branch)
                .cashDeskId(cashDeskId)
                .closingDate(today)
                .closingType(closingType)
                .currentStep(1)
                .totalSteps(totalSteps)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(worker)
                .startedAt(LocalDateTime.now())
                .build();

        // Lépések inicializálása
        List<ClosingWizardStep> steps = createStepsForType(closingType, wizard);
        wizard.setSteps(steps);

        ClosingWizard saved = closingWizardRepository.save(wizard);
        log.info("Zárási varázsló indítva: id={}, típus={}, iroda={}", saved.getId(), closingType, branchId);

        return toDto(saved);
    }

    /**
     * Varázsló lekérése
     */
    @Transactional(readOnly = true)
    public ClosingWizardDto getWizard(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);
        return toDto(wizard);
    }

    /**
     * F-5: multi-tenant/branch IDOR-védelem — a wizard a hívó irodájához tartozzon.
     *
     * <p>A {@code getWizard} eredeti branch-ownership mintáját emeli ki közös helyerbe,
     * hogy minden wizardId-paraméteres művelet (getStep, navigate, complete, cancel,
     * generateClosingReport, finalizeClosing) egységesen védve legyen a
     * {@code findByIdWithSteps(...)} után. Ez user-facing (ClosingWizardController) hívási
     * útra való; az osztálynak nincs {@code @Scheduled}/auth-mentes hívója.</p>
     */
    /**
     * FK-065 (Codex HIGH): user-facing wizard-írás optimista lock-fordítással.
     * A flush() a metóduson BELÜL futtatja le a verzió-ellenőrzést (nem a
     * tranzakció commitjánál), így a konfliktus itt elkapható és felhasználó-barát
     * 409-re fordítható (GlobalExceptionHandler), nem generikus 500-ra. Konfliktus =
     * a sort időközben más írta (pl. a scheduler auto-lejárata EXPIRED-re váltotta).
     */
    private ClosingWizard saveWizardWithConflictCheck(ClosingWizard wizard) {
        try {
            ClosingWizard saved = closingWizardRepository.save(wizard);
            closingWizardRepository.flush();
            return saved;
        } catch (org.springframework.dao.OptimisticLockingFailureException
                | jakarta.persistence.OptimisticLockException e) {
            log.warn("Zárási varázsló optimista lock konfliktus: id={}", wizard.getId());
            throw new jakarta.persistence.OptimisticLockException(
                    "A zárási munkamenet közben megváltozott (pl. automatikus lejárat) — "
                            + "frissítsd az oldalt és próbáld újra.");
        }
    }

    private void assertOwnWizard(ClosingWizard wizard) {
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        if (wizard.getBranch() != null && !wizard.getBranch().getId().equals(currentBranchId)) {
            throw new ValidationException("Nincs jogosultság más iroda zárási varázslójához!");
        }
    }

    /**
     * Adott lépés lekérése
     */
    @Transactional(readOnly = true)
    public ClosingWizardStepDto getStep(UUID wizardId, int stepNumber) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        return wizard.getSteps().stream()
                .filter(s -> s.getStepNumber().equals(stepNumber))
                .findFirst()
                .map(this::toStepDto)
                .orElseThrow(() -> new ResourceNotFoundException("Lépés nem található: " + stepNumber));
    }

    /**
     * Navigáció adott lépésre — végrehajtja az adott lépés ellenőrzését is.
     *
     * A navigate() most már nem csak a currentStep-et lépteti, hanem
     * a DailyClosingService 9 lépéses ellenőrzési láncát is futtatja.
     * Ha a lépés PASS → completed=true, ha FAIL → completed=false.
     */
    public ClosingWizardDto navigate(UUID wizardId, int targetStep) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        if (targetStep < 1 || targetStep > wizard.getTotalSteps()) {
            throw new ValidationException("Érvénytelen lépés szám: " + targetStep);
        }

        wizard.setCurrentStep(targetStep);

        // A lépés ellenőrzésének végrehajtása a DailyClosingService-en keresztül
        ClosingWizardStep step = wizard.getSteps().stream()
                .filter(s -> s.getStepNumber().equals(targetStep))
                .findFirst()
                .orElse(null);

        if (step != null) {
            DailyClosingService.StepCheckResult checkResult =
                    dailyClosingService.executeStepCheck(targetStep, wizard.getBranch().getId(), wizard.getClosingDate());
            step.setCompleted(checkResult.isPassed());

            // Lépés adatok frissítése az ellenőrzés eredményével
            String statusJson = String.format(
                    "{\"passed\":%b,\"skipped\":%b,\"message\":\"%s\"}",
                    checkResult.isPassed(),
                    checkResult.isSkipped(),
                    checkResult.getMessage() != null ? checkResult.getMessage().replace("\"", "\\\"") : "");
            step.setStepData(statusJson);

            if (!checkResult.isPassed()) {
                step.setCanProceed(false);
            }
        }

        ClosingWizard saved = saveWizardWithConflictCheck(wizard);

        return toDto(saved);
    }

    /**
     * Varázsló befejezése
     */
    public ClosingWizardDto complete(UUID wizardId, Long workerId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        Worker worker = findWorkerInCurrentCompany(workerId);

        // M-1: Ellenőrizzük, hogy minden lépés ténylegesen végrehajtva lett-e
        if (wizard.getSteps() == null || wizard.getSteps().isEmpty()) {
            throw new ValidationException("A varázslónak nincsenek lépései — nem zárható le!");
        }
        boolean allStepsCompleted = wizard.getSteps().stream().allMatch(s -> Boolean.TRUE.equals(s.getCompleted()));
        if (!allStepsCompleted) {
            List<String> incomplete = wizard.getSteps().stream()
                    .filter(s -> !Boolean.TRUE.equals(s.getCompleted()))
                    .map(s -> "Lépés " + s.getStepNumber())
                    .collect(Collectors.toList());
            throw new ValidationException("Nem minden lépés lett végrehajtva: " + String.join(", ", incomplete));
        }

        wizard.setWizardStatus(WizardStatus.COMPLETED);
        wizard.setCompletedByWorker(worker);
        wizard.setCompletedAt(LocalDateTime.now());

        ClosingWizard saved = saveWizardWithConflictCheck(wizard);
        log.info("Zárási varázsló befejezve: id={}", wizardId);

        return toDto(saved);
    }

    /**
     * Varázsló megszakítása
     */
    public ClosingWizardDto cancel(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        wizard.setWizardStatus(WizardStatus.CANCELLED);
        ClosingWizard saved = saveWizardWithConflictCheck(wizard);
        log.info("Zárási varázsló megszakítva: id={}", wizardId);

        // FK-065: a megszakítás auditja — az INDÍTÓ és a MEGSZAKÍTÓ megkülönböztetése
        // kizárólag audit_log-on történik (a wizard-táblán nincs erre oszlop): a userId
        // a megszakító (aktor), a changes tartalmazza az indító worker azonosítóját.
        // Manuális megszakítás nem hibaeset — error_code szándékosan nincs.
        if (auditLogService != null) {
            String cancellerCode = SecurityUtils.getCurrentWorkerCode();
            Long starterId = wizard.getStartedByWorker() != null
                    ? wizard.getStartedByWorker().getId()
                    : null;
            String branchIdStr = wizard.getBranch() != null && wizard.getBranch().getId() != null
                    ? wizard.getBranch().getId().toString()
                    : null;
            String branchName = wizard.getBranch() != null ? wizard.getBranch().getName() : null;
            // Security Gate LOW-fix: ObjectMapper-es serializálás a kézi string-fűzés
            // helyett — a cancellerCode így escape-elve kerül a changes JSON-ba.
            Map<String, Object> auditChanges = new LinkedHashMap<>();
            auditChanges.put("KAT", "TX");
            auditChanges.put("started_by_worker_id", starterId);
            auditChanges.put("cancelled_by_worker_code", cancellerCode);
            auditLogService.log(
                    "CLOSING_WIZARD_CANCELLED",
                    "ClosingWizard",
                    wizardId.toString(),
                    cancellerCode,
                    null,
                    branchIdStr,
                    branchName,
                    objectMapper.writeValueAsString(auditChanges),
                    null,
                    null);
        }

        return toDto(saved);
    }

    /**
     * FK-065 FR-1: beragadt (a küszöbnél régebben indított, IN_PROGRESS) zárási
     * varázslók automatikus lejáratása — a {@code ReservationService.autoExpireReservations()}
     * mintája.
     *
     * <p>Scheduler-kontextusban fut, SecurityContext nélkül: TILOS
     * {@code SecurityUtils.getCurrentCompanyId()}-t hívni — a company/branch minden
     * esetben a wizard SAJÁT rekordjából jön. Cross-tenant: egy körben az összes cég
     * sorait kezeli, cégenkénti audittal ({@code logForCompany}, P29-minta;
     * KAT=TX, error_code=VV-BIZ-011). Per-item try/catch: egy hibás rekord nem
     * boríthatja a teljes kört.</p>
     *
     * @return a lejáratott varázslók száma
     */
    public int autoExpireStaleWizards() {
        int expireMinutes = resolveAutoExpireMinutes();
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(expireMinutes);

        List<ClosingWizard> stale = closingWizardRepository
                .findByWizardStatusAndStartedAtBefore(WizardStatus.IN_PROGRESS, cutoff);

        int count = 0;
        for (ClosingWizard wizard : stale) {
            try {
                // Gyors előszűrő: ha a betöltött példány már nem IN_PROGRESS, kihagyjuk.
                if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
                    log.debug("Zárási varázsló már nem aktív, auto-lejárat kihagyva: id={}, státusz={}",
                            wizard.getId(), wizard.getWizardStatus());
                    continue;
                }

                // Bugbot-hardening: a lazy branch→company audit-adatok kiolvasása a bulk
                // UPDATE ELŐTT, lokális változókba. A @Modifying defaultja
                // clearAutomatically=false (a persistence context nem ürül), de így az
                // audit a JPA-viselkedéstől függetlenül, kóddal garantált.
                UUID auditBranchId = wizard.getBranch() != null ? wizard.getBranch().getId() : null;
                UUID auditCompanyId = wizard.getBranch() != null && wizard.getBranch().getCompany() != null
                        ? wizard.getBranch().getCompany().getId()
                        : null;

                // Security Gate HIGH-fix: feltételes, ATOMIKUS UPDATE — a SELECT és az
                // írás közti konkurens cancel()/finalize ellen a DB WHERE-feltétele véd.
                // 0 érintett sor = közben más állapotba került → NEM auditolunk EXPIRED-et.
                int updated = closingWizardRepository.transitionIfStale(
                        wizard.getId(), WizardStatus.IN_PROGRESS, WizardStatus.EXPIRED, cutoff);
                if (updated == 0) {
                    log.debug("Zárási varázsló közben más állapotba került, auto-lejárat kihagyva: id={}",
                            wizard.getId());
                    continue;
                }

                // In-memory szinkron a betöltött példányon (a bulk UPDATE nem frissíti).
                wizard.setWizardStatus(WizardStatus.EXPIRED);
                count++;
                log.info("Beragadt zárási varázsló lejáratva: id={}, indítva={}, küszöb={} perc",
                        wizard.getId(), wizard.getStartedAt(), expireMinutes);

                if (auditLogService != null && auditCompanyId != null) {
                    auditLogService.logForCompany(
                            "CLOSING_WIZARD_AUTO_EXPIRED",
                            String.format(
                                    "{\"KAT\":\"TX\",\"error_code\":\"VV-BIZ-011\","
                                            + "\"branch_id\":\"%s\",\"closing_date\":\"%s\","
                                            + "\"started_at\":\"%s\",\"expire_minutes\":%d}",
                                    auditBranchId, wizard.getClosingDate(),
                                    wizard.getStartedAt(), expireMinutes),
                            wizard.getId().toString(),
                            auditCompanyId);
                }
            } catch (Exception e) {
                log.error("Zárási varázsló auto-lejárat hiba: id={}, hiba={}",
                        wizard.getId(), e.getMessage(), e);
            }
        }
        return count;
    }

    /**
     * FK-065 MEDIUM-fix: az auto-lejárat küszöbének olvasása tartomány-validációval.
     * Érvénytelen (nem szám) érték → default 120 perc; tartományon kívüli érték →
     * WARN + clamp a legközelebbi határra (30..1440 perc). A SystemParameterService-nek
     * nincs saját clamp-mintája, ezért itt, a felhasználás helyén validálunk.
     */
    private int resolveAutoExpireMinutes() {
        int expireMinutes = DEFAULT_AUTO_EXPIRE_MINUTES;
        if (systemParameterService != null) {
            try {
                expireMinutes = Integer.parseInt(systemParameterService
                        .getValue(AUTO_EXPIRE_MINUTES_PARAM, String.valueOf(DEFAULT_AUTO_EXPIRE_MINUTES))
                        .trim());
            } catch (NumberFormatException e) {
                log.warn("Érvénytelen {} paraméter, default {} perc marad: {}",
                        AUTO_EXPIRE_MINUTES_PARAM, DEFAULT_AUTO_EXPIRE_MINUTES, e.getMessage());
                return DEFAULT_AUTO_EXPIRE_MINUTES;
            }
        }
        if (expireMinutes < AUTO_EXPIRE_MIN_MINUTES) {
            log.warn("{} = {} a megengedett tartomány ({}-{} perc) alatt — clamp {} percre",
                    AUTO_EXPIRE_MINUTES_PARAM, expireMinutes,
                    AUTO_EXPIRE_MIN_MINUTES, AUTO_EXPIRE_MAX_MINUTES, AUTO_EXPIRE_MIN_MINUTES);
            return AUTO_EXPIRE_MIN_MINUTES;
        }
        if (expireMinutes > AUTO_EXPIRE_MAX_MINUTES) {
            log.warn("{} = {} a megengedett tartomány ({}-{} perc) felett — clamp {} percre",
                    AUTO_EXPIRE_MINUTES_PARAM, expireMinutes,
                    AUTO_EXPIRE_MIN_MINUTES, AUTO_EXPIRE_MAX_MINUTES, AUTO_EXPIRE_MAX_MINUTES);
            return AUTO_EXPIRE_MAX_MINUTES;
        }
        return expireMinutes;
    }

    // ============ STEP-SPECIFIC METHODS ============

    /**
     * Step 1: Nyitott tranzakciók validálása.
     * Visszaadja a befejezetlen tranzakciók listáját.
     */
    @Transactional(readOnly = true)
    public List<String> validateOpenTransactions(UUID branchId) {
        List<String> errors = new ArrayList<>();
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Ellenőrzés: van-e nyitott session
        if (!dailySessionRepository.hasOpenSession(companyId, branchId)) {
            errors.add("Nincs nyitott napi munkamenet!");
            return errors;
        }

        // Aktuális session lekérése
        DailySession currentSession = dailySessionRepository.findLatest(companyId, branchId)
                .orElse(null);
        if (currentSession != null && currentSession.getStatus() == DailySessionStatus.PENDING_CLOSE) {
            errors.add("A nap zárás alatt van, várjon a folyamat befejezésére!");
        }

        // PENDING tranzakció ellenőrzés — nem szabad zárni, amíg van feldolgozás alatt álló tranzakció
        if (transactionRepository.existsByBranchIdAndStatus(branchId, TransactionStatus.PENDING)) {
            errors.add("Van folyamatban lévő (PENDING) tranzakció! Várjon a befejezésükre a napi zárás előtt.");
        }

        return errors;
    }

    /**
     * Step 2: Cimletolvaso - valutankent cimletek rogzitese + PERZISZTALAS.
     *
     * Issue #117: korabban csak aggregalt objektumot adott vissza, NEM mentette el
     * a DenominationBalance tablaba. Emiatt a DailyClosingService.checkEveningDenomination()
     * mindig "Hianyzik az esti penztar cimletezese!" hibat adott -> napzaras beragadt Step 2-n.
     *
     * Most a DenominationBalance rekordokat upsert-elve ment (EVENING kategoria),
     * igy a checkEveningDenomination az existsByBranchIdAndDateAndCategory(..., EVENING)
     * es sumDenominatedAmount query-kkel megtalalja azokat.
     */
    public Map<String, Object> countDenominations(
            UUID branchId,
            LocalDate businessDate,
            Map<String, Map<Integer, Integer>> denomCounts) {
        Objects.requireNonNull(businessDate, "A címletezés üzleti dátuma kötelező");
        Map<String, Object> result = new LinkedHashMap<>();
        Map<String, BigDecimal> totals = new LinkedHashMap<>();
        int savedRecords = 0;

        for (Map.Entry<String, Map<Integer, Integer>> entry : denomCounts.entrySet()) {
            String currencyCode = entry.getKey();
            Map<Integer, Integer> denoms = entry.getValue();

            hu.puzzleir.valuta.entity.Currency currency = currencyRepository.findByCode(currencyCode)
                    .orElseThrow(() -> new ValidationException(
                            "Ismeretlen valuta a cimletezesnel: " + currencyCode));

            BigDecimal total = BigDecimal.ZERO;
            List<Map<String, Object>> denomDetails = new ArrayList<>();

            for (Map.Entry<Integer, Integer> denom : denoms.entrySet()) {
                int value = denom.getKey();
                int count = denom.getValue();
                // FK-072 (FR-3): 1 alatti névértékű kulcs nem fogadható el — darabszámtól
                // FÜGGETLENÜL (Codex HIGH: a count==0-s érvénytelen kulcs is Denomination
                // auto-create-et futtatna lentebb, törzs-szennyezés direkt API-hívásból).
                // A tört (nem-egész) kulcsot már a JSON-binding utasítja el
                // (GlobalExceptionHandler, azonos VV-VALID-004 kóddal).
                if (value < 1) {
                    throw new ValidationException(
                            "VV-VALID-004: A címlet névértéke nem lehet 1-nél kisebb"
                                    + " (tört címlet nem rögzíthető): " + currencyCode + " " + value);
                }
                BigDecimal subtotal = BigDecimal.valueOf(value).multiply(BigDecimal.valueOf(count));
                total = total.add(subtotal);

                denomDetails.add(Map.of(
                        "value", value,
                        "count", count,
                        "subtotal", subtotal
                ));

                // Issue #117: persist DenominationBalance rekordot
                saveDenominationBalance(
                        branchId, currency, BigDecimal.valueOf(value), count, subtotal, businessDate);
                savedRecords++;
            }

            totals.put(currencyCode, total);
            result.put(currencyCode, Map.of("denominations", denomDetails, "total", total));
        }

        result.put("totals", totals);
        result.put("savedRecords", savedRecords);
        log.info("countDenominations: branchId={}, savedRecords={}, currencies={}",
                branchId, savedRecords, denomCounts.keySet());
        return result;
    }

    /**
     * Issue #117: upsert DenominationBalance rekord.
     * Idempotens: ha letezik (branchId, denominationId) rekord -> UPDATE. Ha nem -> INSERT.
     * Denomination auto-create, ha a branch-currency-faceValue kombora meg nem letezik.
     */
    private void saveDenominationBalance(
            UUID branchId,
            hu.puzzleir.valuta.entity.Currency currency,
            BigDecimal faceValue,
            int quantity,
            BigDecimal subtotal,
            LocalDate businessDate) {
        Denomination denomination = denominationRepository
                .findByBranchIdAndCurrencyIdAndFaceValue(branchId, currency.getId(), faceValue)
                .orElseGet(() -> {
                    Branch branch = findBranchInCurrentCompany(branchId);
                    // HUF szabaly: >= 200 Ft bankjegy, < 200 Ft erme; nem-HUF-ra is BANKNOTE default.
                    DenominationType denomType = faceValue.compareTo(BigDecimal.valueOf(200)) >= 0
                            ? DenominationType.BANKNOTE
                            : DenominationType.COIN;
                    Denomination d = Denomination.builder()
                            .company(branch.getCompany())
                            .branch(branch)
                            .currency(currency)
                            .faceValue(faceValue)
                            .denominationType(denomType)
                            .active(true)
                            .build();
                    log.debug("Denomination auto-create: branch={}, currency={}, faceValue={}",
                            branchId, currency.getCode(), faceValue);
                    return denominationRepository.save(d);
                });

        DenominationBalance balance = denominationBalanceRepository
                .findByCashDeskIdAndDenominationId(branchId, denomination.getId())
                .orElseGet(() -> DenominationBalance.builder()
                        .cashDeskId(branchId)
                        .denomination(denomination)
                        .quantity(0)
                        .totalValue(BigDecimal.ZERO)
                        .denominationCategory(DenominationCategory.EVENING)
                        .build());
        balance.setQuantity(quantity);
        balance.setTotalValue(subtotal);
        balance.setDenominationCategory(DenominationCategory.EVENING);
        balance.setSubmissionDate(businessDate);
        denominationBalanceRepository.save(balance);
    }

    private Branch findBranchInCurrentCompany(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        Optional<Branch> branch = companyId != null
                ? branchRepository.findByIdAndCompanyId(branchId, companyId)
                : branchRepository.findById(branchId);
        return branch.orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private Worker findWorkerInCurrentCompany(Long workerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        Optional<Worker> worker = companyId != null
                ? workerRepository.findByIdAndCompanyId(workerId, companyId)
                : workerRepository.findById(workerId);
        return worker.orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));
    }

    /**
     * Step 3: Eltérés számítás — nyilvántartás vs fizikai készlet.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> calculateDifferences(UUID branchId, Map<String, BigDecimal> physicalCounts) {
        Branch branch = findBranchInCurrentCompany(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Map<String, Object>> differences = new ArrayList<>();

        if (isVaultContext(branch)) {
            for (hu.puzzleir.valuta.entity.Currency currency : currencyRepository.findAllActiveOrdered()) {
                String code = currency.getCode();
                BigDecimal expected = currencyStockRepository
                        .findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                                companyId, "VAULT", resolveVaultEntityId(branch), code)
                        .map(CurrencyStock::getQuantity)
                        .orElse(BigDecimal.ZERO);
                differences.add(differenceItem(code, expected, physicalCounts.getOrDefault(code, BigDecimal.ZERO)));
            }
            for (String code : physicalCounts.keySet()) {
                boolean missing = differences.stream()
                        .noneMatch(item -> code.equals(item.get("currencyCode")));
                if (missing) {
                    differences.add(differenceItem(code, BigDecimal.ZERO, physicalCounts.getOrDefault(code, BigDecimal.ZERO)));
                }
            }
            return differences;
        }

        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        for (CashBalance cb : balances) {
            String code = cb.getCurrency().getCode();
            differences.add(differenceItem(code, cb.getCurrentBalance(), physicalCounts.getOrDefault(code, BigDecimal.ZERO)));
        }

        return differences;
    }

    /**
     * Step 4: Zárási riport generálás.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> generateClosingReport(UUID wizardId) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        UUID branchId = wizard.getBranch().getId();
        UUID companyId = wizard.getBranch().getCompany().getId();
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, LocalDate.now())
                .orElse(null);

        Map<String, Object> report = new LinkedHashMap<>();
        report.put("wizardId", wizardId.toString());
        report.put("branchName", wizard.getBranch().getName());
        report.put("closingDate", wizard.getClosingDate().toString());
        report.put("closingType", wizard.getClosingType().name());

        if (session != null) {
            report.put("transactionCount", session.getTransactionCount());
            report.put("buyCount", session.getBuyCount());
            report.put("sellCount", session.getSellCount());
            report.put("reversalCount", session.getReversalCount());
            report.put("buyTurnoverHuf", session.getBuyTurnoverHuf());
            report.put("sellTurnoverHuf", session.getSellTurnoverHuf());
            report.put("handlingFeeTotal", session.getHandlingFeeTotal());
            report.put("openingBalanceHuf", session.getOpeningBalanceHuf());
            report.put("closingBalanceHuf", session.getClosingBalanceHuf() != null
                    ? session.getClosingBalanceHuf() : BigDecimal.ZERO);
        }

        // Készlet állapot
        List<Map<String, Object>> inventorySnapshot = new ArrayList<>();
        if (isVaultContext(wizard.getBranch())) {
            for (CurrencyStock stock : currencyStockRepository.findByEntityTypeAndEntityId(
                    "VAULT", resolveVaultEntityId(wizard.getBranch()))) {
                inventorySnapshot.add(Map.of(
                        "currencyCode", stock.getCurrencyCode(),
                        "openingBalance", BigDecimal.ZERO,
                        "currentBalance", stock.getQuantity(),
                        "dailyChange", BigDecimal.ZERO
                ));
            }
        } else {
            List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
            for (CashBalance cb : balances) {
                inventorySnapshot.add(Map.of(
                        "currencyCode", cb.getCurrency().getCode(),
                        "openingBalance", cb.getOpeningBalance(),
                        "currentBalance", cb.getCurrentBalance(),
                        "dailyChange", cb.getDailyChange()
                ));
            }
        }
        report.put("inventory", inventorySnapshot);

        return report;
    }

    /**
     * Step 5: Zárás véglegesítése — DailyClosingService 9 lépéses ellenőrzési lánc + session lezárás.
     *
     * 1. Ellenőrzi, hogy minden wizard lépés completed=true
     * 2. Futtatja a DailyClosingService.startDailyClosing()-ot (valódi zárás: snapshot, archív, AML reset stb.)
     * 3. Lezárja a wizard-ot
     */
    public boolean finalizeClosing(UUID wizardId, Long workerId) {
        return finalizeClosing(wizardId, workerId, null);
    }

    /**
     * G3 (EXCMD b2-zaras-ablak FR-13): zárás véglegesítése eltérés-magyarázat gate-tel.
     *
     * <p>A wizard véglegesítése előtt kiszámítja a pénzügyi eltérést (címletezett vs.
     * várt készlet). Ha a {@code CLOSING_DISCREPANCY_EXPLANATION_REQUIRED} feature-flag
     * be van kapcsolva ÉS az eltérés meghaladja a toleranciát, akkor magyarázat
     * nélkül a zárás NEM véglegesíthető (FR-13 eltérés-magyarázat). Az eltérés-összeg
     * és a magyarázat auditálható módon a wizardra kerül. Default (flag KI): a
     * korábbi viselkedés változatlan, a magyarázat csak rögzítésre kerül, ha megadták.</p>
     */
    public boolean finalizeClosing(UUID wizardId, Long workerId, String discrepancyExplanation) {
        ClosingWizard wizard = closingWizardRepository.findByIdWithSteps(wizardId)
                .orElseThrow(() -> new ResourceNotFoundException("Varázsló nem található: " + wizardId));
        assertOwnWizard(wizard);

        if (wizard.getWizardStatus() != WizardStatus.IN_PROGRESS) {
            throw new ValidationException("Ez a varázsló már nem aktív!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        // Ellenőrzés: minden wizard lépés completed kell legyen
        if (wizard.getSteps() != null && !wizard.getSteps().isEmpty()) {
            boolean allStepsCompleted = wizard.getSteps().stream()
                    .allMatch(s -> Boolean.TRUE.equals(s.getCompleted()));
            if (!allStepsCompleted) {
                List<String> incomplete = wizard.getSteps().stream()
                        .filter(s -> !Boolean.TRUE.equals(s.getCompleted()))
                        .map(s -> "Lépés " + s.getStepNumber())
                        .collect(Collectors.toList());
                throw new ValidationException("Nem minden lépés lett végrehajtva: " + String.join(", ", incomplete));
            }
        }

        // Valódi napzárás végrehajtása a DailyClosingService-en keresztül
        LocalDate closingDate = wizard.getClosingDate() != null ? wizard.getClosingDate() : LocalDate.now();
        Branch branch = wizard.getBranch();

        if (branch != null && isVaultContext(branch)) {
            ClosingWizardStatusDto status = getClosingStatus(branch.getId(), closingDate);
            if (!status.isExactMatch()) {
                throw new ValidationException(status.getMessage());
            }
        }

        // G3 (FR-13): eltérés-magyarázat gate a véglegesítés előtt.
        UUID gateCompanyId = SecurityUtils.getCurrentCompanyId();
        // FK-063 FR-3/FR-4: pénztári (nem-vault) ágon pénznemenkénti eltérés-térkép,
        // hogy a blokkoló üzenet nevesítse az érintett pénznem(ek)et.
        Map<String, BigDecimal> perCurrencyDiscrepancies =
                (branch != null && !isVaultContext(branch))
                        ? computePerCurrencyDiscrepancies(gateCompanyId, branch.getId(), closingDate)
                        : null;
        // Sourcery/Codex review (PR #1483): a discrepancyAmount oszlop Ft-szemantikájú —
        // pénztári ágon CSAK a HUF-eltérést perzisztáljuk (a nem-HUF eltérések nominális
        // összegzése árfolyam nélkül értelmezhetetlen volna). A gate ettől függetlenül
        // minden pénznemre a perCurrencyDiscrepancyBlockReason-nel blokkol.
        java.math.BigDecimal discrepancy = perCurrencyDiscrepancies != null
                ? perCurrencyDiscrepancies.getOrDefault("HUF", BigDecimal.ZERO)
                : computeCashDiscrepancy(gateCompanyId,
                        branch != null ? branch.getId() : null, closingDate);
        wizard.setDiscrepancyAmount(discrepancy);
        if (discrepancyExplanation != null && !discrepancyExplanation.isBlank()) {
            wizard.setDiscrepancyExplanation(discrepancyExplanation.trim());
        }
        boolean enforce = systemParameterService != null
                && "true".equalsIgnoreCase(systemParameterService.getValue(CLOSING_DISCREPANCY_PARAM, "false"));
        if (enforce) {
            // FK-066 (FR-3/FR-6): a tolerancia pénznemenként a közös ClosingToleranceService-ből
            // jön; az ág-függő operátor (explicit >=, fallback >) a ClosingTolerance.blocks()-ban.
            String blockReason = perCurrencyDiscrepancies != null
                    ? perCurrencyDiscrepancyBlockReason(
                            perCurrencyDiscrepancies, wizard.getDiscrepancyExplanation(),
                            closingToleranceService::getToleranceFor)
                    : closingDiscrepancyBlockReason(
                            discrepancy, wizard.getDiscrepancyExplanation(),
                            closingToleranceService.getToleranceFor("HUF"));
            if (blockReason != null) {
                throw new ValidationException(blockReason);
            }
        }
        ClosingWizardResult closingResult = dailyClosingService.startDailyClosing(closingDate);

        if (!closingResult.isAllPassed()) {
            // Ha a belső ellenőrzés valamelyik lépése elbukik
            String failedSteps = closingResult.getSteps().stream()
                    .filter(s -> !s.isPassed())
                    .map(s -> s.getStepName() + ": " + s.getMessage())
                    .collect(Collectors.joining("; "));
            throw new ValidationException("Napzárás belső ellenőrzés sikertelen: " + failedSteps);
        }

        if (!closingResult.getWarnings().isEmpty()) {
            log.warn("Napzárás lezárva, de {} lépés figyelmeztetéssel: {}",
                    closingResult.getWarnings().size(),
                    closingResult.getWarnings().stream()
                            .map(w -> w.getStep() + ": " + w.getMessage())
                            .collect(Collectors.joining("; ")));
        }

        // Wizard lezárása — optimista lock-ellenőrzéssel (Codex HIGH): ha a
        // scheduler auto-lejárata közben EXPIRED-re váltotta, itt konfliktus lesz,
        // nem néma COMPLETED-felülírás.
        wizard.setWizardStatus(WizardStatus.COMPLETED);
        wizard.setCompletedByWorker(worker);
        wizard.setCompletedAt(LocalDateTime.now());
        saveWizardWithConflictCheck(wizard);

        log.info("Zárás véglegesítve: wizard={}, closingDate={}", wizardId, closingDate);

        return true;
    }

    /**
     * G3 (FR-13): a pénzügyi eltérés (címletezett − várt készlet) kiszámítása a
     * zárás napjára. {@code null} csak akkor, ha a branchId null; a repó query-k
     * COALESCE-olnak 0-ra, így hiányzó adatnál az eltérés 0 (toleranciaon belül).
     */
    private java.math.BigDecimal computeCashDiscrepancy(UUID companyId, UUID branchId, LocalDate date) {
        if (branchId == null) {
            return null;
        }
        Branch branch = findBranchInCurrentCompany(branchId);
        if (isVaultContext(branch)) {
            return calculateDifferences(branchId, loadPhysicalCounts(branchId, date)).stream()
                    .map(item -> item.get("difference"))
                    .filter(BigDecimal.class::isInstance)
                    .map(BigDecimal.class::cast)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
        }
        // FK-063 (PR #1483 review): a visszatérési érték Ft-szemantikájú (discrepancyAmount
        // oszlop) — pénztári ágon a HUF-eltérést adjuk vissza; a nem-HUF pénznemek eltéréseit
        // a perCurrencyDiscrepancyBlockReason gate kezeli pénznemenként.
        return computePerCurrencyDiscrepancies(companyId, branchId, date)
                .getOrDefault("HUF", BigDecimal.ZERO);
    }

    /**
     * FK-063 FR-3/FR-4: pénztári (nem-vault) ág pénznemenkénti eltérései —
     * becímletezett (EVENING, {@code sumActualStockByCurrency}) vs. nyilvántartott
     * ({@code cash_balance}) egyenleg, pénznem-kód szerint. Csak a nem-nulla
     * eltérésű pénznemek kerülnek a térképbe.
     */
    private Map<String, BigDecimal> computePerCurrencyDiscrepancies(UUID companyId, UUID branchId, LocalDate date) {
        Map<String, BigDecimal> denominated = loadPhysicalCounts(branchId, date);
        Map<String, BigDecimal> expected = new LinkedHashMap<>();
        for (CashBalance cb : cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId)) {
            expected.put(cb.getCurrency().getCode(), cb.getCurrentBalance());
        }
        Set<String> codes = new LinkedHashSet<>(expected.keySet());
        codes.addAll(denominated.keySet());

        Map<String, BigDecimal> diffs = new LinkedHashMap<>();
        for (String code : codes) {
            BigDecimal diff = denominated.getOrDefault(code, BigDecimal.ZERO)
                    .subtract(expected.getOrDefault(code, BigDecimal.ZERO));
            if (diff.compareTo(BigDecimal.ZERO) != 0) {
                diffs.put(code, diff);
            }
        }
        return diffs;
    }

    /**
     * FK-063 FR-1: pénznem-kódok, amelyekre a pénztári becímletezésnek szekciót kell
     * nyitnia — a branch nem-nulla {@code cash_balance} készletű pénznemei, plusz a
     * HUF mindig (akkor is, ha az egyenlege éppen 0). Cég-szűrt (cross-tenant
     * branchId üres készletet ad — csak a kötelező HUF marad).
     */
    @Transactional(readOnly = true)
    public List<String> getCurrenciesWithBalance(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<String> codes = new ArrayList<>(
                cashBalanceRepository.findCurrencyCodesWithNonZeroBalance(branchId, companyId));
        if (!codes.contains("HUF")) {
            codes.add(0, "HUF");
        }
        return codes;
    }

    /**
     * G3 (FR-13) eltérés-gate döntés — legacy overload rögzített HUF-toleranciával.
     * FK-066: fallback-szemantikával delegál ({@code |diff| > tolerancia} blokkol) —
     * a paraméter-vezérelt viselkedés változatlan.
     */
    static String closingDiscrepancyBlockReason(
            java.math.BigDecimal discrepancyHuf, String explanation, java.math.BigDecimal toleranceHuf) {
        return closingDiscrepancyBlockReason(discrepancyHuf, explanation,
                ClosingTolerance.fallbackOf(toleranceHuf));
    }

    /**
     * G3 (FR-13) + FK-066 eltérés-gate döntés — statikus, függőség-mentes (tesztelhető).
     * Az ág-függő blokkolási operátor (explicit {@code >=}, fallback {@code >}) a
     * {@link ClosingTolerance#blocks} közös döntési pontjában dől el (FR-6).
     *
     * @return blokkoló indok, ha (az eltérés blokkoló ÉS nincs magyarázat);
     *         {@code null}, ha nincs eltérés / tolerancián belül / van magyarázat /
     *         nem dönthető el (null eltérés)
     */
    static String closingDiscrepancyBlockReason(
            java.math.BigDecimal discrepancyHuf, String explanation, ClosingTolerance tolerance) {
        if (discrepancyHuf == null) {
            return null;
        }
        if (!tolerance.blocks(discrepancyHuf)) {
            return null;
        }
        if (explanation != null && !explanation.isBlank()) {
            return null;
        }
        // FR-7: pénznem + alkalmazott tolerancia az üzenetben.
        return String.format(
                "Pénzügyi eltérés (HUF: %s Ft, tolerancia: %s Ft) — a zárás véglegesítéséhez eltérés-magyarázat kötelező (FR-13).",
                discrepancyHuf.toPlainString(), tolerance.value().toPlainString());
    }

    /**
     * FK-063 FR-4: pénznemenkénti eltérés-gate döntés — legacy overload rögzített
     * HUF-toleranciával. FK-066: fallback-szemantikával delegál (HUF: {@code |diff| >
     * tolerancia} blokkol; nem-HUF: bármilyen nem-nulla eltérés blokkol) — a
     * paraméter-vezérelt viselkedés változatlan.
     */
    static String perCurrencyDiscrepancyBlockReason(
            Map<String, java.math.BigDecimal> perCurrencyDiscrepancies,
            String explanation,
            java.math.BigDecimal hufToleranceHuf) {
        return perCurrencyDiscrepancyBlockReason(perCurrencyDiscrepancies, explanation,
                code -> "HUF".equals(code)
                        ? ClosingTolerance.fallbackOf(hufToleranceHuf)
                        : ClosingTolerance.fallbackOf(java.math.BigDecimal.ZERO));
    }

    /**
     * FK-063 FR-4 + FK-066: pénznemenkénti eltérés-gate döntés a pénztári (nem-vault)
     * ágra — statikus, függőség-mentes (tesztelhető). A toleranciát pénznemenként a
     * {@code toleranceOf} adja (éles hívásnál {@code ClosingToleranceService::getToleranceFor}),
     * a blokkolási döntés (explicit {@code >=}, fallback {@code >}, nulla eltérés soha)
     * KIZÁRÓLAG a {@link ClosingTolerance#blocks} közös pontjában dől el (FR-6).
     * A blokkoló üzenet nevesíti az érintett pénznem(ek)et, eltérésüket és az
     * alkalmazott toleranciát (FR-7).
     *
     * @return blokkoló indok, ha van blokkoló eltérés ÉS nincs magyarázat;
     *         különben {@code null}
     */
    static String perCurrencyDiscrepancyBlockReason(
            Map<String, java.math.BigDecimal> perCurrencyDiscrepancies,
            String explanation,
            java.util.function.Function<String, ClosingTolerance> toleranceOf) {
        if (perCurrencyDiscrepancies == null || perCurrencyDiscrepancies.isEmpty()) {
            return null;
        }
        List<String> blocking = new ArrayList<>();
        for (Map.Entry<String, java.math.BigDecimal> entry : perCurrencyDiscrepancies.entrySet()) {
            java.math.BigDecimal diff = entry.getValue();
            ClosingTolerance tolerance = toleranceOf.apply(entry.getKey());
            if (!tolerance.blocks(diff)) {
                continue;
            }
            // FR-7: pénznem + eltérés + alkalmazott tolerancia.
            blocking.add(entry.getKey() + ": " + diff.toPlainString()
                    + " (tolerancia: " + tolerance.value().toPlainString() + ")");
        }
        if (blocking.isEmpty()) {
            return null;
        }
        if (explanation != null && !explanation.isBlank()) {
            return null;
        }
        return String.format(
                "Pénznemenkénti pénzügyi eltérés (%s) — a zárás véglegesítéséhez eltérés-magyarázat kötelező (FR-13).",
                String.join("; ", blocking));
    }

    @Transactional(readOnly = true)
    public ClosingWizardStatusDto getClosingStatus(UUID branchId, LocalDate date) {
        Branch branch = findBranchInCurrentCompany(branchId);
        boolean denominationRecorded = denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                branchId, date, DenominationCategory.EVENING);
        List<Map<String, Object>> differences = calculateDifferences(branchId, loadPhysicalCounts(branchId, date));
        boolean exactMatch = denominationRecorded && differences.stream()
                .allMatch(item -> "OK".equals(String.valueOf(item.get("status"))));

        String message;
        if (!denominationRecorded) {
            message = "Nincs rogzitett esti cimletezes erre a napra.";
        } else if (!exactMatch) {
            message = isVaultContext(branch)
                    ? "Az esti zaras csak a valutankenti cimletezes es a currency_stock teljes egyezese utan kuldheto."
                    : "Eltérés van a címletezés és a nyilvántartás között.";
        } else {
            message = "A zárási címletezés pontosan egyezik a nyilvántartással.";
        }

        // FK-065 FR-2 (egyhívásos FR-3): a napra vonatkozó beragadt/aktív wizard jelzése —
        // mai IN_PROGRESS elsőbbség, EXPIRED-fallback, különben mindkettő null. A frontend
        // ebből dönt (Folytatás / Új zárás indítása), külön get() hívás nélkül.
        String activeWizardId = null;
        String activeWizardStatus = null;
        List<ClosingWizard> activeToday = closingWizardRepository
                .findByBranchIdAndStatusAndClosingDate(branchId, WizardStatus.IN_PROGRESS, date);
        if (!activeToday.isEmpty()) {
            activeWizardId = activeToday.get(0).getId().toString();
            activeWizardStatus = WizardStatus.IN_PROGRESS.name();
        } else {
            List<ClosingWizard> expiredToday = closingWizardRepository
                    .findByBranchIdAndStatusAndClosingDate(branchId, WizardStatus.EXPIRED, date);
            if (!expiredToday.isEmpty()) {
                activeWizardId = expiredToday.get(0).getId().toString();
                activeWizardStatus = WizardStatus.EXPIRED.name();
            }
        }

        return ClosingWizardStatusDto.builder()
                .branchId(branchId.toString())
                .closingDate(date.toString())
                .vaultContext(isVaultContext(branch))
                .denominationRecorded(denominationRecorded)
                .exactMatch(exactMatch)
                .message(message)
                .differences(differences)
                .activeWizardId(activeWizardId)
                .activeWizardStatus(activeWizardStatus)
                .build();
    }

    public void ensureClosingCanBeSent(UUID branchId, LocalDate date) {
        Branch branch = findBranchInCurrentCompany(branchId);
        if (!isVaultContext(branch)) {
            return;
        }
        ClosingWizardStatusDto status = getClosingStatus(branchId, date);
        if (!status.isExactMatch()) {
            throw new ValidationException(status.getMessage());
        }
    }

    // ============ HELPER METHODS ============

    /**
     * Lépésszám a legacy 16 lépéses struktúra alapján (típusfüggő szűréssel).
     * Legacy: NAPZAR.DLL + CHECKLST.DLL — 16 lépés, de nem mindegyik aktív minden típusnál.
     * @see ClosingWizardSteps
     */
    private int getStepCount(ClosingType type) {
        return ClosingWizardSteps.getStepCountForType(type.name());
    }

    /**
     * Lépések létrehozása a legacy 16 lépéses struktúra alapján (típusfüggő szűréssel).
     * Az adott zárástípusra nem vonatkozó lépések kihagyásra kerülnek.
     * @see ClosingWizardSteps
     */
    private List<ClosingWizardStep> createStepsForType(ClosingType type, ClosingWizard wizard) {
        List<ClosingWizardSteps.StepDefinition> applicableSteps =
            ClosingWizardSteps.getStepsForType(type.name());

        List<ClosingWizardStep> steps = new ArrayList<>();
        for (int i = 0; i < applicableSteps.size(); i++) {
            ClosingWizardSteps.StepDefinition def = applicableSteps.get(i);
            steps.add(ClosingWizardStep.builder()
                    .wizard(wizard)
                    .stepNumber(i + 1)
                    .stepTitle(def.stepName())
                    .stepDescription(def.description())
                    .completed(false)
                    .canProceed(true)
                    .stepData(String.format("{\"legacyStepNumber\":%d}", def.stepNumber()))
                    .build());
        }
        return steps;
    }

    private ClosingWizardDto toDto(ClosingWizard entity) {
        return ClosingWizardDto.builder()
                .id(entity.getId().toString())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .cashDeskId(entity.getCashDeskId() != null ? entity.getCashDeskId().toString() : null)
                .closingDate(entity.getClosingDate().toString())
                .closingType(entity.getClosingType().name())
                .currentStep(entity.getCurrentStep())
                .totalSteps(entity.getTotalSteps())
                .wizardStatus(entity.getWizardStatus().name())
                .startedByWorkerId(String.valueOf(entity.getStartedByWorker().getId()))
                .startedByWorkerName(entity.getStartedByWorker().getName())
                .startedAt(entity.getStartedAt())
                .completedByWorkerId(entity.getCompletedByWorker() != null ? String.valueOf(entity.getCompletedByWorker().getId()) : null)
                .completedByWorkerName(entity.getCompletedByWorker() != null ? entity.getCompletedByWorker().getName() : null)
                .completedAt(entity.getCompletedAt())
                .notes(entity.getNotes())
                .steps(entity.getSteps() != null
                    ? entity.getSteps().stream().map(this::toStepDto).collect(Collectors.toList())
                    : null)
                .build();
    }

    private ClosingWizardStepDto toStepDto(ClosingWizardStep step) {
        Map<String, Object> stepDataMap = new HashMap<>();
        if (step.getStepData() != null && !step.getStepData().isBlank()) {
            try {
                stepDataMap = objectMapper.readValue(step.getStepData(), new TypeReference<>() {});
            } catch (JacksonException e) {
                log.warn("Nem sikerült parse-olni a stepData-t: {}", step.getStepData());
            }
        }

        return ClosingWizardStepDto.builder()
                .stepNumber(step.getStepNumber())
                .stepTitle(step.getStepTitle())
                .stepDescription(step.getStepDescription())
                .completed(step.getCompleted())
                .canProceed(step.getCanProceed())
                .stepData(stepDataMap)
                .build();
    }

    private Map<String, BigDecimal> loadPhysicalCounts(UUID branchId, LocalDate date) {
        Map<String, BigDecimal> counts = new LinkedHashMap<>();
        for (Object[] row : denominationBalanceRepository.sumActualStockByCurrency(
                branchId, date, DenominationCategory.EVENING)) {
            if (row.length >= 2 && row[0] instanceof String code && row[1] instanceof BigDecimal total) {
                counts.put(code, total);
            }
        }
        return counts;
    }

    private Map<String, Object> differenceItem(String code, BigDecimal expected, BigDecimal actual) {
        BigDecimal diff = actual.subtract(expected);
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("currencyCode", code);
        item.put("expected", expected);
        item.put("actual", actual);
        item.put("difference", diff);
        item.put("status", diff.compareTo(BigDecimal.ZERO) == 0 ? "OK" : "DISCREPANCY");
        return item;
    }

    private boolean isVaultContext(Branch branch) {
        return branch != null && Boolean.TRUE.equals(branch.getIsVault());
    }

    private String resolveVaultEntityId(Branch branch) {
        if (branch == null || branch.getVaultTerritoryId() == null) {
            throw new ValidationException("Az ertektari branchhez nincs vault_territory_id rendelve.");
        }
        return branch.getVaultTerritoryId().toString();
    }
}
