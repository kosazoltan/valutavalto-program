package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Napi készlet / forgalom szolgáltatás.
 *
 * A Delphi napi záráskor számolta a készletmozgást:
 * nyitó + vétel + átvétel - eladás - átadás = záró
 *
 * Ez a számviteli lánc alapja, nélkülözhetetlen a havi záráshoz.
 *
 * Legacy: NAPZAR.DLL — napi forgalom számítás
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DailyBalanceService {

    private static final DateTimeFormatter YEAR_MONTH_FMT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final DailyBalanceRepository dailyBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final TransactionLineRepository transactionLineRepository;
    private final TransferRepository transferRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final AuditLogService auditLogService;
    private final MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final BranchRepository branchRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;

    /**
     * Napi mérleg számítása egy iroda + dátum + valuta kombinációhoz.
     *
     * @param branchId    Iroda ID
     * @param date        Dátum
     * @param currencyCode Valuta kód
     * @return Számított DailyBalance
     */
    public DailyBalance calculateDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        log.info("Napi mérleg számítása: branchId={}, date={}, currency={}", branchId, date, currencyCode);

        // Cég azonosító
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ValidationException("Cég nem található: " + companyId));

        // Ellenőrzés: már létezik-e
        DailyBalance existing = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElse(null);

        if (existing != null && existing.getIsClosed()) {
            throw new ValidationException(
                String.format("A %s napi mérleg már lezárva! (%s)", date, currencyCode)
            );
        }

        // 1. Nyitó készlet (háromszintű fallback)
        BigDecimal openingBalance = getOpeningBalance(branchId, date, currencyCode);

        // 2. Vásárlás (BUY) — multi-line-helyes (Codex #903, l. #913 snapshot-fix): az egy-soros
        //    tranzakciók ÉS a multi-line bizonylatok tétel-sorai (TransactionLine) összege valutánként.
        //    A régi header-alapú sumDailyTurnoverByCurrency multi-valutás bizonylatnál az első valutára
        //    számolta a teljes összeget → téves per-valuta napi zárás-egyenleg.
        BigDecimal purchases = dailyCurrencyTurnover(branchId, date, TransactionType.BUY, currencyCode);

        // 3. Eladás (SELL) — ugyanaz a multi-line-helyes összegzés
        BigDecimal sales = dailyCurrencyTurnover(branchId, date, TransactionType.SELL, currencyCode);

        // 4. Átvétel más irodától (transfer IN)
        BigDecimal transfersIn = getTransfersIn(branchId, date, currencyCode);
        if (transfersIn == null) {
            transfersIn = BigDecimal.ZERO;
        }

        // 5. Átadás más irodába (transfer OUT)
        BigDecimal transfersOut = getTransfersOut(branchId, date, currencyCode);
        if (transfersOut == null) {
            transfersOut = BigDecimal.ZERO;
        }

        // 6. Záró készlet számítása
        BigDecimal closingBalance = openingBalance
            .add(purchases)
            .add(transfersIn)
            .subtract(sales)
            .subtract(transfersOut);

        // DailyBalance entity
        DailyBalance balance = existing != null ? existing : DailyBalance.builder()
            .branchId(branchId)
            .balanceDate(date)
            .currencyCode(currencyCode)
            .company(company)
            .isClosed(false)
            .build();

        balance.setOpeningBalance(openingBalance);
        balance.setPurchases(purchases);
        balance.setTransfersIn(transfersIn);
        balance.setSales(sales);
        balance.setTransfersOut(transfersOut);
        balance.setClosingBalance(closingBalance);

        // Mentés
        DailyBalance saved = dailyBalanceRepository.save(balance);

        log.info("Napi mérleg kész: opening={}, purchases={}, transfersIn={}, sales={}, transfersOut={}, closing={}",
            openingBalance, purchases, transfersIn, sales, transfersOut, closingBalance);

        return saved;
    }

    /**
     * Összes valuta napi mérlege (egy napra).
     *
     * FIX: Per-valuta hiba izolálás — egy valuta hibája nem állítja le a többi feldolgozását.
     * Részleges hiba esetén audit log bejegyzés készül.
     */
    public List<DailyBalance> calculateAllCurrenciesForDay(UUID branchId, LocalDate date) {
        log.info("Összes valuta napi mérlege: branchId={}, date={}", branchId, date);

        // Aktív valuták
        List<Currency> currencies = currencyRepository.findActiveByCompany(SecurityUtils.getCurrentCompanyId());

        List<DailyBalance> results = new ArrayList<>();
        List<String> failedCurrencies = new ArrayList<>();

        for (Currency currency : currencies) {
            try {
                DailyBalance balance = calculateDailyBalance(branchId, date, currency.getCode());
                results.add(balance);
            } catch (Exception e) {
                log.error("Napi mérleg számítási hiba: branchId={}, date={}, currency={} — {}",
                    branchId, date, currency.getCode(), e.getMessage(), e);
                failedCurrencies.add(currency.getCode());
            }
        }

        if (!failedCurrencies.isEmpty()) {
            String failedList = String.join(", ", failedCurrencies);
            log.warn("Részleges napi mérleg hiba: branchId={}, date={}, hibás valuták: {}",
                branchId, date, failedList);
            auditLogService.log(
                "DAILY_BALANCE_PARTIAL_FAILURE",
                String.format("Részleges napi mérleg hiba (%s): hibás valuták: %s", date, failedList),
                branchId.toString()
            );
        }

        return results;
    }

    /**
     * Nyitó készlet számítása — háromszintű fallback:
     *
     * 1. Előző napi záró egyenleg (DailyBalance tábla)
     * 2. Előző havi lezárt összesítő (MonthlyClosingSummary — currency breakdown JSON-ből)
     * 3. Aktuális valutakészlet (CurrencyStock.quantity)
     * 4. Nulla (első nap az irodában)
     */
    BigDecimal getOpeningBalance(UUID branchId, LocalDate date, String currencyCode) {
        // Szint 1: előző nap záró egyenlege
        LocalDate previousDay = date.minusDays(1);
        Optional<BigDecimal> previousClosing = dailyBalanceRepository
            .findClosingBalance(branchId, currencyCode, previousDay);

        if (previousClosing.isPresent()) {
            log.debug("Nyitó egyenleg forrása: előző napi záró ({}): {}", previousDay, previousClosing.get());
            return previousClosing.get();
        }

        // Szint 2: előző havi MonthlyClosingSummary (currencyBreakdown JSON)
        LocalDate prevMonthDate = date.minusMonths(1);
        String prevYearMonth = prevMonthDate.format(YEAR_MONTH_FMT);

        Optional<MonthlyClosingSummary> monthlySummary =
            monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(branchId, prevYearMonth);

        if (monthlySummary.isPresent()) {
            BigDecimal monthlyClosingBalance = extractCurrencyClosingFromSummary(
                monthlySummary.get(), currencyCode);
            if (monthlyClosingBalance != null) {
                log.debug("Nyitó egyenleg forrása: havi összesítő ({}, {}): {}",
                    prevYearMonth, currencyCode, monthlyClosingBalance);
                return monthlyClosingBalance;
            }
        }

        // Szint 3: CurrencyStock.quantity (iroda jelenlegi készlete)
        Optional<CurrencyStock> stock = currencyStockRepository
            .findByBranchIdAndCurrencyCode(branchId.toString(), currencyCode);

        if (stock.isPresent() && stock.get().getQuantity() != null
                && stock.get().getQuantity().compareTo(BigDecimal.ZERO) > 0) {
            log.debug("Nyitó egyenleg forrása: CurrencyStock.quantity ({}): {}",
                currencyCode, stock.get().getQuantity());
            return stock.get().getQuantity();
        }

        // Szint 4: nulla — első nap az irodában
        log.warn("Nincs nyitó egyenleg forrás: branchId={}, currency={}, date={} → nyitó=0",
            branchId, currencyCode, date);
        return BigDecimal.ZERO;
    }

    /**
     * Kinyeri az adott valuta záró egyenlegét a MonthlyClosingSummary.currencyBreakdown JSON-ből.
     *
     * Elvárt JSON formátum:
     * [{"currencyCode":"EUR","closingBalance":5000.00,...}, ...]
     *
     * Ha a JSON nem tartalmaz closingBalance mezőt, visszatér null-lal.
     */
    private BigDecimal extractCurrencyClosingFromSummary(MonthlyClosingSummary summary, String currencyCode) {
        String breakdown = summary.getCurrencyBreakdown();
        if (breakdown == null || breakdown.isBlank()) {
            return null;
        }
        try {
            // Egyszerű JSON parsing — Spring Boot nem tartalmaz Jackson-t feleslegesen,
            // de a kontextusban elérhető. Kézi parse a függőség-mentes megoldáshoz.
            // Keressük: "currencyCode":"EUR" közelében a "closingBalance":<szám>
            String searchKey = "\"currencyCode\":\"" + currencyCode + "\"";
            int keyIdx = breakdown.indexOf(searchKey);
            if (keyIdx < 0) {
                return null;
            }
            // A "closingBalance" mező a currencyCode után vagy előtt lehet az objektumban
            // Keresés az adott blokkon belül: { ... "currencyCode":"EUR" ... "closingBalance":NNN ... }
            int blockStart = breakdown.lastIndexOf('{', keyIdx);
            int blockEnd = breakdown.indexOf('}', keyIdx);
            if (blockStart < 0 || blockEnd < 0) {
                return null;
            }
            String block = breakdown.substring(blockStart, blockEnd + 1);
            String closingKey = "\"closingBalance\":";
            int closingIdx = block.indexOf(closingKey);
            if (closingIdx < 0) {
                return null;
            }
            int valueStart = closingIdx + closingKey.length();
            int valueEnd = valueStart;
            while (valueEnd < block.length()) {
                char c = block.charAt(valueEnd);
                if (c == ',' || c == '}' || c == ' ') break;
                valueEnd++;
            }
            String valueStr = block.substring(valueStart, valueEnd).trim();
            return new BigDecimal(valueStr);
        } catch (Exception e) {
            log.warn("Havi összesítő currency breakdown parse hiba: currency={}, error={}",
                currencyCode, e.getMessage());
            return null;
        }
    }

    /**
     * Napi forgalom (deviza-mennyiség) valutánként, MULTI-LINE-helyesen: az egy-soros tranzakciók
     * ({@code sumDailySingleLineTurnoverByCurrency}) ÉS a multi-line bizonylatok tétel-sorai
     * ({@code TransactionLine.banknoteCount}, {@code sumDailyLineTurnoverByCurrency}) ÖSSZEGE.
     * Lásd a #913 snapshot-fix indoklását — a header-alapú összegzés multi-valutás bizonylatnál téves.
     */
    private BigDecimal dailyCurrencyTurnover(UUID branchId, LocalDate date, TransactionType type, String currencyCode) {
        BigDecimal single = transactionRepository.sumDailySingleLineTurnoverByCurrency(branchId, date, type, currencyCode);
        BigDecimal line = transactionLineRepository.sumDailyLineTurnoverByCurrency(branchId, date, type, currencyCode);
        return (single != null ? single : BigDecimal.ZERO).add(line != null ? line : BigDecimal.ZERO);
    }

    /**
     * Átvétel (transfer IN) számítása
     */
    private BigDecimal getTransfersIn(UUID branchId, LocalDate date, String currencyCode) {
        // FK-046 FR-3: a TH (Többlet-Hiány) elszámolási pénztár felőli tételek KIZÁRVA — azokat a
        // surplus/shortage mező hordozza, nem a normál pénztárközi átvétel.
        return transferRepository.sumTransfersInExcludingTh(branchId, date, currencyCode);
    }

    /**
     * Átadás (transfer OUT) számítása
     */
    private BigDecimal getTransfersOut(UUID branchId, LocalDate date, String currencyCode) {
        // FK-046 FR-3: a TH elszámolási pénztár felé irányuló tételek KIZÁRVA.
        return transferRepository.sumTransfersOutExcludingTh(branchId, date, currencyCode);
    }

    /**
     * Napi mérleg lezárása
     */
    public void closeDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        DailyBalance balance = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElseThrow(() -> new ValidationException(
                String.format("Nincs napi mérleg: %s / %s", date, currencyCode)
            ));

        if (balance.getIsClosed()) {
            throw new ValidationException("A mérleg már lezárva!");
        }

        balance.setIsClosed(true);
        balance.setClosedAt(LocalDateTime.now());
        balance.setClosedBy(SecurityUtils.getCurrentWorkerCode());

        dailyBalanceRepository.save(balance);

        auditLogService.log(
            "DAILY_BALANCE_CLOSED",
            String.format("Napi mérleg lezárva: %s / %s", date, currencyCode),
            branchId.toString()
        );

        log.info("Napi mérleg lezárva: branchId={}, date={}, currency={}", branchId, date, currencyCode);
    }

    /**
     * Leltári eltérés rögzítése
     */
    public void recordActualStock(
        UUID branchId,
        LocalDate date,
        String currencyCode,
        BigDecimal actualStock,
        String note
    ) {
        DailyBalance balance = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElseThrow(() -> new ValidationException(
                String.format("Nincs napi mérleg: %s / %s", date, currencyCode)
            ));

        balance.setActualStock(actualStock);
        balance.calculateDifference();

        if (note != null && !note.isBlank()) {
            balance.setDifferenceNote(note);
        }

        dailyBalanceRepository.save(balance);

        log.info("Leltári eltérés rögzítve: branchId={}, date={}, currency={}, actual={}, difference={}",
            branchId, date, currencyCode, actualStock, balance.getDifference());
    }

    /**
     * FK-046 — napi zárás SZÁMZÁR + Többlet/Hiány (TH) bekötés.
     *
     * <p>A napi zárás véglegesítésekor (a {@code calculateAllCurrenciesForDay} után, a napi mérleg-sorok
     * már léteznek) automatikusan, kézi beavatkozás nélkül rögzíti pénztári (NEM értéktári) irodákra:
     * <ul>
     *   <li>FR-1/2/7: a fizikailag leszámolt záró készletet (SZÁMZÁR = {@code actualStock}) a záráskori
     *       (EVENING) címlet-snapshotból, valutánként összegezve. Ha egy valutára nincs snapshot-sor,
     *       a mező üresen marad (nem 0), és a folyamat nem hibázik.</li>
     *   <li>FR-4/6/10: a TH elszámolási pénztárral szembeni, TELJESÍTETT (COMPLETED) tételeket
     *       irányhelyesen — TH-tól átvétel → Többlet ({@code surplus}), TH-nak átadás → Hiány
     *       ({@code shortage}) — valutánként, naponta.</li>
     *   <li>FR-5/8: az eltérés (számított záró − SZÁMZÁR) a meglévő {@code difference} mezőn marad.</li>
     *   <li>NFR-3: a HUF összegekre {@code HungarianRounding.roundToFive}.</li>
     *   <li>NFR-5: idempotens — ismételt zárás-futás felülírja, nem duplázza az értékeket.</li>
     * </ul>
     *
     * <p>FR-9: értéktári (is_vault=true) irodára NEM fut le. Hiba esetén NEM dob (a zárás ne akadjon meg),
     * a hívó {@code DailyClosingService} amúgy is try/catch-eli ezt a lépést.
     */
    public void recordClosingAdjustments(UUID branchId, LocalDate date) {
        Branch branch = branchRepository.findById(branchId).orElse(null);
        if (branch == null) {
            log.warn("FK-046 SZÁMZÁR/TH kihagyva: ismeretlen branch={}", branchId);
            return;
        }
        // FR-9: kizárólag pénztári (nem értéktári) irodákra.
        if (Boolean.TRUE.equals(branch.getIsVault())) {
            log.debug("FK-046 SZÁMZÁR/TH kihagyva (értéktári iroda): branch={}", branchId);
            return;
        }

        // FR-2: a záráskori (EVENING) címlet-snapshotból valutánként összesített SZÁMZÁR.
        // GLM #1 fix: [date, date+1) félzárt tartomány — a következő napi snapshot nem szivárog be.
        Map<String, BigDecimal> actualStockByCurrency = new HashMap<>();
        for (Object[] row : denominationBalanceRepository.sumActualStockByCurrency(
                branchId, date, date.plusDays(1), DenominationCategory.EVENING)) {
            if (row[0] == null) {
                continue;
            }
            actualStockByCurrency.put((String) row[0], toBd(row[1]));
        }

        // A nap napi mérleg-sorai valutakód szerint indexelve (idempotens felülíráshoz).
        Map<String, DailyBalance> balanceByCurrency = new HashMap<>();
        for (DailyBalance b : dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date)) {
            balanceByCurrency.put(b.getCurrencyCode(), b);
        }

        // GLM #3 fix (FR-1/9.2 Fázis 2.a): a feldolgozandó valuták halmaza = a meglévő mérleg-sorok
        // ∪ a snapshot-tal rendelkező valuták. Így annak a valutának is rögzül a SZÁMZÁR, amelyre
        // aznap nem volt mozgás (és így nincs előzetes mérleg-sor), de van záráskori címletezés.
        Set<String> currencies = new LinkedHashSet<>(balanceByCurrency.keySet());
        currencies.addAll(actualStockByCurrency.keySet());

        Company company = null; // lazy — csak ha új sort kell létrehozni
        int processed = 0;
        for (String currencyCode : currencies) {
            DailyBalance balance = balanceByCurrency.get(currencyCode);
            if (balance == null) {
                // Csak snapshot-tal rendelkező valuta: hozzunk létre mérleg-sort (nyitó/forgalom 0).
                if (company == null) {
                    UUID companyId = SecurityUtils.getCurrentCompanyId();
                    company = companyRepository.findById(companyId).orElse(null);
                    if (company == null) {
                        log.warn("FK-046: cég nem található ({}), a csak-snapshot valuta kihagyva: {}",
                            companyId, currencyCode);
                        continue;
                    }
                }
                balance = DailyBalance.builder()
                    .branchId(branchId).balanceDate(date).currencyCode(currencyCode)
                    .company(company).isClosed(false).build();
            } else if (Boolean.TRUE.equals(balance.getIsClosed())) {
                continue; // lezárt sort nem írunk felül
            }

            // FR-4/6/10: TH-alapú Többlet/Hiány (irányhelyesen, csak COMPLETED tételek).
            // GLM #2 fix (NFR-3): a roundToFive (5 Ft-os szabály) CSAK HUF-ra; más valuta változatlan.
            BigDecimal surplus = roundIfHuf(currencyCode, toBd(transferRepository.sumSurplusFromTh(branchId, date, currencyCode)));
            BigDecimal shortage = roundIfHuf(currencyCode, toBd(transferRepository.sumShortageToTh(branchId, date, currencyCode)));
            // NFR-5: idempotens felülírás (nem additív).
            balance.setSurplus(surplus);
            balance.setShortage(shortage);

            // FR-1/2/7: SZÁMZÁR a snapshotból; ha nincs az adott valutára, a mező ÜRES marad (nem 0).
            BigDecimal actual = actualStockByCurrency.get(currencyCode);
            if (actual != null) {
                balance.setActualStock(roundIfHuf(currencyCode, actual));
            }

            // FR-5/8: a számított záró (MNB-validáció a Többlet/Hiány-nyal) + eltérés a SZÁMZÁR-hoz.
            balance.calculateMnbValidation();
            balance.calculateDifference();
            dailyBalanceRepository.save(balance);
            processed++;
        }

        // §6.b audit (KAT=TX): a Többlet/Hiány a napi mérlegre íródott (pénzügyi adat-módosítás).
        auditLogService.log(
            "DAILY_BALANCE_TH_ADJUSTMENT",
            String.format("{\"KAT\":\"TX\",\"date\":\"%s\",\"branch_id\":\"%s\",\"currencies\":%d}",
                date, branchId, processed),
            branchId.toString()
        );
        log.info("FK-046 SZÁMZÁR + Többlet/Hiány rögzítve: branchId={}, date={}, valuták={}",
            branchId, date, processed);
    }

    /** Object[]-ből biztonságos BigDecimal (COALESCE 0 + null-véd). */
    private static BigDecimal toBd(Object value) {
        return value == null ? BigDecimal.ZERO : (BigDecimal) value;
    }

    /**
     * FK-046 NFR-3 (GLM #2 fix): az 5 Ft-os magyar kerekítést KIZÁRÓLAG HUF összegre alkalmazzuk.
     * Más valuta (EUR/USD/…) értékét változatlanul adjuk vissza — egy EUR összeget 5-ös léptékre
     * kerekíteni hibás pénzügyi érték lenne.
     */
    private static BigDecimal roundIfHuf(String currencyCode, BigDecimal value) {
        if (value == null) {
            return null;
        }
        return "HUF".equals(currencyCode) ? HungarianRounding.roundToFive(value) : value;
    }

    /**
     * Napi mérleg lekérdezése
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getDailyBalances(UUID branchId, LocalDate date) {
        return dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date);
    }

    /**
     * Havi mérlegek lekérdezése
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getMonthlyBalances(UUID branchId, int year, int month) {
        return dailyBalanceRepository.findByBranchAndMonth(branchId, year, month);
    }
}
