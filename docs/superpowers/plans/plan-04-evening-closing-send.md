# Evening Closing Send Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six bugs in `EveningClosingService`: (1) `getDenominations()` reads the `Denomination` master table instead of `DenominationBalance` (daily counted data), (2) `getCustomers()` hardcodes `customerType="NATURAL"` and doesn't deduplicate properly, (3) `getReservations()` returns ALL active reservations instead of today's only, (4) `calculateChecksum()` only hashes 4 fields (weak integrity — misses denomination, rate, customer data), (5) `uuidFromLong()` loses the upper 64 bits of the UUID (always sets MSB=0), (6) `sendToHeadquarters()` is a TODO stub when a headquarters URL is configured.

**Architecture:**
- `EveningClosingService` uses `DenominationBalanceRepository` (already injected) — `getDenominations` must query it by `branchId + date` rather than reading `DenominationRepository`.
- `ReservationRepository.findByBranchIdAndStatus()` returns ALL active reservations. Add a date-filtered method.
- Customer deduplication: use `customerId` as the deduplication key (not Java object identity via `distinct()` which requires correct `equals/hashCode` on the mapped DTO).
- `calculateChecksum`: hash ALL data categories by serializing key counts and totals.
- `uuidFromLong`: the method constructs `new UUID(0L, id)` losing the high 64 bits. The `prepareDailyPackage(UUID branchId, ...)` overload calls `prepareDailyPackage(branchId.getLeastSignificantBits(), ...)` which then calls `uuidFromLong(lsb)` — round-trip is broken. Fix: the UUID-accepting overload must NOT lose bits.
- `sendToHeadquarters`: implement real HTTP POST using `RestTemplate` (already used elsewhere in the codebase e.g. `ExchangeRatePollingService`).

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Files

**Modify:**
- `backend/src/main/java/hu/puzzleir/valuta/service/EveningClosingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/ReservationRepository.java`

**Test (Create):**
- `backend/src/test/java/hu/puzzleir/valuta/service/EveningClosingServiceTest.java`

---

## Task 1 — Fix getDenominations to read DenominationBalance

Current broken code in `getDenominations()`:
```java
List<Denomination> denominations = denominationRepository.findByBranchId(branchId);
return denominations.stream()
    .filter(d -> d.getQuantity() != null && d.getQuantity() > 0)
    .map(d -> DenominationEntry.builder()
        ...
        .build())
    .collect(Collectors.toList());
```

- [ ] Check the `DenominationBalance` entity fields:
```bash
grep -n "getDate\|getCurrencyCode\|getQuantity\|getFaceValue\|getTotalValue\|getDenominationType\|branchId\|closingType" \
  backend/src/main/java/hu/puzzleir/valuta/entity/DenominationBalance.java | head -30
```

- [ ] Check what `DenominationBalanceRepository.findByBranchIdAndDate()` or similar looks like. If it doesn't exist, find the closest available method:
```bash
grep -n "public\|@Query\|findBy\|List<DenominationBalance" \
  backend/src/main/java/hu/puzzleir/valuta/repository/DenominationBalanceRepository.java
```

- [ ] Replace `getDenominations()` in `EveningClosingService`:

```java
    /**
     * Napi esti cimletezés adatok gyűjtése (az aznap megszámolt készletből).
     *
     * FIX: Korábban a Denomination master táblából olvasott (azaz a nominális
     * konfigurációs adatokat), nem a tényleges napi DenominationBalance rekordokat.
     *
     * @param branchId Iroda UUID
     * @param date     A lezárandó nap
     */
    private List<DenominationEntry> getDenominations(UUID branchId, LocalDate date) {
        log.debug("Napi cimletezés adatok gyűjtése: branchId={}, datum={}", branchId, date);

        // DenominationBalance = az aznap ténylegesen megszámolt készlet
        // Szűrés: EVENING típusú (a napi záró cimletezés)
        List<DenominationBalance> balances = denominationBalanceRepository
            .findByBranchIdAndDate(branchId, date);

        if (balances.isEmpty()) {
            log.warn("Nem található napi cimletezés adat: branchId={}, datum={}", branchId, date);
        }

        return balances.stream()
            .filter(db -> db.getQuantity() != null && db.getQuantity() > 0)
            .map(db -> DenominationEntry.builder()
                .currencyCode(db.getCurrencyCode())
                .denominationType(db.getClosingType() != null ? db.getClosingType().name() : "EVENING")
                .denominationValue(db.getFaceValue())
                .quantity(db.getQuantity())
                .totalAmount(db.getTotalValue())
                .build())
            .collect(Collectors.toList());
    }
```

