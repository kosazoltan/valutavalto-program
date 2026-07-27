package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * DailyClosingService kiterjesztett unit tesztek.
 *
 * Ellenőrzi, hogy a 4 újonnan hozzáadott legacy lépés
 * (archiválás, dekád riport, AML reset, bizonylat gap check)
 * valóban meghívódik-e az executeClosing() során.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class DailyClosingServiceExtendedTest {

    @InjectMocks
    private DailyClosingService dailyClosingService;

    // Meglévő függőségek
    @Mock private DailySessionService dailySessionService;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private ClosingWizardRepository closingWizardRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private SystemParameterService systemParameterService;
    @Mock private AuditLogService auditLogService;
    @Mock private DailyBalanceService dailyBalanceService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private PosTerminalRepository posTerminalRepository;
    @Mock private EveningClosingService eveningClosingService;
    @Mock private DailyClosingArchiveService dailyClosingArchiveService;

    // Új függőségek
    @Mock private MonthlyArchiveService monthlyArchiveService;
    @Mock private DecadeReportService decadeReportService;
    @Mock private AmlService amlService;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private ClosingControlService closingControlService;
    @Mock private BranchRepository branchRepository;
    /** FK-066: új konstruktor-függőség (FK-065 minta) — fixture-bekötés, assertion nem változik. */
    @Mock private ClosingToleranceService closingToleranceService;

    private static final UUID BRANCH_ID  = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth =
            new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Alapértelmezett stub-ok, amelyek elindítják a startDailyClosing-ot
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        ClosingWizard wizard = ClosingWizard.builder()
            .id(UUID.randomUUID())
            .closingDate(LocalDate.of(2026, 3, 10))
            .wizardStatus(WizardStatus.IN_PROGRESS)
            .totalSteps(9)
            .build();
        when(closingWizardRepository.save(any())).thenReturn(wizard);

        // Lépés ellenőrzések: mind PASS
        when(transactionRepository.findByBranchIdAndTransactionDateAndMtcnIsNull(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                any(), any(), eq(DenominationCategory.EVENING))).thenReturn(true);
        when(denominationBalanceRepository.sumDenominatedAmount(any(), any(), any()))
            .thenReturn(new BigDecimal("100000"));
        // FK-063: a checkEveningDenomination pénznemenkénti útjának default stubjai —
        // becímletezett HUF 100 000 = nyilvántartott HUF 100 000 (step 2 PASS).
        when(denominationBalanceRepository.sumActualStockByCurrency(
                any(), any(), eq(DenominationCategory.EVENING)))
            .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100000")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(any(), any()))
            .thenReturn(List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));
        when(cashBalanceRepository.sumCurrentBalanceHufByBranchIdAndCompanyId(any(), any()))
            .thenReturn(new BigDecimal("100000"));
        when(transactionRepository.sumDailyHandlingFees(any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countUnreportedTransactions(any(), any())).thenReturn(0L);
        when(systemParameterService.getValue(anyString())).thenReturn("false");
        // FK-066 fixture: paraméter-sor nélküli (fallback) tolerancia-szimuláció — a
        // korábbi hardkódolt viselkedés tükre (HUF: 1 Ft '>' operátorral, nem-HUF: 0).
        // A meglévo tesztek szemantikáját nem változtatja.
        when(closingToleranceService.getToleranceFor(anyString()))
            .thenAnswer(inv -> "HUF".equals(inv.getArgument(0))
                ? ClosingTolerance.fallbackOf(BigDecimal.ONE)
                : ClosingTolerance.fallbackOf(BigDecimal.ZERO));

        // FK-061: alapértelmezett nem-vault branch (pénztári kontextus)
        Branch nonVaultBranch = new Branch();
        nonVaultBranch.setId(BRANCH_ID);
        nonVaultBranch.setIsVault(false);
        when(branchRepository.findById(any(UUID.class)))
            .thenReturn(java.util.Optional.of(nonVaultBranch));

        // executeClosing belső hívások
        when(exchangeRateRepository.findActiveRatesByDate(any(), any()))
            .thenReturn(Collections.emptyList());
        when(posTerminalRepository.findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(any()))
            .thenReturn(Collections.emptyList());

        DataSyncResult syncResult = mock(DataSyncResult.class);
        when(syncResult.isSuccess()).thenReturn(true);
        when(syncResult.getChecksum()).thenReturn("abc123");
        DailyDataPackage pkg = mock(DailyDataPackage.class);
        when(eveningClosingService.prepareDailyPackage(any(UUID.class), any(LocalDate.class))).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(any())).thenReturn(syncResult);

        // Új lépések stub-jai
        when(receiptSequenceService.checkReceiptContinuity(any(), any()))
            .thenReturn(Collections.emptyList());
        when(monthlyArchiveService.archiveDailyTransactions(any(), any())).thenReturn(0);
        when(dailyClosingArchiveService.executeFullDailyArchive(any(), any())).thenReturn("ok");
    }

    // ============ TESZTEK ============

    @Test
    @DisplayName("archiveDailyTransactions meghívódik napzáráskor")
    void executeClosing_callsArchiveDailyTransactions() {
        // Adott
        LocalDate closingDate = LocalDate.of(2026, 3, 15);

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(monthlyArchiveService, times(1))
            .archiveDailyTransactions(eq(BRANCH_ID), eq(closingDate));
    }

    @Test
    @DisplayName("resetDailyCache meghívódik napzáráskor")
    void executeClosing_callsAmlResetDailyCache() {
        // Adott
        LocalDate closingDate = LocalDate.of(2026, 3, 15);

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(amlService, times(1)).resetDailyCache();
    }

    @Test
    @DisplayName("checkReceiptContinuity meghívódik napzáráskor")
    void executeClosing_callsCheckReceiptContinuity() {
        // Adott
        LocalDate closingDate = LocalDate.of(2026, 3, 15);

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(receiptSequenceService, times(1))
            .checkReceiptContinuity(eq(BRANCH_ID), eq(closingDate));
    }

    @Test
    @DisplayName("generateDecadeReport meghívódik a 10-én (dekád 1. napján)")
    void executeClosing_onDecadeDay10_callsGenerateDecadeReport() {
        // Adott: március 10. = 3. hónap, 1. dekád → globalDekad = (3-1)*3 + 1 = 7
        LocalDate closingDate = LocalDate.of(2026, 3, 10);
        when(decadeReportService.generateDecadeReport(any(), anyInt(), anyInt()))
            .thenReturn(mock(DecadeReportDto.class));

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor: 2026 év, 7. globális dekád
        verify(decadeReportService, times(1))
            .generateDecadeReport(eq(BRANCH_ID), eq(2026), eq(7));
    }

    @Test
    @DisplayName("generateDecadeReport meghívódik a 20-án (dekád 2. napján)")
    void executeClosing_onDecadeDay20_callsGenerateDecadeReport() {
        // Adott: március 20. = 3. hónap, 2. dekád → globalDekad = (3-1)*3 + 2 = 8
        LocalDate closingDate = LocalDate.of(2026, 3, 20);
        when(decadeReportService.generateDecadeReport(any(), anyInt(), anyInt()))
            .thenReturn(mock(DecadeReportDto.class));

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(decadeReportService, times(1))
            .generateDecadeReport(eq(BRANCH_ID), eq(2026), eq(8));
    }

    @Test
    @DisplayName("generateDecadeReport meghívódik hó utolsó napján (dekád 3. napján)")
    void executeClosing_onLastDayOfMonth_callsGenerateDecadeReport() {
        // Adott: március 31. = 3. hónap, 3. dekád → globalDekad = (3-1)*3 + 3 = 9
        LocalDate closingDate = LocalDate.of(2026, 3, 31);
        when(decadeReportService.generateDecadeReport(any(), anyInt(), anyInt()))
            .thenReturn(mock(DecadeReportDto.class));

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(decadeReportService, times(1))
            .generateDecadeReport(eq(BRANCH_ID), eq(2026), eq(9));
    }

    @Test
    @DisplayName("generateDecadeReport NEM hívódik meg nem-dekád napon")
    void executeClosing_onNonDecadeDay_doesNotCallGenerateDecadeReport() {
        // Adott: március 15. — nem dekád nap
        LocalDate closingDate = LocalDate.of(2026, 3, 15);

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor
        verify(decadeReportService, never())
            .generateDecadeReport(any(), anyInt(), anyInt());
    }

    @Test
    @DisplayName("bizonylat gap detektálásakor audit log keletkezik")
    void executeClosing_whenGapsFound_logsAuditEntry() {
        // Adott: 2 hiányzó bizonylat
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        when(receiptSequenceService.checkReceiptContinuity(any(), any()))
            .thenReturn(List.of("V001000042", "E001000017"));

        // Ha
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor: audit log meghívódik RECEIPT_GAP_DETECTED action-nel
        verify(auditLogService, atLeastOnce()).log(
            eq("RECEIPT_GAP_DETECTED"),
            eq("DailyClosing"),
            eq(BRANCH_ID.toString()),
            any(), any(), any(), any(), any(), any(), any()
        );
    }

    @Test
    @DisplayName("sikertelen esti központi szinkron nem zárhatja sikeresre a napot")
    void executeClosing_eveningSyncFailureBlocksClosing() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        when(eveningClosingService.sendToHeadquarters(any()))
            .thenReturn(DataSyncResult.failure("HQ URL nincs konfigurálva", 1));

        assertThatThrownBy(() -> dailyClosingService.startDailyClosing(closingDate))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Esti zárás adatcsomag küldés sikertelen")
            .hasMessageContaining("HQ URL nincs konfigurálva");

        verify(closingWizardRepository, times(1)).save(any(ClosingWizard.class));
    }

    @Test
    @DisplayName("NAV kontroll fail-closed, ha aktív a NAV feature, de nincs éles/szimulált visszaigazolás")
    void navStepFailsClosedWhenBridgeSimulationDisabled() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        when(systemParameterService.getValue("FEATURE_NAV_INTEGRATION")).thenReturn("true");

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(9, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.isSkipped()).isFalse();
        assertThat(result.getMessage()).contains("nincs eles NAV jelentes-visszaigazolas");
        verify(transactionRepository, never()).countUnreportedTransactions(any(), any());
    }

    @Test
    @DisplayName("NAV kontroll csak explicit bridge-szimuláció mellett használja a régi printed=false számlálót")
    void navStepUsesLegacyCounterOnlyWhenBridgeSimulationEnabled() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        ReflectionTestUtils.setField(dailyClosingService, "navBridgeSimulatedSuccessEnabled", true);
        when(systemParameterService.getValue("FEATURE_NAV_INTEGRATION")).thenReturn("true");
        when(transactionRepository.countUnreportedTransactions(BRANCH_ID, closingDate)).thenReturn(0L);

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(9, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isTrue();
        assertThat(result.getMessage()).contains("NAV kontroll");
        verify(transactionRepository).countUnreportedTransactions(BRANCH_ID, closingDate);
    }

    @Test
    @DisplayName("FK-060: más kategória mai sora nem helyettesíti az EVENING címletezést")
    void eveningDenominationRequiresEveningCategory() {
        LocalDate closingDate = LocalDate.of(2026, 7, 22);
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, closingDate, DenominationCategory.EVENING)).thenReturn(false);

        DailyClosingService.StepCheckResult result =
                dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.getMessage()).contains("Hianyzik az esti penztar cimletezese");
        verify(denominationBalanceRepository).existsByBranchIdAndDateAndCategory(
                BRANCH_ID, closingDate, DenominationCategory.EVENING);
        verify(denominationBalanceRepository, never())
                .sumDenominatedAmount(any(), any(), any());
    }

    @Test
    @DisplayName("archiveDailyTransactions hibája nem állítja meg a napzárást")
    void executeClosing_archiveException_doesNotBlockClosing() {
        // Adott: archiválás kivételt dob
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        when(monthlyArchiveService.archiveDailyTransactions(any(), any()))
            .thenThrow(new RuntimeException("Archiválás hiba teszt"));

        // Ha — NEM dob kivételt
        dailyClosingService.startDailyClosing(closingDate);

        // Akkor: a session zárás megtörtént (a zárás nem akadt el)
        verify(dailySessionService, times(1)).closeSession(any());
    }

    @Test
    @DisplayName("Mérleg-számítás hiba: zárás lezárul ÉS warning kerül a válaszba")
    void executeClosing_balanceCalcFails_closingCompletesWithWarning() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        doThrow(new RuntimeException("mérleg hiba"))
            .when(dailyBalanceService).calculateAllCurrenciesForDay(any(), any());

        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings())
            .extracting(DailyClosingService.ClosingWarning::getStep)
            .contains("balance_calc");
        verify(closingControlService).markClosingDone(any(), any(), eq(closingDate), any());
    }

    @Test
    @DisplayName("Hibátlan zárás: warnings üres lista (nem null)")
    void executeClosing_noFailures_warningsEmpty() {
        var result = dailyClosingService.startDailyClosing(LocalDate.of(2026, 3, 15));

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings()).isNotNull().isEmpty();
    }

    @Test
    @DisplayName("Napi archiválás hiba: warning keletkezik és a későbbi S1-02 archívum lefut")
    void executeClosing_dailyArchiveFails_warningAndLaterArchiveStillRuns() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        when(monthlyArchiveService.archiveDailyTransactions(any(), any()))
            .thenThrow(new RuntimeException("archív hiba"));

        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings())
            .extracting(DailyClosingService.ClosingWarning::getStep)
            .contains("daily_archive");
        verify(dailyClosingArchiveService).executeFullDailyArchive(eq(BRANCH_ID), eq(closingDate));
    }

    @Test
    @DisplayName("AML cache reset hiba: warning kerül a válaszba")
    void executeClosing_amlCacheResetFails_warningReturned() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        doThrow(new RuntimeException("AML hiba")).when(amlService).resetDailyCache();

        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings())
            .extracting(DailyClosingService.ClosingWarning::getStep)
            .contains("aml_cache_reset");
    }

    @Test
    @DisplayName("FK-052: sikeres záráskor a vault banki igazítás commit után, pontosan egyszer fut")
    void executeClosing_registersVaultBankAdjustmentForAfterCommit() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);

        TransactionSynchronizationManager.initSynchronization();
        try {
            var result = dailyClosingService.startDailyClosing(closingDate);

            verify(dailyBalanceService).recordClosingAdjustments(BRANCH_ID, closingDate);
            verify(dailyBalanceService, never()).recordVaultBankAdjustments(any(), any());
            assertThat(result.getWarnings()).isEmpty();

            List<TransactionSynchronization> synchronizations =
                    TransactionSynchronizationManager.getSynchronizations();
            assertThat(synchronizations).hasSize(1);
            synchronizations.forEach(TransactionSynchronization::afterCommit);

            verify(dailyBalanceService, times(1))
                    .recordVaultBankAdjustments(BRANCH_ID, closingDate);
            assertThat(result.getWarnings()).isEmpty();
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    @DisplayName("FK-052: commit utáni banki igazítás hibája a már visszaadandó eredmény warning-listájába kerül")
    void executeClosing_afterCommitVaultBankAdjustmentFailure_isVisibleInReturnedWarnings() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        doThrow(new RuntimeException("banki igazítás hiba"))
                .when(dailyBalanceService).recordVaultBankAdjustments(BRANCH_ID, closingDate);

        TransactionSynchronizationManager.initSynchronization();
        try {
            var result = dailyClosingService.startDailyClosing(closingDate);

            assertThat(result.isAllPassed()).isTrue();
            assertThat(result.getWarnings())
                    .extracting(DailyClosingService.ClosingWarning::getStep)
                    .doesNotContain("bank_adjustment");

            TransactionSynchronizationManager.getSynchronizations()
                    .forEach(TransactionSynchronization::afterCommit);

            assertThat(result.getWarnings())
                    .anySatisfy(warning -> {
                        assertThat(warning.getStep()).isEqualTo("bank_adjustment");
                        assertThat(warning.getMessage()).contains("banki igazítás hiba");
                    });
            verify(closingControlService)
                    .markClosingDone(COMPANY_ID, BRANCH_ID, closingDate, ClosingMarkType.DAILY);
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    // ============ FK-061: vault-kontextusú checkEveningDenomination kihagyás ============

    private void makeBranchVault() {
        Branch vaultBranch = new Branch();
        vaultBranch.setId(BRANCH_ID);
        vaultBranch.setIsVault(true);
        when(branchRepository.findById(any(UUID.class)))
            .thenReturn(java.util.Optional.of(vaultBranch));
    }

    @Test
    @DisplayName("FK-061: vault branch — az esti címletezés-lépés kihagyva (skipped, PASS), audit-esemény rögzítve")
    void startDailyClosing_vaultBranch_skipsEveningDenominationWithAudit() {
        makeBranchVault();
        // A HUF-only egyezés szándékosan HIBÁS lenne (nem-HUF állományú értéktár szimulációja):
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                any(), any(), eq(DenominationCategory.EVENING))).thenReturn(false);

        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        var step2 = result.getSteps().stream()
            .filter(s -> s.getStepNumber() == 2).findFirst().orElseThrow();
        assertThat(step2.isPassed()).isTrue();
        assertThat(step2.isSkipped()).isTrue();
        verify(auditLogService).log(
            eq("EVENING_DENOMINATION_CHECK_SKIPPED_VAULT"),
            contains("vault"),
            eq(BRANCH_ID.toString()));
        // A HUF-only ellenőrzés lekérdezései nem futhatnak vault-kontextusban
        verify(denominationBalanceRepository, never()).sumDenominatedAmount(any(), any(), eq("EVENING"));
    }

    @Test
    @DisplayName("FK-061/FK-063 regresszió: nem-vault branch — az esti címletezés-lépés változatlanul fut, nincs skip-audit")
    void startDailyClosing_cashierBranch_eveningDenominationRunsUnchanged() {
        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        var step2 = result.getSteps().stream()
            .filter(s -> s.getStepNumber() == 2).findFirst().orElseThrow();
        assertThat(step2.isSkipped()).isFalse();
        verify(auditLogService, never()).log(
            eq("EVENING_DENOMINATION_CHECK_SKIPPED_VAULT"), anyString(), anyString());
        // FK-063: a pénztári ág már a pénznemenkénti lekérdezést használja
        verify(denominationBalanceRepository).sumActualStockByCurrency(
            any(), any(), eq(DenominationCategory.EVENING));
    }

    @Test
    @DisplayName("FK-061/FK-063 regresszió: nem-vault branch címletezés-eltéréssel (HUF) továbbra is FAIL")
    void startDailyClosing_cashierBranch_denominationMismatchStillFails() {
        // FK-063: pénznemenkénti út — becímletezve 99 000 HUF, nyilvántartva 100 000 HUF
        when(denominationBalanceRepository.sumActualStockByCurrency(
                any(), any(), eq(DenominationCategory.EVENING)))
            .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("99000")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(any(), any()))
            .thenReturn(List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

        LocalDate closingDate = LocalDate.of(2026, 3, 15);
        var result = dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isFalse();
        var step2 = result.getSteps().stream()
            .filter(s -> s.getStepNumber() == 2).findFirst().orElseThrow();
        assertThat(step2.isPassed()).isFalse();
        assertThat(step2.getMessage()).contains("HUF");
    }

    // ============ FK-063: pénznemenkénti checkEveningDenomination a pénztári ágon ============

    private CashBalance cashBalanceOf(String code, BigDecimal balance) {
        Currency currency = new Currency();
        currency.setCode(code);
        CashBalance cb = new CashBalance();
        cb.setCurrency(currency);
        cb.setCurrentBalance(balance);
        return cb;
    }

    @Test
    @DisplayName("FK-063 FR-5: minden bekért pénznem (HUF+EUR+USD) egyezik → step 2 PASS")
    void checkEveningDenomination_allCurrenciesMatch_passes() {
        LocalDate closingDate = LocalDate.of(2026, 7, 24);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, closingDate, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(
                new Object[]{"HUF", new BigDecimal("100000")},
                new Object[]{"EUR", new BigDecimal("500")},
                new Object[]{"USD", new BigDecimal("300")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
            .thenReturn(List.of(
                cashBalanceOf("HUF", new BigDecimal("100000")),
                cashBalanceOf("EUR", new BigDecimal("500")),
                cashBalanceOf("USD", new BigDecimal("300"))));

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isTrue();
        assertThat(result.isSkipped()).isFalse();
    }

    @Test
    @DisplayName("FK-063 FR-6: EUR-eltérés esetén a step 2 bukik és nevesíti az EUR-t (HUF/USD egyezik)")
    void checkEveningDenomination_eurMismatch_failsNamingEur() {
        LocalDate closingDate = LocalDate.of(2026, 7, 24);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, closingDate, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(
                new Object[]{"HUF", new BigDecimal("100000")},
                new Object[]{"EUR", new BigDecimal("450")},
                new Object[]{"USD", new BigDecimal("300")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
            .thenReturn(List.of(
                cashBalanceOf("HUF", new BigDecimal("100000")),
                cashBalanceOf("EUR", new BigDecimal("500")),
                cashBalanceOf("USD", new BigDecimal("300"))));

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.getMessage()).contains("EUR").doesNotContain("USD");
    }

    @Test
    @DisplayName("FK-066 regresszió: HUF-fallback felső határa — 2 Ft eltérés paraméter-sor nélkül bukik")
    void checkEveningDenomination_hufFallbackUpperBoundary() {
        // FK-066 szerződés-rögzítés: system_parameter sor NÉLKÜL a kód-szintű fallback
        // HUF-tolerancia 1 Ft marad (a seedelt 5 CSAK explicit DB-sorként érvényes),
        // tehát a 2 Ft-os eltérésnek fallback-ágon FK-066 után is buknia kell.
        LocalDate closingDate = LocalDate.of(2026, 7, 24);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, closingDate, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100002")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
            .thenReturn(List.of(cashBalanceOf("HUF", new BigDecimal("100000"))));

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.getMessage()).contains("HUF");
    }

    @Test
    @DisplayName("FK-063: HUF 1 Ft-os kerekítési eltérés tolerálva, de nem-HUF 1 egységnyi eltérés bukik")
    void checkEveningDenomination_hufToleranceOnly() {
        LocalDate closingDate = LocalDate.of(2026, 7, 24);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, closingDate, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(
                new Object[]{"HUF", new BigDecimal("100001")},
                new Object[]{"EUR", new BigDecimal("501")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
            .thenReturn(List.of(
                cashBalanceOf("HUF", new BigDecimal("100000")),
                cashBalanceOf("EUR", new BigDecimal("500"))));

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.getMessage()).contains("EUR").doesNotContain("HUF:");
    }

    @Test
    @DisplayName("FK-063: nyilvántartott, de be nem címletezett pénznem (hiányzó EUR-szekció) bukik")
    void checkEveningDenomination_missingCurrencySection_fails() {
        LocalDate closingDate = LocalDate.of(2026, 7, 24);
        when(denominationBalanceRepository.sumActualStockByCurrency(
                BRANCH_ID, closingDate, DenominationCategory.EVENING))
            .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("100000")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID))
            .thenReturn(List.of(
                cashBalanceOf("HUF", new BigDecimal("100000")),
                cashBalanceOf("EUR", new BigDecimal("500"))));

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isFalse();
        assertThat(result.getMessage()).contains("EUR");
    }

    @Test
    @DisplayName("FK-063 regresszió: vault-ági skipped-logika változatlan (per-currency út nem fut vaultnál)")
    void checkEveningDenomination_vaultBranch_skipLogicUntouched() {
        makeBranchVault();
        LocalDate closingDate = LocalDate.of(2026, 7, 24);

        DailyClosingService.StepCheckResult result =
            dailyClosingService.executeStepCheck(2, BRANCH_ID, closingDate);

        assertThat(result.isPassed()).isTrue();
        assertThat(result.isSkipped()).isTrue();
        verify(denominationBalanceRepository, never()).sumActualStockByCurrency(any(), any(), any());
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }
}
