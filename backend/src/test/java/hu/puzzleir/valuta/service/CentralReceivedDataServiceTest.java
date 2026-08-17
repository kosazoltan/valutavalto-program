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

    @Test
    @DisplayName("overview lastSyncedAt = legfrissebb átvett report ideje (submittedAt elsőbbség, fallback createdAt)")
    void overview_computesLastSyncedAtFromMostRecentReport() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");
        Branch b2 = branch(UUID.randomUUID(), "BP02", "Budapest 02");
        Branch b3 = branch(UUID.randomUUID(), "BP03", "Budapest 03");

        java.time.LocalDateTime older = date.atTime(9, 0);
        java.time.LocalDateTime newest = date.atTime(17, 30);

        // b1: submittedAt = older
        DailyReport r1 = DailyReport.builder().id(1L).branch(b1).reportDate(date)
                .submitted(true).submittedAt(older).createdAt(date.atTime(8, 0)).build();
        // b2: nincs beküldés (submitted=false), csak createdAt = newest (fallback ág)
        DailyReport r2 = DailyReport.builder().id(2L).branch(b2).reportDate(date)
                .submitted(false).submittedAt(null).createdAt(newest).build();
        // b3: nincs report (missing) → nem számít bele

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of(r1, r2));
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1, b2, b3));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals(newest, overview.getLastSyncedAt(),
                "lastSyncedAt a legfrissebb átvett adat ideje (b2 createdAt fallback = 17:30)");
    }

    @Test
    @DisplayName("overview lastSyncedAt = null ha egyetlen branch sem küldött adatot")
    void overview_lastSyncedAtNullWhenNoReports() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        org.junit.jupiter.api.Assertions.assertNull(overview.getLastSyncedAt());
    }

    @Test
    @DisplayName("overview dailyClosingDone alone is COMPLETE (FK-062 pattern — evening/nav flags vault branches-nál nem íródnak)")
    void overview_dailyDoneOnly_isNotCriticalClosing() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        ClosingControl closing = ClosingControl.builder()
                .companyId(companyId)
                .branchId(b1.getId())
                .controlDate(date)
                .dailyClosingDone(true)
                .eveningClosingDone(false)
                .navClosingDone(false)
                .alertLevel(null)
                .build();

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of(closing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("NONE", overview.getRows().get(0).getClosingAlertLevel(),
                "csak a napi zárás számít teljesnek (FK-062: evening/nav nem íródik értéktári fiókoknál)");
        assertEquals(0, overview.getCriticalClosings());
    }

    @Test
    @DisplayName("overview control==null múlt dátumon → CRITICAL zárás-jelzés")
    void overview_controlNull_pastDate_isCritical() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("CRITICAL", overview.getRows().get(0).getClosingAlertLevel());
    }

    @Test
    @DisplayName("overview control==null mai napon → WARNING zárás-jelzés")
    void overview_controlNull_today_isWarning() {
        LocalDate date = LocalDate.now();
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("WARNING", overview.getRows().get(0).getClosingAlertLevel());
    }

    @Test
    @DisplayName("overview napi zárás nélkül múlt dátumon → marad CRITICAL")
    void overview_dailyNotDone_pastDate_staysCritical() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        ClosingControl closing = ClosingControl.builder()
                .companyId(companyId)
                .branchId(b1.getId())
                .controlDate(date)
                .dailyClosingDone(false)
                .eveningClosingDone(true)
                .navClosingDone(true)
                .alertLevel(null)
                .build();

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of(closing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("CRITICAL", overview.getRows().get(0).getClosingAlertLevel());
    }

    @Test
    @DisplayName("overview napi zárás nélkül mai napon → marad WARNING")
    void overview_dailyNotDone_today_staysWarning() {
        LocalDate date = LocalDate.now();
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        ClosingControl closing = ClosingControl.builder()
                .companyId(companyId)
                .branchId(b1.getId())
                .controlDate(date)
                .dailyClosingDone(false)
                .eveningClosingDone(false)
                .navClosingDone(false)
                .alertLevel(null)
                .build();

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of(closing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("WARNING", overview.getRows().get(0).getClosingAlertLevel());
    }

    @Test
    @DisplayName("overview tárolt alertLevel elsőbbséget élvez a jelzőkkel szemben")
    void overview_storedAlertLevel_winsOverFlags() {
        LocalDate date = LocalDate.now().minusDays(1);
        Branch b1 = branch(UUID.randomUUID(), "BP01", "Budapest 01");

        ClosingControl closing = ClosingControl.builder()
                .companyId(companyId)
                .branchId(b1.getId())
                .controlDate(date)
                .dailyClosingDone(true)
                .eveningClosingDone(true)
                .navClosingDone(true)
                .alertLevel("WARNING")
                .build();

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of());
        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of(closing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(b1));

        CentralReceivedDataOverviewDto overview = service.getOverview(date);

        assertEquals("WARNING", overview.getRows().get(0).getClosingAlertLevel(),
                "a tárolt alertLevel ág előbb értékelődik ki, mint a teljesség-vizsgálat");
        assertEquals(0, overview.getCriticalClosings());
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
