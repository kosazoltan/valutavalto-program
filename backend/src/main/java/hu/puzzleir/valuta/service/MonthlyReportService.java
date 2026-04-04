package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.MonthlyReportFullDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.*;

/**
 * Havi riport szolgaltatas (Delphi: HAVIZAR.DLL osszesites).
 *
 * <p>Havi szinten aggregalja a napi zarasi adatokat es valutaforgalmat,
 * WU/AFA, kezelesi dij, e-kereskedelem bontassal.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class MonthlyReportService {

    private final ReportService reportService;
    private final BranchRepository branchRepository;
    private final DailyBalanceRepository dailyBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final MnbExchangeRateService mnbExchangeRateService;

    public ReportService.MonthlyTurnoverReport generateMonthlyTurnoverReport(Integer year, Integer month) {
        return reportService.generateMonthlyTurnoverReport(year, month);
    }

    /**
     * Teljes havi jelentes generalas (Delphi: havizar osszesites).
     */
    public MonthlyReportFullDto generateFullReport(UUID branchId, String yearMonthStr) {
        YearMonth ym = YearMonth.parse(yearMonthStr);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        log.info("S3-01 havi jelentes: branchId={}, yearMonth={}", branchId, yearMonthStr);

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));

        // Currency name map
        Map<String, String> currencyNameMap = new HashMap<>();
        currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()
                .forEach(c -> currencyNameMap.put(c.getCode(), c.getName()));

        // 1. Havi osszesitett forgalom — napi balance-ok aggregalasa
        List<DailyBalance> monthlyBalances = dailyBalanceRepository.findByBranchAndMonth(
                branchId, ym.getYear(), ym.getMonthValue());

        // Utolso nap balance (zaro keszlet)
        List<DailyBalance> lastDayBalances = dailyBalanceRepository.findByBranchIdAndBalanceDate(
                branchId, monthEnd);
        // Elso nap balance (nyito keszlet)
        List<DailyBalance> firstDayBalances = dailyBalanceRepository.findByBranchIdAndBalanceDate(
                branchId, monthStart);

        Map<String, BigDecimal> openingMap = new HashMap<>();
        for (DailyBalance bal : firstDayBalances) {
            openingMap.put(bal.getCurrencyCode(), nz(bal.getOpeningBalance()));
        }

        Map<String, BigDecimal> closingMap = new HashMap<>();
        for (DailyBalance bal : lastDayBalances) {
            closingMap.put(bal.getCurrencyCode(), nz(bal.getClosingBalance()));
        }

        // Devizank havi osszesitett forgalom
        Map<String, BigDecimal> totalBuyMap = new HashMap<>();
        Map<String, BigDecimal> totalSellMap = new HashMap<>();
        for (DailyBalance bal : monthlyBalances) {
            String cc = bal.getCurrencyCode();
            totalBuyMap.merge(cc, nz(bal.getPurchases()), BigDecimal::add);
            totalSellMap.merge(cc, nz(bal.getSales()), BigDecimal::add);
        }

        // MNB arfolyamok
        MonthlyClosingService monthlyClosingService = null; // not injected, get last business day
        LocalDate lastBusinessDay = getLastBusinessDay(monthEnd);
        Map<String, MnbExchangeRateCache> mnbRates = mnbExchangeRateService.getRatesForDate(lastBusinessDay);

        // Arfolyam — atlagos arfolyam szamitashoz a napi rate-ek
        List<ExchangeRate> lastDayRates = exchangeRateRepository.findActiveByDateAndBranch(monthEnd, branchId);
        Map<String, ExchangeRate> rateMap = new HashMap<>();
        for (ExchangeRate er : lastDayRates) {
            if (er.getCurrency() != null) {
                rateMap.putIfAbsent(er.getCurrency().getCode(), er);
            }
        }

        // Currency lines
        Set<String> allCurrencies = new TreeSet<>();
        allCurrencies.addAll(openingMap.keySet());
        allCurrencies.addAll(closingMap.keySet());
        allCurrencies.addAll(totalBuyMap.keySet());
        allCurrencies.addAll(totalSellMap.keySet());

        BigDecimal closingHuf = BigDecimal.ZERO;
        BigDecimal closingForeignHuf = BigDecimal.ZERO;
        List<MonthlyReportFullDto.CurrencyLineDto> currencyLines = new ArrayList<>();

        for (String cc : allCurrencies) {
            BigDecimal opening = openingMap.getOrDefault(cc, BigDecimal.ZERO);
            BigDecimal closing = closingMap.getOrDefault(cc, BigDecimal.ZERO);
            BigDecimal totalBuy = totalBuyMap.getOrDefault(cc, BigDecimal.ZERO);
            BigDecimal totalSell = totalSellMap.getOrDefault(cc, BigDecimal.ZERO);

            BigDecimal avgBuyRate = BigDecimal.ZERO;
            BigDecimal avgSellRate = BigDecimal.ZERO;
            ExchangeRate rate = rateMap.get(cc);
            if (rate != null) {
                avgBuyRate = nz(rate.getBaseBuyRate());
                avgSellRate = nz(rate.getBaseSellRate());
            }

            BigDecimal mnbRate = BigDecimal.ZERO;
            MnbExchangeRateCache mnbCached = mnbRates.get(cc);
            if (mnbCached != null && mnbCached.getOfficialRate() != null) {
                mnbRate = mnbCached.getOfficialRate();
            }

            BigDecimal buyHuf;
            BigDecimal sellHuf;
            if ("HUF".equals(cc)) {
                closingHuf = closingHuf.add(closing);
                buyHuf = totalBuy;
                sellHuf = totalSell;
            } else {
                buyHuf = totalBuy.multiply(avgBuyRate);
                sellHuf = totalSell.multiply(avgSellRate);
                BigDecimal midRate = avgBuyRate.add(avgSellRate).compareTo(BigDecimal.ZERO) > 0
                        ? avgBuyRate.add(avgSellRate).divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;
                closingForeignHuf = closingForeignHuf.add(closing.multiply(midRate));
            }

            currencyLines.add(MonthlyReportFullDto.CurrencyLineDto.builder()
                    .currencyCode(cc)
                    .currencyName(currencyNameMap.getOrDefault(cc, cc))
                    .openingStock(opening)
                    .closingStock(closing)
                    .totalBuyAmount(totalBuy)
                    .totalSellAmount(totalSell)
                    .totalBuyHuf(buyHuf)
                    .totalSellHuf(sellHuf)
                    .avgBuyRate(avgBuyRate)
                    .avgSellRate(avgSellRate)
                    .mnbRate(mnbRate)
                    .build());
        }

        // 2. Tranzakcio szamok
        List<Transaction> monthTx = transactionRepository.findActiveByBranchAndDateRange(
                branchId, monthStart, monthEnd);
        int buyCount = 0, sellCount = 0, reversalCount = 0;
        BigDecimal totalBuyHuf = BigDecimal.ZERO;
        BigDecimal totalSellHuf = BigDecimal.ZERO;

        for (Transaction tx : monthTx) {
            BigDecimal huf = tx.getHufAmount() != null ? tx.getHufAmount().abs() : BigDecimal.ZERO;
            TransactionType type = tx.getTransactionType();
            if (type == TransactionType.BUY) {
                buyCount++;
                totalBuyHuf = totalBuyHuf.add(huf);
            } else if (type == TransactionType.SELL) {
                sellCount++;
                totalSellHuf = totalSellHuf.add(huf);
            } else if (type == TransactionType.REVERSAL) {
                reversalCount++;
            }
        }

        // 3. WU/AFA — ho elso napjanak nyitoja es utolso napjanak zaroja
        BigDecimal wuUsdOpening = getSubledgerValue(branchId, monthStart, "WU_USD", "USD", true);
        BigDecimal wuUsdBalance = getSubledgerValue(branchId, monthEnd, "WU_USD", "USD", false);
        BigDecimal wuUsdIncome = sumSubledgerField(branchId, monthStart, monthEnd, "WU_USD", "USD", "income");
        BigDecimal wuUsdExpense = sumSubledgerField(branchId, monthStart, monthEnd, "WU_USD", "USD", "expense");

        BigDecimal wuHufOpening = getSubledgerValue(branchId, monthStart, "WU_HUF", "HUF", true);
        BigDecimal wuHufBalance = getSubledgerValue(branchId, monthEnd, "WU_HUF", "HUF", false);
        BigDecimal wuHufIncome = sumSubledgerField(branchId, monthStart, monthEnd, "WU_HUF", "HUF", "income");
        BigDecimal wuHufExpense = sumSubledgerField(branchId, monthStart, monthEnd, "WU_HUF", "HUF", "expense");

        BigDecimal afaOpening = getSubledgerValue(branchId, monthStart, "WU_VAT", "HUF", true);
        BigDecimal afaBalance = getSubledgerValue(branchId, monthEnd, "WU_VAT", "HUF", false);
        BigDecimal afaIncome = sumSubledgerField(branchId, monthStart, monthEnd, "WU_VAT", "HUF", "income");
        BigDecimal afaExpense = sumSubledgerField(branchId, monthStart, monthEnd, "WU_VAT", "HUF", "expense");

        // 4. E-kereskedelem
        BigDecimal ecomOpening = getSubledgerValue(branchId, monthStart, "ECOMMERCE", "HUF", true);
        BigDecimal ecomBalance = getSubledgerValue(branchId, monthEnd, "ECOMMERCE", "HUF", false);
        BigDecimal ecomIncome = sumSubledgerField(branchId, monthStart, monthEnd, "ECOMMERCE", "HUF", "income");
        BigDecimal ecomExpense = sumSubledgerField(branchId, monthStart, monthEnd, "ECOMMERCE", "HUF", "expense");

        // 5. Munkanapok
        int workingDays = 0;
        for (LocalDate d = monthStart; !d.isAfter(monthEnd); d = d.plusDays(1)) {
            if (d.getDayOfWeek().getValue() <= 5) workingDays++;
        }
        int closedDays = (int) dailyBalanceRepository.findByBranchAndMonth(branchId, ym.getYear(), ym.getMonthValue())
                .stream().map(DailyBalance::getBalanceDate).distinct().count();

        // B6: branch cim + adoszam
        String branchAddress = branch.getAddress();
        String taxId = branch.getCompany() != null ? branch.getCompany().getTaxNumber() : null;

        return MonthlyReportFullDto.builder()
                .yearMonth(yearMonthStr)
                .branchId(branchId.toString())
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .branchAddress(branchAddress)
                .taxId(taxId)
                .closingBalanceHuf(closingHuf)
                .closingBalanceForeign(closingForeignHuf)
                .closingBalanceTotal(closingHuf.add(closingForeignHuf))
                .currencyLines(currencyLines)
                .totalBuyHuf(totalBuyHuf)
                .totalSellHuf(totalSellHuf)
                .transactionCount(monthTx.size())
                .buyCount(buyCount)
                .sellCount(sellCount)
                .reversalCount(reversalCount)
                .wuUsdOpening(wuUsdOpening)
                .wuUsdIncome(wuUsdIncome)
                .wuUsdExpense(wuUsdExpense)
                .wuUsdBalance(wuUsdBalance)
                .wuHufOpening(wuHufOpening)
                .wuHufIncome(wuHufIncome)
                .wuHufExpense(wuHufExpense)
                .wuHufBalance(wuHufBalance)
                .afaOpening(afaOpening)
                .afaIncome(afaIncome)
                .afaExpense(afaExpense)
                .afaBalance(afaBalance)
                .handlingFeeOpening(BigDecimal.ZERO) // TODO: HANDLING_FEE subledger
                .handlingFeeIncome(BigDecimal.ZERO)
                .handlingFeeExpense(BigDecimal.ZERO)
                .handlingFeeBalance(BigDecimal.ZERO)
                .ecommerceOpening(ecomOpening)
                .ecommerceIncome(ecomIncome)
                .ecommerceExpense(ecomExpense)
                .ecommerceBalance(ecomBalance)
                .workingDays(workingDays)
                .closedDays(closedDays)
                .build();
    }

    // ============ HELPER ============

    private BigDecimal nz(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    /**
     * Subledger snapshot ertek: opening (ho elso nap) vagy closing (ho utolso nap).
     */
    private BigDecimal getSubledgerValue(UUID branchId, LocalDate date,
                                         String subledgerType, String currencyCode, boolean opening) {
        return subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                        branchId, date, subledgerType, currencyCode)
                .map(snap -> opening ? nz(snap.getOpeningBalance()) : nz(snap.getClosingBalance()))
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Subledger havi osszesites (income/expense a honapban).
     * Osszegyujti az osszes napi snapshot income/expense-t.
     */
    private BigDecimal sumSubledgerField(UUID branchId, LocalDate start, LocalDate end,
                                         String subledgerType, String currencyCode, String field) {
        BigDecimal sum = BigDecimal.ZERO;
        List<DailySubledgerSnapshot> snaps = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDate(branchId, start);
        // findByBranchIdAndSnapshotDate only returns one date — need range query
        // Fallback: iterate days
        for (LocalDate d = start; !d.isAfter(end); d = d.plusDays(1)) {
            Optional<DailySubledgerSnapshot> snap = subledgerSnapshotRepository
                    .findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                            branchId, d, subledgerType, currencyCode);
            if (snap.isPresent()) {
                BigDecimal val = "income".equals(field)
                        ? nz(snap.get().getIncome())
                        : nz(snap.get().getExpense());
                sum = sum.add(val);
            }
        }
        return sum;
    }

    /**
     * Ho utolso munkanapja (hetvege + magyar unnepnapok kizarasa).
     */
    private LocalDate getLastBusinessDay(LocalDate monthEnd) {
        LocalDate d = monthEnd;
        while (d.getDayOfWeek() == java.time.DayOfWeek.SATURDAY
                || d.getDayOfWeek() == java.time.DayOfWeek.SUNDAY) {
            d = d.minusDays(1);
        }
        return d;
    }
}
