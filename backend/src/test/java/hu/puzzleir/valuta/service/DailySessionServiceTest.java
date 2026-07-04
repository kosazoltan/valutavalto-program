package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationCountRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DailySessionServiceTest {

    @Mock
    private DailySessionRepository dailySessionRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private DenominationCountRepository denominationCountRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private CashBalanceService cashBalanceService;

    @InjectMocks
    private DailySessionService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();
    private final Long workerId = 101L;

    @BeforeEach
    void setupSecurityContext() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("ADMIN", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(workerId, companyId, branchId, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("openDay handles inconsistent cash balances without internal error")
    void openDay_handlesInconsistentBalancesWithout500() {
        Company company = Company.builder().id(companyId).code("EBC").name("EBC").build();
        Branch branch = Branch.builder().id(branchId).code("B01").name("Kozpont").company(company).build();
        Worker worker = Worker.builder()
                .id(workerId)
                .code("ADMIN")
                .name("Admin")
                .passwordHash("x")
                .role(WorkerRole.CASHIER)
                .company(company)
                .branch(branch)
                .build();

        CashBalance brokenBalance = CashBalance.builder()
                .branch(branch)
                .company(company)
                .currency(null)
                .currentBalance(null)
                .build();

        DailySession savedSession = DailySession.builder()
                .id(1L)
                .branch(branch)
                .company(company)
                .sessionDate(LocalDate.now())
                .openingBalanceHuf(BigDecimal.ZERO)
                .build();

        when(dailySessionRepository.findOpenSessionsByBranch(org.mockito.ArgumentMatchers.eq(companyId), org.mockito.ArgumentMatchers.eq(branchId))).thenReturn(List.of());
        when(dailySessionRepository.findByBranchIdAndSessionDate(org.mockito.ArgumentMatchers.eq(companyId), eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.empty());
        when(dailySessionRepository.findLatest(org.mockito.ArgumentMatchers.eq(companyId), org.mockito.ArgumentMatchers.eq(branchId))).thenReturn(Optional.empty());
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(workerId)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchId(branchId)).thenReturn(List.of(brokenBalance));
        when(dailySessionRepository.save(any(DailySession.class))).thenReturn(savedSession);
        when(cashBalanceRepository.save(any(CashBalance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DailySession result = service.openDay();

        assertNotNull(result);
        assertEquals(BigDecimal.ZERO, result.getOpeningBalanceHuf());
        assertEquals(BigDecimal.ZERO, brokenBalance.getCurrentBalance());
        assertEquals(BigDecimal.ZERO, brokenBalance.getOpeningBalance());
        assertEquals(0L, brokenBalance.getVersion());
    }
    @Test
    @DisplayName("Issue #110: openDay auto-init cash_balance rekordokat hiv uj branch-en")
    void openDay_autoInitsCashBalancesForNewBranch() {
        Company company = Company.builder().id(companyId).code("EBC").name("EBC").build();
        Branch branch = Branch.builder().id(branchId).code("B99").name("Uj Iroda").company(company).build();
        Worker worker = Worker.builder()
                .id(workerId)
                .code("ADMIN")
                .name("Admin")
                .passwordHash("x")
                .role(WorkerRole.CASHIER)
                .company(company)
                .branch(branch)
                .build();

        DailySession savedSession = DailySession.builder()
                .id(2L)
                .branch(branch)
                .company(company)
                .sessionDate(LocalDate.now())
                .openingBalanceHuf(BigDecimal.ZERO)
                .build();

        when(dailySessionRepository.findOpenSessionsByBranch(org.mockito.ArgumentMatchers.eq(companyId), org.mockito.ArgumentMatchers.eq(branchId))).thenReturn(List.of());
        when(dailySessionRepository.findByBranchIdAndSessionDate(org.mockito.ArgumentMatchers.eq(companyId), eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.empty());
        when(dailySessionRepository.findLatest(org.mockito.ArgumentMatchers.eq(companyId), org.mockito.ArgumentMatchers.eq(branchId))).thenReturn(Optional.empty());
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(workerId)).thenReturn(Optional.of(worker));
        // Uj branch: cash_balance meg ures
        when(cashBalanceRepository.findByBranchId(branchId)).thenReturn(List.of());
        when(dailySessionRepository.save(any(DailySession.class))).thenReturn(savedSession);

        DailySession result = service.openDay();

        assertNotNull(result);
        // Issue #110: auto-init kell hogy meghivva legyen pontosan 1x
        verify(cashBalanceService, times(1)).initializeBranchBalances(branchId);
    }

    @Test
    @DisplayName("FK-038: openDay ÉRTÉKTÁR fiókra ValidationException — NINCS daily_session, NINCS cash_balance init")
    void openDay_vaultBranch_rejected() {
        Company company = Company.builder().id(companyId).code("EBC").name("EBC").build();
        Branch vault = Branch.builder().id(branchId).code("BR020").name("Szeged Értéktár")
                .company(company).isVault(true).build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(vault));

        // FK-038: a gate a metódus elején, a stale-session-zárás és a session-mentés ELŐTT dob.
        assertThatThrownBy(() -> service.openDay())
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Értéktári fiók nem nyithat");

        verify(dailySessionRepository, never()).save(any(DailySession.class));
        verify(cashBalanceService, never()).initializeBranchBalances(any());
    }

    @Test
    @DisplayName("FK-038: getSessionHistory az ÉRTÉKTÁR-kizáró query-t hívja (a Zárási-állapot widget A-forrása)")
    void getSessionHistory_excludesVault() {
        LocalDate from = LocalDate.now();
        LocalDate to = LocalDate.now();
        DailySession penztarSession = DailySession.builder().id(1L).sessionDate(from).build();
        when(dailySessionRepository.findByDateRangeExcludingVault(companyId, from, to))
                .thenReturn(List.of(penztarSession));

        List<DailySession> result = service.getSessionHistory(from, to);

        assertEquals(1, result.size());
        // A widget A-forrása a vault-KIZÁRÓ query-t hívja — NEM a sima findByDateRange-t, különben
        // egy (legacy) vault daily_session tévesen megjelenne a pénztári zárás-állapot csempén.
        verify(dailySessionRepository).findByDateRangeExcludingVault(companyId, from, to);
        verify(dailySessionRepository, never()).findByDateRange(any(), any(), any());
    }

    // === Codex P1 (2026-05-31, #944 review) — sztorno-plafon lockolo szamlalo ===

    @Test
    @DisplayName("getDailyReversalCountForUpdate - a PESSIMISTIC_WRITE-lockolt session reversalCount-jat adja vissza")
    void getDailyReversalCountForUpdate_returnsLockedCount() {
        DailySession locked = DailySession.builder()
                .id(7L)
                .sessionDate(LocalDate.now())
                .reversalCount(2)
                .build();
        when(dailySessionRepository.findByBranchIdAndSessionDateForUpdate(eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.of(locked));

        assertEquals(2, service.getDailyReversalCountForUpdate());
    }

    @Test
    @DisplayName("getDailyReversalCountForUpdate - nincs session a lock-ponton -> ValidationException (fail-loud: a plafon NEM kerulhet ki csendben 0-val)")
    void getDailyReversalCountForUpdate_noSession_throws() {
        // A validateOpenSession elvileg garantalja a nyitott sort, de a lockolo uton az ures
        // talalat invarians-sertes -> dobni kell, NEM 0-t adni (kulonben a plafon csendben kikerul).
        when(dailySessionRepository.findByBranchIdAndSessionDateForUpdate(eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getDailyReversalCountForUpdate())
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("munkamenet");
    }
}
