package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.session.SessionDataDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import hu.puzzleir.valuta.entity.Currency;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SessionOpenService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class SessionOpenServiceTest {

    @InjectMocks
    private SessionOpenService service;

    @Mock
    private DailySessionRepository dailySessionRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private BranchRepository branchRepository;

    // Issue #110: lazy cash_balance init dependency
    @Mock
    private CashBalanceService cashBalanceService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    private Company createCompany() {
        return Company.builder()
                .id(COMPANY_ID)
                .code("BEST")
                .name("Best Change Kft.")
                .build();
    }

    private Branch createBranch() {
        Branch b = new Branch();
        b.setId(BRANCH_ID);
        b.setCode("B01");
        b.setName("Budapest Keleti");
        return b;
    }

    private Worker createWorker() {
        return Worker.builder()
                .id(WORKER_ID)
                .code("P001")
                .name("Teszt Pénztáros")
                .build();
    }

    @Test
    @DisplayName("openSession → first day, empty balance")
    void testOpenSession_firstDay() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(createCompany()));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(createBranch()));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(createWorker()));
            when(dailySessionRepository.hasOpenSession(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(false);
            when(dailySessionRepository.findByBranchIdAndSessionDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Collections.emptyList());
            when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> {
                DailySession ds = inv.getArgument(0);
                ds.setId(1L);
                return ds;
            });
            when(dailySessionRepository.findLatest(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Optional.empty());

            SessionDataDto result = service.openSession(WORKER_ID, BRANCH_ID);

            assertThat(result).isNotNull();
            assertThat(result.getStatus()).isEqualTo("OPEN");
            assertThat(result.getOpeningBalances()).isEmpty();
            assertThat(result.getWorkerName()).isEqualTo("Teszt Pénztáros");
            assertThat(result.getBranchName()).isEqualTo("Budapest Keleti");
        }
    }

    @Test
    @DisplayName("FK-038: openSession ÉRTÉKTÁR fiókra ValidationException — NINCS session, NINCS cash_balance lazy-init")
    void testOpenSession_vaultBranch_rejected() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Branch vault = createBranch();
            vault.setIsVault(true);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(createCompany()));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(vault));

            // FK-038: az értéktár NEM nyithat pénztári napi munkamenetet — a gate a branch betöltése
            // után, MINDEN mellékhatás (cash_balance lazy-init, session-mentés) ELŐTT dob.
            assertThatThrownBy(() -> service.openSession(WORKER_ID, BRANCH_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Értéktári fiók nem nyithat");

            verify(dailySessionRepository, never()).save(any(DailySession.class));
            verify(cashBalanceService, never()).initializeBranchBalances(any());
            verify(cashBalanceRepository, never()).existsByBranchIdAndCompanyId(any(), any());
        }
    }

    @Test
    @DisplayName("openSession → cash_balance lazy init failure blocks session opening")
    void testOpenSession_cashBalanceInitFailure_blocksOpening() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(createCompany()));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(createBranch()));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(createWorker()));
            when(cashBalanceRepository.existsByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(false);
            when(cashBalanceService.initializeBranchBalances(BRANCH_ID))
                    .thenThrow(new RuntimeException("currency master missing"));

            assertThatThrownBy(() -> service.openSession(WORKER_ID, BRANCH_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Kasszaegyenlegek inicializálása sikertelen");
            verify(dailySessionRepository, never()).save(any(DailySession.class));
        }
    }

    @Test
    @DisplayName("openSession → with previous close, balance carried")
    void testOpenSession_withPreviousClose() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Create currency mock
            Currency eur = Currency.builder().id(1L).code("EUR").build();
            Currency usd = Currency.builder().id(2L).code("USD").build();

            CashBalance eurBalance = CashBalance.builder()
                    .id(1L)
                    .currency(eur)
                    .currentBalance(new BigDecimal("5000.00"))
                    .openingBalance(BigDecimal.ZERO)
                    .build();
            CashBalance usdBalance = CashBalance.builder()
                    .id(2L)
                    .currency(usd)
                    .currentBalance(new BigDecimal("3000.00"))
                    .openingBalance(BigDecimal.ZERO)
                    .build();

            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(createCompany()));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(createBranch()));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(createWorker()));
            when(dailySessionRepository.hasOpenSession(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(false);
            when(dailySessionRepository.findByBranchIdAndSessionDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(List.of(eurBalance, usdBalance));
            when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> {
                DailySession ds = inv.getArgument(0);
                ds.setId(2L);
                return ds;
            });
            when(dailySessionRepository.findLatest(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Optional.empty());

            SessionDataDto result = service.openSession(WORKER_ID, BRANCH_ID);

            assertThat(result).isNotNull();
            assertThat(result.getStatus()).isEqualTo("OPEN");
            assertThat(result.getOpeningBalances()).containsKey("EUR");
            assertThat(result.getOpeningBalances().get("EUR")).isEqualByComparingTo(new BigDecimal("5000.00"));
            assertThat(result.getOpeningBalances()).containsKey("USD");
            assertThat(result.getOpeningBalances().get("USD")).isEqualByComparingTo(new BigDecimal("3000.00"));
        }
    }

    @Test
    @DisplayName("validateSessionOpen → open session exists → warning")
    void testValidateSessionOpen_openSession() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            DailySession openSession = DailySession.builder()
                    .id(1L)
                    .branch(createBranch())
                    .sessionDate(LocalDate.now().minusDays(1))
                    .status(DailySessionStatus.OPEN)
                    .build();

            when(dailySessionRepository.findLatest(org.mockito.ArgumentMatchers.eq(COMPANY_ID), org.mockito.ArgumentMatchers.eq(BRANCH_ID))).thenReturn(Optional.of(openSession));
            when(dailySessionRepository.findByBranchIdAndSessionDate(org.mockito.ArgumentMatchers.eq(COMPANY_ID), eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Collections.emptyList());

            List<String> warnings = service.validateSessionOpen(BRANCH_ID);

            assertThat(warnings).isNotEmpty();
            assertThat(warnings).anyMatch(w -> w.contains("nincs lezárva") || w.contains("előző"));
        }
    }

    // === FKH-051 (Test plan 1-2): day-open must NOT auto-close past OPEN days ===

    @Test
    @DisplayName("FKH-051 T1: openSession does NOT auto-close a past OPEN session — it survives as OPEN")
    void testOpenSession_pastOpenSession_isNotAutoClosed() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            LocalDate pastDate = LocalDate.now().minusDays(2);
            DailySession pastSession = DailySession.builder()
                    .id(90L)
                    .branch(createBranch())
                    .sessionDate(pastDate)
                    .status(DailySessionStatus.OPEN)
                    .openingBalanceHuf(new BigDecimal("1000.00"))
                    .build();

            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(createCompany()));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(createBranch()));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(createWorker()));
            // Lenient: FKH-051 WU6 deletes the force-close loop, the only caller of
            // findOpenSessionsByBranch inside openSession — the stub must not turn
            // into an UnnecessaryStubbing failure once the loop is gone.
            Mockito.lenient().when(dailySessionRepository.findOpenSessionsByBranch(COMPANY_ID, BRANCH_ID))
                    .thenReturn(List.of(pastSession));
            when(dailySessionRepository.hasOpenSession(COMPANY_ID, BRANCH_ID)).thenReturn(false);
            when(dailySessionRepository.findByBranchIdAndSessionDate(eq(COMPANY_ID), eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Collections.emptyList());
            when(dailySessionRepository.findLatest(COMPANY_ID, BRANCH_ID)).thenReturn(Optional.of(pastSession));
            when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> {
                DailySession ds = inv.getArgument(0);
                ds.setId(99L);
                return ds;
            });

            SessionDataDto result = service.openSession(WORKER_ID, BRANCH_ID);

            // FR-1: nothing was saved with the past date in CLOSED status.
            ArgumentCaptor<DailySession> captor = ArgumentCaptor.forClass(DailySession.class);
            verify(dailySessionRepository, atLeastOnce()).save(captor.capture());
            assertThat(captor.getAllValues())
                    .noneMatch(saved -> pastDate.equals(saved.getSessionDate())
                            && saved.getStatus() == DailySessionStatus.CLOSED);
            // The past day itself survives OPEN, and today's session is created OPEN.
            assertThat(pastSession.getStatus()).isEqualTo(DailySessionStatus.OPEN);
            assertThat(result.getStatus()).isEqualTo("OPEN");
            assertThat(result.getSessionDate()).isEqualTo(LocalDate.now());
        }
    }

    @Test
    @DisplayName("FKH-051 T2: validateSessionOpen keeps the past-open-day WARNING (the only remaining signal)")
    void testValidateSessionOpen_pastOpenDay_returnsWarning() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            DailySession pastOpen = DailySession.builder()
                    .id(91L)
                    .branch(createBranch())
                    .sessionDate(LocalDate.now().minusDays(1))
                    .status(DailySessionStatus.OPEN)
                    .build();

            when(dailySessionRepository.findLatest(COMPANY_ID, BRANCH_ID)).thenReturn(Optional.of(pastOpen));
            when(dailySessionRepository.findByBranchIdAndSessionDate(eq(COMPANY_ID), eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(Collections.emptyList());

            List<String> warnings = service.validateSessionOpen(BRANCH_ID);

            // Pinning test: this warning MUST survive the WU6 auto-close removal —
            // after FKH-051 it is the only day-open signal about a past OPEN day.
            assertThat(warnings).anyMatch(w -> w.contains("Az előző nap nincs lezárva!"));
        }
    }
}
