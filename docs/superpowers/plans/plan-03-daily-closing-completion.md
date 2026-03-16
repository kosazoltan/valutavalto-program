# Daily Closing Completion Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `DailyClosingService.executeClosing()` by adding four missing legacy steps from `NAPZAR.DLL`: (1) daily transaction archiving, (2) actual `DecadeReportService.generateDecadeReport()` call on decade days instead of only logging to AuditLog, (3) customer daily AML accumulator reset, (4) receipt number continuity check (gap detection).

**Architecture:**
- `DailyClosingService.executeClosing()` already calls `snapshotDailyRates`, `dailySessionService.closeSession`, `dailyBalanceService.calculateAllCurrenciesForDay`, `posTerminalService.dailyClose`, `eveningClosingService.prepareDailyPackage/sendToHeadquarters`, and `checkDecadeClosing`.
- `MonthlyArchiveService.archiveMonth(branchId, yearMonth)` exists — it archives a full month. We need `archiveDailyTransactions(branchId, date)` which marks the day's transactions as ARCHIVED in the main table (or copies to ArchivedTransaction). Looking at MonthlyArchiveService: it copies to `ArchivedTransaction` table. The daily archive should do the same for just one day.
- `DecadeReportService.generateDecadeReport(branchId, year, decade)` exists and is correct — it just needs to be called from `checkDecadeClosing()`.
- `AmlService` accumulates per-customer daily totals via `transactionRepository.findCustomerDailyTransactions`. There is no `resetDailyAccumulators()` — daily AML resets happen implicitly because queries filter by `LocalDate.now()`. However the `AmlAccumulatorCache` (if present) needs an explicit flush. We add a `resetDailyCache()` method to `AmlService`.
- `ReceiptSequenceService` generates receipt numbers. We add a gap check method `checkReceiptContinuity(branchId, date)` that queries the receipt numbers for the day and verifies no gaps.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Files

**Modify:**
- `backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyArchiveService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ReceiptSequenceService.java`

**Test (Create):**
- `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingExecuteClosingTest.java`

---

## Task 1 — Add daily transaction archiving

### 1a — Add archiveDailyTransactions to MonthlyArchiveService

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyArchiveService.java`.

Locate the existing `archiveMonth()` method (line ~55). Add a new method after it:

```java
    /**
     * Napi tranzakciók archiválása (napzárás részeként).
     *
     * Csak az aznap lezárt, COMPLETED státuszú tranzakciókat archiválja.
     * REVERSED tranzakciók szándékosan kimaradnak (azok a sztornó bizonylaton követhetők).
     *
     * Legacy: NAPZAR.DLL → CopyTables — a napi forgalom átmásolása a havi gyűjtőbe.
     *
     * @param branchId Az iroda azonosítója
     * @param date     A lezárandó nap
     * @return Archivált tranzakciók száma
     */
    @Transactional
    public int archiveDailyTransactions(UUID branchId, LocalDate date) {
        String archiveMonth = date.format(MONTH_FORMAT);
        log.info("Napi archiválás kezdése: branchId={}, datum={}", branchId, date);

        List<Transaction> toArchive = transactionRepository
            .findActiveByBranchAndDate(branchId, date)
            .stream()
            .filter(t -> t.getStatus() == TransactionStatus.COMPLETED)
            .collect(java.util.stream.Collectors.toList());

        if (toArchive.isEmpty()) {
            log.info("Nincs archiválandó tranzakció: branchId={}, datum={}", branchId, date);
            return 0;
        }

        int count = 0;
        for (Transaction tx : toArchive) {
            // Duplikáció ellenőrzés — ne archiváljuk kétszer ugyanazt a bizonylátot
            boolean exists = archivedTransactionRepository
                .existsByReceiptNumberAndArchiveMonth(tx.getReceiptNumber(), archiveMonth);
            if (exists) {
                log.debug("Már archivált bizonylat, skip: receipt={}", tx.getReceiptNumber());
                continue;
            }

            ArchivedTransaction archived = ArchivedTransaction.builder()
                .originalId(tx.getId())
                .branchId(branchId)
                .archiveMonth(archiveMonth)
                .receiptNumber(tx.getReceiptNumber())
                .transactionType(tx.getTransactionType() != null ? tx.getTransactionType().name() : null)
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : null)
                .currencyAmount(tx.getCurrencyAmount())
                .exchangeRate(tx.getExchangeRate())
                .hufAmount(tx.getHufAmount())
                .handlingFee(tx.getHandlingFee())
                .transactionDate(tx.getTransactionDate())
                .workerName(tx.getWorker() != null ? tx.getWorker().getName() : null)
                .customerName(tx.getCustomerName())
                .build();

            archivedTransactionRepository.save(archived);
            count++;
        }

        log.info("Napi archiválás kész: branchId={}, datum={}, archivált={}", branchId, date, count);
        return count;
    }
