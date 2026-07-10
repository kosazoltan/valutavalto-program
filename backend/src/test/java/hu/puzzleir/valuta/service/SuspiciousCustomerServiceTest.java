package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-12 S1: gyanús ügyfél service-kontraktus — SecurityContext companyId, validáció, defaultok és export-cap.
 */
@ExtendWith(MockitoExtension.class)
class SuspiciousCustomerServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final BigDecimal BAND_LIMIT = new BigDecimal("12345678.50");

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ValueBandService valueBandService;

    @Test
    @DisplayName("FS-12 S1: minden feltétel kikapcsolása fail-closed validációs hiba")
    void allConditionsDisabledIsValidationError() {
        SuspiciousCustomerService service = service();

        assertThatThrownBy(() -> service.search(null, null, false, null, false, null, false, null, PageRequest.of(0, 10)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Legalább egy szűrőfeltétel");
    }

    @Test
    @DisplayName("FS-12 S1: dátum- és küszöb-validáció pozitív értékeket kényszerít")
    void validatesDateRangeAndPositiveThresholds() {
        SuspiciousCustomerService service = service();

        assertThatThrownBy(() -> service.search(LocalDate.of(2026, 7, 11), LocalDate.of(2026, 7, 10), true, 1, false, null, false, null, PageRequest.of(0, 10)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kezdete");
        assertThatThrownBy(() -> service.search(null, null, true, 0, false, null, false, null, PageRequest.of(0, 10)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("tranzakciószám");
        assertThatThrownBy(() -> service.search(null, null, false, null, true, BigDecimal.ZERO, false, null, PageRequest.of(0, 10)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("össz-érték");
        assertThatThrownBy(() -> service.search(null, null, false, null, false, null, true, -1, PageRequest.of(0, 10)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("váltópont");
    }

    @Test
    @DisplayName("FS-12 S1: defaultok 10/értéksáv/3, companyId kizárólag SecurityUtils-ból")
    void resolvesDefaultsAndUsesSecurityContextCompanyId() {
        LocalDate endDate = LocalDate.of(2026, 7, 10);
        when(valueBandService.getEffectiveBands()).thenReturn(bands(BAND_LIMIT));
        when(transactionRepository.findSuspiciousCustomerAggregates(
                any(), any(), any(), anyBoolean(), anyLong(), anyBoolean(), any(), anyBoolean(), anyLong()))
                .thenReturn(java.util.Collections.singletonList(
                        row("C-1", "Kovács Béla", 12L, new BigDecimal("20000000"), 4L)));
        SuspiciousCustomerService service = service();

        try (MockedStatic<SecurityUtils> security = Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Page<SuspiciousCustomerDto> page = service.search(null, endDate, true, null, true, null, true, null, PageRequest.of(0, 10));

            assertThat(page.getTotalElements()).isEqualTo(1);
            SuspiciousCustomerDto dto = page.getContent().get(0);
            assertThat(dto.getCustomerId()).isEqualTo("C-1");
            assertThat(dto.getTransactionCount()).isEqualTo(12);
            assertThat(dto.getTotalHufAmount()).isEqualByComparingTo("20000000");
            assertThat(dto.getBranchCount()).isEqualTo(4);
            assertThat(dto.isHighTransactionCount()).isTrue();
            assertThat(dto.isHighTotalValue()).isTrue();
            assertThat(dto.isManyBranches()).isTrue();
        }

        verify(transactionRepository).findSuspiciousCustomerAggregates(
                eq(COMPANY_ID), eq(endDate.minusDays(30)), eq(endDate), eq(true), eq(10L), eq(true), eq(BAND_LIMIT), eq(true), eq(3L));
    }

    @Test
    @DisplayName("FS-12 S1: memórialapozás totalElements megőrzéssel működik")
    void inMemoryPagingKeepsTotalElements() {
        when(valueBandService.getEffectiveBands()).thenReturn(bands(BAND_LIMIT));
        List<Object[]> rows = new ArrayList<>();
        for (int i = 0; i < 25; i++) {
            rows.add(row("C-" + i, "Ügyfél " + i, 20L, BigDecimal.valueOf(25_000_000L - i), 4L));
        }
        when(transactionRepository.findSuspiciousCustomerAggregates(
                any(), any(), any(), anyBoolean(), anyLong(), anyBoolean(), any(), anyBoolean(), anyLong()))
                .thenReturn(rows);
        SuspiciousCustomerService service = service();

        try (MockedStatic<SecurityUtils> security = Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            Page<SuspiciousCustomerDto> page = service.search(LocalDate.of(2026, 7, 1), LocalDate.of(2026, 7, 31), true, null, true, null, true, null, PageRequest.of(1, 10));

            assertThat(page.getContent()).hasSize(10);
            assertThat(page.getContent().get(0).getCustomerId()).isEqualTo("C-10");
            assertThat(page.getTotalElements()).isEqualTo(25);
        }
    }

    @Test
    @DisplayName("FS-12 S1: export a hatályos értéksáv-küszöbbel kérdez és 10k felett fail-closed")
    void exportUsesBandLimitAndFailsClosedAboveCap() {
        when(valueBandService.getEffectiveBands()).thenReturn(bands(BAND_LIMIT));
        List<Object[]> tooMany = new ArrayList<>();
        for (int i = 0; i < SuspiciousCustomerService.EXPORT_MAX_ROWS + 1; i++) {
            tooMany.add(row("C-" + i, "Ügyfél " + i, 1L, BAND_LIMIT, 1L));
        }
        when(transactionRepository.findSuspiciousCustomerAggregates(
                any(), any(), any(), anyBoolean(), anyLong(), anyBoolean(), any(), anyBoolean(), anyLong()))
                .thenReturn(tooMany);
        SuspiciousCustomerService service = service();

        try (MockedStatic<SecurityUtils> security = Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.listValueBandReachedForExport(LocalDate.of(2026, 7, 1), LocalDate.of(2026, 7, 31)))
                    .isInstanceOf(BusinessException.class)
                    .extracting("errorCode")
                    .isEqualTo("SUSPICIOUS_EXPORT_TOO_LARGE");
        }

        ArgumentCaptor<BigDecimal> minTotalCaptor = ArgumentCaptor.forClass(BigDecimal.class);
        verify(transactionRepository).findSuspiciousCustomerAggregates(
                eq(COMPANY_ID), eq(LocalDate.of(2026, 7, 1)), eq(LocalDate.of(2026, 7, 31)),
                eq(false), eq(Long.MAX_VALUE), eq(true), minTotalCaptor.capture(), eq(false), eq(Long.MAX_VALUE));
        assertThat(minTotalCaptor.getValue()).isEqualByComparingTo(BAND_LIMIT);
    }

    private SuspiciousCustomerService service() {
        return new SuspiciousCustomerService(transactionRepository, valueBandService);
    }

    private static ValueBandService.ValueBands bands(BigDecimal incomeProofLimit) {
        return new ValueBandService.ValueBands(new BigDecimal("100000"), new BigDecimal("300000"), incomeProofLimit, 8);
    }

    private static Object[] row(String customerId, String customerName, long count, BigDecimal total, long branches) {
        return new Object[] {customerId, customerName, count, total, branches};
    }
}
