# Decade Report Fixes Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four bugs in `DecadeReportService`: (1) `calculateForintControl()` does not include handling fee income in the forint control calculation, (2) `getUnitRate()` throws `ValidationException` instead of falling back to the most recent available MNB rate, (3) `printControlFlag` is never set (always remains `false`), (4) no daily closing completeness check before generating a decade report.

**Architecture:**
- `DecadeReportService.calculateForintControl()` accumulates `totalIncome` and `totalExpense` from transactions. Handling fees are income (the company receives them from customers). They are currently not added to `totalIncome`.
- `getUnitRate()` calls `mnbExchangeRateService.getRatesForDate(date)`. Looking at `MnbExchangeRateService.getRatesForDate()`: it already has a fallback (`findLatestRates`) that returns the most recent cached rates. BUT `getUnitRate()` throws before the fallback can take effect — it checks `rates.get(currency) == null` and throws. The fallback in `MnbExchangeRateService` is at the service level (if the map is empty, it falls back). If the map is non-empty but the specific currency is missing, `getUnitRate` throws. Fix: if currency is not in the map, call `mnbExchangeRateService.getRatesForDate()` with progressively earlier dates.
- `printControlFlag` should be `true` when `forintControlValid == true`. It is set on the entity but `calculateForintControl()` never calls `report.setPrintControlFlag(true/false)`.
- Daily closing completeness: before generating the decade report, verify that all days in the period have a closed `DailySession` or a `DailyBalance` entry. Use `DailySessionRepository` or `DailyBalanceRepository`.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Files

**Modify:**
- `backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java`

**Test (Create):**
- `backend/src/test/java/hu/puzzleir/valuta/service/DecadeReportServiceTest.java`

---

## Task 1 — Add handling fee income to forint control calculation

### Current state (in `calculateForintControl()`):

```java
for (Transaction tx : transactions) {
    BigDecimal huf = tx.getHufAmount();
    if (huf == null) continue;
    ...
    if (tx.getTransactionType().isSellType()) {
        totalIncome = totalIncome.add(huf);
    } else if (tx.getTransactionType().isBuyType()) {
        totalExpense = totalExpense.add(huf);
    } ...
}
```

Handling fees (`tx.getHandlingFee()`) are never added to income. In the legacy `DEKRUTIN.DLL` calculation:
- Vétel (BUY): ügyfél ad devizát → cég ad HUF-ot → HUF kiadás
  - DE: kezelési díj LEVONÓDIK a HUF-ból → a cég kevesebb HUF-ot ad → a kezelési díj csökkenti a kiadást VAGY bevételként jelenik meg
- Eladás (SELL): ügyfél ad HUF-ot → cég ad devizát → HUF bevétel
  - Kezelési díj a HUF-on felül → bevétel növelése
- A `hufAmount` már tartalmazza a kezelési díjat (lásd `TransactionService`: `grossAmount = handlingFeeCalculator.calculateSellGross(hufAmount, serverHandlingFee)` majd `payableAmount = roundToFive(grossAmount)`). Tehát a `hufAmount`-ban a kezelési díj már benne van.

**A valódi probléma:** A `hufAmount` mező az ügyfél által fizetett/kapott kerekített bruttó összeg (kezelési díjjal együtt). A forint kontroll szempontjából ez helyes — a kezelési díj nincs "duplikálva". AZONBAN a legacirendszer külön `KEZELESI_DIJ` sorként is rögzítette (mint kiegészítő bevételt), és a HUF kontrollba is beleértette. Ezt a hiányt ki kell javítani.

**Pontosabb fix:** Az `handlingFee` mező tartalmazza a kezelési díj összegét KÜLÖN is (a `hufAmount`-ban is benne van, de a `handlingFee` az elkülönített rész). A forint kontroll a BRUTTÓ `hufAmount`-ot használja — ami már tartalmazza a kezelési díjat. Tehát a helyes kezelés:

- Minden BUY tranzakciónál: `hufAmount` = amit a cég fizet az ügyfélnek (nettó - díj). A `handlingFee` a cégnek marad → ez BEVÉTEL a forint kontrollban, de az `hufAmount`-ban NEM szerepel (mert az a nettó kifizetés).
- Minden SELL tranzakciónál: `hufAmount` = amit az ügyfél fizet a cégnek (nettó + díj). A `handlingFee` benne van az `hufAmount`-ban.

