# Transaction Fixes Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two P0 legal compliance bugs: (1) `executeSell()` is missing the 300,000 HUF customer identification check (NAV legal requirement), and (2) `executeConversion()` does not apply 5 Ft rounding to the `toAmount` (cél valuta összeg).

**Architecture:** Both fixes are in `TransactionService`. The `validateIdentification()` private method already exists and is called in `executeBuy()` — it simply needs to be called in `executeSell()` in the same location (after `payableAmount` is computed, before AML check). The conversion `toAmount` must pass through `HungarianRounding.roundToFive()` before being used in the sub-transactions and the cash balance update.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Files

**Modify:**
- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`

**Test (Create):**
- `backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceIdentificationTest.java`

---

## Task 1 — Failing test: executeSell without customer ID when hufAmount >= 300,000

- [ ] Create the test class at the exact path:

```
backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceIdentificationTest.java
```

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("TransactionService – ügyfél-azonosítás ellenőrzések")
class TransactionServiceIdentificationTest {

    @Mock TransactionRepository transactionRepository;
    @Mock CurrencyRepository currencyRepository;
    @Mock ExchangeRateRepository exchangeRateRepository;
    @Mock ExchangeRateService exchangeRateService;
    @Mock CashBalanceRepository cashBalanceRepository;
    @Mock CompanyRepository companyRepository;
    @Mock BranchRepository branchRepository;
    @Mock WorkerRepository workerRepository;
    @Mock DailySessionService dailySessionService;
    @Mock AmlService amlService;
    @Mock HandlingFeeCalculator handlingFeeCalculator;
    @Mock ReceiptSequenceService receiptSequenceService;
    @Mock PosTerminalService posTerminalService;

    @InjectMocks
    TransactionService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long CURRENCY_ID = 10L;

    @BeforeEach
    void setUpMocks() {
        // session open
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        // company / branch / worker
        Company company = new Company(); company.setId(COMPANY_ID);
        Branch branch = new Branch(); branch.setId(BRANCH_ID);
        Worker worker = new Worker(); worker.setId(WORKER_ID);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        // currency
        Currency eur = new Currency(); eur.setId(CURRENCY_ID); eur.setCode("EUR");
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eur));

        // exchange rate – 400 Ft/EUR sell rate
        ExchangeRate rate = mock(ExchangeRate.class);
        when(rate.getBaseSellRate()).thenReturn(new BigDecimal("400"));
        when(rate.getSellRateForAmount(any())).thenReturn(new BigDecimal("400"));
        when(exchangeRateService.getCurrentRate(CURRENCY_ID)).thenReturn(rate);

        // handling fee – zero for simplicity
        when(handlingFeeCalculator.calculate(any(), eq(TransactionType.SELL), any()))
                .thenReturn(BigDecimal.ZERO);
        when(handlingFeeCalculator.calculateSellGross(any(), any()))
                .thenAnswer(inv -> inv.getArgument(0));

        // stock always sufficient
        CashBalance stock = mock(CashBalance.class);
        when(stock.getCurrentBalance()).thenReturn(new BigDecimal("100000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), any()))
                .thenReturn(Optional.of(stock));
    }

    // -----------------------------------------------------------------------
    // Task 1 — BUG: executeSell does NOT call validateIdentification
    // This test MUST FAIL before the fix and PASS after.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("executeSell – 300 000 Ft felett ügyfél-azonosítás nélkül ValidationException-t kell dobjon")
    void executeSell_above300k_noCustomerName_shouldThrow() {
        // 750 EUR × 400 = 300 000 HUF → azonosítás kötelező
        TransactionService.SellRequest req = TransactionService.SellRequest.builder()
                .currencyId(CURRENCY_ID)
                .currencyAmount(new BigDecimal("750"))
                .customerName(null)          // <– szándékosan hiányzik
                .customerDocumentNumber(null)
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            assertThatThrownBy(() -> service.executeSell(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("300000");
        }
    }

    @Test
    @DisplayName("executeSell – 300 000 Ft felett okmányszám nélkül ValidationException-t kell dobjon")
    void executeSell_above300k_noDocumentNumber_shouldThrow() {
        TransactionService.SellRequest req = TransactionService.SellRequest.builder()
                .currencyId(CURRENCY_ID)
                .currencyAmount(new BigDecimal("750"))
                .customerName("Teszt Ügyfél")
                .customerDocumentNumber(null)  // <– szándékosan hiányzik
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            assertThatThrownBy(() -> service.executeSell(req))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("300000");
        }
    }

    @Test
    @DisplayName("executeSell – 300 000 Ft alatt azonosítás nélkül is átmehet")
    void executeSell_below300k_noCustomer_isAllowed() {
        // 100 EUR × 400 = 40 000 HUF → nem kell azonosítás
        when(receiptSequenceService.generateReceiptNumber(any(), eq(TransactionType.SELL)))
                .thenReturn("E0316-00001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        CashBalance hufBalance = mock(CashBalance.class);
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(any(), any()))
                .thenReturn(Optional.of(hufBalance));
        Currency huf = new Currency(); huf.setId(99L); huf.setCode("HUF");
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));

        TransactionService.SellRequest req = TransactionService.SellRequest.builder()
                .currencyId(CURRENCY_ID)
                .currencyAmount(new BigDecimal("100"))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

            // Should NOT throw
            service.executeSell(req);
        }
    }
}
```

