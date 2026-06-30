package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto.CurrencyTurnoverDto;
import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto.WorkerTurnoverDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Forgalom összesítő szolgáltatás — napi, heti, havi, éves, cégszintű.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TurnoverService {

    private final TransactionRepository transactionRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    // IDOR-fix (audit 2026-06-15, FINDING #3): branch-ownership guard a per-branch
    // riportoknál. A branchService.findById(branchId) ResourceNotFoundException-t dob,
    // ha a branch NEM a hívó cégéhez (SecurityUtils.getCurrentCompanyId()) tartozik —
    // így a CASHIER-elérhető /daily|/weekly|/monthly|/yearly végpontok nem szivárogtatnak
    // cross-tenant forgalmi adatot. (A /company végpont már SecurityUtils-szal védett.)
    private final BranchService branchService;

    public TurnoverReportDto getDailyTurnover(UUID branchId, LocalDate date) {
        return buildReport(
            branchId,
            date.toString(),
            date.atStartOfDay(),
            date.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getWeeklyTurnover(UUID branchId, LocalDate weekStart) {
        LocalDate mondayStart = weekStart.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate sundayEnd = mondayStart.plusDays(6);
        return buildReport(
            branchId,
            mondayStart + " - " + sundayEnd,
            mondayStart.atStartOfDay(),
            sundayEnd.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getMonthlyTurnover(UUID branchId, YearMonth month) {
        LocalDate first = month.atDay(1);
        LocalDate last = month.atEndOfMonth();
        return buildReport(
            branchId,
            month.toString(),
            first.atStartOfDay(),
            last.atTime(LocalTime.MAX)
        );
    }

    public TurnoverReportDto getYearlyTurnover(UUID branchId, int year) {
        LocalDate first = LocalDate.of(year, 1, 1);
        LocalDate last = LocalDate.of(year, 12, 31);
        return buildReport(
            branchId,
            String.valueOf(year),
            first.atStartOfDay(),
            last.atTime(LocalTime.MAX)
        );
    }

    /**
     * FK-045 FR-2/FR-3: egy pénztár (branch) forgalma TETSZŐLEGES dátumtartományra (nap-tól nap-ig).
     * A korábbi frontend a /daily-t hívta, ami csak egyetlen napot adott — a kiválasztott intervallum
     * elveszett. Ez a metódus a teljes [from, to] tartományt aggregálja a buildReport-on át.
     */
    public TurnoverReportDto getBranchTurnoverRange(UUID branchId, LocalDate from, LocalDate to) {
        TurnoverReportDto report = buildReport(
            branchId,
            from + " - " + to,
            from.atStartOfDay(),
            to.atTime(LocalTime.MAX)
        );
        // FK-045 NFR-3: a Napi forgalom pénztár-nézet VETT/ELADOTT összesítői 5 Ft-ra kerekítve
        // (a company/territory nézettel konzisztensen). A közös buildReport-ot NEM módosítjuk, hogy a
        // meglévő daily/weekly/havi/éves riportok viselkedése változatlan maradjon.
        report.setTotalBuy(HungarianRounding.roundToFive(report.getTotalBuy()));
        report.setTotalSell(HungarianRounding.roundToFive(report.getTotalSell()));
        return report;
    }

    public TurnoverReportDto getCompanyTurnover(UUID companyId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        BigDecimal totalBuy = transactionRepository.sumHufAmountByCompanyAndTypeAndPeriod(
            companyId, "BUY", fromDt, toDt);
        BigDecimal totalSell = transactionRepository.sumHufAmountByCompanyAndTypeAndPeriod(
            companyId, "SELL", fromDt, toDt);
        BigDecimal fees = transactionRepository.sumFeeByCompanyAndPeriod(companyId, fromDt, toDt);

        totalBuy = totalBuy != null ? totalBuy : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees = fees != null ? fees : BigDecimal.ZERO;

        // NFR-3: 5 Ft-os kerekítés a VETT/ELADOTT összesítőkön (a területi nézettel konzisztensen).
        totalBuy = HungarianRounding.roundToFive(totalBuy);
        totalSell = HungarianRounding.roundToFive(totalSell);

        // FR-7: a „Teljes cég" nézet valutánkénti bontása + MNB official_rate (minden nézetre kötelező).
        List<CurrencyTurnoverDto> byCurrency = accumulateByCurrency(
            transactionRepository.groupByCurrencyAndTypeForCompany(companyId, from, to));
        applyOfficialRates(byCurrency, companyId, to);

        return TurnoverReportDto.builder()
            .period(from + " - " + to)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(totalSell.subtract(totalBuy))
            .fees(fees)
            .netProfit(totalSell.subtract(totalBuy).add(fees))
            .byCurrency(byCurrency)
            .byWorker(Collections.emptyList())
            .build();
    }

    // ============ HELPER ============

    /**
     * FK-045 FR-4/FR-9: egy értéktári terület (vault_territory) összes pénztárának összesített
     * forgalma, valutánkénti bontással + MNB elszámolási árfolyammal (FR-7). A getCompanyTurnover
     * mintáját követi, de territory-szűrt aggregáló query-kkel.
     *
     * <p>Multi-tenant guard (§1): a {@code countBranchesInTerritory} 0-t ad, ha a territoryId nem
     * a hívó cégéhez tartozik (vagy nem létezik) → {@link ResourceNotFoundException} (404), mielőtt
     * bármilyen aggregáló query lefutna — idegen tenant területe nem szivárog ki.</p>
     */
    public TurnoverReportDto getVaultTerritoryTurnover(UUID companyId, Integer vaultTerritoryId,
                                                       LocalDate from, LocalDate to) {
        // Tenant + létezés guard: a területhez tartozó, a hívó cégébe eső branch-ek száma > 0 kell.
        if (transactionRepository.countBranchesInTerritory(companyId, vaultTerritoryId) == 0) {
            throw new ResourceNotFoundException(
                "Értéktári terület nem található a jelenlegi cégben: vaultTerritoryId=" + vaultTerritoryId);
        }

        BigDecimal totalBuy = transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
            companyId, vaultTerritoryId, "BUY", from, to);
        BigDecimal totalSell = transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
            companyId, vaultTerritoryId, "SELL", from, to);
        BigDecimal fees = transactionRepository.sumFeeByTerritoryAndPeriod(
            companyId, vaultTerritoryId, from, to);

        totalBuy = totalBuy != null ? totalBuy : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees = fees != null ? fees : BigDecimal.ZERO;

        // FK-045 NFR-3: a VETT/ELADOTT összesítők 5 Ft-ra kerekítve (HungarianRounding, HALF_UP) —
        // a domain-szótár és a frontend megjelenítés ezt írja elő a területi összesítőkre is.
        totalBuy = HungarianRounding.roundToFive(totalBuy);
        totalSell = HungarianRounding.roundToFive(totalSell);

        List<Object[]> rows = transactionRepository.groupByCurrencyAndTypeForTerritory(
            companyId, vaultTerritoryId, from, to);
        List<CurrencyTurnoverDto> byCurrency = accumulateByCurrency(rows);
        applyOfficialRates(byCurrency, companyId, to);

        return TurnoverReportDto.builder()
            .period(from + " - " + to)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(totalSell.subtract(totalBuy))
            .fees(fees)
            .netProfit(totalSell.subtract(totalBuy).add(fees))
            .byCurrency(byCurrency)
            .byWorker(Collections.emptyList())
            .build();
    }

    /**
     * FK-045 FR-7 + TBD-1: a byCurrency sorokba tölti az MNB elszámolási árfolyamot (official_rate),
     * az időszak UTOLSÓ napján érvényes aktív árfolyamokból, devizánként. Ha egy valutához nincs
     * official_rate (vagy nincs aktív árfolyam az adott napra) → a mező null marad (a UI „–"-t mutat).
     */
    private void applyOfficialRates(List<CurrencyTurnoverDto> byCurrency, UUID companyId, LocalDate to) {
        if (byCurrency.isEmpty()) {
            return;
        }
        Map<String, BigDecimal> rateByCode = new LinkedHashMap<>();
        for (ExchangeRate er : exchangeRateRepository.findActiveRatesByDate(companyId, to)) {
            if (er.getCurrency() != null && er.getCurrency().getCode() != null
                    && er.getOfficialRate() != null) {
                // findActiveRatesByDate displayOrder szerint rendez; az első (legrelevánsabb) marad.
                rateByCode.putIfAbsent(er.getCurrency().getCode(), er.getOfficialRate());
            }
        }
        for (CurrencyTurnoverDto dto : byCurrency) {
            dto.setOfficialRate(rateByCode.get(dto.getCurrencyCode()));
        }
    }

    private TurnoverReportDto buildReport(UUID branchId, String period,
                                           LocalDateTime from, LocalDateTime to) {
        // IDOR guard (FINDING #3): a branchId KÖTELEZŐEN a hívó cégéhez tartozik.
        // findById ResourceNotFoundException-t dob cross-tenant branchId-nél, mielőtt
        // bármilyen branch-szűrt aggregáló query lefutna. Minden per-branch publikus
        // metódus (daily/weekly/monthly/yearly) ide fut be, ezért egy helyen elég.
        var branch = branchService.findById(branchId);

        LocalDate dateFrom = from.toLocalDate();
        LocalDate dateTo = to.toLocalDate();

        // Főösszegek — sztornókat és megszakítottakat kizárva
        BigDecimal totalBuy = transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
            branchId, "BUY", dateFrom, dateTo);
        BigDecimal totalSell = transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
            branchId, "SELL", dateFrom, dateTo);
        BigDecimal fees = transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(branchId, dateFrom, dateTo);

        totalBuy = totalBuy != null ? totalBuy : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees = fees != null ? fees : BigDecimal.ZERO;

        BigDecimal spread = totalSell.subtract(totalBuy);
        BigDecimal netProfit = spread.add(fees);

        // Valuta szerinti bontás
        List<CurrencyTurnoverDto> byCurrency = buildByCurrency(branchId, dateFrom, dateTo);
        // FR-7: az MNB elszámolási árfolyam a pénztár/napi nézetben is megjelenik (minden nézetre kötelező).
        if (branch != null && branch.getCompanyId() != null) {
            applyOfficialRates(byCurrency, branch.getCompanyId(), dateTo);
        }

        // Pénztáros szerinti bontás
        List<WorkerTurnoverDto> byWorker = buildByWorker(branchId, dateFrom, dateTo);

        return TurnoverReportDto.builder()
            .period(period)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(spread)
            .fees(fees)
            .netProfit(netProfit)
            .byCurrency(byCurrency)
            .byWorker(byWorker)
            .build();
    }

    private List<CurrencyTurnoverDto> buildByCurrency(UUID branchId, LocalDate dateFrom, LocalDate dateTo) {
        List<Object[]> rows = transactionRepository.groupByCurrencyAndTypeForBranch(branchId, dateFrom, dateTo);
        return accumulateByCurrency(rows);
    }

    /**
     * Közös valuta-akkumuláció a [currencyCode, txType, currencyAmount, hufAmount, handlingFee, count]
     * sorokból — branch és territory aggregáció is ezt használja (DRY, FK-045).
     */
    private List<CurrencyTurnoverDto> accumulateByCurrency(List<Object[]> rows) {
        Map<String, CurrencyAccum> accMap = new LinkedHashMap<>();
        for (Object[] row : rows) {
            String currCode = (String) row[0];
            String txType = (String) row[1];
            BigDecimal currencyAmount = toBigDecimal(row[2]);
            BigDecimal hufAmount = toBigDecimal(row[3]);
            BigDecimal handlingFee = toBigDecimal(row[4]);
            long count = toLong(row[5]);

            CurrencyAccum acc = accMap.computeIfAbsent(currCode, CurrencyAccum::new);
            if ("BUY".equals(txType)) {
                acc.buyVolume = acc.buyVolume.add(currencyAmount);
                acc.buyHuf = acc.buyHuf.add(hufAmount);
                acc.buyCount += (int) count;
            } else if ("SELL".equals(txType)) {
                acc.sellVolume = acc.sellVolume.add(currencyAmount);
                acc.sellHuf = acc.sellHuf.add(hufAmount);
                acc.sellCount += (int) count;
            }
            acc.totalFee = acc.totalFee.add(handlingFee);
        }

        List<CurrencyTurnoverDto> result = new ArrayList<>();
        for (CurrencyAccum acc : accMap.values()) {
            result.add(CurrencyTurnoverDto.builder()
                .currencyCode(acc.code)
                .buyVolume(acc.buyVolume)
                .sellVolume(acc.sellVolume)
                .buyHuf(acc.buyHuf)
                .sellHuf(acc.sellHuf)
                .fee(acc.totalFee)
                .transactionCount(acc.buyCount + acc.sellCount)
                .build());
        }
        return result;
    }

    private List<WorkerTurnoverDto> buildByWorker(UUID branchId, LocalDate dateFrom, LocalDate dateTo) {
        List<Object[]> rows = transactionRepository.groupByWorkerForBranch(branchId, dateFrom, dateTo);
        List<WorkerTurnoverDto> result = new ArrayList<>();
        for (Object[] row : rows) {
            Long workerId = row[0] != null ? ((Number) row[0]).longValue() : null;
            String workerName = (String) row[1];
            BigDecimal totalVolume = toBigDecimal(row[2]);
            BigDecimal handlingFee = toBigDecimal(row[3]);
            int count = (int) toLong(row[4]);
            result.add(WorkerTurnoverDto.builder()
                .workerId(workerId)
                .workerName(workerName)
                .totalVolume(totalVolume)
                .fee(handlingFee)
                .transactionCount(count)
                .build());
        }
        return result;
    }

    private static BigDecimal toBigDecimal(Object val) {
        if (val == null) return BigDecimal.ZERO;
        if (val instanceof BigDecimal bd) return bd;
        return new BigDecimal(val.toString());
    }

    private static long toLong(Object val) {
        if (val == null) return 0L;
        if (val instanceof Number n) return n.longValue();
        return Long.parseLong(val.toString());
    }

    // ============ BELSŐ SEGÉDOSZTÁLY ============

    private static class CurrencyAccum {
        final String code;
        BigDecimal buyVolume = BigDecimal.ZERO;
        BigDecimal buyHuf = BigDecimal.ZERO;
        BigDecimal sellVolume = BigDecimal.ZERO;
        BigDecimal sellHuf = BigDecimal.ZERO;
        BigDecimal totalFee = BigDecimal.ZERO;
        int buyCount;
        int sellCount;

        CurrencyAccum(String code) {
            this.code = code;
        }
    }
}
