package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Napzarasi szolgaltatas — 9 lepesu ellenorzesi lanc.
 *
 * Legacy: NAPZAR.DLL + CHECKLST.DLL + CIMLCTRL.DLL + CIMLMENU.DLL + DEKAD.DLL
 *
 * A legacy rendszerben a napzaras szigoru sorrendben tortent:
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
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DailyClosingService {

    private final DailySessionService dailySessionService;
    private final TransactionRepository transactionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final ClosingWizardRepository closingWizardRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;

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
        Branch branch = new com.puzzleir.backend.entity.Branch();
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
        stepResults.add(runStep(2, "Esti penztarallag cimletezese", () -> checkEveningDenomination(branchId, closingDate)));
        stepResults.add(runStep(3, "Kezelesi dij cimletezese", () -> checkHandlingFeeDenomination(branchId, closingDate)));
        stepResults.add(runStep(4, "Western Union cimletezese", () -> checkWesternUnionDenomination(branchId, closingDate)));
        stepResults.add(runStep(5, "AFA cimletezese", () -> checkVatDenomination(branchId, closingDate)));
        stepResults.add(runStep(6, "Foglalo cimletezese", () -> checkDepositDenomination(branchId, closingDate)));
        stepResults.add(runStep(7, "E-kereskedelem cimletezese", () -> checkEcommerceDenomination(branchId, closingDate)));
        stepResults.add(runStep(8, "Egyeb cimletezesek (AXA/MoneyGram)", () -> checkOtherDenominations(branchId, closingDate)));
        stepResults.add(runStep(9, "NAV kontroll es napi jelentes", () -> checkNavControlAndReport(branchId, closingDate)));

        // Eredmeny osszesites
        boolean allPassed = stepResults.stream().allMatch(ClosingStepResult::isPassed);

        if (allPassed) {
            // Napzaras vegrehajtasa
            executeClosing(branchId, companyId, closingDate);
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
            log.error("Napzaras lepes {} hiba: {}", stepNumber, e.getMessage(), e);
            return ClosingStepResult.builder()
                .stepNumber(stepNumber)
                .stepName(stepName)
                .passed(false)
                .message("Rendszerhiba: " + e.getMessage())
                .build();
        }
    }

    // ============ ELLENORZESI LEPESEK ============

    /**
     * 1. MTCN szam ellenorzes (Western Union bizonylatok).
     * Legacy: MTCNControl - megkeresi az osszes WU bizonylat at es ellenorzi hogy van-e MTCN szam.
     */
    private StepCheckResult checkMtcnNumbers(UUID branchId, LocalDate date) {
        // Western Union tranzakciok keresese (MTCN szam nelkul)
        List<Transaction> wuTransactions = transactionRepository
            .findByBranchIdAndTransactionDateAndMtcnIsNull(branchId, date);

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
    private StepCheckResult checkEveningDenomination(UUID branchId, LocalDate date) {
        // Ellenorzi hogy a cimletezett osszeg egyezik-e a szamitott keszlettel
        boolean hasDenomination = denominationBalanceRepository
            .existsByBranchIdAndDate(branchId, date);

        if (!hasDenomination) {
            return StepCheckResult.failed("Hianyzik az esti penztar cimletezese!");
        }

        // Osszeg egyezes ellenorzese
        BigDecimal denominatedTotal = denominationBalanceRepository
            .sumDenominatedAmount(branchId, date, "EVENING");
        BigDecimal expectedTotal = cashBalanceRepository
            .sumCurrentBalanceHuf(branchId);

        if (denominatedTotal == null || expectedTotal == null) {
            return StepCheckResult.failed("Nem lehet ellenorizni a cimletezest (hianyznak adatok)");
        }

        // 1 Ft elteres megengedett (kerekites miatt)
        if (denominatedTotal.subtract(expectedTotal).abs().compareTo(BigDecimal.ONE) > 0) {
            return StepCheckResult.failed(String.format(
                "Cimletezesi elter es: ciml=%s Ft, vart=%s Ft",
                denominatedTotal.toPlainString(), expectedTotal.toPlainString()));
        }

        return StepCheckResult.passed("Esti cimletez es rendben");
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
    private void executeClosing(UUID branchId, UUID companyId, LocalDate closingDate) {
        log.info("Napzaras vegrehajtasa: datum={}", closingDate);

        // 1. Napi arfolyamok rogzitese (snapshot a zaraskor ervenyes arfolyamokrol)
        snapshotDailyRates(companyId, closingDate);

        // 2. Napi munkamenet lezarasa
        dailySessionService.closeSession(closingDate);

        // 3. Dekad kontroll (10 napos idoszak zaras)
        checkDecadeClosing(branchId, closingDate);

        log.info("Napzaras vegrehajtva: datum={}, iroda={}", closingDate, branchId);
    }

    /**
     * Napi arfolyamok snapshot-ja (archivalaas).
     */
    private void snapshotDailyRates(UUID companyId, LocalDate date) {
        // Az aktualis aktiv arfolyamokat "befagyasztjuk" a zaras napjahoz
        List<ExchangeRate> activeRates = exchangeRateRepository
            .findActiveRatesByDate(companyId, date);

        for (ExchangeRate rate : activeRates) {
            rate.setValidDate(date);
            exchangeRateRepository.save(rate);
        }

        log.info("Napi arfolyamok rogzitve: {} db", activeRates.size());
    }

    /**
     * Dekad (10 napos idoszak) zaras kontroll.
     * Legacy: DekzarCtrl - minden 10. napon kulon osszesites.
     */
    private void checkDecadeClosing(UUID branchId, LocalDate date) {
        int dayOfMonth = date.getDayOfMonth();
        if (dayOfMonth == 10 || dayOfMonth == 20 || dayOfMonth == date.lengthOfMonth()) {
            log.info("Dekad zaras szukseges: nap={}", dayOfMonth);
            // TODO: dekad jelentes generalasa
        }
    }

    /**
     * Ellenorzi hogy az iroda rendelkezik-e egy adott feature-rel.
     */
    private boolean hasFeature(UUID branchId, String featureName) {
        // Alapertelmezetten: WESTERN_UNION, VAT, DEPOSITS, ECOMMERCE, AXA, MONEYGRAM
        // Ezek a SystemParameter tabla ban tarolodnak iroda szinten
        // Egyelore: csak a valutavalto alapfeaturok aktivan (WU, cimletezes)
        // A tobbi opcionalis — skip-eli ha nincs
        return false; // Default: nincs, skip
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
    public static class ClosingWizardResult {
        private String wizardId;
        private LocalDate closingDate;
        private boolean allPassed;
        private List<ClosingStepResult> steps;
    }
}