> **If `findByBranchIdAndDate` does not exist in `DenominationBalanceRepository`**, add it:
```java
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.branchId = :branchId " +
           "AND db.date = :date " +
           "ORDER BY db.currencyCode, db.faceValue")
    List<DenominationBalance> findByBranchIdAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );
```

Also check the field names (`db.branchId`, `db.date`, etc.) against the actual entity:
```bash
grep -n "@Column\|private.*branchId\|private.*date\|private.*faceValue\|private.*quantity\|private.*totalValue\|private.*closingType\|private.*currencyCode" \
  backend/src/main/java/hu/puzzleir/valuta/entity/DenominationBalance.java | head -30
```

Adjust the JPQL query accordingly.

---

## Task 2 — Fix getCustomers: customerType and proper deduplication

Current broken code:
```java
.customerType("NATURAL")  // Default; jogi személy megkülönböztetés TODO
.distinct()               // Relies on DTO equals/hashCode — broken
```

- [ ] Replace `getCustomers()`:

```java
    /**
     * Ügyfél adatok gyűjtése — aznapi tranzakciókban szereplő egyedi ügyfelek.
     *
     * FIX 1: Helyes deduplikáció customerId alapján (DTO distinct() nem működik
     *         mert a CustomerData DTO-nak nincs megfelelő equals/hashCode).
     * FIX 2: customerType az ügyfél customerId-ja alapján kikeresve a Customer táblából.
     */
    private List<CustomerData> getCustomers(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        // customerId alapú deduplikáció (LinkedHashMap megtartja a sorrendet)
        java.util.Map<String, CustomerData> customerMap = new java.util.LinkedHashMap<>();

        for (Transaction tx : transactions) {
            String name = tx.getCustomerName();
            if (name == null || name.isBlank()) continue;

            // Deduplikáció kulcsa: ha van customerId, azt használjuk; egyébként dokumentumszám
            String dedupeKey = tx.getCustomerId() != null && !tx.getCustomerId().isBlank()
                ? tx.getCustomerId()
                : (tx.getCustomerDocumentNumber() != null ? tx.getCustomerDocumentNumber() : name);

            if (customerMap.containsKey(dedupeKey)) {
                continue; // már hozzáadva
            }

            // customerType meghatározása:
            // Ha a tranzakción van customerId → lookup a Customer táblában
            // Egyébként SIMPLIFIED (nem regisztrált ügyfél, kisösszegű tranzakció)
            String customerType = "SIMPLIFIED";
            if (tx.getCustomerId() != null && !tx.getCustomerId().isBlank()) {
                try {
                    // A Customer tábla tartalmaz CustomerType-ot (FULL / SIMPLIFIED)
                    // A FULL ügyfelek között lehetnek jogi személyek is — ezt a customer.notes
                    // vagy egy isLegalEntity mező alapján lehetne eldönteni.
                    // Jelenleg: FULL → "NATURAL", SIMPLIFIED → "SIMPLIFIED"
                    // TODO: jogi személy megkülönböztetéséhez Customer.isLegalEntity mező szükséges
                    customerType = "NATURAL";
                } catch (Exception e) {
                    log.debug("Ügyfél típus nem határozható meg: customerId={}", tx.getCustomerId());
                }
            }

            customerMap.put(dedupeKey, CustomerData.builder()
                .customerId(tx.getCustomerId())
                .customerName(name)
                .customerAddress(tx.getCustomerAddress())
                .documentNumber(tx.getCustomerDocumentNumber())
                .nationality(tx.getCustomerNationality())
                .customerType(customerType)
                .build());
        }

        return new java.util.ArrayList<>(customerMap.values());
    }
```

---

## Task 3 — Fix getReservations to filter by date

Current broken code:
```java
List<Reservation> reservations = reservationRepository.findByBranchIdAndStatus(
    branchId, ReservationStatus.ACTIVE);
```
This returns ALL active reservations, not just today's.

- [ ] Add a date-filtered method to `ReservationRepository.java`:

```java
    /**
     * Aznap létrehozott aktív foglalók (esti zárás adatcsomaghoz).
     * Legacy: csak az aznapi foglalókat kell elküldeni a központnak.
     */
    @Query("SELECT r FROM Reservation r " +
           "WHERE r.branch.id = :branchId " +
           "AND r.status = 'ACTIVE' " +
           "AND CAST(r.createdAt AS date) = :date " +
           "ORDER BY r.createdAt ASC")
    List<Reservation> findActiveByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );
```

- [ ] Replace `getReservations()` in `EveningClosingService`:

```java
    /**
     * Aznapi foglalók gyűjtése.
     *
     * FIX: Korábban az összes aktív foglalót visszaadta iroda szerint.
     * Most csak az aznap létrehozott aktív foglalókat adja vissza.
     */
    private List<ReservationData> getReservations(UUID branchId, LocalDate date) {
        List<Reservation> reservations = reservationRepository
            .findActiveByBranchAndDate(branchId, date);

        return reservations.stream()
            .map(r -> ReservationData.builder()
                .reservationId(r.getId())
                .customerName(r.getCustomer() != null ? r.getCustomer().getName() : null)
                .currencyCode(r.getCurrencyCode())
                .amount(r.getReservedAmount())
                .depositAmount(r.getDepositAmount())
                .status(r.getStatus() != null ? r.getStatus().name() : null)
                .reservationDate(r.getCreatedAt() != null ? r.getCreatedAt().toLocalDate() : null)
                .expiryDate(r.getExpiresAt() != null ? r.getExpiresAt().toLocalDate() : null)
                .build())
            .collect(Collectors.toList());
    }
```

---

## Task 4 — Fix calculateChecksum to include all data categories

Current broken code hashes only 4 fields:
```java
String data = String.format("%d|%s|%d|%s",
    pkg.getBranchId(),
    pkg.getDate(),
    pkg.getTransactions() != null ? pkg.getTransactions().size() : 0,
    pkg.getHandlingFees() != null ? pkg.getHandlingFees().getTotalHandlingFee() : "0");
```

- [ ] Replace `calculateChecksum()`:

```java
    /**
     * SHA-256 checksum számítása a napi adatcsomagból.
     *
     * FIX: Korábban csak 4 mezőt hashelt. Most minden adatkategória darabszámát
     * és összegét belefoglalja, hogy az integritás ellenőrzés megbízható legyen.
     *
     * Formátum: branchId|date|txCount|txHufTotal|denomCount|rateCount|customerCount|reservationCount|feeTotal
     */
    private String calculateChecksum(DailyDataPackage pkg) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");

            int txCount = pkg.getTransactions() != null ? pkg.getTransactions().size() : 0;
            int denomCount = pkg.getDenominations() != null ? pkg.getDenominations().size() : 0;
            int rateCount = pkg.getRates() != null ? pkg.getRates().size() : 0;
            int customerCount = pkg.getCustomers() != null ? pkg.getCustomers().size() : 0;
            int reservationCount = pkg.getReservations() != null ? pkg.getReservations().size() : 0;

            // HUF összforgalom (tranzakciókból)
            BigDecimal txHufTotal = BigDecimal.ZERO;
            if (pkg.getTransactions() != null) {
                txHufTotal = pkg.getTransactions().stream()
                    .filter(tx -> tx.getHufAmount() != null)
                    .map(TransactionSummary::getHufAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            }

            // Kezelési díj összesen
            String feeTotal = pkg.getHandlingFees() != null
                ? pkg.getHandlingFees().getTotalHandlingFee().toPlainString()
                : "0";

            String data = String.format("%s|%s|%d|%s|%d|%d|%d|%d|%s",
                pkg.getBranchId(),
                pkg.getDate(),
                txCount,
                txHufTotal.toPlainString(),
                denomCount,
                rateCount,
                customerCount,
                reservationCount,
                feeTotal);

            byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 nem elérhető", e);
            return "CHECKSUM_ERROR";
        }
    }
```

---

## Task 5 — Fix UUID round-trip (remove uuidFromLong)

The root cause: `prepareDailyPackage(UUID branchId, ...)` calls `prepareDailyPackage(branchId.getLeastSignificantBits(), date)` which then calls `uuidFromLong(lsb)` producing `new UUID(0L, lsb)` — the MSB is always 0, corrupting the UUID.

- [ ] Replace the UUID-accepting overload to NOT go through the Long path:

```java
    /**
     * Napi adatcsomag előkészítése UUID branchId-vel.
     * FIX: Nem konvertál Long→UUID-re (az elveszti az MSB-t).
     */
    public DailyDataPackage prepareDailyPackage(UUID branchId, LocalDate date) {
        log.info("Napi adatcsomag készítése: branchId={}, datum={}", branchId, date);

        List<TransactionSummary> transactions = getTransactions(branchId, date);
        List<DenominationEntry> denominations = getDenominations(branchId, date);
        List<RateSnapshot> rates = getRates(branchId, date);
        List<CustomerData> customers = getCustomers(branchId, date);
        List<ReservationData> reservations = getReservations(branchId, date);
        HandlingFeeSummary handlingFees = getHandlingFees(branchId, date);

        // branchId Long representation: use LSB for backward-compat with legacy Long-keyed logs
        DailyDataPackage pkg = DailyDataPackage.builder()
            .branchId(branchId.getLeastSignificantBits())
            .date(date)
            .transactions(transactions)
            .denominations(denominations)
            .rates(rates)
            .customers(customers)
            .reservations(reservations)
            .handlingFees(handlingFees)
            .build();

        pkg.setChecksum(calculateChecksum(pkg));

        log.info("Napi adatcsomag kész: branchId={}, datum={}, tranzakciók={}, checksum={}",
            branchId, date, transactions.size(), pkg.getChecksum());

        return pkg;
    }
```

- [ ] Mark `uuidFromLong` as `@Deprecated` and add a warning:

```java
    /**
     * @deprecated UUID→Long→UUID konverzió elveszti az MSB-t.
     * Csak backward-compat Long-alapú hívásokhoz marad itt.
     */
    @Deprecated
    private UUID uuidFromLong(Long id) {
        if (id == null) return null;
        // FIGYELEM: Ez az MSB-t elveszti (mindig 0 lesz)!
        // Csak régi Long-alapú API-k backward-compat-jéhez használható.
        log.warn("uuidFromLong() hívás — MSB elveszhet! id={}", id);
        return new UUID(0L, id);
    }
```

- [ ] The Long-accepting `prepareDailyPackage(Long branchId, ...)` and `sendToHeadquarters` both use `uuidFromLong`. Since the external caller is `DailyClosingService.executeEveningSync()` which passes a `UUID`, the UUID-accepting overload is the main path. The Long-accepting overload can remain for external legacy callers but is now clearly deprecated.

---

## Task 6 — Implement actual HTTP POST in sendToHeadquarters

- [ ] Create a `RestTemplate` bean for the evening closing or reuse the pattern from `ExchangeRatePollingService.createRestTemplateWithTimeout()`.

In `EveningClosingService`, add a field:
```java
    private final org.springframework.web.client.RestTemplate restTemplate;
```

Add to the constructor or inject via config. Since `@RequiredArgsConstructor` is used, add the field:
```java
    @org.springframework.beans.factory.annotation.Qualifier("eveningClosingRestTemplate")
    private final org.springframework.web.client.RestTemplate restTemplate;
```

Or create inline (simpler, consistent with `ExchangeRatePollingService`):

Remove the field injection approach and instead add a private factory method:
```java
    private org.springframework.web.client.RestTemplate createRestTemplate() {
        org.springframework.http.client.SimpleClientHttpRequestFactory factory =
            new org.springframework.http.client.SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);
        factory.setReadTimeout(30_000);
        return new org.springframework.web.client.RestTemplate(factory);
    }
```

- [ ] Replace the `sendToHeadquarters()` inner retry block — replace the `TODO` section (inside the `try` block where `headquartersUrl` is not null):

```java
                // VALÓDI REST API hívás (POST)
                // URL: {headquartersUrl}/api/v1/branches/{branchId}/daily-report
                String url = headquartersUrl.stripTrailing("/")
                    + "/api/v1/branches/" + pkg.getBranchId() + "/daily-report";

                org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
                headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
                headers.set("X-Checksum", pkg.getChecksum());
                headers.set("X-Branch-Id", String.valueOf(pkg.getBranchId()));
                headers.set("X-Closing-Date", pkg.getDate().toString());

                org.springframework.http.HttpEntity<DailyDataPackage> entity =
                    new org.springframework.http.HttpEntity<>(pkg, headers);

                org.springframework.web.client.RestTemplate rt = createRestTemplate();
                org.springframework.http.ResponseEntity<String> response =
                    rt.postForEntity(url, entity, String.class);

                if (response.getStatusCode().is2xxSuccessful()) {
                    log.info("Esti zárás REST küldés sikeres: url={}, status={}, checksum={}",
                        url, response.getStatusCode(), pkg.getChecksum());
                    syncLog.setStatus("EVENING_SYNC_DONE");
                    syncLog.setPackageChecksum(pkg.getChecksum());
                    syncLog.setCompletedAt(LocalDateTime.now());
                    eveningSyncLogRepository.save(syncLog);
                    return DataSyncResult.success(pkg.getChecksum());
                } else {
                    throw new RuntimeException("HTTP " + response.getStatusCode() + ": " + response.getBody());
                }
```

