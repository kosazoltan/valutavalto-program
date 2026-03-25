package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Riport szolgaltatas — Facade.
 *
 * Delegál a specializált generátorokra:
 * - DailyReportGenerator: napi záras, kassza állapot
 * - MonthlyReportGenerator: havi forgalom, időszaki, kezelési díj
 * - NbReportGenerator: NAV/MNB riportok, pénztáros teljesítmény, átadás-átvétel
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class ReportService {

    private final DailyReportGenerator dailyReportGenerator;
    private final MonthlyReportGenerator monthlyReportGenerator;
    private final NbReportGenerator nbReportGenerator;

    // ============ DAILY REPORTS ============

    public DailyClosingReport generateDailyClosingReport(LocalDate date) {
        return dailyReportGenerator.generateDailyClosingReport(date);
    }

    public CashStatusReport generateCashStatusReport() {
        return dailyReportGenerator.generateCashStatusReport();
    }

    // ============ MONTHLY/PERIOD REPORTS ============

    public PeriodReport generatePeriodReport(LocalDate startDate, LocalDate endDate) {
        return monthlyReportGenerator.generatePeriodReport(startDate, endDate);
    }

    public MonthlyTurnoverReport generateMonthlyTurnoverReport(Integer year, Integer month) {
        return monthlyReportGenerator.generateMonthlyTurnoverReport(year, month);
    }

    public HandlingFeeReport generateHandlingFeeReport(LocalDate startDate, LocalDate endDate) {
        return monthlyReportGenerator.generateHandlingFeeReport(startDate, endDate);
    }

    // ============ NAV/MNB REPORTS ============

    public WorkerPerformanceReport generateWorkerPerformanceReport(Long workerId, LocalDate startDate, LocalDate endDate) {
        return nbReportGenerator.generateWorkerPerformanceReport(workerId, startDate, endDate);
    }

    public CurrencyReport generateCurrencyReport(Long currencyId, LocalDate startDate, LocalDate endDate) {
        return nbReportGenerator.generateCurrencyReport(currencyId, startDate, endDate);
    }

    public TransferReport generateTransferReport(LocalDate startDate, LocalDate endDate) {
        return nbReportGenerator.generateTransferReport(startDate, endDate);
    }

    // ============ SHARED HELPER ============

    /**
     * Valutankenti forgalom szamitas (kozos helper).
     */
    static Map<String, CurrencyTurnover> calculateCurrencyTurnovers(List<Transaction> transactions) {
        Map<String, CurrencyTurnover> turnovers = new LinkedHashMap<>();

        for (Transaction t : transactions) {
            if (!t.isActive()) continue;

            String code = t.getCurrency().getCode();
            CurrencyTurnover turnover = turnovers.computeIfAbsent(code, k ->
                    CurrencyTurnover.builder()
                            .currencyCode(code)
                            .currencyName(t.getCurrency().getName())
                            .buyAmount(BigDecimal.ZERO)
                            .sellAmount(BigDecimal.ZERO)
                            .buyHuf(BigDecimal.ZERO)
                            .sellHuf(BigDecimal.ZERO)
                            .buyCount(0)
                            .sellCount(0)
                            .build());

            if (t.getTransactionType() == TransactionType.BUY) {
                turnover.setBuyAmount(turnover.getBuyAmount().add(t.getCurrencyAmount()));
                turnover.setBuyHuf(turnover.getBuyHuf().add(t.getHufAmount()));
                turnover.setBuyCount(turnover.getBuyCount() + 1);
            } else if (t.getTransactionType() == TransactionType.SELL) {
                turnover.setSellAmount(turnover.getSellAmount().add(t.getCurrencyAmount()));
                turnover.setSellHuf(turnover.getSellHuf().add(t.getHufAmount()));
                turnover.setSellCount(turnover.getSellCount() + 1);
            }
        }

        return turnovers;
    }

    // ============ REPORT DTOs ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyClosingReport {
        private LocalDate reportDate;
        private LocalDateTime generatedAt;
        private Long sessionId;
        private String sessionStatus;
        private BigDecimal openingBalanceHuf;
        private BigDecimal closingBalanceHuf;
        private int transactionCount;
        private int buyCount;
        private int sellCount;
        private int reversalCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal netTurnoverHuf;
        private BigDecimal totalHandlingFees;
        private List<CurrencyTurnover> currencyTurnovers;
        private List<CashBalance> cashBalances;
        private List<Denomination> hufDenominations;
        private BigDecimal denominatedTotalHuf;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CurrencyTurnover {
        private String currencyCode;
        private String currencyName;
        private BigDecimal buyAmount;
        private BigDecimal sellAmount;
        private BigDecimal buyHuf;
        private BigDecimal sellHuf;
        private int buyCount;
        private int sellCount;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class PeriodReport {
        private LocalDate startDate;
        private LocalDate endDate;
        private LocalDateTime generatedAt;
        private int totalDays;
        private int totalTransactions;
        private int totalReversals;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal netTurnoverHuf;
        private BigDecimal totalHandlingFees;
        private BigDecimal averageDailyTurnover;
        private List<DailySummary> dailySummaries;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailySummary {
        private LocalDate date;
        private String branchName;
        private Integer transactionCount;
        private BigDecimal buyTurnover;
        private BigDecimal sellTurnover;
        private BigDecimal netTurnover;
        private BigDecimal handlingFees;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class WorkerPerformanceReport {
        private Long workerId;
        private String workerCode;
        private String workerName;
        private LocalDate startDate;
        private LocalDate endDate;
        private LocalDateTime generatedAt;
        private int totalTransactions;
        private int buyTransactions;
        private int sellTransactions;
        private int reversalCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal totalTurnoverHuf;
        private BigDecimal averageTransactionValue;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CurrencyReport {
        private Long currencyId;
        private String currencyCode;
        private String currencyName;
        private LocalDate startDate;
        private LocalDate endDate;
        private LocalDateTime generatedAt;
        private int buyTransactionCount;
        private int sellTransactionCount;
        private BigDecimal totalBoughtAmount;
        private BigDecimal totalSoldAmount;
        private BigDecimal netAmount;
        private BigDecimal totalBoughtHuf;
        private BigDecimal totalSoldHuf;
        private BigDecimal netHuf;
        private BigDecimal averageBuyRate;
        private BigDecimal averageSellRate;
        private BigDecimal spread;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CashStatusReport {
        private LocalDateTime generatedAt;
        private int totalCurrencies;
        private BigDecimal hufBalance;
        private int lowBalanceAlerts;
        private int highBalanceAlerts;
        private int lowDenominationAlerts;
        private List<CashBalance> balances;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class MonthlyTurnoverReport {
        private Integer year;
        private Integer month;
        private LocalDateTime generatedAt;
        private int branchCount;
        private int totalTransactions;
        private int totalBuyCount;
        private int totalSellCount;
        private int totalReversals;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal netTurnoverHuf;
        private BigDecimal totalHandlingFees;
        private List<BranchMonthlyData> branchData;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BranchMonthlyData {
        private UUID branchId;
        private String branchName;
        private Integer transactionCount;
        private Integer buyCount;
        private Integer sellCount;
        private Integer reversalCount;
        private BigDecimal buyHuf;
        private BigDecimal sellHuf;
        private BigDecimal netResult;
        private BigDecimal handlingFees;
        private Boolean finalized;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class TransferReport {
        private LocalDate startDate;
        private LocalDate endDate;
        private LocalDateTime generatedAt;
        private int outgoingCount;
        private int outgoingCompleted;
        private int outgoingPending;
        private BigDecimal totalOutgoingHuf;
        private int incomingCount;
        private int incomingCompleted;
        private int incomingPending;
        private BigDecimal totalIncomingHuf;
        private BigDecimal netTransferHuf;
        private BigDecimal totalDifference;
        private List<TransferSummaryItem> outgoingItems;
        private List<TransferSummaryItem> incomingItems;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class TransferSummaryItem {
        private String transferNumber;
        private LocalDate date;
        private String targetBranchName;
        private String currencyCode;
        private BigDecimal amount;
        private BigDecimal hufValue;
        private String status;
        private BigDecimal difference;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class HandlingFeeReport {
        private LocalDate startDate;
        private LocalDate endDate;
        private LocalDateTime generatedAt;
        private BigDecimal totalHandlingFees;
        private int transactionsWithFee;
        private List<CurrencyFeeData> feesByCurrency;
    }

    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CurrencyFeeData {
        private String currencyCode;
        private BigDecimal totalFees;
    }
}