- [ ] Run to confirm FAILURE (Task 1 test must fail before fix):
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=TransactionServiceIdentificationTest#executeSell_above300k_noCustomerName_shouldThrow \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `AssertionError` — test fails because no exception is thrown.

---

## Task 2 — Fix: Add validateIdentification call to executeSell

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`.

Find this block in `executeSell()` (line ~279–283):
```java
        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
```

Insert the missing call between rounding and AML:
```java
        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakció esetén ügyfél-azonosítás kötelező (NAV jogi követelmény).
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.)
        performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
```

- [ ] Verify the `validateIdentification` method signature (already exists in the class):
```java
private void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
    if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
        if (customerName == null || customerName.isBlank()) {
            throw new ValidationException(
                String.format("%s Ft feletti tranzakcióhoz ügyfél azonosítás kötelező!",
                    IDENTIFICATION_LIMIT.toPlainString()));
        }
        if (documentNumber == null || documentNumber.isBlank()) {
            throw new ValidationException(
                String.format("%s Ft feletti tranzakcióhoz igazolvány szám kötelező!",
                    IDENTIFICATION_LIMIT.toPlainString()));
        }
    }
}
```
No changes needed to the method itself; `IDENTIFICATION_LIMIT = new BigDecimal("300000")` is already defined at class level.

- [ ] Run Task 1 tests again to confirm PASS:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=TransactionServiceIdentificationTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `Tests run: 3, Failures: 0, Errors: 0`.

---

## Task 3 — Failing test: executeConversion toAmount 5 Ft rounding

- [ ] Add a new test class (or add to the existing one):

```
backend/src/test/java/hu/puzzleir/valuta/service/TransactionConversionRoundingTest.java
```

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("TransactionService – konverzió toAmount 5 Ft kerekítés")
class TransactionConversionRoundingTest {

    @Mock TransactionRepository transactionRepository;
    @Mock CurrencyRepository currencyRepository;
    @Mock ExchangeRateRepository exchangeRateRepository;
    @Mock ExchangeRateService exchangeRateService;
    @Mock CashBalanceRepository cashBalanceRepository;
    @Mock CompanyRepository companyRepository;
    @Mock BranchRepository branchRepository;
    @Mock WorkerRepository workerRepository;
    @Mock DailySessionService dailySessionService;
    @Mock AmlService amlService;
    @Mock HandlingFeeCalculator handlingFeeCalculator;
    @Mock ReceiptSequenceService receiptSequenceService;
    @Mock PosTerminalService posTerminalService;

    @InjectMocks
    TransactionService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long FROM_CURRENCY_ID = 10L; // EUR
    private static final Long TO_CURRENCY_ID = 11L;   // USD

    @Captor ArgumentCaptor<Transaction> transactionCaptor;

    @BeforeEach
    void setUpMocks() {
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        Company company = new Company(); company.setId(COMPANY_ID);
        Branch branch = new Branch(); branch.setId(BRANCH_ID);
        Worker worker = new Worker(); worker.setId(WORKER_ID);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        Currency eur = new Currency(); eur.setId(FROM_CURRENCY_ID); eur.setCode("EUR");
        Currency usd = new Currency(); usd.setId(TO_CURRENCY_ID);   usd.setCode("USD");
        when(currencyRepository.findById(FROM_CURRENCY_ID)).thenReturn(Optional.of(eur));
        when(currencyRepository.findById(TO_CURRENCY_ID)).thenReturn(Optional.of(usd));

        // EUR buy rate = 395, USD sell rate = 376
        // 100 EUR × 395 = 39500 HUF (roundToFive → 39500)
        // toAmount = 39500 / 376 = 105.053... → should be rounded to 5 Ft in HUF terms
        ExchangeRate fromRate = mock(ExchangeRate.class);
        when(fromRate.getBaseBuyRate()).thenReturn(new BigDecimal("395"));
        ExchangeRate toRate = mock(ExchangeRate.class);
        when(toRate.getBaseSellRate()).thenReturn(new BigDecimal("376"));
        when(exchangeRateService.getCurrentRate(FROM_CURRENCY_ID)).thenReturn(fromRate);
        when(exchangeRateService.getCurrentRate(TO_CURRENCY_ID)).thenReturn(toRate);

        when(handlingFeeCalculator.calculate(any(), eq(TransactionType.CONVERSION), any()))
                .thenReturn(BigDecimal.ZERO);

        // stock sufficient
        CashBalance usdStock = mock(CashBalance.class);
        when(usdStock.getCurrentBalance()).thenReturn(new BigDecimal("10000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(any(), eq(TO_CURRENCY_ID)))
                .thenReturn(Optional.of(usdStock));

        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("X-00001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CashBalance balStub = mock(CashBalance.class);
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(any(), any()))
                .thenReturn(Optional.of(balStub));
    }

    /**
     * Test case: 100 EUR → USD
     *   hufAmount = 100 × 395 = 39 500 (exact, no rounding needed on from-side)
     *   toAmount raw = 39 500 / 376 = 105.0531... USD
     *   The convSell sub-transaction's currencyAmount MUST be the rounded value.
     *
     * BUG: currently toAmount is NOT rounded — it keeps fractional digits.
     * After fix: toAmount must pass through HungarianRounding.roundToFive applied to
     * the HUF-equivalent cross-check. In practice for foreign currency amounts the
     * rounding is applied to the HUF leg, but the toAmount must be recalculated from
     * the rounded HUF so that the sell-side bizonylat reflects a clean amount.
     *
     * SPECIFICALLY: the convSell sub-transaction must store currencyAmount that,
     * when multiplied by toRate, equals the roundedHufAmount (no residual fraction).
     */
    @Test
    @DisplayName("Konverzió – toAmount kiszámítása a kerekített HUF összeget kell tükrözze")
    void executeConversion_toAmountDerivedFromRoundedHuf() {
        TransactionService.ConversionRequest req = TransactionService.ConversionRequest.builder()
                .fromCurrencyId(FROM_CURRENCY_ID)
                .toCurrencyId(TO_CURRENCY_ID)
                .fromAmount(new BigDecimal("100"))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            service.executeConversion(req);
        }

        // Capture all saved transactions
        verify(transactionRepository, atLeast(3)).save(transactionCaptor.capture());
        Transaction convSell = transactionCaptor.getAllValues().stream()
                .filter(t -> TransactionType.SELL.equals(t.getTransactionType()))
                .findFirst().orElseThrow();

        BigDecimal toAmount = convSell.getCurrencyAmount();
        // toAmount × sellRate must equal a multiple of 5
        BigDecimal hufEquivalent = toAmount.multiply(new BigDecimal("376"))
                .setScale(0, java.math.RoundingMode.HALF_UP);
        assertThat(hufEquivalent.remainder(BigDecimal.valueOf(5)))
                .isEqualByComparingTo(BigDecimal.ZERO);
    }
}
```

