# Western Union Full Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden WesternUnionService: (1) replace String status with a proper enum, (2) validate MTCN format, (3) add AML check to send/receive, (4) add `reverseWuTransaction()`, (5) deduplicate WuCustomer by name + ID document, (6) add missing operation types (IC=InterChange, STORNO).

**Architecture:** New `WuTransactionStatus` enum replaces the `String status` column. Flyway V91 migrates existing data. `WesternUnionService` gains three new methods. `WuCustomerRepository` gets a deduplication query. No new REST endpoints needed — existing `recordSend`/`recordReceive` signatures preserved.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Context

- **WesternUnionService:** `backend/src/main/java/hu/puzzleir/valuta/service/WesternUnionService.java`
- **WuTransaction entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/WuTransaction.java`
  - `transactionType`: String — values: `"SEND"`, `"RECEIVE"`
  - `status`: String — values: `"COMPLETED"`
  - `mtcn`: String length 20
  - `amountUsd`, `amountHuf`, `exchangeRate`, `feeAmount`: BigDecimal
  - `wuCustomer`: FK → WuCustomer (nullable)
- **WuCustomer entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/WuCustomer.java`
  - fields: `firstName`, `lastName`, `idType`, `idNumber`, `phone`, `nationality`, `dateOfBirth`, `address`
- **WuCustomerRepository:** `backend/src/main/java/hu/puzzleir/valuta/repository/WuCustomerRepository.java`
  - only has `findByIdNumber(String idNumber)` — no name+doc deduplication
- **WuBalance entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/WuBalance.java`
- **AmlService:** injected into WesternUnionService — currently NOT injected, needs to be added
- **Migrations dir:** V89 (plan-06), V90 (plan-07) reserved → use **V91**

### Legacy operation types (from WU DLL)
| Code | Description |
|------|-------------|
| SEND | Küldés (pénz kiküldése) |
| RECEIVE | Fogadás (pénz átvétele) |
| IC_OUT | InterChange kimenő |
| IC_IN  | InterChange bejövő |
| STORNO | Visszavonás |
| CUSTOMER_IN | Ügyfél befizetés |
| CUSTOMER_OUT | Ügyfél kifizetés |

---

## Task 1: WuTransactionStatus enum

- [ ] Create: `backend/src/main/java/hu/puzzleir/valuta/entity/WuTransactionStatus.java`

```java
package hu.puzzleir.valuta.entity;

/**
 * Western Union tranzakció státuszok.
 * Legacy: WU DLL — WUMOZGAS.STATUS mező.
 */
public enum WuTransactionStatus {
    /** Tranzakció befogadva, feldolgozás folyamatban */
    PENDING,
    /** Sikeresen elvégezve */
    COMPLETED,
    /** Sztornózva / visszavonva */
    REVERSED,
    /** Hibás, nem lett feldolgozva */
    FAILED
}
```

### Flyway migration V91 — migrate string status → enum-compatible

- [ ] Create: `backend/src/main/resources/db/migration/V91__wu_transaction_status_enum.sql`

```sql
-- V91: WU tranzakció státusz mező normalizálás + új művelettípusok
-- A status mezőt megtartjuk VARCHAR-ként (Spring @Enumerated(STRING) kompatibilis)

-- 1. Normalizálás: esetleges NULL vagy üres értékek fixálása
UPDATE wu_transactions SET status = 'COMPLETED' WHERE status IS NULL OR status = '';

-- 2. Érvényes értékek kényszere
ALTER TABLE wu_transactions
    ADD CONSTRAINT chk_wu_status
    CHECK (status IN ('PENDING','COMPLETED','REVERSED','FAILED'));

-- 3. Érvényes művelettípusok kényszere
-- Ha már van chk_wu_type, drop+recreate
ALTER TABLE wu_transactions
    DROP CONSTRAINT IF EXISTS chk_wu_type;
ALTER TABLE wu_transactions
    ADD CONSTRAINT chk_wu_type
    CHECK (transaction_type IN ('SEND','RECEIVE','IC_IN','IC_OUT','STORNO','CUSTOMER_IN','CUSTOMER_OUT'));

