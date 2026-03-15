package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.decade.DecadeReportLineDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DecadeReportLine;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.entity.DecadeReport;
import hu.puzzleir.valuta.entity.DecadeReport.DecadeReportStatus;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.security.SecurityUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Dekádjelentés szolgáltatás.
 * Dekád = 10 napos időszak: 1-10, 11-20, 21-hó vége.
 * Évenként max 36 dekád.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DecadeReportService {

    private final DecadeReportRepository decadeReportRepository;
    private final TransactionRepository transactionRepository;
    private final BranchRepository branchRepository;
    private final DailyBalanceRepository dailyBalanceRepository;
    private final MnbExchangeRateService mnbExchangeRateService;

    /**
     * Dekádjelentés generálása. Összesíti az adott 10 napos időszak tranzakcióit.
     */
    @Transactional
    public DecadeReportDto generateDecadeReport(UUID branchId, int year, int decade) {
        if (decade < 1 || decade > 36) {
            throw new ValidationException("Érvénytelen dekád: " + decade + " (1-36 között kell legyen)");
        }

        // IDOR védelem: csak a saját céghez tartozó irodára generálható
        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!branch.getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultság más cég irodájának dekádjelentéséhez!");
        }

        // Időszak kiszámítása a dekád számból
        LocalDate[] period = calculateDecadePeriod(year, decade);
        LocalDate periodStart = period[0];
        LocalDate periodEnd = period[1];

        // Meglévő ellenőrzés
        DecadeReport existing = decadeReportRepository
            .findByBranchIdAndYearAndDecade(branchId, year, decade)
            .orElse(null);

        if (existing != null && existing.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a dekádjelentés már le van zárva.");
        }

        // Összesítés a tranzakciókból (transactionDate alapján — üzleti szemantika)
        BigDecimal totalBuy = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "BUY", periodStart, periodEnd);
        BigDecimal totalSell = transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
            branchId, "SELL", periodStart, periodEnd);
        BigDecimal totalFee = transactionRepository.sumFeeByBranchAndPeriod(branchId, periodStart, periodEnd);
        long txCount = transactionRepository.countByBranchAndPeriod(branchId, periodStart, periodEnd);

        DecadeReport report;
        if (existing != null) {
            report = existing;
        } else {
            report = DecadeReport.builder()
                .branch(branch)
                .year(year)
                .decade(decade)
                .build();
        }

        report.setTotalBuyHuf(totalBuy != null ? totalBuy : BigDecimal.ZERO);
        report.setTotalSellHuf(totalSell != null ? totalSell : BigDecimal.ZERO);
        report.setTotalHandlingFee(totalFee != null ? totalFee : BigDecimal.ZERO);
        report.setTransactionCount((int) txCount);
        report.setStatus(DecadeReportStatus.DRAFT);

        // === MNB árfolyamos dekád haszonszámítás ===
        calculateDecadeProfit(report, branchId, period[0], period[1]);

        // === FORINT KONTROLL (Legacy: DEKRUTIN.DLL) ===
        calculateForintControl(report, branchId, period[0], period[1]);

        report = decadeReportRepository.save(report);
        log.info("Dekádjelentés generálva: branch={}, year={}, decade={}, txCount={}, profit={}",
            branchId, year, decade, txCount, report.getDecadeProfitHuf());

        return toDto(report);
    }

    /**
     * Dekád véglegesítése (CLOSED státusz).
     */
    @Transactional
    public DecadeReportDto closeDecade(UUID reportId) {
        DecadeReport report = decadeReportRepository.findById(reportId)
            .orElseThrow(() -> new ResourceNotFoundException("Dekádjelentés nem található: " + reportId));

        // IDOR védelem: csak a saját céghez tartozó dekádjelentés zárható le
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!report.getBranch().getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultság más cég dekádjelentésének lezárásához!");
        }

        if (report.getStatus() == DecadeReportStatus.CLOSED) {
            throw new ValidationException("Ez a dekádjelentés már le van zárva.");
        }

        report.setStatus(DecadeReportStatus.CLOSED);
        report.setClosedAt(LocalDateTime.now());
        report = decadeReportRepository.save(report);

        log.info("Dekádjelentés lezárva: id={}", reportId);
        return toDto(report);
    }

    /**
     * Dekádjelentések lekérdezése iroda és év szerint.
     */
    @Transactional(readOnly = true)
    public Page<DecadeReportDto> getDecadeReports(UUID branchId, int year, int page, int size) {
        return decadeReportRepository
            .findByBranchIdAndYear(branchId, year, PageRequest.of(page, size, Sort.by("decade")))
            .map(this::toDto);
    }

    // ============ MNB DEKÁD HASZON ============

    /**
     * MNB árfolyamos készletfelértékelés — dekád haszon számítás.
     *
     * Logika (valutánként):
     *   nyitóÉrték = nyitóKészlet × MNB_árfolyam(dekád_első_nap)
     *   záróÉrték  = záróKészlet × MNB_árfolyam(dekád_utolsó_nap)
     *   haszon      = záróÉrték − nyitóÉrték
     *
     * Ha egy dátumra nincs MNB árfolyam (pl. hétvége, ünnepnap),
     * a service fallback-ként az utolsó elérhető árfolyamot használja.
     */
    private void calculateDecadeProfit(DecadeReport report, UUID branchId,
                                       LocalDate periodStart, LocalDate periodEnd) {

        // Nyitó napi mérlegek — dekád első napja
        List<DailyBalance> openingBalances =
            dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, periodStart);

        // Záró napi mérlegek — dekád utolsó napja
        List<DailyBalance> closingBalances =
            dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, periodEnd);

        // Összegyűjtjük az összes érintett valutát
        Set<String> allCurrencies = new LinkedHashSet<>();
        openingBalances.forEach(b -> allCurrencies.add(b.getCurrencyCode()));
        closingBalances.forEach(b -> allCurrencies.add(b.getCurrencyCode()));

        // HUF-ra nem számolunk MNB felértékelést
        allCurrencies.remove("HUF");

        if (allCurrencies.isEmpty()) {
            report.setOpeningInventoryValueHuf(BigDecimal.ZERO);
            report.setClosingInventoryValueHuf(BigDecimal.ZERO);
            report.setDecadeProfitHuf(BigDecimal.ZERO);
            return;
        }

        // MNB árfolyamok a dekád első és utolsó napjára
        Map<String, MnbExchangeRateCache> openingRates =
            mnbExchangeRateService.getRatesForDate(periodStart);
        Map<String, MnbExchangeRateCache> closingRates =
            mnbExchangeRateService.getRatesForDate(periodEnd);

        // Keresési segéd: napi mérleg valuta szerint
        Map<String, BigDecimal> openingMap = openingBalances.stream()
            .collect(Collectors.toMap(
                DailyBalance::getCurrencyCode,
                db -> db.getOpeningBalance() != null ? db.getOpeningBalance() : BigDecimal.ZERO,
                (a, b) -> a));

        Map<String, BigDecimal> closingMap = closingBalances.stream()
            .collect(Collectors.toMap(
                DailyBalance::getCurrencyCode,
                db -> db.getClosingBalance() != null ? db.getClosingBalance() : BigDecimal.ZERO,
                (a, b) -> a));

        BigDecimal totalOpeningValueHuf = BigDecimal.ZERO;
        BigDecimal totalClosingValueHuf = BigDecimal.ZERO;

        // Régi sorok törlése (újrageneráláskor)
        report.getLines().clear();

        for (String currency : allCurrencies) {
            BigDecimal openingBal = openingMap.getOrDefault(currency, BigDecimal.ZERO);
            BigDecimal closingBal = closingMap.getOrDefault(currency, BigDecimal.ZERO);

            // MNB árfolyam lekérés (1 egységre vetítve)
            BigDecimal openingRate = getUnitRate(openingRates, currency);
            BigDecimal closingRate = getUnitRate(closingRates, currency);

            // Felértékelés HUF-ra
            BigDecimal openingValueHuf = openingBal.multiply(openingRate)
                .setScale(2, RoundingMode.HALF_UP);
            BigDecimal closingValueHuf = closingBal.multiply(closingRate)
                .setScale(2, RoundingMode.HALF_UP);
            BigDecimal profitHuf = closingValueHuf.subtract(openingValueHuf);

            DecadeReportLine line = DecadeReportLine.builder()
                .decadeReport(report)
                .currencyCode(currency)
                .openingBalance(openingBal)
                .openingMnbRate(openingRate)
                .openingValueHuf(openingValueHuf)
                .closingBalance(closingBal)
                .closingMnbRate(closingRate)
                .closingValueHuf(closingValueHuf)
                .profitHuf(profitHuf)
                .build();

            report.getLines().add(line);

            totalOpeningValueHuf = totalOpeningValueHuf.add(openingValueHuf);
            totalClosingValueHuf = totalClosingValueHuf.add(closingValueHuf);

            log.debug("Dekád haszon {}: nyitó={}×{}={} HUF, záró={}×{}={} HUF, profit={} HUF",
                currency, openingBal, openingRate, openingValueHuf,
                closingBal, closingRate, closingValueHuf, profitHuf);
        }

        report.setOpeningInventoryValueHuf(totalOpeningValueHuf);
        report.setClosingInventoryValueHuf(totalClosingValueHuf);
        report.setDecadeProfitHuf(totalClosingValueHuf.subtract(totalOpeningValueHuf));
    }

    /**
     * MNB árfolyam kinyerése 1 egységre vetítve.
     * Ha nincs elérhető árfolyam, BigDecimal.ZERO-t ad vissza (log-gal jelezve).
     */
    private BigDecimal getUnitRate(Map<String, MnbExchangeRateCache> rates, String currency) {
        MnbExchangeRateCache rate = rates.get(currency);
        if (rate == null) {
            throw new ValidationException(
                "Hiányzó MNB árfolyam a dekádjelentés generálásához: " + currency +
                ". Ellenőrizze, hogy az MNB árfolyamok be vannak-e töltve az adott időszakra!"
            );
        }
        return rate.getRatePerUnit();
    }

    // ============ FORINT KONTROLL (DEKRUTIN.DLL) ============

    /**
     * Forint kontroll validáció — Legacy: DEKRUTIN.DLL
     *
     * Képlet: _tNyito + _osszBevetel - _osszKiadas = _tZaro
     * Ha nem egyezik → forintControlValid = false, forintControlDiff = eltérés.
     *
     * Bevétel (beáramlás): eladásból kapott HUF + átvétel
     * Kiadás (kiáramlás): vételre kiadott HUF + átadás
     *
     * Legacy: BF* monthly tables → SUM(FIZETENDO) WHERE STORNO=1
     *   - TIPUS='V' (vétel): kiadás (HUF kimegy az ügyfélnek)
     *   - TIPUS='E' (eladás): bevétel (HUF bejön az ügyféltől)
     *   - FIZETOESZKOZ=2: bankkártyás elkülönítés
     *   - KEZDOSORSZAM / UTOLSOSORSZAM: bizonylat sorszám tracking
     */
    private void calculateForintControl(DecadeReport report, UUID branchId,
                                         LocalDate periodStart, LocalDate periodEnd) {

        // Aktív tranzakciók a dekádban
        List<Transaction> transactions = transactionRepository
            .findActiveByBranchAndDateRange(branchId, periodStart, periodEnd);

        // HUF napi mérleg a nyitó napra (forint nyitó)
        List<DailyBalance> openingHufBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(branchId, periodStart);
        BigDecimal forintOpening = openingHufBalances.stream()
            .filter(b -> "HUF".equals(b.getCurrencyCode()))
            .map(DailyBalance::getOpeningBalance)
            .findFirst()
            .orElse(BigDecimal.ZERO);

        // HUF napi mérleg a záró napra (forint záró)
        List<DailyBalance> closingHufBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(branchId, periodEnd);
        BigDecimal forintClosing = closingHufBalances.stream()
            .filter(b -> "HUF".equals(b.getCurrencyCode()))
            .map(DailyBalance::getClosingBalance)
            .findFirst()
            .orElse(BigDecimal.ZERO);

        BigDecimal totalIncome = BigDecimal.ZERO;   // eladásból kapott HUF
        BigDecimal totalExpense = BigDecimal.ZERO;   // vételre kiadott HUF
        BigDecimal cardTotal = BigDecimal.ZERO;
        String firstReceipt = null;
        String lastReceipt = null;

        for (Transaction tx : transactions) {
            BigDecimal huf = tx.getHufAmount();
            if (huf == null) continue;

            // Bizonylat sorszám tracking (Legacy: KEZDOSORSZAM/UTOLSOSORSZAM)
            String receipt = tx.getReceiptNumber();
            if (receipt != null) {
                if (firstReceipt == null || receipt.compareTo(firstReceipt) < 0) {
                    firstReceipt = receipt;
                }
                if (lastReceipt == null || receipt.compareTo(lastReceipt) > 0) {
                    lastReceipt = receipt;
                }
            }

            // Bankkártyás elkülönítés (Legacy: FIZETOESZKOZ=2)
            if (tx.getPaymentMethod() == PaymentMethod.CARD) {
                cardTotal = cardTotal.add(huf);
            }

            // Bevétel/kiadás szétválasztás
            if (tx.getTransactionType().isSellType()) {
                // Eladás: HUF bejön az ügyféltől → bevétel
                totalIncome = totalIncome.add(huf);
            } else if (tx.getTransactionType().isBuyType()) {
                // Vétel: HUF kimegy az ügyfélnek → kiadás
                totalExpense = totalExpense.add(huf);
            } else if (tx.getTransactionType() == TransactionType.TRANSFER_IN) {
                totalIncome = totalIncome.add(huf);
            } else if (tx.getTransactionType() == TransactionType.TRANSFER_OUT) {
                totalExpense = totalExpense.add(huf);
            }
        }

        // Forint kontroll: nyitó + bevétel - kiadás = záró
        BigDecimal expected = forintOpening.add(totalIncome).subtract(totalExpense);
        BigDecimal diff = forintClosing.subtract(expected);
        boolean valid = diff.compareTo(BigDecimal.ZERO) == 0;

        report.setForintOpening(forintOpening);
        report.setForintTotalIncome(totalIncome);
        report.setForintTotalExpense(totalExpense);
        report.setForintClosing(forintClosing);
        report.setForintControlValid(valid);
        report.setForintControlDiff(diff);
        report.setFirstReceiptNumber(firstReceipt);
        report.setLastReceiptNumber(lastReceipt);
        report.setCardPaymentTotal(cardTotal);

        if (!valid) {
            log.warn("⚠️ FORINT KONTROLL ELTÉRÉS! branch={}, dekád={}/{}, " +
                     "nyitó={}, bevétel={}, kiadás={}, elvárt záró={}, tényleges záró={}, diff={}",
                branchId, report.getYear(), report.getDecade(),
                forintOpening, totalIncome, totalExpense, expected, forintClosing, diff);
        } else {
            log.info("✅ Forint kontroll OK: branch={}, dekád={}/{}", branchId, report.getYear(), report.getDecade());
        }
    }

    // ============ HELPER ============

    /**
     * Dekád időszak kiszámítása.
     * Dekád 1-3: január 1-10, 11-20, 21-31
     * Dekád 4-6: február 1-10, 11-20, 21-28/29
     * stb.
     */
    private LocalDate[] calculateDecadePeriod(int year, int decade) {
        int month = ((decade - 1) / 3) + 1; // 1-12
        int decadeInMonth = ((decade - 1) % 3) + 1; // 1-3

        LocalDate start;
        LocalDate end;

        switch (decadeInMonth) {
            case 1:
                start = LocalDate.of(year, month, 1);
                end = LocalDate.of(year, month, 10);
                break;
            case 2:
                start = LocalDate.of(year, month, 11);
                end = LocalDate.of(year, month, 20);
                break;
            case 3:
                start = LocalDate.of(year, month, 21);
                end = YearMonth.of(year, month).atEndOfMonth();
                break;
            default:
                throw new ValidationException("Érvénytelen dekád: " + decade);
        }

        return new LocalDate[]{start, end};
    }

    private DecadeReportDto toDto(DecadeReport entity) {
        List<DecadeReportLineDto> lineDtos = entity.getLines() != null
            ? entity.getLines().stream().map(this::toLineDto).collect(Collectors.toList())
            : null;

        return DecadeReportDto.builder()
            .id(entity.getId())
            .branchId(entity.getBranch().getId())
            .year(entity.getYear())
            .decade(entity.getDecade())
            .totalBuyHuf(entity.getTotalBuyHuf())
            .totalSellHuf(entity.getTotalSellHuf())
            .totalHandlingFee(entity.getTotalHandlingFee())
            .transactionCount(entity.getTransactionCount())
            .openingInventoryValueHuf(entity.getOpeningInventoryValueHuf())
            .closingInventoryValueHuf(entity.getClosingInventoryValueHuf())
            .decadeProfitHuf(entity.getDecadeProfitHuf())
            .lines(lineDtos)
            // Forint kontroll
            .forintOpening(entity.getForintOpening())
            .forintTotalIncome(entity.getForintTotalIncome())
            .forintTotalExpense(entity.getForintTotalExpense())
            .forintClosing(entity.getForintClosing())
            .forintControlValid(entity.getForintControlValid())
            .forintControlDiff(entity.getForintControlDiff())
            .firstReceiptNumber(entity.getFirstReceiptNumber())
            .lastReceiptNumber(entity.getLastReceiptNumber())
            .cardPaymentTotal(entity.getCardPaymentTotal())
            .printControlFlag(entity.getPrintControlFlag())
            .status(entity.getStatus().name())
            .closedAt(entity.getClosedAt())
            .closedBy(entity.getClosedBy())
            .createdAt(entity.getCreatedAt())
            .build();
    }

    private DecadeReportLineDto toLineDto(DecadeReportLine line) {
        return DecadeReportLineDto.builder()
            .id(line.getId())
            .currencyCode(line.getCurrencyCode())
            .openingBalance(line.getOpeningBalance())
            .openingMnbRate(line.getOpeningMnbRate())
            .openingValueHuf(line.getOpeningValueHuf())
            .closingBalance(line.getClosingBalance())
            .closingMnbRate(line.getClosingMnbRate())
            .closingValueHuf(line.getClosingValueHuf())
            .profitHuf(line.getProfitHuf())
            .build();
    }
}
