package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.MonthlyClosingSummaryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.entity.Branch;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
 * Modern: MonthlyClosingSummary entity-be összesít, JSON currency breakdown-nal.
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

    /**
     * Havi zárás végrehajtása.
     *
     * Az adott hónap összes tranzakcióját összesíti valutanemenként:
     * össz vétel, össz eladás, össz kezelési díj, tranzakciószám.
     *
     * @param branchId   iroda azonosító
     * @param yearMonth  év-hónap (pl. "2026-03")
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

        // Valutánkénti bontás
        String currencyBreakdown = buildCurrencyBreakdown(branchId, monthStart, monthEnd);

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
        log.info("Havi zárás elvégezve: branch={}, yearMonth={}, tranzakciók={}, vétel={}, eladás={}",
            branchId, yearMonth, transactionCount, totalBuyHuf, totalSellHuf);

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
     * Valutánkénti bontás JSON-ként.
     */
    private String buildCurrencyBreakdown(UUID branchId, LocalDate monthStart, LocalDate monthEnd) {
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

        try {
            return objectMapper.writeValueAsString(breakdownMap.values());
        } catch (JsonProcessingException e) {
            log.error("Hiba a currency breakdown JSON generálásakor", e);
            return "[]";
        }
    }

    /**
     * Belső segéd-osztály a valutánkénti bontáshoz.
     */
    private static class CurrencyBreakdownEntry {
        String currencyCode;
        int buyCount;
        BigDecimal buyAmount = BigDecimal.ZERO;
        BigDecimal buyHuf = BigDecimal.ZERO;
        int sellCount;
        BigDecimal sellAmount = BigDecimal.ZERO;
        BigDecimal sellHuf = BigDecimal.ZERO;
        BigDecimal handlingFee = BigDecimal.ZERO;

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
    }
}
