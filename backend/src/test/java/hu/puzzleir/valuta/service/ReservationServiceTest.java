package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * ReservationService unit tesztek — P1-09 bugfix ellenőrzés.
 *
 * T1: fulfillReservation maradékfizetés HUF-ba kerül
 * T2: fulfillReservation — ha deposit fedezi a teljes árat, nincs HUF hívás
 * T3: fulfillReservation — státusz FULFILLED lesz
 * T4: getReservedStock — valutanemre specifikus count
 * T5: autoExpireReservations — már nem aktív foglalót átugorja (idempotency)
 * T6: autoExpireReservations — helyes count-ot ad vissza
 * T7: sendPreExpiryWarnings — értesítést hoz létre
 * T8: sendPreExpiryWarnings — idempotens (duplikátumot nem ment)
 * T9: sendPreExpiryWarnings — csak az ACTIVE + hamarosan lejárókat veszi figyelembe
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ReservationServiceTest {

    @InjectMocks
    private ReservationService service;

    @Mock private ReservationRepository reservationRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private NotificationRepository notificationRepository;

    private static final UUID BRANCH_ID  = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Long  WORKER_ID = 1L;

    @BeforeEach
    void setUpSecurityContext() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ========== Helper: alap entitások ==========

    private Branch branch(UUID id) {
        Branch b = new Branch();
        b.setId(id);
        b.setName("Test iroda");
        return b;
    }

    private Worker worker(Long id) {
        Worker w = new Worker();
        w.setId(id);
        w.setName("Teszt Péter");
        return w;
    }

    private Customer customer(Long id) {
        Customer c = new Customer();
        c.setId(id);
        c.setName("Ügyfél Béla");
        return c;
    }

    private Currency hufCurrency() {
        Currency c = new Currency();
        c.setId(100L);
        c.setCode("HUF");
        return c;
    }

    private CashBalance hufBalance(BigDecimal amount) {
        CashBalance cb = new CashBalance();
        cb.setCurrentBalance(amount);
        return cb;
    }

    /** Általános kassza-egyenleg (valutától független), olvashatóbb néven. */
    private CashBalance cashBalanceWith(BigDecimal amount) {
        CashBalance cb = new CashBalance();
        cb.setCurrentBalance(amount);
        return cb;
    }

    /** Alap aktív Reservation builder */
    private Reservation activeReservation(Long id, String currencyCode,
                                           BigDecimal reservedAmount, BigDecimal rate,
                                           BigDecimal depositAmount) {
        Reservation r = new Reservation();
        r.setId(id);
        r.setCurrencyCode(currencyCode);
        r.setReservedAmount(reservedAmount);
        r.setExchangeRate(rate);
        r.setDepositAmount(depositAmount);
        r.setStatus(ReservationStatus.ACTIVE);
        r.setExpiresAt(LocalDateTime.now().plusDays(1));
        r.setBranch(branch(BRANCH_ID));
        r.setCustomer(customer(10L));
        r.setRefundAmount(BigDecimal.ZERO);
        return r;
    }

    // ========== T1: fulfillReservation adds remaining payment ==========

    @Test
    @DisplayName("T1: fulfillReservation — maradékfizetés (fullPrice - deposit) HUF kasszába kerül")
    void t1_fulfillReservation_addsRemainingPaymentToHuf() {
        // 100 EUR @ 400 HUF = 40000 HUF fullPrice; deposit=36000 → remaining=4000
        BigDecimal reserved  = new BigDecimal("100");
        BigDecimal rate      = new BigDecimal("400");
        BigDecimal deposit   = new BigDecimal("36000");
        BigDecimal remaining = new BigDecimal("4000");

        Reservation res = activeReservation(1L, "EUR", reserved, rate, deposit);

        when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(res));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID)));

        Currency huf = hufCurrency();
        CashBalance hufBal = hufBalance(new BigDecimal("100000"));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(eq(BRANCH_ID), eq(huf.getId())))
                .thenReturn(Optional.of(hufBal));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(reservationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.fulfillReservation(1L);

        // HUF egyenleg növelése: 100000 + 4000 = 104000
        assertThat(hufBal.getCurrentBalance())
                .isEqualByComparingTo(new BigDecimal("104000"));
    }

    // ========== T2: fulfillReservation — no HUF call when deposit covers full price ==========

    @Test
    @DisplayName("T2: fulfillReservation — deposit fedezi a teljes árat, nincs HUF hívás")
    void t2_fulfillReservation_noHufCallWhenDepositCoversFull() {
        // 100 EUR @ 400; deposit=40000 = fullPrice → remaining=0
        BigDecimal reserved = new BigDecimal("100");
        BigDecimal rate     = new BigDecimal("400");
        BigDecimal deposit  = new BigDecimal("40000");

        Reservation res = activeReservation(2L, "EUR", reserved, rate, deposit);

        when(reservationRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(res));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID)));
        when(reservationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.fulfillReservation(2L);

        // HUF currency lekérdezés NEM fut le (remaining <= 0)
        verify(currencyRepository, never()).findByCode("HUF");
        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdForUpdate(any(), any());
    }

    // ========== T3: fulfillReservation sets status FULFILLED ==========

    @Test
    @DisplayName("T3: fulfillReservation — státusz FULFILLED lesz")
    void t3_fulfillReservation_statusFulfilled() {
        BigDecimal reserved = new BigDecimal("50");
        BigDecimal rate     = new BigDecimal("400");
        BigDecimal deposit  = new BigDecimal("20000"); // fullPrice=20000 → remaining=0

        Reservation res = activeReservation(3L, "EUR", reserved, rate, deposit);

        when(reservationRepository.findByIdForUpdate(3L)).thenReturn(Optional.of(res));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID)));
        when(reservationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Reservation result = service.fulfillReservation(3L);

        assertThat(result.getStatus()).isEqualTo(ReservationStatus.FULFILLED);
        assertThat(result.getFulfilledAt()).isNotNull();
        assertThat(result.getRefundAmount()).isEqualByComparingTo(deposit);
    }

    // ========== T4: getReservedStock — currency-specific count ==========

    @Test
    @DisplayName("T4: getReservedStock — currency-specifikus countActiveByCurrencyAndBranch hívódik")
    void t4_getReservedStock_usesCurrencySpecificCount() {
        Object[] row = new Object[]{"EUR", new BigDecimal("500")};
        List<Object[]> rawData = new ArrayList<>();
        rawData.add(row);
        when(reservationRepository.getReservedStockByBranch(BRANCH_ID))
                .thenReturn(rawData);
        when(reservationRepository.countActiveByCurrencyAndBranch(BRANCH_ID, "EUR"))
                .thenReturn(3L);

        var result = service.getReservedStock(BRANCH_ID);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.get(0).getActiveCount()).isEqualTo(3L);
        assertThat(result.get(0).getReservedAmount()).isEqualByComparingTo("500");

        // Ellenőrzés: a régi (nem currency-specifikus) count NEM hívódott
        verify(reservationRepository, never())
                .countByBranchAndStatusAndCreatedAtBetween(any(), any(), any(), any());
        verify(reservationRepository).countActiveByCurrencyAndBranch(BRANCH_ID, "EUR");
    }

    // ========== T5: autoExpireReservations — idempotency ==========

    @Test
    @DisplayName("T5: autoExpireReservations — már EXPIRED foglalót átugorja (idempotency)")
    void t5_autoExpireReservations_skipsAlreadyExpired() {
        Reservation alreadyExpired = activeReservation(5L, "USD",
                new BigDecimal("200"), new BigDecimal("300"), new BigDecimal("60000"));
        alreadyExpired.setStatus(ReservationStatus.ACTIVE); // listában aktívként szerepel
        alreadyExpired.setExpiresAt(LocalDateTime.now().minusHours(1));

        // A lista-lekérdezés visszaadja
        when(reservationRepository.findByStatusAndExpiresAtBefore(
                eq(ReservationStatus.ACTIVE), any()))
                .thenReturn(List.of(alreadyExpired));

        // De a lock-os újralekérdezés már EXPIRED státuszú entitást ad vissza
        Reservation lockedExpired = activeReservation(5L, "USD",
                new BigDecimal("200"), new BigDecimal("300"), new BigDecimal("60000"));
        lockedExpired.setStatus(ReservationStatus.EXPIRED);
        when(reservationRepository.findByIdForUpdate(5L))
                .thenReturn(Optional.of(lockedExpired));

        int count = service.autoExpireReservations();

        assertThat(count).isZero();
        // save NEM hívódott meg (az entitást átugrotta)
        verify(reservationRepository, never()).save(any());
    }

    // ========== T6: autoExpireReservations — helyes count ==========

    @Test
    @DisplayName("T6: autoExpireReservations — helyes lejárt count-ot ad vissza")
    void t6_autoExpireReservations_returnsCorrectCount() {
        Reservation r1 = activeReservation(6L, "EUR",
                new BigDecimal("100"), new BigDecimal("400"), new BigDecimal("40000"));
        r1.setExpiresAt(LocalDateTime.now().minusHours(2));

        Reservation r2 = activeReservation(7L, "USD",
                new BigDecimal("50"),  new BigDecimal("350"), new BigDecimal("17500"));
        r2.setExpiresAt(LocalDateTime.now().minusHours(3));

        when(reservationRepository.findByStatusAndExpiresAtBefore(
                eq(ReservationStatus.ACTIVE), any()))
                .thenReturn(List.of(r1, r2));

        // findByIdForUpdate mindkét foglalót aktívként adja vissza → valóban lejárnak
        when(reservationRepository.findByIdForUpdate(6L)).thenReturn(Optional.of(r1));
        when(reservationRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(r2));

        // currencyRepository stub a restoreCurrencyStock-hoz
        Currency eur = new Currency(); eur.setId(1L); eur.setCode("EUR");
        Currency usd = new Currency(); usd.setId(2L); usd.setCode("USD");
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));

        CashBalance eurBal = new CashBalance(); eurBal.setCurrentBalance(new BigDecimal("1000"));
        CashBalance usdBal = new CashBalance(); usdBal.setCurrentBalance(new BigDecimal("500"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, 1L))
                .thenReturn(Optional.of(eurBal));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, 2L))
                .thenReturn(Optional.of(usdBal));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(reservationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        int count = service.autoExpireReservations();

        assertThat(count).isEqualTo(2);
    }

    // ========== T7: sendPreExpiryWarnings — creates notification ==========

    @Test
    @DisplayName("T7: sendPreExpiryWarnings — értesítést hoz létre a lejáró foglalóhoz")
    void t7_sendPreExpiryWarnings_createsNotification() {
        Reservation res = activeReservation(10L, "EUR",
                new BigDecimal("100"), new BigDecimal("400"), new BigDecimal("40000"));
        res.setExpiresAt(LocalDateTime.now().plusHours(12));

        when(reservationRepository.findActiveExpiringBetween(any(), any()))
                .thenReturn(List.of(res));
        when(notificationRepository.existsByEntityTypeAndEntityIdAndNotificationType(
                "Reservation", "10", "PRE_EXPIRY_WARNING"))
                .thenReturn(false);
        when(notificationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.sendPreExpiryWarnings();

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(captor.capture());

        Notification saved = captor.getValue();
        assertThat(saved.getEntityType()).isEqualTo("Reservation");
        assertThat(saved.getEntityId()).isEqualTo("10");
        assertThat(saved.getNotificationType()).isEqualTo("PRE_EXPIRY_WARNING");
        assertThat(saved.getType()).isEqualTo("WARNING");
        assertThat(saved.getTitle()).contains("lejár");
    }

    // ========== T8: sendPreExpiryWarnings — idempotent ==========

    @Test
    @DisplayName("T8: sendPreExpiryWarnings — duplikátumot nem ment (idempotens)")
    void t8_sendPreExpiryWarnings_idempotent() {
        Reservation res = activeReservation(11L, "EUR",
                new BigDecimal("100"), new BigDecimal("400"), new BigDecimal("40000"));
        res.setExpiresAt(LocalDateTime.now().plusHours(6));

        when(reservationRepository.findActiveExpiringBetween(any(), any()))
                .thenReturn(List.of(res));
        // Már létezik értesítés
        when(notificationRepository.existsByEntityTypeAndEntityIdAndNotificationType(
                "Reservation", "11", "PRE_EXPIRY_WARNING"))
                .thenReturn(true);

        service.sendPreExpiryWarnings();

        // save NEM fut le
        verify(notificationRepository, never()).save(any());
    }

    // ========== T9: sendPreExpiryWarnings — only active expiring soon ==========

    @Test
    @DisplayName("T9: sendPreExpiryWarnings — csak a hamarosan lejáró foglalókat veszi figyelembe")
    void t9_sendPreExpiryWarnings_onlyActiveExpiringSoon() {
        // A repository query paramétereit ellenőrizzük:
        // from = now, to = now + 24h
        when(reservationRepository.findActiveExpiringBetween(any(), any()))
                .thenReturn(List.of()); // üres eredmény

        service.sendPreExpiryWarnings();

        ArgumentCaptor<LocalDateTime> fromCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        ArgumentCaptor<LocalDateTime> toCaptor   = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(reservationRepository).findActiveExpiringBetween(
                fromCaptor.capture(), toCaptor.capture());

        LocalDateTime from = fromCaptor.getValue();
        LocalDateTime to   = toCaptor.getValue();

        // from ≈ most (±5 perc tolerancia)
        assertThat(from).isAfter(LocalDateTime.now().minusMinutes(5));
        assertThat(from).isBefore(LocalDateTime.now().plusMinutes(5));

        // to ≈ most + 24 óra (±5 perc tolerancia)
        assertThat(to).isAfter(LocalDateTime.now().plusHours(23).plusMinutes(55));
        assertThat(to).isBefore(LocalDateTime.now().plusHours(24).plusMinutes(5));

        // save nem hívódott (nincs foglalás)
        verify(notificationRepository, never()).save(any());
    }

    // ========== T10: createReservation — 5% letét (G8, FR-9) ==========

    @Test
    @DisplayName("T10: createReservation — a letét a ft-érték 5%-a (100 EUR @ 400 = 40000 → 2000)")
    void t10_createReservation_fivePercentDeposit() {
        Long customerId = 10L;
        BigDecimal amount = new BigDecimal("100");
        BigDecimal rate = new BigDecimal("400");

        Company company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Teszt Kft.");

        Currency eur = new Currency();
        eur.setId(200L);
        eur.setCode("EUR");
        eur.setActive(true);

        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID)));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker(WORKER_ID)));
        when(customerRepository.findById(customerId)).thenReturn(Optional.of(customer(customerId)));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency()));
        // EUR készlet (van elég: 1000 >= 100)
        CashBalance eurBalance = cashBalanceWith(new BigDecimal("1000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, 200L))
                .thenReturn(Optional.of(eurBalance));
        // HUF kassza (addHufBalance — ide kerül a befizetett 5% letét)
        CashBalance hufKassza = cashBalanceWith(new BigDecimal("0"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(BRANCH_ID, 100L))
                .thenReturn(Optional.of(hufKassza));
        // save: id beállítása + visszaadás (az audit log getId()-t hív)
        when(reservationRepository.save(any(Reservation.class))).thenAnswer(inv -> {
            Reservation r = inv.getArgument(0);
            r.setId(999L);
            return r;
        });

        Reservation result = service.createReservation(
                customerId, "EUR", amount, rate,
                LocalDateTime.now().plusDays(2), "teszt foglaló");

        // ft-érték = 100 × 400 = 40000; 5% = 2000; round5(2000) = 2000
        assertThat(result.getDepositAmount()).isEqualByComparingTo("2000");
        assertThat(result.getReservedAmount()).isEqualByComparingTo("100");
        assertThat(result.getStatus()).isEqualTo(ReservationStatus.ACTIVE);
        // Pénzmozgás: a lefoglalt 100 EUR kivonva (1000 → 900), a HUF kasszába a 5% letét (0 → 2000)
        assertThat(eurBalance.getCurrentBalance()).isEqualByComparingTo("900");
        assertThat(hufKassza.getCurrentBalance()).isEqualByComparingTo("2000");

        // CASH-VS-CASH LOCK-ORDERING (#953): a foglalas a cash_balance sorokat NOVEKVO currencyId
        // sorrendben elo-lockolja a mutacio elott -> determinisztikus, a BUY/SELL/sztorno aggal egyezo
        // sorrend -> nincs cash<->cash AB-BA deadlock. Az ELSO KET lock a pre-lock: HUF(100) majd EUR(200).
        org.mockito.ArgumentCaptor<Long> cidCaptor = org.mockito.ArgumentCaptor.forClass(Long.class);
        verify(cashBalanceRepository, atLeast(2))
                .findByBranchIdAndCurrencyIdForUpdate(eq(BRANCH_ID), cidCaptor.capture());
        assertThat(cidCaptor.getAllValues().subList(0, 2)).containsExactly(100L, 200L);
    }
}