```

### 1b — Ensure ArchivedTransactionRepository has existsByReceiptNumberAndArchiveMonth

- [ ] Check `backend/src/main/java/hu/puzzleir/valuta/repository/ArchivedTransactionRepository.java`:

```bash
grep -n "existsByReceipt\|existsByOriginalId" \
  backend/src/main/java/hu/puzzleir/valuta/repository/ArchivedTransactionRepository.java
```

If the method does not exist, add:
```java
    boolean existsByReceiptNumberAndArchiveMonth(String receiptNumber, String archiveMonth);
```

### 1c — Call archiveDailyTransactions from executeClosing

- [ ] In `DailyClosingService`, inject `MonthlyArchiveService`:

```java
    private final MonthlyArchiveService monthlyArchiveService;
```

(Add to the `@RequiredArgsConstructor` field list.)

- [ ] In `executeClosing()`, after the `dailyBalanceService.calculateAllCurrenciesForDay()` block, add:

```java
        // 3b. Napi tranzakciók archiválása (legacy: CopyTables — NAPZAR.DLL)
        try {
            int archivedCount = monthlyArchiveService.archiveDailyTransactions(branchId, closingDate);
            log.info("Napi tranzakciók archivált: datum={}, iroda={}, db={}", closingDate, branchId, archivedCount);
        } catch (Exception e) {
            log.error("Napi archiválás hiba: datum={}, iroda={}, hiba={}",
                closingDate, branchId, e.getMessage(), e);
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }
```

---

## Task 2 — Make checkDecadeClosing call DecadeReportService.generateDecadeReport

- [ ] In `DailyClosingService`, inject `DecadeReportService`:

```java
    private final DecadeReportService decadeReportService;
```

- [ ] Replace `checkDecadeClosing()`:

```java
    /**
     * Dekád (10 napos időszak) zárás kontroll.
     * Legacy: DekzarCtrl — a 10., 20. és hónap utolsó napján dekád összesítés + riport.
     *
     * FIX: Korábban csak AuditLog bejegyzést írt. Most valóban meghívja a
     * DecadeReportService.generateDecadeReport() metódust.
     */
    private void checkDecadeClosing(UUID branchId, LocalDate date) {
        int dayOfMonth = date.getDayOfMonth();
        boolean isDecadeDay = (dayOfMonth == 10 || dayOfMonth == 20 || dayOfMonth == date.lengthOfMonth());

        if (!isDecadeDay) {
            return;
        }

        // Dekád időszak azonosítása (1-10 → dekád 1, 11-20 → dekád 2, 21-vége → dekád 3)
        int month  = date.getMonthValue();
        int year   = date.getYear();
        int decadeInMonth = (dayOfMonth <= 10) ? 1 : (dayOfMonth <= 20) ? 2 : 3;
        // Globális dekád szám: (hónap-1)*3 + dekád-a-hónapon-belül
        int decade = (month - 1) * 3 + decadeInMonth;

        String decadePeriod = (dayOfMonth == 10) ? "1-10"
                            : (dayOfMonth == 20) ? "11-20"
                            : "21-" + dayOfMonth;

        log.info("Dekád zárás indul: nap={}, idoszak={}, dekád={}. évszám={}",
            dayOfMonth, decadePeriod, decade, year);

        try {
            // Valódi dekádjelentés generálása (nem csak AuditLog!)
            hu.puzzleir.valuta.dto.decade.DecadeReportDto report =
                decadeReportService.generateDecadeReport(branchId, year, decade);

            log.info("Dekád riport generálva: branch={}, dekád={}/{}, profit={} HUF, kontroll={}",
                branchId, year, decade, report.getDecadeProfitHuf(), report.getForintControlValid());

            // AuditLog bejegyzés a sikerességről
            auditLogService.log(
                "DECADE_CLOSING",
                "DailyClosing",
                branchId.toString(),
                SecurityUtils.getCurrentWorkerId() != null
                    ? SecurityUtils.getCurrentWorkerId().toString() : null,
                null,
                branchId.toString(),
                null,
                String.format("{\"date\":\"%s\",\"decade\":%d,\"decadePeriod\":\"%s\",\"reportId\":\"%s\"}",
                    date, decade, decadePeriod, report.getId()),
                null,
                null
            );
        } catch (Exception e) {
            log.error("Dekád riport generálás hiba: branch={}, dekád={}/{}, hiba={}",
                branchId, year, decade, e.getMessage(), e);
            // NEM dobunk kivételt — ne akadjon meg a zárás
        }
    }
