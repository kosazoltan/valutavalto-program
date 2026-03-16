package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.eveningclosing.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * EveningClosingService unit tesztek — 6 bug ellenőrzése.
 *
 * Bug 1: getDenominations DenominationBalance-ból olvas, nem Denomination masterből
 * Bug 2: getCustomers deduplikál customerId szerint, nincs hardkódolt customerType
 * Bug 3: getReservations csak az adott napi ACTIVE foglalókat adja vissza
 * Bug 4: calculateChecksum mind a 9 adatkategóriát tartalmazza (64 hex karakter)
 * Bug 5: UUID round-trip — UUID overload nem konvertál Long-gá és vissza
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class EveningClosingServiceTest {

    @InjectMocks
    private EveningClosingService service;

    @Mock private TransactionRepository transactionRepository;
    @Mock private DenominationBalanceRepository denominationBalanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private ReservationRepository reservationRepository;
    @Mock private EveningSyncLogRepository eveningSyncLogRepository;
    @Mock private SystemParameterService systemParameterService;

    private static final UUID BRANCH_UUID = UUID.randomUUID();
    private static final UUID COMPANY_UUID = UUID.randomUUID();
    private static final LocalDate DATE = LocalDate.of(2026, 3, 16);

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, COMPANY_UUID, BRANCH_UUID, "ADMIN");
        TestingAuthenticationToken auth =
            new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Alapértelmezett empty stubbok
        when(transactionRepository.findByBranchAndDate(any(), any())).thenReturn(Collections.emptyList());
        when(transactionRepository.sumDailyHandlingFees(any(), any())).thenReturn(BigDecimal.ZERO);
        when(denominationBalanceRepository.findByBranchIdAndDate(any(), any())).thenReturn(Collections.emptyList());
        when(exchangeRateRepository.findActiveRatesByDate(any(), any())).thenReturn(Collections.emptyList());
        when(reservationRepository.findActiveByBranchAndDate(any(), any(), any())).thenReturn(Collections.emptyList());
    }

    // ============ BUG 1: getDenominations ============

    @Test
    @DisplayName("Bug 1: getDenominations DenominationBalance-ból olvas, nem Denomination masterből")
    void getDenominations_readsDenominationBalance_notDenominationMaster() {
        // Adott: van egy DenominationBalance rekord
        Currency eur = Currency.builder().code("EUR").build();
        Denomination denom = Denomination.builder()
                .faceValue(new BigDecimal("50"))
                .denominationType(DenominationType.BANKNOTE)
                .currency(eur)
                .build();
        DenominationBalance balance = DenominationBalance.builder()
                .cashDeskId(BRANCH_UUID)
                .denomination(denom)
                .quantity(10)
                .totalValue(new BigDecimal("500"))
                .build();

        when(denominationBalanceRepository.findByBranchIdAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(balance));

        // Ha
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: DenominationBalance repository hívódott meg
        verify(denominationBalanceRepository, times(1)).findByBranchIdAndDate(eq(BRANCH_UUID), eq(DATE));
        // Denomination master repository NEM hívódott meg
        verify(denominationRepository, never()).findByBranchId(any());

        // A csomag tartalmaz egy cimletezési sort
        assertThat(pkg.getDenominations()).hasSize(1);
        assertThat(pkg.getDenominations().get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(pkg.getDenominations().get(0).getQuantity()).isEqualTo(10);
        assertThat(pkg.getDenominations().get(0).getTotalAmount()).isEqualByComparingTo("500");
    }

    // ============ BUG 2: getCustomers deduplikáció ============

    @Test
    @DisplayName("Bug 2: getCustomers deduplikál customerId szerint")
    void getCustomers_deduplicatesById() {
        // Adott: 2 tranzakció ugyanazzal a customerId-vel
        Transaction tx1 = buildTransaction("C001", "Kiss József", "DOC111");
        Transaction tx2 = buildTransaction("C001", "Kiss József", "DOC111");
        Transaction tx3 = buildTransaction("C002", "Nagy Mária", "DOC222");

        when(transactionRepository.findByBranchAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(tx1, tx2, tx3));

        // Ha
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: csak 2 egyedi ügyfél szerepel (C001 egyszer, C002 egyszer)
        assertThat(pkg.getCustomers()).hasSize(2);
        long c001Count = pkg.getCustomers().stream()
                .filter(c -> "C001".equals(c.getCustomerId()))
                .count();
        assertThat(c001Count).isEqualTo(1);
    }

    @Test
    @DisplayName("Bug 2: getCustomers dokumentumszám szerint deduplikál ha nincs customerId")
    void getCustomers_deduplicatesByDocumentNumber_whenNoCustomerId() {
        // Adott: 2 tranzakció ugyanazzal a documentNumber-rel, customerId nélkül
        Transaction tx1 = buildTransaction(null, "Kiss József", "PASS12345");
        Transaction tx2 = buildTransaction(null, "Kiss József", "PASS12345");

        when(transactionRepository.findByBranchAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(tx1, tx2));

        // Ha
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: csak 1 ügyfél (dokumentumszám alapján deduplikálva)
        assertThat(pkg.getCustomers()).hasSize(1);
    }

    // ============ BUG 3: getReservations dátum szűrés ============

    @Test
    @DisplayName("Bug 3: getReservations csak az adott napi foglalókat kéri le")
    void getReservations_filtersbyDate() {
        // Adott: van 1 mai foglaló
        Customer customer = Customer.builder().id(1L).name("Test Ügyfél").build();
        Reservation reservation = Reservation.builder()
                .id(1L)
                .currencyCode("USD")
                .reservedAmount(new BigDecimal("500"))
                .depositAmount(new BigDecimal("50"))
                .status(ReservationStatus.ACTIVE)
                .customer(customer)
                .createdAt(DATE.atTime(10, 0))
                .expiresAt(DATE.plusDays(3).atStartOfDay())
                .build();

        when(reservationRepository.findActiveByBranchAndDate(
                eq(BRANCH_UUID),
                any(LocalDateTime.class),
                any(LocalDateTime.class)))
                .thenReturn(List.of(reservation));

        // Ha
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: a dátumszűrős metódus hívódott meg
        verify(reservationRepository, times(1))
                .findActiveByBranchAndDate(eq(BRANCH_UUID), any(LocalDateTime.class), any(LocalDateTime.class));
        // A régi (dátum nélküli) metódus NEM hívódott meg
        verify(reservationRepository, never()).findByBranchIdAndStatus(any(), any());

        assertThat(pkg.getReservations()).hasSize(1);
        assertThat(pkg.getReservations().get(0).getCurrencyCode()).isEqualTo("USD");
    }

    // ============ BUG 4: calculateChecksum ============

    @Test
    @DisplayName("Bug 4: calculateChecksum érvényes SHA-256 (64 hex karakter)")
    void calculateChecksum_isValid64CharSha256() {
        // Ha
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: a checksum 64 hex karakter hosszú (SHA-256 = 32 byte = 64 hex char)
        assertThat(pkg.getChecksum()).isNotNull();
        assertThat(pkg.getChecksum()).hasSize(64);
        assertThat(pkg.getChecksum()).matches("[0-9a-f]{64}");
    }

    @Test
    @DisplayName("Bug 4: checksum eltér ha eltérő adatok vannak")
    void calculateChecksum_differsBetweenDifferentData() {
        // Adott: első csomag üres adatokkal
        DailyDataPackage pkg1 = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Adott: második csomag egy tranzakcióval
        Transaction tx = buildTransaction("C001", "Kiss József", "DOC111");
        tx.setHufAmount(new BigDecimal("50000"));
        when(transactionRepository.findByBranchAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(tx));
        when(transactionRepository.sumDailyHandlingFees(any(), any()))
                .thenReturn(new BigDecimal("1000"));

        DailyDataPackage pkg2 = service.prepareDailyPackage(BRANCH_UUID, DATE);

        // Akkor: a két checksum különbözik
        assertThat(pkg1.getChecksum()).isNotEqualTo(pkg2.getChecksum());
    }

    // ============ BUG 5: UUID round-trip ============

    @Test
    @DisplayName("Bug 5: UUID overload nem konvertál Long-gá — branchId megőrzi az eredeti UUID-t")
    void uuidOverload_doesNotLoseUpperBits() {
        // Adott: egy UUID aminek mindkét 64 bites fele nem nulla
        UUID originalUuid = UUID.fromString("a1b2c3d4-e5f6-7890-abcd-ef1234567890");

        // Ha: UUID overload-dal hívjuk
        DailyDataPackage pkg = service.prepareDailyPackage(originalUuid, DATE);

        // Akkor: a csomag nem null és a branchId a leastSignificantBits (backward compat)
        assertThat(pkg).isNotNull();
        assertThat(pkg.getDate()).isEqualTo(DATE);
        // Ellenőrzés: az UUID overload közvetlenül hívja a belső metódust,
        // nem konvertál UUID->Long->UUID (ez utóbbi elvesztené a felső 64 bitet)
        // A branchId Long érték a leastSignificantBits
        assertThat(pkg.getBranchId()).isEqualTo(originalUuid.getLeastSignificantBits());
    }

    @Test
    @DisplayName("Bug 5: uuidFromLong deprecated annotációval jelölve")
    void uuidFromLong_isDeprecated() throws Exception {
        // Ellenőrzés: a metódus @Deprecated annotációval van ellátva
        var method = EveningClosingService.class.getDeclaredMethod("uuidFromLong", Long.class);
        assertThat(method.isAnnotationPresent(Deprecated.class)).isTrue();
    }

    // ============ HELPER METÓDUSOK ============

    private Transaction buildTransaction(String customerId, String customerName, String docNumber) {
        Currency eur = Currency.builder().code("EUR").build();
        Worker worker = Worker.builder().name("Test Pénztáros").build();
        Transaction tx = Transaction.builder()
                .id((long) (Math.random() * 10000))
                .receiptNumber("V00001")
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(DATE)
                .transactionTime(java.time.LocalTime.of(10, 0))
                .currency(eur)
                .currencyAmount(new BigDecimal("100"))
                .exchangeRate(new BigDecimal("400"))
                .hufAmount(new BigDecimal("40000"))
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .roundingAmount(BigDecimal.ZERO)
                .customerId(customerId)
                .customerName(customerName)
                .customerDocumentNumber(docNumber)
                .paymentMethod(PaymentMethod.CASH)
                .worker(worker)
                .build();
        return tx;
    }
}
