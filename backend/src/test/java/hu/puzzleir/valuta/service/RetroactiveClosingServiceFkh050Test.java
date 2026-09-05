package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.dto.retroactiveclosing.OpenPastDayDto;
import hu.puzzleir.valuta.dto.retroactiveclosing.RetroactiveReconciliationDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-050: user-initiated simplified retroactive closing of past open daily sessions.
 *
 * <p>Unit tests over {@link RetroactiveClosingService} (mock repositories/services).
 * Multi-tenant invariant #1: every query companyId-scoped, enforced here through
 * {@code requireRetroactiveScope} (own branch or vault-region scope).</p>
 */
@ExtendWith(MockitoExtension.class)
class RetroactiveClosingServiceFkh050Test {

    @Mock
    private DailySessionRepository dailySessionRepository;
    @Mock
    private DailyBalanceRepository dailyBalanceRepository;
    @Mock
    private DenominationBalanceRepository denominationBalanceRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private WorkerRepository workerRepository;
    @Mock
    private AccessScopeService accessScopeService;
    @Mock
    private ClosingToleranceService closingToleranceService;
    @Mock
    private DailyBalanceService dailyBalanceService;
    @Mock
    private EveningClosingService eveningClosingService;
    @Mock
    private ClosingControlService closingControlService;
    @Mock
    private DailySessionService dailySessionService;
    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private RetroactiveClosingService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();
    private final Long workerId = 101L;

