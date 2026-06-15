package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStepDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
    private final SystemParameterService systemParameterService;

    /** G3: a zárás-eltérés magyarázat-kötelezettség feature-flag SystemParameter kulcsa. */
    static final String CLOSING_DISCREPANCY_PARAM = "CLOSING_DISCREPANCY_EXPLANATION_REQUIRED";
    /** G3: az eltérés-tolerancia (Ft) — ezalatt nincs magyarázat-kötelezettség (kerekítés). */
    private static final java.math.BigDecimal DISCREPANCY_TOLERANCE_HUF = java.math.BigDecimal.ONE;

    /**
     * Zárási varázsló indítása
     */
    public ClosingWizardDto startWizard(UUID branchId, UUID cashDeskId, String closingTypeStr, Long workerId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        // Ellenőrzés: nincs-e már aktív varázsló
        List<ClosingWizard> activeWizards = closingWizardRepository.findByBranchIdAndStatus(branchId, WizardStatus.IN_PROGRESS);
        if (!activeWizards.isEmpty()) {
            throw new ValidationException("Már van aktív zárási varázsló ehhez az irodához!");
        }

        ClosingType closingType = ClosingType.valueOf(closingTypeStr);
        int totalSteps = getStepCount(closingType);

        ClosingWizard wizard = ClosingWizard.builder()
                .branch(branch)
                .cashDeskId(cashDeskId)
                .closingDate(LocalDate.now())
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

        ClosingWizard saved = closingWizardRepository.save(wizard);

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

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

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

        ClosingWizard saved = closingWizardRepository.save(wizard);
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
        ClosingWizard saved = closingWizardRepository.save(wizard);
        log.info("Zárási varázsló megszakítva: id={}", wizardId);

        return toDto(saved);
    }

    // ============ STEP-SPECIFIC METHODS ============

    /**
     * Step 1: Nyitott tranzakciók validálása.
     * Visszaadja a befejezetlen tranzakciók listáját.
     */
    @Transactional(readOnly = true)
    public List<String> validateOpenTransactions(UUID branchId) {
        List<String> errors = new ArrayList<>();

        // Ellenőrzés: van-e nyitott session
        if (!dailySessionRepository.hasOpenSession(branchId)) {
            errors.add("Nincs nyitott napi munkamenet!");
            return errors;
        }

        // Aktuális session lekérése
        DailySession currentSession = dailySessionRepository.findLatest(branchId)
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
     * igy a checkEveningDenomination a existsByBranchIdAndDate es sumDenominatedAmount
     * query-kkel megtalalja azokat.
     */
    public Map<String, Object> countDenominations(UUID branchId, Map<String, Map<Integer, Integer>> denomCounts) {
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
                BigDecimal subtotal = BigDecimal.valueOf(value).multiply(BigDecimal.valueOf(count));
                total = total.add(subtotal);

                denomDetails.add(Map.of(
                        "value", value,
                        "count", count,
                        "subtotal", subtotal
                ));

                // Issue #117: persist DenominationBalance rekordot
                saveDenominationBalance(branchId, currency, BigDecimal.valueOf(value), count, subtotal);
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
    private void saveDenominationBalance(UUID branchId, hu.puzzleir.valuta.entity.Currency currency, BigDecimal faceValue, int quantity, BigDecimal subtotal) {
        Denomination denomination = denominationRepository
                .findByBranchIdAndCurrencyIdAndFaceValue(branchId, currency.getId(), faceValue)
                .orElseGet(() -> {
                    Branch branch = branchRepository.findById(branchId)
                            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));
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
        denominationBalanceRepository.save(balance);
    }

    /**
     * Step 3: Eltérés számítás — nyilvántartás vs fizikai készlet.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> calculateDifferences(UUID branchId, Map<String, BigDecimal> physicalCounts) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Map<String, Object>> differences = new ArrayList<>();

        for (CashBalance cb : balances) {
            String code = cb.getCurrency().getCode();
            BigDecimal expected = cb.getCurrentBalance();
            BigDecimal actual = physicalCounts.getOrDefault(code, BigDecimal.ZERO);
            BigDecimal diff = actual.subtract(expected);

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode", code);
            item.put("expected", expected);
            item.put("actual", actual);
            item.put("difference", diff);
            item.put("status", diff.compareTo(BigDecimal.ZERO) == 0 ? "OK" : "DISCREPANCY");

            differences.add(item);
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
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, LocalDate.now())
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
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Map<String, Object>> inventorySnapshot = new ArrayList<>();
        for (CashBalance cb : balances) {
            inventorySnapshot.add(Map.of(
                    "currencyCode", cb.getCurrency().getCode(),
                    "openingBalance", cb.getOpeningBalance(),
                    "currentBalance", cb.getCurrentBalance(),
                    "dailyChange", cb.getDailyChange()
            ));
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

        // G3 (FR-13): eltérés-magyarázat gate a véglegesítés előtt.
        java.math.BigDecimal discrepancy = computeCashDiscrepancy(wizard.getBranch() != null ? wizard.getBranch().getId() : null, closingDate);
        wizard.setDiscrepancyAmount(discrepancy);
        if (discrepancyExplanation != null && !discrepancyExplanation.isBlank()) {
            wizard.setDiscrepancyExplanation(discrepancyExplanation.trim());
        }
        boolean enforce = systemParameterService != null
                && "true".equalsIgnoreCase(systemParameterService.getValue(CLOSING_DISCREPANCY_PARAM, "false"));
        if (enforce) {
            String blockReason = closingDiscrepancyBlockReason(
                    discrepancy, wizard.getDiscrepancyExplanation(), DISCREPANCY_TOLERANCE_HUF);
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

        // Wizard lezárása
        wizard.setWizardStatus(WizardStatus.COMPLETED);
        wizard.setCompletedByWorker(worker);
        wizard.setCompletedAt(LocalDateTime.now());
        closingWizardRepository.save(wizard);

        log.info("Zárás véglegesítve: wizard={}, closingDate={}", wizardId, closingDate);

        return true;
    }

    /**
     * G3 (FR-13): a pénzügyi eltérés (címletezett − várt készlet) kiszámítása a
     * zárás napjára. {@code null} csak akkor, ha a branchId null; a repó query-k
     * COALESCE-olnak 0-ra, így hiányzó adatnál az eltérés 0 (toleranciaon belül).
     */
    private java.math.BigDecimal computeCashDiscrepancy(UUID branchId, LocalDate date) {
        if (branchId == null) {
            return null;
        }
        java.math.BigDecimal denominated = denominationBalanceRepository.sumDenominatedAmount(branchId, date, "EVENING");
        java.math.BigDecimal expected = cashBalanceRepository.sumCurrentBalanceHuf(branchId);
        if (denominated == null || expected == null) {
            return null;
        }
        return denominated.subtract(expected);
    }

    /**
     * G3 (FR-13) eltérés-gate döntés — statikus, függőség-mentes (tesztelhető).
     *
     * @return blokkoló indok, ha (az eltérés meghaladja a toleranciát ÉS nincs
     *         magyarázat); {@code null}, ha nincs eltérés / toleranciaon belül /
     *         van magyarázat / nem dönthető el (null eltérés)
     */
    static String closingDiscrepancyBlockReason(
            java.math.BigDecimal discrepancyHuf, String explanation, java.math.BigDecimal toleranceHuf) {
        if (discrepancyHuf == null) {
            return null;
        }
        if (discrepancyHuf.abs().compareTo(toleranceHuf) <= 0) {
            return null;
        }
        if (explanation != null && !explanation.isBlank()) {
            return null;
        }
        return String.format(
                "Pénzügyi eltérés (%s Ft) — a zárás véglegesítéséhez eltérés-magyarázat kötelező (FR-13).",
                discrepancyHuf.toPlainString());
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
            } catch (JsonProcessingException e) {
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
}
