package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.MonthlyClosing;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Havi riport generátor.
 *
 * Legacy: HAVIFORG, időszaki riportok, kezelési díj kimutatások
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class MonthlyReportGenerator {

    private final TransactionRepository transactionRepository;
    private final DailySessionRepository dailySessionRepository;
    private final MonthlyClosingRepository monthlyClosingRepository;
    private final BranchRepository branchRepository;

    /**
     * Idoszaki forgalmi kimutatas
     */
    public ReportService.PeriodReport generatePeriodReport(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<DailySession> sessions = dailySessionRepository.findByDateRange(companyId, startDate, endDate);

        BigDecimal totalBuy = BigDecimal.ZERO;
        BigDecimal totalSell = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;
        int totalTransactions = 0;
        int totalReversals = 0;

        List<ReportService.DailySummary> dailySummaries = new ArrayList<>();

        for (DailySession session : sessions) {
            totalBuy = totalBuy.add(session.getBuyTurnoverHuf() != null ? session.getBuyTurnoverHuf() : BigDecimal.ZERO);
            totalSell = totalSell.add(session.getSellTurnoverHuf() != null ? session.getSellTurnoverHuf() : BigDecimal.ZERO);
            totalFees = totalFees.add(session.getHandlingFeeTotal() != null ? session.getHandlingFeeTotal() : BigDecimal.ZERO);
            totalTransactions += session.getTransactionCount() != null ? session.getTransactionCount() : 0;
            totalReversals += session.getReversalCount() != null ? session.getReversalCount() : 0;

            dailySummaries.add(ReportService.DailySummary.builder()
                    .date(session.getSessionDate())
                    .branchName(session.getBranch().getName())
                    .transactionCount(session.getTransactionCount())
                    .buyTurnover(session.getBuyTurnoverHuf())
                    .sellTurnover(session.getSellTurnoverHuf())
                    .netTurnover(session.getNetTurnover())
                    .handlingFees(session.getHandlingFeeTotal())
                    .build());
        }

        return ReportService.PeriodReport.builder()
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
     * Havi forgalmi kimutatas
     *
     * Legacy: HAVIFORG - havi forgalmi osszesito
     */
    public ReportService.MonthlyTurnoverReport generateMonthlyTurnoverReport(Integer year, Integer month) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<MonthlyClosing> closings = monthlyClosingRepository
                .findByCompanyIdAndClosingYearOrderByClosingMonthDesc(companyId, year).stream()
                .filter(c -> c.getClosingMonth().equals(month))
                .collect(Collectors.toList());

        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalHandlingFees = BigDecimal.ZERO;
        int totalTransactions = 0;
        int totalBuyCount = 0;
        int totalSellCount = 0;
        int totalReversals = 0;

        Set<UUID> branchIds = closings.stream().map(MonthlyClosing::getBranchId).collect(Collectors.toSet());
        Map<UUID, String> branchNames = branchRepository.findAllById(branchIds).stream()
                .collect(Collectors.toMap(Branch::getId, Branch::getName));

        List<ReportService.BranchMonthlyData> branchData = new ArrayList<>();

        for (MonthlyClosing closing : closings) {
            totalBuyHuf = totalBuyHuf.add(closing.getTotalBuyHuf() != null ? closing.getTotalBuyHuf() : BigDecimal.ZERO);
            totalSellHuf = totalSellHuf.add(closing.getTotalSellHuf() != null ? closing.getTotalSellHuf() : BigDecimal.ZERO);
            totalHandlingFees = totalHandlingFees.add(closing.getTotalHandlingFees() != null ? closing.getTotalHandlingFees() : BigDecimal.ZERO);
            totalTransactions += closing.getTotalTransactionCount() != null ? closing.getTotalTransactionCount() : 0;
            totalBuyCount += closing.getBuyCount() != null ? closing.getBuyCount() : 0;
            totalSellCount += closing.getSellCount() != null ? closing.getSellCount() : 0;
            totalReversals += closing.getReversalCount() != null ? closing.getReversalCount() : 0;

            String branchName = branchNames.getOrDefault(closing.getBranchId(),
                    "Iroda-" + closing.getBranchId().toString().substring(0, 8));

            branchData.add(ReportService.BranchMonthlyData.builder()
                    .branchId(closing.getBranchId())
                    .branchName(branchName)
                    .transactionCount(closing.getTotalTransactionCount())
                    .buyCount(closing.getBuyCount())
                    .sellCount(closing.getSellCount())
                    .reversalCount(closing.getReversalCount())
                    .buyHuf(closing.getTotalBuyHuf())
                    .sellHuf(closing.getTotalSellHuf())
                    .netResult(closing.getTotalSellHuf().subtract(closing.getTotalBuyHuf()))
                    .handlingFees(closing.getTotalHandlingFees())
                    .finalized(("CLOSED".equals(closing.getStatus())))
                    .build());
        }

        return ReportService.MonthlyTurnoverReport.builder()
                .year(year)
                .month(month)
                .generatedAt(LocalDateTime.now())
                .branchCount(closings.size())
                .totalTransactions(totalTransactions)
                .totalBuyCount(totalBuyCount)
                .totalSellCount(totalSellCount)
                .totalReversals(totalReversals)
                .totalBuyHuf(totalBuyHuf)
                .totalSellHuf(totalSellHuf)
                .netTurnoverHuf(totalSellHuf.subtract(totalBuyHuf))
                .totalHandlingFees(totalHandlingFees)
                .branchData(branchData)
                .build();
    }

    /**
     * Kezelesi dij osszesito riport
     */
    public ReportService.HandlingFeeReport generateHandlingFeeReport(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Object[]> rows = transactionRepository
                .findHandlingFeeSummaryByBranchAndDateRange(branchId, startDate, endDate);

        BigDecimal totalFees = BigDecimal.ZERO;
        long transactionsWithFee = 0;
        Map<String, BigDecimal> feesByCurrency = new LinkedHashMap<>();

        for (Object[] row : rows) {
            BigDecimal feeSum = row[2] != null ? (BigDecimal) row[2] : BigDecimal.ZERO;
            long count = row[3] != null ? ((Number) row[3]).longValue() : 0L;
            String currencyCode = (String) row[1];

            totalFees = totalFees.add(feeSum);
            transactionsWithFee += count;
            feesByCurrency.merge(currencyCode, feeSum, BigDecimal::add);
        }

        List<ReportService.CurrencyFeeData> currencyFeeList = feesByCurrency.entrySet().stream()
                .map(e -> new ReportService.CurrencyFeeData(e.getKey(), e.getValue()))
                .collect(Collectors.toList());

        return ReportService.HandlingFeeReport.builder()
                .startDate(startDate)
                .endDate(endDate)
                .generatedAt(LocalDateTime.now())
                .totalHandlingFees(totalFees)
                .transactionsWithFee((int) transactionsWithFee)
                .feesByCurrency(currencyFeeList)
                .build();
    }
}
