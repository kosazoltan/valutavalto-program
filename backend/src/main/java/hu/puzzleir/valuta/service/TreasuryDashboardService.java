package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.treasury.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.security.SecurityUtils;

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
        private final BranchGroupRepository branchGroupRepository;

    /**
     * Összes iroda összesítve (mai nap).
     */
    @Transactional(readOnly = true)
    public TreasuryDashboardDto getCompanyWideSummary() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, today);

        Map<String, CurrencyTotalsDto> currencyTotals = new LinkedHashMap<>();
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;
        BigDecimal totalFeeHuf = BigDecimal.ZERO;
        BigDecimal totalProfit = BigDecimal.ZERO;
        int totalTransactions = 0;

        for (DailyReport report : reports) {
            totalBuyHuf = totalBuyHuf.add(nz(report.getTotalBuyHuf()));
            totalSellHuf = totalSellHuf.add(nz(report.getTotalSellHuf()));
            totalFeeHuf = totalFeeHuf.add(nz(report.getTotalFeeHuf()));
            totalProfit = totalProfit.add(nz(report.getTotalProfit()));
            totalTransactions += report.getTransactionCount() != null ? report.getTransactionCount() : 0;
        }

        // Aktuális készlet összesítés valutánként — csak a saját céghez tartozó egyenlegek
        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyId(companyId);
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

        List<Branch> activeBranches = branchRepository.findByCompanyId(companyId);

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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, today);

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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<InventoryMovement> bankFlows = movementRepository.findBankFlowsByCompanyId(companyId, startDate, endDate);

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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        List<Branch> activeBranches = branchRepository.findByCompanyId(companyId);
        List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, today);

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

        /**
         * Körzet (BranchGroup) szintű összesítés napi riportok alapján.
         */
        @Transactional(readOnly = true)
        public List<TreasuryAggregateDto> getBranchGroupSummary(LocalDate date) {
                UUID companyId = SecurityUtils.getCurrentCompanyId();
                LocalDate targetDate = date != null ? date : LocalDate.now();
                List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, targetDate);
                List<BranchGroup> groups = branchGroupRepository.findByIsActiveTrue();

                Map<UUID, TreasuryAggregateDto.TreasuryAggregateDtoBuilder> aggregates = new LinkedHashMap<>();
                Set<UUID> groupedBranchIds = new HashSet<>();

                for (BranchGroup group : groups) {
                        List<UUID> branchIds = group.getBranchIds();
                        if (branchIds == null || branchIds.isEmpty()) {
                                continue;
                        }

                        TreasuryAggregateDto.TreasuryAggregateDtoBuilder builder = aggregates.computeIfAbsent(group.getId(),
                                        id -> TreasuryAggregateDto.builder()
                                                        .id(group.getId().toString())
                                                        .code(group.getCode())
                                                        .name(group.getName())
                                                        .totalBuyHuf(BigDecimal.ZERO)
                                                        .totalSellHuf(BigDecimal.ZERO)
                                                        .totalFeeHuf(BigDecimal.ZERO)
                                                        .totalProfit(BigDecimal.ZERO)
                                                        .transactionCount(0)
                                                        .branchCount(0));

                        int branchCount = 0;
                        BigDecimal buy = BigDecimal.ZERO;
                        BigDecimal sell = BigDecimal.ZERO;
                        BigDecimal fee = BigDecimal.ZERO;
                        BigDecimal profit = BigDecimal.ZERO;
                        int txCount = 0;

                        for (DailyReport report : reports) {
                                UUID branchId = report.getBranch().getId();
                                if (!branchIds.contains(branchId)) {
                                        continue;
                                }

                                groupedBranchIds.add(branchId);
                                branchCount++;
                                buy = buy.add(nz(report.getTotalBuyHuf()));
                                sell = sell.add(nz(report.getTotalSellHuf()));
                                fee = fee.add(nz(report.getTotalFeeHuf()));
                                profit = profit.add(nz(report.getTotalProfit()));
                                txCount += report.getTransactionCount() != null ? report.getTransactionCount() : 0;
                        }

                        builder.branchCount(branchCount)
                                        .totalBuyHuf(buy.setScale(2, RoundingMode.HALF_UP))
                                        .totalSellHuf(sell.setScale(2, RoundingMode.HALF_UP))
                                        .totalFeeHuf(fee.setScale(2, RoundingMode.HALF_UP))
                                        .totalProfit(profit.setScale(2, RoundingMode.HALF_UP))
                                        .transactionCount(txCount);
                }

                // Nem csoportosított irodák külön bucketben
                BigDecimal ungroupedBuy = BigDecimal.ZERO;
                BigDecimal ungroupedSell = BigDecimal.ZERO;
                BigDecimal ungroupedFee = BigDecimal.ZERO;
                BigDecimal ungroupedProfit = BigDecimal.ZERO;
                int ungroupedTx = 0;
                int ungroupedBranchCount = 0;

                for (DailyReport report : reports) {
                        UUID branchId = report.getBranch().getId();
                        if (groupedBranchIds.contains(branchId)) {
                                continue;
                        }
                        ungroupedBranchCount++;
                        ungroupedBuy = ungroupedBuy.add(nz(report.getTotalBuyHuf()));
                        ungroupedSell = ungroupedSell.add(nz(report.getTotalSellHuf()));
                        ungroupedFee = ungroupedFee.add(nz(report.getTotalFeeHuf()));
                        ungroupedProfit = ungroupedProfit.add(nz(report.getTotalProfit()));
                        ungroupedTx += report.getTransactionCount() != null ? report.getTransactionCount() : 0;
                }

                List<TreasuryAggregateDto> result = aggregates.values().stream()
                                .map(TreasuryAggregateDto.TreasuryAggregateDtoBuilder::build)
                                .sorted(Comparator.comparing(TreasuryAggregateDto::getName, String.CASE_INSENSITIVE_ORDER))
                                .collect(Collectors.toList());

                if (ungroupedBranchCount > 0) {
                        result.add(TreasuryAggregateDto.builder()
                                        .id("UNGROUPED")
                                        .code("UNGROUPED")
                                        .name("Nem csoportositott irodak")
                                        .totalBuyHuf(ungroupedBuy.setScale(2, RoundingMode.HALF_UP))
                                        .totalSellHuf(ungroupedSell.setScale(2, RoundingMode.HALF_UP))
                                        .totalFeeHuf(ungroupedFee.setScale(2, RoundingMode.HALF_UP))
                                        .totalProfit(ungroupedProfit.setScale(2, RoundingMode.HALF_UP))
                                        .transactionCount(ungroupedTx)
                                        .branchCount(ungroupedBranchCount)
                                        .build());
                }

                return result;
        }

        /**
         * KFT/cég (Company) szintű összesítés napi riportok alapján.
         */
        @Transactional(readOnly = true)
        public List<TreasuryAggregateDto> getCompanySummary(LocalDate date) {
                UUID companyId = SecurityUtils.getCurrentCompanyId();
                LocalDate targetDate = date != null ? date : LocalDate.now();
                List<DailyReport> reports = dailyReportRepository.findByCompanyIdAndReportDate(companyId, targetDate);

                Map<UUID, TreasuryAggregateDto.TreasuryAggregateDtoBuilder> builders = new LinkedHashMap<>();
                Map<UUID, Set<UUID>> branchSets = new HashMap<>();

                for (DailyReport report : reports) {
                        Branch branch = report.getBranch();
                        Company company = branch.getCompany();
                        UUID reportCompanyId = company.getId();

                        TreasuryAggregateDto.TreasuryAggregateDtoBuilder builder = builders.computeIfAbsent(reportCompanyId,
                                        id -> TreasuryAggregateDto.builder()
                                                        .id(reportCompanyId.toString())
                                                        .code(company.getCode())
                                                        .name(company.getName())
                                                        .totalBuyHuf(BigDecimal.ZERO)
                                                        .totalSellHuf(BigDecimal.ZERO)
                                                        .totalFeeHuf(BigDecimal.ZERO)
                                                        .totalProfit(BigDecimal.ZERO)
                                                        .transactionCount(0)
                                                        .branchCount(0));

                        TreasuryAggregateDto current = builder.build();
                        builder.totalBuyHuf(current.getTotalBuyHuf().add(nz(report.getTotalBuyHuf())).setScale(2, RoundingMode.HALF_UP))
                                        .totalSellHuf(current.getTotalSellHuf().add(nz(report.getTotalSellHuf())).setScale(2, RoundingMode.HALF_UP))
                                        .totalFeeHuf(current.getTotalFeeHuf().add(nz(report.getTotalFeeHuf())).setScale(2, RoundingMode.HALF_UP))
                                        .totalProfit(current.getTotalProfit().add(nz(report.getTotalProfit())).setScale(2, RoundingMode.HALF_UP))
                                        .transactionCount(current.getTransactionCount() + (report.getTransactionCount() != null ? report.getTransactionCount() : 0));

                        branchSets.computeIfAbsent(reportCompanyId, k -> new HashSet<>()).add(branch.getId());
                        builder.branchCount(branchSets.get(reportCompanyId).size());
                }

                return builders.values().stream()
                                .map(TreasuryAggregateDto.TreasuryAggregateDtoBuilder::build)
                                .sorted(Comparator.comparing(TreasuryAggregateDto::getName, String.CASE_INSENSITIVE_ORDER))
                                .collect(Collectors.toList());
        }

        private BigDecimal nz(BigDecimal value) {
                return value != null ? value : BigDecimal.ZERO;
        }
}