-- 4. Sztornó esetén a reversed_transaction_id hasznos
ALTER TABLE wu_transactions
    ADD COLUMN IF NOT EXISTS reversed_transaction_id UUID,
    ADD COLUMN IF NOT EXISTS reversal_reason VARCHAR(500);

ALTER TABLE wu_transactions
    ADD CONSTRAINT fk_wu_reversed FOREIGN KEY (reversed_transaction_id)
    REFERENCES wu_transactions(id)
    ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE INDEX IF NOT EXISTS idx_wu_reversed ON wu_transactions(reversed_transaction_id)
    WHERE reversed_transaction_id IS NOT NULL;

-- 5. WuCustomer deduplication index
CREATE UNIQUE INDEX IF NOT EXISTS uidx_wu_customer_name_doc
    ON wu_customers(last_name, first_name, id_type, id_number)
    WHERE id_number IS NOT NULL AND id_type IS NOT NULL;
```

### Update WuTransaction entity

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/entity/WuTransaction.java`

Replace the `status` field declaration:
```java
// BEFORE:
@Column(name = "status", nullable = false, length = 20)
@Builder.Default
private String status = "COMPLETED";

// AFTER:
@Enumerated(EnumType.STRING)
@Column(name = "status", nullable = false, length = 20)
@Builder.Default
private WuTransactionStatus status = WuTransactionStatus.COMPLETED;
```

Also add the reversal fields:
```java
/** Ha ez egy sztornó tranzakció, az eredeti tranzakció UUID-je */
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "reversed_transaction_id")
private WuTransaction reversedTransaction;

/** Sztornó indoklás */
@Column(name = "reversal_reason", length = 500)
private String reversalReason;
```

---

## Task 2: MTCN format validation

MTCN (Money Transfer Control Number): 10 jegyű numerikus szám (WU specifikáció).

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/WesternUnionService.java`

Add private static method:
```java
private static final java.util.regex.Pattern MTCN_PATTERN =
    java.util.regex.Pattern.compile("^\\d{10}$");

/**
 * MTCN validáció (10 jegyű numerikus, WU specifikáció).
 * Példa érvényes MTCN: "1234567890"
 */
private void validateMtcn(String mtcn) {
    if (mtcn == null || mtcn.isBlank()) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "MTCN (Money Transfer Control Number) megadása kötelező!");
    }
    if (!MTCN_PATTERN.matcher(mtcn.trim()).matches()) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "Érvénytelen MTCN formátum: '" + mtcn +
            "' — pontosan 10 jegyű szám szükséges (pl. 1234567890)");
    }
}
```

Call `validateMtcn(dto.getMtcn())` as the FIRST line in both `recordSend()` and `recordReceive()`.

---

## Task 3: AML check in recordSend and recordReceive

- [ ] Edit `WesternUnionService.java` — add `AmlService` injection

Add to constructor-injected fields:
```java
private final AmlService amlService;
```

### AML check helper

```java
/**
 * AML ellenőrzés WU tranzakcióhoz.
 * WU tranzakciók HUF értéke is ellenőrzendő a 300K / 1.5M / 3.6M limitekkel.
 */
private void performAmlCheck(WuTransactionDto dto) {
    if (dto.getAmountHuf() == null) return;

    AmlService.AmlBasicCheckResult amlResult = amlService.checkTransaction(
        dto.getAmountHuf(),
        dto.getWuCustomerId() != null ? dto.getWuCustomerId().toString() : null,
        dto.getSenderName() != null ? dto.getSenderName() : dto.getReceiverName(),
        null // WU esetén nincs okmányszám ebben a DTO-ban
    );

    if (!amlResult.isApproved()) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "WU tranzakció AML ellenőrzés sikertelen: " + amlResult.getRejectionReason());
    }

    if (amlResult.isRequiresDetailedId()) {
        log.warn("WU AML: Részletes azonosítás szükséges! MTCN={}, összeg={} HUF",
            dto.getMtcn(), dto.getAmountHuf());
    }

    if (amlResult.isSuspiciousFlag()) {
        log.warn("WU AML: Gyanús napi összeg! MTCN={}, összeg={} HUF",
            dto.getMtcn(), dto.getAmountHuf());
    }
}
```

Call `performAmlCheck(dto)` at the start of `recordSend()` and `recordReceive()` — after MTCN validation.

---

## Task 4: reverseWuTransaction()

- [ ] Edit `WesternUnionService.java` — add reversal method

```java
/**
 * WU tranzakció sztornózása / visszavonása.
 *
 * Legacy: WU DLL STORNO típusú tranzakció.
 * - Új STORNO tranzakció létrehozása az eredeti ellentétje
 * - Egyenleg visszaállítása
 * - Eredeti tranzakció REVERSED státuszra vált
 *
 * @param originalTxId visszavonandó tranzakció UUID
 * @param reason       stornó oka (kötelező)
 * @return az újonnan létrehozott STORNO tranzakció
 */
