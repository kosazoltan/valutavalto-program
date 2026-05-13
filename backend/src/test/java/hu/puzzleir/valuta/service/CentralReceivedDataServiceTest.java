package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.central.CentralReceivedDataOverviewDto;
import hu.puzzleir.valuta.dto.central.CentralReceivedDataRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyReport;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CentralReceivedDataServiceTest {

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DailyReportRepository dailyReportRepository;

    @Mock
    private ClosingControlRepository closingControlRepository;

    @InjectMocks
    private CentralReceivedDataService service;

    private UUID companyId;

    @BeforeEach
    void setUpAuthContext() {
        companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("WORKER001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(99L, companyId, branchId, "MANAGER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearAuthContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("overview includes active branches without daily report as missing data")
    void overview_includesMissingDailyReportRows() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch reported = branch(UUID.randomUUID(), "BP01", "Budapest 01");
        Branch missing = branch(UUID.randomUUID(), "BP02", "Budapest 02");
        DailyReport report = DailyReport.builder()
                .id(10L)
                .branch(reported)
                .reportDate(date)
                .submitted(true)
                .transactionCount(7)
                .totalBuyHuf(new BigDecimal("1000.00"))
                .totalSellHuf(new BigDecimal("2000.00"))
                .totalFeeHuf(new BigDecimal("50.00"))
                .totalProfit(new BigDecimal("75.00"))
                .build();
        ClosingControl closing = ClosingControl.builder()
                .companyId(companyId)
                .branchId(reported.getId())
                .controlDate(date)
                .dailyClosingDone(true)
                .eveningClosingDone(true)
                .navClosingDone(true)
                .alertLevel("NONE")
                .build();

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of(report));
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of(closing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(reported, missing));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals(2, overview.getTotalBranches());
        assertEquals(1, overview.getReceivedReports());
        assertEquals(1, overview.getSubmittedReports());
        assertEquals(1, overview.getMissingReports());
        assertEquals(1, overview.getCriticalClosings());
        assertEquals(7, overview.getTotalTransactions());
        assertEquals(new BigDecimal("1000.00"), overview.getTotalBuyHuf());

        CentralReceivedDataRowDto missingRow = overview.getRows().get(1);
        assertEquals("BP02", missingRow.getBranchCode());
        assertFalse(missingRow.getReportReceived());
        assertEquals("CRITICAL", missingRow.getDataStatus());
        assertTrue(missingRow.getClosingControlMissing());
    }

    private Branch branch(UUID id, String code, String name) {
        return Branch.builder()
                .id(id)
                .code(code)
                .name(name)
                .city("Budapest")
                .company(Company.builder().id(companyId).name("Best Change").build())
                .isActive(true)
                .build();
    }
}
