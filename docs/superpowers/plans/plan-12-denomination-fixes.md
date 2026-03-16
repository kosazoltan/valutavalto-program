# Denomination Fixes Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four bugs in `DenominationService`: (1) 100 Ft és 200 Ft érmék tévesen BANKNOTE-nak vannak kategorizálva, (2) nincs külföldi valuta címlet inicializálás, (3) negatív készletmennyiség lehetséges, (4) `calculateOptimalChange` adatbázis rendezési sorrendtől függ.

**Architecture:** Csak `DenominationService` módosítása szükséges — nincs sémaváltozás (a `DenominationType.COIN/BANKNOTE` enum és az entitás már létezik). Az idegen valuta inicializáló lista konstansként van definiálva a service-ben, a `initializeBranchDenominations()` metódust kiterjesztjük. A `calculateOptimalChange()` egy explicit Java-oldali rendezéssel védi magát a DB sorrendtől.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P2-MEDIUM
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/DenominationService.java` (fő módosítás)
  - `backend/src/test/java/hu/puzzleir/valuta/service/DenominationServiceTest.java` (ÚJ vagy bővítés)

---

## Task 1: HUF érmék/bankjegyek helyes kategorizálása

### 1.1 A bug leírása

A jelenlegi kód:
```java
DenominationType type = faceValue.compareTo(new BigDecimal("100")) >= 0
        ? DenominationType.BANKNOTE
        : DenominationType.COIN;