@Transactional
public WuTransaction reverseWuTransaction(UUID originalTxId, String reason) {
    if (reason == null || reason.isBlank()) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "WU sztornó indoklása kötelező!");
    }

    WuTransaction original = wuTransactionRepository.findById(originalTxId)
        .orElseThrow(() -> new hu.puzzleir.valuta.exception.ResourceNotFoundException(
            "WU tranzakció nem található: " + originalTxId));

    if (original.getStatus() == WuTransactionStatus.REVERSED) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "Ez a WU tranzakció már sztornózva van: " + originalTxId);
    }
    if (original.getStatus() == WuTransactionStatus.FAILED) {
        throw new hu.puzzleir.valuta.exception.ValidationException(
            "Hibás WU tranzakció nem sztornózható: " + originalTxId);
    }

    // Sztornó tranzakció létrehozása
    WuTransaction storno = WuTransaction.builder()
        .branch(original.getBranch())
        .wuCustomer(original.getWuCustomer())
        .transactionType("STORNO")
        .mtcn(original.getMtcn())                   // ugyanaz az MTCN
        .amountUsd(original.getAmountUsd())
        .amountHuf(original.getAmountHuf())
        .exchangeRate(original.getExchangeRate())
        .feeAmount(original.getFeeAmount())
        .senderName(original.getSenderName())
        .receiverName(original.getReceiverName())
        .destinationCountry(original.getDestinationCountry())
        .status(WuTransactionStatus.COMPLETED)
        .reversedTransaction(original)
        .reversalReason(reason)
        .transactionDate(LocalDateTime.now())
        .build();

    WuTransaction savedStorno = wuTransactionRepository.save(storno);

    // Eredeti REVERSED státuszra vált
    original.setStatus(WuTransactionStatus.REVERSED);
    original.setReversalReason(reason);
    wuTransactionRepository.save(original);

    // Egyenleg visszaállítás (ellentétes irány mint az eredetinél)
    boolean originalWasSend = "SEND".equals(original.getTransactionType());
    // Eredeti SEND volt → sztornó a SEND irányát megfordítja (receive irányban korrigál)
    updateBalance(original.getBranch().getId(),
        original.getAmountUsd(), original.getAmountHuf(), !originalWasSend);

    log.info("WU sztornó: originalId={}, MTCN={}, stornoId={}, ok={}",
        originalTxId, original.getMtcn(), savedStorno.getId(), reason);

    return savedStorno;
}
```

---

## Task 5: WuCustomer deduplication

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/repository/WuCustomerRepository.java`

Add deduplication query:
```java
/**
 * WuCustomer deduplikáció — név + okmányazonosító alapján.
 * Ha már létezik → ne hozzunk létre új rekordot.
 */
@Query("SELECT wc FROM WuCustomer wc " +
       "WHERE LOWER(wc.lastName) = LOWER(:lastName) " +
       "AND LOWER(wc.firstName) = LOWER(:firstName) " +
       "AND wc.idType = :idType " +
       "AND wc.idNumber = :idNumber")
Optional<WuCustomer> findByNameAndDocument(
    @Param("lastName") String lastName,
    @Param("firstName") String firstName,
    @Param("idType") String idType,
    @Param("idNumber") String idNumber);
```

### findOrCreateWuCustomer helper in WesternUnionService

- [ ] Edit `WesternUnionService.java` — add helper method:

