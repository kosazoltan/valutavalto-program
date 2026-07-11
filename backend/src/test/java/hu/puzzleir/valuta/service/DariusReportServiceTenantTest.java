package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DariusDailyReport;
import hu.puzzleir.valuta.entity.DariusReportLine;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DariusDailyReportRepository;
import hu.puzzleir.valuta.repository.DariusReportLineRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class DariusReportServiceTenantTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID REPORT_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final UUID BRANCH_ID = UUID.fromString("30000000-0000-0000-0000-000000000003");
    private static final LocalDate REPORT_DATE = LocalDate.of(2026, 7, 11);

    private final DariusDailyReportRepository reportRepository = mock(DariusDailyReportRepository.class);
    private final DariusReportLineRepository lineRepository = mock(DariusReportLineRepository.class);
    private final TransactionRepository transactionRepository = mock(TransactionRepository.class);
    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final AuditLogService auditLogService = mock(AuditLogService.class);
    private final IntegrationTransportProperties transportProperties = new IntegrationTransportProperties();
    private final FileTransportService fileTransportService = mock(FileTransportService.class);

    private DariusReportService service;

    @BeforeEach
    void setUp() {
        service = new DariusReportService(
                reportRepository,
                lineRepository,
                transactionRepository,
                branchRepository,
                auditLogService,
                transportProperties,
                fileTransportService);
    }

    @Test
    void getReportRejectsForeignReportBeforeLoadingLines() {
        when(reportRepository.findByIdAndCompanyId(REPORT_ID, COMPANY_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> secured(() -> service.getReport(REPORT_ID)))
                .isInstanceOf(ResourceNotFoundException.class);

        verifyNoInteractions(lineRepository);
    }

    @Test
    void getReportLoadsLinesOnlyWithinCurrentCompany() {
        DariusDailyReport report = report(DariusReportStatus.GENERATED);
        when(reportRepository.findByIdAndCompanyId(REPORT_ID, COMPANY_ID)).thenReturn(Optional.of(report));
        when(lineRepository.findByCompanyIdAndReportIdOrderByCurrencyCodeAsc(COMPANY_ID, REPORT_ID))
                .thenReturn(List.of());

        secured(() -> service.getReport(REPORT_ID));

        verify(lineRepository).findByCompanyIdAndReportIdOrderByCurrencyCodeAsc(COMPANY_ID, REPORT_ID);
    }

    @Test
    void regenerateDeletesExistingLinesOnlyWithinCurrentCompany() {
        DariusDailyReport existing = report(DariusReportStatus.DRAFT);
        when(reportRepository.findByCompanyIdAndReportDate(COMPANY_ID, REPORT_DATE))
                .thenReturn(Optional.of(existing));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of());
        when(reportRepository.save(existing)).thenReturn(existing);

        secured(() -> service.generateDailyReport(REPORT_DATE));

        verify(lineRepository).deleteByCompanyIdAndReportId(COMPANY_ID, REPORT_ID);
    }

    @Test
    void generatedLinesCarryParentCompanyId() {
        Branch branch = Branch.builder().id(BRANCH_ID).code("BR001").build();
        when(reportRepository.findByCompanyIdAndReportDate(COMPANY_ID, REPORT_DATE))
                .thenReturn(Optional.empty());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of(branch));
        when(transactionRepository.groupByCurrencyAndTypeForBranch(BRANCH_ID, REPORT_DATE, REPORT_DATE))
                .thenReturn(List.<Object[]>of(new Object[] {
                        "EUR", "BUY", new BigDecimal("100"), new BigDecimal("39000"), BigDecimal.ZERO, 1L
                }));
        when(reportRepository.save(any(DariusDailyReport.class))).thenAnswer(invocation -> {
            DariusDailyReport report = invocation.getArgument(0);
            report.setId(REPORT_ID);
            return report;
        });

        secured(() -> service.generateDailyReport(REPORT_DATE));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Iterable<DariusReportLine>> captor = ArgumentCaptor.forClass(Iterable.class);
        verify(lineRepository).saveAll(captor.capture());
        assertThat(captor.getValue()).allSatisfy(line -> assertThat(line.getCompanyId()).isEqualTo(COMPANY_ID));
    }

    @Test
    void reportMutationsRejectForeignReportWithoutSaving() {
        when(reportRepository.findByIdAndCompanyId(REPORT_ID, COMPANY_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> secured(() -> service.approveReport(REPORT_ID)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> secured(() -> service.submitReport(REPORT_ID)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> secured(() -> service.acknowledgeReport(REPORT_ID, "ACK-1")))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(reportRepository, never()).save(any());
        verifyNoInteractions(lineRepository);
        verifyNoInteractions(fileTransportService);
    }

    @Test
    void retryQueriesOnlyCurrentCompanysFailedReports() {
        when(reportRepository.findRetryable(eq(COMPANY_ID), any(LocalDateTime.class)))
                .thenReturn(List.of());

        secured(service::retryFailedReports);

        verify(reportRepository).findRetryable(eq(COMPANY_ID), any(LocalDateTime.class));
    }

    private DariusDailyReport report(DariusReportStatus status) {
        return DariusDailyReport.builder()
                .id(REPORT_ID)
                .companyId(COMPANY_ID)
                .reportDate(REPORT_DATE)
                .status(status)
                .totalBuyHuf(BigDecimal.ZERO)
                .totalSellHuf(BigDecimal.ZERO)
                .totalHandlingFeeHuf(BigDecimal.ZERO)
                .transactionCount(0)
                .branchCount(0)
                .build();
    }

    private <T> T secured(Supplier<T> action) {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("FOERT01");
            return action.get();
        }
    }
}
