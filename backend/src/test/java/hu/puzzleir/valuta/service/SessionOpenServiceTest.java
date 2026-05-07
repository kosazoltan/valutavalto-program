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
            when(dailySessionRepository.hasOpenSession(BRANCH_ID)).thenReturn(false);
            when(dailySessionRepository.findByBranchIdAndSessionDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(Collections.emptyList());
            when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> {
                DailySession ds = inv.getArgument(0);
                ds.setId(1L);
                return ds;
            });
            when(dailySessionRepository.findLatest(BRANCH_ID)).thenReturn(Optional.empty());

            SessionDataDto result = service.openSession(WORKER_ID, BRANCH_ID);

            assertThat(result).isNotNull();
            assertThat(result.getStatus()).isEqualTo("OPEN");
            assertThat(result.getOpeningBalances()).isEmpty();
            assertThat(result.getWorkerName()).isEqualTo("Teszt Pénztáros");
            assertThat(result.getBranchName()).isEqualTo("Budapest Keleti");
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
            when(cashBalanceRepository.existsByBranchId(BRANCH_ID)).thenReturn(false);
            when(cashBalanceService.initializeBranchBalances(BRANCH_ID))
                    .thenThrow(new RuntimeException("currency master missing"));

            Throwable thrown = catchThrowable(() -> service.openSession(WORKER_ID, BRANCH_ID));

            assertThat(thrown)
                    .isInstanceOf(ValidationException.class)
                    .hasMessage("Kasszaegyenlegek inicializálása sikertelen. Nyitás nem folytatható.")
                    .hasCauseInstanceOf(RuntimeException.class);
            assertThat(thrown.getMessage()).doesNotContain("currency master missing");
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
            when(dailySessionRepository.hasOpenSession(BRANCH_ID)).thenReturn(false);
            when(dailySessionRepository.findByBranchIdAndSessionDate(eq(BRANCH_ID), any(LocalDate.class)))
                    .thenReturn(Optional.empty());
            when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(List.of(eurBalance, usdBalance));
            when(dailySessionRepository.save(any(DailySession.class))).thenAnswer(inv -> {
                DailySession ds = inv.getArgument(0);
                ds.setId(2L);
                return ds;
            });
            when(dailySessionRepository.findLatest(BRANCH_ID)).thenReturn(Optional.empty());

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
        DailySession openSession = DailySession.builder()
                .id(1L)
                .branch(createBranch())
                .sessionDate(LocalDate.now().minusDays(1))
                .status(DailySessionStatus.OPEN)
                .build();

        when(dailySessionRepository.findLatest(BRANCH_ID)).thenReturn(Optional.of(openSession));
        when(dailySessionRepository.findByBranchIdAndSessionDate(eq(BRANCH_ID), any(LocalDate.class)))
                .thenReturn(Optional.empty());
        when(cashBalanceRepository.findByBranchId(BRANCH_ID)).thenReturn(Collections.emptyList());

        List<String> warnings = service.validateSessionOpen(BRANCH_ID);

        assertThat(warnings).isNotEmpty();
        assertThat(warnings).anyMatch(w -> w.contains("nincs lezárva") || w.contains("előző"));
    }
}
