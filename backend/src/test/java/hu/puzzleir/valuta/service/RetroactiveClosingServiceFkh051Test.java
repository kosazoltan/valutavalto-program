package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.retroactiveclosing.OpenPastDayDto;
import hu.puzzleir.valuta.dto.retroactiveclosing.RetroactiveDayInspectionDto;
import hu.puzzleir.valuta.dto.retroactiveclosing.RetroactiveDayKind;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
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
 * FKH-051 (Test plan 4-12): inspect a typed past date, reopen false-closed days,
 * and list the union of OPEN + false-closed past days.
 *
 * <p>False-closed fingerprint (plan D3): past date + status CLOSED +
 * closedByWorker IS NULL + isRetroactiveClosing null-or-false. Reopen (plan D5)
 * is a separate state change, re-checked under the pessimistic row lock, audited
 * as RETROACTIVE_FALSE_CLOSED_REOPENED, and touches NO cash_balance row (NFR-1)
 * and recomputes NO later day (NFR-2).</p>
 */
@ExtendWith(MockitoExtension.class)
class RetroactiveClosingServiceFkh051Test {

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
        // Company-wide default scope (null). Mockito's RETURNS_DEFAULTS gives an
        // EMPTY Set ("see nothing"), so pin null explicitly (Fkh050Test pattern).
        Mockito.lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // ---------------------------------------------------------------------
    // Test plan 4-8 — inspect
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-051 T4: inspect false-closed day -> FALSE_CLOSED, canReprocess=true, canStart=false")
    void inspect_falseClosed_returnsFalseClosed() {
        LocalDate d2 = LocalDate.now().minusDays(2);
        when(dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, d2))
                .thenReturn(Optional.of(falseClosedSession(d2)));

        RetroactiveDayInspectionDto result = service.inspect(branchId, d2);

