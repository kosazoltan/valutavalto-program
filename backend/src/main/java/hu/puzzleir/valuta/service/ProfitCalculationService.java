package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.Branch;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

/**
 * Haszon számítás szolgáltatás.
 *
 * Bevétel = eladási HUF - vételi HUF (spread × mennyiség)
 * Kiadás = kezelési díjak
 * Bruttó haszon = Bevétel
 * Nettó haszon = Bevétel - Kiadás
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ProfitCalculationService {

    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;

    /**
     * Napi haszon számítás.
     */
    public ProfitReport calculateDailyProfit(UUID branchId, LocalDate date) {
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, date);
        return buildProfitReport(transactions);
    }

    /**
     * Havi haszon számítás.
     */
    public ProfitReport calculateMonthlyProfit(UUID branchId, String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        List<Transaction> transactions = transactionRepository.findByBranchAndMonth(branchId, monthStart, monthEnd);
        return buildProfitReport(transactions);
    }

    /**
     * Cég szintű havi haszon.
     */
    public ProfitReport calculateCompanyProfit(UUID companyId, String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        // Összes branch keresése a céghez
        List<Branch> branches = branchRepository.findByCompanyId(companyId);

        List<Transaction> allTx = new ArrayList<>();
        for (Branch branch : branches) {
            allTx.addAll(transactionRepository.findByBranchAndMonth(branch.getId(), monthStart, monthEnd));
        }

        return buildProfitReport(allTx);
    }

    // ============ BELSŐ LOGIKA ============

    private ProfitReport buildProfitReport(List<Transaction> transactions) {
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;

        Map<String, CurrencyProfit> currencyMap = new LinkedHashMap<>();

        for (Transaction t : transactions) {
            String currCode = t.getCurrency() != null ? t.getCurrency().getCode() : "UNKNOWN";
            CurrencyProfit cp = currencyMap.computeIfAbsent(currCode, CurrencyProfit::new);

            BigDecimal huf = t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO;
            BigDecimal fee = t.getHandlingFee() != null ? t.getHandlingFee() : BigDecimal.ZERO;

            if (t.getTransactionType().isSellType()) {
                totalSellHuf = totalSellHuf.add(huf);
                cp.sellHuf = cp.sellHuf.add(huf);
                cp.sellCount++;
            } else if (t.getTransactionType().isBuyType()) {
                totalBuyHuf = totalBuyHuf.add(huf);
                cp.buyHuf = cp.buyHuf.add(huf);
                cp.buyCount++;
            }

            totalFees = totalFees.add(fee);
            cp.fees = cp.fees.add(fee);
        }

        // Bevétel = eladásból kapott HUF - vételre kifizetett HUF (spread profit)
        BigDecimal revenue = totalSellHuf.subtract(totalBuyHuf).setScale(2, RoundingMode.HALF_UP);
        BigDecimal grossProfit = revenue;
        BigDecimal netProfit = grossProfit.subtract(totalFees).setScale(2, RoundingMode.HALF_UP);

        List<Map<String, Object>> profitByCurrency = new ArrayList<>();
        for (CurrencyProfit cp : currencyMap.values()) {
            BigDecimal currRevenue = cp.sellHuf.subtract(cp.buyHuf).setScale(2, RoundingMode.HALF_UP);
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("currencyCode", cp.currencyCode);
            entry.put("buyCount", cp.buyCount);
            entry.put("sellCount", cp.sellCount);
            entry.put("buyHuf", cp.buyHuf.setScale(2, RoundingMode.HALF_UP));
            entry.put("sellHuf", cp.sellHuf.setScale(2, RoundingMode.HALF_UP));
            entry.put("revenue", currRevenue);
            entry.put("fees", cp.fees.setScale(2, RoundingMode.HALF_UP));
            entry.put("profit", currRevenue.subtract(cp.fees).setScale(2, RoundingMode.HALF_UP));
            profitByCurrency.add(entry);
        }

        ProfitReport report = new ProfitReport();
        report.revenue = revenue;
        report.expenses = totalFees;
        report.grossProfit = grossProfit;
        report.netProfit = netProfit;
        report.totalTransactions = transactions.size();
        report.profitByCurrency = profitByCurrency;

        return report;
    }

    // ============ DTO-K ============

    public static class ProfitReport {
        public BigDecimal revenue = BigDecimal.ZERO;
        public BigDecimal expenses = BigDecimal.ZERO;
        public BigDecimal grossProfit = BigDecimal.ZERO;
        public BigDecimal netProfit = BigDecimal.ZERO;
        public int totalTransactions;
        public List<Map<String, Object>> profitByCurrency = new ArrayList<>();

        // Jackson serialization
        public BigDecimal getRevenue() { return revenue; }
        public BigDecimal getExpenses() { return expenses; }
        public BigDecimal getGrossProfit() { return grossProfit; }
        public BigDecimal getNetProfit() { return netProfit; }
        public int getTotalTransactions() { return totalTransactions; }
        public List<Map<String, Object>> getProfitByCurrency() { return profitByCurrency; }
    }

    private static class CurrencyProfit {
        String currencyCode;
        int buyCount;
        int sellCount;
        BigDecimal buyHuf = BigDecimal.ZERO;
        BigDecimal sellHuf = BigDecimal.ZERO;
        BigDecimal fees = BigDecimal.ZERO;

        CurrencyProfit(String currencyCode) {
            this.currencyCode = currencyCode;
        }
    }
}
