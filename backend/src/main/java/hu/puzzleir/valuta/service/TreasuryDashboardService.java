package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.treasury.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.security.SecurityUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private final TransactionRepository transactionRepository;

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

        // Aktuális készlet összesítés valutánként — csak a saját céghez tartozó egyenlegek.
        // FKH-029 FR-6: az értéktári (is_vault=TRUE) és a VAULT_COUNTERPARTY branch-ek
        // egyenlege NEM tartozik a pénztári valuta-összesítőbe. Ez a szűrő az FKH-029 V371
        // közvetlen következménye: a migráció után mind a 8 Értéktárnak van 23-23 (nulla)
        // cash_balance sora, és bármely jövőbeni nem-nulla értéktári egyenleg meghamisítaná
        // az Országos pénztári készletet (FK-036 hibaosztály). A vault-készlet helyes
        // megjelenítési helye a getVaultStockFlow / StockSnapshotService vault-szekciója.
        // A counterparty-kizárás azért KELL az isVault mellé, mert a VAULT_COUNTERPARTY
        // branch-ek is_vault=FALSE értékűek (FK-058 kanonikus minta, null-safe).
        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyId(companyId);
        for (CashBalance cb : allBalances) {
            if (isExcludedFromCashierTotals(cb.getBranch())) {
                continue;
            }
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

        // FKH-029 FR-6: a "pénztár-szám" ne tartalmazza az Értéktárakat és a
        // counterparty-branch-eket (MNB, bankok, Úton lévő pénztár, Többlet/Hiány) —
        // ez a FK-036 "66 helyett 65 pénztár" hibaosztály. A repo-metódus a FK-058
        // kanonikus, null-safe counterparty-kizárása; az isVault szűrés fölötte.
        long activeCashierBranchCount = branchRepository
                .findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId).stream()
                .filter(b -> !Boolean.TRUE.equals(b.getIsVault()))
                .count();

        return TreasuryDashboardDto.builder()
                .currencyTotals(currencyTotals)
                .totalBuyHuf(totalBuyHuf.setScale(2, RoundingMode.HALF_UP))
                .totalSellHuf(totalSellHuf.setScale(2, RoundingMode.HALF_UP))
                .totalFeeHuf(totalFeeHuf.setScale(2, RoundingMode.HALF_UP))
                .totalProfit(totalProfit.setScale(2, RoundingMode.HALF_UP))
                .totalTransactionCount(totalTransactions)
                .branchCount((int) activeCashierBranchCount)
                .build();
    }

    /**
     * FKH-029 FR-6: kizárandó-e a branch a PÉNZTÁRI valuta-összesítőből?
     *
     * <p>Két, egymást nem helyettesítő feltétel:
     * <ul>
     *   <li>{@code is_vault=TRUE} — Értéktár. Az FKH-029 V371 után mindegyiknek van
     *       {@code cash_balance} sora (könyvelési réteg), de az nem pénztári készlet.</li>
     *   <li>{@code branchType.code = 'VAULT_COUNTERPARTY'} — MNB, bankok, Úton lévő pénztár,
     *       Többlet/Hiány. Ezek {@code is_vault=FALSE} értékűek, ezért az {@code isVault}
     *       szűrő ŐKET NEM fogja meg (FK-058 tanulság).</li>
     * </ul>
     * Null-safe: hiányzó branch vagy branchType nem okoz NPE-t.</p>
     */
    private static boolean isExcludedFromCashierTotals(Branch branch) {
        if (branch == null) {
            return true;
        }
        if (Boolean.TRUE.equals(branch.getIsVault())) {
            return true;
        }
        var branchType = branch.getBranchType();
        return branchType != null && "VAULT_COUNTERPARTY".equals(branchType.getCode());
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
                Set<UUID> reportBranchIds = reports.stream()
                                .map(DailyReport::getBranch)
                                .filter(Objects::nonNull)
                                .map(Branch::getId)
                                .filter(Objects::nonNull)
                                .collect(Collectors.toSet());

                Map<UUID, TreasuryAggregateDto.TreasuryAggregateDtoBuilder> aggregates = new LinkedHashMap<>();
                Set<UUID> groupedBranchIds = new HashSet<>();

                for (BranchGroup group : groups) {
                        List<UUID> branchIds = group.getBranchIds();
                        if (branchIds == null || branchIds.isEmpty()) {
                                continue;
                        }

                        Set<UUID> scopedBranchIds = branchIds.stream()
                                        .filter(reportBranchIds::contains)
                                        .collect(Collectors.toCollection(LinkedHashSet::new));
                        if (scopedBranchIds.isEmpty()) {
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

                        BigDecimal buy = BigDecimal.ZERO;
                        BigDecimal sell = BigDecimal.ZERO;
                        BigDecimal fee = BigDecimal.ZERO;
                        BigDecimal profit = BigDecimal.ZERO;
                        int txCount = 0;
                        LocalDateTime groupLatest = null;

                        for (DailyReport report : reports) {
                                UUID branchId = report.getBranch().getId();
                                if (!scopedBranchIds.contains(branchId)) {
                                        continue;
                                }

                                groupedBranchIds.add(branchId);
                                buy = buy.add(nz(report.getTotalBuyHuf()));
                                sell = sell.add(nz(report.getTotalSellHuf()));
                                fee = fee.add(nz(report.getTotalFeeHuf()));
                                profit = profit.add(nz(report.getTotalProfit()));
                                txCount += report.getTransactionCount() != null ? report.getTransactionCount() : 0;
                                groupLatest = maxTimestamp(groupLatest, reportTimestamp(report));
                        }

                        builder.branchCount(scopedBranchIds.size())
                                        .totalBuyHuf(buy.setScale(2, RoundingMode.HALF_UP))
                                        .totalSellHuf(sell.setScale(2, RoundingMode.HALF_UP))
                                        .totalFeeHuf(fee.setScale(2, RoundingMode.HALF_UP))
                                        .totalProfit(profit.setScale(2, RoundingMode.HALF_UP))
                                        .transactionCount(txCount)
                                        .lastSyncedAt(groupLatest);
                }

                // Nem csoportosított irodák külön bucketben
                BigDecimal ungroupedBuy = BigDecimal.ZERO;
                BigDecimal ungroupedSell = BigDecimal.ZERO;
                BigDecimal ungroupedFee = BigDecimal.ZERO;
                BigDecimal ungroupedProfit = BigDecimal.ZERO;
                int ungroupedTx = 0;
                int ungroupedBranchCount = 0;
                LocalDateTime ungroupedLatest = null;

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
                        ungroupedLatest = maxTimestamp(ungroupedLatest, reportTimestamp(report));
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
                                        .lastSyncedAt(ungroupedLatest)
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
                Map<UUID, LocalDateTime> latestByCompany = new HashMap<>();

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

                        // Per-cég lastSyncedAt inline akkumuláció (külön stream/lista nélkül).
                        latestByCompany.merge(reportCompanyId, reportTimestamp(report),
                                        TreasuryDashboardService::maxTimestamp);
                }

                return builders.entrySet().stream()
                                .map(e -> e.getValue()
                                                .lastSyncedAt(latestByCompany.get(e.getKey()))
                                                .build())
                                .sorted(Comparator.comparing(TreasuryAggregateDto::getName, String.CASE_INSENSITIVE_ORDER))
                                .collect(Collectors.toList());
        }

    // ============ LEGACY G4: Ügyfél- és bankforgalom összesítők ============

    /**
     * Ügyfélforgalom összesítő irodánként, valutanemenként.
     * Legacy: unit5.pas SUMUGYFELFORGALOM tábla.
     */
    @Transactional(readOnly = true)
    public List<CustomerTurnoverDto> getCustomerTurnover(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        List<CustomerTurnoverDto> result = new ArrayList<>();

        for (Branch branch : branches) {
            List<Object[]> sellRows = transactionRepository.sumAmountByCurrencyAndBranchAndTypeAndDate(
                    branch.getId(), TransactionType.SELL, date);
            List<Object[]> buyRows = transactionRepository.sumAmountByCurrencyAndBranchAndTypeAndDate(
                    branch.getId(), TransactionType.BUY, date);

            Map<String, CustomerTurnoverDto> map = new LinkedHashMap<>();

            for (Object[] row : sellRows) {
                String code = (String) row[0];
                BigDecimal amount = row[1] != null ? (BigDecimal) row[1] : BigDecimal.ZERO;
                map.computeIfAbsent(code, k -> CustomerTurnoverDto.builder()
                        .branchCode(branch.getCode())
                        .branchName(branch.getName())
                        .currencyCode(k)
                        .soldAmount(BigDecimal.ZERO)
                        .boughtAmount(BigDecimal.ZERO)
                        .sellCount(0)
                        .buyCount(0)
                        .build());
                map.get(code).setSoldAmount(amount.setScale(4, RoundingMode.HALF_UP));
            }

            for (Object[] row : buyRows) {
                String code = (String) row[0];
                BigDecimal amount = row[1] != null ? (BigDecimal) row[1] : BigDecimal.ZERO;
                map.computeIfAbsent(code, k -> CustomerTurnoverDto.builder()
                        .branchCode(branch.getCode())
                        .branchName(branch.getName())
                        .currencyCode(k)
                        .soldAmount(BigDecimal.ZERO)
                        .boughtAmount(BigDecimal.ZERO)
                        .sellCount(0)
                        .buyCount(0)
                        .build());
                map.get(code).setBoughtAmount(amount.setScale(4, RoundingMode.HALF_UP));
            }

            result.addAll(map.values());
        }

        return result;
    }

    /**
     * Bankforgalom összesítő valutanemenként.
     * Legacy: unit5.pas SUMBANKFORGALOM tábla.
     */
    @Transactional(readOnly = true)
    public List<BankTurnoverDto> getBankTurnover(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<InventoryMovement> bankFlows = movementRepository.findBankFlowsByCompanyId(
                companyId, date, date);

        // Company info a branch-ön keresztül
        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        String companyCode = "UNKNOWN";
        String companyName = "Ismeretlen";
        if (!branches.isEmpty() && branches.get(0).getCompany() != null) {
            companyCode = branches.get(0).getCompany().getCode();
            companyName = branches.get(0).getCompany().getName();
        }

        Map<String, BankTurnoverDto> flowMap = new LinkedHashMap<>();
        for (InventoryMovement m : bankFlows) {
            String code = m.getCurrency().getCode();
            String finalCompanyCode = companyCode;
            String finalCompanyName = companyName;
            BankTurnoverDto flow = flowMap.computeIfAbsent(code,
                    k -> BankTurnoverDto.builder()
                            .companyCode(finalCompanyCode)
                            .companyName(finalCompanyName)
                            .currencyCode(code)
                            .withdrawnAmount(BigDecimal.ZERO)
                            .depositedAmount(BigDecimal.ZERO)
                            .netFlow(BigDecimal.ZERO)
                            .build());

            if (m.getMovementType() == MovementType.BANK_WITHDRAW) {
                flow.setWithdrawnAmount(flow.getWithdrawnAmount()
                        .add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            } else if (m.getMovementType() == MovementType.BANK_DEPOSIT) {
                flow.setDepositedAmount(flow.getDepositedAmount()
                        .add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            }
            flow.setNetFlow(flow.getWithdrawnAmount().subtract(flow.getDepositedAmount())
                    .setScale(4, RoundingMode.HALF_UP));
        }

        return new ArrayList<>(flowMap.values());
    }

        private BigDecimal nz(BigDecimal value) {
                return value != null ? value : BigDecimal.ZERO;
        }

        /**
         * Egy napi-riport "frissesség" időbélyege: a beküldés ideje, ha van,
         * különben a létrehozás ideje (a submitted_at nullable, a created_at nem).
         */
        static LocalDateTime reportTimestamp(DailyReport report) {
                if (report == null) {
                        return null;
                }
                return report.getSubmittedAt() != null ? report.getSubmittedAt() : report.getCreatedAt();
        }

        /**
         * Két időbélyeg közül a későbbit adja vissza, a {@code null} értékeket
         * kihagyva (mindkettő null → null). Inline lastSyncedAt-akkumulációhoz,
         * köztes lista/stream allokáció nélkül.
         */
        static LocalDateTime maxTimestamp(LocalDateTime a, LocalDateTime b) {
                if (a == null) {
                        return b;
                }
                if (b == null) {
                        return a;
                }
                return a.isAfter(b) ? a : b;
        }
}