```java
/**
 * WU ügyfél keresése vagy létrehozása.
 * Deduplikáció: azonos nevű + okmányú ügyfél nem duplikálódik.
 *
 * @param dto WU tranzakció DTO (tartalmaznia kell az ügyfél adatokat)
 * @return meglévő vagy új WuCustomer entity
 */
public WuCustomer findOrCreateWuCustomer(String firstName, String lastName,
                                          String idType, String idNumber,
                                          String phone, String nationality) {
    if (idType != null && idNumber != null) {
        Optional<WuCustomer> existing = wuCustomerRepository.findByNameAndDocument(
            lastName, firstName, idType, idNumber);
        if (existing.isPresent()) {
            log.debug("WU ügyfél dedup: megtalálva: {} {} ({}:{})",
                firstName, lastName, idType, idNumber);
            return existing.get();
        }
    }

    WuCustomer newCustomer = WuCustomer.builder()
        .firstName(firstName)
        .lastName(lastName)
        .idType(idType)
        .idNumber(idNumber)
        .phone(phone)
        .nationality(nationality)
        .build();

    WuCustomer saved = wuCustomerRepository.save(newCustomer);
    log.info("WU ügyfél létrehozva: {} {}, id: {}", firstName, lastName, saved.getId());
    return saved;
}
```

---

## Task 6: Missing operation types (IC, STORNO, CUSTOMER_IN/OUT)

- [ ] Edit `WesternUnionService.java` — add new operation methods:

```java
/**
 * IC (InterChange) bejövő rögzítése.
 * Legacy: WU DLL IC_IN típus — bankközi átvezetés.
 */
@Transactional
public WuTransaction recordIcIn(WuTransactionDto dto) {
    Branch branch = findBranch(dto.getBranchId());

    WuTransaction tx = WuTransaction.builder()
        .branch(branch)
        .transactionType("IC_IN")
        .mtcn(dto.getMtcn())
        .amountUsd(dto.getAmountUsd())
        .amountHuf(dto.getAmountHuf())
        .exchangeRate(dto.getExchangeRate())
        .feeAmount(dto.getFeeAmount())
        .senderName(dto.getSenderName())
        .receiverName(dto.getReceiverName())
        .status(WuTransactionStatus.COMPLETED)
        .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
        .build();

    WuTransaction saved = wuTransactionRepository.save(tx);
    // IC_IN: USD nő, HUF csökken (fordított irány mint SEND)
    updateBalance(dto.getBranchId(), dto.getAmountUsd(), dto.getAmountHuf(), false);
    log.info("WU IC_IN recorded: amount={} USD, branch={}", dto.getAmountUsd(), dto.getBranchId());
    return saved;
}

/**
 * IC (InterChange) kimenő rögzítése.
 * Legacy: WU DLL IC_OUT típus — bankközi átvezetés.
 */
@Transactional
public WuTransaction recordIcOut(WuTransactionDto dto) {
    Branch branch = findBranch(dto.getBranchId());

    WuTransaction tx = WuTransaction.builder()
        .branch(branch)
        .transactionType("IC_OUT")
        .mtcn(dto.getMtcn())
        .amountUsd(dto.getAmountUsd())
        .amountHuf(dto.getAmountHuf())
        .exchangeRate(dto.getExchangeRate())
        .feeAmount(dto.getFeeAmount())
        .senderName(dto.getSenderName())
        .receiverName(dto.getReceiverName())
        .status(WuTransactionStatus.COMPLETED)
        .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
        .build();

    WuTransaction saved = wuTransactionRepository.save(tx);
    // IC_OUT: USD csökken, HUF nő (azonos irány mint SEND)
    updateBalance(dto.getBranchId(), dto.getAmountUsd(), dto.getAmountHuf(), true);
    log.info("WU IC_OUT recorded: amount={} USD, branch={}", dto.getAmountUsd(), dto.getBranchId());
    return saved;
}
```

### getDailyReport frissítése — új típusokat is számol

- [ ] Edit `getDailyReport()` in `WesternUnionService.java`

Replace the `if ("SEND".equals(tx.getTransactionType()))` block with an enhanced version:
```java
switch (tx.getTransactionType()) {
    case "SEND", "IC_OUT", "CUSTOMER_OUT" -> {
        sendCount++;
        if (tx.getAmountUsd() != null) totalSendUsd = totalSendUsd.add(tx.getAmountUsd());
        if (tx.getAmountHuf() != null) totalSendHuf = totalSendHuf.add(tx.getAmountHuf());
    }
    case "RECEIVE", "IC_IN", "CUSTOMER_IN" -> {
        receiveCount++;
        if (tx.getAmountUsd() != null) totalReceiveUsd = totalReceiveUsd.add(tx.getAmountUsd());
        if (tx.getAmountHuf() != null) totalReceiveHuf = totalReceiveHuf.add(tx.getAmountHuf());
    }
    case "STORNO" -> {
        // Sztornókat nem számoljuk bele a forgalomba — külön riportálni
    }
    default -> log.warn("Ismeretlen WU tranzakció típus a napi riportban: {}", tx.getTransactionType());
}
```