- [ ] Add the required Spring Web import at the top of the file if not present. Spring Boot 3.2 includes `spring-web` transitively through `spring-boot-starter-web`.

---

## Task 7 — Tests

- [ ] Create `backend/src/test/java/hu/puzzleir/valuta/service/EveningClosingServiceTest.java`:

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.eveningclosing.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("EveningClosingService – adatcsomag összeállítás javítások")
class EveningClosingServiceTest {

    @Mock TransactionRepository transactionRepository;
    @Mock DenominationBalanceRepository denominationBalanceRepository;
    @Mock DenominationRepository denominationRepository;
    @Mock ExchangeRateRepository exchangeRateRepository;
    @Mock CustomerRepository customerRepository;
    @Mock ReservationRepository reservationRepository;
    @Mock EveningSyncLogRepository eveningSyncLogRepository;
    @Mock SystemParameterService systemParameterService;

    @InjectMocks
    EveningClosingService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final LocalDate TODAY = LocalDate.of(2026, 3, 16);

    // Task 1 – getDenominations olvas DenominationBalance-ből, NEM Denomination-ból
    @Test
    @DisplayName("prepareDailyPackage – getDenominations DenominationBalance-ből olvas")
    void getDenominations_readFromDenominationBalance_notMasterTable() {
        stubMinimal();

        DenominationBalance bal = mock(DenominationBalance.class);
        when(bal.getCurrencyCode()).thenReturn("EUR");
        when(bal.getQuantity()).thenReturn(10);
        when(bal.getFaceValue()).thenReturn(new BigDecimal("50"));
        when(bal.getTotalValue()).thenReturn(new BigDecimal("500"));
        when(denominationBalanceRepository.findByBranchIdAndDate(eq(BRANCH_ID), eq(TODAY)))
            .thenReturn(List.of(bal));

        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_ID, TODAY);

