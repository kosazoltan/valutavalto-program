package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Riport szolgáltatás.
 *
 * Legacy: Napi zárás riportok, forgalmi kimutatások
 * - Napi forgalmi összesítő
 * - Valutánkénti forgalom
 * - Pénztáros teljesítmény
 * - Időszaki kimutatások
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class ReportService {

    private final TransactionRepository transactionRepository;
    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationRepository denominationRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;

    /**
     * Napi zárás riport
     *
     * Legacy: NAPZAR - összesítő riport nyomtatáshoz
     */
    public DailyClosingReport generateDailyClosingReport(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Session adatok
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, date)
                .orElse(null);

        // Napi tranzakciók
        List<Transaction> transactions = transactionRepository.findByBranchAndDate(branchId, date);

        // Valutánkénti bontás
        Map<String, CurrencyTurnover> currencyTurnovers = calculateCurrencyTurnovers(transactions);

        // Kassza egyenlegek
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);

        // Címletezés (HUF)
        Currency huf = currencyRepository.findByCode("HUF").orElse(null);
        List<Denomination> hufDenominations = huf != null
                ? denominationRepository.findByBranchAndCurrency(branchId, huf.getId())
                : Collections.emptyList();

        BigDecimal denominatedTotal = hufDenominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Összesítés
        BigDecimal totalBuy = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHandlingFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long reversalCount = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.REVERSAL)
                .count();

        return DailyClosingReport.builder()
                .reportDate(date)
                .generatedAt(LocalDateTime.now())
                .sessionId(session != null ? session.getId() : null)
                .sessionStatus(session != null ? session.getStatus().name() : "NO_SESSION")
                .openingBalanceHuf(session != null ? session.getOpeningBalanceHuf() : BigDecimal.ZERO)
                .closingBalanceHuf(session != null ? session.getClosingBalanceHuf() : null)
                .transactionCount(transactions.size())
                .buyCount((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.BUY).count())
                .sellCount((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.SELL).count())
                .reversalCount((int) reversalCount)
                .totalBuyHuf(totalBuy)
                .totalSellHuf(totalSell)
                .netTurnoverHuf(totalSell.subtract(totalBuy))
                .totalHandlingFees(totalFees)
                .currencyTurnovers(new ArrayList<>(currencyTurnovers.values()))
                .cashBalances(balances)
                .hufDenominations(hufDenominations)
                .denominatedTotalHuf(denominatedTotal)
                .build();
    }

    /**
     * Időszaki forgalmi kimutatás
     *
     * Legacy: Időszaki riportok
     */
    public PeriodReport generatePeriodReport(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<DailySession> sessions = dailySessionRepository.findByDateRange(companyId, startDate, endDate);

        BigDecimal totalBuy = BigDecimal.ZERO;
        BigDecimal totalSell = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;
        int totalTransactions = 0;
        int totalReversals = 0;

        List<DailySummary> dailySummaries = new ArrayList<>();

        for (DailySession session : sessions) {
            totalBuy = totalBuy.add(session.getBuyTurnoverHuf() != null ? session.getBuyTurnoverHuf() : BigDecimal.ZERO);
            totalSell = totalSell.add(session.getSellTurnoverHuf() != null ? session.getSellTurnoverHuf() : BigDecimal.ZERO);
            totalFees = totalFees.add(session.getHandlingFeeTotal() != null ? session.getHandlingFeeTotal() : BigDecimal.ZERO);
            totalTransactions += session.getTransactionCount() != null ? session.getTransactionCount() : 0;
            totalReversals += session.getReversalCount() != null ? session.getReversalCount() : 0;

            dailySummaries.add(DailySummary.builder()
                    .date(session.getSessionDate())
                    .branchName(session.getBranch().getName())
                    .transactionCount(session.getTransactionCount())
                    .buyTurnover(session.getBuyTurnoverHuf())
                    .sellTurnover(session.getSellTurnoverHuf())
                    .netTurnover(session.getNetTurnover())
                    .handlingFees(session.getHandlingFeeTotal())
                    .build());
        }

        return PeriodReport.builder()
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .totalDays(sessions.size())
                .totalTransactions(totalTransactions)
                .totalReversals(totalReversals)
                .totalBuyHuf(totalBuy)
                .totalSellHuf(totalSell)
                .netTurnoverHuf(totalSell.subtract(totalBuy))
                .totalHandlingFees(totalFees)
                .averageDailyTurnover(sessions.isEmpty() ? BigDecimal.ZERO :
                        totalSell.add(totalBuy).divide(BigDecimal.valueOf(sessions.size()), 0, RoundingMode.HALF_UP))
                .dailySummaries(dailySummaries)
                .build();
    }

    /**
     * Pénztáros teljesítmény riport
     */
    public WorkerPerformanceReport generateWorkerPerformanceReport(Long workerId, LocalDate startDate, LocalDate endDate) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new RuntimeException("Pénztáros nem található"));

        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            transactions.addAll(transactionRepository.findByWorkerAndDate(workerId, current));
            current = current.plusDays(1);
        }

        BigDecimal totalBuy = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.BUY && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.SELL && t.isActive())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long reversals = transactions.stream()
                .filter(t -> t.getTransactionType() == TransactionType.REVERSAL)
                .count();

        return WorkerPerformanceReport.builder()
                .workerId(workerId)
                .workerCode(worker.getCode())
                .workerName(worker.getName())
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .totalTransactions(transactions.size())
                .buyTransactions((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.BUY).count())
                .sellTransactions((int) transactions.stream().filter(t -> t.getTransactionType() == TransactionType.SELL).count())
                .reversalCount((int) reversals)
                .totalBuyHuf(totalBuy)
                .totalSellHuf(totalSell)
                .totalTurnoverHuf(totalBuy.add(totalSell))
                .averageTransactionValue(transactions.isEmpty() ? BigDecimal.ZERO :
                        totalBuy.add(totalSell).divide(BigDecimal.valueOf(transactions.size()), 0, RoundingMode.HALF_UP))
                .build();
    }

    /**
     * Valutánkénti forgalmi kimutatás
     */
    public CurrencyReport generateCurrencyReport(Long currencyId, LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new RuntimeException("Valuta nem található"));

        List<Transaction> buyTransactions = transactionRepository.findByTypeAndDateRange(
                companyId, TransactionType.BUY, startDate, endDate).stream()
                .filter(t -> t.getCurrency().getId().equals(currencyId))
                .collect(Collectors.toList());

        List<Transaction> sellTransactions = transactionRepository.findByTypeAndDateRange(
                companyId, TransactionType.SELL, startDate, endDate).stream()
                .filter(t -> t.getCurrency().getId().equals(currencyId))
                .collect(Collectors.toList());

        BigDecimal totalBoughtAmount = buyTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getCurrencyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSoldAmount = sellTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getCurrencyAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalBoughtHuf = buyTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSoldHuf = sellTransactions.stream()
                .filter(Transaction::isActive)
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgBuyRate = totalBoughtAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalBoughtHuf.divide(totalBoughtAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal avgSellRate = totalSoldAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalSoldHuf.divide(totalSoldAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return CurrencyReport.builder()
                .currencyId(currencyId)
                .currencyCode(currency.getCode())
                .currencyName(currency.getName())
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .buyTransactionCount(buyTransactions.size())
                .sellTransactionCount(sellTransactions.size())
                .totalBoughtAmount(totalBoughtAmount)
                .totalSoldAmount(totalSoldAmount)
                .netAmount(totalBoughtAmount.subtract(totalSoldAmount))
                .totalBoughtHuf(totalBoughtHuf)
                .totalSoldHuf(totalSoldHuf)
                .netHuf(totalSoldHuf.subtract(totalBoughtHuf))
                .averageBuyRate(avgBuyRate)
                .averageSellRate(avgSellRate)
                .spread(avgSellRate.subtract(avgBuyRate))
                .build();
    }

    /**
     * Kassza állapot riport (pillanat állás)
     *
     * Legacy: PILLALL - pillanat állapot
     */
    public CashStatusReport generateCashStatusReport() {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        List<Denomination> denominations = denominationRepository.findByBranchId(branchId);

        BigDecimal totalHuf = balances.stream()
                .filter(b -> "HUF".equals(b.getCurrency().getCode()))
                .map(CashBalance::getCurrentBalance)
                .findFirst()
                .orElse(BigDecimal.ZERO);

        // Összes egyenleg HUF-ra átszámítva (egyszerűsített - csak HUF-ot mutatjuk)
        int lowBalanceAlerts = (int) balances.stream().filter(CashBalance::isLowBalance).count();
        int highBalanceAlerts = (int) balances.stream().filter(CashBalance::isHighBalance).count();
        int lowDenominationAlerts = (int) denominations.stream().filter(Denomination::isLowStock).count();

        return CashStatusReport.builder()
                .generatedAt(LocalDateTime.now())
                .totalCurrencies(balances.size())
                .hufBalance(totalHuf)
                .lowBalanceAlerts(lowBalanceAlerts)
                .highBalanceAlerts(highBalanceAlerts)
                .lowDenominationAlerts(lowDenominationAlerts)
                .balances(balances)
                .build();
    }

    // ============ HELPER METHODS ============

    private Map<String, CurrencyTurnover> calculateCurrencyTurnovers(List<Transaction> transactions) {
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
}
