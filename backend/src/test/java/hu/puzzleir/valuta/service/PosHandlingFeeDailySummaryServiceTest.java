package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.controller.PosHandlingFeeDailySummaryController;
import hu.puzzleir.valuta.dto.handlingfee.PosHandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PosHandlingFeeDailySummaryServiceTest {

    private static final UUID BRANCH_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID COMPANY_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final LocalDate D1 = LocalDate.of(2026, 7, 1);
    private static final LocalDate D2 = LocalDate.of(2026, 7, 2);

    @Mock private TransactionRepository transactionRepository;
    @Mock private BranchService branchService;
    @Mock private AuditLogService auditLogService;

    private PosHandlingFeeDailySummaryService service;

    @BeforeEach
    void setUp() {
        service = new PosHandlingFeeDailySummaryService(transactionRepository, branchService, auditLogService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("POS repository rows map to daily rows and null-safe report totals")
    void mapsRepositoryRowsAndTotals() {
        authenticate("FOERTEKTAR");
        when(transactionRepository.findDailyPosHandlingFee(BRANCH_ID, D1, D2))
                .thenReturn(List.of(
                        new Object[]{D1, "K&H", "001", new BigDecimal("73000"), new BigDecimal("3000")},
                        new Object[]{D2, "K&H", "001", null, null}));

        PosHandlingFeeDailySummaryDto result = service.getDailySummary(BRANCH_ID, D1, D2);

        assertThat(result.getStartDate()).isEqualTo(D1);
        assertThat(result.getEndDate()).isEqualTo(D2);
        assertThat(result.getRows()).hasSize(2);
        assertThat(result.getRows().get(0).getDate()).isEqualTo(D1);
        assertThat(result.getRows().get(0).getNetAmount()).isEqualByComparingTo("73000");
        assertThat(result.getRows().get(0).getFeeAmount()).isEqualByComparingTo("3000");
        assertThat(result.getRows().get(1).getNetAmount()).isEqualByComparingTo("0");
        assertThat(result.getRows().get(1).getFeeAmount()).isEqualByComparingTo("0");
        assertThat(result.getTotalNetAmount()).isEqualByComparingTo("73000");
        assertThat(result.getTotalFeeAmount()).isEqualByComparingTo("3000");
        verify(branchService).findById(BRANCH_ID);
    }

    @Test
    void companyWideSummaryUsesSecurityCompanyAndNeverLooksUpBranch() {
        authenticate("FOERTEKTAR");
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transactionRepository.findDailyPosHandlingFeeForCompany(COMPANY_ID, D1, D2))
                    .thenReturn(List.<Object[]>of(
                            new Object[]{D1, "K&H", "001", new BigDecimal("93000"), new BigDecimal("3800")}));

            PosHandlingFeeDailySummaryDto result = service.getDailySummary(null, D1, D2);

            assertThat(result.getRows()).hasSize(1);
            assertThat(result.getTotalNetAmount()).isEqualByComparingTo("93000");
            assertThat(result.getTotalFeeAmount()).isEqualByComparingTo("3800");
        }

        verify(branchService, never()).findById(any());
        verify(transactionRepository, never()).findDailyPosHandlingFee(any(), any(), any());
        verify(transactionRepository).findDailyPosHandlingFeeForCompany(COMPANY_ID, D1, D2);
    }

    @Test
    @DisplayName("FK-095: two offices on the same date produce two rows, totals unchanged")
    void twoOfficesOnTheSameDateProduceTwoRows() {
        authenticate("FOERTEKTAR");
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transactionRepository.findDailyPosHandlingFeeForCompany(COMPANY_ID, D1, D2))
                    .thenReturn(List.of(
                            new Object[]{D1, "K&H", "001", new BigDecimal("73000"), new BigDecimal("3000")},
                            new Object[]{D1, "OTP", "002", new BigDecimal("20000"), new BigDecimal("800")}));

            PosHandlingFeeDailySummaryDto result = service.getDailySummary(null, D1, D2);

            assertThat(result.getRows()).hasSize(2);
            assertThat(result.getRows().get(0).getBankCode()).isEqualTo("K&H");
            assertThat(result.getRows().get(0).getCode()).isEqualTo("001");
            assertThat(result.getRows().get(0).getNetAmount()).isEqualByComparingTo("73000");
            assertThat(result.getRows().get(1).getBankCode()).isEqualTo("OTP");
            assertThat(result.getRows().get(1).getCode()).isEqualTo("002");
            assertThat(result.getRows().get(1).getNetAmount()).isEqualByComparingTo("20000");
            assertThat(result.getTotalNetAmount()).isEqualByComparingTo("93000");
            assertThat(result.getTotalFeeAmount()).isEqualByComparingTo("3800");
        }
    }

    @Test
    @DisplayName("FK-095: null bankCode is normalised to empty string, code kept, null amounts to zero")
    void blankBankCodeIsNormalisedToEmptyString() {
        authenticate("FOERTEKTAR");
        when(transactionRepository.findDailyPosHandlingFee(BRANCH_ID, D1, D2))
                .thenReturn(List.<Object[]>of(
                        new Object[]{D2, null, "002", null, null}));

        PosHandlingFeeDailySummaryDto result = service.getDailySummary(BRANCH_ID, D1, D2);

        assertThat(result.getRows()).hasSize(1);
        assertThat(result.getRows().get(0).getBankCode()).isEqualTo("");
        assertThat(result.getRows().get(0).getCode()).isEqualTo("002");
        assertThat(result.getRows().get(0).getNetAmount()).isEqualByComparingTo("0");
        assertThat(result.getRows().get(0).getFeeAmount()).isEqualByComparingTo("0");
    }

    @ParameterizedTest(name = "allowed report role: {0}")
    @ValueSource(strings = {
            "FOERTEKTAR", "UGYVEZETO", "IRODAVEZETO",
            "BELSO_ELLENOR", "TERULETI_VEZETO", "PENZUGYI_VEZETO"
    })
    void allowsAllCanonicalReportRoles(String role) {
        authenticate(role);

        service.getDailySummary(BRANCH_ID, D1, D2);

        verify(branchService).findById(BRANCH_ID);
        verify(transactionRepository).findDailyPosHandlingFee(BRANCH_ID, D1, D2);
    }

    @ParameterizedTest(name = "denied report role: {0}")
    @ValueSource(strings = {"PENZTAR", "CASHIER"})
    void deniesOtherRolesAndAuditsBeforeRepositoryAccess(String role) {
        authenticate(role);
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);

            assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D1, D2))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageStartingWith("VV-AUTH-005");
        }

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("POS_HANDLING_FEE_DAILY_SUMMARY"), eq(BRANCH_ID.toString()),
                eq("42"), isNull(), isNull(), isNull(), contains("\"error_code\":\"VV-AUTH-005\""));
        verify(transactionRepository, never()).findDailyPosHandlingFee(any(), any(), any());
        verify(transactionRepository, never()).findDailyPosHandlingFeeForCompany(any(), any(), any());
    }

    @Test
    void deniesEmptyAuthorityListAndAuditsWithoutWorkerId() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("worker", "n/a", List.of()));
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenThrow(new ValidationException("nincs worker"));

            assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D1, D2))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageStartingWith("VV-AUTH-005");
        }

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("POS_HANDLING_FEE_DAILY_SUMMARY"), eq(BRANCH_ID.toString()),
                isNull(), isNull(), isNull(), isNull(), contains("\"error_code\":\"VV-AUTH-005\""));
        verify(transactionRepository, never()).findDailyPosHandlingFee(any(), any(), any());
    }

    @Test
    void propagatesCrossTenantNotFoundBeforeRepositoryAccess() {
        authenticate("FOERTEKTAR");
        when(branchService.findById(BRANCH_ID))
                .thenThrow(new ResourceNotFoundException("Fiók nem található: " + BRANCH_ID));

        assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D1, D2))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(transactionRepository, never()).findDailyPosHandlingFee(any(), any(), any());
    }

    @Test
    void rejectsReversedBranchDateRangeBeforeBranchOrRepositoryAccess() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D2, D1))
                .isInstanceOf(ValidationException.class)
                .hasMessage("A kezdő dátum nem lehet a záró dátum után.");

        verify(branchService, never()).findById(any());
        verify(transactionRepository, never()).findDailyPosHandlingFee(any(), any(), any());
    }

    @Test
    void rejectsReversedCompanyDateRangeBeforeSecurityOrRepositoryAccess() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getDailySummary(null, D2, D1))
                .isInstanceOf(ValidationException.class)
                .hasMessage("A kezdő dátum nem lehet a záró dátum után.");

        verify(branchService, never()).findById(any());
        verify(transactionRepository, never()).findDailyPosHandlingFeeForCompany(any(), any(), any());
    }

    @Test
    void posDailySummaryCsvContainsHeaderDataAndTotalRows() {
        PosHandlingFeeDailySummaryDto report = PosHandlingFeeDailySummaryDto.builder()
                .startDate(D1)
                .endDate(D2)
                .totalNetAmount(new BigDecimal("73000"))
                .totalFeeAmount(new BigDecimal("3000"))
                .rows(List.of(PosHandlingFeeDailySummaryDto.DailyRow.builder()
                        .date(D1)
                        .netAmount(new BigDecimal("73000"))
                        .feeAmount(new BigDecimal("3000"))
                        .build()))
                .build();

        String csv = new ReportExportService().exportPosHandlingFeeDailySummaryCsv(report);

        assertThat(csv).contains("Dátum,POS nettó (Ft),POS KK (Ft)");
        assertThat(csv).contains("2026-07-01,73000,3000");
        assertThat(csv).contains("Összesen,73000,3000");
    }

    @Test
    void controllerDelegatesBranchJsonWithoutExportAudit() {
        PosHandlingFeeDailySummaryService summaryService = mock(PosHandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        AuditEventService auditEventService = mock(AuditEventService.class);
        PosHandlingFeeDailySummaryDto report = PosHandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(BRANCH_ID, D1, D2)).thenReturn(report);
        PosHandlingFeeDailySummaryController controller =
                new PosHandlingFeeDailySummaryController(summaryService, exportService, auditEventService);

        var response = controller.dailySummary(BRANCH_ID, D1, D2);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(report);
        verify(summaryService).getDailySummary(BRANCH_ID, D1, D2);
        verify(auditEventService, never()).appendEvent(any());
    }

    @Test
    void controllerDelegatesCompanyWideJsonWithoutExportAudit() {
        PosHandlingFeeDailySummaryService summaryService = mock(PosHandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        AuditEventService auditEventService = mock(AuditEventService.class);
        PosHandlingFeeDailySummaryDto report = PosHandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(null, D1, D2)).thenReturn(report);
        PosHandlingFeeDailySummaryController controller =
                new PosHandlingFeeDailySummaryController(summaryService, exportService, auditEventService);

        var response = controller.dailySummary(null, D1, D2);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(report);
        verify(summaryService).getDailySummary(null, D1, D2);
        verify(auditEventService, never()).appendEvent(any());
    }

    @Test
    void controllerCsvHasBomFilenameAndExportAudit() {
        PosHandlingFeeDailySummaryService summaryService = mock(PosHandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        AuditEventService auditEventService = mock(AuditEventService.class);
        PosHandlingFeeDailySummaryDto report = PosHandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(BRANCH_ID, D1, D2)).thenReturn(report);
        when(exportService.getBom()).thenReturn(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        when(exportService.exportPosHandlingFeeDailySummaryCsv(report)).thenReturn("csv");
        PosHandlingFeeDailySummaryController controller =
                new PosHandlingFeeDailySummaryController(summaryService, exportService, auditEventService);

        var response = controller.dailySummaryCsv(BRANCH_ID, D1, D2);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("kezelesi-dij-pos-napi-2026-07-01-2026-07-02.csv");
        assertThat(response.getBody()).startsWith((byte) 0xEF, (byte) 0xBB, (byte) 0xBF);
        ArgumentCaptor<AuditEventService.AuditEventRequest> auditCaptor =
                ArgumentCaptor.forClass(AuditEventService.AuditEventRequest.class);
        verify(auditEventService).appendEvent(auditCaptor.capture());
        AuditEventService.AuditEventRequest audit = auditCaptor.getValue();
        assertThat(audit.action()).isEqualTo("EXPORT");
        assertThat(audit.eventType()).isEqualTo("POS_HANDLING_FEE_DAILY_SUMMARY_EXPORT");
        assertThat(audit.entityType()).isEqualTo("PosHandlingFeeDailySummary");
        assertThat(audit.afterStateJson()).contains(
                "\"startDate\":\"2026-07-01\"",
                "\"endDate\":\"2026-07-02\"",
                "\"branchId\":\"" + BRANCH_ID + "\"");
    }

    @Test
    void controllerCompanyWideCsvAuditsNullBranchAndAuditFailureDoesNotBlockDownload() {
        PosHandlingFeeDailySummaryService summaryService = mock(PosHandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        AuditEventService auditEventService = mock(AuditEventService.class);
        PosHandlingFeeDailySummaryDto report = PosHandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(null, D1, D2)).thenReturn(report);
        when(exportService.getBom()).thenReturn(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        when(exportService.exportPosHandlingFeeDailySummaryCsv(report)).thenReturn("csv");
        doThrow(new RuntimeException("audit unavailable")).when(auditEventService).appendEvent(any());
        PosHandlingFeeDailySummaryController controller =
                new PosHandlingFeeDailySummaryController(summaryService, exportService, auditEventService);

        assertThatCode(() -> {
            var response = controller.dailySummaryCsv(null, D1, D2);
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getBody()).startsWith((byte) 0xEF, (byte) 0xBB, (byte) 0xBF);
        }).doesNotThrowAnyException();

        ArgumentCaptor<AuditEventService.AuditEventRequest> auditCaptor =
                ArgumentCaptor.forClass(AuditEventService.AuditEventRequest.class);
        verify(auditEventService).appendEvent(auditCaptor.capture());
        assertThat(auditCaptor.getValue().afterStateJson()).contains("\"branchId\":null");
    }

    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        "worker", "n/a", List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }
}
