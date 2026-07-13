package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.Reservation;
import hu.puzzleir.valuta.entity.ReservationStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.NotificationRepository;
import hu.puzzleir.valuta.repository.ReservationRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * P1-05/F-017 parity regresszió, legacy _visszatipus mapping.
 * Spec-forrás: .hermes/dev-loop/reservation-parity-matrix.md.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ReservationParityTest {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long SUPERVISOR_ID = 2L;
    private static final Long HUF_ID = 100L;
    private static final Long EUR_ID = 200L;

    @InjectMocks private ReservationService service;
    @Mock private ReservationRepository reservationRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private NotificationRepository notificationRepository;

    @BeforeEach
    void setUpSecurityContext() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        authentication.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    @Test
    @DisplayName("B1 R1: létrehozáskor a valuta elkülönül és az 5% letét HUF-ba kerül")
    void b1_createSeparatesCurrencyStockAndAddsDepositToHuf() {
        CashBalance eurBalance = cashBalance("1000");
        CashBalance hufBalance = cashBalance("500000");
        stubCreateDependencies(eurBalance, hufBalance);

        Reservation result = service.createReservation(
                10L, "EUR", new BigDecimal("100"), new BigDecimal("400"),
                LocalDateTime.now().plusDays(2), null);

        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("900");
        assertThat(hufBalance.getCurrentBalance()).isEqualByComparingTo("502000");
        assertThat(result.getStatus()).isEqualTo(ReservationStatus.ACTIVE);
        assertThat(result.getReservedAmount()).isEqualByComparingTo("100");
        assertThat(result.getDepositAmount()).isEqualByComparingTo("2000");
    }

    @Test
    @DisplayName("B2 R2: fedezethiánynál nincs balance- vagy reservation-mentés")
    void b2_insufficientCurrencyStockFailsClosed() {
        CashBalance eurBalance = cashBalance("50");
        CashBalance hufBalance = cashBalance("500000");
        stubCreateDependencies(eurBalance, hufBalance);

        assertThatThrownBy(() -> service.createReservation(
                10L, "EUR", new BigDecimal("100"), new BigDecimal("400"),
                LocalDateTime.now().plusDays(2), null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő");

        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("50");
        assertThat(hufBalance.getCurrentBalance()).isEqualByComparingTo("500000");
        verify(cashBalanceRepository, never()).save(any());
        verify(reservationRepository, never()).save(any());
    }

    @Test
    @DisplayName("B3 R5: teljesítéskor csak a HUF változik, a lefoglalt valuta nem")
    void b3_fulfillmentDoesNotMoveReservedCurrencyAgain() {
        Reservation reservation = activeReservation(1L);
        CashBalance hufBalance = cashBalance("100000");
        when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(reservation));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(currency(HUF_ID, "HUF")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, HUF_ID, COMPANY_ID)).thenReturn(Optional.of(hufBalance));
        when(reservationRepository.save(any(Reservation.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID, WorkerRole.CASHIER, BRANCH_ID)));

        Reservation result = service.fulfillReservation(1L);

        assertThat(hufBalance.getCurrentBalance()).isEqualByComparingTo("138000");
        assertThat(result.getRefundAmount()).isEqualByComparingTo("2000");
        assertThat(result.getStatus()).isEqualTo(ReservationStatus.FULFILLED);
        ArgumentCaptor<Long> currencyIdCaptor = ArgumentCaptor.forClass(Long.class);
        verify(cashBalanceRepository, atLeastOnce())
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                        eq(BRANCH_ID), currencyIdCaptor.capture(), eq(COMPANY_ID));
        assertThat(currencyIdCaptor.getAllValues()).containsOnly(HUF_ID);
    }

    @Test
    @DisplayName("B4 R6: ügyfél-stornó refund nélkül visszavezeti a valutát, HUF-ot nem mozgat")
    void b4_customerCancellationRestoresCurrencyAndKeepsDeposit() {
        Reservation reservation = activeReservation(2L);
        CashBalance eurBalance = cashBalance("900");
        when(reservationRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(reservation));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(currency(EUR_ID, "EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, EUR_ID, COMPANY_ID)).thenReturn(Optional.of(eurBalance));
        when(reservationRepository.save(any(Reservation.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID, WorkerRole.CASHIER, BRANCH_ID)));

        Reservation result = service.cancelByCustomer(2L, "Ügyfél visszalépett");

        assertThat(result.getStatus()).isEqualTo(ReservationStatus.CANCELLED_BY_CUSTOMER);
        assertThat(result.getRefundAmount()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getCancellationReason()).isEqualTo("Ügyfél visszalépett");
        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("1000");
        verify(currencyRepository, never()).findByCode("HUF");
    }

    @Test
    @DisplayName("B5 R7: EBC-stornó dupla refundot fizet és visszavezeti a valutát")
    void b5_companyCancellationPaysDoubleAndRestoresCurrency() {
        Reservation reservation = activeReservation(3L);
        Worker supervisor = worker(SUPERVISOR_ID, WorkerRole.SUPERVISOR, BRANCH_ID);
        CashBalance hufBalance = cashBalance("100000");
        CashBalance eurBalance = cashBalance("900");
        stubCompanyCancellation(reservation, supervisor, hufBalance, eurBalance);
        when(workerRepository.findByIdAndCompanyId(WORKER_ID, COMPANY_ID))
                .thenReturn(Optional.of(worker(WORKER_ID, WorkerRole.CASHIER, BRANCH_ID)));
        when(reservationRepository.save(any(Reservation.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Reservation result = service.cancelByCompany(3L, "EBC hiba", SUPERVISOR_ID);

        assertThat(result.getRefundAmount()).isEqualByComparingTo("4000.00");
        assertThat(hufBalance.getCurrentBalance()).isEqualByComparingTo("96000.00");
        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("1000");
        assertThat(result.getSupervisorApproval()).isTrue();
        assertThat(result.getSupervisorWorker()).isSameAs(supervisor);
        assertThat(result.getStatus()).isEqualTo(ReservationStatus.CANCELLED_BY_COMPANY);
    }

    @Test
    @DisplayName("B6 R7: EBC-stornó HUF-fedezethiánynál fail-closed")
    void b6_companyCancellationInsufficientHufFailsClosed() {
        Reservation reservation = activeReservation(4L);
        CashBalance hufBalance = cashBalance("3000");
        CashBalance eurBalance = cashBalance("900");
        stubCompanyCancellation(
                reservation, worker(SUPERVISOR_ID, WorkerRole.SUPERVISOR, BRANCH_ID),
                hufBalance, eurBalance);

        assertThatThrownBy(() -> service.cancelByCompany(4L, "EBC hiba", SUPERVISOR_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő HUF");

        assertThat(reservation.getStatus()).isEqualTo(ReservationStatus.ACTIVE);
        assertThat(hufBalance.getCurrentBalance()).isEqualByComparingTo("3000");
        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("900");
        verify(reservationRepository, never()).save(any());
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("B7a R8: EBC-stornóhoz indoklás kötelező")
    void b7a_companyCancellationRequiresReason() {
        assertThatThrownBy(() -> service.cancelByCompany(5L, " ", SUPERVISOR_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("indoklás kötelező");
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("B7b R8: CASHIER nem hagyhat jóvá EBC-stornót")
    void b7b_companyCancellationRequiresSupervisorRole() {
        when(workerRepository.findByIdAndCompanyId(SUPERVISOR_ID, COMPANY_ID))
                .thenReturn(Optional.of(worker(SUPERVISOR_ID, WorkerRole.CASHIER, BRANCH_ID)));

        assertThatThrownBy(() -> service.cancelByCompany(5L, "EBC hiba", SUPERVISOR_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nincs supervisor jogosultsága");
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("B7c R8: supervisor csak a saját irodájában hagyhat jóvá")
    void b7c_companyCancellationRequiresSameBranchSupervisor() {
        when(workerRepository.findByIdAndCompanyId(SUPERVISOR_ID, COMPANY_ID))
                .thenReturn(Optional.of(worker(SUPERVISOR_ID, WorkerRole.SUPERVISOR, UUID.randomUUID())));

        assertThatThrownBy(() -> service.cancelByCompany(5L, "EBC hiba", SUPERVISOR_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("saját irodájában");
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("B8 R9: lejárat visszavezeti a valutát, a letét HUF-ban marad")
    void b8_expiryRestoresCurrencyAndKeepsDeposit() {
        Reservation reservation = activeReservation(6L);
        reservation.setExpiresAt(LocalDateTime.now().minusHours(1));
        CashBalance eurBalance = cashBalance("900");
        when(reservationRepository.findByStatusAndExpiresAtBefore(eq(ReservationStatus.ACTIVE), any()))
                .thenReturn(List.of(reservation));
        when(reservationRepository.findByIdForUpdate(6L)).thenReturn(Optional.of(reservation));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(currency(EUR_ID, "EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, EUR_ID, COMPANY_ID)).thenReturn(Optional.of(eurBalance));
        when(reservationRepository.save(any(Reservation.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        int count = service.autoExpireReservations();

        assertThat(count).isEqualTo(1);
        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("1000");
        assertThat(reservation.getStatus()).isEqualTo(ReservationStatus.EXPIRED);
        assertThat(reservation.getRefundAmount()).isEqualByComparingTo(BigDecimal.ZERO);
        verify(currencyRepository, never()).findByCode("HUF");
    }

    @Test
    @DisplayName("B9a R10: ismételt teljesítés nem mozgat készletet")
    void b9a_secondFulfillmentIsRejectedBeforeBalanceMutation() {
        Reservation reservation = fulfilledReservation(7L);
        when(reservationRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(reservation));

        assertThatThrownBy(() -> service.fulfillReservation(7L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem aktív");

        verifyLockedReadAndNoMutation(7L);
    }

    @Test
    @DisplayName("B9b R10: teljesített foglaló ügyfél-stornója nem mozgat készletet")
    void b9b_customerCancellationAfterFulfillmentIsRejectedBeforeBalanceMutation() {
        Reservation reservation = fulfilledReservation(8L);
        when(reservationRepository.findByIdForUpdate(8L)).thenReturn(Optional.of(reservation));

        assertThatThrownBy(() -> service.cancelByCustomer(8L, "késő"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem aktív");

        verifyLockedReadAndNoMutation(8L);
    }

    @Test
    @DisplayName("B9c R10: teljesített foglaló EBC-stornója nem mozgat készletet")
    void b9c_companyCancellationAfterFulfillmentIsRejectedBeforeBalanceMutation() {
        Reservation reservation = fulfilledReservation(9L);
        when(workerRepository.findByIdAndCompanyId(SUPERVISOR_ID, COMPANY_ID))
                .thenReturn(Optional.of(worker(SUPERVISOR_ID, WorkerRole.SUPERVISOR, BRANCH_ID)));
        when(reservationRepository.findByIdForUpdate(9L)).thenReturn(Optional.of(reservation));

        assertThatThrownBy(() -> service.cancelByCompany(9L, "késő", SUPERVISOR_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem aktív");

        verifyLockedReadAndNoMutation(9L);
    }

    private void stubCreateDependencies(CashBalance eurBalance, CashBalance hufBalance) {
        Company company = Company.builder().id(COMPANY_ID).name("Teszt Kft.").build();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID)));
        when(workerRepository.findById(WORKER_ID))
                .thenReturn(Optional.of(worker(WORKER_ID, WorkerRole.CASHIER, BRANCH_ID)));
        when(customerRepository.findById(10L)).thenReturn(Optional.of(customer(10L)));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(currency(EUR_ID, "EUR")));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(currency(HUF_ID, "HUF")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, EUR_ID, COMPANY_ID)).thenReturn(Optional.of(eurBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, HUF_ID, COMPANY_ID)).thenReturn(Optional.of(hufBalance));
        when(reservationRepository.save(any(Reservation.class))).thenAnswer(invocation -> {
            Reservation reservation = invocation.getArgument(0);
            reservation.setId(999L);
            return reservation;
        });
    }

    private void stubCompanyCancellation(Reservation reservation, Worker supervisor,
                                         CashBalance hufBalance, CashBalance eurBalance) {
        when(workerRepository.findByIdAndCompanyId(SUPERVISOR_ID, COMPANY_ID))
                .thenReturn(Optional.of(supervisor));
        when(reservationRepository.findByIdForUpdate(reservation.getId()))
                .thenReturn(Optional.of(reservation));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(currency(HUF_ID, "HUF")));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(currency(EUR_ID, "EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, HUF_ID, COMPANY_ID)).thenReturn(Optional.of(hufBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                BRANCH_ID, EUR_ID, COMPANY_ID)).thenReturn(Optional.of(eurBalance));
    }

    private void verifyLockedReadAndNoMutation(Long reservationId) {
        verify(reservationRepository).findByIdForUpdate(reservationId);
        verify(reservationRepository, never()).findById(reservationId);
        verify(reservationRepository, never()).save(any());
        verifyNoInteractions(cashBalanceRepository);
    }

    private Reservation activeReservation(Long id) {
        return Reservation.builder()
                .id(id)
                .company(Company.builder().id(COMPANY_ID).build())
                .customer(customer(10L))
                .branch(branch(BRANCH_ID))
                .worker(worker(WORKER_ID, WorkerRole.CASHIER, BRANCH_ID))
                .currencyCode("EUR")
                .reservedAmount(new BigDecimal("100"))
                .exchangeRate(new BigDecimal("400"))
                .depositAmount(new BigDecimal("2000"))
                .status(ReservationStatus.ACTIVE)
                .expiresAt(LocalDateTime.now().plusDays(1))
                .refundAmount(BigDecimal.ZERO)
                .build();
    }

    private Reservation fulfilledReservation(Long id) {
        Reservation reservation = activeReservation(id);
        reservation.setStatus(ReservationStatus.FULFILLED);
        return reservation;
    }

    private Branch branch(UUID id) {
        return Branch.builder()
                .id(id)
                .name("Teszt iroda")
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
    }

    private Worker worker(Long id, WorkerRole role, UUID branchId) {
        return Worker.builder()
                .id(id)
                .name("Teszt dolgozó")
                .role(role)
                .branch(branch(branchId))
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
    }

    private Customer customer(Long id) {
        Customer customer = new Customer();
        customer.setId(id);
        customer.setName("Ügyfél Béla");
        return customer;
    }

    private Currency currency(Long id, String code) {
        Currency currency = new Currency();
        currency.setId(id);
        currency.setCode(code);
        currency.setActive(true);
        return currency;
    }

    private CashBalance cashBalance(String amount) {
        CashBalance balance = new CashBalance();
        balance.setCurrentBalance(new BigDecimal(amount));
        return balance;
    }
}
