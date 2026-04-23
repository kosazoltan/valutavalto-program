package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StockSnapshotService {

    private final BranchRepository branchRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final WuBalanceRepository wuBalanceRepository;
    private final ReservationRepository reservationRepository;
    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;

    public static final List<String> CURRENCY_CODES = List.of(
            "AUD", "BAM", "BGN", "BRL", "CAD", "CHF",
            "CNY", "CZK", "DKK", "EUR", "GBP", "HRK",
            "HUF", "ILS", "JPY", "MXN", "NOK", "NZD",
            "PLN", "RON", "RSD", "RUB", "SEK", "THB",
            "TRY", "UAH", "USD"
    );

    public static final Map<String, String> REGION_NAMES = new LinkedHashMap<>() {{
        put("10", "SZEKSZARD");
        put("20", "SZEGED");
        put("40", "KECSKEMET");
        put("50", "DEBRECEN");
        put("63", "NYIREGYHAZA");
        put("75", "BEKESCSABA");
        put("120", "PECS");
        put("145", "KAPOSVAR");
    }};

    @Transactional(readOnly = true)
    public StockSnapshotDto getFullSnapshot(UUID companyId) {
        LocalDateTime snapshotTime = LocalDateTime.now();
        LocalDate today = LocalDate.now();

        String companyName = companyRepository.findById(companyId).map(hu.puzzleir.valuta.entity.Company::getName).orElse(null);

        List<Branch> branches = branchRepository.findActiveWithRegionByCompanyId(companyId);

        if (branches.isEmpty()) {
            return StockSnapshotDto.builder()
                    .snapshotTime(snapshotTime)
                    .companyId(companyId)
                    .companyName(companyName)
                    .regions(List.of())
                    .companyTotals(buildCompanyTotalsWithFallback(companyId, List.of()))  // Fix #154 extended
                    .build();
        }

        // Batch queries
        List<String> branchIdStrings = branches.stream()
                .map(b -> b.getId().toString()).collect(Collectors.toList());
        List<UUID> branchUuids = branches.stream()
                .map(Branch::getId).collect(Collectors.toList());

        Map<String, List<CurrencyStock>> stockByBranch = currencyStockRepository
                .findAllByBranchIds(branchIdStrings).stream()
                .collect(Collectors.groupingBy(CurrencyStock::getEntityId));

        Map<UUID, WuBalance> wuByBranch = wuBalanceRepository
                .findByBranchIdsAndCompanyId(branchUuids, companyId).stream()
                .collect(Collectors.toMap(wb -> wb.getBranch().getId(), wb -> wb));

        // Build per-branch snapshots grouped by region
        Map<String, List<BranchSnapshotDto>> branchesByRegion = new LinkedHashMap<>();
        for (Branch branch : branches) {
            BranchSnapshotDto branchDto = buildBranchSnapshot(branch, stockByBranch, wuByBranch, today);
            branchesByRegion.computeIfAbsent(branch.getRegionCode(), k -> new ArrayList<>()).add(branchDto);
        }

        // Region aggregation
        List<RegionSnapshotDto> regions = new ArrayList<>();
        for (Map.Entry<String, String> entry : REGION_NAMES.entrySet()) {
            List<BranchSnapshotDto> regionBranches = branchesByRegion.getOrDefault(entry.getKey(), List.of());
            if (regionBranches.isEmpty()) continue;
            regions.add(RegionSnapshotDto.builder()
                    .regionCode(entry.getKey())
                    .regionName(entry.getValue())
                    .branches(regionBranches)
                    .totals(aggregateTotals(regionBranches))
                    .build());
        }

        // Company totals - Codex P2 #157 fix:
        // branchesByRegion.values() MINDEN branch-et tartalmaz (ismeretlen region-code is),
        // regions.flatMap(branches) viszont CSAK a REGION_NAMES-ben felsorolt region-code-uakat.
        // Igy az ismeretlen region-u branch-ek stockjai nem vesznek el a companyTotals fallback-bol.
        List<BranchSnapshotDto> allBranches = branchesByRegion.values().stream()
                .flatMap(List::stream).collect(Collectors.toList());

        return StockSnapshotDto.builder()
                .snapshotTime(snapshotTime)
                .companyId(companyId)
                .companyName(companyName)
                .regions(regions)
                .companyTotals(buildCompanyTotalsWithFallback(companyId, allBranches))
                .build();
    }

    private BranchSnapshotDto buildBranchSnapshot(
            Branch branch, Map<String, List<CurrencyStock>> stockByBranch,
            Map<UUID, WuBalance> wuByBranch, LocalDate today) {

        UUID branchId = branch.getId();
        String branchIdStr = branchId.toString();

        List<CurrencyStock> stocks = stockByBranch.getOrDefault(branchIdStr, List.of());
        Map<String, CurrencyStock> stockMap = stocks.stream()
                .collect(Collectors.toMap(CurrencyStock::getCurrencyCode, s -> s));

        Map<String, Long> reservedByCode = new HashMap<>();
        for (Object[] row : reservationRepository.getReservedStockByBranch(branchId)) {
            reservedByCode.put((String) row[0], ((BigDecimal) row[1]).longValue());
        }

        List<CurrencyStockDetailDto> currencies = new ArrayList<>();
        LocalDateTime lastUpdated = null;

        for (String code : CURRENCY_CODES) {
            CurrencyStock cs = stockMap.get(code);
            long stock = 0, stockHuf = 0;
            if (cs != null) {
                stock = cs.getQuantity().longValue();
                stockHuf = cs.getQuantity().multiply(cs.getWeightedAvgCost()).longValue();
                if (cs.getLastUpdated() != null && (lastUpdated == null || cs.getLastUpdated().isAfter(lastUpdated))) {
                    lastUpdated = cs.getLastUpdated();
                }
            }

            BigDecimal dailyBuy = transactionRepository.sumDailyTurnoverByCurrency(branchId, today, TransactionType.BUY, code);
            BigDecimal dailySell = transactionRepository.sumDailyTurnoverByCurrency(branchId, today, TransactionType.SELL, code);

            currencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(stock).stockHuf(stockHuf)
                    .dailyBuy(dailyBuy != null ? dailyBuy.longValue() : 0)
                    .dailyBuyHuf(0)
                    .dailySell(dailySell != null ? dailySell.longValue() : 0)
                    .dailySellHuf(0)
                    .build());
        }

        WuBalance wu = wuByBranch.get(branchId);
        WuBalanceDetailDto wuDto = WuBalanceDetailDto.builder()
                .wuUsd(wu != null ? wu.getUsdBalance().longValue() : 0)
                .wuHuf(wu != null ? wu.getHufBalance().longValue() : 0)
                .build();

        List<ReservationSummaryDto> reservations = reservedByCode.entrySet().stream()
                .map(e -> ReservationSummaryDto.builder().currencyCode(e.getKey()).totalAmount(e.getValue()).build())
                .sorted(Comparator.comparing(ReservationSummaryDto::getCurrencyCode))
                .collect(Collectors.toList());

        return BranchSnapshotDto.builder()
                .branchId(branchId).branchName(branch.getName()).branchCode(branch.getCode())
                .lastUpdated(lastUpdated).currencies(currencies).wuBalance(wuDto).reservations(reservations)
                .build();
    }

    private BranchStockTotalsDto aggregateTotals(List<BranchSnapshotDto> branches) {
        if (branches.isEmpty()) return createEmptyTotals();

        Map<String, long[]> totals = new LinkedHashMap<>();
        for (String code : CURRENCY_CODES) totals.put(code, new long[6]);

        long totalWuUsd = 0, totalWuHuf = 0, totalVat = 0, totalFee = 0, totalEcom = 0;
        Map<String, Long> totalReservations = new HashMap<>();

        for (BranchSnapshotDto branch : branches) {
            for (CurrencyStockDetailDto c : branch.getCurrencies()) {
                long[] t = totals.get(c.getCurrencyCode());
                if (t != null) {
                    t[0] += c.getStock(); t[1] += c.getStockHuf();
                    t[2] += c.getDailyBuy(); t[3] += c.getDailyBuyHuf();
                    t[4] += c.getDailySell(); t[5] += c.getDailySellHuf();
                }
            }
            WuBalanceDetailDto wu = branch.getWuBalance();
            if (wu != null) {
                totalWuUsd += wu.getWuUsd(); totalWuHuf += wu.getWuHuf();
                totalVat += wu.getVat(); totalFee += wu.getHandlingFee(); totalEcom += wu.getECommerce();
            }
            for (ReservationSummaryDto r : branch.getReservations())
                totalReservations.merge(r.getCurrencyCode(), r.getTotalAmount(), Long::sum);
        }

        return BranchStockTotalsDto.builder()
                .currencies(CURRENCY_CODES.stream().map(code -> {
                    long[] t = totals.get(code);
                    return CurrencyStockDetailDto.builder().currencyCode(code)
                            .stock(t[0]).stockHuf(t[1]).dailyBuy(t[2]).dailyBuyHuf(t[3]).dailySell(t[4]).dailySellHuf(t[5]).build();
                }).collect(Collectors.toList()))
                .wuBalance(WuBalanceDetailDto.builder().wuUsd(totalWuUsd).wuHuf(totalWuHuf).vat(totalVat).handlingFee(totalFee).eCommerce(totalEcom).build())
                .reservations(totalReservations.entrySet().stream()
                        .map(e -> ReservationSummaryDto.builder().currencyCode(e.getKey()).totalAmount(e.getValue()).build())
                        .sorted(Comparator.comparing(ReservationSummaryDto::getCurrencyCode)).collect(Collectors.toList()))
                .build();
    }

    private BranchStockTotalsDto createEmptyTotals() {
        return BranchStockTotalsDto.builder()
                .currencies(CURRENCY_CODES.stream().map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build()).collect(Collectors.toList()))
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of()).build();
    }

    private BranchStockTotalsDto buildCompanyTotalsWithFallback(UUID companyId, List<BranchSnapshotDto> branchSnapshots) {
        List<Object[]> rows = currencyStockRepository.sumCompanyLevelByCurrency(companyId);
        // Fix #156: ures DB agg eseten fallback branch-aggregaciora (test-kompat + ures DB)
        if (rows == null || rows.isEmpty()) {
            return (branchSnapshots == null || branchSnapshots.isEmpty()) ? createEmptyTotals() : aggregateTotals(branchSnapshots);
        }
        Map<String, CurrencyStockDetailDto> byCode = new LinkedHashMap<>();
        for (String code : CURRENCY_CODES) {
            byCode.put(code, CurrencyStockDetailDto.builder().currencyCode(code).build());
        }
        for (Object[] row : rows) {
            String code = (String) row[0];
            BigDecimal qty = row[1] != null ? (BigDecimal) row[1] : BigDecimal.ZERO;
            BigDecimal huf = row[2] != null ? (BigDecimal) row[2] : BigDecimal.ZERO;
            byCode.put(code, CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(qty.longValue())
                    .stockHuf(huf.longValue())
                    .build());
        }
        return BranchStockTotalsDto.builder()
                .currencies(new ArrayList<>(byCode.values()))
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }
}