A `handlingFeeCalculator.calculateBuyGross()` visszaadja: `hufAmount - handlingFee` (cég kevesebbet ad). Tehát a cégnek maradó `handlingFee` KÜLÖN BEVÉTELI SOR.

**Fix logika:**
```
BUY tranzakció:
  kiadás += hufAmount        (cég kifizeti az ügyfélnek)
  bevétel += handlingFee    (cégnek marad a díj — ez valójában az hufAmount-ban NEM szerepel)

SELL tranzakció:
  bevétel += hufAmount       (ügyfél befizeti, tartalmazza a díjat is)
  → handlingFee-t NEM kell külön hozzáadni, mert már benne van az hufAmount-ban
```

- [ ] In `DecadeReportService.calculateForintControl()`, after declaring `totalIncome` and `totalExpense`, update the loop:

```java
        for (Transaction tx : transactions) {
            BigDecimal huf = tx.getHufAmount();
            if (huf == null) continue;

            // Bizonylat sorszám tracking
            String receipt = tx.getReceiptNumber();
            if (receipt != null) {
                if (firstReceipt == null || receipt.compareTo(firstReceipt) < 0) firstReceipt = receipt;
                if (lastReceipt == null || receipt.compareTo(lastReceipt) > 0) lastReceipt = receipt;
            }

            // Bankkártyás elkülönítés
            if (tx.getPaymentMethod() == PaymentMethod.CARD) {
                cardTotal = cardTotal.add(huf);
            }

            // Bevétel/kiadás szétválasztás
            if (tx.getTransactionType().isSellType()) {
                // Eladás: HUF bejön az ügyféltől (kezelési díjjal együtt) → bevétel
                totalIncome = totalIncome.add(huf);
                // handlingFee az hufAmount-ban benne van → NEM adjuk hozzá külön
            } else if (tx.getTransactionType().isBuyType()) {
                // Vétel: HUF kimegy az ügyfélnek → kiadás
                totalExpense = totalExpense.add(huf);
                // Kezelési díj (a cégnek marad, az hufAmount-ban NEM szerepel) → bevétel
                BigDecimal fee = tx.getHandlingFee();
                if (fee != null && fee.compareTo(BigDecimal.ZERO) > 0) {
                    totalIncome = totalIncome.add(fee);
                }
            } else if (tx.getTransactionType() == TransactionType.TRANSFER_IN) {
                totalIncome = totalIncome.add(huf);
            } else if (tx.getTransactionType() == TransactionType.TRANSFER_OUT) {
                totalExpense = totalExpense.add(huf);
            }
        }
```

---

## Task 2 — MNB rate fallback (find most recent rate if exact date missing)

### Current broken code:
```java
private BigDecimal getUnitRate(Map<String, MnbExchangeRateCache> rates, String currency) {
    MnbExchangeRateCache rate = rates.get(currency);
    if (rate == null) {
        throw new ValidationException(
            "Hiányzó MNB árfolyam a dekádjelentés generálásához: " + currency + ...);
    }
    return rate.getRatePerUnit();
}
```

### Fix: inject `MnbExchangeRateService` and retry with earlier dates:

`DecadeReportService` already has `mnbExchangeRateService` injected. `MnbExchangeRateService.getRatesForDate()` already has a fallback to `findLatestRates()` if the map for the date is empty. HOWEVER, if the date-specific map is non-empty but the specific currency is absent, the service returns the date-specific map without the currency, and `getUnitRate` throws.

- [ ] Change the signature of `getUnitRate` to accept the date and retry:

```java
    /**
     * MNB árfolyam kinyerése 1 egységre vetítve.
     *
     * FIX: Ha az adott napra nincs árfolyam az adott valutához, visszamegy legfeljebb
     * 7 naptári napot (hétvége, ünnepnap miatti hiány kezelése).
     * Ha 7 napon belül sem találja → ValidationException.
     */
    private BigDecimal getUnitRate(Map<String, MnbExchangeRateCache> rates,
                                    String currency, LocalDate rateDate) {
        MnbExchangeRateCache rate = rates.get(currency);
        if (rate != null) {
            return rate.getRatePerUnit();
        }

        // Fallback: keresés az előző 7 napban
        log.warn("MNB árfolyam hiányzik {} valutához {}-n — fallback próba",
            currency, rateDate);

        for (int daysBack = 1; daysBack <= 7; daysBack++) {
            LocalDate fallbackDate = rateDate.minusDays(daysBack);
            Map<String, MnbExchangeRateCache> fallbackRates =
                mnbExchangeRateService.getRatesForDate(fallbackDate);
            MnbExchangeRateCache fallbackRate = fallbackRates.get(currency);
            if (fallbackRate != null) {
                log.info("MNB fallback árfolyam használva: {} valuta, {} nap helyett {}",
                    currency, rateDate, fallbackDate);
                return fallbackRate.getRatePerUnit();
            }
        }

        throw new ValidationException(
            "Hiányzó MNB árfolyam a dekádjelentés generálásához: " + currency +
            " (utolsó 7 nap sem tartalmaz adatot). " +
            "Ellenőrizze, hogy az MNB árfolyamok be vannak-e töltve az adott időszakra!");
    }
```