```

---

## Task 3 — Add AML daily accumulator reset

AML daily totals are computed on-the-fly from the database (no in-memory cache that persists between requests). However, if `AmlService` has an in-memory cache (e.g., `ConcurrentHashMap`) keyed by `customerId + date`, it needs clearing on day close.

- [ ] Check `AmlService` for in-memory caches:

```bash
grep -n "ConcurrentHashMap\|HashMap\|cache\|Cache\|Map<String" \
  backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java | head -20
```

- [ ] If a cache field exists (e.g., `private final Map<String, ...> dailyCache`), add a reset method to `AmlService.java`:

```java
    /**
     * Napi AML göngyölési cache törlése — napzárás részeként hívandó.
     * Legacy: CIML göngyölési számlálók nullázása napzáráskor.
     */
    public void resetDailyCache() {
        // Ha van in-memory cache, azt itt kell törölni.
        // Példa: dailyAccumulatorCache.clear();
        log.info("AML napi cache törölve (napzárás)");
    }
```

If no in-memory cache is found, still add the stub method with a comment explaining that DB-driven queries reset implicitly.

- [ ] In `DailyClosingService`, inject `AmlService`:

```java
    private final AmlService amlService;
```

- [ ] In `executeClosing()`, after the archiving step, add:

```java
        // 3c. Ügyfél napi AML göngyölési számlálók nullázása
        try {
            amlService.resetDailyCache();
            log.info("AML napi göngyölés nullázva: datum={}", closingDate);
        } catch (Exception e) {
            log.error("AML nullázás hiba: datum={}, hiba={}", closingDate, e.getMessage(), e);
        }
```

---

## Task 4 — Add receipt number continuity check

- [ ] Add a gap detection method to `ReceiptSequenceService`:

```java
    /**
     * Ellenőrzi, hogy az aznapi bizonylat sorszámokban nincs-e hiány.
     *
     * Algoritmus: lekéri az összes aznapi sorszámot, kivonja a sorszám numerikus
     * részét, rendezi és megkeresi az ugrásokat.
     *
     * @param branchId Az iroda azonosítója
     * @param date     Az ellenőrzendő nap
     * @return Hiányzó sorszámok listája (üres lista = nincs hiány)
     */
    @Transactional(readOnly = true)
    public List<String> checkReceiptContinuity(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository
            .findActiveByBranchAndDate(branchId, date);

        // Típusonként csoportosítva ellenőrzés (BUY, SELL külön szekvenciák)
        java.util.Map<String, java.util.TreeSet<Integer>> byPrefix = new java.util.HashMap<>();

        for (Transaction tx : transactions) {
            String receipt = tx.getReceiptNumber();
            if (receipt == null || receipt.length() < 2) continue;

            // Prefix: első karakter (V=vétel, E=eladás, K=konverzió, S=sztornó)
            String prefix = receipt.substring(0, 1);
            // Numerikus rész: utolsó 5 karakter
            if (receipt.length() < 6) continue;
            String numPart = receipt.substring(receipt.length() - 5);
            try {
                int num = Integer.parseInt(numPart);
                byPrefix.computeIfAbsent(prefix, k -> new java.util.TreeSet<>()).add(num);
            } catch (NumberFormatException e) {
                log.debug("Nem numerikus sorszám rész, skip: receipt={}", receipt);
            }
        }

        List<String> gaps = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, java.util.TreeSet<Integer>> entry : byPrefix.entrySet()) {
            String prefix = entry.getKey();
            java.util.TreeSet<Integer> nums = entry.getValue();
            if (nums.size() < 2) continue;

            int prev = nums.first();
            for (int num : nums.tailSet(prev + 1)) {
                if (num != prev + 1) {
                    for (int missing = prev + 1; missing < num; missing++) {
                        gaps.add(String.format("%s%05d (hiányzik)", prefix, missing));
                    }
                }
                prev = num;
            }
        }

        if (!gaps.isEmpty()) {
            log.warn("Bizonylat sorszám hiányok: datum={}, iroda={}, hiányok={}", date, branchId, gaps);
        }

        return gaps;
    }