    @BeforeEach
    void setupSecurityContext() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("CASHIER1", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(workerId, companyId, branchId, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
        // Company-wide default scope (null = company-wide). Mockito's RETURNS_DEFAULTS
        // returns an EMPTY Set ("see nothing"), so pin the null explicitly.
        Mockito.lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // ---------------------------------------------------------------------
    // FR-1 — list own open past days only (companyId + branch scoped, ASC, no today)
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FR-1: list returns only own company+branch open past days, ASC, today excluded")
    void fr1_listReturnsOnlyOwnCompanyBranchOpenPastDays_excludingToday() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        LocalDate d1 = today.minusDays(1);

        // Repository is expected to be queried with companyId + branchId + today.
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d3), session(d1)));

        List<OpenPastDayDto> result = service.listOpenPastDays(branchId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).date()).isEqualTo(d3);
        assertThat(result.get(1).date()).isEqualTo(d1);
        verify(dailySessionRepository).findOpenPastSessionsByBranch(companyId, branchId, today);
    }

    @Test
    @DisplayName("FR-1/D2: scope guard rejects a branch outside company+region before any data access")
    void fr1_scopeGuardRejectsForeignBranch() {
        UUID foreignBranch = UUID.randomUUID();
        // Scope narrowed to a vault region that does NOT contain the foreign branch.
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(branchId));

        assertThatThrownBy(() -> service.listOpenPastDays(foreignBranch))
                .isInstanceOf(AccessDeniedException.class);
        verify(dailySessionRepository, never()).findOpenPastSessionsByBranch(any(), any(), any());
    }

    // ---------------------------------------------------------------------
    // D3 — chronological, oldest-first
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("D3: close rejects a newer day while an older open day exists; oldest closes fine")
    void d3_closeRejectsNewerDayWhileOlderOpenDayExists() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        LocalDate d1 = today.minusDays(1);

        // Attempt 1: close D-1 while D-3 is still open -> reject.
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d3), session(d1)));

        assertThatThrownBy(() -> service.closeRetroactively(branchId, d1))
                .isInstanceOf(ValidationException.class);
        verify(eveningClosingService, never()).prepareDailyPackage(any(UUID.class), any());

        // Attempt 2: close the oldest (D-3) -> allowed through the ordering gate.
        DailySession d3Session = session(d3);
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d3, companyId)).thenReturn(Optional.of(d3Session));
        stubReconciliationClean(d3);
        stubCloseHappyPath(d3);

        service.closeRetroactively(branchId, d3);

        assertThat(d3Session.getStatus()).isEqualTo(DailySessionStatus.CLOSED);

        // Attempt 3: now D-1 is the oldest -> closes too.
        Mockito.reset(dailySessionRepository);
        DailySession d1Session = session(d1);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d1)));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d1, companyId)).thenReturn(Optional.of(d1Session));
        stubReconciliationClean(d1);
        stubCloseHappyPath(d1);

        service.closeRetroactively(branchId, d1);

        assertThat(d1Session.getStatus()).isEqualTo(DailySessionStatus.CLOSED);
    }

    // ---------------------------------------------------------------------
    // FR-6 / FR-7 — close sets CLOSED + retroactive audit fields
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FR-6/FR-7: close sets CLOSED, isRetroactiveClosing, retroactive worker/time,"
            + " writes RETROACTIVE_CLOSING_EXECUTED audit and marks the PAST date EVENING control")
    void fr6_fr7_closeSetsClosedAndRetroactiveAuditFields() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        DailySession d3Session = session(d3);

        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(d3Session));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d3, companyId)).thenReturn(Optional.of(d3Session));
        stubReconciliationClean(d3);
        stubCloseHappyPath(d3);

        service.closeRetroactively(branchId, d3);

        // FR-6: session closed with the past day's book closing balance, not today's cash.
        assertThat(d3Session.getStatus()).isEqualTo(DailySessionStatus.CLOSED);
        assertThat(d3Session.getClosedAt()).isNotNull();
        assertThat(d3Session.getClosingBalanceHuf()).isEqualByComparingTo("100000.00");

        // FR-7: retroactive audit fields, distinct from session_date.
        assertThat(d3Session.getIsRetroactiveClosing()).isTrue();
        assertThat(d3Session.getRetroactiveClosedByWorker()).isNotNull();
        assertThat(d3Session.getRetroactiveClosedByWorker().getId()).isEqualTo(workerId);
        assertThat(d3Session.getRetroactiveClosedAt()).isNotNull();
        assertThat(d3Session.getRetroactiveClosedAt().toLocalDate()).isEqualTo(LocalDate.now());
        assertThat(d3Session.getRetroactiveClosedAt().toLocalDate()).isNotEqualTo(d3Session.getSessionDate());

        // Closing control marked for the PAST date, EVENING.
        verify(closingControlService).markClosingDone(companyId, branchId, d3, ClosingMarkType.EVENING);

        // NFR-3: exactly one RETROACTIVE_CLOSING_EXECUTED audit row.
        ArgumentCaptor<String> action = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).log(action.capture(), anyString(), anyString());
        assertThat(action.getValue()).isEqualTo("RETROACTIVE_CLOSING_EXECUTED");
    }

    // ---------------------------------------------------------------------
    // NFR-1 — intermediate days untouched
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("NFR-1: closing D-3 touches no daily_session/daily_balance row of D-2..today")
    void nfr1_intermediateDaysUntouched() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        DailySession d3Session = session(d3);

        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(d3Session));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d3, companyId)).thenReturn(Optional.of(d3Session));
        stubReconciliationClean(d3);
        stubCloseHappyPath(d3);

        service.closeRetroactively(branchId, d3);

        // The ONLY daily_session row ever persisted is the target session itself.
        ArgumentCaptor<DailySession> savedSession = ArgumentCaptor.forClass(DailySession.class);
        verify(dailySessionRepository).save(savedSession.capture());
        assertThat(savedSession.getValue().getSessionDate()).isEqualTo(d3);

        // No daily_balance write for any date other than the closed one.
        verify(dailyBalanceRepository, never()).save(any());

        // No session lookup/write for intermediate days (D-2, D-1, today).
        verify(dailySessionRepository, never()).findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(today.minusDays(2)), eq(companyId));
        verify(dailySessionRepository, never()).findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(today.minusDays(1)), eq(companyId));
        verify(dailySessionRepository, never()).findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(today), eq(companyId));

        // Denomination calculation for the past date only (balance_date=submission_date=D-3).
        verify(dailyBalanceService).calculateAllCurrenciesForDay(branchId, d3);
        verify(dailyBalanceService, never()).calculateAllCurrenciesForDay(any(), eq(today));
    }

    // ---------------------------------------------------------------------
    // FR-5 — expected from the PAST day's daily_balance closing balance
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FR-5: reconciliation expected = past day daily_balance closing balance,"
            + " today's cash_balance (555000) never appears")
    void fr5_expectedComesFromPastDayClosingBalance() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);

        // Past day book value = 100000 HUF.
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(branchId, d3, "HUF"))
                .thenReturn(Optional.of(DailyBalance.builder()
                        .branchId(branchId)
                        .balanceDate(d3)
                        .currencyCode("HUF")
                        .closingBalance(new BigDecimal("100000.00"))
                        .build()));
        // Today's cash_balance must NOT be used — stub it so a misuse would still resolve.
        Currency huf = Currency.builder().id(1L).code("HUF").name("Forint").build();
        Mockito.lenient().when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(List.of(CashBalance.builder()
                        .currency(huf)
                        .currentBalance(new BigDecimal("555000.00"))
                        .build()));
        // Counted EVENING HUF stock with submissionDate = D-3 is 100000.
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, d3, hu.puzzleir.valuta.entity.DenominationCategory.EVENING))
                .thenReturn(List.of(new Object[]{"HUF", new BigDecimal("100000.00")}));
        when(closingToleranceService.getToleranceFor("HUF"))
                .thenReturn(ClosingTolerance.fallbackOf(BigDecimal.ONE));

        RetroactiveReconciliationDto result = service.reconcile(branchId, d3);

        assertThat(result.date()).isEqualTo(d3);
        assertThat(result.rows()).hasSize(1);
        RetroactiveReconciliationDto.Row row = result.rows().get(0);
        assertThat(row.currencyCode()).isEqualTo("HUF");
        assertThat(row.expected()).isEqualByComparingTo("100000.00");
        assertThat(row.actual()).isEqualByComparingTo("100000.00");
        assertThat(row.difference()).isEqualByComparingTo("0");
        assertThat(row.blocking()).isFalse();
        assertThat(result.anyBlocking()).isFalse();

        // The reconciliation must be computed for the PAST date, never today.
        verify(dailyBalanceService).calculateAllCurrenciesForDay(branchId, d3);
        verify(denominationBalanceRepository).sumActualStockByCurrency(
                branchId, d3, hu.puzzleir.valuta.entity.DenominationCategory.EVENING);
        // 555000 (today's cash) must appear nowhere.
        assertThat(row.expected()).isNotEqualByComparingTo("555000.00");
        assertThat(row.actual()).isNotEqualByComparingTo("555000.00");
    }

    // ---------------------------------------------------------------------
    // FR-6 — send failure leaves the day open
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FR-6: evening package send failure -> exception, session stays OPEN,"
            + " no audit row, no control mark")
    void fr6_sendFailureLeavesDayOpen() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        DailySession d3Session = session(d3);

        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(d3Session));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d3, companyId)).thenReturn(Optional.of(d3Session));
        stubReconciliationClean(d3);
        DailyDataPackage pkg = DailyDataPackage.builder().build();
        when(eveningClosingService.prepareDailyPackage(branchId, d3)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg))
                .thenReturn(DataSyncResult.failure("connection refused", 3));

        assertThatThrownBy(() -> service.closeRetroactively(branchId, d3))
                .isInstanceOf(ValidationException.class);

        assertThat(d3Session.getStatus()).isEqualTo(DailySessionStatus.OPEN);
        assertThat(d3Session.getIsRetroactiveClosing()).isFalse();
        assertThat(d3Session.getRetroactiveClosedAt()).isNull();
        verify(closingControlService, never()).markClosingDone(any(), any(), any(), any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
        verify(dailySessionRepository, never()).save(any());
    }

    // ---------------------------------------------------------------------
    // D7 — blocking difference rejects the close
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("D7: counted 90000 vs expected 100000 (HUF tolerance 1) -> close rejected, unchanged")
    void d7_blockingDifferenceRejectsClose() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        DailySession d3Session = session(d3);

        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(d3Session));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(branchId, d3, "HUF"))
                .thenReturn(Optional.of(DailyBalance.builder()
                        .branchId(branchId)
                        .balanceDate(d3)
                        .currencyCode("HUF")
                        .closingBalance(new BigDecimal("100000.00"))
                        .build()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, d3, hu.puzzleir.valuta.entity.DenominationCategory.EVENING))
                .thenReturn(List.of(new Object[]{"HUF", new BigDecimal("90000.00")}));
        when(closingToleranceService.getToleranceFor("HUF"))
                .thenReturn(ClosingTolerance.explicitOf(BigDecimal.ONE));

        assertThatThrownBy(() -> service.closeRetroactively(branchId, d3))
                .isInstanceOf(ValidationException.class);

        assertThat(d3Session.getStatus()).isEqualTo(DailySessionStatus.OPEN);
        verify(eveningClosingService, never()).prepareDailyPackage(any(UUID.class), any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
    }

    // ---------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------

    private DailySession session(LocalDate date) {
        return DailySession.builder()
                .id(date.getDayOfYear() + 100L)
                .sessionDate(date)
                .status(DailySessionStatus.OPEN)
                .build();
    }

    /** Clean reconciliation for the given date (expected == actual == 100000 HUF). */
    private void stubReconciliationClean(LocalDate date) {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, "HUF"))
                .thenReturn(Optional.of(DailyBalance.builder()
                        .branchId(branchId)
                        .balanceDate(date)
                        .currencyCode("HUF")
                        .closingBalance(new BigDecimal("100000.00"))
                        .build()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, date, hu.puzzleir.valuta.entity.DenominationCategory.EVENING))
                .thenReturn(List.of(new Object[]{"HUF", new BigDecimal("100000.00")}));
        when(closingToleranceService.getToleranceFor("HUF"))
                .thenReturn(ClosingTolerance.fallbackOf(BigDecimal.ONE));
    }

    /** Happy-path close side effects: package prepared + sent, control marked. */
    private void stubCloseHappyPath(LocalDate date) {
        DailyDataPackage pkg = DailyDataPackage.builder().build();
        when(eveningClosingService.prepareDailyPackage(branchId, date)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg)).thenReturn(DataSyncResult.success("chk"));
        when(workerRepository.findById(workerId))
                .thenReturn(Optional.of(Worker.builder().id(workerId).code("CASHIER1").build()));
    }
}
