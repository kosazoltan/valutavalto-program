package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
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

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-052: the chronological "oldest first" gate of retroactive closing runs on
 * the UNION of OPEN and FALSE_CLOSED past days — the same set
 * {@code listOpenPastDays} displays — and it also guards
 * {@code reopenFalseClosed}, which had no order gate before.
 *
 * <p>A rejected close/reopen takes no row lock, writes nothing and logs no
 * audit entry (FR-1/FR-2). When the oldest processable day is FALSE_CLOSED,
 * {@code close(oldest)} passes the order gate and then fails on the existing
 * CLOSED check — no auto-reopen (ticket T7).</p>
 */
@ExtendWith(MockitoExtension.class)
class RetroactiveClosingServiceFkh052Test {

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
    // Test plan T1 — close gate on the union
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-052 T1 (FR-1): close of the oldest OPEN day is rejected while an older FALSE_CLOSED day exists")
    void close_olderFalseClosedExists_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate d1 = today.minusDays(1);
        LocalDate d10 = today.minusDays(10);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d1, DailySessionStatus.OPEN)));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d10)));

        assertThatThrownBy(() -> service.closeRetroactively(branchId, d1))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(d10.toString());

        verify(eveningClosingService, never()).prepareDailyPackage(any(UUID.class), any(LocalDate.class));
        verify(dailySessionRepository, never()).save(any());
    }

    // ---------------------------------------------------------------------
    // Test plan T3/T6 — reopen gate on the union
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-052 T3 (FR-2): reopen is rejected while an older FALSE_CLOSED day exists — no lock, no save, no audit")
    void reopen_olderFalseClosedExists_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate d1 = today.minusDays(1);
        LocalDate d10 = today.minusDays(10);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d10), falseClosedSession(d1)));

        assertThatThrownBy(() -> service.reopenFalseClosed(branchId, d1))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(d10.toString());

        verify(dailySessionRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
        verify(dailySessionRepository, never())
                .findByBranchIdAndSessionDateAndCompanyIdForUpdate(any(), any(), any());
    }

    @Test
    @DisplayName("FKH-052 T6 (C10): reopen is rejected when the oldest processable day is OPEN — no save, no audit")
    void reopen_oldestIsOpen_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate d1 = today.minusDays(1);
        LocalDate d10 = today.minusDays(10);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d10, DailySessionStatus.OPEN)));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d1)));

        assertThatThrownBy(() -> service.reopenFalseClosed(branchId, d1))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(d10.toString());

        verify(dailySessionRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
        verify(dailySessionRepository, never())
                .findByBranchIdAndSessionDateAndCompanyIdForUpdate(any(), any(), any());
    }

    // ---------------------------------------------------------------------
    // Test plan T5/T7 — close paths through the union gate
    // ---------------------------------------------------------------------

    @Test
    @DisplayName("FKH-052 T5 (NFR-2): close of the oldest OPEN day with an empty FALSE_CLOSED list proceeds to the row lock")
    void close_oldestOpenEmptyFalseClosed_proceedsToLock() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(session(d3, DailySessionStatus.OPEN)));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());

        // No session behind the lock -> the flow must have passed the order gate
        // and reached the lock (the missing-session error proves it).
        assertThatThrownBy(() -> service.closeRetroactively(branchId, d3))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs napi munkamenet");

        verify(dailySessionRepository)
                .findByBranchIdAndSessionDateAndCompanyIdForUpdate(branchId, d3, companyId);
    }

    @Test
    @DisplayName("FKH-052 T7: oldest processable day is FALSE_CLOSED -> close passes the order gate, then fails on the CLOSED check (no auto-reopen)")
    void close_oldestFalseClosed_passesGateFailsClosedCheck() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        DailySession locked = falseClosedSession(d3);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosedSession(d3)));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, d3, companyId)).thenReturn(Optional.of(locked));

        assertThatThrownBy(() -> service.closeRetroactively(branchId, d3))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Ez a nap már le van zárva");

        verify(eveningClosingService, never()).prepareDailyPackage(any(UUID.class), any(LocalDate.class));
    }

    // ---------------------------------------------------------------------
    // helpers (mirroring Fkh051Test)
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