        assertThat(result.date()).isEqualTo(d2);
        assertThat(result.kind()).isEqualTo(RetroactiveDayKind.FALSE_CLOSED);
        assertThat(result.canReprocess()).isTrue();
        assertThat(result.canStart()).isFalse();
        assertThat(result.message()).isNotBlank();
    }

    @Test
    @DisplayName("FKH-051 T5: inspect genuine CLOSED (closedByWorker set OR retroactive) -> GENUINE_CLOSED, canReprocess=false")
    void inspect_genuineClosed_returnsGenuineClosed() {
        LocalDate d2 = LocalDate.now().minusDays(2);

        // Case A: normal close — closedByWorker is set.
        DailySession genuine = falseClosedSession(d2);
        genuine.setClosedByWorker(Worker.builder().id(workerId).code("CASHIER1").build());
        when(dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, d2))
                .thenReturn(Optional.of(genuine));

        RetroactiveDayInspectionDto resultA = service.inspect(branchId, d2);
        assertThat(resultA.kind()).isEqualTo(RetroactiveDayKind.GENUINE_CLOSED);
        assertThat(resultA.canReprocess()).isFalse();
        assertThat(resultA.canStart()).isFalse();

        // Case B: FKH-050 retroactive close — isRetroactiveClosing=true even without closedByWorker.
        DailySession retroactive = falseClosedSession(d2);
        retroactive.setClosedByWorker(null);
        retroactive.setIsRetroactiveClosing(true);
        when(dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, d2))
                .thenReturn(Optional.of(retroactive));

        RetroactiveDayInspectionDto resultB = service.inspect(branchId, d2);
        assertThat(resultB.kind()).isEqualTo(RetroactiveDayKind.GENUINE_CLOSED);
        assertThat(resultB.canReprocess()).isFalse();
    }

    @Test
    @DisplayName("FKH-051 T6: inspect OPEN past day -> OPEN, canStart=true")
    void inspect_openDay_returnsOpen() {
        LocalDate d3 = LocalDate.now().minusDays(3);
        when(dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, d3))
                .thenReturn(Optional.of(session(d3, DailySessionStatus.OPEN)));

        RetroactiveDayInspectionDto result = service.inspect(branchId, d3);

        assertThat(result.kind()).isEqualTo(RetroactiveDayKind.OPEN);
        assertThat(result.canStart()).isTrue();
        assertThat(result.canReprocess()).isFalse();
    }

    @Test
    @DisplayName("FKH-051 T7: inspect today or future -> NOT_PAST, no data access")
    void inspect_todayOrFuture_returnsNotPast() {
        RetroactiveDayInspectionDto today = service.inspect(branchId, LocalDate.now());
        assertThat(today.kind()).isEqualTo(RetroactiveDayKind.NOT_PAST);
        assertThat(today.canStart()).isFalse();
        assertThat(today.canReprocess()).isFalse();

        RetroactiveDayInspectionDto future = service.inspect(branchId, LocalDate.now().plusDays(1));
        assertThat(future.kind()).isEqualTo(RetroactiveDayKind.NOT_PAST);

        verify(dailySessionRepository, never()).findByBranchIdAndSessionDate(any(), any(), any());
    }

    @Test
    @DisplayName("FKH-051 T8: inspect missing session -> NO_SESSION, canStart=false")
    void inspect_missingSession_returnsNoSession() {
        LocalDate d4 = LocalDate.now().minusDays(4);
        when(dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, d4))
                .thenReturn(Optional.empty());

        RetroactiveDayInspectionDto result = service.inspect(branchId, d4);

        assertThat(result.kind()).isEqualTo(RetroactiveDayKind.NO_SESSION);
        assertThat(result.canStart()).isFalse();
        assertThat(result.canReprocess()).isFalse();
    }

    // ---------------------------------------------------------------------
    // Test plan 9-11 — reopen
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-051 T9: reopen false-closed day -> OPEN, closedAt/closingBalanceHuf null, audited")
    void reopen_falseClosed_setsOpenAndAudits() {
        LocalDate today = LocalDate.now();
        LocalDate d2 = today.minusDays(2);
        // FKH-052 union gate: the reopened day must be the oldest processable one.
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d2)));
        DailySession locked = falseClosedSession(d2);
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d2, companyId)).thenReturn(Optional.of(locked));
        when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> inv.getArgument(0));

        DailySession result = service.reopenFalseClosed(branchId, d2);

        assertThat(result.getStatus()).isEqualTo(DailySessionStatus.OPEN);
        assertThat(result.getClosedAt()).isNull();
        assertThat(result.getClosingBalanceHuf()).isNull();

        ArgumentCaptor<DailySession> captor = ArgumentCaptor.forClass(DailySession.class);
        verify(dailySessionRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DailySessionStatus.OPEN);

        verify(auditLogService).log(eq("RETROACTIVE_FALSE_CLOSED_REOPENED"), anyString(), anyString());
    }

    @Test
    @DisplayName("FKH-051 T10: reopen genuine CLOSED -> ValidationException, no save")
    void reopen_genuineClosed_throwsAndDoesNotMutate() {
        LocalDate today = LocalDate.now();
        LocalDate d2 = today.minusDays(2);
        // FKH-052 union gate: pass the order gate so the under-lock genuine-CLOSED
        // check remains the exercised path (finder list row differs from the locked
        // row — the gate only reads dates; the fingerprint check runs under lock).
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d2)));
        DailySession genuine = falseClosedSession(d2);
        genuine.setClosedByWorker(Worker.builder().id(workerId).code("CASHIER1").build());
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d2, companyId)).thenReturn(Optional.of(genuine));

        assertThatThrownBy(() -> service.reopenFalseClosed(branchId, d2))
                .isInstanceOf(ValidationException.class);

        verify(dailySessionRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("FKH-051 T11 (NFR-1/NFR-2): reopen touches no cash_balance and recomputes no day")
    void reopen_doesNotTouchCashBalance() {
        LocalDate today = LocalDate.now();
        LocalDate d2 = today.minusDays(2);
        // FKH-052 union gate: the reopened day must be the oldest processable one.
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d2)));
        DailySession locked = falseClosedSession(d2);
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d2, companyId)).thenReturn(Optional.of(locked));
        when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> inv.getArgument(0));

        service.reopenFalseClosed(branchId, d2);

        verify(cashBalanceRepository, never()).save(any());
        Mockito.verifyNoInteractions(dailyBalanceService);
    }

    // ---------------------------------------------------------------------
    // Test plan 12 — list union
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-051 T12 (D6): listOpenPastDays unions OPEN + false-closed, ascending, with kinds")
    void listOpenPastDays_unionsOpenAndFalseClosed() {
        LocalDate today = LocalDate.now();
        LocalDate d4 = today.minusDays(4);
        LocalDate d2 = today.minusDays(2);

        // Older OPEN day from the existing finder...
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d4, DailySessionStatus.OPEN)));
        // ...newer false-closed day from the new fingerprint finder.
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d2)));

        List<OpenPastDayDto> result = service.listOpenPastDays(branchId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).date()).isEqualTo(d4);
        assertThat(result.get(1).date()).isEqualTo(d2);
        assertThat(result.get(0).kind()).isEqualTo(RetroactiveDayKind.OPEN);
        assertThat(result.get(1).kind()).isEqualTo(RetroactiveDayKind.FALSE_CLOSED);
    }

    // ---------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------

    private DailySession session(LocalDate date, DailySessionStatus status) {
        return DailySession.builder()
                .id(date.getDayOfYear() + 100L)
                .sessionDate(date)
                .status(status)
                .build();
    }

    /** D3 fingerprint row: CLOSED, closedByWorker null, isRetroactiveClosing false. */
    private DailySession falseClosedSession(LocalDate date) {
        return DailySession.builder()
                .id(date.getDayOfYear() + 500L)
                .sessionDate(date)
                .status(DailySessionStatus.CLOSED)
                .closedAt(LocalDateTime.now().minusDays(1))
                .closedByWorker(null)
                .closingBalanceHuf(new BigDecimal("1000.00"))
                .isRetroactiveClosing(false)
                .build();
    }
}
