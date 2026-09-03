package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
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
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
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
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
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

    // FKH-048: regional vault scope post-filter for getSessionHistory. The company-wide
    // (null) default is pinned in setupSecurityContext via a lenient stub — see PLAN GAP:
    // Mockito's RETURNS_DEFAULTS would return an EMPTY Set ("see nothing"), not null.
    @Mock
    private AccessScopeService accessScopeService;

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
        // FKH-048: pin the company-wide default explicitly. Mockito's RETURNS_DEFAULTS gives
        // an EMPTY Set for vaultRegionBranchScopeOrNull() (collection return type), which
        // means "see nothing" and would filter out every session for the pre-existing
        // company-wide tests. Lenient: most tests never reach getSessionHistory (strict
        // stubs would flag the stub as unnecessary).
        Mockito.lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
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
        when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId)).thenReturn(List.of(brokenBalance));
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
        when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId)).thenReturn(List.of());
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

    @Test
    @DisplayName("FKH-048: getSessionHistory filters foreign-region sessions for a regional vault worker")
    void getSessionHistory_regionalVaultWorker_filtersForeignRegionSessions() {
        LocalDate from = LocalDate.now();
        LocalDate to = LocalDate.now();
        UUID szegedBranchId = UUID.randomUUID();
        UUID bekescsabaBranchId = UUID.randomUUID();
        Branch szegedBranch = Branch.builder().id(szegedBranchId).build();
        Branch bekescsabaBranch = Branch.builder().id(bekescsabaBranchId).build();
        DailySession szegedSession = DailySession.builder().id(1L).sessionDate(from).branch(szegedBranch).build();
        DailySession bekescsabaSession = DailySession.builder().id(2L).sessionDate(from).branch(bekescsabaBranch).build();
        when(dailySessionRepository.findByDateRangeExcludingVault(companyId, from, to))
                .thenReturn(List.of(szegedSession, bekescsabaSession));

        Set<UUID> scope = Set.of(szegedBranchId);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(scope);
        // Stub per branch id STRING — proves the real collaborator is consulted,
        // not a homemade region compare. isBranchVisible takes (Set<UUID>, String).
        when(accessScopeService.isBranchVisible(eq(scope), eq(szegedBranchId.toString()))).thenReturn(true);
        when(accessScopeService.isBranchVisible(eq(scope), eq(bekescsabaBranchId.toString()))).thenReturn(false);

        List<DailySession> result = service.getSessionHistory(from, to);

        assertEquals(1, result.size());
        assertEquals(szegedSession, result.get(0));
        verify(accessScopeService).vaultRegionBranchScopeOrNull();
    }

    @Test
    @DisplayName("FKH-048: getSessionHistory with company-wide (null) scope returns all non-vault sessions")
    void getSessionHistory_companyWideScope_returnsAllNonVaultSessions() {
        LocalDate from = LocalDate.now();
        LocalDate to = LocalDate.now();
        DailySession sessionA = DailySession.builder().id(1L).sessionDate(from).build();
        DailySession sessionB = DailySession.builder().id(2L).sessionDate(from).build();
        when(dailySessionRepository.findByDateRangeExcludingVault(companyId, from, to))
                .thenReturn(List.of(sessionA, sessionB));
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        List<DailySession> result = service.getSessionHistory(from, to);

        assertEquals(2, result.size());
        // scope == null short-circuit: no per-element visibility check is performed.
        verify(accessScopeService, never()).isBranchVisible(any(), anyString());
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
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(LocalDate.now()), eq(companyId)))
                .thenReturn(Optional.of(locked));

        assertEquals(2, service.getDailyReversalCountForUpdate());
    }

    @Test
    @DisplayName("getDailyReversalCountForUpdate - nincs session a lock-ponton -> ValidationException (fail-loud: a plafon NEM kerulhet ki csendben 0-val)")
    void getDailyReversalCountForUpdate_noSession_throws() {
        // A validateOpenSession elvileg garantalja a nyitott sort, de a lockolo uton az ures
        // talalat invarians-sertes -> dobni kell, NEM 0-t adni (kulonben a plafon csendben kikerul).
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(LocalDate.now()), eq(companyId)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getDailyReversalCountForUpdate())
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("munkamenet");
    }

    @Test
    @DisplayName("getDailyReversalCountForUpdate - mas ceg daily_session sora nem eleg, fail-closed ValidationException")
    void getDailyReversalCountForUpdate_crossTenantSessionExcluded_throws() {
        UUID otherCompanyId = UUID.randomUUID();
        // A lockolo repo-query companyId-vel szurt: ugyanazon branch+nap mas ceg sora nem talalat.
        when(dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(LocalDate.now()), eq(companyId)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getDailyReversalCountForUpdate())
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs nyitott napi munkamenet");

        verify(dailySessionRepository, never()).findByBranchIdAndSessionDateAndCompanyIdForUpdate(
                eq(branchId), eq(LocalDate.now()), eq(otherCompanyId));
    }

    // === kanban #4 (2026-09-01) — napzaras utani telepitesi ablak (FR-3) ===
    // A hitelesitett penztaros gep suite-telepitesi ablakanak allapotforrasa a
    // GET /daily-sessions/today: a mai session BARMELY statusszal visszakerul
    // (nem csak OPEN), igy a renderer a CLOSED_AFTER_DAY_END allapotot lathatja.

    @Test
    @DisplayName("kanban #4 T1: findTodaySession - a mai CLOSED sessiont adja vissza, NEM dob ValidationException-t (FR-3)")
    void findTodaySession_closedToday_returnsSessionWithoutThrow() {
        DailySession closedSession = DailySession.builder()
                .id(31L)
                .sessionDate(LocalDate.now())
                .status(DailySessionStatus.CLOSED)
                .build();
        when(dailySessionRepository.findByBranchIdAndSessionDateWithDetails(
                eq(companyId), eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.of(closedSession));

        Optional<DailySession> result = service.findTodaySession();

        assertThat(result).containsSame(closedSession);
    }

    @Test
    @DisplayName("kanban #4 T2: findTodaySession - a mai OPEN session szures nelkul visszakerul (nincs .filter)")
    void findTodaySession_openToday_returnsSessionUnfiltered() {
        DailySession openSession = DailySession.builder()
                .id(32L)
                .sessionDate(LocalDate.now())
                .status(DailySessionStatus.OPEN)
                .build();
        when(dailySessionRepository.findByBranchIdAndSessionDateWithDetails(
                eq(companyId), eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.of(openSession));

        Optional<DailySession> result = service.findTodaySession();

        assertThat(result).containsSame(openSession);
    }

    @Test
    @DisplayName("kanban #4 T3: findTodaySession - nincs mai rekord -> Optional.empty, NEM dob; a tenant-szures a security fixture-bol jon (AC-6)")
    void findTodaySession_noRecordToday_returnsEmptyWithoutThrow() {
        when(dailySessionRepository.findByBranchIdAndSessionDateWithDetails(
                eq(companyId), eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.empty());

        Optional<DailySession> result = service.findTodaySession();

        assertThat(result).isEmpty();
        verify(dailySessionRepository).findByBranchIdAndSessionDateWithDetails(
                companyId, branchId, LocalDate.now());
    }
}
