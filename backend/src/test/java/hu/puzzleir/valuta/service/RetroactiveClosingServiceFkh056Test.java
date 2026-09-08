package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.DenominationCategory;
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
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
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
 * FKH-056: simplified close of a FALSE_CLOSED day (CLOSED + closedByWorker ==
 * null + isRetroactiveClosing not TRUE) — re-stamp so the day leaves the
 * findFalseClosedPastSessionsByBranch fingerprint. No EVENING exists-check, no
 * blocking tolerance, no HQ send, no unconfirmed-incoming gate (plan D7).
 */
@ExtendWith(MockitoExtension.class)
class RetroactiveClosingServiceFkh056Test {

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
    @Mock
    private UnconfirmedIncomingClosingGate unconfirmedIncomingClosingGate;
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
        Mockito.lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FKH-056 T1: oldest FALSE_CLOSED day closes simplified — stamp + calculateAll + audit; never exists/send")
    void t1_happyPath_oldestFalseClosed_stampedAndAudited() {
        LocalDate today = LocalDate.now();
        LocalDate pastDate = today.minusDays(3);
        DailySession falseClosed = falseClosedSession(pastDate);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(falseClosed));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, pastDate, companyId)).thenReturn(Optional.of(falseClosed));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(
                companyId, branchId, pastDate, "HUF"))
                .thenReturn(Optional.of(DailyBalance.builder()
                        .branchId(branchId)
                        .balanceDate(pastDate)
                        .currencyCode("HUF")
                        .closingBalance(new BigDecimal("250000.00"))
                        .build()));
        Worker worker = Worker.builder().id(workerId).code("CASHIER1").build();
        when(workerRepository.findById(workerId)).thenReturn(Optional.of(worker));

        DailySession closed = service.closeRetroactivelySimplified(branchId, pastDate);

        assertThat(closed.getStatus()).isEqualTo(DailySessionStatus.CLOSED);
        assertThat(closed.getClosedByWorker()).isSameAs(worker);
        assertThat(closed.getIsRetroactiveClosing()).isTrue();
        assertThat(closed.getRetroactiveClosedByWorker()).isSameAs(worker);
        assertThat(closed.getRetroactiveClosedAt()).isNotNull();
        assertThat(closed.getClosedAt()).isNotNull();
        assertThat(closed.getClosingBalanceHuf()).isEqualByComparingTo("250000.00");

        verify(dailyBalanceService).calculateAllCurrenciesForDay(branchId, pastDate);
        verify(denominationBalanceRepository, never()).existsByBranchIdAndDateAndCategory(
                any(), any(), any(DenominationCategory.class));
        verify(eveningClosingService, never()).sendToHeadquarters(any());
        verify(unconfirmedIncomingClosingGate, never()).ensureNoUnconfirmedIncoming(any(), any());
        verify(auditLogService).log(eq("RETROACTIVE_CLOSE_SIMPLIFIED"), any(), eq(branchId.toString()));
        verify(dailySessionRepository).save(falseClosed);
    }

    @Test
    @DisplayName("FKH-056 T2: non-oldest FALSE_CLOSED day is rejected — no save, no audit, no lock")
    void t2_nonOldestFalseClosed_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate oldest = today.minusDays(5);
        LocalDate newer = today.minusDays(3);
        DailySession older = falseClosedSession(oldest);
        DailySession requested = falseClosedSession(newer);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(older, requested));

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, newer))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("legrégebbi feldolgozható napon");

        verify(dailySessionRepository, never()).findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                any(), any(), any());
        verify(dailySessionRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("FKH-056 T3: out-of-scope branch → AccessDenied, no save")
    void t3_outOfScopeBranch_accessDenied() {
        UUID otherBranch = UUID.randomUUID();
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(otherBranch));
        LocalDate pastDate = LocalDate.now().minusDays(3);

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, pastDate))
                .isInstanceOf(AccessDeniedException.class);

        verify(dailySessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("FKH-056 T4: today/future → past-date ValidationException")
    void t4_todayOrFuture_rejected() {
        LocalDate today = LocalDate.now();

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, today))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("múlt-beli napra");
        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, today.plusDays(1)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("múlt-beli napra");

        verify(dailySessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("FKH-056 T5: OPEN session as oldest → simplified close rejects (not FALSE_CLOSED)")
    void t5_openSession_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate pastDate = today.minusDays(3);
        DailySession open = DailySession.builder()
                .id(500L)
                .sessionDate(pastDate)
                .status(DailySessionStatus.OPEN)
                .build();
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(open));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, pastDate, companyId)).thenReturn(Optional.of(open));

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, pastDate))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("tévesen lezárt");

        verify(dailySessionRepository, never()).save(any());
        verify(auditLogService, never()).log(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("FKH-056 T6: genuine CLOSED (closedByWorker set) → reject")
    void t6_genuineClosed_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate pastDate = today.minusDays(3);
        DailySession genuine = DailySession.builder()
                .id(501L)
                .sessionDate(pastDate)
                .status(DailySessionStatus.CLOSED)
                .closedByWorker(Worker.builder().id(9L).code("OTHER").build())
                .isRetroactiveClosing(true)
                .build();
        // D5 race: the row is listed as FALSE_CLOSED at gate time, but a concurrent
        // closeRetroactively stamped it genuine CLOSED before this call takes the
        // lock — the fingerprint re-check UNDER the lock must reject (no save).
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(genuine));
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, pastDate, companyId)).thenReturn(Optional.of(genuine));

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, pastDate))
                .isInstanceOf(ValidationException.class);

        verify(dailySessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("FKH-056 T7: EMPTY vault scope + other branch → AccessDenied")
    void t7_emptyVaultScope_accessDenied() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of());
        LocalDate pastDate = LocalDate.now().minusDays(3);

        assertThatThrownBy(() -> service.closeRetroactivelySimplified(branchId, pastDate))
                .isInstanceOf(AccessDeniedException.class);

        verify(dailySessionRepository, never()).save(any());
    }

    private DailySession falseClosedSession(LocalDate date) {
        return DailySession.builder()
                .id(date.getDayOfYear() + 100L)
                .sessionDate(date)
                .status(DailySessionStatus.CLOSED)
                .closedByWorker(null)
                .isRetroactiveClosing(null)
                .build();
    }
}