- [ ] Update all callers of `getUnitRate` in `calculateDecadeProfit()`:

```java
        // MNB árfolyamok a dekád első és utolsó napjára
        Map<String, MnbExchangeRateCache> openingRates =
            mnbExchangeRateService.getRatesForDate(periodStart);
        Map<String, MnbExchangeRateCache> closingRates =
            mnbExchangeRateService.getRatesForDate(periodEnd);

        ...

        for (String currency : allCurrencies) {
            BigDecimal openingBal = openingMap.getOrDefault(currency, BigDecimal.ZERO);
            BigDecimal closingBal = closingMap.getOrDefault(currency, BigDecimal.ZERO);

            // Updated calls — pass the date for fallback logic
            BigDecimal openingRate = getUnitRate(openingRates, currency, periodStart);
            BigDecimal closingRate = getUnitRate(closingRates, currency, periodEnd);
            ...
        }
```

---

## Task 3 — Set printControlFlag based on forint control validation result

`DecadeReport.printControlFlag` is declared on the entity (line 128: `private Boolean printControlFlag = false`) but is never set to `true` after a successful validation.

- [ ] At the end of `calculateForintControl()`, add:

```java
        report.setForintOpening(forintOpening);
        report.setForintTotalIncome(totalIncome);
        report.setForintTotalExpense(totalExpense);
        report.setForintClosing(forintClosing);
        report.setForintControlValid(valid);
        report.setForintControlDiff(diff);
        report.setFirstReceiptNumber(firstReceipt);
        report.setLastReceiptNumber(lastReceipt);
        report.setCardPaymentTotal(cardTotal);

        // printControlFlag: true ha a forint kontroll egyezik (nyomtatásra kész)
        // Legacy: DEKRUTIN.DLL → nyomtatható jelzés (NyomtCtrl)
        report.setPrintControlFlag(valid);

        if (!valid) {
            log.warn("FORINT KONTROLL ELTÉRÉS! branch={}, dekád={}/{}, diff={} — printControlFlag=false",
                branchId, report.getYear(), report.getDecade(), diff);
        } else {
            log.info("Forint kontroll OK: branch={}, dekád={}/{} — printControlFlag=true",
                branchId, report.getYear(), report.getDecade());
        }
```

---

## Task 4 — Add daily closing completeness validation

Before generating the decade report, verify that every business day in the period has a closed daily session. Days without a `DailyBalance` entry indicate the day was never properly closed.

- [ ] Check `DailyBalanceRepository` for a method that lists all dates for a branch in a range:

```bash
grep -n "findByBranchIdAnd\|findAll\|LocalDate" \
  backend/src/main/java/hu/puzzleir/valuta/repository/DailyBalanceRepository.java | head -20
```

- [ ] If needed, add to `DailyBalanceRepository`:

```java
    /**
     * Lezárt napok listája egy időszakban.
     * Minden naphoz legalább egy DailyBalance rekord szükséges.
     */
    @Query("SELECT DISTINCT db.balanceDate FROM DailyBalance db " +
           "WHERE db.branch.id = :branchId " +
           "AND db.balanceDate BETWEEN :from AND :to " +
           "ORDER BY db.balanceDate")
    List<LocalDate> findClosedDates(
        @Param("branchId") UUID branchId,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to
    );
```

- [ ] Add a `validateDailyClosingCompleteness()` private method to `DecadeReportService`:

```java
    /**
     * Ellenőrzi, hogy az adott dekád időszakban minden munkanap le van-e zárva.
     *
     * FIX: Korábban a dekádjelentés lezáratlan napokkal is generálható volt —
     * ez hibás adatokat eredményezhetett.
     *
     * Logika: megkeresi a hiányzó DailyBalance rekordokat. Hétvégék és ünnepnapok
     * kizárva (nincs forgalom ezeken a napokon → DailyBalance nélkülük is OK).
     *
     * @throws ValidationException ha van lezáratlan nap a dekádban
     */
    private void validateDailyClosingCompleteness(UUID branchId,
                                                   LocalDate periodStart,
                                                   LocalDate periodEnd) {
        List<LocalDate> closedDates = dailyBalanceRepository
            .findClosedDates(branchId, periodStart, periodEnd);

        // Elvárt napok: a teljes dekád (hétvégéket NEM zárjuk ki — ha a pénzváltó nyitva volt,
        // DailyBalance kellett volna; ha zárva volt, nem kell).
        // Kompromisszum: csak figyelmeztetünk, nem blokkolunk.
        long expectedDays = periodStart.datesUntil(periodEnd.plusDays(1)).count();
        long closedDays   = closedDates.size();

        if (closedDays == 0 && expectedDays > 0) {
            log.warn("Dekád időszakban nincs lezárt nap! branch={}, időszak={} – {}",
                branchId, periodStart, periodEnd);
            // Figyelmeztetés, de nem hiba — lehet hogy az iroda zárva volt az egész dekád alatt
        } else if (closedDays < expectedDays) {
            log.info("Dekád időszakban {} / {} nap lezárva: branch={}, időszak={} – {}",
                closedDays, expectedDays, branchId, periodStart, periodEnd);
        } else {
            log.debug("Dekád időszak összes napja lezárva: branch={}, {} nap", branchId, closedDays);
        }

        // STRICTABB ELLENŐRZÉS: Ha a LEGUTOLSÓ NAP nem zárva, a riport nem generálható.
        // (A dekád utolsó napjának le kell lennie zárva, hogy a záró keszlet helyes legyen.)
        if (!closedDates.contains(periodEnd)) {
            throw new ValidationException(
                String.format("A dekád utolsó napja (%s) nincs lezárva! " +
                    "A napi zárás elvégzése szükséges a dekádjelentés generálásához.", periodEnd));
        }
    }
```

- [ ] Call this method at the beginning of `generateDecadeReport()`, after the period calculation and before the DB queries:

```java
        // Napi zárás teljességének ellenőrzése
        validateDailyClosingCompleteness(branchId, periodStart, periodEnd);
```

- [ ] Ensure `DailyBalanceRepository` is injected (it already is: `private final DailyBalanceRepository dailyBalanceRepository;`).

---

## Task 5 — Write failing then passing tests

- [ ] Create `backend/src/test/java/hu/puzzleir/valuta/service/DecadeReportServiceTest.java`:

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("DecadeReportService – forint kontroll + MNB fallback + printControlFlag + completeness")
class DecadeReportServiceTest {

    @Mock DecadeReportRepository decadeReportRepository;
    @Mock TransactionRepository transactionRepository;
    @Mock BranchRepository branchRepository;
    @Mock DailyBalanceRepository dailyBalanceRepository;
    @Mock MnbExchangeRateService mnbExchangeRateService;

    @InjectMocks
    DecadeReportService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private Branch stubBranch() {
        Company company = new Company(); company.setId(COMPANY_ID);
        Branch branch = new Branch(); branch.setId(BRANCH_ID); branch.setCompany(company);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        return branch;
    }

    private void stubDecadeClosedPeriod(LocalDate start, LocalDate end) {
        // Last day is "closed" (has a DailyBalance)
        when(dailyBalanceRepository.findClosedDates(eq(BRANCH_ID), eq(start), eq(end)))
            .thenReturn(List.of(end));
    }

    private Transaction buyTx(BigDecimal huf, BigDecimal fee) {
        Transaction tx = mock(Transaction.class);
        when(tx.getHufAmount()).thenReturn(huf);
        when(tx.getHandlingFee()).thenReturn(fee);
        when(tx.getTransactionType()).thenReturn(TransactionType.BUY);
        when(tx.getPaymentMethod()).thenReturn(PaymentMethod.CASH);
        return tx;
    }

    private Transaction sellTx(BigDecimal huf) {
        Transaction tx = mock(Transaction.class);
        when(tx.getHufAmount()).thenReturn(huf);
        when(tx.getHandlingFee()).thenReturn(BigDecimal.ZERO);
        when(tx.getTransactionType()).thenReturn(TransactionType.SELL);
        when(tx.getPaymentMethod()).thenReturn(PaymentMethod.CASH);
        return tx;
    }

