package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.treasury.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Központi összesítő dashboard service.
 *
 * Legacy: SZERVER — bankforg.dll, keszletdisp.dll, forgalomdisp.dll, zarasctrl.dll
 */
@Service
@RequiredArgsConstructor
public class TreasuryDashboardService {

    private final DailyReportRepository dailyReportRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final InventoryMovementRepository movementRepository;
    private final BranchRepository branchRepository;

    /**
     * Összes iroda összesítve (mai nap).
     */
    @Transactional(readOnly = true)
    public TreasuryDashboardDto getCompanyWideSummary() {
        LocalDate today = LocalDate.now();
        List<DailyReport> reports = dailyReportRepository.findAllByReportDate(today);

        Map<String, CurrencyTotalsDto> currencyTotals = new LinkedHashMap<>();
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalFeeHuf = BigDecimal.ZERO;
        BigDecimal totalProfit = BigDecimal.ZERO;
        int totalTransactions = 0;

        for (DailyReport report : reports) {
            totalBuyHuf = totalBuyHuf.add(report.getTotalBuyHuf());
            totalSellHuf = totalSellHuf.add(report.getTotalSellHuf());
            totalFeeHuf = totalFeeHuf.add(report.getTotalFeeHuf());
            totalProfit = totalProfit.add(report.getTotalProfit());
            totalTransactions += report.getTransactionCount();
        }

        // Aktuális készlet összesítés valutánként
        List<CashBalance> allBalances = cashBalanceRepository.findAll();
        for (CashBalance cb : allBalances) {
            String code = cb.getCurrency().getCode();
            CurrencyTotalsDto totals = currencyTotals.computeIfAbsent(code,
                    k -> CurrencyTotalsDto.builder()
                            .currencyCode(code)
                            .currencyName(cb.getCurrency().getName())
                            .totalStock(BigDecimal.ZERO)
                            .totalBuyHuf(BigDecimal.ZERO)
                            .totalSellHuf(BigDecimal.ZERO)
                            .build());
            totals.setTotalStock(totals.getTotalStock()
                    .add(cb.getCurrentBalance()).setScale(4, RoundingMode.HALF_UP));
        }

        List<Branch> activeBranches = branchRepository.findByIsActiveTrue();

        return TreasuryDashboardDto.builder()
                .currencyTotals(currencyTotals)
                .totalBuyHuf(totalBuyHuf.setScale(2, RoundingMode.HALF_UP))
                .totalSellHuf(totalSellHuf.setScale(2, RoundingMode.HALF_UP))
                .totalFeeHuf(totalFeeHuf.setScale(2, RoundingMode.HALF_UP))
                .totalProfit(totalProfit.setScale(2, RoundingMode.HALF_UP))
                .totalTransactionCount(totalTransactions)
                .branchCount(activeBranches.size())
                .build();
    }

    /**
     * Irodák rangsorolása forgalom szerint (mai nap).
     */
    @Transactional(readOnly = true)
    public List<BranchComparisonDto> getBranchComparison() {
        LocalDate today = LocalDate.now();
        List<DailyReport> reports = dailyReportRepository.findAllByReportDate(today);

        return reports.stream()
                .map(r -> BranchComparisonDto.builder()
                        .branchId(r.getBranch().getId().toString())
                        .branchCode(r.getBranch().getCode())
                        .branchName(r.getBranch().getName())
                        .totalBuyHuf(r.getTotalBuyHuf().setScale(2, RoundingMode.HALF_UP))
                        .totalSellHuf(r.getTotalSellHuf().setScale(2, RoundingMode.HALF_UP))
                        .totalFeeHuf(r.getTotalFeeHuf().setScale(2, RoundingMode.HALF_UP))
                        .totalProfit(r.getTotalProfit().setScale(2, RoundingMode.HALF_UP))
                        .transactionCount(r.getTransactionCount())
                        .build())
                .sorted(Comparator.comparing(BranchComparisonDto::getTotalProfit).reversed())
                .collect(Collectors.toList());
    }

    /**
     * Bank be/ki forgalom összesítés.
     */
    @Transactional(readOnly = true)
    public List<BankFlowDto> getBankFlowSummary(LocalDate startDate, LocalDate endDate) {
        List<InventoryMovement> bankFlows = movementRepository.findBankFlows(startDate, endDate);

        Map<String, BankFlowDto> flowMap = new LinkedHashMap<>();
        for (InventoryMovement m : bankFlows) {
            String code = m.getCurrency().getCode();
            BankFlowDto flow = flowMap.computeIfAbsent(code,
                    k -> BankFlowDto.builder()
                            .currencyCode(code)
                            .currencyName(m.getCurrency().getName())
                            .totalWithdraw(BigDecimal.ZERO)
                            .totalDeposit(BigDecimal.ZERO)
                            .netFlow(BigDecimal.ZERO)
                            .build());

            if (m.getMovementType() == MovementType.BANK_WITHDRAW) {
                flow.setTotalWithdraw(flow.getTotalWithdraw()
                        .add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            } else if (m.getMovementType() == MovementType.BANK_DEPOSIT) {
                flow.setTotalDeposit(flow.getTotalDeposit()
                        .add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            }
            flow.setNetFlow(flow.getTotalWithdraw().subtract(flow.getTotalDeposit())
                    .setScale(4, RoundingMode.HALF_UP));
        }

        return new ArrayList<>(flowMap.values());
    }

    /**
     * Melyik iroda zárta le a napot (DailyReport.submitted).
     */
    @Transactional(readOnly = true)
    public List<SubmissionStatusDto> getSubmissionStatus() {
        LocalDate today = LocalDate.now();
        List<Branch> activeBranches = branchRepository.findByIsActiveTrue();
        List<DailyReport> reports = dailyReportRepository.findAllByReportDate(today);

        Map<String, DailyReport> reportMap = reports.stream()
                .collect(Collectors.toMap(
                        r -> r.getBranch().getId().toString(),
                        r -> r,
                        (a, b) -> a));

        return activeBranches.stream()
                .map(branch -> {
                    DailyReport report = reportMap.get(branch.getId().toString());
                    return SubmissionStatusDto.builder()
                            .branchId(branch.getId().toString())
                            .branchCode(branch.getCode())
                            .branchName(branch.getName())
                            .submitted(report != null && Boolean.TRUE.equals(report.getSubmitted()))
                            .submittedAt(report != null && report.getSubmittedAt() != null
                                    ? report.getSubmittedAt().toString() : null)
                            .build();
                })
                .collect(Collectors.toList());
    }
}
