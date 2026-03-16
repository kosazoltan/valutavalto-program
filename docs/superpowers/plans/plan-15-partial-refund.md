# Partial Refund Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `StornoService.executeOtpRefund()` — a `refundAmount` paraméter el van fogadva, de `executeReversal()` mindig teljes sztornót hajt végre. Implementálni kell a valódi részleges visszatérítés logikát: új `PARTIAL_REFUND` tranzakciótípus, részleges kassza egyenleg módosítás, és az eredeti tranzakcióhoz való kapcsolás.

**Architecture:** Új `PARTIAL_REFUND` enum értéket adunk a `TransactionType`-hoz. A `TransactionService`-ben új `executePartialRefund()` metódus a részleges összegű visszatérítési tranzakciót hozza létre (nem módosítja az eredetit `isReversed=true`-ra). A `CashBalance` csak a részleges összeggel módosul. Az eredeti tranzakcióhoz `partialRefundId` foreign key linkel. Flyway migrációval adjuk hozzá a `partial_refund_amount` és `original_transaction_id` oszlopokat.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P2-MEDIUM
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/StornoService.java` (fő módosítás)
  - `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java` (új metódus)
  - `backend/src/main/java/hu/puzzleir/valuta/entity/TransactionType.java` (PARTIAL_REFUND)
  - `backend/src/main/java/hu/puzzleir/valuta/entity/Transaction.java` (új mezők)
  - `backend/src/main/resources/db/migration/V90__partial_refund_support.sql` (ÚJ)
  - `backend/src/test/java/hu/puzzleir/valuta/service/StornoServiceTest.java` (bővítés vagy ÚJ)

---

## Task 1: Teszt a részleges visszatérítésre (TDD első)

### 1.1 Meglévő viselkedés demonstrálása (Red teszt)

- [ ] Hozd létre / nyisd meg: `backend/src/test/java/hu/puzzleir/valuta/service/StornoServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class StornoServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private StornoApprovalRepository stornoApprovalRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private TransactionService transactionService;
    @Mock private DictionaryRepository dictionaryRepository;

    @InjectMocks private StornoService stornoService;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    // ============ TASK 1: RÉSZLEGES VISSZATÉRÍTÉS ============

    @Test
    @DisplayName("executeOtpRefund: 50%-os visszatérítés — NEM teljes sztornó")
    void executeOtpRefund_partialAmount_doesNotFullyReverse() {
        mockSecurityContextWithBranch(BRANCH_ID);

        Transaction original = Transaction.builder()
            .id(42L)
            .hufAmount(new BigDecimal("100000"))    // eredeti összeg: 100 000 Ft
            .currencyAmount(new BigDecimal("250"))
            .paymentMethod(PaymentMethod.CARD)
            .posAuthorizationCode("AUTH-001")
            .posReferenceNumber("POS-REF-001")
            .transactionType(TransactionType.SELL)
            .branch(Branch.builder().id(BRANCH_ID).build())
            .isReversed(false)
            .isReversal(false)
            .build();

        when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));
        when(transactionService.executePartialRefund(any()))
            .thenAnswer(inv -> {
                TransactionService.PartialRefundRequest req = inv.getArgument(0);
                // Ellenőrzés: az összeg valóban 50 000 Ft (50%), nem 100 000 Ft
                assertThat(req.getRefundHufAmount())
                    .isEqualByComparingTo(new BigDecimal("50000"));
                return Transaction.builder()
                    .id(99L)
                    .transactionType(TransactionType.PARTIAL_REFUND)
                    .hufAmount(req.getRefundHufAmount())
                    .build();
            });

        Transaction result = stornoService.executeOtpRefund(
            42L, WORKER_ID, new BigDecimal("50000"), "Részleges visszatérítés");

        assertThat(result.getTransactionType()).isEqualTo(TransactionType.PARTIAL_REFUND);
        assertThat(result.getHufAmount()).isEqualByComparingTo(new BigDecimal("50000"));

        // Az eredeti tranzakció NEM lett reversed (nem teljes sztornó)
        assertThat(original.isReversed()).isFalse();

        // executeReversal NEM lett meghívva
        verify(transactionService, never()).executeReversal(any());
        // executePartialRefund lett meghívva
        verify(transactionService, times(1)).executePartialRefund(any());
    }

    @Test
    @DisplayName("executeOtpRefund: összeg > eredeti → ValidationException")
    void executeOtpRefund_exceedsOriginal_throws() {
        mockSecurityContextWithBranch(BRANCH_ID);

        Transaction original = Transaction.builder()
            .id(42L)
            .hufAmount(new BigDecimal("100000"))
            .paymentMethod(PaymentMethod.CARD)
            .posAuthorizationCode("AUTH-001")
            .branch(Branch.builder().id(BRANCH_ID).build())
            .isReversed(false).isReversal(false)
            .build();

        when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));

        assertThatThrownBy(() ->
            stornoService.executeOtpRefund(42L, WORKER_ID, new BigDecimal("150000"), "Túlzott visszatérítés"))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("nem haladhatja meg");
    }

    @Test
    @DisplayName("executeOtpRefund: null összeg → teljes sztornó (executeReversal hívódik)")
    void executeOtpRefund_nullAmount_fullReversal() {
        mockSecurityContextWithBranch(BRANCH_ID);

        Transaction original = Transaction.builder()
            .id(42L)
            .hufAmount(new BigDecimal("100000"))
            .paymentMethod(PaymentMethod.CARD)
            .posAuthorizationCode("AUTH-001")
            .branch(Branch.builder().id(BRANCH_ID).build())
            .isReversed(false).isReversal(false)
            .build();

        when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));
        when(transactionService.executeReversal(any())).thenReturn(Transaction.builder()
            .id(99L).transactionType(TransactionType.REVERSAL)
            .hufAmount(new BigDecimal("100000")).build());
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // null összeg = teljes sztornó (visszafelé kompatibilitás)
        Transaction result = stornoService.executeOtpRefund(42L, WORKER_ID, null, "Teljes visszatérítés");

        assertThat(result.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
        verify(transactionService, times(1)).executeReversal(any());
        verify(transactionService, never()).executePartialRefund(any());
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=StornoServiceTest#executeOtpRefund*` → PIROS

---

## Task 2: PARTIAL_REFUND tranzakció típus és infrastruktúra

### 2.1 TransactionType enum bővítése

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/entity/TransactionType.java`
- [ ] Add hozzá a `PARTIAL_REFUND` értéket:

```java
public enum TransactionType {
    BUY,
    SELL,
    REVERSAL,
    PARTIAL_REFUND,  // ← ÚJ: részleges OTP visszatérítés (áruvisszavét)
    COMMISSION_ONLY;

    public boolean isBuyType() {
        return this == BUY;
    }

    public boolean isSellType() {
        return this == SELL;
    }

    public boolean isReversalType() {
        return this == REVERSAL || this == PARTIAL_REFUND;
    }
}
```

### 2.2 Flyway migráció

- [ ] Hozd létre: `backend/src/main/resources/db/migration/V90__partial_refund_support.sql`

```sql
-- Részleges visszatérítés támogatása
ALTER TABLE transaction
    ADD COLUMN IF NOT EXISTS partial_refund_amount    NUMERIC(18,4),
    ADD COLUMN IF NOT EXISTS original_transaction_id  BIGINT
        REFERENCES transaction(id) ON DELETE SET NULL;

-- Index a visszakereshetőséghez
CREATE INDEX IF NOT EXISTS idx_transaction_original_id
    ON transaction(original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;

-- PARTIAL_REFUND típus komment
COMMENT ON COLUMN transaction.partial_refund_amount IS
    'PARTIAL_REFUND típusnál: a visszatérített összeg HUF-ban';
COMMENT ON COLUMN transaction.original_transaction_id IS
    'PARTIAL_REFUND/REVERSAL típusnál: az eredeti tranzakció ID-ja';
```

### 2.3 Transaction entitás frissítése

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/entity/Transaction.java`
- [ ] Add hozzá:

```java
@Column(name = "partial_refund_amount", precision = 18, scale = 4)
private BigDecimal partialRefundAmount;

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "original_transaction_id")
private Transaction originalTransaction;

/**
 * Részleges visszatérítés-e?
 */
public boolean isPartialRefund() {
    return this.transactionType == TransactionType.PARTIAL_REFUND;
}
```

---

## Task 3: executePartialRefund() a TransactionService-ben

### 3.1 PartialRefundRequest belső osztály

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- [ ] Add hozzá a `PartialRefundRequest` inner osztályt (a meglévő `ReversalRequest` mellé):

```java
@lombok.Data
@lombok.Builder
@lombok.NoArgsConstructor
@lombok.AllArgsConstructor
public static class PartialRefundRequest {
    private Long originalTransactionId;
    private BigDecimal refundHufAmount;   // visszatérítendő HUF összeg
    private BigDecimal refundCurrencyAmount; // visszatérítendő deviza összeg (opcionális)
    private String reason;
    private String approvedBy;
}
```

### 3.2 executePartialRefund() implementálása

- [ ] Add hozzá a `TransactionService`-hez:

```java
/**
 * Részleges visszatérítés végrehajtása (OTP áruvisszavét).
 *
 * Különbség a teljes sztornótól:
 * - Az eredeti tranzakció MEGMARAD (isReversed=false marad)
 * - Új PARTIAL_REFUND tranzakció jön létre a részleges összeggel
 * - A kassza egyenleg csak a részleges összeggel módosul
 * - Az eredeti tranzakcióhoz linkeljük a részleges visszatérítést
 *
 * Legacy: VTEMP.OTPFUNCTYPE=4 → OtpAruvisszavet
 */
@Transactional
public Transaction executePartialRefund(PartialRefundRequest request) {
    Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
        .orElseThrow(() -> new ResourceNotFoundException(
            "Tranzakció nem található: " + request.getOriginalTransactionId()));

    // Validáció
    if (original.isReversed()) {
        throw new ValidationException("Ez a tranzakció már sztornózva lett — részleges visszatérítés nem lehetséges!");
    }
    if (original.isPartialRefund()) {
        throw new ValidationException("Részleges visszatérítés nem ismételhető!");
    }
    if (request.getRefundHufAmount().compareTo(BigDecimal.ZERO) <= 0) {
        throw new ValidationException("Visszatérítési összeg pozitív kell legyen!");
    }
    if (request.getRefundHufAmount().compareTo(original.getHufAmount()) > 0) {
        throw new ValidationException(
            "Visszatérítési összeg (" + request.getRefundHufAmount()
            + " Ft) nem haladhatja meg az eredeti összeget ("
            + original.getHufAmount() + " Ft)!");
    }

    // Deviza összeg arányos számítása (ha nincs megadva)
    BigDecimal refundCurrencyAmount = request.getRefundCurrencyAmount();
    if (refundCurrencyAmount == null && original.getCurrencyAmount() != null
            && original.getHufAmount().compareTo(BigDecimal.ZERO) > 0) {
        // Arányos: refundHuf / originalHuf * originalCurrency
        refundCurrencyAmount = request.getRefundHufAmount()
            .divide(original.getHufAmount(), 8, RoundingMode.HALF_UP)
            .multiply(original.getCurrencyAmount())
            .setScale(4, RoundingMode.HALF_UP);
    }

    // Új PARTIAL_REFUND tranzakció létrehozása
    Transaction partialRefund = Transaction.builder()
        .transactionType(TransactionType.PARTIAL_REFUND)
        .branch(original.getBranch())
        .worker(original.getWorker())
        .currency(original.getCurrency())
        .hufAmount(request.getRefundHufAmount())
        .currencyAmount(refundCurrencyAmount)
        .exchangeRate(original.getExchangeRate())
        .paymentMethod(original.getPaymentMethod())
        .posAuthorizationCode(original.getPosAuthorizationCode())
        .posReferenceNumber(original.getPosReferenceNumber())
        .posTerminalId(original.getPosTerminalId())
        .originalTransaction(original)
        .partialRefundAmount(request.getRefundHufAmount())
        .transactionDate(LocalDate.now())
        .transactionTime(java.time.LocalTime.now())
        .notes("Részleges visszatérítés: " + request.getReason()
            + " (eredeti: " + original.getReceiptNumber() + ")")
        .active(true)
        .status(TransactionStatus.COMPLETED)
        .build();

    // Bizonylat szám generálás
    partialRefund.setReceiptNumber(generateReceiptNumber(original.getBranch().getId()));

    Transaction saved = transactionRepository.save(partialRefund);

    // Kassza egyenleg módosítás — CSAK a részleges összeg
    adjustCashBalanceForPartialRefund(original, request.getRefundHufAmount(), refundCurrencyAmount);

    log.info("Részleges visszatérítés végrehajtva: eredeti={}, visszatérítés={}, HUF összeg={}",
        original.getReceiptNumber(), saved.getReceiptNumber(), request.getRefundHufAmount());

    return saved;
}

/**
 * Kassza egyenleg módosítás részleges visszatérítésnél.
 * - Eredeti SELL tranzakció volt → vevő visszaadja a devizát → deviza készlet NŐ
 *   (a valutaváltónál: az ügyfél devizát kapott, részben visszahozza)
 * - Eredeti BUY tranzakció volt → az ügyfél visszakapja a HUF-ot
 */
private void adjustCashBalanceForPartialRefund(Transaction original,
        BigDecimal refundHuf, BigDecimal refundCurrency) {
    UUID branchId = original.getBranch().getId();
    Long currencyId = original.getCurrency().getId();

    if (original.getTransactionType() == TransactionType.SELL) {
        // Eredeti SELL: pénztáros devizát adott el → visszajön a deviza, kimegy a HUF
        // Deviza visszajön a kasszába
        if (refundCurrency != null) {
            updateCashBalanceInternal(branchId, currencyId, refundCurrency, true);
        }
        // HUF kimegy a kasszából (visszaadjuk az ügyfélnek)
        updateCashBalanceInternal(branchId, getHufCurrencyId(), refundHuf, false);

    } else if (original.getTransactionType() == TransactionType.BUY) {
        // Eredeti BUY: pénztáros devizát vett → visszaadjuk a devizát, visszajön a HUF
        if (refundCurrency != null) {
            updateCashBalanceInternal(branchId, currencyId, refundCurrency, false);
        }
        updateCashBalanceInternal(branchId, getHufCurrencyId(), refundHuf, true);
    }
}
```

---

## Task 4: executeOtpRefund() javítása

### 4.1 A javított metódus

- [ ] Nyisd meg: `StornoService.java` → `executeOtpRefund()`
- [ ] Cseréld le a teljes metódust:

```java
/**
 * OTP áruvisszavét (részleges visszatérítés).
 * Legacy: VTEMP.OTPFUNCTYPE=4 → OtpAruvisszavet
 *
 * Ha refundAmount == null → teljes sztornó (visszafelé kompatibilitás).
 * Ha refundAmount < originalAmount → valódi részleges visszatérítés.
 */
public Transaction executeOtpRefund(Long transactionId, Long workerId,
                                     BigDecimal refundAmount, String reason) {
    Transaction original = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

    UUID branchId = SecurityUtils.getCurrentBranchId();
    if (!original.getBranch().getId().equals(branchId)) {
        throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
    }

    if (original.getPaymentMethod() != PaymentMethod.CARD) {
        throw new ValidationException("OTP áruvisszavét csak bankkártyás tranzakcióra alkalmazható!");
    }

    // Összeg validáció
    if (refundAmount != null && refundAmount.compareTo(BigDecimal.ZERO) <= 0) {
        throw new ValidationException("Visszatérítési összeg pozitív kell legyen!");
    }
    if (refundAmount != null && refundAmount.compareTo(original.getHufAmount()) > 0) {
        throw new ValidationException(
            String.format("Visszatérítés összege (%s Ft) nem haladhatja meg az eredeti összeget (%s Ft)!",
                refundAmount, original.getHufAmount()));
    }

    Transaction result;

    if (refundAmount == null || refundAmount.compareTo(original.getHufAmount()) == 0) {
        // Teljes sztornó (visszafelé kompatibilis eset)
        log.info("OTP áruvisszavét — teljes sztornó: tranzakció={}", transactionId);
        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason("OTP_ARUVISSZAVET_TELJES: " + reason)
                .approvedBy(String.valueOf(workerId))
                .build();
        result = transactionService.executeReversal(reversalRequest);

    } else {
        // RÉSZLEGES visszatérítés — az ÚJ metódus
        log.info("OTP áruvisszavét — részleges visszatérítés: tranzakció={}, összeg={} Ft",
                transactionId, refundAmount);
        TransactionService.PartialRefundRequest partialRequest = TransactionService.PartialRefundRequest.builder()
                .originalTransactionId(transactionId)
                .refundHufAmount(refundAmount)
                .reason("OTP_ARUVISSZAVET: " + reason)
                .approvedBy(String.valueOf(workerId))
                .build();
        result = transactionService.executePartialRefund(partialRequest);
    }

    // POS terminál adatok másolása az eredménytranzakcióra
    result.setPosAuthorizationCode(original.getPosAuthorizationCode());
    result.setPosReferenceNumber(original.getPosReferenceNumber());
    result.setPosTerminalId(original.getPosTerminalId());
    result.setPaymentMethod(PaymentMethod.CARD);
    transactionRepository.save(result);

    log.info("OTP áruvisszavét végrehajtva: eredeti={}, visszatérítés={}, HUF={}",
            original.getReceiptNumber(), result.getReceiptNumber(), refundAmount);

    return result;
}
```

### 4.2 Kiegészítő tesztek

```java
@Test
@DisplayName("executeOtpRefund: nem kártyás fizetés → ValidationException")
void executeOtpRefund_notCard_throws() {
    mockSecurityContextWithBranch(BRANCH_ID);

    Transaction original = Transaction.builder()
        .id(42L).hufAmount(new BigDecimal("100000"))
        .paymentMethod(PaymentMethod.CASH)  // ← készpénzes!
        .branch(Branch.builder().id(BRANCH_ID).build())
        .isReversed(false).isReversal(false)
        .build();

    when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));

    assertThatThrownBy(() ->
        stornoService.executeOtpRefund(42L, WORKER_ID, new BigDecimal("50000"), "test"))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("bankkártyás");
}

@Test
@DisplayName("executeOtpRefund: 0 Ft visszatérítés → ValidationException")
void executeOtpRefund_zeroAmount_throws() {
    mockSecurityContextWithBranch(BRANCH_ID);

    Transaction original = Transaction.builder()
        .id(42L).hufAmount(new BigDecimal("100000"))
        .paymentMethod(PaymentMethod.CARD)
        .posAuthorizationCode("AUTH-001")
        .branch(Branch.builder().id(BRANCH_ID).build())
        .isReversed(false).isReversal(false)
        .build();

    when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));

    assertThatThrownBy(() ->
        stornoService.executeOtpRefund(42L, WORKER_ID, BigDecimal.ZERO, "test"))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("pozitív");
}

@Test
@DisplayName("executeOtpRefund: teljes összeg → executeReversal (kompatibilitás)")
void executeOtpRefund_fullAmount_callsReversal() {
    mockSecurityContextWithBranch(BRANCH_ID);

    Transaction original = Transaction.builder()
        .id(42L).hufAmount(new BigDecimal("100000"))
        .paymentMethod(PaymentMethod.CARD)
        .posAuthorizationCode("AUTH-001")
        .branch(Branch.builder().id(BRANCH_ID).build())
        .isReversed(false).isReversal(false)
        .build();

    when(transactionRepository.findById(42L)).thenReturn(Optional.of(original));
    when(transactionService.executeReversal(any())).thenReturn(Transaction.builder()
        .id(99L).transactionType(TransactionType.REVERSAL)
        .hufAmount(new BigDecimal("100000")).build());
    when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Transaction result = stornoService.executeOtpRefund(
        42L, WORKER_ID, new BigDecimal("100000"), "Teljes összeg");

    verify(transactionService, times(1)).executeReversal(any());
    verify(transactionService, never()).executePartialRefund(any());
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=StornoServiceTest` → ZÖLD

---

## Futtatandó parancsok

```bash
# Migráció futtatása
cd backend && ./mvnw flyway:migrate

# Tesztek
cd backend && ./mvnw test -Dtest=StornoServiceTest

# Transaction service tesztek is
cd backend && ./mvnw test -Dtest=StornoServiceTest,TransactionServiceTest

# Teljes build
cd backend && ./mvnw clean verify -DskipITs
```

---

## Commit üzenetek

```
feat(transaction): add PARTIAL_REFUND transaction type

feat(transaction): add executePartialRefund() with partial cash balance adjustment

fix(storno): executeOtpRefund delegates to executePartialRefund for partial amounts

test(storno): add StornoServiceTest for partial refund vs full reversal

db: V90 migration — partial_refund_amount and original_transaction_id columns
```

---

## Technikai megjegyzések

### Riportok kezelése

A `PARTIAL_REFUND` tranzakció típust a meglévő riportokban figyelembe kell venni:

- **MnbReportService.aggregateTransactions()**: A `PARTIAL_REFUND` nem `BUY` és nem `SELL` típus → az MNB riportba NE számítson bele (hasonlóan a `REVERSAL`-hoz).
- **ReportService.generateDailyClosingReport()**: A `reversalCount` mezőbe belevehetjük a `PARTIAL_REFUND` tranzakciókat is, vagy külön `partialRefundCount` mezőt hozunk létre.

```java
// MnbReportService.aggregateTransactions() — nincs változás szükséges, mivel:
if (tx.getTransactionType().isBuyType()) { ... }
else if (tx.getTransactionType().isSellType()) { ... }
// PARTIAL_REFUND nem isBuyType() és nem isSellType() → automatikusan kihagyja
```

### OTP terminál protokoll

Az OTP terminál részleges visszatérítési parancshoz (FUNC_TYPE=4, azaz `OtpAruvisszavet`) a terminálnak külön referencia számot kell adni. A jelenlegi implementáció az eredeti POS auth kódot másolja — az éles integráció során ezt pontosítani kell az OTP terminál specifikáció alapján (39/2013 MNB rendelet és az OTP Bank terminál implementációs kézikönyve szerint).