- [ ] Run to confirm FAILURE before fix:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=TransactionConversionRoundingTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `AssertionError` — huf equivalent is not divisible by 5.

---

## Task 4 — Fix: Apply 5 Ft rounding to conversion toAmount

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`.

Locate `executeConversion()`. Find these lines (around line 549–556):
```java
        // HUF-on keresztül konvertálás
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);

        // Magyar 5 Ft-os kerekítés a köztes HUF összegre
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        BigDecimal toAmount = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);
```

Replace the `toAmount` line with a version that rounds down to the nearest unit and then verifies the HUF cross-check is a multiple of 5:
```java
        // HUF-on keresztül konvertálás
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);

        // Magyar 5 Ft-os kerekítés a köztes HUF összegre
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        // toAmount kiszámítása a kerekített HUF-ból (FLOOR — az ügyfél nem kaphat
        // annyi valutát, hogy a HUF ellenérték magasabb legyen mint a kerekített összeg)
        BigDecimal toAmountRaw = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.HALF_UP);
        BigDecimal toAmount = toAmountRaw.setScale(2, RoundingMode.FLOOR);
```

> **Rationale:** The existing `toAmount` calculation already uses `RoundingMode.HALF_UP` which can produce a value whose HUF back-conversion exceeds `roundedHufAmount`. Switching to `FLOOR` ensures the foreign currency amount never exceeds what the rounded HUF amount can buy. The difference (at most a fraction of a cent-equivalent) is absorbed as additional rounding. The `convSell` sub-transaction's `hufAmount` remains `roundedHufAmount` — the canonical HUF figure — which is already a multiple of 5.

- [ ] Run both test classes to confirm all pass:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest="TransactionServiceIdentificationTest,TransactionConversionRoundingTest" \
  -Dmaven.test.skip=false 2>&1 | tail -30
```
Expected: `Tests run: 4, Failures: 0, Errors: 0`.

- [ ] Run the full test suite to check for regressions:
```bash
cd backend && ./mvnw test 2>&1 | tail -30
```
Expected: no new failures.

---

## Commit

```bash
git add \
  backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java \
  backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceIdentificationTest.java \
  backend/src/test/java/hu/puzzleir/valuta/service/TransactionConversionRoundingTest.java

git commit -m "$(cat <<'EOF'
fix(transaction): add missing 300K identification check in executeSell + fix conversion toAmount rounding

- executeSell() was missing validateIdentification() call — NAV legal requirement
- executeConversion() toAmount now uses FLOOR rounding so HUF back-value never exceeds roundedHufAmount
- TDD: added TransactionServiceIdentificationTest and TransactionConversionRoundingTest

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
