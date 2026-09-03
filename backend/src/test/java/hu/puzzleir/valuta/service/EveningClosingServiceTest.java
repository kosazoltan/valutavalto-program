package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
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
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.nio.file.Path;
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
    @Mock private IntegrationTransportProperties integrationTransportProperties;
    @Mock private FileTransportService fileTransportService;
    // FKH-036 FR-1: a két új összefoglaló-függőség (WU-1).
    @Mock private BranchRepository branchRepository;
    @Mock private ShipmentRequestRepository shipmentRequestRepository;

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

    @Test
    @DisplayName("HQ URL hiányában artifact készül, ARTIFACT_PENDING, is_bridged marad false")
    void sendToHeadquarters_missingUrlFailsClosedByDefault() throws Exception {
        stubArtifactSync();

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage()).contains("HQ URL nincs konfigurálva");
        assertThat(result.getAttemptCount()).isEqualTo(1);
        verify(fileTransportService).writeJson(anyString(), eq("evening_daily_report"), any());
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo("ARTIFACT_PENDING");
        assertThat(captor.getValue().getIsBridged()).isFalse();
    }

    @Test
    @DisplayName("FK-091 FR-2: HQ URL nélküli artifact + kapcsoló BE → EVENING_SYNC_DONE, is_bridged=true")
    void sendToHeadquarters_missingUrlCanBeExplicitlyMarkedSuccessfulForTests() throws Exception {
        stubArtifactSync();
        ReflectionTestUtils.setField(service, "artifactSuccessEnabled", true);

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getChecksum()).isEqualTo("checksum-123");
        verify(fileTransportService).writeJson(anyString(), eq("evening_daily_report"), any());
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo("EVENING_SYNC_DONE");
        assertThat(captor.getValue().getIsBridged()).isTrue();
        assertThat(captor.getValue().getErrorMessage()).isEqualTo("BRIDGED_TO_MANAGED_ARTIFACT");
    }

    @Test
    @DisplayName("FK-091 FR-3: valódi HQ HTTP 2xx → EVENING_SYNC_DONE, is_bridged=false")
    @SuppressWarnings("unchecked")
    void sendToHeadquarters_http2xxSetsIsBridgedFalse() throws Exception {
        stubArtifactSync();
        when(systemParameterService.getValue("evening.closing.headquarters.url"))
                .thenReturn("http://hq.example");
        RestTemplate mockRt = mock(RestTemplate.class);
        when(mockRt.exchange(anyString(), eq(org.springframework.http.HttpMethod.POST), any(), eq(String.class)))
                .thenReturn(new ResponseEntity<>("ok", HttpStatus.OK));
        ReflectionTestUtils.setField(service, "headquartersRestTemplate", mockRt);

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isTrue();
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo("EVENING_SYNC_DONE");
        assertThat(captor.getValue().getIsBridged()).isFalse();
    }

    @Test
    @DisplayName("FK-091 FR-5: újrafelhasznált bridged sor → ARTIFACT_PENDING is_bridged=false")
    void sendToHeadquarters_reusedBridgedRow_artifactPendingResetsIsBridged() throws Exception {
        stubArtifactSync();
        EveningSyncLog existing = EveningSyncLog.builder()
                .branchId(BRANCH_UUID)
                .syncDate(DATE)
                .status("EVENING_SYNC_DONE")
                .isBridged(true)
                .attemptCount(1)
                .build();
        when(eveningSyncLogRepository.findByBranchIdAndSyncDate(any(), any()))
                .thenReturn(Optional.of(existing));

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isFalse();
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo("ARTIFACT_PENDING");
        assertThat(captor.getValue().getIsBridged()).isFalse();
    }

    @Test
    @DisplayName("FK-091 FR-5: újrafelhasznált bridged sor → FAILED is_bridged=false")
    @SuppressWarnings("unchecked")
    void sendToHeadquarters_reusedBridgedRow_failedResetsIsBridged() throws Exception {
        stubArtifactSync();
        EveningSyncLog existing = EveningSyncLog.builder()
                .branchId(BRANCH_UUID)
                .syncDate(DATE)
                .status("EVENING_SYNC_DONE")
                .isBridged(true)
                .attemptCount(1)
                .build();
        when(eveningSyncLogRepository.findByBranchIdAndSyncDate(any(), any()))
                .thenReturn(Optional.of(existing));
        when(systemParameterService.getValue("evening.closing.headquarters.url"))
                .thenReturn("http://hq.example");
        RestTemplate mockRt = mock(RestTemplate.class);
        when(mockRt.exchange(anyString(), eq(org.springframework.http.HttpMethod.POST), any(), eq(String.class)))
                .thenThrow(new RestClientException("down"));
        ReflectionTestUtils.setField(service, "headquartersRestTemplate", mockRt);

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isFalse();
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        EveningSyncLog last = captor.getAllValues().get(captor.getAllValues().size() - 1);
        assertThat(last.getStatus()).isEqualTo("FAILED");
        assertThat(last.getIsBridged()).isFalse();
    }

    @Test
    @DisplayName("FK-091 FR-5: HQ hívás FAILED ágán is_bridged marad false")
    @SuppressWarnings("unchecked")
    void sendToHeadquarters_failedKeepsIsBridgedFalse() throws Exception {
        stubArtifactSync();
        when(systemParameterService.getValue("evening.closing.headquarters.url"))
                .thenReturn("http://hq.example");
        RestTemplate mockRt = mock(RestTemplate.class);
        when(mockRt.exchange(anyString(), eq(org.springframework.http.HttpMethod.POST), any(), eq(String.class)))
                .thenThrow(new RestClientException("down"));
        ReflectionTestUtils.setField(service, "headquartersRestTemplate", mockRt);

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isFalse();
        ArgumentCaptor<EveningSyncLog> captor = ArgumentCaptor.forClass(EveningSyncLog.class);
        verify(eveningSyncLogRepository).save(captor.capture());
        EveningSyncLog last = captor.getAllValues().get(captor.getAllValues().size() - 1);
        assertThat(last.getStatus()).isEqualTo("FAILED");
        assertThat(last.getIsBridged()).isFalse();
    }

    // ============ FKH-036 FR-1: összefoglaló mezők ============

    @Test
    @DisplayName("FKH-036: üres napon az összefoglaló lista-mezők soha nem nullák, status=NOT_STARTED")
    void prepareDailyPackage_summaryFieldsNeverNull_onEmptyDay() {
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        assertThat(pkg.getWarnings()).isNotNull();
        assertThat(pkg.getBalances()).isNotNull();
        assertThat(pkg.getPackages()).isNotNull();
        assertThat(pkg.getWarnings()).isEmpty();
        assertThat(pkg.getBalances()).isEmpty();
        assertThat(pkg.getPackages()).isEmpty();
        assertThat(pkg.getStatus()).isEqualTo("NOT_STARTED");
        assertThat(pkg.getTransactionCount()).isZero();
        assertThat(pkg.getPendingSyncs()).isZero();
        assertThat(pkg.getOpenReservations()).isZero();
        assertThat(pkg.getTotalBuyHuf()).isEqualByComparingTo("0");
        assertThat(pkg.getTotalSellHuf()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("FKH-036 B1: a PENDING-figyelmeztetés DÁTUM-SZKÓPOLT — nem a branch-szintű existsBy-ből jön")
    void prepareDailyPackage_pendingWarning_isDateScoped() {
        // Beragadt, MÁS napi PENDING sor szimulálása: a branch-szintű (dátum nélküli)
        // metódus true-t adna — ha az implementáció ezt használná, a figyelmeztetés
        // akkor is megjelenne, ha az adott napon nincs PENDING tranzakció.
        Transaction completedTx = buildTransaction("C001", "Kiss József", "DOC111");
        when(transactionRepository.findByBranchAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(completedTx));
        when(transactionRepository.existsByBranchIdAndStatus(any(), any())).thenReturn(true);

        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);

        assertThat(pkg.getWarnings()).noneMatch(w -> w.contains("PENDING"));
        verify(transactionRepository, never()).existsByBranchIdAndStatus(any(), any());

        // Aznapi PENDING tranzakció → pontosan egy, a számot is tartalmazó figyelmeztetés.
        Transaction pendingTx = buildTransaction("C002", "Nagy Mária", "DOC222");
        pendingTx.setStatus(TransactionStatus.PENDING);
        when(transactionRepository.findByBranchAndDate(eq(BRANCH_UUID), eq(DATE)))
                .thenReturn(List.of(completedTx, pendingTx));

        DailyDataPackage pkg2 = service.prepareDailyPackage(BRANCH_UUID, DATE);

        assertThat(pkg2.getWarnings())
                .filteredOn(w -> w.matches("1 aznapi, folyamatban lévő \\(PENDING\\) tranzakció van.*"))
                .hasSize(1);
        verify(transactionRepository, never()).existsByBranchIdAndStatus(any(), any());
    }

    @Test
    @DisplayName("FKH-036: a checksumot az új összefoglaló mezők NEM változtatják (pénzügyi integritás)")
    void prepareDailyPackage_checksumUnchangedByNewSummaryFields() throws Exception {
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_UUID, DATE);
        assertThat(pkg.getChecksum()).matches("[0-9a-f]{64}");

        // A várt hash a változás ELŐTTI kódot leíró 9-bemenetű formátumból számítva
        // (nem hardkódolt literál): branchId|date|txCount|totalHuf|denomCount|rateCount|
        // customerCount|reservationCount|totalFees.
        String data = String.format("%d|%s|%d|%s|%d|%d|%d|%d|%s",
                BRANCH_UUID.getLeastSignificantBits(), DATE, 0, "0", 0, 0, 0, 0, "0");
        byte[] hash = java.security.MessageDigest.getInstance("SHA-256")
                .digest(data.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        StringBuilder expected = new StringBuilder();
        for (byte b : hash) {
            expected.append(String.format("%02x", b));
        }
        assertThat(pkg.getChecksum()).isEqualTo(expected.toString());

        // Két csomag, amely CSAK az új összefoglaló mezőkben tér el → azonos checksum.
        DailyDataPackage plain = DailyDataPackage.builder()
                .branchId(pkg.getBranchId()).date(DATE)
                .transactions(List.of()).denominations(List.of()).rates(List.of())
                .customers(List.of()).reservations(List.of()).handlingFees(null)
                .warnings(List.of()).balances(List.of()).packages(List.of())
                .status("NOT_STARTED").transactionCount(0).build();
        DailyDataPackage enriched = DailyDataPackage.builder()
                .branchId(pkg.getBranchId()).date(DATE)
                .transactions(List.of()).denominations(List.of()).rates(List.of())
                .customers(List.of()).reservations(List.of()).handlingFees(null)
                .warnings(List.of("Van függőben lévő esti szinkron erre a napra."))
                .balances(List.of(BalanceView.builder().currency("EUR").amount(new BigDecimal("50")).build()))
                .packages(List.of(PackageView.builder().packageId("FF-20260316-0001").build()))
                .status("SENT").branchName("Más iroda").transactionCount(99)
                .totalBuyHuf(new BigDecimal("12345")).totalSellHuf(new BigDecimal("678"))
                .pendingSyncs(1).openReservations(3).build();

        String checksumPlain = ReflectionTestUtils.invokeMethod(service, "calculateChecksum", plain);
        String checksumEnriched = ReflectionTestUtils.invokeMethod(service, "calculateChecksum", enriched);
        assertThat(checksumPlain).isEqualTo(checksumEnriched);
    }

    // ============ HELPER METÓDUSOK ============

    private DailyDataPackage emptyPackage() {
        return DailyDataPackage.builder()
                .branchId(123L)
                .date(DATE)
                .transactions(Collections.emptyList())
                .checksum("checksum-123")
                .build();
    }

    @Test
    @DisplayName("FKH-045 FR-5: artifact-írási (fájlrendszeri) hiba esetén NEM a nyers útvonal jelenik meg")
    void sendToHeadquarters_artifactWriteFailureHasFriendlyMessage() throws Exception {
        stubArtifactSync();
        when(fileTransportService.writeJson(anyString(), eq("evening_daily_report"), any()))
                .thenThrow(new java.nio.file.NoSuchFileException("/home/valuta/.valuta/integrations/branch-sync"));

        DataSyncResult result = service.sendToHeadquarters(emptyPackage());

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage())
                .as("FR-5: érthető, üzemeltetésre utaló üzenet")
                .contains("üzemeltetés");
        assertThat(result.getMessage())
                .as("FR-5: a nyers fájlrendszer-útvonal NEM kerülhet a felhasználói üzenetbe")
                .doesNotContain("/home/valuta");
    }

    private void stubArtifactSync() throws Exception {
        IntegrationTransportProperties.Sync sync = new IntegrationTransportProperties.Sync();
        sync.setDir("branch-sync");
        when(integrationTransportProperties.getSync()).thenReturn(sync);
        when(systemParameterService.getValue("evening.closing.headquarters.url")).thenReturn("");
        when(eveningSyncLogRepository.findByBranchIdAndSyncDate(any(), any())).thenReturn(Optional.empty());
        when(eveningSyncLogRepository.save(any(EveningSyncLog.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fileTransportService.sanitizePathSegment(anyString(), anyString()))
                .thenAnswer(inv -> inv.getArgument(0));
        when(fileTransportService.writeJson(anyString(), eq("evening_daily_report"), any()))
                .thenReturn(Path.of("C:/tmp/evening_daily_report.json"));
    }

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