```

Ez azt okozza, hogy a **100 Ft** és **200 Ft érmék** `BANKNOTE`-ként lesznek nyilvántartva, holott fizikailag érmék.

**Magyar jogszabályi valóság (MNB 2019):**
- ÉRMÉK (COIN): 5, 10, 20, 50, 100, 200 Ft
- BANKJEGYEK (BANKNOTE): 500, 1000, 2000, 5000, 10000, 20000 Ft

A határvonal: **>= 500 Ft = BANKNOTE**, **< 500 Ft = COIN** (de a HUF esetén HUF-specifikus: >= 1000 Ft a bankjegy)

> **Pontosítás a feladat leírásból:** HUF: >= 1000 is BANKNOTE, < 1000 is COIN. Ez azt jelenti: 500 Ft = COIN.

### 1.2 TDD — Teszt előbb

- [ ] Hozd létre / nyisd meg: `backend/src/test/java/hu/puzzleir/valuta/service/DenominationServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class DenominationServiceTest {

    @Mock private DenominationRepository denominationRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;

    @InjectMocks private DenominationService denominationService;

    private static final UUID BRANCH_ID   = UUID.randomUUID();
    private static final UUID COMPANY_ID  = UUID.randomUUID();

    // ============ TASK 1: COIN/BANKNOTE KATEGORIZÁLÁS ============

    @Test
    @DisplayName("initializeBranchDenominations: 100 Ft → COIN (nem BANKNOTE)")
    void hufInit_100ft_isCoin() {
        setupSecurityContext(COMPANY_ID, BRANCH_ID);
        setupBranchAndCompany();
        Currency huf = buildCurrency("HUF", 1L);
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        denominationService.initializeBranchDenominations(BRANCH_ID);

        // Ellenőrzés: 100 Ft COIN
        ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
        verify(denominationRepository, atLeastOnce()).save(captor.capture());

        List<Denomination> saved = captor.getAllValues();
        Denomination d100 = saved.stream()
            .filter(d -> d.getFaceValue().compareTo(new BigDecimal("100")) == 0)
            .findFirst().orElseThrow();
        assertThat(d100.getDenominationType()).isEqualTo(DenominationType.COIN);
    }

    @Test
    @DisplayName("initializeBranchDenominations: 200 Ft → COIN")
    void hufInit_200ft_isCoin() {
        setupSecurityContext(COMPANY_ID, BRANCH_ID);
        setupBranchAndCompany();
        Currency huf = buildCurrency("HUF", 1L);
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        denominationService.initializeBranchDenominations(BRANCH_ID);

        ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
        verify(denominationRepository, atLeastOnce()).save(captor.capture());

        Denomination d200 = captor.getAllValues().stream()
            .filter(d -> d.getFaceValue().compareTo(new BigDecimal("200")) == 0)
            .findFirst().orElseThrow();
        assertThat(d200.getDenominationType()).isEqualTo(DenominationType.COIN);
    }

    @Test
    @DisplayName("initializeBranchDenominations: 500 Ft → COIN (< 1000)")
    void hufInit_500ft_isCoin() {
        setupSecurityContext(COMPANY_ID, BRANCH_ID);
        setupBranchAndCompany();
        Currency huf = buildCurrency("HUF", 1L);
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        denominationService.initializeBranchDenominations(BRANCH_ID);

        ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
        verify(denominationRepository, atLeastOnce()).save(captor.capture());

        Denomination d500 = captor.getAllValues().stream()
            .filter(d -> d.getFaceValue().compareTo(new BigDecimal("500")) == 0)
            .findFirst().orElseThrow();
        assertThat(d500.getDenominationType()).isEqualTo(DenominationType.COIN);
    }

    @Test
    @DisplayName("initializeBranchDenominations: 1000 Ft → BANKNOTE (>= 1000)")
    void hufInit_1000ft_isBanknote() {
        setupSecurityContext(COMPANY_ID, BRANCH_ID);
        setupBranchAndCompany();
        Currency huf = buildCurrency("HUF", 1L);
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
            .thenReturn(Optional.empty());
        when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        denominationService.initializeBranchDenominations(BRANCH_ID);

        ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
        verify(denominationRepository, atLeastOnce()).save(captor.capture());

        Denomination d1000 = captor.getAllValues().stream()
            .filter(d -> d.getFaceValue().compareTo(new BigDecimal("1000")) == 0)
            .findFirst().orElseThrow();
        assertThat(d1000.getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DenominationServiceTest` → PIROS

### 1.3 Fix implementálása

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/service/DenominationService.java`
- [ ] Cseréld ki a `initializeBranchDenominations()` metódusban a type-meghatározást:

```java
// RÉGI (hibás):
DenominationType type = faceValue.compareTo(new BigDecimal("100")) >= 0
        ? DenominationType.BANKNOTE
        : DenominationType.COIN;

// ÚJ (helyes — HUF: >= 1000 bankjegy, < 1000 érme):
DenominationType type = faceValue.compareTo(new BigDecimal("1000")) >= 0
        ? DenominationType.BANKNOTE
        : DenominationType.COIN;
```

- [ ] Adj hozzá egy privát helper metódust a jövőbeni valutafüggő logikához:

```java
/**
 * Meghatározza, hogy az adott névértékű HUF-ot hogyan kell kategorizálni.
 * HUF szabály (MNB 2019): >= 1000 Ft bankjegy, < 1000 Ft érme.
 */
private DenominationType classifyHufDenomination(BigDecimal faceValue) {
    return faceValue.compareTo(new BigDecimal("1000")) >= 0
            ? DenominationType.BANKNOTE
            : DenominationType.COIN;
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DenominationServiceTest#hufInit*` → ZÖLD

---

## Task 2: Külföldi valuta cím­let inicializálás

### 2.1 Konstansok definiálása

- [ ] Nyisd meg: `DenominationService.java`
- [ ] Add hozzá a meglévő `HUF_DENOMINATIONS` konstans mellé:

```java
/** EUR bankjegyek és érmék (2002 óta forgalomban). */
private static final BigDecimal[] EUR_BANKNOTES = {
    new BigDecimal("500"), new BigDecimal("200"), new BigDecimal("100"),
    new BigDecimal("50"),  new BigDecimal("20"),  new BigDecimal("10"),
    new BigDecimal("5")
};
private static final BigDecimal[] EUR_COINS = {
    new BigDecimal("2"), new BigDecimal("1"),
    new BigDecimal("0.50"), new BigDecimal("0.20"), new BigDecimal("0.10"),
    new BigDecimal("0.05")
};

/** USD bankjegyek és érmék. */
private static final BigDecimal[] USD_BANKNOTES = {
    new BigDecimal("100"), new BigDecimal("50"), new BigDecimal("20"),
    new BigDecimal("10"),  new BigDecimal("5"),  new BigDecimal("2"),
    new BigDecimal("1")
};
private static final BigDecimal[] USD_COINS = {
    new BigDecimal("0.50"), new BigDecimal("0.25"),
    new BigDecimal("0.10"), new BigDecimal("0.05"), new BigDecimal("0.01")
};

/** GBP bankjegyek és érmék. */
private static final BigDecimal[] GBP_BANKNOTES = {
    new BigDecimal("50"), new BigDecimal("20"), new BigDecimal("10"), new BigDecimal("5")
};
private static final BigDecimal[] GBP_COINS = {
    new BigDecimal("2"), new BigDecimal("1"),
    new BigDecimal("0.50"), new BigDecimal("0.20"), new BigDecimal("0.10"),
    new BigDecimal("0.05"), new BigDecimal("0.02"), new BigDecimal("0.01")
};

/** CHF bankjegyek és érmék. */
private static final BigDecimal[] CHF_BANKNOTES = {
    new BigDecimal("200"), new BigDecimal("100"), new BigDecimal("50"),
    new BigDecimal("20"), new BigDecimal("10")
};
private static final BigDecimal[] CHF_COINS = {
    new BigDecimal("5"), new BigDecimal("2"), new BigDecimal("1"),
    new BigDecimal("0.50"), new BigDecimal("0.20"), new BigDecimal("0.10"), new BigDecimal("0.05")
};

/** CZK bankjegyek és érmék. */
private static final BigDecimal[] CZK_BANKNOTES = {
    new BigDecimal("5000"), new BigDecimal("2000"), new BigDecimal("1000"),
    new BigDecimal("500"), new BigDecimal("200"), new BigDecimal("100")
};
private static final BigDecimal[] CZK_COINS = {
    new BigDecimal("50"), new BigDecimal("20"), new BigDecimal("10"),
    new BigDecimal("5"), new BigDecimal("2"), new BigDecimal("1")
};

/** Összes támogatott idegen valuta azonosítói. */
private static final Map<String, BigDecimal[][]> FOREIGN_DENOMINATIONS = Map.of(
    "EUR", new BigDecimal[][] { EUR_BANKNOTES, EUR_COINS },
    "USD", new BigDecimal[][] { USD_BANKNOTES, USD_COINS },
    "GBP", new BigDecimal[][] { GBP_BANKNOTES, GBP_COINS },
    "CHF", new BigDecimal[][] { CHF_BANKNOTES, CHF_COINS },
    "CZK", new BigDecimal[][] { CZK_BANKNOTES, CZK_COINS }
);
```

### 2.2 initializeBranchDenominations() bővítése

- [ ] Alakítsd át a metódust, hogy az aktívan konfigurált külföldi valutákhoz is inicializáljon:

```java
/**
 * Címletek inicializálása új irodához — HUF + aktív külföldi valuták.
 * Idempotens: meglévő rekordot nem ír felül.
 */
public void initializeBranchDenominations(UUID branchId) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();

    Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
    Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

    // 1. HUF inicializálás (javított kategorizálással)
    Currency huf = currencyRepository.findByCode("HUF")
            .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található"));

    for (BigDecimal faceValue : HUF_DENOMINATIONS) {
        if (denominationRepository
                .findByBranchIdAndCurrencyIdAndFaceValue(branchId, huf.getId(), faceValue)
                .isEmpty()) {
            denominationRepository.save(Denomination.builder()
                    .company(company).branch(branch).currency(huf)
                    .faceValue(faceValue)
                    .denominationType(classifyHufDenomination(faceValue))
                    .quantity(0).active(true).build());
        }
    }

    // 2. Külföldi valuták inicializálása (csak ha az adatbázisban szerepel az adott valuta)
    for (Map.Entry<String, BigDecimal[][]> entry : FOREIGN_DENOMINATIONS.entrySet()) {
        String currCode = entry.getKey();
        currencyRepository.findByCode(currCode).ifPresent(currency -> {
            BigDecimal[] banknotes = entry.getValue()[0];
            BigDecimal[] coins = entry.getValue()[1];

            for (BigDecimal fv : banknotes) {
                if (denominationRepository
                        .findByBranchIdAndCurrencyIdAndFaceValue(branchId, currency.getId(), fv)
                        .isEmpty()) {
                    denominationRepository.save(Denomination.builder()
                            .company(company).branch(branch).currency(currency)
                            .faceValue(fv).denominationType(DenominationType.BANKNOTE)
                            .quantity(0).active(true).build());
                }
            }

            for (BigDecimal fv : coins) {
                if (denominationRepository
                        .findByBranchIdAndCurrencyIdAndFaceValue(branchId, currency.getId(), fv)
                        .isEmpty()) {
                    denominationRepository.save(Denomination.builder()
                            .company(company).branch(branch).currency(currency)
                            .faceValue(fv).denominationType(DenominationType.COIN)
                            .quantity(0).active(true).build());
                }
            }

            log.info("Külföldi valuta cím­letek inicializálva: {} (iroda: {})", currCode, branch.getName());
        });
    }

    log.info("Összes cím­let inicializálva irodához: {}", branch.getName());
}
```

### 2.3 Tesztek

```java
@Test
@DisplayName("initializeBranchDenominations: EUR bankjegy 500 → BANKNOTE")
void foreignInit_eur500_isBanknote() {
    setupSecurityContext(COMPANY_ID, BRANCH_ID);
    setupBranchAndCompany();
    Currency huf = buildCurrency("HUF", 1L);
    Currency eur = buildCurrency("EUR", 2L);
    when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
    when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
    // Többi valuta nem elérhető
    when(currencyRepository.findByCode(argThat(c -> !c.equals("HUF") && !c.equals("EUR"))))
        .thenReturn(Optional.empty());
    when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
        .thenReturn(Optional.empty());
    when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    denominationService.initializeBranchDenominations(BRANCH_ID);

    ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
    verify(denominationRepository, atLeastOnce()).save(captor.capture());

    List<Denomination> eurDenoms = captor.getAllValues().stream()
        .filter(d -> d.getCurrency().getCode().equals("EUR"))
        .collect(Collectors.toList());

    assertThat(eurDenoms).isNotEmpty();

    Denomination eur500 = eurDenoms.stream()
        .filter(d -> d.getFaceValue().compareTo(new BigDecimal("500")) == 0)
        .findFirst().orElseThrow(() -> new AssertionError("EUR 500 not found"));
    assertThat(eur500.getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
}

@Test
@DisplayName("initializeBranchDenominations: EUR cent 0.50 → COIN")
void foreignInit_eurCent_isCoin() {
    setupSecurityContext(COMPANY_ID, BRANCH_ID);
    setupBranchAndCompany();
    Currency huf = buildCurrency("HUF", 1L);
    Currency eur = buildCurrency("EUR", 2L);
    when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
    when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eur));
    when(currencyRepository.findByCode(argThat(c -> !c.equals("HUF") && !c.equals("EUR"))))
        .thenReturn(Optional.empty());
    when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
        .thenReturn(Optional.empty());
    when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    denominationService.initializeBranchDenominations(BRANCH_ID);

    ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
    verify(denominationRepository, atLeastOnce()).save(captor.capture());

    Denomination eurHalf = captor.getAllValues().stream()
        .filter(d -> d.getCurrency().getCode().equals("EUR"))
        .filter(d -> d.getFaceValue().compareTo(new BigDecimal("0.50")) == 0)
        .findFirst().orElseThrow(() -> new AssertionError("EUR 0.50 not found"));
    assertThat(eurHalf.getDenominationType()).isEqualTo(DenominationType.COIN);
}

@Test
@DisplayName("initializeBranchDenominations: idempotens — meglévő rekord nem duplikálódik")
void foreignInit_idempotent() {
    setupSecurityContext(COMPANY_ID, BRANCH_ID);
    setupBranchAndCompany();
    Currency huf = buildCurrency("HUF", 1L);
    when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
    when(currencyRepository.findByCode(argThat(c -> !c.equals("HUF"))))
        .thenReturn(Optional.empty());
    // Minden már létezik
    when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
        .thenReturn(Optional.of(Denomination.builder().quantity(5).build()));

    denominationService.initializeBranchDenominations(BRANCH_ID);

    verify(denominationRepository, never()).save(any());
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DenominationServiceTest` → ZÖLD

---

## Task 3: Negatív készletmennyiség validálás

### 3.1 TDD

```java
@Test
@DisplayName("updateDenominationQuantity: negatív mennyiség → ValidationException")
void updateQuantity_negative_throws() {
    mockSecurityContext();
    DenominationService.UpdateDenominationRequest req = DenominationService.UpdateDenominationRequest.builder()
        .currencyId(1L)
        .faceValue(new BigDecimal("100"))
        .newQuantity(-1)
        .build();

    assertThatThrownBy(() -> denominationService.updateDenominationQuantity(req))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("negatív");
}

@Test
@DisplayName("updateDenominationQuantity: 0 mennyiség → engedélyezett (kassza kiürülhet)")
void updateQuantity_zero_allowed() {
    mockSecurityContext();
    Denomination existing = Denomination.builder()
        .quantity(5).currency(buildCurrency("HUF", 1L))
        .faceValue(new BigDecimal("100")).build();
    when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
        .thenReturn(Optional.of(existing));
    when(denominationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DenominationService.UpdateDenominationRequest req = DenominationService.UpdateDenominationRequest.builder()
        .currencyId(1L)
        .faceValue(new BigDecimal("100"))
        .newQuantity(0)
        .build();

    Denomination result = denominationService.updateDenominationQuantity(req);
    assertThat(result.getQuantity()).isEqualTo(0);
}
```

### 3.2 Fix

- [ ] Nyisd meg: `DenominationService.java` → `updateDenominationQuantity()`
- [ ] Add hozzá a validációt a mennyiség beállítása előtt:

```java
public Denomination updateDenominationQuantity(UpdateDenominationRequest request) {
    // ÚJ: negatív mennyiség ellenőrzés
    if (request.getNewQuantity() < 0) {
        throw new ValidationException(
            "Cím­let mennyiség nem lehet negatív! Megadott érték: " + request.getNewQuantity());
    }

    UUID branchId = SecurityUtils.getCurrentBranchId();
    Denomination denomination = denominationRepository
            .findByBranchIdAndCurrencyIdAndFaceValue(branchId, request.getCurrencyId(), request.getFaceValue())
            .orElseThrow(() -> new ResourceNotFoundException("Cím­let nem található"));

    int oldQuantity = denomination.getQuantity();
    denomination.setQuantity(request.getNewQuantity());
    Denomination saved = denominationRepository.save(denomination);

    log.info("Cím­let frissítve: {} {} - {} db -> {} db",
            denomination.getCurrency().getCode(), request.getFaceValue(),
            oldQuantity, request.getNewQuantity());

    return saved;
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DenominationServiceTest#updateQuantity*` → ZÖLD

---

## Task 4: calculateOptimalChange — explicit rendezés

### 4.1 A bug leírása

A jelenlegi kód:
```java
List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);
// Nagyobb cím­letektől kezdve
for (Denomination denom : denominations) { ... }
```

A lista sorrendje a `findByBranchAndCurrency` repository metódus implementációjától függ. Ha az adatbázis nem garantál rendezést (pl. `EXPLAIN ANALYZE` cache-miss után eltérő sorrend), a visszajáró számítás helytelen lehet: kis cím­leteket próbál előbb felhasználni.

### 4.2 TDD

```java
@Test
@DisplayName("calculateOptimalChange: DB sorrendtől függetlenül DESC faceValue sorrendben dolgoz")
void calculateOptimalChange_sortedDescByFaceValue() {
    UUID branchId = UUID.randomUUID();
    mockSecurityContextWithBranch(branchId);

    // Szándékosan rossz sorrendben adjuk vissza a DB-ből (ASC)
    List<Denomination> unordered = List.of(
        buildDenomination("HUF", new BigDecimal("1"),    10),
        buildDenomination("HUF", new BigDecimal("5"),    10),
        buildDenomination("HUF", new BigDecimal("10"),   10),
        buildDenomination("HUF", new BigDecimal("100"),  5),
        buildDenomination("HUF", new BigDecimal("1000"), 3)
    );
    when(denominationRepository.findByBranchAndCurrency(eq(branchId), eq(1L)))
        .thenReturn(unordered);

    Map<BigDecimal, Integer> change = denominationService.calculateOptimalChange(1L, new BigDecimal("2100"));

    // 2x 1000 Ft bankjegy + 1x 100 Ft — NEM 210x 10 Ft
    assertThat(change.get(new BigDecimal("1000"))).isEqualTo(2);
    assertThat(change.get(new BigDecimal("100"))).isEqualTo(1);
    assertThat(change.getOrDefault(new BigDecimal("10"), 0)).isEqualTo(0);
}

@Test
@DisplayName("calculateOptimalChange: 230 Ft visszajáró → 2x100 + 1x20 + 1x10")
void calculateOptimalChange_230_correctCombination() {
    UUID branchId = UUID.randomUUID();
    mockSecurityContextWithBranch(branchId);

    List<Denomination> denominations = List.of(
        buildDenomination("HUF", new BigDecimal("500"), 5),
        buildDenomination("HUF", new BigDecimal("100"), 5),
        buildDenomination("HUF", new BigDecimal("50"),  5),
        buildDenomination("HUF", new BigDecimal("20"),  5),
        buildDenomination("HUF", new BigDecimal("10"),  5)
    );
    when(denominationRepository.findByBranchAndCurrency(eq(branchId), eq(1L)))
        .thenReturn(denominations);

    Map<BigDecimal, Integer> change = denominationService.calculateOptimalChange(1L, new BigDecimal("230"));

    assertThat(change.get(new BigDecimal("100"))).isEqualTo(2);
    assertThat(change.get(new BigDecimal("20"))).isEqualTo(1);
    assertThat(change.get(new BigDecimal("10"))).isEqualTo(1);
    assertThat(change.getOrDefault(new BigDecimal("50"), 0)).isEqualTo(0);
}
```

### 4.3 Fix

- [ ] Nyisd meg: `DenominationService.java` → `calculateOptimalChange()`
- [ ] Add hozzá az explicit rendezést a lista elejére:

```java
@Transactional(readOnly = true)
public Map<BigDecimal, Integer> calculateOptimalChange(Long currencyId, BigDecimal amount) {
    UUID branchId = SecurityUtils.getCurrentBranchId();

    List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

    // ÚJ: Explicit DESC rendezés faceValue szerint — nem bízunk a DB sorrendben
    List<Denomination> sorted = denominations.stream()
            .sorted(Comparator.comparing(Denomination::getFaceValue).reversed())
            .collect(java.util.stream.Collectors.toList());

    Map<BigDecimal, Integer> result = new LinkedHashMap<>();
    BigDecimal remaining = amount;

    for (Denomination denom : sorted) {  // 'denominations' helyett 'sorted'
        if (denom.getQuantity() > 0 && remaining.compareTo(denom.getFaceValue()) >= 0) {
            int needed = remaining.divideToIntegralValue(denom.getFaceValue()).intValue();
            int available = Math.min(needed, denom.getQuantity());

            if (available > 0) {
                result.put(denom.getFaceValue(), available);
                remaining = remaining.subtract(denom.getFaceValue().multiply(BigDecimal.valueOf(available)));
            }
        }

        if (remaining.compareTo(BigDecimal.ZERO) == 0) {
            break;
        }
    }

    if (remaining.compareTo(BigDecimal.ZERO) > 0) {
        log.warn("Nem sikerült teljes visszajárót kiadni: {} maradék", remaining);
    }

    return result;
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DenominationServiceTest` → ZÖLD

---

## Segéd-metódusok a teszthez

```java
// DenominationServiceTest.java — helper metódusok
private void setupSecurityContext(UUID companyId, UUID branchId) {
    WorkerAuthenticationDetails details = mock(WorkerAuthenticationDetails.class);
    when(details.getCompanyId()).thenReturn(companyId);
    when(details.getBranchId()).thenReturn(branchId);
    TestingAuthenticationToken auth = new TestingAuthenticationToken("worker", null);
    auth.setDetails(details);
    SecurityContextHolder.getContext().setAuthentication(auth);
}

private void setupBranchAndCompany() {
    Company company = Company.builder().id(COMPANY_ID).build();
    Branch branch = Branch.builder().id(BRANCH_ID).name("Főiroda").build();
    when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
    when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
}

private Currency buildCurrency(String code, Long id) {
    return Currency.builder().id(id).code(code).name(code).build();
}

private Denomination buildDenomination(String currCode, BigDecimal faceValue, int qty) {
    return Denomination.builder()
        .currency(buildCurrency(currCode, 1L))
        .faceValue(faceValue)
        .quantity(qty)
        .denominationType(faceValue.compareTo(new BigDecimal("1000")) >= 0
            ? DenominationType.BANKNOTE : DenominationType.COIN)
        .build();
}
```

---

## Futtatandó parancsok

```bash
# Összes denomination teszt
cd backend && ./mvnw test -Dtest=DenominationServiceTest

# Denomination calculator is érintett lehet
cd backend && ./mvnw test -Dtest=DenominationCalculatorServiceTest

# Teljes build
cd backend && ./mvnw clean verify -DskipITs
```

---

## Commit üzenetek

```
fix(denomination): correct HUF coin/banknote threshold — >= 1000 Ft is BANKNOTE

feat(denomination): add foreign currency denomination initialization (EUR, USD, GBP, CHF, CZK)

fix(denomination): prevent negative quantity in updateDenominationQuantity

fix(denomination): sort denominations DESC by faceValue in calculateOptimalChange

test(denomination): add DenominationServiceTest for all four bug fixes
```
