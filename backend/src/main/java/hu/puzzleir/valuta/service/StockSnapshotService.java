package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.util.HungarianRounding;
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
    private final TransactionLineRepository transactionLineRepository;
    private final CompanyRepository companyRepository;
    private final CurrencyRepository currencyRepository;

    // FK-006 follow-up (Kasza Helga visszajelzés a telepítés után): a snapshot valutalistája a
    // KÖZPONTI valutanem-törzsből (currency tábla, is_active + display_order) jön, NEM hardkódolt
    // listából. A FK-003/004 spec szerint a HUF MINDIG az utolsó sorban. Inaktív valuta, amelyhez
    // még tartozik fizikai készlet (leftover), a snapshot végén szerepel (alfabetikusan rendezve),
    // hogy az MNB-jellegű készletriport ne mutasson alá (a többi felület — Országos készlet,
    // Aktuális árfolyamok — szigorúan csak az aktív törzset jeleníti meg).

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

    /**
     * A `branch.region` (text) normalizálása a REGION_NAMES ASCII-nagybetűs értékeihez (SZEGED,
     * BEKESCSABA, ...). A seedelt adat már ASCII-nagybetűs (V145/V254), de defenzíven az ékezeteket
     * is leképezzük, hogy egy esetleges 'Szeged'/'Nyíregyháza' érték is helyes körzetbe kerüljön.
     */
    private static String normalizeRegion(String region) {
        if (region == null) {
            return null;
        }
        String s = region.trim().toUpperCase(java.util.Locale.forLanguageTag("hu"));
        return s.replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O")
                .replace("Ö", "O").replace("Ő", "O").replace("Ú", "U").replace("Ü", "U").replace("Ű", "U");
    }

    @Transactional(readOnly = true)
    public StockSnapshotDto getFullSnapshot(UUID companyId) {
        LocalDateTime snapshotTime = LocalDateTime.now();
        LocalDate today = LocalDate.now();

        String companyName = companyRepository.findById(companyId).map(hu.puzzleir.valuta.entity.Company::getName).orElse(null);

        // FK-019: a területi füleken az értéktár MELLETT az összes hozzá tartozó pénztár is megjelenjen.
        // KORÁBBAN a findActiveWithRegionByCompanyId CSAK a regionCode<>NULL irodákat adta vissza — a
        // pénztárak regionCode-ja NULL (V250), így kimaradtak. Most az ÖSSZES aktív, valódi irodát
        // (értéktár + pénztár) kérjük, a virtuális partnereket (VAULT_COUNTERPARTY) kizárva.
        // A területi csoportosítás a `region` (text) mezőn megy (lentebb) — a vault_territory_id a
        // seed-állapotban NULL (V288 NO-OP), ezért NEM arra csoportosítunk.
        List<Branch> branches = new ArrayList<>(
                branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId));

        // FR-02: a területen belül az értéktár (isVault=true) az ELSŐ oszlop, utána a pénztárak névsorban.
        branches.sort(
                Comparator.comparing((Branch b) -> Boolean.TRUE.equals(b.getIsVault()), Comparator.reverseOrder())
                        .thenComparing(b -> b.getName() == null ? "" : b.getName(), String.CASE_INSENSITIVE_ORDER));

        if (branches.isEmpty()) {
            List<Object[]> companyRowsEmpty = currencyStockRepository.sumCompanyLevelByCurrency(companyId);
            List<String> codesEmpty = resolveCurrencyCodes(Map.of(), companyRowsEmpty);
            return StockSnapshotDto.builder()
                    .snapshotTime(snapshotTime)
                    .companyId(companyId)
                    .companyName(companyName)
                    .regions(List.of())
                    .companyTotals(buildCompanyTotalsWithFallback(companyId, List.of(), codesEmpty, companyRowsEmpty))
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

        // Company-szintű leftover (orphan-zombie kódok, amelyek branch-szinten nem mutatkoznak)
        List<Object[]> companyRows = currencyStockRepository.sumCompanyLevelByCurrency(companyId);

        // FK-006: EGYETLEN per-request kódlista (aktív törzs + branch leftover + company-level leftover).
        // Önkonzisztens — minden snapshot DTO array (branch / region / company) ugyanezzel a kódlistával
        // épül, így az index-alapú leképzések (Excel-export) nem ütköznek IOOBE-be.
        List<String> codes = resolveCurrencyCodes(stockByBranch, companyRows);

        // Build per-branch snapshots grouped by region.
        // FK-019: az értéktárnak van regionCode-ja (KESZLEX 10/20/...), a pénztárnak NINCS (NULL),
        // viszont a `region` (text, pl. 'SZEGED') mind a kettőnél kitöltött (V145 pénztár, V254 értéktár)
        // és közvetlenül egyezik a REGION_NAMES értékeivel → a pénztárt a region-névből képzett
        // regionCode-ra soroljuk. A besorolatlan (egyik mezővel sem rendelkező) irodák a null kulcs alá
        // kerülnek: a területi füleken nem jelennek meg, de a cégösszesítőből nem esnek ki.
        Map<String, String> regionNameToCode = new HashMap<>();
        REGION_NAMES.forEach((code, name) -> regionNameToCode.put(name, code));

        Map<String, List<BranchSnapshotDto>> branchesByRegion = new LinkedHashMap<>();
        for (Branch branch : branches) {
            BranchSnapshotDto branchDto = buildBranchSnapshot(branch, stockByBranch, wuByBranch, today, codes);
            String regionCode = branch.getRegionCode();
            if (regionCode == null && branch.getRegion() != null) {
                regionCode = regionNameToCode.get(normalizeRegion(branch.getRegion()));
            }
            branchesByRegion.computeIfAbsent(regionCode, k -> new ArrayList<>()).add(branchDto);
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
                    .totals(aggregateTotals(regionBranches, codes))
                    .lastSyncedAt(latestLastUpdated(regionBranches))
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
                .companyTotals(buildCompanyTotalsWithFallback(companyId, allBranches, codes, companyRows))
                .build();
    }

    /**
     * A snapshot-hoz tartozó valutakód-lista a FK-006 elv szerint, EGYETLEN igazságforrással
     * (önkonzisztens minden DTO array-re, hogy az index-alapú leképzés ne csorduljon túl):
     *  1) Aktív törzs (currency.is_active=true), display_order ASC szerint;
     *  2) a HUF a végére mozgatva (FK-003/004 spec — Kasza Helga); ha HUF nincs az aktív
     *     törzsben (degenerált eset), akkor is kényszerítjük a végére, így a HUF sosem kerül
     *     a leftover-blokkba.
     *  3) a végén alfabetikus sorrendben azok az INAKTÍV valuták, amelyeknek nem-nulla a fizikai
     *     készlete (branch-szintű VAGY company-szintű forrásból — MNB-riport ne mutasson alá).
     */
    List<String> resolveCurrencyCodes(Map<String, List<CurrencyStock>> stockByBranch,
                                      List<Object[]> companyLevelRows) {
        List<Currency> active = currencyRepository.findAllActiveOrdered();
        List<String> activeNonHuf = new ArrayList<>();
        Set<String> activeSet = new LinkedHashSet<>();
        for (Currency c : active) {
            String code = c.getCode();
            if (code == null) continue;
            activeSet.add(code);
            if (!"HUF".equals(code)) activeNonHuf.add(code);
        }
        activeSet.add("HUF"); // HUF mindig az aktív halmaz része a leftover-szűréshez

        // Nem-nulla leftover inaktívak — branch-szintű forrás
        Set<String> leftover = new TreeSet<>();
        if (stockByBranch != null) {
            for (List<CurrencyStock> stocks : stockByBranch.values()) {
                if (stocks == null) continue;
                for (CurrencyStock cs : stocks) {
                    String code = cs.getCurrencyCode();
                    if (code == null || activeSet.contains(code)) continue;
                    BigDecimal q = cs.getQuantity();
                    if (q != null && q.signum() != 0) leftover.add(code);
                }
            }
        }
        // Company-szintű forrás (orphan-zombie kódok, amelyek branch-szinten nem mutatkoznak)
        if (companyLevelRows != null) {
            for (Object[] row : companyLevelRows) {
                if (row == null || row.length < 2) continue;
                String code = (String) row[0];
                BigDecimal qty = row[1] != null ? (BigDecimal) row[1] : BigDecimal.ZERO;
                if (code != null && !activeSet.contains(code) && qty.signum() != 0) {
                    leftover.add(code);
                }
            }
        }

        // Codex P2 (c9c74930): a FK-003/004 spec szerint a HUF MINDIG ABSZOLÚT az utolsó sor.
        // Sorrend: aktív (HUF nélkül) → inaktív leftover (alfabetikus) → HUF a legvégén.
        List<String> result = new ArrayList<>(activeNonHuf);
        result.addAll(leftover);
        result.add("HUF");
        return result;
    }

    /** Null-safe BigDecimal → long (a COALESCE miatt elvileg sosem null, de defenzív). */
    private static long nz(BigDecimal v) {
        return v != null ? v.longValue() : 0L;
    }

    private BranchSnapshotDto buildBranchSnapshot(
            Branch branch, Map<String, List<CurrencyStock>> stockByBranch,
            Map<UUID, WuBalance> wuByBranch, LocalDate today, List<String> codes) {

        UUID branchId = branch.getId();
        String branchIdStr = branchId.toString();

        List<CurrencyStock> stocks = stockByBranch.getOrDefault(branchIdStr, List.of());
        Map<String, CurrencyStock> stockMap = stocks.stream()
                .collect(Collectors.toMap(CurrencyStock::getCurrencyCode, s -> s, (a, b) -> a));

        Map<String, Long> reservedByCode = new HashMap<>();
        for (Object[] row : reservationRepository.getReservedStockByBranch(branchId)) {
            reservedByCode.put((String) row[0], ((BigDecimal) row[1]).longValue());
        }

        List<CurrencyStockDetailDto> currencies = new ArrayList<>();
        LocalDateTime lastUpdated = null;

        for (String code : codes) {
            CurrencyStock cs = stockMap.get(code);
            long stock = 0, stockHuf = 0;
            if (cs != null) {
                stock = cs.getQuantity().longValue();
                // Audit P3 (2026-05-31): a longValue() lefelé CSONKOLT — a HUF készletérték
                // megjelenítésnél HALF_UP + 5 Ft-os kerekítés a helyes (HungarianRounding,
                // konzisztens a program többi HUF-összegével), nem a tizedes-vesztő csonkolás.
                stockHuf = HungarianRounding.roundToFive(
                        cs.getQuantity().multiply(cs.getWeightedAvgCost())).longValue();
                if (cs.getLastUpdated() != null && (lastUpdated == null || cs.getLastUpdated().isAfter(lastUpdated))) {
                    lastUpdated = cs.getLastUpdated();
                }
            }

            // FK-003/004 NAPI FORGALOM — multi-line-helyes (Codex #903): az egy-soros tranzakciók
            // (Transaction.currencyAmount/hufAmount) ÉS a multi-line bizonylatok tétel-sorai
            // (TransactionLine.banknoteCount/hufValue) ÖSSZEGE valutánként. Korábban a header-alapú
            // query a multi-valutás bizonylatnál az első valutára számolta a teljes összeget.
            long dailyBuy = nz(transactionRepository.sumDailySingleLineTurnoverByCurrency(branchId, today, TransactionType.BUY, code))
                    + nz(transactionLineRepository.sumDailyLineTurnoverByCurrency(branchId, today, TransactionType.BUY, code));
            long dailySell = nz(transactionRepository.sumDailySingleLineTurnoverByCurrency(branchId, today, TransactionType.SELL, code))
                    + nz(transactionLineRepository.sumDailyLineTurnoverByCurrency(branchId, today, TransactionType.SELL, code));
            long dailyBuyHuf = nz(transactionRepository.sumDailySingleLineTurnoverHufByCurrency(branchId, today, TransactionType.BUY, code))
                    + nz(transactionLineRepository.sumDailyLineTurnoverHufByCurrency(branchId, today, TransactionType.BUY, code));
            long dailySellHuf = nz(transactionRepository.sumDailySingleLineTurnoverHufByCurrency(branchId, today, TransactionType.SELL, code))
                    + nz(transactionLineRepository.sumDailyLineTurnoverHufByCurrency(branchId, today, TransactionType.SELL, code));

            currencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(stock).stockHuf(stockHuf)
                    .dailyBuy(dailyBuy)
                    .dailyBuyHuf(dailyBuyHuf)
                    .dailySell(dailySell)
                    .dailySellHuf(dailySellHuf)
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

    private BranchStockTotalsDto aggregateTotals(List<BranchSnapshotDto> branches, List<String> codes) {
        if (branches.isEmpty()) return createEmptyTotals(codes);

        Map<String, long[]> totals = new LinkedHashMap<>();
        for (String code : codes) totals.put(code, new long[6]);

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
                .currencies(codes.stream().map(code -> {
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

    /**
     * Egy körzet legfrissebb készlet-frissítése = a hozzá tartozó branch-ek
     * {@code lastUpdated} mezőinek maximuma (a null értékeket figyelmen kívül hagyva).
     * Üres lista vagy csupa-null esetén {@code null} (még sosem szinkronizált körzet).
     */
    static LocalDateTime latestLastUpdated(List<BranchSnapshotDto> branches) {
        if (branches == null) {
            return null;
        }
        return branches.stream()
                .map(BranchSnapshotDto::getLastUpdated)
                .filter(Objects::nonNull)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }

    private BranchStockTotalsDto createEmptyTotals(List<String> codes) {
        return BranchStockTotalsDto.builder()
                .currencies(codes.stream().map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build()).collect(Collectors.toList()))
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of()).build();
    }

    private BranchStockTotalsDto buildCompanyTotalsWithFallback(UUID companyId,
                                                                List<BranchSnapshotDto> branchSnapshots,
                                                                List<String> codes,
                                                                List<Object[]> rows) {
        // Fix #156: ures DB agg eseten fallback branch-aggregaciora (test-kompat + ures DB).
        if (rows == null || rows.isEmpty()) {
            return (branchSnapshots == null || branchSnapshots.isEmpty()) ? createEmptyTotals(codes) : aggregateTotals(branchSnapshots, codes);
        }
        // FK-006 P1: a kódlistát NE bővítsük itt — a `codes` már magában foglalja a company-szintű
        // leftover-eket is (resolveCurrencyCodes companyLevelRows ága). Ez biztosítja, hogy
        // minden DTO array (branch / region / company) ugyanazzal a sorrenddel és mérettel épül,
        // így az Excel index-alapú leképzése nem csordul túl (subagent self-review P1 IOOBE).
        Map<String, CurrencyStockDetailDto> byCode = new LinkedHashMap<>();
        for (String code : codes) {
            byCode.put(code, CurrencyStockDetailDto.builder().currencyCode(code).build());
        }
        for (Object[] row : rows) {
            String code = (String) row[0];
            if (code == null || !byCode.containsKey(code)) continue;
            BigDecimal qty = row[1] != null ? (BigDecimal) row[1] : BigDecimal.ZERO;
            BigDecimal huf = row[2] != null ? (BigDecimal) row[2] : BigDecimal.ZERO;
            byCode.put(code, CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(qty.longValue())
                    // Audit P3 (2026-05-31): HALF_UP + 5 Ft kerekítés a csonkoló longValue() helyett.
                    .stockHuf(HungarianRounding.roundToFive(huf).longValue())
                    .build());
        }
        return BranchStockTotalsDto.builder()
                .currencies(new ArrayList<>(byCode.values()))
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }
}