```

> Note: `ReceiptSequenceService` does not currently have a `transactionRepository` dependency. Add it:
```java
    private final TransactionRepository transactionRepository;
```

- [ ] In `DailyClosingService`, inject `ReceiptSequenceService`:

```java
    private final ReceiptSequenceService receiptSequenceService;
```

- [ ] In `executeClosing()`, add the continuity check BEFORE the session close (so we can still query today's transactions):

```java
        // 0. Bizonylat sorszám folyamatosság ellenőrzése
        try {
            List<String> gaps = receiptSequenceService.checkReceiptContinuity(branchId, closingDate);
            if (!gaps.isEmpty()) {
                log.warn("FIGYELEM: Bizonylat sorszám hiányok (datum={}, iroda={}): {}",
                    closingDate, branchId, gaps);
                auditLogService.log(
                    "RECEIPT_GAP_WARNING", "DailyClosing", branchId.toString(),
                    SecurityUtils.getCurrentWorkerId() != null
                        ? SecurityUtils.getCurrentWorkerId().toString() : null,
                    null, branchId.toString(), null,
                    "{\"gaps\":" + gaps.size() + ",\"first\":\"" + gaps.get(0) + "\"}",
                    null, null
                );
                // NEM blokkolja a zárást — figyelmeztetés, nem hiba
            } else {
                log.info("Bizonylat sorszámok folyamatosak: datum={}, iroda={}", closingDate, branchId);
            }
        } catch (Exception e) {
            log.error("Bizonylat sorszám ellenőrzés hiba: {}", e.getMessage(), e);
        }
