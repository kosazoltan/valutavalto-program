package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.IsoFields;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * AML (Anti Money Laundering) / Gongyolesi kontroll szolgaltatas.
 *
 * Legacy: BIGCTRL.DLL
 * Input:  ugyfeltipus, ugyfelszam, fizetendo, konverzio, bizonylatszam (VTEMP-en keresztul)
 * Output: gongyolt, sorszam, nevtabla, forras, engedelyezo, plombaszam
 *
 * Fo szabalyok:
 * 1. 300.000 Ft felett KOTELEZO ugyfel azonositas (NAV eloiras)
 * 2. Eves gongyolesi limit: termeszetes szemely = 3.600.000 Ft/ev
 *    (Ha elerte -> kotelezo "nagy ugyfel" kezeles: reszletes nyilvantartas)
 * 3. 1.500.000 Ft feletti egyszeri tranzakcio -> reszletes azonositas + bejelentesi kotelezettseg
 * 4. Terrorlista ellenorzes
 * 5. Gyanus tranzakcio jelzes
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class AmlService {

    private final TransactionRepository transactionRepository;
    private final CustomerRepository customerRepository;

    /** Azonositas nelkuli limit (NAV) */
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    /** Eves gongyolesi limit termeszetes szemelyeknel */
    private static final BigDecimal ANNUAL_ROLLING_LIMIT = new BigDecimal("3600000");

    /** Reszletes azonositasi limit (bejelentes kotelezo) */
    private static final BigDecimal DETAILED_ID_LIMIT = new BigDecimal("1500000");

    /** Napi gyanusagi limit (tobb kisebb tranzakcio osszege) */
    private static final BigDecimal DAILY_SUSPICIOUS_LIMIT = new BigDecimal("900000");

    /**
     * Tranzakcio elotti AML ellenorzes.
     *
     * Legacy: BIGCTRL.DLL - a tranzakcio konyvelesetol fut le
     * result: 1 = ugyfel konyvelve (OK), 2 = STOP, 3 = nincs ugyfelszam/internet
     */
    public AmlBasicCheckResult checkTransaction(
            BigDecimal hufAmount,
            String customerId,
            String customerName,
            String documentNumber) {

        // Input validacio
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) < 0) {
            return AmlBasicCheckResult.builder()
                .approved(false)
                .rejectionReason("Ervenytelen tranzakcio osszeg")
                .build();
        }

        AmlBasicCheckResult.AmlBasicCheckResultBuilder result = AmlBasicCheckResult.builder()
            .approved(true)
            .requiresIdentification(false)
            .requiresDetailedId(false)
            .annualLimitReached(false)
            .suspiciousFlag(false);

        // 1. Azonositasi kotelezettseg ellenorzes (300K+ Ft)
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            result.requiresIdentification(true);

            if (customerName == null || customerName.isBlank()
                || documentNumber == null || documentNumber.isBlank()) {
                result.approved(false);
                result.rejectionReason(
                    IDENTIFICATION_LIMIT.toPlainString() + " Ft feletti tranzakciohoz ugyfel azonositas (nev + igazolvany) KOTELEZO!");
                return result.build();
            }
        }

        // 2. Reszletes azonositas (1.5M+ Ft) - bejelentesi kotelezettseg
        if (hufAmount.compareTo(DETAILED_ID_LIMIT) >= 0) {
            result.requiresDetailedId(true);
            result.requiresIdentification(true);
            log.warn("AML: Reszletes azonositas szukseges - {} Ft (>= {} Ft limit)",
                hufAmount, DETAILED_ID_LIMIT);
        }

        // 3. Eves gongyolesi kontroll (ha van ugyfel azonosito)
        // HIGH FIX: .isBlank() konzisztens validáció (Java 11+)
        if (customerId != null && !customerId.isBlank()) {
            BigDecimal annualTotal = getAnnualRollingTotal(customerId);
            BigDecimal projectedTotal = annualTotal.add(hufAmount);

            if (projectedTotal.compareTo(ANNUAL_ROLLING_LIMIT) >= 0) {
                result.annualLimitReached(true);
                result.annualTotal(annualTotal);
                result.projectedTotal(projectedTotal);
                log.warn("AML: Eves gongyolesi limit elerve - ugyfel: {}, eves: {} Ft, tervezett: {} Ft",
                    customerId, annualTotal, projectedTotal);

                if (!SecurityUtils.isSupervisorOrAbove()) {
                    result.requiresApproval(true);
                    result.approvalReason("Eves gongyolesi limit (" + ANNUAL_ROLLING_LIMIT + " Ft) elerve. Supervisor jovahagyas szukseges.");
                }
            }

            result.annualTotal(annualTotal);
            result.projectedTotal(projectedTotal);
        }

        // 4. Napi gyanusagi ellenorzes (tobb kis tranzakcio ugyanattol az ugyfeltol)
        if (customerId != null) {
            BigDecimal dailyTotal = getDailyCustomerTotal(customerId);
            if (dailyTotal.add(hufAmount).compareTo(DAILY_SUSPICIOUS_LIMIT) >= 0) {
                result.suspiciousFlag(true);
                log.warn("AML: Gyanus napi osszeg - ugyfel: {}, napi osszeg: {} Ft",
                    customerId, dailyTotal.add(hufAmount));
            }
        }

        return result.build();
    }

    /**
     * Ugyfel eves gongyoles lekerese.
     * Legacy: Az ugyfel{evtized}.fdb-bol olvasta az eves osszesitest.
     */
    @Transactional(readOnly = true)
    public BigDecimal getAnnualRollingTotal(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate yearStart = LocalDate.of(LocalDate.now().getYear(), 1, 1);
        LocalDate today = LocalDate.now();

        BigDecimal total = transactionRepository.sumCustomerAnnualTotal(
            companyId, customerId, yearStart, today);

        return total != null ? total : BigDecimal.ZERO;
    }

    /**
     * Ugyfel napi tranzakcios osszeg lekerese.
     */
    @Transactional(readOnly = true)
    public BigDecimal getDailyCustomerTotal(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        BigDecimal total = transactionRepository.sumCustomerDailyTotal(
            companyId, customerId, LocalDate.now());

        return total != null ? total : BigDecimal.ZERO;
    }

    /**
     * Ugyfel tranzakcios osszesites (admin feluletre).
     */
    @Transactional(readOnly = true)
    public CustomerAmlSummary getCustomerSummary(String customerId) {
        BigDecimal annualTotal = getAnnualRollingTotal(customerId);
        BigDecimal dailyTotal = getDailyCustomerTotal(customerId);

        return CustomerAmlSummary.builder()
            .customerId(customerId)
            .annualTotal(annualTotal)
            .annualLimit(ANNUAL_ROLLING_LIMIT)
            .annualUsagePercent(annualTotal.multiply(new BigDecimal("100"))
                .divide(ANNUAL_ROLLING_LIMIT, 1, RoundingMode.HALF_UP))
            .dailyTotal(dailyTotal)
            .identificationRequired(annualTotal.compareTo(IDENTIFICATION_LIMIT) >= 0)
            .limitReached(annualTotal.compareTo(ANNUAL_ROLLING_LIMIT) >= 0)
            .build();
    }

    // ============ RESULT DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class AmlBasicCheckResult {
        private boolean approved;
        private boolean requiresIdentification;
        private boolean requiresDetailedId;
        private boolean requiresApproval;
        private boolean annualLimitReached;
        private boolean suspiciousFlag;
        private String rejectionReason;
        private String approvalReason;
        private BigDecimal annualTotal;
        private BigDecimal projectedTotal;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CustomerAmlSummary {
        private String customerId;
        private BigDecimal annualTotal;
        private BigDecimal annualLimit;
        private BigDecimal annualUsagePercent;
        private BigDecimal dailyTotal;
        private boolean identificationRequired;
        private boolean limitReached;
    }

    // ============ LEGACY BIGCTRL.DLL IMPLEMENTÁCIÓ ============

    /** Legacy: 50M — kiemelt figyelmet igénylő (TranzTipus 6) */
    private static final BigDecimal THRESHOLD_50M = new BigDecimal("50000000");

    /** Legacy: 10M — fokozott figyelmet igénylő (TranzTipus 5) */
    private static final BigDecimal THRESHOLD_10M = new BigDecimal("10000000");

    /** Legacy: 25M negyedéves (TranzTipus 4) */
    private static final BigDecimal THRESHOLD_25M_QUARTERLY = new BigDecimal("25000000");

    /** Legacy: 8M éves ismétlődő (TranzTipus 3) */
    private static final BigDecimal THRESHOLD_8M = new BigDecimal("8000000");

    /** Legacy: negyedéves tranzakciószám küszöb (TranzTipus 4) */
    private static final int QUARTERLY_TRANSACTION_COUNT_THRESHOLD = 4;

    /**
     * Heti göngyölés: az elmúlt 7 nap tranzakcióinak HUF összege.
     *
     * Legacy: BIGCTRL.DLL
     *   _diff = Napidiff(_lastdatum, _megnyitottnap)
     *   if _diff < 8 then _hasforint = _hasforint + _hetiforint
     *   HETIOSSZ mező az ügyfél táblában
     */
    @Transactional(readOnly = true)
    public BigDecimal getWeeklyTotal(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate sinceDate = LocalDate.now().minusDays(7);

        BigDecimal total = transactionRepository.sumCustomerWeeklyTotal(
            companyId, customerId, sinceDate);
        return total != null ? total : BigDecimal.ZERO;
    }

    /**
     * Éves maximum tranzakció összeg.
     *
     * Legacy: EVIMAX mező — az adott évi legnagyobb tranzakció
     */
    @Transactional(readOnly = true)
    public BigDecimal getYearlyMax(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate now = LocalDate.now();
        LocalDate yearStart = LocalDate.of(now.getYear(), 1, 1);
        LocalDate yearEnd = LocalDate.of(now.getYear(), 12, 31);

        BigDecimal max = transactionRepository.findCustomerYearlyMax(
            companyId, customerId, yearStart, yearEnd);
        return max != null ? max : BigDecimal.ZERO;
    }

    /**
     * Negyedéves statisztikák: tranzakciószám és összeg.
     *
     * Legacy: BIGCTRL.DLL TranzTipus 4 — 4+ tranzakció ÉS >= 25M
     *
     * @return long[0] = count, BigDecimal[0] = total (visszatérés QuarterlyStats-ban)
     */
    @Transactional(readOnly = true)
    public QuarterlyStats getQuarterlyStats(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate now = LocalDate.now();

        int quarter = now.get(IsoFields.QUARTER_OF_YEAR);
        int year = now.getYear();
        LocalDate quarterStart = LocalDate.of(year, (quarter - 1) * 3 + 1, 1);
        LocalDate quarterEnd = quarterStart.plusMonths(3).minusDays(1);

        long count = transactionRepository.countCustomerQuarterlyTransactions(
            companyId, customerId, quarterStart, quarterEnd);
        BigDecimal total = transactionRepository.sumCustomerQuarterlyTotal(
            companyId, customerId, quarterStart, quarterEnd);

        return QuarterlyStats.builder()
            .count(count)
            .total(total != null ? total : BigDecimal.ZERO)
            .build();
    }

    /**
     * Legacy TranzTipus klasszifikáció.
     *
     * BIGCTRL.DLL logika PONTOSAN:
     *  6: _hasforint >= 50.000.000
     *  5: _hasforint >= 10.000.000
     *  4: negyedév 4+ tranzakció ÉS _negyedevFt >= 25.000.000
     *  3: _evimax >= 8.000.000 ÉS _hasforint >= 8.000.000
     *  2: külföldi ügyfél
     *  1: belföldi kiemelt közszereplő (PEP)
     * -1: külföldi, nem kaphat USD-t
     *  0: normál
     *
     * @param customerId   ügyfél azonosító
     * @param hufAmount    aktuális tranzakció HUF összeg (a heti göngyöléssel együtt)
     * @param currencyCode valuta kód (EUR, USD, stb.) — külföldi + USD = -1 blokkolás
     * @return TranzTipus érték (-1, 0, 1, 2, 3, 4, 5, 6)
     */
    @Transactional(readOnly = true)
    public int classifyTransaction(String customerId, BigDecimal hufAmount, String currencyCode) {
        if (customerId == null || customerId.isBlank()) {
            // Névtelen ügyfél — csak összeg alapján
            return classifyByAmount(hufAmount);
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Heti göngyölés: aktuális + elmúlt 7 nap
        BigDecimal weeklyTotal = getWeeklyTotal(customerId);
        BigDecimal hasforint = hufAmount.add(weeklyTotal);

        // TranzTipus 6: >= 50M
        if (hasforint.compareTo(THRESHOLD_50M) >= 0) {
            return 6;
        }

        // TranzTipus 5: >= 10M
        if (hasforint.compareTo(THRESHOLD_10M) >= 0) {
            return 5;
        }

        // TranzTipus 4: negyedéves 4+ tranzakció ÉS >= 25M
        QuarterlyStats qStats = getQuarterlyStats(customerId);
        if (qStats.getCount() >= QUARTERLY_TRANSACTION_COUNT_THRESHOLD
            && qStats.getTotal().compareTo(THRESHOLD_25M_QUARTERLY) >= 0) {
            return 4;
        }

        // TranzTipus 3: éves max >= 8M ÉS aktuális hasforint >= 8M
        BigDecimal yearlyMax = getYearlyMax(customerId);
        if (yearlyMax.compareTo(THRESHOLD_8M) >= 0
            && hasforint.compareTo(THRESHOLD_8M) >= 0) {
            return 3;
        }

        // Ügyfél-specifikus ellenőrzések (isForeign, isPep)
        Optional<Customer> customerOpt = customerRepository
            .findByCustomerCodeAndCompanyId(customerId, companyId);

        if (customerOpt.isPresent()) {
            Customer customer = customerOpt.get();

            // TranzTipus -1 és 2: külföldi ügyfél
            // HIGH FIX #1: Explicit NULL kezelés + audit log
            if (Boolean.TRUE.equals(customer.getIsForeign())) {
                // HIGH FIX #4: TranzTipus -1 — külföldi ügyfél nem kaphat USD-t
                if ("USD".equals(currencyCode)) {
                    log.warn("AML: Külföldi ügyfél {} USD tranzakciót próbál — BLOKKOLVA (TranzTipus -1)",
                            customerId);
                    return -1;
                }
                return 2;
            } else if (customer.getIsForeign() == null) {
                log.warn("AML: Ügyfél {} isForeign=NULL — feltételezzük belföldi", customerId);
            }

            // TranzTipus 1: belföldi kiemelt közszereplő (PEP)
            // HIGH FIX #1: NULL-safe isPep ellenőrzés
            if (Boolean.TRUE.equals(customer.getIsPep())) {
                return 1;
            } else if (customer.getIsPep() == null) {
                log.warn("AML: Ügyfél {} isPep=NULL — feltételezzük nem-PEP", customerId);
            }
        }

        return 0; // normál
    }

    /**
     * Összeg alapú klasszifikáció (névtelen ügyfélnél).
     */
    private int classifyByAmount(BigDecimal hufAmount) {
        if (hufAmount.compareTo(THRESHOLD_50M) >= 0) {
            return 6;
        }
        if (hufAmount.compareTo(THRESHOLD_10M) >= 0) {
            return 5;
        }
        return 0;
    }

    /**
     * Minden AML küszöb ellenőrzése egyben.
     *
     * Visszaadja a teljes AmlCheckResult-ot a legacy BIGCTRL.DLL logika alapján.
     *
     * @param customerId   ügyfél azonosító
     * @param hufAmount    aktuális tranzakció forint összeg
     * @param currencyCode valuta kód (EUR, USD, stb.) — külföldi + USD = -1 blokkolás
     * @return AmlCheckResult DTO
     */
    @Transactional(readOnly = true)
    public hu.puzzleir.valuta.dto.aml.AmlCheckResult checkAllThresholds(String customerId, BigDecimal hufAmount, String currencyCode) {
        List<String> warnings = new ArrayList<>();
        boolean requiresId = false;
        boolean requiresEnhanced = false;
        boolean blocked = false;

        BigDecimal weeklyTotal = BigDecimal.ZERO;
        BigDecimal yearlyMax = BigDecimal.ZERO;
        int quarterlyCount = 0;
        BigDecimal quarterlyTotal = BigDecimal.ZERO;

        if (customerId != null && !customerId.isBlank()) {
            weeklyTotal = getWeeklyTotal(customerId);
            yearlyMax = getYearlyMax(customerId);

            QuarterlyStats qStats = getQuarterlyStats(customerId);
            quarterlyCount = (int) qStats.getCount();
            quarterlyTotal = qStats.getTotal();
        }

        BigDecimal hasforint = hufAmount.add(weeklyTotal);
        int transactionType = classifyTransaction(customerId, hufAmount, currencyCode);

        switch (transactionType) {
            case 6:
                requiresId = true;
                requiresEnhanced = true;
                warnings.add("KIEMELT: Heti göngyölt összeg >= 50.000.000 Ft (" + hasforint.toPlainString() + " Ft)");
                break;
            case 5:
                requiresId = true;
                requiresEnhanced = true;
                warnings.add("FOKOZOTT: Heti göngyölt összeg >= 10.000.000 Ft (" + hasforint.toPlainString() + " Ft)");
                break;
            case 4:
                requiresId = true;
                requiresEnhanced = true;
                warnings.add("NEGYEDÉVES: " + quarterlyCount + " tranzakció, összeg: " + quarterlyTotal.toPlainString() + " Ft (>= 25.000.000 Ft)");
                break;
            case 3:
                requiresId = true;
                warnings.add("ÉVES ISMÉTLŐDŐ: Éves max: " + yearlyMax.toPlainString() + " Ft, aktuális göngyölt: " + hasforint.toPlainString() + " Ft (>= 8.000.000 Ft)");
                break;
            case 2:
                requiresId = true;
                warnings.add("KÜLFÖLDI ÜGYFÉL: Fokozott azonosítás szükséges");
                break;
            case 1:
                requiresId = true;
                requiresEnhanced = true;
                warnings.add("PEP: Kiemelt közszereplő — fokozott átvilágítás szükséges");
                break;
            case -1:
                requiresId = true;
                blocked = true;
                warnings.add("BLOKKOLVA: Külföldi ügyfél nem kaphat USD-t");
                break;
            default:
                // Normál — 300K feletti azonosítási kötelezettség
                if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
                    requiresId = true;
                    warnings.add("Azonosítás szükséges: " + hufAmount.toPlainString() + " Ft >= " + IDENTIFICATION_LIMIT.toPlainString() + " Ft");
                }
                break;
        }

        return hu.puzzleir.valuta.dto.aml.AmlCheckResult.builder()
            .transactionType(transactionType)
            .weeklyTotal(weeklyTotal)
            .yearlyMax(yearlyMax)
            .quarterlyCount(quarterlyCount)
            .quarterlyTotal(quarterlyTotal)
            .requiresId(requiresId)
            .requiresEnhanced(requiresEnhanced)
            .blocked(blocked)
            .warnings(warnings)
            .build();
    }

    // ============ HELPER DTO-K ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class QuarterlyStats {
        private long count;
        private BigDecimal total;
    }
}