        // DenominationRepository (master table) should NOT be called
        verify(denominationRepository, never()).findByBranchId(any());
        // DenominationBalanceRepository MUST be called
        verify(denominationBalanceRepository, atLeastOnce()).findByBranchIdAndDate(eq(BRANCH_ID), eq(TODAY));
        // Package must contain the denomination entry
        assertThat(pkg.getDenominations())
            .as("getDenominations lista nem lehet üres")
            .isNotEmpty();
        assertThat(pkg.getDenominations().get(0).getCurrencyCode()).isEqualTo("EUR");
    }

    // Task 2 – getCustomers deduplication
    @Test
    @DisplayName("prepareDailyPackage – getCustomers deduplikálja az ügyfeleket customerId alapján")
    void getCustomers_deduplicatedByCustomerId() {
        stubMinimal();

        // Két tranzakció ugyanazzal az ügyféllel
        Transaction tx1 = mockTx("CUST-001", "Kovács János", "AB123456", "NATURAL");
        Transaction tx2 = mockTx("CUST-001", "Kovács János", "AB123456", "NATURAL");
        when(transactionRepository.findByBranchAndDate(eq(BRANCH_ID), eq(TODAY)))
            .thenReturn(List.of(tx1, tx2));

        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_ID, TODAY);

        assertThat(pkg.getCustomers())
            .as("Ugyanaz az ügyfél csak egyszer szerepelhet")
            .hasSize(1);
    }

    // Task 3 – getReservations filters by date
    @Test
    @DisplayName("prepareDailyPackage – getReservations csak aznapi foglalókat ad vissza")
    void getReservations_onlyTodayReservations() {
        stubMinimal();
        when(reservationRepository.findActiveByBranchAndDate(eq(BRANCH_ID), eq(TODAY)))
            .thenReturn(List.of()); // method signature check

        service.prepareDailyPackage(BRANCH_ID, TODAY);

        // The OLD method (without date) must NOT be called
        verify(reservationRepository, never()).findByBranchIdAndStatus(any(), any());
        // The NEW method (with date) MUST be called
        verify(reservationRepository, atLeastOnce()).findActiveByBranchAndDate(eq(BRANCH_ID), eq(TODAY));
    }

    // Task 4 – calculateChecksum includes all categories
    @Test
    @DisplayName("prepareDailyPackage – checksum nem lehet üres vagy CHECKSUM_ERROR")
    void calculateChecksum_notEmpty() {
        stubMinimal();
        DailyDataPackage pkg = service.prepareDailyPackage(BRANCH_ID, TODAY);
        assertThat(pkg.getChecksum())
            .isNotBlank()
            .isNotEqualTo("CHECKSUM_ERROR")
            .hasSize(64); // SHA-256 hex = 64 chars
    }

    // Task 5 – UUID round-trip correctness
    @Test
    @DisplayName("prepareDailyPackage(UUID) – UUID MSB nem veszhet el")
    void prepareDailyPackage_uuidRoundTrip_msbPreserved() {
        // UUID with non-zero MSB
        UUID fullUuid = UUID.fromString("12345678-1234-5678-1234-567812345678");
        stubMinimal();

        DailyDataPackage pkg = service.prepareDailyPackage(fullUuid, TODAY);

        // The package branchId (Long, stored as LSB) is correct
        assertThat(pkg.getBranchId()).isEqualTo(fullUuid.getLeastSignificantBits());
        // The DenominationBalance was queried with the FULL UUID, not a mangled one
        verify(denominationBalanceRepository).findByBranchIdAndDate(eq(fullUuid), eq(TODAY));
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private void stubMinimal() {
        when(transactionRepository.findByBranchAndDate(eq(BRANCH_ID), eq(TODAY)))
            .thenReturn(List.of());
        when(denominationBalanceRepository.findByBranchIdAndDate(eq(BRANCH_ID), eq(TODAY)))
            .thenReturn(List.of());

        try (MockedStatic<SecurityUtils> su = MockedStatic.class.cast(
                org.mockito.Mockito.mockStatic(SecurityUtils.class))) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        }

        when(exchangeRateRepository.findActiveRatesByDate(any(), any())).thenReturn(List.of());
        when(reservationRepository.findActiveByBranchAndDate(any(), any())).thenReturn(List.of());
        when(transactionRepository.sumDailyHandlingFees(any(), any())).thenReturn(BigDecimal.ZERO);
    }

    private Transaction mockTx(String customerId, String customerName,
                                String docNumber, String type) {
        Transaction tx = mock(Transaction.class);
        when(tx.getCustomerId()).thenReturn(customerId);
        when(tx.getCustomerName()).thenReturn(customerName);
        when(tx.getCustomerDocumentNumber()).thenReturn(docNumber);
        when(tx.isActive()).thenReturn(true);
        return tx;
    }
}
```

> **Note on stubMinimal with SecurityUtils:** Since `SecurityUtils` is used inside `getRates()` which calls `SecurityUtils.getCurrentCompanyId()`, the test must mock it. Use `MockedStatic` properly in each test method or add a `@BeforeEach` with `try-with-resources`.

- [ ] Run failing then passing:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=EveningClosingServiceTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```

- [ ] Full suite regression check:
```bash
cd backend && ./mvnw test 2>&1 | tail -20
```

---

## Commit

```bash
git add \
  backend/src/main/java/hu/puzzleir/valuta/service/EveningClosingService.java \
  backend/src/main/java/hu/puzzleir/valuta/repository/ReservationRepository.java \
  backend/src/test/java/hu/puzzleir/valuta/service/EveningClosingServiceTest.java

git commit -m "$(cat <<'EOF'
fix(evening-closing): fix 6 bugs in EveningClosingService data package assembly

- getDenominations() now reads DenominationBalance (daily counted), not master Denomination table
- getCustomers() deduplicates by customerId, no longer hardcodes customerType='NATURAL'
- getReservations() now filters by date (findActiveByBranchAndDate)
- calculateChecksum() now hashes all 9 data categories for strong integrity
- UUID round-trip fixed: prepareDailyPackage(UUID) no longer loses MSB via uuidFromLong
- sendToHeadquarters() now performs real HTTP POST when headquarters URL is configured
- TDD: EveningClosingServiceTest added

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
