package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * FKH-061 (A1/A3): tranzakció-izolációs szerződések a napzárás melléklépéseire.
 *
 * <p>Az executeClosing 9 swallow-catch lépésének osztályozása:
 * <ul>
 *   <li>best-effort (0 receipt gap, 4 POS, 6 archiválás, 7 AML reset, 8 dekádriport):
 *       saját tranzakció (REQUIRES_NEW / NOT_SUPPORTED) + ClosingWarning — a fő zárás
 *       sosem lesz rollback-only, nincs UnexpectedRollbackException a commitnál;</li>
 *   <li>hard (3 napi mérleg, 3.b SZÁMZÁR/TH): a zárás tranzakciójával atomi — hiba esetén
 *       ValidationException a lépés megnevezésével (HTTP 400), sosem néma 500.</li>
 * </ul>
 *
 * <p>A Mockito-harnessban nincs tranzakció-szinkronizáció, ezért a
 * {@link TransactionAfterCommit} callback inline fut: a warning-állítások itt is érvényesek,
 * de a valós commit-izolációt a DailyClosingDecadeAfterCommitFkh061PostgresIT bizonyítja.
 * A fixture a DailyClosingServiceExtendedTest @Mock-készletét másolja — a produkciós
 * konstruktor nem bővül.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class DailyClosingTxIsolationFkh061Test {

    @Mock private UnconfirmedIncomingClosingGate unconfirmedIncomingClosingGate;
    @InjectMocks
    private DailyClosingService dailyClosingService;

    // Meglévő függőségek (DailyClosingServiceExtendedTest fixture, változatlanul)
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
    @Mock private MonthlyArchiveService monthlyArchiveService;
    @Mock private DecadeReportService decadeReportService;
    @Mock private AmlService amlService;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private ClosingControlService closingControlService;
    @Mock private BranchRepository branchRepository;
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

        when(dailySessionService.hasOpenSession()).thenReturn(true);

        ClosingWizard wizard = ClosingWizard.builder()
            .id(UUID.randomUUID())
            .closingDate(LocalDate.of(2026, 9, 10))
            .wizardStatus(WizardStatus.IN_PROGRESS)
            .totalSteps(9)
            .build();
        when(closingWizardRepository.save(any())).thenReturn(wizard);

        // Lépés-ellenőrzések: mind a 9 lépés PASS
        when(transactionRepository.findByBranchIdAndTransactionDateAndMtcnIsNull(any(), any(), any()))
            .thenReturn(Collections.emptyList());
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                any(), any(), eq(DenominationCategory.EVENING))).thenReturn(true);
        when(denominationBalanceRepository.sumDenominatedAmount(any(), any(), any()))
            .thenReturn(new BigDecimal("100000"));
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
        when(closingToleranceService.getToleranceFor(anyString()))
            .thenAnswer(inv -> "HUF".equals(inv.getArgument(0))
                ? ClosingTolerance.fallbackOf(BigDecimal.ONE)
                : ClosingTolerance.fallbackOf(BigDecimal.ZERO));

        Branch nonVaultBranch = new Branch();
        nonVaultBranch.setId(BRANCH_ID);
        nonVaultBranch.setIsVault(false);
        when(branchRepository.findById(any(UUID.class)))
            .thenReturn(java.util.Optional.of(nonVaultBranch));

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

        when(receiptSequenceService.checkReceiptContinuity(any(), any()))
            .thenReturn(Collections.emptyList());
        when(monthlyArchiveService.archiveDailyTransactions(any(), any())).thenReturn(0);
        when(dailyClosingArchiveService.executeFullDailyArchive(any(), any())).thenReturn("ok");
    }

    private CashBalance cashBalanceOf(String code, BigDecimal balance) {
        Currency currency = new Currency();
        currency.setCode(code);
        CashBalance cb = new CashBalance();
        cb.setCurrency(currency);
        cb.setCurrentBalance(balance);
        return cb;
    }

    // ============ A1: dekádriport-hiba nem mérgezheti a zárást ============

    @Test
    @DisplayName("FKH-061 A1: generateDecadeReport hiba → zárás sikeres marad, egyetlen decade_report warning")
    void decadeReportFailureDoesNotPoisonClosing() throws Exception {
        // 2026-09-10 = dekádnap (hó 10.) → a 8. lépés dekádriportot generál
        LocalDate closingDate = LocalDate.of(2026, 9, 10);
        when(decadeReportService.generateDecadeReport(any(), anyInt(), anyInt()))
            .thenThrow(new ValidationException(
                "Hiányzó MNB árfolyam a dekádjelentés generálásához: BAM (dátum: 2026-09-01)"));

        ArgumentCaptor<ClosingWizard> wizardCaptor = ArgumentCaptor.forClass(ClosingWizard.class);
        final DailyClosingService.ClosingWizardResult[] resultHolder =
            new DailyClosingService.ClosingWizardResult[1];
        assertThatCode(() -> resultHolder[0] = dailyClosingService.startDailyClosing(closingDate))
            .doesNotThrowAnyException();

        DailyClosingService.ClosingWizardResult result = resultHolder[0];
        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings())
            .singleElement()
            .satisfies(warning -> {
                assertThat(warning.getStep()).isEqualTo("decade_report");
                assertThat(warning.getMessage()).contains("BAM");
            });
        verify(closingControlService).markClosingDone(COMPANY_ID, BRANCH_ID, closingDate, ClosingMarkType.DAILY);
        verify(closingWizardRepository, atLeastOnce()).save(wizardCaptor.capture());
        assertThat(wizardCaptor.getValue().getWizardStatus()).isEqualTo(WizardStatus.COMPLETED);

        // Izolációs pinning: a dekádjelentés saját tranzakcióban fut — ha a zárás
        // tranzakcióján belül buknna (REQUIRED), a külső tx rollback-only lenne és a
        // commit UnexpectedRollbackException-nel bukna (FKH-061 A-hibája).
        Method generate = DecadeReportService.class
            .getMethod("generateDecadeReport", UUID.class, int.class, int.class);
        Transactional tx = generate.getAnnotation(Transactional.class);
        assertThat(tx).as("generateDecadeReport @Transactional").isNotNull();
        assertThat(tx.propagation())
            .as("FKH-061 A1: dekádriport izolált tranzakcióban")
            .isEqualTo(Propagation.REQUIRES_NEW);
    }

    // ============ A3a: best-effort lépések csak warningot termelnek ============

    @ParameterizedTest
    @ValueSource(strings = {"receipt_gap_check", "pos_terminal", "daily_archive", "aml_cache_reset"})
    @DisplayName("FKH-061 A3a: best-effort lépés hibája → zárás sikeres, lépés-nevű warning")
    void bestEffortStepsOnlyProduceWarnings(String step) throws Exception {
        LocalDate closingDate = LocalDate.of(2026, 9, 15); // nem dekádnap
        switch (step) {
            case "receipt_gap_check" -> when(receiptSequenceService.checkReceiptContinuity(any(), any()))
                .thenThrow(new RuntimeException("boom"));
            case "pos_terminal" -> {
                PosTerminal terminal = PosTerminal.builder()
                    .terminalId("T1").isActive(true).build();
                when(posTerminalRepository.findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(any()))
                    .thenReturn(List.of(terminal));
                when(posTerminalService.dailyClose("T1")).thenThrow(new RuntimeException("boom"));
            }
            case "daily_archive" -> when(monthlyArchiveService.archiveDailyTransactions(any(), any()))
                .thenThrow(new RuntimeException("boom"));
            case "aml_cache_reset" -> doThrow(new RuntimeException("boom"))
                .when(amlService).resetDailyCache();
            default -> throw new IllegalArgumentException("ismeretlen lépés: " + step);
        }

        DailyClosingService.ClosingWizardResult result =
            dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings())
            .extracting(DailyClosingService.ClosingWarning::getStep)
            .contains(step);
        verify(closingControlService).markClosingDone(COMPANY_ID, BRANCH_ID, closingDate, ClosingMarkType.DAILY);

        // Izolációs pinning: mindegyik best-effort callee saját (vagy felfüggesztett)
        // tranzakcióban fut, így hibájuk nem jelölheti rollback-only-ra a zárás tx-ét.
        assertPropagation(MonthlyArchiveService.class, "archiveDailyTransactions",
            new Class<?>[]{UUID.class, LocalDate.class}, Propagation.REQUIRES_NEW);
        assertPropagation(PosTerminalService.class, "dailyClose",
            new Class<?>[]{String.class}, Propagation.REQUIRES_NEW);
        assertPropagation(ReceiptSequenceService.class, "checkReceiptContinuity",
            new Class<?>[]{UUID.class, LocalDate.class}, Propagation.REQUIRES_NEW);
        assertPropagation(AmlService.class, "resetDailyCache",
            new Class<?>[]{}, Propagation.NOT_SUPPORTED);
    }

    private static void assertPropagation(
            Class<?> serviceClass, String methodName, Class<?>[] paramTypes, Propagation expected)
            throws Exception {
        Method method = serviceClass.getMethod(methodName, paramTypes);
        Transactional tx = method.getAnnotation(Transactional.class);
        assertThat(tx)
            .as("FKH-061 A3: %s#%s módszer-szintű @Transactional", serviceClass.getSimpleName(), methodName)
            .isNotNull();
        assertThat(tx.propagation())
            .as("FKH-061 A3: %s#%s propagation", serviceClass.getSimpleName(), methodName)
            .isEqualTo(expected);
    }

    // ============ A3b: hard lépések hangosan buktatják a zárást ============

    @Test
    @DisplayName("FKH-061 A3b: napi mérleg hiba → ValidationException a lépés nevével, markClosingDone sosem fut")
    void balanceStepFailsClosingLoudly() {
        LocalDate closingDate = LocalDate.of(2026, 9, 15);
        doThrow(new RuntimeException("db down"))
            .when(dailyBalanceService).calculateAllCurrenciesForDay(any(), any());

        assertThatThrownBy(() -> dailyClosingService.startDailyClosing(closingDate))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Napi mérleg számítás sikertelen");
        verify(closingControlService, never()).markClosingDone(any(), any(), any(), any());
    }

    @Test
    @DisplayName("FKH-061 A3b: SZÁMZÁR/TH igazítás hiba → ValidationException a lépés nevével")
    void closingAdjustmentStepFailsClosingLoudly() {
        LocalDate closingDate = LocalDate.of(2026, 9, 15);
        doThrow(new RuntimeException("th down"))
            .when(dailyBalanceService).recordClosingAdjustments(any(), any());

        assertThatThrownBy(() -> dailyClosingService.startDailyClosing(closingDate))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("SZÁMZÁR");
        verify(closingControlService, never()).markClosingDone(any(), any(), any(), any());
    }

    // ============ Sértetlenség-pinning: sikeres zárás továbbra is warning-mentes ============

    @Test
    @DisplayName("FKH-061 regresszió: hibátlan zárás → üres warnings, dekádriport meghívódik dekádnapon")
    void cleanClosingStillGeneratesDecadeReportWithoutWarnings() {
        LocalDate closingDate = LocalDate.of(2026, 9, 10);
        when(decadeReportService.generateDecadeReport(any(), anyInt(), anyInt()))
            .thenReturn(mock(DecadeReportDto.class));

        DailyClosingService.ClosingWizardResult result =
            dailyClosingService.startDailyClosing(closingDate);

        assertThat(result.isAllPassed()).isTrue();
        assertThat(result.getWarnings()).isEmpty();
        // szeptember 10. = 9. hónap 1. dekádja → globalDecade = (9-1)*3 + 1 = 25
        verify(decadeReportService).generateDecadeReport(BRANCH_ID, 2026, 25);
    }
}