    // -----------------------------------------------------------------------
    // Task 1 – Handling fee included in forint control income
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("calculateForintControl – BUY kezelési díj bevételbe kerül")
    void forintControl_buyHandlingFeeIsIncome() {
        stubBranch();
        // Dekád 1 (január 1-10, 2026)
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end   = LocalDate.of(2026, 1, 10);
        stubDecadeClosedPeriod(start, end);

        // Nyitó HUF: 100 000
        DailyBalance openHuf = mock(DailyBalance.class);
        when(openHuf.getCurrencyCode()).thenReturn("HUF");
        when(openHuf.getOpeningBalance()).thenReturn(new BigDecimal("100000"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, start))
            .thenReturn(List.of(openHuf));

        // Záró HUF: 110 000 (100 000 nyitó + 20 000 eladás bevétel - 15 000 vétel kiadás + 5 000 díj)
        DailyBalance closeHuf = mock(DailyBalance.class);
        when(closeHuf.getCurrencyCode()).thenReturn("HUF");
        when(closeHuf.getClosingBalance()).thenReturn(new BigDecimal("110000"));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, end))
            .thenReturn(List.of(closeHuf));

        // Tranzakciók: 1 SELL 20 000 HUF, 1 BUY 15 000 HUF + 5 000 kezelési díj
        Transaction sell = sellTx(new BigDecimal("20000"));
        Transaction buy  = buyTx(new BigDecimal("15000"), new BigDecimal("5000"));
        when(transactionRepository.findActiveByBranchAndDateRange(BRANCH_ID, start, end))
            .thenReturn(List.of(sell, buy));

        // MNB árfolyamok (üres — nincs idegen valuta)
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(any(), anyInt(), anyInt()))
            .thenReturn(Optional.empty());
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), eq("BUY"), any(), any()))
            .thenReturn(new BigDecimal("15000"));
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), eq("SELL"), any(), any()))
            .thenReturn(new BigDecimal("20000"));
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any()))
            .thenReturn(new BigDecimal("5000"));
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any())).thenReturn(2L);
        when(decadeReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            DecadeReportDto dto = service.generateDecadeReport(BRANCH_ID, 2026, 1);

            // nyitó + bevétel - kiadás = záró
            // 100 000 + (20 000 + 5 000) - 15 000 = 110 000 → kontroll OK
            assertThat(dto.getForintControlValid())
                .as("Forint kontroll valid kell legyen ha kezelési díj bevételbe kerül")
                .isTrue();
            assertThat(dto.getForintControlDiff())
                .isEqualByComparingTo(BigDecimal.ZERO);
        }
    }

    // -----------------------------------------------------------------------
    // Task 2 – MNB rate fallback
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("getUnitRate – ha az adott napra nincs árfolyam, az előző napot használja (fallback)")
    void getUnitRate_fallbackToPreviousDay() {
        stubBranch();
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end   = LocalDate.of(2026, 1, 10);
        stubDecadeClosedPeriod(start, end);

        // Nyitó/záró HUF egyenlegek
        DailyBalance openHuf = mock(DailyBalance.class);
        when(openHuf.getCurrencyCode()).thenReturn("HUF");
        when(openHuf.getOpeningBalance()).thenReturn(BigDecimal.ZERO);
        DailyBalance closeHuf = mock(DailyBalance.class);
        when(closeHuf.getCurrencyCode()).thenReturn("HUF");
        when(closeHuf.getClosingBalance()).thenReturn(BigDecimal.ZERO);

        // EUR nyitó és záró egyenlegek
        DailyBalance openEur = mock(DailyBalance.class);
        when(openEur.getCurrencyCode()).thenReturn("EUR");
        when(openEur.getOpeningBalance()).thenReturn(new BigDecimal("1000"));
        DailyBalance closeEur = mock(DailyBalance.class);
        when(closeEur.getCurrencyCode()).thenReturn("EUR");
        when(closeEur.getClosingBalance()).thenReturn(new BigDecimal("900"));

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, start))
            .thenReturn(List.of(openHuf, openEur));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(BRANCH_ID, end))
            .thenReturn(List.of(closeHuf, closeEur));

        // MNB: start napra nincs EUR árfolyam, end napra van
        MnbExchangeRateCache eurRate = mock(MnbExchangeRateCache.class);
        when(eurRate.getRatePerUnit()).thenReturn(new BigDecimal("395"));

        // start-ra üres, de start-1 napra van
        when(mnbExchangeRateService.getRatesForDate(eq(start))).thenReturn(Map.of());
        when(mnbExchangeRateService.getRatesForDate(eq(start.minusDays(1))))
            .thenReturn(Map.of("EUR", eurRate));
        when(mnbExchangeRateService.getRatesForDate(eq(end)))
            .thenReturn(Map.of("EUR", eurRate));

        when(transactionRepository.findActiveByBranchAndDateRange(BRANCH_ID, start, end))
            .thenReturn(List.of());
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(any(), anyInt(), anyInt()))
            .thenReturn(Optional.empty());
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any())).thenReturn(0L);
        when(decadeReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Should NOT throw ValidationException — fallback to start-1 day
            assertThatCode(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                .doesNotThrowAnyException();
        }
    }

    // -----------------------------------------------------------------------
    // Task 3 – printControlFlag set based on validation
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("generateDecadeReport – printControlFlag=true ha forint kontroll OK")
    void generateDecadeReport_printControlFlagSetWhenValid() {
        stubBranch();
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end   = LocalDate.of(2026, 1, 10);
        stubDecadeClosedPeriod(start, end);

        // Balanced forint control (zero transactions, zero balances)
        DailyBalance zeroBalance = mock(DailyBalance.class);
        when(zeroBalance.getCurrencyCode()).thenReturn("HUF");
        when(zeroBalance.getOpeningBalance()).thenReturn(BigDecimal.ZERO);
        when(zeroBalance.getClosingBalance()).thenReturn(BigDecimal.ZERO);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(any(), any()))
            .thenReturn(List.of(zeroBalance));

        when(transactionRepository.findActiveByBranchAndDateRange(BRANCH_ID, start, end))
            .thenReturn(List.of());
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(any(), anyInt(), anyInt()))
            .thenReturn(Optional.empty());
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(any(), any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumFeeByBranchAndPeriod(any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countByBranchAndPeriod(any(), any(), any())).thenReturn(0L);

        ArgumentCaptor<DecadeReport> captor = ArgumentCaptor.forClass(DecadeReport.class);
        when(decadeReportRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.generateDecadeReport(BRANCH_ID, 2026, 1);
        }

        DecadeReport saved = captor.getValue();
        assertThat(saved.getPrintControlFlag())
            .as("printControlFlag=true ha forint kontroll egyezik")
            .isTrue();
    }

    // -----------------------------------------------------------------------
    // Task 4 – Daily closing completeness check
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("generateDecadeReport – ValidationException ha a dekád utolsó napja nincs lezárva")
    void generateDecadeReport_throwsIfLastDayNotClosed() {
        stubBranch();
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end   = LocalDate.of(2026, 1, 10);

        // Last day (jan 10) is NOT in closed dates
        when(dailyBalanceRepository.findClosedDates(eq(BRANCH_ID), eq(start), eq(end)))
            .thenReturn(List.of(LocalDate.of(2026, 1, 8), LocalDate.of(2026, 1, 9)));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("2026-01-10");
        }
    }
}
```

- [ ] Run failing (before fixes):
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=DecadeReportServiceTest \
  -Dmaven.test.skip=false 2>&1 | tail -30
```

- [ ] After all Tasks 1–4 are complete, run again:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=DecadeReportServiceTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `Tests run: 4, Failures: 0, Errors: 0`.

- [ ] Full regression:
```bash
cd backend && ./mvnw test 2>&1 | tail -20
```

---

## Commit

```bash
git add \
  backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java \
  backend/src/main/java/hu/puzzleir/valuta/repository/DailyBalanceRepository.java \
  backend/src/test/java/hu/puzzleir/valuta/service/DecadeReportServiceTest.java

git commit -m "$(cat <<'EOF'
fix(decade-report): 4 bugs fixed — fee income, MNB fallback, printControlFlag, closing completeness

- calculateForintControl: BUY handling fees now added to totalIncome (were missing)
- getUnitRate: fallback to most recent MNB rate (up to 7 days back) instead of throwing
- printControlFlag set to forintControlValid result after calculateForintControl
- validateDailyClosingCompleteness: throws if last day of decade is not closed
- DailyBalanceRepository.findClosedDates() JPQL query added
- TDD: DecadeReportServiceTest with 4 test cases

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
