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
import org.springframework.transaction.annotation.Propagation;
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
     * FKH-063: second, company-scoped rate source for currencies MNB does not quote
     * (BAM/BRL/EUA/ILS/MXN/NZD/RSD/THB — the main vault records those by hand on the FK-028
     * screen). Consulted only after the MNB cache and its 7-day walk-back have both missed.
     */
    private final MnbSettlementRateService mnbSettlementRateService;

    /**
     * Dekádjelentés generálása. Összesíti az adott 10 napos időszak tranzakcióit.
     *
     * FKH-061: REQUIRES_NEW — a dekádjelentés best-effort riport-artefaktum, nem része a
     * napzárás atomi money-láncának. Ha ez a hívás a napzárás tranzakcióján belül futna
     * (REQUIRED), egy kivétel rollback-only-ra jelölné a külső tranzakciót, és a commit
     * UnexpectedRollbackException-nel buknna — a napzárás "sikertelen" lenne a sikeres
     * pénz-lépések ellenére. Saját tranzakcióban a hiba izolált marad.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
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

        // Napzárás teljességi ellenőrzés: a dekád utolsó napjának le kell lennie zárva
        validateDailyClosingCompleteness(currentCompanyId, branchId, periodStart, periodEnd);

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
        calculateDecadeProfit(report, currentCompanyId, branchId, period[0], period[1]);

        // === FORINT KONTROLL (Legacy: DEKRUTIN.DLL) ===
        calculateForintControl(report, currentCompanyId, branchId, period[0], period[1]);

        report = decadeReportRepository.save(report);
        log.info("Dekádjelentés generálva: branch={}, year={}, decade={}, txCount={}, profit={}",
            branchId, year, decade, txCount, report.getDecadeProfitHuf());

        return toDto(report);
    }

    /**
     * Dekád véglegesítése (CLOSED státusz).
     */
    @Transactional(rollbackFor = Exception.class)
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
        // IDOR védelem (FINDING #5): a lista csak a hívó cégének irodájára szól.
        // A closeDecade/generate már scope-olt — ehhez igazodunk company-szűrt query-vel.
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        return decadeReportRepository
            .findByBranchIdAndYearAndBranchCompanyId(
                branchId, year, currentCompanyId, PageRequest.of(page, size, Sort.by("decade")))
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
    private void calculateDecadeProfit(DecadeReport report, UUID companyId, UUID branchId,
                                       LocalDate periodStart, LocalDate periodEnd) {

        // Nyitó napi mérlegek — dekád első napja
        List<DailyBalance> openingBalances =
            dailyBalanceRepository.findByBranchIdAndBalanceDate(companyId, branchId, periodStart);

        // Záró napi mérlegek — dekád utolsó napja
        List<DailyBalance> closingBalances =
            dailyBalanceRepository.findByBranchIdAndBalanceDate(companyId, branchId, periodEnd);

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

        // Remove the previous lines (regeneration).
        // FKH-063 (board #42): the removal MUST be flushed to the database BEFORE the new lines
        // are inserted. Hibernate orders INSERTs before orphan DELETEs within one flush, so
        // regenerating an existing DRAFT report used to fail on
        // `uk_decade_line_report_currency` (V82). Only meaningful for an already persisted
        // report — on first generation the report is still transient.
        boolean regenerating = report.getId() != null && !report.getLines().isEmpty();
        report.getLines().clear();
        if (regenerating) {
            decadeReportRepository.saveAndFlush(report);
        }

        for (String currency : allCurrencies) {
            BigDecimal openingBal = openingMap.getOrDefault(currency, BigDecimal.ZERO);
            BigDecimal closingBal = closingMap.getOrDefault(currency, BigDecimal.ZERO);

            // Valuation rate for one unit — with a walk-back when the date itself has none.
            // FKH-061 (Defect D): a ZERO stock needs no rate. The decade currency set comes from
            // the daily-balance rows and includes currencies MNB does not quote (in production
            // BAM/RSD, both with 0.00 opening AND 0.00 closing). Those made getUnitRate throw a
            // ValidationException, failing the entire decade report — although the value would be
            // 0 HUF at any rate. So a zero balance yields a null rate (we do not invent a value)
            // and a 0.00 value. FKH-063: the rate (and now its provenance)
            // is still MANDATORY for non-zero stock: there the resolveUnitRate throw is correct
            // (invariant #5).
            ResolvedRate openingResolved = openingBal.signum() == 0
                ? null
                : resolveUnitRate(openingRates, companyId, currency, periodStart);
            ResolvedRate closingResolved = closingBal.signum() == 0
                ? null
                : resolveUnitRate(closingRates, companyId, currency, periodEnd);

            BigDecimal openingRate = openingResolved == null ? null : openingResolved.rate();
            BigDecimal closingRate = closingResolved == null ? null : closingResolved.rate();

            // Felértékelés HUF-ra
            BigDecimal openingValueHuf = openingRate == null
                ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
                : openingBal.multiply(openingRate).setScale(2, RoundingMode.HALF_UP);
            BigDecimal closingValueHuf = closingRate == null
                ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
                : closingBal.multiply(closingRate).setScale(2, RoundingMode.HALF_UP);
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
                .openingRateSource(openingResolved == null ? null : openingResolved.source())
                .closingRateSource(closingResolved == null ? null : closingResolved.source())
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
     * A resolved valuation rate together with its provenance (FKH-063).
     *
     * @param rate   the rate for one unit of the currency
     * @param source {@code MNB} (official cache) or {@code MANUAL_SETTLEMENT} (FK-028 hand-entered)
     */
    private record ResolvedRate(BigDecimal rate, String source) { }

    /** FKH-063: provenance marker for a rate taken from the official MNB cache. */
    private static final String RATE_SOURCE_MNB = "MNB";
    /** FKH-063: provenance marker for a rate taken from the FK-028 settlement-rate history. */
    private static final String RATE_SOURCE_MANUAL = "MANUAL_SETTLEMENT";

    /**
     * FKH-063: {@code decade_report_line.opening/closing_mnb_rate} is {@code NUMERIC(12,4)},
     * i.e. 8 integer digits — narrower than the FK-028 input bound of 11 (NUMERIC(15,4)).
     */
    private static final int MAX_REPORT_RATE_INTEGER_DIGITS = 8;

    /**
     * Resolves the valuation rate for one unit of the currency, together with its provenance.
     *
     * <p>Resolution order — the official MNB rate ALWAYS wins:</p>
     * <ol>
     *   <li>the MNB rate map of the date itself ({@code source='MNB'} cache),</li>
     *   <li>up to a 7-day walk-back in the same cache (weekend, public holiday),</li>
     *   <li>FKH-063: the company's hand-entered FK-028 settlement rate, but ONLY for a currency
     *       MNB does not quote at all.</li>
     * </ol>
     *
     * <p>The manual arm is deliberately restricted to currencies MNB never quotes
     * ({@code MnbExchangeRateService.isQuotedByMnb}). A temporary MNB cache gap for a quoted
     * currency (for example
     * a newly activated code, or a failed download) must NOT silently switch the statutory
     * valuation over to a hand-entered rate — that would be a different, undeclared rate source
     * for a currency the MNB does quote. Such a gap keeps failing closed, which is the signal
     * that the MNB import needs fixing.</p>
     *
     * <p>If no source yields a rate, {@link ValidationException} — a non-zero stock is NEVER
     * valued at 0 HUF (invariant #5). The caller has already skipped zero stock.</p>
     */
    private ResolvedRate resolveUnitRate(Map<String, MnbExchangeRateCache> rates, UUID companyId,
                                         String currency, LocalDate date) {
        MnbExchangeRateCache rate = rates.get(currency);
        if (rate != null) {
            return new ResolvedRate(rate.getRatePerUnit(), RATE_SOURCE_MNB);
        }

        // Fallback: up to a 7-day walk-back in the MNB cache
        for (int i = 1; i <= 7; i++) {
            Map<String, MnbExchangeRateCache> fallbackRates =
                mnbExchangeRateService.getRatesForDate(date.minusDays(i));
            MnbExchangeRateCache fallbackRate = fallbackRates.get(currency);
            if (fallbackRate != null) {
                log.info("MNB rate fallback: no {} rate for {}, stepping back {} day(s) ({})",
                    currency, date, i, date.minusDays(i));
                return new ResolvedRate(fallbackRate.getRatePerUnit(), RATE_SOURCE_MNB);
            }
        }

        // FKH-063: MNB (and Raiffeisen) never quote these currencies (BAM/BRL/EUA/ILS/MXN/NZD/
        // RSD/THB) — the main vault records them by hand on the FK-028 screen. The manual rate is
        // company-scoped and read as-of the valuation date. Guarded by hasAnyMnbCoverage so a
        // temporary cache gap for a QUOTED currency still fails closed instead of silently
        // switching to another rate source.
        if (!mnbExchangeRateService.isQuotedByMnb(currency)) {
            Optional<BigDecimal> manualRate =
                mnbSettlementRateService.findSettlementRateAsOf(companyId, currency, date);
            if (manualRate.isPresent()) {
                BigDecimal resolved = manualRate.get();
                // FKH-063 (PR review): FK-028 accepts up to 11 integer digits (NUMERIC(15,4)),
                // but decade_report_line.opening/closing_mnb_rate is NUMERIC(12,4) = 8 integer
                // digits. Persisting a wider value would fail the INSERT deep inside the flush,
                // after the money arithmetic, with an opaque error. Fail closed HERE with an
                // actionable message instead; the columns are not widened, because no realistic
                // rate for these currencies needs more than 8 integer digits.
                if (resolved.precision() - resolved.scale() > MAX_REPORT_RATE_INTEGER_DIGITS) {
                    throw new ValidationException(
                        "A rögzített MNB elszámolási árfolyam túl nagy a dekádjelentéshez: "
                        + currency + " = " + resolved.toPlainString() + " (dátum: " + date
                        + "). A jelentés legfeljebb " + MAX_REPORT_RATE_INTEGER_DIGITS
                        + " egész jegyű árfolyamot tud tárolni. "
                        + "Ellenőrizze az árfolyamot a Főértéktár → MNB árfolyamok rögzítése oldalon.");
                }
                log.info("FKH-063 manual settlement rate used: currency={}, date={}, source={}",
                    currency, date, RATE_SOURCE_MANUAL);
                return new ResolvedRate(resolved, RATE_SOURCE_MANUAL);
            }
        }

        throw new ValidationException(
            "Hiányzó értékelési árfolyam a dekádjelentéshez: " + currency +
            " (dátum: " + date + "). Nincs MNB árfolyam (7 napos visszalépés után sem) és " +
            "nincs rögzített MNB elszámolási árfolyam sem. " +
            "Rögzítse a Főértéktár → MNB árfolyamok rögzítése oldalon."
        );
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
    private void calculateForintControl(DecadeReport report, UUID companyId, UUID branchId,
                                         LocalDate periodStart, LocalDate periodEnd) {

        // Aktív tranzakciók a dekádban — riport-celu, financialEffective szurve.
        // User-direktiva 2026-05-03: 10 napos dekad-riport NEM duplazhatja a parent
        // CONVERSION sorokat. `findFinanciallyEffectiveByBranchAndDateRange` szuri.
        List<Transaction> transactions = transactionRepository
            .findFinanciallyEffectiveByBranchAndDateRange(branchId, periodStart, periodEnd);

        // HUF napi mérleg a nyitó napra (forint nyitó)
        List<DailyBalance> openingHufBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(companyId, branchId, periodStart);
        BigDecimal forintOpening = openingHufBalances.stream()
            .filter(b -> "HUF".equals(b.getCurrencyCode()))
            .map(DailyBalance::getOpeningBalance)
            .findFirst()
            .orElse(BigDecimal.ZERO);

        // HUF napi mérleg a záró napra (forint záró)
        List<DailyBalance> closingHufBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(companyId, branchId, periodEnd);
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
                // Eladás: HUF bejön az ügyféltől → bevétel (kezelési díj már benne van a hufAmount-ban)
                totalIncome = totalIncome.add(huf);
            } else if (tx.getTransactionType().isBuyType()) {
                // Vétel: HUF kimegy az ügyfélnek → kiadás
                totalExpense = totalExpense.add(huf);
                // Vétel kezelési díja: különálló bevétel, NINCS benne a hufAmount-ban
                BigDecimal fee = tx.getHandlingFee();
                if (fee != null && fee.compareTo(BigDecimal.ZERO) != 0) {
                    totalIncome = totalIncome.add(fee);
                }
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
        // Bug 3 fix: printControlFlag beállítása — korábban mindig false maradt
        report.setPrintControlFlag(valid);
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

    /**
     * Napzárás teljességi ellenőrzés: a dekád utolsó napjának lezárt napi mérleggel kell rendelkeznie.
     * Ha nem, ValidationException-t dob.
     */
    private void validateDailyClosingCompleteness(UUID companyId, UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        List<LocalDate> closedDates = dailyBalanceRepository.findClosedDates(companyId, branchId, periodStart, periodEnd);
        if (!closedDates.contains(periodEnd)) {
            throw new ValidationException(
                "A dekádjelentés nem generálható: a dekád utolsó napja (" + periodEnd +
                ") még nincs lezárva (nincs napzárás). Előbb végezze el a napzárást!"
            );
        }
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
            .openingRateSource(line.getOpeningRateSource())
            .closingRateSource(line.getClosingRateSource())
            .build();
    }
}
