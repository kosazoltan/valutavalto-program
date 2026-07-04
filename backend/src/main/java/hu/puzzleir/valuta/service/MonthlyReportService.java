package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.MonthlyReportFullDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.MonthDay;
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
    // IDOR-fix (audit 2026-06-15, FINDING #2): branch-ownership guard a teljes havi
    // riport (és a rajta keresztül futó PDF) read-úton. A branchService.findById(branchId)
    // ResourceNotFoundException-t dob cross-tenant branchId-nél.
    private final BranchService branchService;
    private final DailyBalanceRepository dailyBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CurrencyRepository currencyRepository;
    private final MnbExchangeRateService mnbExchangeRateService;
    private final TransferRepository transferRepository;

    /**
     * Magyar fix unnepnapok (nem mozgo, evtol fuggetlen).
     * Mozgo unnepnapok (husvet, punkosd) nem tartalmazottak — bovitheto kesobbi fazisban.
     */
    private static final Set<MonthDay> HUNGARIAN_FIXED_HOLIDAYS = Set.of(
            MonthDay.of(1, 1),   // Ujev
            MonthDay.of(3, 15),  // Marcius 15
            MonthDay.of(5, 1),   // Munka unnepe
            MonthDay.of(8, 20),  // Allamalapitas
            MonthDay.of(10, 23), // Oktober 23
            MonthDay.of(11, 1),  // Mindenszentek
            MonthDay.of(12, 25), // Karacsony 1
            MonthDay.of(12, 26)  // Karacsony 2
    );

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

        // IDOR guard (FINDING #2): a branchId KÖTELEZŐEN a hívó cégéhez tartozik —
        // findById ResourceNotFoundException-t dob cross-tenant branchId-nél, mielőtt
        // bármilyen branch-szűrt lekérdezés lefutna. Ez védi a /full és a /pdf (rajta
        // keresztül futó MonthlyClosingPdfService) read-utat is.
        branchService.findById(branchId);

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato: " + branchId));
        // IDOR-fix (FINDING #2): a companyId a HÍVÓ cégéből (SecurityUtils), NEM a cél
        // branch-ből származik — a fenti findById guard után a kettő amúgy is egyezik,
        // de a downstream lekérdezések (pl. exchangeRateRepository.findActiveByDateAndBranch)
        // így garantáltan a hívó cég-scope-jával futnak, nem a cél branchéval.
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Currency name map
        Map<String, String> currencyNameMap = new HashMap<>();
        currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()
                .forEach(c -> currencyNameMap.put(c.getCode(), c.getName()));

        // 1. Havi osszesitett forgalom — napi balance-ok aggregalasa
        List<DailyBalance> monthlyBalances = dailyBalanceRepository.findByBranchAndMonth(
                companyId, branchId, ym.getYear(), ym.getMonthValue());

        // Utolso nap balance (zaro keszlet)
        List<DailyBalance> lastDayBalances = dailyBalanceRepository.findByBranchIdAndBalanceDate(
                companyId, branchId, monthEnd);
        // Elso nap balance (nyito keszlet)
        List<DailyBalance> firstDayBalances = dailyBalanceRepository.findByBranchIdAndBalanceDate(
                companyId, branchId, monthStart);

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
        LocalDate lastBusinessDay = getLastBusinessDay(monthEnd);
        Map<String, MnbExchangeRateCache> mnbRates = mnbExchangeRateService.getRatesForDate(lastBusinessDay);

        // Arfolyam — atlagos arfolyam szamitashoz a napi rate-ek
        List<ExchangeRate> lastDayRates = exchangeRateRepository.findActiveByDateAndBranch(companyId, monthEnd, branchId);
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
        // G18: fizetesi mod szerinti bontas (keszpenzes vs bankkartyas) a BUY+SELL forgalomra
        BigDecimal cashTurnoverHuf = BigDecimal.ZERO;
        BigDecimal cardTurnoverHuf = BigDecimal.ZERO;

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
            if (type == TransactionType.BUY || type == TransactionType.SELL) {
                if (tx.getPaymentMethod() == PaymentMethod.CARD) {
                    cardTurnoverHuf = cardTurnoverHuf.add(huf);
                } else {
                    cashTurnoverHuf = cashTurnoverHuf.add(huf); // CASH vagy null → készpénz
                }
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

        // 4. Kezelesi dij (Delphi: KDAT — HANDLING_FEE subledger)
        BigDecimal handlingFeeOpening = getSubledgerValue(branchId, monthStart, "HANDLING_FEE", "HUF", true);
        BigDecimal handlingFeeBalance = getSubledgerValue(branchId, monthEnd, "HANDLING_FEE", "HUF", false);
        BigDecimal handlingFeeIncome = sumSubledgerField(branchId, monthStart, monthEnd, "HANDLING_FEE", "HUF", "income");
        BigDecimal handlingFeeExpense = sumSubledgerField(branchId, monthStart, monthEnd, "HANDLING_FEE", "HUF", "expense");

        // 5. E-kereskedelem
        BigDecimal ecomOpening = getSubledgerValue(branchId, monthStart, "ECOMMERCE", "HUF", true);
        BigDecimal ecomBalance = getSubledgerValue(branchId, monthEnd, "ECOMMERCE", "HUF", false);
        BigDecimal ecomIncome = sumSubledgerField(branchId, monthStart, monthEnd, "ECOMMERCE", "HUF", "income");
        BigDecimal ecomExpense = sumSubledgerField(branchId, monthStart, monthEnd, "ECOMMERCE", "HUF", "expense");

        // 6. Penztar kozotti mozgasok (Delphi: AtadAtvetLista)
        List<MonthlyReportFullDto.TransferLineDto> transferLines = buildTransferLines(
                companyId, branchId, monthStart, monthEnd, currencyNameMap);

        // 7. Munkanapok
        int workingDays = 0;
        for (LocalDate d = monthStart; !d.isAfter(monthEnd); d = d.plusDays(1)) {
            if (isBusinessDay(d)) workingDays++;
        }
        int closedDays = (int) dailyBalanceRepository.findByBranchAndMonth(companyId, branchId, ym.getYear(), ym.getMonthValue())
                .stream().map(DailyBalance::getBalanceDate).distinct().count();

        // Branch cim + adoszam
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
                .cashTurnoverHuf(cashTurnoverHuf)
                .cardTurnoverHuf(cardTurnoverHuf)
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
                .handlingFeeOpening(handlingFeeOpening)
                .handlingFeeIncome(handlingFeeIncome)
                .handlingFeeExpense(handlingFeeExpense)
                .handlingFeeBalance(handlingFeeBalance)
                .ecommerceOpening(ecomOpening)
                .ecommerceIncome(ecomIncome)
                .ecommerceExpense(ecomExpense)
                .ecommerceBalance(ecomBalance)
                .transferLines(transferLines)
                .workingDays(workingDays)
                .closedDays(closedDays)
                .build();
    }

    // ============ TRANSFER (Delphi: AtadAtvetLista) ============

    /**
     * Penztarak kozotti mozgasok havi osszesitese (Delphi: AtadAtvetGyujtes + AtadAtvetLista).
     * Devizanemenként aggregalja a bejovo es kimeno transfer osszegeket.
     */
    private List<MonthlyReportFullDto.TransferLineDto> buildTransferLines(
            UUID companyId, UUID branchId, LocalDate start, LocalDate end, Map<String, String> currencyNameMap) {

        // Egyetlen aggregalt query devizanementkent (N1 fix: nem N×M napi iteracio)
        Map<String, BigDecimal> inMap = new HashMap<>();
        for (Object[] row : transferRepository.sumTransfersInByPeriod(companyId, branchId, start, end)) {
            inMap.put((String) row[0], (BigDecimal) row[1]);
        }

        Map<String, BigDecimal> outMap = new HashMap<>();
        for (Object[] row : transferRepository.sumTransfersOutByPeriod(companyId, branchId, start, end)) {
            outMap.put((String) row[0], (BigDecimal) row[1]);
        }

        Set<String> allCc = new TreeSet<>();
        allCc.addAll(inMap.keySet());
        allCc.addAll(outMap.keySet());

        List<MonthlyReportFullDto.TransferLineDto> lines = new ArrayList<>();
        for (String cc : allCc) {
            BigDecimal received = inMap.getOrDefault(cc, BigDecimal.ZERO);
            BigDecimal sent = outMap.getOrDefault(cc, BigDecimal.ZERO);
            lines.add(MonthlyReportFullDto.TransferLineDto.builder()
                    .currencyCode(cc)
                    .currencyName(currencyNameMap.getOrDefault(cc, cc))
                    .receivedAmount(received)
                    .sentAmount(sent)
                    .netAmount(received.subtract(sent))
                    .build());
        }
        return lines;
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
     * Egyetlen range query-vel keri le az osszes napi snapshot-ot.
     */
    private BigDecimal sumSubledgerField(UUID branchId, LocalDate start, LocalDate end,
                                         String subledgerType, String currencyCode, String field) {
        List<DailySubledgerSnapshot> snaps = subledgerSnapshotRepository
                .findByBranchIdAndSnapshotDateBetweenAndSubledgerTypeAndCurrencyCode(
                        branchId, start, end, subledgerType, currencyCode);
        BigDecimal sum = BigDecimal.ZERO;
        for (DailySubledgerSnapshot snap : snaps) {
            BigDecimal val = "income".equals(field) ? nz(snap.getIncome()) : nz(snap.getExpense());
            sum = sum.add(val);
        }
        return sum;
    }

    /**
     * Ho utolso munkanapja (hetvege + magyar fix unnepnapok kizarasa).
     */
    LocalDate getLastBusinessDay(LocalDate monthEnd) {
        LocalDate d = monthEnd;
        while (!isBusinessDay(d)) {
            d = d.minusDays(1);
        }
        return d;
    }

    /**
     * Munkanap-e (nem hetvege es nem magyar fix unnepnap).
     */
    private boolean isBusinessDay(LocalDate date) {
        if (date.getDayOfWeek() == DayOfWeek.SATURDAY || date.getDayOfWeek() == DayOfWeek.SUNDAY) {
            return false;
        }
        return !HUNGARIAN_FIXED_HOLIDAYS.contains(MonthDay.of(date.getMonthValue(), date.getDayOfMonth()));
    }

}