---

## TDD Steps

### Test file location
`backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceTest.java`

### Test cases

- [ ] **T1: MTCN valid** — `validateMtcn("1234567890")` does not throw
- [ ] **T2: MTCN invalid — 9 digits** — throws `ValidationException`
- [ ] **T3: MTCN invalid — letters** — `"ABC1234567"` throws `ValidationException`
- [ ] **T4: MTCN null** — throws `ValidationException`
- [ ] **T5: AML check called on recordSend** — when `amlService.checkTransaction` returns `approved=false`, throws `ValidationException`
- [ ] **T6: reverseWuTransaction — creates STORNO** — result has `transactionType == "STORNO"`
- [ ] **T7: reverseWuTransaction — original becomes REVERSED** — original entity status is `REVERSED` after call
- [ ] **T8: reverseWuTransaction — already REVERSED throws** — second reversal throws `ValidationException`
- [ ] **T9: findOrCreateWuCustomer — dedup** — when `findByNameAndDocument` returns existing, no new entity saved
- [ ] **T10: findOrCreateWuCustomer — creates new** — when not found, `wuCustomerRepository.save` called once
- [ ] **T11: WuTransactionStatus enum** — `WuTransaction.builder().status(WuTransactionStatus.COMPLETED).build()` — status is enum, not String
- [ ] **T12: getDailyReport counts IC_IN as receive** — IC_IN transaction increments receiveCount

```java
@Test
void validateMtcn_invalidFormat_throws() {
    assertThrows(ValidationException.class, () -> service.validateMtcn("12345"));
    assertThrows(ValidationException.class, () -> service.validateMtcn("ABC1234567"));
    assertThrows(ValidationException.class, () -> service.validateMtcn(null));
    assertDoesNotThrow(() -> service.validateMtcn("1234567890"));
}

@Test
void reverseWuTransaction_setsReversedStatus() {
    UUID branchId = UUID.randomUUID();
    UUID txId = UUID.randomUUID();
    Branch branch = new Branch(); branch.setId(branchId);
    WuTransaction original = WuTransaction.builder()
        .id(txId).transactionType("SEND").status(WuTransactionStatus.COMPLETED)
        .amountUsd(BigDecimal.valueOf(100)).amountHuf(BigDecimal.valueOf(38000))
        .branch(branch).build();

    when(wuTransactionRepository.findById(txId)).thenReturn(Optional.of(original));
    when(wuTransactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    when(wuBalanceRepository.findByBranchId(branchId)).thenReturn(Optional.empty());
    when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

    WuTransaction storno = service.reverseWuTransaction(txId, "Ügyfél kérte");

    assertEquals("STORNO", storno.getTransactionType());
    assertEquals(WuTransactionStatus.REVERSED, original.getStatus());
}
```

---

## Test commands

```bash
cd backend
./mvnw test -Dtest=WesternUnionServiceTest -q
```

---

## Commit message

```
feat(wu): WuTransactionStatus enum, MTCN validation, AML integration, reversal, dedup, IC types

- WuTransactionStatus enum: PENDING/COMPLETED/REVERSED/FAILED
- V91 migration: status/type CHECK constraints, reversed_transaction_id FK, WuCustomer unique index
- recordSend/recordReceive: MTCN 10-digit validation + AML check
- reverseWuTransaction(): STORNO tx creation, balance rollback, REVERSED status on original
- findOrCreateWuCustomer(): dedup by lastName+firstName+idType+idNumber
- recordIcIn/recordIcOut(): IC=InterChange operation types
- getDailyReport: handles SEND/RECEIVE/IC_IN/IC_OUT/CUSTOMER_IN/CUSTOMER_OUT/STORNO

Fixes: String status, missing AML bypass, no storno, WuCustomer duplicates
```
