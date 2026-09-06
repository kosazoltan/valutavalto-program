package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-053: EVENING denomination row is required before a retroactive close.
 */
@ExtendWith(MockitoExtension.class)
class RetroactiveClosingServiceFkh053Test {

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
        Mockito.lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FKH-053 T1 (FR-1): close without EVENING rows is rejected; no send, no save, no calculate")
    void t1_closeWithoutEveningRows_rejected() {
        LocalDate today = LocalDate.now();
        LocalDate pastDate = today.minusDays(3);
        DailySession open = session(pastDate);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(open));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, pastDate, companyId)).thenReturn(Optional.of(open));
        when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                branchId, pastDate, DenominationCategory.EVENING)).thenReturn(false);

        assertThatThrownBy(() -> service.closeRetroactively(branchId, pastDate))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs rögzített esti címletezés erre a napra");

        verify(eveningClosingService, never()).sendToHeadquarters(any());
        verify(dailySessionRepository, never()).save(any());
        verify(dailyBalanceService, never()).calculateAllCurrenciesForDay(any(), any());
    }

    @Test
    @DisplayName("FKH-053 T2: EVENING exists and reconcile is clean → send is reached, session CLOSED")
    void t2_eveningExists_closeSucceeds() {
        LocalDate today = LocalDate.now();
        LocalDate pastDate = today.minusDays(3);
        DailySession open = session(pastDate);
        when(dailySessionRepository.findOpenPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of(open));
        when(dailySessionRepository.findFalseClosedPastSessionsByBranch(companyId, branchId, today))
                .thenReturn(List.of());
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                branchId, pastDate, companyId)).thenReturn(Optional.of(open));
        Mockito.lenient().when(denominationBalanceRepository.existsByBranchIdAndDateAndCategory(
                branchId, pastDate, DenominationCategory.EVENING)).thenReturn(true);

        Mockito.lenient().when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(
                companyId, branchId, pastDate, "HUF"))
                .thenReturn(Optional.of(DailyBalance.builder()
                        .branchId(branchId)
                        .balanceDate(pastDate)
                        .currencyCode("HUF")
                        .closingBalance(new BigDecimal("100000.00"))
                        .build()));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, pastDate, DenominationCategory.EVENING))
                .thenReturn(List.of());
        DailyDataPackage pkg = DailyDataPackage.builder().build();
        when(eveningClosingService.prepareDailyPackage(branchId, pastDate)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg)).thenReturn(DataSyncResult.success("chk"));
        when(workerRepository.findById(workerId))
                .thenReturn(Optional.of(Worker.builder().id(workerId).code("CASHIER1").build()));

        DailySession closed = service.closeRetroactively(branchId, pastDate);

        assertThat(closed.getStatus()).isEqualTo(DailySessionStatus.CLOSED);
        verify(eveningClosingService).sendToHeadquarters(any());
    }

    private DailySession session(LocalDate date) {
        return DailySession.builder()
                .id(date.getDayOfYear() + 100L)
                .sessionDate(date)
                .status(DailySessionStatus.OPEN)
                .build();
    }
}