```

---

## Task 5 — Write failing then passing tests

- [ ] Create `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingExecuteClosingTest.java`:

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("DailyClosingService – executeClosing kiegészítések")
class DailyClosingExecuteClosingTest {

    @Mock TransactionRepository transactionRepository;
    @Mock ExchangeRateRepository exchangeRateRepository;
    @Mock CashBalanceRepository cashBalanceRepository;
    @Mock DenominationBalanceRepository denominationBalanceRepository;
    @Mock ClosingWizardRepository closingWizardRepository;
    @Mock CurrencyRepository currencyRepository;
    @Mock SystemParameterService systemParameterService;
    @Mock AuditLogService auditLogService;
    @Mock DailyBalanceService dailyBalanceService;
    @Mock PosTerminalService posTerminalService;
    @Mock PosTerminalRepository posTerminalRepository;
    @Mock EveningClosingService eveningClosingService;
    @Mock DailySessionService dailySessionService;
    @Mock MonthlyArchiveService monthlyArchiveService;
    @Mock DecadeReportService decadeReportService;
    @Mock AmlService amlService;
    @Mock ReceiptSequenceService receiptSequenceService;

    @InjectMocks
    DailyClosingService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("executeClosing – archiveDailyTransactions meghívódik")
    void executeClosing_archiveIsCalled() {
        LocalDate date = LocalDate.of(2026, 3, 16);
        stubMinimalExecuteClosing(date);

        when(monthlyArchiveService.archiveDailyTransactions(BRANCH_ID, date)).thenReturn(5);

        invokeExecuteClosingViaStartDailyClosing(date);

        verify(monthlyArchiveService, atLeastOnce()).archiveDailyTransactions(eq(BRANCH_ID), eq(date));
    }

    @Test
    @DisplayName("executeClosing – checkDecadeClosing meghívja generateDecadeReport a 10. napon")
    void executeClosing_decadeDay_generateDecadeReportCalled() {
        LocalDate decadeDay = LocalDate.of(2026, 3, 10); // 10. nap → dekád zárás
        stubMinimalExecuteClosing(decadeDay);

        hu.puzzleir.valuta.dto.decade.DecadeReportDto fakeReport =
            hu.puzzleir.valuta.dto.decade.DecadeReportDto.builder()
                .id(UUID.randomUUID())
                .year(2026).decade(7)
                .decadeProfitHuf(java.math.BigDecimal.ZERO)
                .forintControlValid(true)
                .build();
        when(decadeReportService.generateDecadeReport(eq(BRANCH_ID), eq(2026), eq(7)))
            .thenReturn(fakeReport);

        invokeExecuteClosingViaStartDailyClosing(decadeDay);

        // A 2026. március 10. = (3-1)*3 + 1 = dekád 7
        verify(decadeReportService, times(1)).generateDecadeReport(eq(BRANCH_ID), eq(2026), eq(7));
    }

    @Test
    @DisplayName("executeClosing – AML napi cache nullázódik")
    void executeClosing_amlDailyCacheReset() {
        LocalDate date = LocalDate.of(2026, 3, 16);
        stubMinimalExecuteClosing(date);

        invokeExecuteClosingViaStartDailyClosing(date);

        verify(amlService, atLeastOnce()).resetDailyCache();
    }

    @Test
    @DisplayName("executeClosing – bizonylat sorszám ellenőrzés meghívódik")
    void executeClosing_receiptContinuityChecked() {
        LocalDate date = LocalDate.of(2026, 3, 16);
        stubMinimalExecuteClosing(date);
        when(receiptSequenceService.checkReceiptContinuity(eq(BRANCH_ID), eq(date)))
            .thenReturn(List.of());

        invokeExecuteClosingViaStartDailyClosing(date);

        verify(receiptSequenceService, atLeastOnce()).checkReceiptContinuity(eq(BRANCH_ID), eq(date));
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private void stubMinimalExecuteClosing(LocalDate date) {
        when(dailySessionService.hasOpenSession()).thenReturn(true);

        ClosingWizard wizard = ClosingWizard.builder()
            .id(UUID.randomUUID()).wizardStatus(WizardStatus.IN_PROGRESS)
            .closingDate(date).totalSteps(9).build();
        when(closingWizardRepository.save(any())).thenReturn(wizard);

        // All 9 step checks → skip/pass
        when(transactionRepository.findByBranchIdAndTransactionDateAndMtcnIsNull(any(), any(), any()))
            .thenReturn(List.of());
        when(denominationBalanceRepository.existsByBranchIdAndDate(any(), any())).thenReturn(true);
        when(denominationBalanceRepository.sumDenominatedAmount(any(), any(), any()))
            .thenReturn(java.math.BigDecimal.ZERO);
        when(cashBalanceRepository.sumCurrentBalanceHuf(any()))
            .thenReturn(java.math.BigDecimal.ZERO);
        when(systemParameterService.getValue(anyString())).thenThrow(new RuntimeException("not found"));
        when(transactionRepository.countUnreportedTransactions(any(), any())).thenReturn(0L);

        // Exchange rate snapshot
        when(exchangeRateRepository.findActiveRatesByDate(any(), any())).thenReturn(List.of());

        // POS terminals
        when(posTerminalRepository.findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(any()))
            .thenReturn(List.of());

        // Evening closing
        hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage pkg =
            hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage.builder()
                .branchId(0L).date(date).build();
        when(eveningClosingService.prepareDailyPackage(any(UUID.class), eq(date))).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(any()))
            .thenReturn(hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult.success("checksum"));

        // archiving
        when(monthlyArchiveService.archiveDailyTransactions(any(), any())).thenReturn(0);

        // receipt continuity
        when(receiptSequenceService.checkReceiptContinuity(any(), any())).thenReturn(List.of());
    }

    private void invokeExecuteClosingViaStartDailyClosing(LocalDate date) {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

            service.startDailyClosing(date);
        }
    }
}
```

- [ ] Run failing tests (before implementation):
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=DailyClosingExecuteClosingTest \
  -Dmaven.test.skip=false 2>&1 | tail -30
```
Expected: compile errors or assertion failures.

- [ ] After all Tasks 1–4 are complete, run again:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=DailyClosingExecuteClosingTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `Tests run: 4, Failures: 0, Errors: 0`.

- [ ] Full suite:
```bash
cd backend && ./mvnw test 2>&1 | tail -20
```

---

## Commit

```bash
git add \
  backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java \
  backend/src/main/java/hu/puzzleir/valuta/service/MonthlyArchiveService.java \
  backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java \
  backend/src/main/java/hu/puzzleir/valuta/service/ReceiptSequenceService.java \
  backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingExecuteClosingTest.java

git commit -m "$(cat <<'EOF'
fix(closing): complete executeClosing with archiving, decade report, AML reset, receipt gap check

- archiveDailyTransactions() added to MonthlyArchiveService (legacy CopyTables)
- checkDecadeClosing() now calls DecadeReportService.generateDecadeReport() instead of only logging
- AmlService.resetDailyCache() added and called on day close
- ReceiptSequenceService.checkReceiptContinuity() added for gap detection
- TDD: DailyClosingExecuteClosingTest covers all 4 new steps

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
