package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
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
 * breakdown-nal.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MonthlyClosingService {

    private final TransactionRepository transactionRepository;
    private final MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final ObjectMapper objectMapper;
    private final MnbExchangeRateService mnbExchangeRateService;
    private final CurrencyStockRepository currencyStockRepository;

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
    @Transactional
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

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ValidationException("Iroda nem található: " + branchId));

        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        Worker worker = workerRepository.findById(currentWorkerId)
                .orElseThrow(() -> new ValidationException("Dolgozó nem található: " + currentWorkerId));

        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        // Összesítő adatok
        BigDecimal totalBuyHuf = transactionRepository.sumMonthlyBuyHuf(branchId, monthStart, monthEnd);
        BigDecimal totalSellHuf = transactionRepository.sumMonthlySellHuf(branchId, monthStart, monthEnd);
        BigDecimal totalHandlingFee = transactionRepository.sumMonthlyHandlingFees(branchId, monthStart, monthEnd);
        long transactionCount = transactionRepository.countMonthlyTransactions(branchId, monthStart, monthEnd);

        // MNB árfolyamok a hónap utolsó munkanapjára
        LocalDate lastBusinessDay = getLastBusinessDay(monthEnd);
        Map<String, MnbExchangeRateCache> mnbRates = mnbExchangeRateService.getRatesForDate(lastBusinessDay);
        log.info("MNB árfolyamok letöltve havi záráshoz: date={}, valuták={}", lastBusinessDay, mnbRates.size());

        // Készlet adatok (CurrencyStock — WAC nyilvántartás)
        List<CurrencyStock> stocks = currencyStockRepository
                .findByEntityTypeAndEntityId("CASHIER", branchId.toString());
        Map<String, CurrencyStock> stockMap = new LinkedHashMap<>();
        for (CurrencyStock cs : stocks) {
            stockMap.put(cs.getCurrencyCode(), cs);
        }

        // Valutánkénti bontás (forgalom + MNB készletértékelés)
        String currencyBreakdown = buildCurrencyBreakdown(branchId, monthStart, monthEnd, mnbRates, stockMap);

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

        return saved;
    }

    /**
     * Havi összesítő lekérdezés.
     */
    @Transactional(readOnly = true)
    public MonthlyClosingSummary getMonthlyReport(UUID branchId, String yearMonth) {
        return monthlyClosingSummaryRepository.findByBranchIdAndYearMonth(branchId, yearMonth)
                .orElseThrow(() -> new ValidationException(
                        "Nincs havi zárás a(z) " + yearMonth + " hónapra ennél az irodánál!"));
    }

    /**
     * Lezárt-e már az adott hónap.
     */
    @Transactional(readOnly = true)
    public boolean isMonthClosed(UUID branchId, String yearMonth) {
        return monthlyClosingSummaryRepository.existsByBranchIdAndYearMonth(branchId, yearMonth);
    }

    /**
     * Összes lezárt hónap listája egy branch-hez.
     */
    @Transactional(readOnly = true)
    public List<MonthlyClosingSummary> getAllClosedMonths(UUID branchId) {
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
     * Hónap utolsó munkanapjának meghatározása.
     * Ha a hónap utolsó napja hétvégére esik, visszalép az utolsó péntekre.
     */
    private LocalDate getLastBusinessDay(LocalDate monthEnd) {
        LocalDate d = monthEnd;
        while (d.getDayOfWeek() == DayOfWeek.SATURDAY || d.getDayOfWeek() == DayOfWeek.SUNDAY) {
            d = d.minusDays(1);
        }
        return d;
    }

    /**
     * Valutánkénti bontás JSON-ként — forgalom + MNB készletértékelés.
     *
     * Az MNB árfolyammal felértékelt készlet és a WAC-értékelt készlet
     * különbségéből
     * számítjuk a nem realizált hasznot (unrealizedPnl).
     *
     * Képlet:
     * stockValueMnb = stockQuantity × mnbOfficialRate (1 egységre vetítve)
     * stockValueWac = stockQuantity × weightedAvgCost
     * unrealizedPnl = stockValueMnb − stockValueWac
     */
    private String buildCurrencyBreakdown(UUID branchId, LocalDate monthStart, LocalDate monthEnd,
            Map<String, MnbExchangeRateCache> mnbRates,
            Map<String, CurrencyStock> stockMap) {
        List<Transaction> transactions = transactionRepository.findByBranchAndMonth(
                branchId, monthStart, monthEnd);

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
        // Azokat a valutákat is felvesszük, amelyekből van készlet, de nem volt
        // tranzakció
        for (Map.Entry<String, CurrencyStock> stockEntry : stockMap.entrySet()) {
            String currCode = stockEntry.getKey();
            if ("HUF".equals(currCode))
                continue;
            breakdownMap.computeIfAbsent(currCode, k -> new CurrencyBreakdownEntry(k));
        }

        // Készlet + MNB értékelés feltöltése
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
            }
        }

        try {
            return objectMapper.writeValueAsString(breakdownMap.values());
        } catch (JsonProcessingException e) {
            log.error("Hiba a currency breakdown JSON generálásakor", e);
            return "[]";
        }
    }

    /**
     * Belső segéd-osztály a valutánkénti bontáshoz.
     *
     * Tartalmazza a forgalmi adatokat ÉS az MNB készletértékelést.
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
        BigDecimal mnbOfficialRate; // MNB hivatalos középárfolyam (1 egységre)
        BigDecimal stockQuantity; // Aktuális készlet mennyiség
        BigDecimal weightedAvgCost; // WAC (súlyozott átlagár)
        BigDecimal stockValueMnb; // Készlet × MNB árfolyam (HUF)
        BigDecimal stockValueWac; // Készlet × WAC (HUF)
        BigDecimal unrealizedPnl; // Nem realizált eredmény = MNB − WAC

        CurrencyBreakdownEntry(String currencyCode) {
            this.currencyCode = currencyCode;
        }

        // Jackson szerializáláshoz kell getter
        public String getCurrencyCode() {
            return currencyCode;
        }

        public int getBuyCount() {
            return buyCount;
        }

        public BigDecimal getBuyAmount() {
            return buyAmount;
        }

        public BigDecimal getBuyHuf() {
            return buyHuf;
        }

        public int getSellCount() {
            return sellCount;
        }

        public BigDecimal getSellAmount() {
            return sellAmount;
        }

        public BigDecimal getSellHuf() {
            return sellHuf;
        }

        public BigDecimal getHandlingFee() {
            return handlingFee;
        }

        public BigDecimal getMnbOfficialRate() {
            return mnbOfficialRate;
        }

        public BigDecimal getStockQuantity() {
            return stockQuantity;
        }

        public BigDecimal getWeightedAvgCost() {
            return weightedAvgCost;
        }

        public BigDecimal getStockValueMnb() {
            return stockValueMnb;
        }

        public BigDecimal getStockValueWac() {
            return stockValueWac;
        }

        public BigDecimal getUnrealizedPnl() {
            return unrealizedPnl;
        }
    }
}
