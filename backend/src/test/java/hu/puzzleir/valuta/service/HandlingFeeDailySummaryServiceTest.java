package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.controller.HandlingFeeDailySummaryController;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.entity.TransactionType;
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
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HandlingFeeDailySummaryServiceTest {

    private static final UUID BRANCH_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final LocalDate D1 = LocalDate.of(2026, 7, 1);
    private static final LocalDate D2 = LocalDate.of(2026, 7, 2);

    @Mock private TransactionRepository transactionRepository;
    @Mock private BranchService branchService;
    @Mock private AuditLogService auditLogService;

    private HandlingFeeDailySummaryService service;

    @BeforeEach
    void setUp() {
        service = new HandlingFeeDailySummaryService(transactionRepository, branchService, auditLogService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("napi BUY/SELL sorokra képez és a nem támogatott típust eldobja")
    void mapsRowsAndTotalsWhileIgnoringUnsupportedTransactionTypes() {
        authenticate("FOERTEKTAR");
        when(transactionRepository.findDailyCashHandlingFeeByType(BRANCH_ID, D1, D2))
                .thenReturn(List.of(
                        new Object[]{D1, TransactionType.BUY, new BigDecimal("150")},
                        new Object[]{D1, TransactionType.SELL, new BigDecimal("70")},
                        new Object[]{D2, TransactionType.SELL, new BigDecimal("40")},
                        new Object[]{D1, TransactionType.CONVERSION, new BigDecimal("999")}));

        var result = service.getDailySummary(BRANCH_ID, D1, D2);

        assertThat(result.getStartDate()).isEqualTo(D1);
        assertThat(result.getEndDate()).isEqualTo(D2);
        assertThat(result.getRows()).hasSize(2);
        assertThat(result.getRows().get(0).getDate()).isEqualTo(D1);
        assertThat(result.getRows().get(0).getBuyFee()).isEqualByComparingTo("150");
        assertThat(result.getRows().get(0).getSellFee()).isEqualByComparingTo("70");
        assertThat(result.getRows().get(1).getDate()).isEqualTo(D2);
        assertThat(result.getRows().get(1).getBuyFee()).isEqualByComparingTo("0");
        assertThat(result.getRows().get(1).getSellFee()).isEqualByComparingTo("40");
        assertThat(result.getTotalBuyFee()).isEqualByComparingTo("150");
        assertThat(result.getTotalSellFee()).isEqualByComparingTo("110");
    }

    @ParameterizedTest(name = "engedélyezett szerep: {0}")
    @ValueSource(strings = {
            "FOERTEKTAR", "UGYVEZETO", "IRODAVEZETO",
            "BELSO_ELLENOR", "TERULETI_VEZETO", "PENZUGYI_VEZETO"
    })
    void allowsAllCanonicalReportRoles(String role) {
        authenticate(role);

        service.getDailySummary(BRANCH_ID, D1, D2);

        verify(branchService).findById(BRANCH_ID);
        verify(transactionRepository).findDailyCashHandlingFeeByType(BRANCH_ID, D1, D2);
    }

    @ParameterizedTest(name = "tiltott szerep: {0}")
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
                eq("ACCESS_DENIED"), eq("HANDLING_FEE_DAILY_SUMMARY"), eq(BRANCH_ID.toString()),
                eq("42"), isNull(), isNull(), isNull(), contains("\"error_code\":\"VV-AUTH-005\""));
        verify(transactionRepository, never()).findDailyCashHandlingFeeByType(BRANCH_ID, D1, D2);
    }

    @Test
    void deniesEmptyAuthorityListAndAuditsFailClosed() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("worker", "n/a", List.of()));
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenThrow(new ValidationException("nincs worker"));

            assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D1, D2))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageStartingWith("VV-AUTH-005");
        }

        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("HANDLING_FEE_DAILY_SUMMARY"), eq(BRANCH_ID.toString()),
                isNull(), isNull(), isNull(), isNull(), contains("\"error_code\":\"VV-AUTH-005\""));
        verify(transactionRepository, never()).findDailyCashHandlingFeeByType(BRANCH_ID, D1, D2);
    }

    @Test
    void propagatesCrossTenantNotFoundBeforeRepositoryAccess() {
        authenticate("FOERTEKTAR");
        when(branchService.findById(BRANCH_ID))
                .thenThrow(new ResourceNotFoundException("Fiók nem található: " + BRANCH_ID));

        assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D1, D2))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(transactionRepository, never()).findDailyCashHandlingFeeByType(BRANCH_ID, D1, D2);
    }

    @Test
    void rejectsReversedDateRangeBeforeBranchOrRepositoryAccess() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getDailySummary(BRANCH_ID, D2, D1))
                .isInstanceOf(ValidationException.class)
                .hasMessage("A kezdő dátum nem lehet a záró dátum után.");

        verify(branchService, never()).findById(BRANCH_ID);
        verify(transactionRepository, never()).findDailyCashHandlingFeeByType(BRANCH_ID, D2, D1);
    }

    @Test
    void dailySummaryCsvContainsHeaderDataAndTotalRows() {
        HandlingFeeDailySummaryDto report = HandlingFeeDailySummaryDto.builder()
                .startDate(D1)
                .endDate(D2)
                .totalBuyFee(new BigDecimal("150"))
                .totalSellFee(new BigDecimal("70"))
                .rows(List.of(HandlingFeeDailySummaryDto.DailyRow.builder()
                        .date(D1)
                        .buyFee(new BigDecimal("150"))
                        .sellFee(new BigDecimal("70"))
                        .build()))
                .build();

        String csv = new ReportExportService().exportHandlingFeeDailySummaryCsv(report);

        assertThat(csv).contains("Dátum", "Vétel kezelési díj (Ft)", "Eladás kezelési díj (Ft)");
        assertThat(csv).contains("2026-07-01,150,70");
        assertThat(csv).contains("Összesen,150,70");
    }

    @Test
    void controllerDelegatesJsonSummaryRequest() {
        HandlingFeeDailySummaryService summaryService = mock(HandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        HandlingFeeDailySummaryDto report = HandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(BRANCH_ID, D1, D2)).thenReturn(report);
        HandlingFeeDailySummaryController controller =
                new HandlingFeeDailySummaryController(summaryService, exportService);

        var response = controller.dailySummary(BRANCH_ID, D1, D2);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(report);
        verify(summaryService).getDailySummary(BRANCH_ID, D1, D2);
    }

    @Test
    void controllerCsvResponseHasAttachmentNameAndUtf8BomPrefix() {
        HandlingFeeDailySummaryService summaryService = mock(HandlingFeeDailySummaryService.class);
        ReportExportService exportService = mock(ReportExportService.class);
        HandlingFeeDailySummaryDto report = HandlingFeeDailySummaryDto.builder().build();
        when(summaryService.getDailySummary(BRANCH_ID, D1, D2)).thenReturn(report);
        when(exportService.getBom()).thenReturn(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        when(exportService.exportHandlingFeeDailySummaryCsv(report)).thenReturn("csv");
        HandlingFeeDailySummaryController controller =
                new HandlingFeeDailySummaryController(summaryService, exportService);

        var response = controller.dailySummaryCsv(BRANCH_ID, D1, D2);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .contains("kezelesi-dij-napi-2026-07-01-2026-07-02.csv");
        assertThat(response.getBody()).startsWith((byte) 0xEF, (byte) 0xBB, (byte) 0xBF);
        verify(summaryService).getDailySummary(BRANCH_ID, D1, D2);
        verify(exportService).exportHandlingFeeDailySummaryCsv(report);
    }

    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        "worker", "n/a", List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }
}
