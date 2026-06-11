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
    @DisplayName("V.2.7 b) >=100M havi kumulált: hónap-stabil ablak (hónapvége+1 év)")
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
        // hónapvége-horgony: a hónap bármely trigger-napjára >=1 év, és hónapon belül stabil
        assertThat(customer.getEddUntil()).isEqualTo(LocalDate.of(2027, 6, 30));
        assertThat(customer.getEddReason()).contains("V.2.7 b)").contains("123000000");
    }

    @Test
    @DisplayName("Codex P2 regresszió: havi trigger hónapon belüli újrafutása UNCHANGED, nincs audit-spam")
    void monthlyRescanWithinSameMonthIsUnchanged() {
        flagOn();
        LocalDate laterDay = DAY.plusDays(5); // 2026-06-15 — ugyanaz a hónap
        Customer customer = Customer.builder()
                .customerCode("C-2")
                .eddUntil(LocalDate.of(2027, 6, 30)) // az első scan hónapvége-horgonya
                .eddReason("V.2.7 b): korábbi jelölés")
                .build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                laterDay.withDayOfMonth(1), laterDay, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_B, "C-2", new BigDecimal("150000000")}));
        when(customerRepository.findByCustomerCodeAndCompanyId("C-2", COMPANY_B))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(laterDay);

        assertThat(result.unchanged()).isEqualTo(1);
        assertThat(result.marked()).isZero();
        assertThat(result.extended()).isZero();
        assertThat(customer.getEddUntil()).isEqualTo(LocalDate.of(2027, 6, 30));
        verify(customerRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
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

    @Test
    @DisplayName("V.2.7 f) pass-through: 72h-n belül mindkét irányú >=küszöb forgalom → EDD-ablak")
    void marksEddWindowOnPassThroughTrigger() {
        flagOn();
        Customer customer = Customer.builder().customerCode("C-5").build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddPassThroughTriggers(
                DAY.minusDays(2), DAY, new BigDecimal(AmlEddService.EDD_PASSTHROUGH_MIN_DEFAULT)))
                .thenReturn(List.<Object[]>of(new Object[]{
                        COMPANY_A, "C-5", new BigDecimal("6000000"), new BigDecimal("5500000")}));
        when(transactionRepository.countEddDayActivity(COMPANY_A, "C-5", DAY)).thenReturn(1L);
        when(customerRepository.findByCustomerCodeAndCompanyId("C-5", COMPANY_A))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isEqualTo(1);
        assertThat(customer.getEddUntil()).isEqualTo(LocalDate.of(2027, 6, 30)); // hónapvége-horgony
        assertThat(customer.getEddReason()).contains("V.2.7 f)").contains("pass-through");
    }

    @Test
    @DisplayName("Codex P2 (2. kör) regresszió: pass-through scan-napi aktivitás nélkül nem jelöl újra")
    void passThroughSkipsWithoutScanDayActivity() {
        flagOn();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        // a pár a csúszó 72h-ablakban még látszik (pl. hónap-határ után), de a scan-napon
        // nincs új BUY/SELL → nem szabad újra-hosszabbítani
        when(transactionRepository.findEddPassThroughTriggers(
                DAY.minusDays(2), DAY, new BigDecimal(AmlEddService.EDD_PASSTHROUGH_MIN_DEFAULT)))
                .thenReturn(List.<Object[]>of(new Object[]{
                        COMPANY_A, "C-5", new BigDecimal("6000000"), new BigDecimal("5500000")}));
        when(transactionRepository.countEddDayActivity(COMPANY_A, "C-5", DAY)).thenReturn(0L);

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isZero();
        assertThat(result.extended()).isZero();
        verify(customerRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("V.2.7 g) profil-kiugrás: aktuális hó >= 5× a 6 havi átlag → EDD-ablak")
    void marksEddWindowOnProfileOutlier() {
        flagOn();
        Customer customer = Customer.builder().customerCode("C-6").build();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                DAY.withDayOfMonth(1), DAY, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF)).thenReturn(List.of());
        // g) jelölt-szűrő (10M zaj-küszöb): aktuális hó 30M
        when(transactionRepository.findEddMonthlyTurnoverTriggers(
                DAY.withDayOfMonth(1), DAY, new BigDecimal(AmlEddService.EDD_PROFILE_MIN_DEFAULT)))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-6", new BigDecimal("30000000")}));
        // előzmény: 6 hónap alatt összesen 24M → havi átlag 4M; 30M >= 5×4M=20M → trigger
        when(transactionRepository.sumCustomerQuarterlyTotal(
                eq(COMPANY_A), eq("C-6"), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("24000000"));
        when(customerRepository.findByCustomerCodeAndCompanyId("C-6", COMPANY_A))
                .thenReturn(Optional.of(customer));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isEqualTo(1);
        assertThat(customer.getEddReason()).contains("V.2.7 g)").contains("profil-kiugrás");
    }

    @Test
    @DisplayName("V.2.7 g): előzmény nélküli (új) ügyfélnél a kiugrás nem értelmezett — nincs jelölés")
    void profileOutlierSkipsCustomerWithoutHistory() {
        flagOn();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                DAY.withDayOfMonth(1), DAY, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF)).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyTurnoverTriggers(
                DAY.withDayOfMonth(1), DAY, new BigDecimal(AmlEddService.EDD_PROFILE_MIN_DEFAULT)))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-7", new BigDecimal("30000000")}));
        when(transactionRepository.sumCustomerQuarterlyTotal(
                eq(COMPANY_A), eq("C-7"), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(BigDecimal.ZERO);

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isZero();
        verify(customerRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("V.2.7 g): átlag alatti többszöröződésnél (küszöb alatt) nincs jelölés")
    void profileOutlierSkipsBelowMultiplier() {
        flagOn();
        when(transactionRepository.findEddSingleTransactionTriggers(any(), any())).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyCumulativeTriggers(
                DAY.withDayOfMonth(1), DAY, AmlEddService.EDD_MONTHLY_THRESHOLD_HUF)).thenReturn(List.of());
        when(transactionRepository.findEddMonthlyTurnoverTriggers(
                DAY.withDayOfMonth(1), DAY, new BigDecimal(AmlEddService.EDD_PROFILE_MIN_DEFAULT)))
                .thenReturn(List.<Object[]>of(new Object[]{COMPANY_A, "C-8", new BigDecimal("30000000")}));
        // 6 havi össz 60M → átlag 10M; 30M < 5×10M=50M → nincs trigger
        when(transactionRepository.sumCustomerQuarterlyTotal(
                eq(COMPANY_A), eq("C-8"), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(new BigDecimal("60000000"));

        AmlEddService.AmlEddScanResult result = service.scanDate(DAY);

        assertThat(result.marked()).isZero();
        verifyNoInteractions(auditLogService);
    }

    @Test
    @DisplayName("Pmt.30.§(1) manuális jelölés: 1 éves ablak + audit, flag-állástól függetlenül")
    void manualMarkSetsWindowRegardlessOfFlag() {
        Customer customer = Customer.builder().id(42L).customerCode("C-9")
                .company(hu.puzzleir.valuta.entity.Company.builder().id(COMPANY_A).code("EBC").build())
                .build();
        when(customerRepository.findById(42L)).thenReturn(Optional.of(customer));

        try (org.mockito.MockedStatic<hu.puzzleir.valuta.security.SecurityUtils> sec =
                org.mockito.Mockito.mockStatic(hu.puzzleir.valuta.security.SecurityUtils.class)) {
            sec.when(hu.puzzleir.valuta.security.SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            Customer result = service.markManualEdd(42L, "NAV-bejelentés 2026/123");

            assertThat(result.getEddUntil())
                    .isEqualTo(LocalDate.now(AmlEddService.BUSINESS_ZONE).plusYears(1));
            assertThat(result.getEddReason()).contains("Pmt. 30.§ (1)").contains("NAV-bejelentés 2026/123");
            assertThat(result.getHighRiskFlag()).isTrue();
            verify(customerRepository).save(customer);
            verify(auditLogService).logForCompany(
                    eq(AmlEddService.AUDIT_ACTION), anyString(), anyString(), eq(COMPANY_A));
        }
    }

    @Test
    @DisplayName("Pmt.30.§(1) manuális jelölés: cross-tenant ügyfél 404 (nem szivárog)")
    void manualMarkRejectsCrossTenantCustomer() {
        Customer foreign = Customer.builder().id(43L).customerCode("X-1")
                .company(hu.puzzleir.valuta.entity.Company.builder().id(COMPANY_B).code("BEST").build())
                .build();
        when(customerRepository.findById(43L)).thenReturn(Optional.of(foreign));

        try (org.mockito.MockedStatic<hu.puzzleir.valuta.security.SecurityUtils> sec =
                org.mockito.Mockito.mockStatic(hu.puzzleir.valuta.security.SecurityUtils.class)) {
            sec.when(hu.puzzleir.valuta.security.SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            assertThatThrownBy(() -> service.markManualEdd(43L, "indok"))
                    .isInstanceOf(hu.puzzleir.valuta.exception.ResourceNotFoundException.class);
            verify(customerRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Pmt.30.§(1) manuális jelölés: üres indok ValidationException")
    void manualMarkRejectsBlankReason() {
        assertThatThrownBy(() -> service.markManualEdd(42L, "  "))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        verifyNoInteractions(customerRepository, auditLogService);
    }
}
