package hu.puzzleir.valuta.service;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.ArchivedMonthlyTransaction;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.ArchivedMonthlyTransactionRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.MonthlyClosingSummaryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.Branch;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;

/**
 * Havi zárás szolgáltatás.
 *
 * Legacy: NAPZAR.DLL HaviGyujtokbeMasolas
 * — CopyTables() generikus: mezőnév+típus alapján másolja a rekordokat
 * — Havi tábla neve: prefix + ÉÉVHH (pl. BF2603)
 *
 * Modern: MonthlyClosingSummary entity-be összesít, JSON currency
 * breakdown-nal + archivált tranzakciók táblája.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MonthlyClosingService {

    private final TransactionRepository transactionRepository;
    private final MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    private final BranchRepository branchRepository;
    private final MonthlyClosingAccessGuard monthlyClosingAccessGuard;
    private final WorkerRepository workerRepository;
    private final ObjectMapper objectMapper;
    private final MnbExchangeRateService mnbExchangeRateService;
    private final CurrencyStockRepository currencyStockRepository;
    private final DailySessionRepository dailySessionRepository;
    private final ArchivedMonthlyTransactionRepository archivedMonthlyTransactionRepository;

    /**
     * Havi zárás végrehajtása.
     *
     * Az adott hónap összes tranzakcióját összesíti valutanemenként:
     * össz vétel, össz eladás, össz kezelési díj, tranzakciószám.
     *
     * @param branchId  iroda azonosító
     * @param yearMonth év-hónap (pl. "2026-03")
     * @return MonthlyClosingSummary entity
     */
    @Transactional(rollbackFor = Exception.class)
    public MonthlyClosingSummary performMonthlyClosing(UUID branchId, String yearMonth) {
        // Validáció — HIGH FIX #5: Cheap validáció előbb, expensive DB query később
        YearMonth ym = parseYearMonth(yearMonth);

        // 1. Jövőbeli hónap ellenőrzés (cheap — nincs DB hívás)
        if (ym.isAfter(YearMonth.now())) {
            throw new ValidationException("Jövőbeli hónap nem zárható le: " + yearMonth);
        }

        // 2. DB ellenőrzés (expensive)
        if (monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(branchId, yearMonth)) {
            throw new ValidationException("A(z) " + yearMonth + " hónap már le van zárva ennél az irodánál!");
        }

        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // 3. Nyitott napi sessionök ellenőrzése — BLOCK guard
        // Legacy: NAPZAR.DLL — havi zárás előtt minden napi zárásnak meg kell történnie
        long openSessions = dailySessionRepository.countOpenSessionsInRange(companyId, branchId, monthStart, monthEnd);
        if (openSessions > 0) {
            throw new ValidationException(
                "Havi zárás nem végezhető el: " + openSessions +
                " nyitott napi session van a(z) " + yearMonth + " hónapban! " +
                "Először zárd le az összes napi munkamenetet.");
        }

        Branch branch = monthlyClosingAccessGuard.requireAccessibleBranch(branchId);

        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        Worker worker = workerRepository.findById(currentWorkerId)
                .orElseThrow(() -> new ValidationException("Dolgozó nem található: " + currentWorkerId));

        // Összesítő adatok
        BigDecimal totalBuyHuf = transactionRepository.sumMonthlyBuyHuf(branchId, monthStart, monthEnd);
        BigDecimal totalSellHuf = transactionRepository.sumMonthlySellHuf(branchId, monthStart, monthEnd);
        BigDecimal totalHandlingFee = transactionRepository.sumMonthlyHandlingFees(branchId, monthStart, monthEnd);
        long transactionCount = transactionRepository.countMonthlyTransactions(branchId, monthStart, monthEnd);

        // MNB árfolyamok a hónap utolsó munkanapjára
        LocalDate lastBusinessDay = getLastBusinessDay(monthEnd);
        Map<String, MnbExchangeRateCache> mnbRates = mnbExchangeRateService.getRatesForDate(lastBusinessDay);
        log.info("MNB árfolyamok letöltve havi záráshoz: date={}, valuták={}", lastBusinessDay, mnbRates.size());

        // Készlet adatok (CurrencyStock — WAC nyilvántartás).
        //
        // FKH-029 FR-5 (SZÁNDÉKOSAN NEM ÁTÁLLÍTVA, csak megfigyelhetővé tett): a CASHIER
        // CurrencyStock réteg az élő audit (2026-08-04) szerint holt — élő fióknak nincs sora,
        // mert az egyetlen író útvonal (MaterialReceiptService) soha nem futott élesben
        // (material_receipt = 0 sor). A stockMap ezért élesben ÜRES, és a WAC-alapú
        // bekerülési ár 0-ként számítódik.
        //
        // Miért NEM cseréljük cash_balance-ra: ez egy PÉNZÜGYI RIPORT (havi zárás, realizált
        // eredmény) számértéke. A cash_balance mennyiséget tart nyilván, de NEM tartalmaz
        // súlyozott átlagos bekerülési árat (WAC) — a csere tehát nem ekvivalens átállítás,
        // hanem üzleti/számviteli döntés. A WAC_PROFIT_TRACKING_ENABLED flag emellett default
        // OFF (WacService: az élesítés előtt ops/compliance igazolja a nyitó-készlet
        // bekerülési árának konzisztenciáját). Ezért itt kizárólag LÁTHATÓVÁ tesszük az
        // üres állapotot, hogy ne csendben adjon 0 bekerülési árat.
        List<CurrencyStock> stocks = currencyStockRepository
                .findByEntityTypeAndEntityId("CASHIER", branchId.toString());
        Map<String, CurrencyStock> stockMap = new LinkedHashMap<>();
        for (CurrencyStock cs : stocks) {
            stockMap.put(cs.getCurrencyCode(), cs);
        }
        if (stockMap.isEmpty()) {
            log.warn("FKH-029: nincs CASHIER CurrencyStock sor a havi záráshoz (branch: {}, {}). "
                            + "A WAC-alapú bekerülési ár 0-ként számítódik. A CASHIER készlet-réteg "
                            + "kivezetés alatt áll; WAC-alapú realizált eredményhez önálló fejlesztés "
                            + "és compliance-igazolás szükséges.",
                    branchId, yearMonth);
        }

        // Valutánkénti bontás (forgalom + MNB készletértékelés + realizált eredmény)
        List<Transaction> monthTransactions = transactionRepository.findByBranchAndMonth(
                branchId, monthStart, monthEnd);
        String currencyBreakdown = buildCurrencyBreakdown(monthTransactions, mnbRates, stockMap);

        MonthlyClosingSummary summary = MonthlyClosingSummary.builder()
                .branch(branch)
                .yearMonth(yearMonth)
                .closedAt(LocalDateTime.now())
                .closedBy(worker)
                .totalBuyHuf(totalBuyHuf)
                .totalSellHuf(totalSellHuf)
                .totalHandlingFee(totalHandlingFee)
                .transactionCount((int) transactionCount)
                .currencyBreakdown(currencyBreakdown)
                .build();

        MonthlyClosingSummary saved = monthlyClosingSummaryRepository.save(summary);
        log.info("Havi zárás elvégezve: branch={}, yearMonth={}, tranzakciók={}, vétel={}, eladás={}, MNB dátum={}",
                branchId, yearMonth, transactionCount, totalBuyHuf, totalSellHuf, lastBusinessDay);

        // Tranzakciók archiválása (legacy: CopyTables)
        archiveTransactions(saved, monthTransactions, yearMonth);

        return saved;
    }

    /**
     * Havi összesítő lekérdezés.
     */
    @Transactional(readOnly = true)
    public MonthlyClosingSummary getMonthlyReport(UUID branchId, String yearMonth) {
        monthlyClosingAccessGuard.requireAccessibleBranch(branchId);
        return monthlyClosingSummaryRepository.findByBranchIdAndYearMonth(branchId, yearMonth)
                .orElseThrow(() -> new ValidationException(
                        "Nincs havi zárás a(z) " + yearMonth + " hónapra ennél az irodánál!"));
    }

    /**
     * Lezárt-e már az adott hónap.
     */
    @Transactional(readOnly = true)
    public boolean isMonthClosed(UUID branchId, String yearMonth) {
        monthlyClosingAccessGuard.requireAccessibleBranch(branchId);
        return monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(branchId, yearMonth);
    }

    /**
     * Összes lezárt hónap listája egy branch-hez.
     */
    @Transactional(readOnly = true)
    public List<MonthlyClosingSummary> getAllClosedMonths(UUID branchId) {
        monthlyClosingAccessGuard.requireAccessibleBranch(branchId);
        return monthlyClosingSummaryRepository.findAllByBranchId(branchId);
    }

    // ============ BELSŐ SEGÉDMETÓDUSOK ============

    /**
     * NULL-safe BigDecimal összeadás helper.
     * HIGH FIX #2: Konzisztens NULL kezelés minden BigDecimal nullable mezőnél.
     */
    private BigDecimal safeAdd(BigDecimal current, BigDecimal toAdd) {
        return current.add(toAdd != null ? toAdd : BigDecimal.ZERO);
    }

    private YearMonth parseYearMonth(String yearMonth) {
        try {
            return YearMonth.parse(yearMonth);
        } catch (Exception e) {
            throw new ValidationException("Érvénytelen év-hónap formátum: " + yearMonth + " (elvárt: YYYY-MM)");
        }
    }

    /**
     * Hónap utolsó munkanapjának meghatározása — magyar ünnepnapok figyelembevételével.
     *
     * Legacy: HAVIZAR.DLL — holiday-aware last-business-day számítás.
     *
     * Fix ünnepnapok: jan.1, márc.15, máj.1, aug.20, okt.23, nov.1, dec.25, dec.26
     * Változó ünnepnapok: Húsvét hétfő (Meeus algoritmus alapján)
     */
    LocalDate getLastBusinessDay(LocalDate monthEnd) {
        LocalDate d = monthEnd;
        while (d.getDayOfWeek() == DayOfWeek.SATURDAY
                || d.getDayOfWeek() == DayOfWeek.SUNDAY
                || isHungarianHoliday(d)) {
            d = d.minusDays(1);
        }
        return d;
    }

    /**
     * Magyar munkaszüneti nap-e az adott dátum?
     *
     * Fix ünnepnapok:
     *   jan.1  — Újév
     *   márc.15 — Nemzeti ünnep
     *   máj.1  — A munka ünnepe
     *   aug.20 — Államalapítás ünnepe (Szent István)
     *   okt.23 — Nemzeti ünnep
     *   nov.1  — Mindenszentek
     *   dec.25 — Karácsony
     *   dec.26 — Karácsony 2. napja
     *
     * Változó ünnepnapok (Húsvét hétfő):
     *   Húsvét hétfő = Húsvét vasárnap + 1 nap
     *   Húsvét vasárnap: Meeus/Jones/Butcher algoritmus
     *   Nagypéntek: Húsvét vasárnap - 2 nap (Magyarországon 2017-től munkaszüneti nap)
     */
    boolean isHungarianHoliday(LocalDate date) {
        int month = date.getMonthValue();
        int day = date.getDayOfMonth();

        // Fix ünnepnapok
        if (month == 1  && day == 1)  return true;  // Újév
        if (month == 3  && day == 15) return true;  // Nemzeti ünnep
        if (month == 5  && day == 1)  return true;  // A munka ünnepe
        if (month == 8  && day == 20) return true;  // Államalapítás
        if (month == 10 && day == 23) return true;  // Nemzeti ünnep
        if (month == 11 && day == 1)  return true;  // Mindenszentek
        if (month == 12 && day == 25) return true;  // Karácsony
        if (month == 12 && day == 26) return true;  // Karácsony 2.

        // Húsvét-alapú ünnepnapok (Meeus/Jones/Butcher algoritmus)
        LocalDate easter = calculateEaster(date.getYear());
        LocalDate goodFriday = easter.minusDays(2);   // Nagypéntek (2017-től)
        LocalDate easterMonday = easter.plusDays(1);  // Húsvét hétfő

        if (date.equals(goodFriday) && date.getYear() >= 2017) return true;
        if (date.equals(easterMonday)) return true;

        return false;
    }

    /**
     * Húsvét vasárnap kiszámítása — Meeus/Jones/Butcher algoritmus.
     *
     * Referencia: Jean Meeus, "Astronomical Algorithms", 1991.
     * Pontosság: 1900–2099 közötti évekre érvényes.
     *
     * 2025 → április 20.
     * 2026 → április 5.
     */
    LocalDate calculateEaster(int year) {
        int a = year % 19;
        int b = year / 100;
        int c = year % 100;
        int d = b / 4;
        int e = b % 4;
        int f = (b + 8) / 25;
        int g = (b - f + 1) / 3;
        int h = (19 * a + b - d - g + 15) % 30;
        int i = c / 4;
        int k = c % 4;
        int l = (32 + 2 * e + 2 * i - h - k) % 7;
        int m = (a + 11 * h + 22 * l) / 451;
        int month = (h + l - 7 * m + 114) / 31;
        int day = ((h + l - 7 * m + 114) % 31) + 1;
        return LocalDate.of(year, month, day);
    }

    /**
     * Tranzakciók archiválása havi záráskor.
     *
     * Legacy: NAPZAR.DLL CopyTables() — a napi TRAD+MMDD táblák tartalmát
     * havi gyűjtő táblákba (BF2603 stb.) másolta mezőnév+típus alapján.
     *
     * Modern: ArchivedMonthlyTransaction entity-kbe másol batch-ben.
     */
    private void archiveTransactions(MonthlyClosingSummary saved,
                                      List<Transaction> transactions,
                                      String yearMonth) {
        if (transactions.isEmpty()) {
            log.info("Nincs archiválandó tranzakció: branch={}, yearMonth={}", saved.getBranch().getId(), yearMonth);
            return;
        }

        List<ArchivedMonthlyTransaction> archives = new ArrayList<>(transactions.size());
        LocalDateTime now = LocalDateTime.now();

        for (Transaction t : transactions) {
            String currencyCode = t.getCurrency() != null ? t.getCurrency().getCode() : "UNKNOWN";
            Long workerId = t.getWorker() != null ? t.getWorker().getId() : null;

            ArchivedMonthlyTransaction archive = ArchivedMonthlyTransaction.builder()
                    .monthlyClosingId(saved.getId())
                    .branchId(saved.getBranch().getId())
                    .companyId(t.getCompany() != null ? t.getCompany().getId() : null)
                    .originalTxId(t.getId())
                    .transactionDate(t.getTransactionDate())
                    .transactionType(t.getTransactionType() != null ? t.getTransactionType().name() : "UNKNOWN")
                    .currencyCode(currencyCode)
                    .currencyAmount(t.getCurrencyAmount())
                    .hufAmount(t.getHufAmount())
                    .exchangeRate(t.getExchangeRate())
                    .handlingFee(t.getHandlingFee())
                    .customerId(t.getCustomerId())
                    .workerId(workerId)
                    .archivedAt(now)
                    .yearMonth(yearMonth)
                    .build();

            archives.add(archive);
        }

        archivedMonthlyTransactionRepository.saveAll(archives);
        log.info("Tranzakciók archiválva: branch={}, yearMonth={}, db={}",
                saved.getBranch().getId(), yearMonth, archives.size());
    }

    /**
     * Valutánkénti bontás JSON-ként — forgalom + MNB készletértékelés + realizált eredmény.
     *
     * Az MNB árfolyammal felértékelt készlet és a WAC-értékelt készlet
     * különbségéből számítjuk a nem realizált hasznot (unrealizedPnl).
     *
     * Realizált eredmény (realizedPnl):
     *   BUY esetén: hufAmount − (currencyAmount × WAC)  → ha olcsóbban vettük mint WAC
     *   SELL esetén: hufAmount − (currencyAmount × WAC) → ha drágábban adtuk el mint WAC
     *   Képlet: realizedPnl = Σ(eladási HUF − eladott mennyiség × WAC)
     *
     * Képlet (unrealizedPnl):
     *   stockValueMnb = stockQuantity × mnbOfficialRate
     *   stockValueWac = stockQuantity × weightedAvgCost
     *   unrealizedPnl = stockValueMnb − stockValueWac
     */
    private String buildCurrencyBreakdown(List<Transaction> transactions,
            Map<String, MnbExchangeRateCache> mnbRates,
            Map<String, CurrencyStock> stockMap) {

        Map<String, CurrencyBreakdownEntry> breakdownMap = new LinkedHashMap<>();

        for (Transaction t : transactions) {
            String currencyCode = t.getCurrency() != null ? t.getCurrency().getCode() : "UNKNOWN";

            CurrencyBreakdownEntry entry = breakdownMap.computeIfAbsent(
                    currencyCode, k -> new CurrencyBreakdownEntry(k));

            // HIGH FIX #2: safeAdd helper — konzisztens NULL-safe BigDecimal összesítés
            if (t.getTransactionType() != null && t.getTransactionType().isBuyType()) {
                entry.buyCount++;
                entry.buyAmount = safeAdd(entry.buyAmount, t.getCurrencyAmount());
                entry.buyHuf = safeAdd(entry.buyHuf, t.getHufAmount());
            } else if (t.getTransactionType() != null && t.getTransactionType().isSellType()) {
                entry.sellCount++;
                entry.sellAmount = safeAdd(entry.sellAmount, t.getCurrencyAmount());
                entry.sellHuf = safeAdd(entry.sellHuf, t.getHufAmount());
            }

            entry.handlingFee = safeAdd(entry.handlingFee, t.getHandlingFee());
        }

        // MNB készletértékelés hozzáadása
        // Azokat a valutákat is felvesszük, amelyekből van készlet, de nem volt tranzakció
        for (Map.Entry<String, CurrencyStock> stockEntry : stockMap.entrySet()) {
            String currCode = stockEntry.getKey();
            if ("HUF".equals(currCode))
                continue;
            breakdownMap.computeIfAbsent(currCode, k -> new CurrencyBreakdownEntry(k));
        }

        // Készlet + MNB értékelés + realizált PnL feltöltése
        for (CurrencyBreakdownEntry entry : breakdownMap.values()) {
            String currCode = entry.currencyCode;
            if ("HUF".equals(currCode) || "UNKNOWN".equals(currCode))
                continue;

            CurrencyStock stock = stockMap.get(currCode);
            MnbExchangeRateCache mnbRate = mnbRates.get(currCode);

            if (stock != null && stock.getQuantity().compareTo(BigDecimal.ZERO) > 0) {
                entry.stockQuantity = stock.getQuantity();
                entry.weightedAvgCost = stock.getWeightedAvgCost();

                // WAC-alapú készletérték
                entry.stockValueWac = entry.stockQuantity
                        .multiply(entry.weightedAvgCost)
                        .setScale(2, RoundingMode.HALF_UP);

                if (mnbRate != null) {
                    // MNB 1 egységre vetített árfolyam
                    entry.mnbOfficialRate = mnbRate.getRatePerUnit();

                    // MNB-alapú készletérték
                    entry.stockValueMnb = entry.stockQuantity
                            .multiply(entry.mnbOfficialRate)
                            .setScale(2, RoundingMode.HALF_UP);

                    // Nem realizált eredmény = MNB érték − WAC érték
                    entry.unrealizedPnl = entry.stockValueMnb
                            .subtract(entry.stockValueWac)
                            .setScale(2, RoundingMode.HALF_UP);
                }

                // Realizált PnL számítása WAC alapján
                // SELL: kapott HUF − (eladott mennyiség × WAC) → pozitív ha jól adtuk el
                if (entry.sellAmount.compareTo(BigDecimal.ZERO) > 0
                        && entry.weightedAvgCost != null
                        && entry.weightedAvgCost.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal sellCostAtWac = entry.sellAmount
                            .multiply(entry.weightedAvgCost)
                            .setScale(2, RoundingMode.HALF_UP);
                    entry.realizedPnl = entry.sellHuf
                            .subtract(sellCostAtWac)
                            .setScale(2, RoundingMode.HALF_UP);
                }
            }
        }

        try {
            return objectMapper.writeValueAsString(breakdownMap.values());
        } catch (JacksonException e) {
            log.error("Hiba a currency breakdown JSON generálásakor", e);
            return "[]";
        }
    }

    /**
     * Belső segéd-osztály a valutánkénti bontáshoz.
     *
     * Tartalmazza a forgalmi adatokat, az MNB készletértékelést
     * és a realizált/nem realizált eredményt.
     */
    private static class CurrencyBreakdownEntry {
        // --- Forgalmi adatok ---
        String currencyCode;
        int buyCount;
        BigDecimal buyAmount = BigDecimal.ZERO;
        BigDecimal buyHuf = BigDecimal.ZERO;
        int sellCount;
        BigDecimal sellAmount = BigDecimal.ZERO;
        BigDecimal sellHuf = BigDecimal.ZERO;
        BigDecimal handlingFee = BigDecimal.ZERO;

        // --- MNB készletértékelés ---
        BigDecimal mnbOfficialRate;    // MNB hivatalos középárfolyam (1 egységre)
        BigDecimal stockQuantity;      // Aktuális készlet mennyiség
        BigDecimal weightedAvgCost;    // WAC (súlyozott átlagár)
        BigDecimal stockValueMnb;      // Készlet × MNB árfolyam (HUF)
        BigDecimal stockValueWac;      // Készlet × WAC (HUF)
        BigDecimal unrealizedPnl;      // Nem realizált eredmény = MNB − WAC
        BigDecimal realizedPnl;        // Realizált eredmény = eladási HUF − (eladott qty × WAC)

        CurrencyBreakdownEntry(String currencyCode) {
            this.currencyCode = currencyCode;
        }

        // Jackson szerializáláshoz kell getter
        public String getCurrencyCode() { return currencyCode; }
        public int getBuyCount() { return buyCount; }
        public BigDecimal getBuyAmount() { return buyAmount; }
        public BigDecimal getBuyHuf() { return buyHuf; }
        public int getSellCount() { return sellCount; }
        public BigDecimal getSellAmount() { return sellAmount; }
        public BigDecimal getSellHuf() { return sellHuf; }
        public BigDecimal getHandlingFee() { return handlingFee; }
        public BigDecimal getMnbOfficialRate() { return mnbOfficialRate; }
        public BigDecimal getStockQuantity() { return stockQuantity; }
        public BigDecimal getWeightedAvgCost() { return weightedAvgCost; }
        public BigDecimal getStockValueMnb() { return stockValueMnb; }
        public BigDecimal getStockValueWac() { return stockValueWac; }
        public BigDecimal getUnrealizedPnl() { return unrealizedPnl; }
        public BigDecimal getRealizedPnl() { return realizedPnl; }
    }
}
