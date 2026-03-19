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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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

        when(dailySessionRepository.hasOpenSession(branchId)).thenReturn(false);
        when(dailySessionRepository.findByBranchIdAndSessionDate(eq(branchId), eq(LocalDate.now())))
                .thenReturn(Optional.empty());
        when(dailySessionRepository.findLatest(branchId)).thenReturn(Optional.empty());
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
}
