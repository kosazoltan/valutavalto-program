package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Napzarasi szolgaltatas — belső ellenőrzési lánc (9 technikai lépés).
 *
 * Legacy: NAPZAR.DLL + CHECKLST.DLL + CIMLCTRL.DLL + CIMLMENU.DLL + DEKAD.DLL
 *
 * FONTOS: Ez a szolgáltatás a belső (backend) ellenőrzési lépéseket hajtja végre.
 * A felhasználói 16 lépéses zárási varázsló a {@link ClosingWizardSteps} osztályban
 * és a {@link ClosingWizardService}-ben van definiálva.
 *
 * Belső ellenőrzési lépések (a legacy 9 lépéses CIMLCTRL szekvencia):
 * 1. MTCN szam ellenorzes (Western Union)
 * 2. Esti cimletez es ellenorzes
 * 3. Kezelesi dij cimletez es
 * 4. Western Union cimletez es
 * 5. AFA cimletez es (Metro/Tesco)
 * 6. Foglalo cimletez es
 * 7. E-kereskedelem cimletez es
 * 8. AXA + MoneyGram cimletez es
 * 9. NAV kontroll + QR + dekad + havi gyujto + napi jelentes
 *
 * Minden lepes PASS/FAIL — ha FAIL, nem mehet tovabb.
 * A rendszer CSAK akkor zarhat napot, ha minden lepes PASS.
 *
 * @see ClosingWizardSteps a teljes 16 lépéses legacy varázsló struktúra
 * @see ClosingWizardService a varázsló felhasználói felületének szolgáltatása
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DailyClosingService {

    // V234 strukturalt error code log (PR #682 phase 2)
    private static final VVLogger VV_LOG = VVLogger.of(DailyClosingService.class);

    private final DailySessionService dailySessionService;
    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final ClosingWizardRepository closingWizardRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final SystemParameterService systemParameterService;
    private final AuditLogService auditLogService;
    private final DailyBalanceService dailyBalanceService;
    private final PosTerminalService posTerminalService;
    private final PosTerminalRepository posTerminalRepository;
    private final EveningClosingService eveningClosingService;
    private final MonthlyArchiveService monthlyArchiveService;
    private final DailyClosingArchiveService dailyClosingArchiveService;
    private final DecadeReportService decadeReportService;
    private final AmlService amlService;
    private final ReceiptSequenceService receiptSequenceService;
    private final ClosingControlService closingControlService;
    private final BranchRepository branchRepository;
    /** FK-066: pénznemenkénti zárás-tolerancia közös forrása (FR-6) — a kemény kapu ebből olvas. */
    private final ClosingToleranceService closingToleranceService;

    @Value("${nav.bridge.simulated-success-enabled:false}")
    private boolean navBridgeSimulatedSuccessEnabled;

    /** Max lep esek szama */
    private static final int TOTAL_STEPS = 9;

    /**
     * Napzaras inditasa — letrehozza a wizard-ot es elinditja az ellenorzeseket.
     */
    public ClosingWizardResult startDailyClosing(LocalDate closingDate) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Validacio: van nyitott nap?
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet!");
        }

        log.info("Napzaras inditasa: datum={}, iroda={}", closingDate, branchId);

        // Wizard letrehozasa
        Branch branch = new hu.puzzleir.valuta.entity.Branch();
        branch.setId(branchId);
        Worker worker = new Worker();
        worker.setId(SecurityUtils.getCurrentWorkerId());

        ClosingWizard wizard = ClosingWizard.builder()
            .branch(branch)
            .closingDate(closingDate)
            .closingType(ClosingType.DAILY)
            .wizardStatus(WizardStatus.IN_PROGRESS)
            .totalSteps(TOTAL_STEPS)
            .startedByWorker(worker)
            .startedAt(LocalDateTime.now())
            .build();
        wizard = closingWizardRepository.save(wizard);

        // Lepes ek futtatasa sorrendben
        List<ClosingStepResult> stepResults = new ArrayList<>();

        stepResults.add(runStep(1, "MTCN szam ellenorzes", () -> checkMtcnNumbers(branchId, closingDate)));
        stepResults.add(runStep(2, "Esti penztarallag cimletezese", () -> checkEveningDenomination(companyId, branchId, closingDate)));
        stepResults.add(runStep(3, "Kezelesi dij cimletezese", () -> checkHandlingFeeDenomination(branchId, closingDate)));
        stepResults.add(runStep(4, "Western Union cimletezese", () -> checkWesternUnionDenomination(branchId, closingDate)));
        stepResults.add(runStep(5, "AFA cimletezese", () -> checkVatDenomination(branchId, closingDate)));
        stepResults.add(runStep(6, "Foglalo cimletezese", () -> checkDepositDenomination(branchId, closingDate)));
        stepResults.add(runStep(7, "E-kereskedelem cimletezese", () -> checkEcommerceDenomination(branchId, closingDate)));
        stepResults.add(runStep(8, "Egyeb cimletezesek (AXA/MoneyGram)", () -> checkOtherDenominations(branchId, closingDate)));
        stepResults.add(runStep(9, "NAV kontroll es napi jelentes", () -> checkNavControlAndReport(branchId, closingDate)));

        // Eredmeny osszesites
        boolean allPassed = stepResults.stream().allMatch(ClosingStepResult::isPassed);

        List<ClosingWarning> warnings = new ArrayList<>();

        if (allPassed) {
            // Napzaras vegrehajtasa
            executeClosing(branchId, companyId, closingDate, warnings);
            closingControlService.markClosingDone(companyId, branchId, closingDate, ClosingMarkType.DAILY);
            wizard.setWizardStatus(WizardStatus.COMPLETED);
            wizard.setCompletedAt(LocalDateTime.now());
            log.info("Napzaras SIKERES: datum={}, iroda={}", closingDate, branchId);
        } else {
            wizard.setWizardStatus(WizardStatus.FAILED);
            log.warn("Napzaras SIKERTELEN - nem minden lepes PASS");
        }

        closingWizardRepository.save(wizard);

        return ClosingWizardResult.builder()
            .wizardId(wizard.getId().toString())
            .closingDate(closingDate)
            .allPassed(allPassed)
            .steps(stepResults)
            .warnings(warnings)
            .build();
    }

    /**
     * Egyes lepes futtatasa.
     */
    private ClosingStepResult runStep(int stepNumber, String stepName, StepCheck check) {
        try {
            StepCheckResult checkResult = check.execute();
            boolean passed = checkResult.isPassed();

            log.info("Napzaras lepes {}/{}: {} - {}", stepNumber, TOTAL_STEPS, stepName,
                passed ? "RENDBEN" : "HIBA: " + checkResult.getMessage());

            return ClosingStepResult.builder()
                .stepNumber(stepNumber)
                .stepName(stepName)
                .passed(passed)
                .message(checkResult.getMessage())
                .skipped(checkResult.isSkipped())
                .build();
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-006", "daily_closing.step_failed", e,
                    java.util.Map.of("step_number", stepNumber));
            return ClosingStepResult.builder()
                .stepNumber(stepNumber)
                .stepName(stepName)
                .passed(false)
                .message("Rendszerhiba: " + e.getMessage())
                .build();
        }
    }

    /**
     * Egy adott lepes ellenorzeset futtatja — a ClosingWizardService hivja navigate()-bol.
     * Igy a wizard UI egyenkent tudja futtatni es megjeleníteni az ellenorzeseket.
     */
    public StepCheckResult executeStepCheck(int stepNumber, UUID branchId, LocalDate closingDate) {
        return switch (stepNumber) {
            case 1 -> checkMtcnNumbers(branchId, closingDate);
            case 2 -> checkEveningDenomination(SecurityUtils.getCurrentCompanyId(), branchId, closingDate);
            case 3 -> checkHandlingFeeDenomination(branchId, closingDate);
            case 4 -> checkWesternUnionDenomination(branchId, closingDate);
            case 5 -> checkVatDenomination(branchId, closingDate);
            case 6 -> checkDepositDenomination(branchId, closingDate);
            case 7 -> checkEcommerceDenomination(branchId, closingDate);
            case 8 -> checkOtherDenominations(branchId, closingDate);
            case 9 -> checkNavControlAndReport(branchId, closingDate);
            default -> StepCheckResult.failed("Ismeretlen lepes szam: " + stepNumber);
        };
    }

    // ============ ELLENORZESI LEPESEK ============

    /**
     * 1. MTCN szam ellenorzes (Western Union bizonylatok).
     * Legacy: MTCNControl - megkeresi az osszes WU bizonylat at es ellenorzi hogy van-e MTCN szam.
     */
    private StepCheckResult checkMtcnNumbers(UUID branchId, LocalDate date) {
        // Western Union tranzakciok keresese (MTCN szam nelkul)
        List<Transaction> wuTransactions = transactionRepository
            .findByBranchIdAndTransactionDateAndMtcnIsNull(branchId, date, "WU%");

        // Ha nincs WU modullunk, skip
        boolean hasWesternUnion = hasFeature(branchId, "WESTERN_UNION");
        if (!hasWesternUnion) {
            return StepCheckResult.skipped("Western Union nem aktiv ezen az irodan");
        }

        if (!wuTransactions.isEmpty()) {
            return StepCheckResult.failed(
                wuTransactions.size() + " Western Union bizonylaton hianyzik az MTCN szam!");
        }

        return StepCheckResult.passed("Minden MTCN szam kitoltve");
    }

    /**
     * 2. Esti penztar cimletezese.
     * Legacy: cimletsorszam=1, cimletctrlrutin - osszeveti a valos penzt a szamitott keszlettel.
     */
    private StepCheckResult checkEveningDenomination(UUID companyId, UUID branchId, LocalDate date) {
        // FK-061 FR-2: vault-kontextusban (értéktári branch) ez a HUF-only lépés kihagyandó —
        // az értéktári véglegesítés kizárólag a valutánkénti currency_stock-alapú
        // ellenőrzésre támaszkodik (VaultClosing). A pénztári (nem-vault) viselkedés változatlan.
        if (isVaultBranch(branchId)) {
            log.info("FK-061: checkEveningDenomination kihagyva vault-kontextusban: branch={}, datum={}",
                branchId, date);
            auditLogService.log("EVENING_DENOMINATION_CHECK_SKIPPED_VAULT",
                "Esti cimletezes-ellenorzes (HUF-only) kihagyva vault-kontextusban; "
                    + "a veglegesites a valutankenti currency_stock ellenorzesre tamaszkodik. "
                    + "{\"branchId\":\"" + branchId + "\",\"date\":\"" + date + "\"}",
                branchId.toString());
            return StepCheckResult.skipped("Esti cimletezes-ellenorzes kihagyva (ertektar)");
        }

        // Ellenorzi hogy a cimletezett osszeg egyezik-e a szamitott keszlettel
        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndCategory(branchId, date, DenominationCategory.EVENING);

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik az esti penztar cimletezese!");
        }

        // FK-063 FR-5/FR-6: pénznemenkénti összevetés a pénztári ágon (nem HUF-only).
        // Becímletezett (EVENING, valutánként) vs. nyilvántartott cash_balance egyenleg.
        Map<String, BigDecimal> denominatedByCurrency = new LinkedHashMap<>();
        for (Object[] row : denominationBalanceRepository.sumActualStockByCurrency(
                branchId, date, DenominationCategory.EVENING)) {
            if (row.length >= 2 && row[0] instanceof String code && row[1] instanceof BigDecimal total) {
                denominatedByCurrency.put(code, total);
            }
        }
        Map<String, BigDecimal> expectedByCurrency = new LinkedHashMap<>();
        for (CashBalance cb : cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId)) {
            expectedByCurrency.put(cb.getCurrency().getCode(), cb.getCurrentBalance());
        }

        Set<String> codes = new LinkedHashSet<>(expectedByCurrency.keySet());
        codes.addAll(denominatedByCurrency.keySet());

        // Sourcery review (PR #1483): üres adathalmaz nem mehet át csendben "rendben"-ként —
        // ha sem becímletezett, sem nyilvántartott adat nincs, az adat-/konfigurációs hiba.
        if (codes.isEmpty()) {
            return StepCheckResult.failed("Nem lehet ellenorizni a cimletezest (hianyznak adatok)");
        }

        List<String> mismatches = new ArrayList<>();
        for (String code : codes) {
            BigDecimal denominated = denominatedByCurrency.getOrDefault(code, BigDecimal.ZERO);
            BigDecimal expected = expectedByCurrency.getOrDefault(code, BigDecimal.ZERO);
            BigDecimal diff = denominated.subtract(expected);
            // FK-066 (FR-2/FR-6): a tolerancia és az ág-függő operátor (explicit >=,
            // fallback >) KIZÁRÓLAG a közös ClosingTolerance.blocks()-ban dől el.
            ClosingTolerance tolerance = closingToleranceService.getToleranceFor(code);
            if (tolerance.blocks(diff)) {
                // FR-7: a hibaüzenet nevesíti a pénznemet ÉS az alkalmazott toleranciát.
                mismatches.add(String.format("%s: ciml=%s, vart=%s, tolerancia=%s",
                    code, denominated.toPlainString(), expected.toPlainString(),
                    tolerance.value().toPlainString()));
            }
        }

        if (!mismatches.isEmpty()) {
            return StepCheckResult.failed(
                "Cimletezesi elteres penznemenkent — " + String.join("; ", mismatches));
        }

        return StepCheckResult.passed("Esti cimletez es rendben (penznemenkent egyezik)");
    }

    /**
     * 3. Kezelesi dij cimletezese.
     * Legacy: cimletsorszam=2
     */
    private StepCheckResult checkHandlingFeeDenomination(UUID branchId, LocalDate date) {
        BigDecimal totalHandlingFees = transactionRepository
            .sumDailyHandlingFees(branchId, date);

        if (totalHandlingFees == null || totalHandlingFees.compareTo(BigDecimal.ZERO) == 0) {
            return StepCheckResult.skipped("Nem volt kezelesi dij ma");
        }

        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndType(branchId, date, "HANDLING_FEE");

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik a kezelesi dij cimletezese!");
        }

        return StepCheckResult.passed("Kezelesi dij cimletezes rendben");
    }

    /**
     * 4. Western Union cimletezese.
     */
    private StepCheckResult checkWesternUnionDenomination(UUID branchId, LocalDate date) {
        boolean hasWesternUnion = hasFeature(branchId, "WESTERN_UNION");
        if (!hasWesternUnion) {
            return StepCheckResult.skipped("Western Union nem aktiv");
        }

        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndType(branchId, date, "WESTERN_UNION");

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik a Western Union cimletezese!");
        }

        return StepCheckResult.passed("Western Union cimletezes rendben");
    }

    /**
     * 5. AFA cimletezese (Metro/Tesco afas termekek).
     */
    private StepCheckResult checkVatDenomination(UUID branchId, LocalDate date) {
        boolean hasVat = hasFeature(branchId, "VAT_PRODUCTS");
        if (!hasVat) {
            return StepCheckResult.skipped("AFA-s termek ertekesites nem aktiv");
        }

        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndType(branchId, date, "VAT");

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik az AFA cimletezese!");
        }

        return StepCheckResult.passed("AFA cimletezes rendben");
    }

    /**
     * 6. Foglalo cimletezese.
     */
    private StepCheckResult checkDepositDenomination(UUID branchId, LocalDate date) {
        boolean hasDeposit = hasFeature(branchId, "DEPOSITS");
        if (!hasDeposit) {
            return StepCheckResult.skipped("Foglalo nem aktiv");
        }

        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndType(branchId, date, "DEPOSIT");

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik a foglalo cimletezese!");
        }

        return StepCheckResult.passed("Foglalo cimletezes rendben");
    }

    /**
     * 7. E-kereskedelem cimletezese.
     */
    private StepCheckResult checkEcommerceDenomination(UUID branchId, LocalDate date) {
        boolean hasEcommerce = hasFeature(branchId, "ECOMMERCE");
        if (!hasEcommerce) {
            return StepCheckResult.skipped("E-kereskedelem nem aktiv");
        }

        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDateAndType(branchId, date, "ECOMMERCE");

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik az e-kereskedelem cimletezese!");
        }

        return StepCheckResult.passed("E-kereskedelem cimletezes rendben");
    }

    /**
     * 8. Egyeb cimletezesek (AXA, MoneyGram stb.).
     */
    private StepCheckResult checkOtherDenominations(UUID branchId, LocalDate date) {
        // Egyeb partneri cimletezesek osszesitett ellenorzese
        boolean hasAxa = hasFeature(branchId, "AXA");
        boolean hasMoneyGram = hasFeature(branchId, "MONEYGRAM");

        if (!hasAxa && !hasMoneyGram) {
            return StepCheckResult.skipped("Nincs egyeb partner");
        }

        // AXA
        if (hasAxa) {
            boolean hasDenom = denominationBalanceRepository
                .existsByBranchIdAndDateAndType(branchId, date, "AXA");
            if (!hasDenom) {
                return StepCheckResult.failed("Hianyzik az AXA cimletezese!");
            }
        }

        // MoneyGram
        if (hasMoneyGram) {
            boolean hasDenom = denominationBalanceRepository
                .existsByBranchIdAndDateAndType(branchId, date, "MONEYGRAM");
            if (!hasDenom) {
                return StepCheckResult.failed("Hianyzik a MoneyGram cimletezese!");
            }
        }

        return StepCheckResult.passed("Egyeb cimletezesek rendben");
    }

    /**
     * 9. NAV kontroll + napi jelentes + dekad + havi gyujtobe masolas.
     *
     * Legacy: navzarocontrol + napijelrutin + DekzarCtrl + napzarnyomtatorutin
     */
    private StepCheckResult checkNavControlAndReport(UUID branchId, LocalDate date) {
        // Issue #120: ha nincs NAV integracio a branch-en, SKIP (ne blokkolja a napzarast).
        // A meglevo checkUnreportedTransactions query a printed=false flag-et nezi, ami valojaban
        // NEM a NAV-jelentes allapota. Amig nincs valodi nav_report integracio,
        // a hasFeature check szerint az egesz step kihagyhato.
        if (!hasFeature(branchId, "NAV_INTEGRATION")) {
            return StepCheckResult.skipped("NAV integracio nem aktiv ezen az irodan");
        }

        if (!navBridgeSimulatedSuccessEnabled) {
            return StepCheckResult.failed(
                    "NAV integracio aktiv, de nincs eles NAV jelentes-visszaigazolas; "
                            + "a bridge szimulacio nem zarhat napot production modban");
        }

        // NAV: ellenorizzuk hogy minden tranzakcio jelentve van-e
        long unreportedCount = transactionRepository.countUnreportedTransactions(branchId, date);
        if (unreportedCount > 0) {
            return StepCheckResult.failed(unreportedCount + " nem jelentett tranzakcio van!");
        }

        return StepCheckResult.passed("NAV kontroll es jelentes rendben");
    }

    // ============ NAPZARAS VEGREHAJTASA ============

    /**
     * A tenyleges napzaras (miutan minden ellenorzes PASS).
     *
     * Legacy: HARDWARE.LEZARTNAP = aktualis datum
     *         + havi gyujtok feltoltese
     *         + napi arfolyamtablak rogzitese
     *         + ugyfel napi gyujtok nullazasa
     */
    private void executeClosing(UUID branchId, UUID companyId, LocalDate closingDate, List<ClosingWarning> warnings) {
        log.info("Napzaras vegrehajtasa: datum={}", closingDate);

        // 0. Bizonylat folytonossági ellenőrzés (gap detektálás) — MUNKAMENET ZÁRÁS ELŐTT
        try {
            List<String> gaps = receiptSequenceService.checkReceiptContinuity(branchId, closingDate);
            if (!gaps.isEmpty()) {
                String gapList = String.join(", ", gaps.subList(0, Math.min(gaps.size(), 10)));
                auditLogService.log(
                    "RECEIPT_GAP_DETECTED",
                    "DailyClosing",
                    branchId.toString(),
                    SecurityUtils.getCurrentWorkerId() != null ? SecurityUtils.getCurrentWorkerId().toString() : null,
                    null,
                    branchId.toString(),
                    null,
                    String.format("{\"date\":\"%s\",\"gapCount\":%d,\"gaps\":\"%s%s\"}",
                        closingDate, gaps.size(), gapList, gaps.size() > 10 ? "..." : ""),
                    null,
                    null
                );
                log.warn("Bizonylat gap detektálva napzáráskor: datum={}, iroda={}, {} hiányzó bizonylat",
                    closingDate, branchId, gaps.size());
            }
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-006", "daily_closing.receipt_gap_check_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "step", "receipt_gap_check"));
            warnings.add(ClosingWarning.builder()
                    .step("receipt_gap_check")
                    .message("Bizonylat folytonossági ellenőrzés hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }

        // 1. Napi arfolyamok rogzitese (snapshot a zaraskor ervenyes arfolyamokrol)
        snapshotDailyRates(companyId, closingDate);

        // 2. Napi munkamenet lezarasa
        dailySessionService.closeSession(closingDate);

        // 3. Napi mérleg számítása (MODERN KIEGÉSZÍTÉS — Delphi napi forgalom számítás)
        try {
            dailyBalanceService.calculateAllCurrenciesForDay(branchId, closingDate);
            log.info("Napi mérleg számítás sikeres: datum={}, iroda={}", closingDate, branchId);
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-006", "daily_closing.balance_calc_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "step", "balance_calc"));
            warnings.add(ClosingWarning.builder()
                    .step("balance_calc")
                    .message("Napi mérleg számítás hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás, csak logoljuk
        }

        // 3.b FK-046: pénztári SZÁMZÁR (fizikailag leszámolt záró készlet) + Többlet/Hiány (TH
        //     elszámolási pénztár) bekötése a napi mérlegbe. A napi mérleg-sorok (3. lépés) már
        //     léteznek; ez a lépés tölti az actualStock/surplus/shortage mezőket pénztári irodákra.
        try {
            dailyBalanceService.recordClosingAdjustments(branchId, closingDate);
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-006", "daily_closing.szamzar_th_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "step", "szamzar_th_adjustment"));
            warnings.add(ClosingWarning.builder()
                    .step("szamzar_th_adjustment")
                    .message("SZÁMZÁR TH igazítás hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás (FR-7/FR-9 szellemében)
        }

        // 3.c FK-052: a banki (technikai RB) BANK+/BANK− bekötés csak a teljes napzárás
        //     sikeres commitja UTÁN indul. A callback szinkron fut a commit közben, ezért a
        //     mutable warnings lista kiegészítése még látszik a visszaadott eredményben.
        TransactionAfterCommit.run(() -> {
            try {
                dailyBalanceService.recordVaultBankAdjustments(branchId, closingDate);
            } catch (Exception e) {
                VV_LOG.error("VV-BIZ-006", "daily_closing.bank_adjustment_failed", e,
                        java.util.Map.of("closing_date", closingDate,
                                "branch_id", branchId,
                                "step", "bank_adjustment"));
                warnings.add(ClosingWarning.builder()
                        .step("bank_adjustment")
                        .message("Banki BANK+/BANK− igazítás hiba: " + e.getMessage())
                        .build());
                // A fő zárás ekkor már commitált; a banki REQUIRES_NEW hiba csak warning.
            }
        }, "FK-052 bank adjustment branch=" + branchId + ", date=" + closingDate);

        // 4. POS terminál napi zárás — ha van aktív terminál az irodán
        executePosTerminalClosing(branchId, closingDate, warnings);

        // 5. Esti zárás adatcsomag küldés a központnak (legacy ESTIZAR ekvivalens)
        executeEveningSync(branchId, closingDate);

        // 6. Napi tranzakciók archiválása (legacy BfCopy + BtCopy)
        try {
            int archivedCount = monthlyArchiveService.archiveDailyTransactions(branchId, closingDate);
            log.info("Napi archiválás kész: datum={}, iroda={}, archivált={}", closingDate, branchId, archivedCount);
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-010", "daily_closing.archive_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "phase", "daily_archive"));
            warnings.add(ClosingWarning.builder()
                    .step("daily_archive")
                    .message("Napi archiválás hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }

        // 6b. S1-02: Teljes napi archiválás (Delphi: HaviGyujtokbeMasolas — CimtCopy, EdatCopy, KdatCopy, WuniCopy, WzarCopy)
        try {
            String archiveSummary = dailyClosingArchiveService.executeFullDailyArchive(branchId, closingDate);
            log.info("S1-02 napi archiválás kész: datum={}, iroda={}, summary={}", closingDate, branchId, archiveSummary);
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-010", "daily_closing.s1_02_archive_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "phase", "s1_02_archive"));
            warnings.add(ClosingWarning.builder()
                    .step("s1_02_archive")
                    .message("S1-02 napi archiválás hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }

        // 7. AML napi ügyfél gyűjtők nullázása
        try {
            amlService.resetDailyCache();
            log.info("AML napi cache reset kész: datum={}, iroda={}", closingDate, branchId);
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-006", "daily_closing.aml_cache_reset_failed", e,
                    java.util.Map.of("closing_date", closingDate,
                            "branch_id", branchId,
                            "step", "aml_cache_reset"));
            warnings.add(ClosingWarning.builder()
                    .step("aml_cache_reset")
                    .message("AML napi cache reset hiba: " + e.getMessage())
                    .build());
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }

        // 8. Dekad kontroll (10 napos idoszak zaras) — most már valódi generateDecadeReport hívással
        checkDecadeClosing(branchId, closingDate, warnings);

        log.info("Napzaras vegrehajtva: datum={}, iroda={}", closingDate, branchId);
    }

    /**
     * Napi arfolyamok snapshot-ja (archivalaas).
     * HIGH FIX #7: Duplikáció ellenőrzés — ne mentsen ha már van aznapi snapshot.
     */
    private void snapshotDailyRates(UUID companyId, LocalDate date) {
        // Az aktualis aktiv arfolyamokat "befagyasztjuk" a zaras napjahoz:
        // Active rátákat inaktiváljuk, ezzel rögzítve az aznapi záró állapotot.
        List<ExchangeRate> activeRates = exchangeRateRepository
            .findActiveRatesByDate(companyId, date);

        if (activeRates.isEmpty()) {
            log.warn("Napi arfolyam snapshot: nincs aktiv arfolyam a(z) {} napra — SKIP", date);
            return;
        }

        // Duplikáció ellenőrzés: ha nincs aktív árfolyam (mind inaktív), már lefutott a snapshot
        boolean allInactive = activeRates.stream().noneMatch(ExchangeRate::getActive);
        if (allInactive) {
            log.info("Napi arfolyam snapshot mar letezik: datum={}, {} db — SKIP", date, activeRates.size());
            return;
        }

        for (ExchangeRate rate : activeRates) {
            rate.setActive(false);
            exchangeRateRepository.save(rate);
        }

        log.info("Napi arfolyamok rogzitve (befagyasztva): {} db", activeRates.size());
    }

    /**
     * POS terminál napi zárás — az irodához tartozó összes aktív terminálon.
     * Legacy: otpterminal DLL — napzárás hívás.
     */
    private void executePosTerminalClosing(UUID branchId, LocalDate closingDate, List<ClosingWarning> warnings) {
        try {
            List<PosTerminal> terminals = posTerminalRepository
                    .findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(branchId);

            if (terminals.isEmpty()) {
                log.debug("Nincs aktív POS terminál az irodán: branchId={}", branchId);
                return;
            }

            for (PosTerminal terminal : terminals) {
                try {
                    PosClosingResult result = posTerminalService.dailyClose(terminal.getTerminalId());
                    if (result.success()) {
                        log.info("POS terminál napi zárás sikeres: terminál={}, tranzakciók={}, összeg={}",
                                terminal.getTerminalId(), result.transactionCount(), result.totalAmount());
                    } else {
                        log.warn("POS terminál napi zárás sikertelen: terminál={}, hiba={}",
                                terminal.getTerminalId(), result.errorMessage());
                    }
                } catch (Exception e) {
                    // Codex PR #685 P2: Map.of() reject null-okat. Ha az inkonzisztens
                    // DB-rekord miatt a terminal.getTerminalId() null, az Map.of() NPE-t
                    // dobna a catch-ben es megszakitana a loopot. Defensive: csak nem-null
                    // attr-okat raknak HashMap-be, igy mindenkeppen folytatodik a loop.
                    java.util.Map<String, Object> attrs = new java.util.HashMap<>();
                    String terminalId = terminal.getTerminalId();
                    if (terminalId != null) {
                        attrs.put("terminal_id", terminalId);
                    } else {
                        attrs.put("terminal_id", "<null - inkonzisztens DB-rekord>");
                    }
                    VV_LOG.error("VV-BIZ-007", "daily_closing.pos_terminal_failed", e, attrs);
                    warnings.add(ClosingWarning.builder()
                            .step("pos_terminal")
                            .message("POS terminál napi zárás hiba (" + terminalId + "): " + e.getMessage())
                            .build());
                    // NEM dobunk kivételt — ne akadjon meg a zárás
                }
            }
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-007", "daily_closing.pos_terminal_general_failed", e,
                    java.util.Map.of("branch_id", branchId,
                            "scope", "all_terminals"));
            warnings.add(ClosingWarning.builder()
                    .step("pos_terminal")
                    .message("POS terminál napi zárás általános hiba: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Esti zárás adatcsomag küldése a központnak.
     * Legacy: Delphi ESTIZAR modul → FTP-n bináris csomag.
     * Modern: REST API — JSON adatcsomag.
     */
    private void executeEveningSync(UUID branchId, LocalDate closingDate) {
        try {
            DailyDataPackage pkg = eveningClosingService.prepareDailyPackage(branchId, closingDate);
            DataSyncResult result = eveningClosingService.sendToHeadquarters(pkg);

            if (result.isSuccess()) {
                log.info("Esti zárás adatcsomag sikeresen elküldve: branchId={}, datum={}, checksum={}",
                        branchId, closingDate, result.getChecksum());
            } else {
                log.warn("Esti zárás adatcsomag küldés sikertelen: branchId={}, datum={}, hiba={}",
                        branchId, closingDate, result.getMessage());
                throw new ValidationException("Esti zárás adatcsomag küldés sikertelen: " + result.getMessage());
            }
        } catch (ValidationException e) {
            throw e;
        } catch (Exception e) {
            VV_LOG.error("VV-BIZ-008", "daily_closing.evening_send_failed", e,
                    java.util.Map.of("branch_id", branchId,
                            "closing_date", closingDate));
            if (e instanceof RuntimeException runtimeException) {
                throw runtimeException;
            }
            throw new ValidationException("Esti zárás adatcsomag küldés hiba: " + e.getMessage());
        }
    }

    /**
     * Dekad (10 napos idoszak) zaras kontroll.
     * Legacy: DekzarCtrl - minden 10. napon kulon osszesites.
     */
    /**
     * HIGH FIX #6: Dekád zárás — ne csak logoljon, hozzon létre audit riport record-ot.
     * Legacy: DekzarCtrl — a 10., 20. és hónap utolsó napján dekád összesítés.
     */
    private void checkDecadeClosing(UUID branchId, LocalDate date, List<ClosingWarning> warnings) {
        int dayOfMonth = date.getDayOfMonth();
        if (dayOfMonth == 10 || dayOfMonth == 20 || dayOfMonth == date.lengthOfMonth()) {
            // Dekád számítás: (hónap-1)*3 + dekádInHónap
            // dekádInHónap: 10. nap→1, 20. nap→2, hó vége→3
            int month = date.getMonthValue();
            int decadeInMonth = (dayOfMonth == 10) ? 1 : (dayOfMonth == 20) ? 2 : 3;
            int globalDecade = (month - 1) * 3 + decadeInMonth; // 1-36

            String decadePeriod;
            if (decadeInMonth == 1) {
                decadePeriod = "1-10";
            } else if (decadeInMonth == 2) {
                decadePeriod = "11-20";
            } else {
                decadePeriod = "21-" + dayOfMonth;
            }
            log.info("Dekad zaras: nap={}, idoszak={}, globalDekad={}", dayOfMonth, decadePeriod, globalDecade);

            // Dekádjelentés generálása (legacy DekzarCtrl)
            try {
                decadeReportService.generateDecadeReport(branchId, date.getYear(), globalDecade);
                log.info("Dekadjelentes generálva: branchId={}, ev={}, dekad={}", branchId, date.getYear(), globalDecade);
            } catch (Exception e) {
                VV_LOG.error("VV-BIZ-009", "daily_closing.decade_report_failed", e,
                        java.util.Map.of("branch_id", branchId,
                                "year", date.getYear(),
                                "decade", globalDecade));
                warnings.add(ClosingWarning.builder()
                        .step("decade_report")
                        .message("Dekád jelentés hiba: " + e.getMessage())
                        .build());
                // NEM dobunk kivételt — ne akadjon meg a zárás
            }

            // Audit log
            auditLogService.log(
                "DECADE_CLOSING",
                "DailyClosing",
                branchId.toString(),
                SecurityUtils.getCurrentWorkerId() != null ? SecurityUtils.getCurrentWorkerId().toString() : null,
                null,
                branchId.toString(),
                null,
                String.format("{\"date\":\"%s\",\"dayOfMonth\":%d,\"decadePeriod\":\"%s\",\"globalDecade\":%d}",
                    date, dayOfMonth, decadePeriod, globalDecade),
                null,
                null
            );
        }
    }

    /**
     * Ellenorzi hogy az iroda rendelkezik-e egy adott feature-rel.
     * A feature-ok a SystemParameter tablaban tarolodnak: FEATURE_{featureName} = true/false
     */
    private boolean hasFeature(UUID branchId, String featureName) {
        try {
            String key = "FEATURE_" + featureName;
            String val = systemParameterService.getValue(key);
            return "true".equalsIgnoreCase(val) || "1".equals(val);
        } catch (Exception e) {
            // Ha nincs ilyen parameter, a feature nem aktiv
            return false;
        }
    }

    /**
     * FK-061: backend-oldali vault-kontextus detektálás — a branch `isVault` jelzője alapján.
     * Újrahasználható segéd a napi zárás ellenőrzés-láncához; a frontend zárási varázsló
     * mode-detekciójának (értéktár mód) szerver-oldali megfelelője.
     */
    private boolean isVaultBranch(UUID branchId) {
        return branchRepository.findById(branchId)
            .map(b -> Boolean.TRUE.equals(b.getIsVault()))
            .orElse(false);
    }

    // ============ HELPER CLASSOK ============

    @FunctionalInterface
    private interface StepCheck {
        StepCheckResult execute();
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class StepCheckResult {
        private boolean passed;
        private boolean skipped;
        private String message;

        public static StepCheckResult passed(String message) {
            return StepCheckResult.builder().passed(true).skipped(false).message(message).build();
        }

        public static StepCheckResult failed(String message) {
            return StepCheckResult.builder().passed(false).skipped(false).message(message).build();
        }

        public static StepCheckResult skipped(String message) {
            return StepCheckResult.builder().passed(true).skipped(true).message(message).build();
        }
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ClosingStepResult {
        private int stepNumber;
        private String stepName;
        private boolean passed;
        private boolean skipped;
        private String message;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ClosingWarning {
        /** Gépi lépés-kulcs — azonos a VVLogger step/phase attribútummal. */
        private String step;
        /** Emberi hibaüzenet a UI-nak. */
        private String message;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ClosingWizardResult {
        private String wizardId;
        private LocalDate closingDate;
        private boolean allPassed;
        private List<ClosingStepResult> steps;
        @lombok.Builder.Default
        private List<ClosingWarning> warnings = new ArrayList<>();
    }
}
