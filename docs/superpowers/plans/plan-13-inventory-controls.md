# Inventory Controls Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four issues in `InventoryService`: (1) `depositToBank` önmaga jóváhagyja a banki befizetést (nincs négy szem elv), (2) `transferBetweenBranches` nem ellenőrzi a forrás iroda készletét létrehozáskor, (3) `getAllStock` nincs `@Transactional(readOnly=true)` megjelölve, (4) `hufValue` mindig `BigDecimal.ZERO` a mozgás rekordon.

**Architecture:** A négy szem elv implementációhoz a `depositToBank` PENDING státusszal hoz létre mozgást (mint a `requestBankWithdraw`), a CashBalance csökkentést az `approveMovement`-be tesszük BANK_DEPOSIT esetén. A HUF érték számításhoz az aktuális `ExchangeRate`-et hívjuk le a `CashRegisterService`-ből vagy közvetlenül a `ExchangeRateRepository`-ból. Nincs sémaváltozás.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P2-MEDIUM
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/InventoryService.java` (fő módosítás)
  - `backend/src/main/java/hu/puzzleir/valuta/repository/ExchangeRateRepository.java` (meglévő, lekérdezés)
  - `backend/src/test/java/hu/puzzleir/valuta/service/InventoryServiceTest.java` (ÚJ)

---

## Task 1: Négy szem elv — depositToBank PENDING státuszra állítás

### 1.1 A bug leírása

```java
// JELENLEGI KÓDBAN (InventoryService.java:109-110):
.status(MovementStatus.APPROVED)
.approvedBy(worker)         // ← self-approval: aki létrehozza, az is jóváhagyja
.approvedAt(LocalDateTime.now())
```

A `depositToBank()` azonnal APPROVED státusszal hozza létre a mozgást, és a CashBalance-t is azonnal csökkenti. Ez azt jelenti, hogy egyetlen pénztáros jóváhagyás nélkül vihet pénzt a bankba. Az `approveMovement()` metódus már létezik és kezeli a CashBalance-t BANK_WITHDRAW esetén — ezt ki kell terjeszteni BANK_DEPOSIT-ra is.

### 1.2 TDD

- [ ] Hozd létre: `backend/src/test/java/hu/puzzleir/valuta/service/InventoryServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {

    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;

    @InjectMocks private InventoryService inventoryService;

    private static final UUID BRANCH_ID   = UUID.randomUUID();
    private static final Long WORKER_ID   = 1L;
    private static final Long CURRENCY_ID = 10L;

    // ============ TASK 1: NÉGY SZEM ELV ============

    @Test
    @DisplayName("depositToBank: PENDING státusszal hoz létre mozgást (nem APPROVED)")
    void depositToBank_createsPendingMovement() {
        setupCommonMocks();
        CashBalance balance = CashBalance.builder()
            .currentBalance(new BigDecimal("10000"))
            .build();
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), any()))
            .thenReturn(Optional.of(balance));
        when(movementRepository.save(any())).thenAnswer(inv -> {
            InventoryMovement m = inv.getArgument(0);
            m.setId(1L);
            return m;
        });
        when(movementRepository.findMaxReferenceNumber(any())).thenReturn(0L);

        BankDepositRequestDto dto = BankDepositRequestDto.builder()
            .branchId(BRANCH_ID.toString())
            .currencyId(CURRENCY_ID)
            .amount(new BigDecimal("1000"))
            .notes("Napi záró befizetés")
            .build();

        InventoryMovementDto result = inventoryService.depositToBank(dto, WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        assertThat(result.getApprovedById()).isNull();  // önmagát NEM jóváhagyja
        // CashBalance NEM csökkent azonnal
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("depositToBank: elégtelen készlet → ValidationException (PENDING-nél is ellenőrzünk)")
    void depositToBank_insufficientBalance_throws() {
        setupCommonMocks();
        CashBalance balance = CashBalance.builder()
            .currentBalance(new BigDecimal("500"))
            .build();
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), any()))
            .thenReturn(Optional.of(balance));

        BankDepositRequestDto dto = BankDepositRequestDto.builder()
            .branchId(BRANCH_ID.toString())
            .currencyId(CURRENCY_ID)
            .amount(new BigDecimal("1000"))
            .build();

        assertThatThrownBy(() -> inventoryService.depositToBank(dto, WORKER_ID))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("készlet");
    }

    @Test
    @DisplayName("approveMovement: BANK_DEPOSIT jóváhagyásakor CashBalance csökken")
    void approveMovement_bankDeposit_decreasesCashBalance() {
        Branch branch = Branch.builder().id(BRANCH_ID).build();
        Currency currency = Currency.builder().id(CURRENCY_ID).code("EUR").build();
        Worker approver = Worker.builder().id(2L).name("Supervisor").build();

        CashBalance balance = mock(CashBalance.class);
        when(balance.getCurrentBalance()).thenReturn(new BigDecimal("5000"));

        InventoryMovement movement = InventoryMovement.builder()
            .id(1L)
            .fromBranch(branch)
            .currency(currency)
            .amount(new BigDecimal("1000"))
            .movementType(MovementType.BANK_DEPOSIT)
            .status(MovementStatus.PENDING)
            .initiatedBy(Worker.builder().id(WORKER_ID).build())
            .build();

        when(movementRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(2L)).thenReturn(Optional.of(approver));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
            .thenReturn(Optional.of(balance));
        when(movementRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        inventoryService.approveMovement(1L, 2L);

        // CashBalance.subtractBalance() meghívva
        verify(balance).subtractBalance(new BigDecimal("1000"));
        verify(cashBalanceRepository).save(balance);
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=InventoryServiceTest#depositToBank*,*bankDeposit*` → PIROS

### 1.3 Fix

- [ ] Nyisd meg: `InventoryService.java`
- [ ] Cseréld le a `depositToBank()` metódust:

```java
/**
 * Pénztár → bank befizetés kérés (PENDING státusz — négy szem elvhez).
 * CashBalance csökkentés csak approveMovement() jóváhagyásakor történik.
 */
@Transactional
public InventoryMovementDto depositToBank(BankDepositRequestDto dto, Long workerId) {
    Branch branch = findBranch(dto.getBranchId());
    Currency currency = findCurrency(dto.getCurrencyId());
    Worker worker = findWorker(workerId);

    // Ellenőrzés: van-e elegendő készlet (már itt ellenőrzünk, hogy korai hibajelzés legyen)
    CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                    branch.getId(), currency.getId())
            .orElseThrow(() -> new ValidationException(
                    "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));

    if (balance.getCurrentBalance().compareTo(dto.getAmount()) < 0) {
        throw new ValidationException("Nincs elegendő készlet! Egyenleg: "
                + balance.getCurrentBalance().setScale(4, RoundingMode.HALF_UP)
                + ", kért: " + dto.getAmount());
    }

    // PENDING státusz — négy szem elvhez (CashBalance NEM csökken azonnal)
    InventoryMovement movement = InventoryMovement.builder()
            .fromBranch(branch)
            .toBranch(null)
            .currency(currency)
            .amount(dto.getAmount())
            .hufValue(BigDecimal.ZERO)  // Task 4-ben javítjuk
            .movementType(MovementType.BANK_DEPOSIT)
            .status(MovementStatus.PENDING)  // ← VOLT: APPROVED
            .initiatedBy(worker)
            // approvedBy NINCS beállítva — négy szem elv
            .referenceNumber(generateReferenceNumber())
            .notes(dto.getNotes())
            .movementDate(LocalDate.now())
            .movementTime(LocalTime.now())
            .build();

    movement = movementRepository.save(movement);
    return toDto(movement);
}
```

- [ ] Bővítsd az `approveMovement()` BANK_DEPOSIT ágát — add a `receiveMovement()` switch-ben lévő BANK_DEPOSIT ághoz CashBalance csökkentést:

```java
// approveMovement() metódusban, a switch blokk UTÁN, de a save() ELŐTT:
// BANK_DEPOSIT esetén az approve = azonnali CashBalance csökkentés (bank ténylegesen megkapja)
if (movement.getMovementType() == MovementType.BANK_DEPOSIT
        && movement.getStatus() == MovementStatus.APPROVED) {
    if (movement.getFromBranch() == null) {
        throw new ValidationException("Bank deposit: fromBranch nem lehet null!");
    }
    updateCashBalance(movement.getFromBranch().getId(),
            movement.getCurrency().getId(), movement.getAmount(), false);
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=InventoryServiceTest` → ZÖLD

---

## Task 2: Forrás iroda készlet ellenőrzés transferBetweenBranches-nél

### 2.1 A bug leírása

```java
// JELENLEGI (InventoryService.java:127-154):
// ← Nincs CashBalance ellenőrzés! PENDING mozgás létrejön akkor is,
//    ha a forrás irodán nincs elegendő valuta.
```

A PENDING mozgás létrejön, majd jóváhagyásra vár. A jóváhagyáskor (`approveMovement`) sem történik készlet ellenőrzés — az csak a `receiveMovement`-nél csökkentené a forrás egyenlegét. Ez lehetővé teszi, hogy egy iroda "negatívba" menjen.

### 2.2 TDD

```java
@Test
@DisplayName("transferBetweenBranches: forrás iroda nincs elég készlet → ValidationException")
void transferBetweenBranches_insufficientSourceStock_throws() {
    Branch fromBranch = Branch.builder().id(BRANCH_ID).build();
    Branch toBranch   = Branch.builder().id(UUID.randomUUID()).build();
    Currency currency = Currency.builder().id(CURRENCY_ID).code("EUR").build();
    Worker worker     = Worker.builder().id(WORKER_ID).build();

    when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(fromBranch));
    when(branchRepository.findById(toBranch.getId())).thenReturn(Optional.of(toBranch));
    when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(currency));
    when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

    // Forrás irodán csak 500 EUR van, 1000-et kérnek
    CashBalance fromBalance = CashBalance.builder()
        .currentBalance(new BigDecimal("500")).build();
    when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
        .thenReturn(Optional.of(fromBalance));

    BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
        .fromBranchId(BRANCH_ID.toString())
        .toBranchId(toBranch.getId().toString())
        .currencyId(CURRENCY_ID)
        .amount(new BigDecimal("1000"))
        .build();

    assertThatThrownBy(() -> inventoryService.transferBetweenBranches(dto, WORKER_ID))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("készlet");
}

@Test
@DisplayName("transferBetweenBranches: elegendő készlet → PENDING mozgás létrejön")
void transferBetweenBranches_sufficientStock_createsPending() {
    Branch fromBranch = Branch.builder().id(BRANCH_ID).build();
    UUID toBranchId   = UUID.randomUUID();
    Branch toBranch   = Branch.builder().id(toBranchId).build();
    Currency currency = Currency.builder().id(CURRENCY_ID).code("EUR").build();
    Worker worker     = Worker.builder().id(WORKER_ID).build();

    when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(fromBranch));
    when(branchRepository.findById(toBranchId)).thenReturn(Optional.of(toBranch));
    when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(currency));
    when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

    CashBalance fromBalance = CashBalance.builder()
        .currentBalance(new BigDecimal("2000")).build();
    when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
        .thenReturn(Optional.of(fromBalance));
    when(movementRepository.findMaxReferenceNumber(any())).thenReturn(0L);
    when(movementRepository.save(any())).thenAnswer(inv -> {
        InventoryMovement m = inv.getArgument(0);
        m.setId(99L);
        return m;
    });

    BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
        .fromBranchId(BRANCH_ID.toString())
        .toBranchId(toBranchId.toString())
        .currencyId(CURRENCY_ID)
        .amount(new BigDecimal("1000"))
        .build();

    InventoryMovementDto result = inventoryService.transferBetweenBranches(dto, WORKER_ID);

    assertThat(result.getStatus()).isEqualTo("PENDING");
}
```

### 2.3 Fix

- [ ] Cseréld le a `transferBetweenBranches()` metódust:

```java
/**
 * Irodák közti szállítás (PENDING státusz).
 * ÚJ: Forrás iroda készlet ellenőrzés létrehozáskor.
 */
@Transactional
public InventoryMovementDto transferBetweenBranches(BranchTransferRequestDto dto, Long workerId) {
    Branch fromBranch = findBranch(dto.getFromBranchId());
    Branch toBranch = findBranch(dto.getToBranchId());
    Currency currency = findCurrency(dto.getCurrencyId());
    Worker worker = findWorker(workerId);

    if (fromBranch.getId().equals(toBranch.getId())) {
        throw new ValidationException("A forrás és cél iroda nem lehet azonos!");
    }

    // ÚJ: Forrás iroda készlet ellenőrzés — korai hibajelzés
    CashBalance sourceBalance = cashBalanceRepository
            .findByBranchIdAndCurrencyId(fromBranch.getId(), currency.getId())
            .orElseThrow(() -> new ValidationException(
                    "Forrás irodán nincs kassza egyenleg ehhez a valutához: " + currency.getCode()
                    + " (iroda: " + fromBranch.getName() + ")"));

    if (sourceBalance.getCurrentBalance().compareTo(dto.getAmount()) < 0) {
        throw new ValidationException(
                "Forrás irodán nincs elegendő készlet szállításhoz! Egyenleg: "
                + sourceBalance.getCurrentBalance().setScale(4, RoundingMode.HALF_UP)
                + " " + currency.getCode()
                + ", kért összeg: " + dto.getAmount());
    }

    InventoryMovement movement = InventoryMovement.builder()
            .fromBranch(fromBranch)
            .toBranch(toBranch)
            .currency(currency)
            .amount(dto.getAmount())
            .hufValue(BigDecimal.ZERO)  // Task 4-ben javítjuk
            .movementType(MovementType.BRANCH_TRANSFER)
            .status(MovementStatus.PENDING)
            .initiatedBy(worker)
            .referenceNumber(generateReferenceNumber())
            .notes(dto.getNotes())
            .movementDate(LocalDate.now())
            .movementTime(LocalTime.now())
            .build();

    movement = movementRepository.save(movement);
    return toDto(movement);
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=InventoryServiceTest#transfer*` → ZÖLD

---

## Task 3: @Transactional(readOnly=true) hozzáadása olvasó metódusokhoz

### 3.1 Érintett metódusok

Az `getAllStock()` metódusnál hiányzik az annotáció:

```java
// JELENLEGI (hibás — nincs @Transactional):
public List<CashBalance> getAllStock() {
    return cashBalanceRepository.findAll();
}
```

### 3.2 Fix

- [ ] Nyisd meg: `InventoryService.java`
- [ ] Add hozzá az `@Transactional(readOnly=true)` annotációt az `getAllStock()` metódushoz:

```java
@Transactional(readOnly=true)
public List<CashBalance> getAllStock() {
    return cashBalanceRepository.findAll();
}
```

- [ ] Ellenőrizd, hogy az összes többi lekérdező metódus is helyes-e — `getCurrentStock()`, `getStockMatrix()`, `getMovement()`, `searchMovements()` már rendelkeznek az annotációval (ellenőrzés a forráskódban).

- [ ] Teszt:

```java
@Test
@DisplayName("getAllStock: metódust @Transactional(readOnly=true) annotációval hívjuk")
void getAllStock_isReadOnly() throws NoSuchMethodException {
    java.lang.reflect.Method method = InventoryService.class
        .getMethod("getAllStock");
    Transactional tx = method.getAnnotation(Transactional.class);

    assertThat(tx).isNotNull();
    assertThat(tx.readOnly()).isTrue();
}
```

---

## Task 4: hufValue kiszámítása aktuális árfolyammal

### 4.1 A bug leírása

Minden `InventoryMovement` létrehozásakor:
```java
.hufValue(BigDecimal.ZERO)  // ← sosem számítják ki
```

Ez azt jelenti, hogy a riportokban és az auditban nem látható a mozgás HUF értéke.

### 4.2 ExchangeRate lookup

- [ ] Nyisd meg: `InventoryService.java`
- [ ] Add hozzá az `ExchangeRateRepository` függőséget:

```java
private final ExchangeRateRepository exchangeRateRepository;
```

- [ ] Add hozzá a privát helper metódust:

```java
/**
 * HUF értéket számít az aktuális árfolyam alapján.
 * Ha az árfolyam nem elérhető (pl. HUF valuta esetén), az összeget adja vissza.
 */
private BigDecimal calculateHufValue(Currency currency, BigDecimal amount) {
    if ("HUF".equalsIgnoreCase(currency.getCode())) {
        return amount;
    }
    try {
        // Aktuális MID ráta (buy/sell közép)
        return exchangeRateRepository
            .findLatestMidRateByCurrencyCode(currency.getCode())
            .map(rate -> amount.multiply(rate).setScale(0, RoundingMode.HALF_UP))
            .orElseGet(() -> {
                log.warn("Nincs érvényes árfolyam: {} — HUF érték 0 marad", currency.getCode());
                return BigDecimal.ZERO;
            });
    } catch (Exception e) {
        log.warn("Árfolyam lekérdezési hiba: {} — HUF érték 0 marad. Hiba: {}", currency.getCode(), e.getMessage());
        return BigDecimal.ZERO;
    }
}
```

- [ ] Ellenőrizd a repository metódus nevét a tényleges `ExchangeRateRepository.java`-ban. Ha nem létezik `findLatestMidRateByCurrencyCode`, add hozzá a repository interfészhez:

```java
// ExchangeRateRepository.java-ban (ha szükséges)
@Query("SELECT (e.buyRate + e.sellRate) / 2 FROM ExchangeRate e " +
       "WHERE e.currencyCode = :code AND e.active = true " +
       "ORDER BY e.rateDate DESC, e.createdAt DESC LIMIT 1")
Optional<BigDecimal> findLatestMidRateByCurrencyCode(@Param("code") String currencyCode);
```

- [ ] Frissítsd mindhárom mozgás-létrehozó metódust (`requestBankWithdraw`, `depositToBank`, `transferBetweenBranches`):

```java
// Mindháromban cseréld ki:
.hufValue(BigDecimal.ZERO)
// erre:
.hufValue(calculateHufValue(currency, dto.getAmount()))
```

### 4.3 Teszt

```java
@Test
@DisplayName("depositToBank: hufValue az árfolyam alapján számítódik")
void depositToBank_hufValueCalculated() {
    setupCommonMocks();
    CashBalance balance = CashBalance.builder()
        .currentBalance(new BigDecimal("10000")).build();
    when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), any()))
        .thenReturn(Optional.of(balance));

    // EUR árfolyam: 395.00
    when(exchangeRateRepository.findLatestMidRateByCurrencyCode("EUR"))
        .thenReturn(Optional.of(new BigDecimal("395.00")));

    when(movementRepository.save(any())).thenAnswer(inv -> {
        InventoryMovement m = inv.getArgument(0);
        m.setId(1L);
        return m;
    });
    when(movementRepository.findMaxReferenceNumber(any())).thenReturn(0L);

    BankDepositRequestDto dto = BankDepositRequestDto.builder()
        .branchId(BRANCH_ID.toString())
        .currencyId(CURRENCY_ID)
        .amount(new BigDecimal("1000"))
        .build();

    InventoryMovementDto result = inventoryService.depositToBank(dto, WORKER_ID);

    // 1000 EUR × 395.00 = 395000 HUF
    assertThat(result.getHufValue()).isEqualByComparingTo(new BigDecimal("395000"));
}

@Test
@DisplayName("depositToBank: nincs árfolyam → hufValue = 0, nem dob hibát")
void depositToBank_noExchangeRate_hufValueZero() {
    setupCommonMocks();
    CashBalance balance = CashBalance.builder()
        .currentBalance(new BigDecimal("10000")).build();
    when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), any()))
        .thenReturn(Optional.of(balance));
    when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any()))
        .thenReturn(Optional.empty());
    when(movementRepository.save(any())).thenAnswer(inv -> {
        InventoryMovement m = inv.getArgument(0);
        m.setId(1L);
        return m;
    });
    when(movementRepository.findMaxReferenceNumber(any())).thenReturn(0L);

    BankDepositRequestDto dto = BankDepositRequestDto.builder()
        .branchId(BRANCH_ID.toString()).currencyId(CURRENCY_ID)
        .amount(new BigDecimal("1000")).build();

    InventoryMovementDto result = inventoryService.depositToBank(dto, WORKER_ID);

    assertThat(result.getHufValue()).isEqualByComparingTo(BigDecimal.ZERO);
}
```

---

## Segéd-metódusok a teszthez

```java
// InventoryServiceTest.java segédek
private void setupCommonMocks() {
    Branch branch   = Branch.builder().id(BRANCH_ID).name("Főiroda").build();
    Currency eur    = Currency.builder().id(CURRENCY_ID).code("EUR").name("Euro").build();
    Worker worker   = Worker.builder().id(WORKER_ID).name("Pénztáros").build();
    when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
    when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eur));
    when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
}
```

---

## Futtatandó parancsok

```bash
# Csak az inventory tesztek
cd backend && ./mvnw test -Dtest=InventoryServiceTest

# Kapcsolódó tesztek is fussanak
cd backend && ./mvnw test -Dtest=InventoryServiceTest,InventoryMovementServiceTest

# Teljes build ellenőrzés
cd backend && ./mvnw clean verify -DskipITs
```

---

## Commit üzenetek

```
fix(inventory): depositToBank creates PENDING movement for four-eye principle

fix(inventory): approve BANK_DEPOSIT decreases CashBalance

fix(inventory): check source branch stock before creating transfer

fix(inventory): mark getAllStock as @Transactional(readOnly=true)

feat(inventory): calculate hufValue from current exchange rate on movement creation

test(inventory): add InventoryServiceTest for all four fixes
```

---

## Migrációs megjegyzés

Nincs szükség Flyway migrációra — a `hufValue` oszlop már létezik az `inventory_movement` táblában, értéke eddig mindig 0 volt. A módosítás visszafele kompatibilis: a meglévő 0-ás rekordok megmaradnak, az újak helyes értéket kapnak.

> **Figyelem:** Az approveMovement() BANK_DEPOSIT CashBalance csökkentési logika bevezetése után a meglévő PENDING státuszú BANK_DEPOSIT mozgások automatikusan kétszer csökkentik az egyenleget, ha jóváhagyják őket. Éles bevezetés előtt ajánlott ezeket a régi PENDING mozgásokat manuálisan kezelni (pl. CANCELLED-re állítani és újra létrehozni).
