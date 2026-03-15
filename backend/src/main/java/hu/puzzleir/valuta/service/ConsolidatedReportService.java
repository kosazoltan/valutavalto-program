package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.BranchDailyReportDto;
import hu.puzzleir.valuta.dto.ertektar.ConsolidatedReportResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ConsolidatedReportService {

    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;

    @Transactional(readOnly = true)
    public ConsolidatedReportResponseDto getConsolidatedReport(LocalDate dateFrom, LocalDate dateTo) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        List<BranchDailyReportDto> branchReports = new ArrayList<>();

        int totalTransactions = 0, totalSellCount = 0, totalBuyCount = 0;
        long totalHufTurnover = 0, totalFees = 0;

        for (Branch branch : branches) {
            // Count sells and buys for date range
            int sellCount = transactionRepository.countByBranchIdAndTransactionTypeAndTransactionDateBetween(
                    branch.getId(), TransactionType.SELL, dateFrom, dateTo);
            int buyCount = transactionRepository.countByBranchIdAndTransactionTypeAndTransactionDateBetween(
                    branch.getId(), TransactionType.BUY, dateFrom, dateTo);

            // Sum HUF volumes
            BigDecimal sellVolume = transactionRepository.sumHufAmountByBranchIdAndTypeAndDateBetween(
                    branch.getId(), TransactionType.SELL, dateFrom, dateTo);
            BigDecimal buyVolume = transactionRepository.sumHufAmountByBranchIdAndTypeAndDateBetween(
                    branch.getId(), TransactionType.BUY, dateFrom, dateTo);
            BigDecimal feeSum = transactionRepository.sumFeesByBranchIdAndDateBetween(
                    branch.getId(), dateFrom, dateTo);

            long sellHuf = sellVolume != null ? sellVolume.longValue() : 0;
            long buyHuf = buyVolume != null ? buyVolume.longValue() : 0;
            long fees = feeSum != null ? feeSum.longValue() : 0;

            if (sellCount + buyCount == 0) continue; // Skip branches with no transactions

            BranchDailyReportDto report = BranchDailyReportDto.builder()
                    .branchCode(branch.getCode())
                    .branchName(branch.getName())
                    .date(dateFrom.toString())
                    .sellCount(sellCount)
                    .buyCount(buyCount)
                    .totalTransactions(sellCount + buyCount)
                    .sellHufVolume(sellHuf)
                    .buyHufVolume(buyHuf)
                    .totalHufTurnover(sellHuf + buyHuf)
                    .totalFees(fees)
                    .build();

            branchReports.add(report);

            totalTransactions += sellCount + buyCount;
            totalSellCount += sellCount;
            totalBuyCount += buyCount;
            totalHufTurnover += sellHuf + buyHuf;
            totalFees += fees;
        }

        ConsolidatedReportResponseDto.TotalsDto totals = ConsolidatedReportResponseDto.TotalsDto.builder()
                .totalTransactions(totalTransactions)
                .totalSellCount(totalSellCount)
                .totalBuyCount(totalBuyCount)
                .totalHufTurnover(totalHufTurnover)
                .totalFees(totalFees)
                .build();

        return ConsolidatedReportResponseDto.builder()
                .dateFrom(dateFrom.toString())
                .dateTo(dateTo.toString())
                .branches(branchReports)
                .totals(totals)
                .build();
    }
}
