package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AmlEddServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SystemParameterService systemParameterService;

    @InjectMocks
    private AmlEddService service;

    private static final LocalDate DAY = LocalDate.of(2026, 6, 10);
    private static final UUID COMPANY_A = UUID.randomUUID();
    private static final UUID COMPANY_B = UUID.randomUUID();

    private void flagOn() {
        when(systemParameterService.getValue(
                AmlEddService.EDD_TRACKING_PARAM, AmlEddService.EDD_TRACKING_DEFAULT))
                .thenReturn("true");
    }

    @Test
    @DisplayName("Flag kikapcsolva: a scan no-op, repository-t sem hív")
    void scanIsNoOpWhenFlagDisabled() {
        when(systemParameterService.getValue(
                AmlEddService.EDD_TRACKING_PARAM, AmlEddService.EDD_TRACKING_DEFAULT))
                .thenReturn("false");

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.enabled()).isFalse();
        assertThat(result.marked()).isZero();
        verifyNoInteractions(transactionRepository, customerRepository, auditLogService);
    }

    @Test
    @DisplayName("V.2.7 a) >=50M egyedi tranzakció: 1 éves EDD-ablak + highRisk + audit")
    void marksEddWindowOnSingleTransactionTrigger() {
        flagOn();
        Customer customer = Customer.builder().customerCode("C-1").build();
        when(transactionRepository.findEddSingleTransactionTriggers(DAY, AmlEddService.EDD_SINGLE_TX_THRESHOLD_HUF))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-1"}));
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                DAY.withDayOfMonth(1), DAY, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF))
                .thenReturn(List.of());
        when(customerRepository.findByCustomerCodeAndCompanyId("C-1", COMPANY_A))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isEqualTo(1);
        assertThat(customer.getEddUntil()).isEqualTo(DAY.plusYears(1));
        assertThat(customer.getEddReason()).contains("V.2.7 a)");
        assertThat(customer.getHighRiskFlag()).isTrue();
        verify(customerRepository).save(customer);
        verify(auditLogService).logForCompany(
                eq(AmlEddService.AUDIT_ACTION), anyString(),
                eq("C-1:" + DAY.plusYears(1)), eq(COMPANY_A));
    }

    @Test
    @DisplayName("V.2.7 b) >=100M havi kumulált: EDD-ablak a havi triggerből")
    void marksEddWindowOnMonthlyCumulativeTrigger() {
        flagOn();
        Customer customer = Customer.builder().customerCode("C-2").build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                DAY.withDayOfMonth(1), DAY, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_B, "C-2", new BigDecimal("123000000")}));
        when(customerRepository.findByCustomerCodeAndCompanyId("C-2", COMPANY_B))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isEqualTo(1);
        assertThat(customer.getEddUntil()).isEqualTo(DAY.plusYears(1));
        assertThat(customer.getEddReason()).contains("V.2.7 b)").contains("123000000");
    }

    @Test
    @DisplayName("Extend-only: meglévő későbbi ablakot nem rövidít, audit sem készül")
    void doesNotShortenExistingLaterWindow() {
        flagOn();
        Customer customer = Customer.builder()
                .customerCode("C-3")
                .eddUntil(DAY.plusYears(2))
                .eddReason("korábbi ok")
                .build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any()))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-3"}));
        when(transactionRepository.findEddMonthlyCumulativeTriggers(any(), any(), any()))
                .thenReturn(List.of());
        when(customerRepository.findByCustomerCodeAndCompanyId("C-3", COMPANY_A))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isZero();
        assertThat(result.unchanged()).isEqualTo(1);
        assertThat(customer.getEddUntil()).isEqualTo(DAY.plusYears(2));
        assertThat(customer.getEddReason()).isEqualTo("korábbi ok");
        verify(customerRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("Aktív, de korábbi lejáratú ablak: hosszabbítás (EXTENDED)")
    void extendsActiveShorterWindow() {
        flagOn();
        Customer customer = Customer.builder()
                .customerCode("C-4")
                .eddUntil(DAY.plusMonths(1))
                .build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any()))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-4"}));
        when(transactionRepository.findEddMonthlyCumulativeTriggers(any(), any(), any()))
                .thenReturn(List.of());
        when(customerRepository.findByCustomerCodeAndCompanyId("C-4", COMPANY_A))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.extended()).isEqualTo(1);
        assertThat(customer.getEddUntil()).isEqualTo(DAY.plusYears(1));
        ArgumentCaptor<String> msg = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).logForCompany(
                eq(AmlEddService.AUDIT_ACTION), msg.capture(), anyString(), eq(COMPANY_A));
        assertThat(msg.getValue()).contains("hosszabbítva");
    }

    @Test
    @DisplayName("Ismeretlen ügyfél-trigger: nincs crash, változatlanként számolódik")
    void unknownCustomerIsCountedUnchanged() {
        flagOn();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any()))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "GHOST"}));
        when(transactionRepository.findEddMonthlyCumulativeTriggers(any(), any(), any()))
                .thenReturn(List.of());
        when(customerRepository.findByCustomerCodeAndCompanyId("GHOST", COMPANY_A))
                .thenReturn(Optional.empty());

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.unchanged()).isEqualTo(1);
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("isEddActive: aktív ma, lejárt tegnap, null mezők")
    void eddActiveHelperBoundaries() {
        LocalDate today = LocalDate.of(2026, 6, 11);
        assertThat(AmlEddService.isEddActive(
                Customer.builder().eddUntil(today).build(), today)).isTrue();
        assertThat(AmlEddService.isEddActive(
                Customer.builder().eddUntil(today.minusDays(1)).build(), today)).isFalse();
        assertThat(AmlEddService.isEddActive(Customer.builder().build(), today)).isFalse();
        assertThat(AmlEddService.isEddActive(null, today)).isFalse();
    }

    @Test
    @DisplayName("Null nap: IllegalArgumentException")
    void rejectsNullDay() {
        assertThatThrownBy(() -> service.scanDate(null))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
