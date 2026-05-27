package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.aml.AmlDailySummaryDto;
import hu.puzzleir.valuta.dto.aml.AmlDailyExportDto;
import hu.puzzleir.valuta.dto.aml.AmlReportDto;
import hu.puzzleir.valuta.dto.aml.CreateAmlReportDto;
import hu.puzzleir.valuta.dto.aml.CustomerRiskProfileDto;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.AmlReportRepository;
import hu.puzzleir.valuta.repository.AmlThresholdRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
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
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class AmlService {

    private final TransactionRepository transactionRepository;
    private final CustomerRepository customerRepository;
    private final AmlReportRepository amlReportRepository;
    private final AmlThresholdRepository amlThresholdRepository;
    private final AuditLogService auditLogService;
    private final SanctionScreeningService sanctionScreeningService;
    private final BlacklistService blacklistService;
    private final ShiftedCalendarDayRepository shiftedCalendarDayRepository;

    /** Egyszerusitett azonositasi limit (2017. LIII. tv. 7.§) */
    private static final BigDecimal SIMPLIFIED_IDENTIFICATION_LIMIT = new BigDecimal("100000");

    /** Teljes azonositasi limit (2017. LIII. tv. 7.§) */
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
        return checkTransaction(hufAmount, customerId, customerName, documentNumber, null);
    }

    public AmlBasicCheckResult checkTransaction(
            BigDecimal hufAmount,
            String customerId,
            String customerName,
            String documentNumber,
            String currencyCode) {

        // 0. Szankciós szűrés — KÖTELEZŐ, mindig az első ellenőrzés
        if (customerName != null && !customerName.isBlank()) {
            SanctionScreeningResult sanctionResult = sanctionScreeningService.screenCustomer(
                customerName, documentNumber, null, null, null, null);
            if (sanctionResult.isMatched()) {
                log.warn("AML: Szankciós lista találat — ügyfél: '{}', kockázat: {}",
                    customerName, sanctionResult.getRiskLevel());
                return AmlBasicCheckResult.builder()
                    .approved(false)
                    .rejectionReason("Szankciós lista találat (" + sanctionResult.getRiskLevel()
                        + "): " + customerName + " — tranzakció megtagadva")
                    .build();
            } else {
                log.debug("AML: Szankciós szűrés: TISZTA — ügyfél: '{}'", customerName);
            }

            Optional<ProhibitedPerson> blacklistMatch = blacklistService.findActivePersonMatch(customerName, documentNumber);
            if (blacklistMatch.isPresent()) {
                ProhibitedPerson person = blacklistMatch.get();
                log.warn("AML: Belső tiltólista találat — ügyfél: '{}', okmány: '{}'", customerName, documentNumber);
                return AmlBasicCheckResult.builder()
                    .approved(false)
                    .rejectionReason("Tiltólista találat: " + person.getFullName() + " — tranzakció megtagadva")
                    .build();
            }

            // Tiltott CÉG szűrés (legacy: JOGI SET TILTVA=1) — jogi-személy ügyfélnél a customerName a cégnév.
            Optional<ProhibitedCompany> companyMatch = blacklistService.findActiveCompanyMatch(customerName, documentNumber);
            if (companyMatch.isPresent()) {
                ProhibitedCompany company = companyMatch.get();
                log.warn("AML: Belső tiltólista találat (CÉG) — '{}'", customerName);
                return AmlBasicCheckResult.builder()
                    .approved(false)
                    .rejectionReason("Tiltólista találat (cég): " + company.getCompanyName() + " — tranzakció megtagadva")
                    .build();
            }
        }

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

        // 1a. Egyszerusitett azonositasi kotelezettseg (100K-300K Ft)
        if (hufAmount.compareTo(SIMPLIFIED_IDENTIFICATION_LIMIT) >= 0) {
            result.requiresIdentification(true);

            if (customerName == null || customerName.isBlank()
                || documentNumber == null || documentNumber.isBlank()) {
                result.approved(false);
                result.rejectionReason(
                    SIMPLIFIED_IDENTIFICATION_LIMIT.toPlainString()
                    + " Ft feletti tranzakciohoz ugyfel azonositas (nev + igazolvany) KOTELEZO!");
                return result.build();
            }
        }

        // 1b. Teljes azonositasi kotelezettseg (300K+ Ft)
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            result.requiresDetailedId(true);
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
        // HARDENING: .isBlank() guard a 3./5. szekcióval konzisztensen — üres customerId
        // ("") nem indít értelmetlen napi-göngyölés lekérdezést.
        if (customerId != null && !customerId.isBlank()) {
            BigDecimal dailyTotal = getDailyCustomerTotal(customerId);
            if (dailyTotal.add(hufAmount).compareTo(DAILY_SUSPICIOUS_LIMIT) >= 0) {
                result.suspiciousFlag(true);
                log.warn("AML: Gyanus napi osszeg - ugyfel: {}, napi osszeg: {} Ft",
                    customerId, dailyTotal.add(hufAmount));
            }
        }

        // 5. BIGCTRL 6 szintű kockázati besorolás (heti + negyedéves + éves göngyölés)
        if (customerId != null && !customerId.isBlank()) {
            int transactionType = classifyTransaction(customerId, hufAmount, currencyCode);
            result.transactionType(transactionType);

            if (transactionType >= 3) {
                result.requiresIdentification(true);
                result.requiresDetailedId(true);
                log.warn("AML: BIGCTRL TranzTipus {} — ügyfél: {}, hufAmount: {}",
                    transactionType, customerId, hufAmount);
            } else if (transactionType == 2) {
                result.requiresIdentification(true);
                log.info("AML: Külföldi ügyfél (TranzTipus 2): {}", customerId);
            } else if (transactionType == 1) {
                result.requiresIdentification(true);
                result.requiresDetailedId(true);
                log.info("AML: PEP ügyfél (TranzTipus 1): {}", customerId);
            } else if (transactionType == -1) {
                result.requiresIdentification(true);
                result.approved(false);
                result.rejectionReason("Külföldi ügyfél nem kaphat USD-t (TranzTipus -1)");
                log.warn("AML: Külföldi USD blokkolás: {}", customerId);
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
            .identificationRequired(annualTotal.compareTo(SIMPLIFIED_IDENTIFICATION_LIMIT) >= 0)
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
        /** Legacy BIGCTRL TranzTipus: -1, 0, 1, 2, 3, 4, 5, 6 */
        private int transactionType;
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
     *
     * FONTOS: A legacy 8 napos ablakot használ (_diff < 8), ezért minusDays(8).
     */
    @Transactional(readOnly = true)
    public BigDecimal getWeeklyTotal(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate sinceDate = LocalDate.now().minusDays(8);

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
                // 100K+ egyszerusitett azonositasi kotelezettseg
                if (hufAmount.compareTo(SIMPLIFIED_IDENTIFICATION_LIMIT) >= 0) {
                    requiresId = true;
                    if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
                        requiresEnhanced = true;
                        warnings.add("Teljes azonosítás szükséges: " + hufAmount.toPlainString() + " Ft >= " + IDENTIFICATION_LIMIT.toPlainString() + " Ft");
                    } else {
                        warnings.add("Egyszerűsített azonosítás szükséges: " + hufAmount.toPlainString() + " Ft >= " + SIMPLIFIED_IDENTIFICATION_LIMIT.toPlainString() + " Ft");
                    }
                }
                break;
        }

        // Sprint 5.3 C2 - 8 napos rolling window explicit check
        boolean rollingWindowExceeded = false;
        boolean requiresManagerApproval = false;
        String managerApprovalReason = null;

        if (hasforint.compareTo(ROLLING_WINDOW_LIMIT_HUF) >= 0) {
            rollingWindowExceeded = true;
            warnings.add("8 NAPOS ABLAK: gördülő összeg " + hasforint.toPlainString()
                + " Ft >= " + ROLLING_WINDOW_LIMIT_HUF.toPlainString() + " Ft limit (Pmt. 33.§)");
        }

        // Manager jóváhagyás kötelező: TranzTipus 4, 5, 6 vagy rolling window túllépés
        if (transactionType >= 4 || rollingWindowExceeded) {
            requiresManagerApproval = true;
            managerApprovalReason = "TranzTipus " + transactionType
                + (rollingWindowExceeded ? " + 8 napos ablak túllépés" : "")
                + " — SUPERVISOR vagy MANAGER jóváhagyás szükséges";
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
            .rollingWindowExceeded(rollingWindowExceeded)
            .rollingWindowLimit(ROLLING_WINDOW_LIMIT_HUF)
            .rollingWindowTotal(hasforint)
            .rollingWindowDays(ROLLING_WINDOW_DAYS)
            .requiresManagerApproval(requiresManagerApproval)
            .managerApprovalReason(managerApprovalReason)
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

    // ============ 2017. ÉVI LIII. TV. — PÉNZMOSÁS ELLENI MODUL ============

    /** 2017. LIII. tv.: Bejelentési küszöb */
    private static final BigDecimal REPORTING_THRESHOLD = new BigDecimal("2000000");

    /** 2017. LIII. tv.: Fokozott átvilágítási küszöb */
    private static final BigDecimal ENHANCED_THRESHOLD = new BigDecimal("4500000");

    /**
     * Sprint 5.3 C2 — 8 napos rolling window limit (HUF).
     * Pmt. (2017. LIII. tv.) szerint a fokozott átvilágítási küszöb felett
     * kötelező a manager jóváhagyás + részletes dokumentálás.
     * A BIGCTRL.DLL TranzTipus 5, 6 szintek ezen limit feletti eseteket kezelték.
     */
    private static final BigDecimal ROLLING_WINDOW_LIMIT_HUF = new BigDecimal("4500000");

    /**
     * Sprint 5.3 — Rolling window hossza napokban (legacy BIGCTRL: _diff < 8 → minusDays(8)).
     */
    private static final int ROLLING_WINDOW_DAYS = 8;

    /** Structuring detektálás: limit alatti tranzakciók száma egy napon belül */
    private static final int STRUCTURING_MIN_TRANSACTIONS = 3;

    /** Structuring: ha a tranzakciók a limit 80%-a fölött vannak */
    private static final BigDecimal STRUCTURING_RATIO = new BigDecimal("0.80");

    /** Napi gyakoriság küszöb (gyanús ha > 3) */
    private static final int DAILY_FREQUENCY_THRESHOLD = 3;

    /** 30 napos volumen küszöb (gyanús ha > 5M) */
    private static final BigDecimal MONTHLY_VOLUME_THRESHOLD = new BigDecimal("5000000");

    /**
     * Ügyfél kockázati profil lekérése.
     * Elmúlt 30 nap tranzakciói, összegek, gyakorisság alapján.
     */
    @Transactional(readOnly = true)
    public CustomerRiskProfileDto getCustomerRiskProfile(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        LocalDate thirtyDaysAgo = today.minusDays(30);

        BigDecimal last30DaysTotal = transactionRepository.sumCustomerTotalSince(
            companyId, customerId, thirtyDaysAgo);
        long last30DaysCount = transactionRepository.countCustomerTransactionsSince(
            companyId, customerId, thirtyDaysAgo);
        BigDecimal dailyTotal = getDailyCustomerTotal(customerId);
        long dailyCount = transactionRepository.countCustomerDailyTransactions(
            companyId, customerId, today);

        boolean structuring = isStructuringInternal(companyId, customerId, today);
        boolean highFrequency = dailyCount > DAILY_FREQUENCY_THRESHOLD;
        boolean highVolume = last30DaysTotal.compareTo(MONTHLY_VOLUME_THRESHOLD) > 0;

        String riskLevel;
        if (structuring || (highFrequency && highVolume)) {
            riskLevel = "CRITICAL";
        } else if (highFrequency || highVolume) {
            riskLevel = "HIGH";
        } else if (last30DaysTotal.compareTo(REPORTING_THRESHOLD) >= 0) {
            riskLevel = "MEDIUM";
        } else {
            riskLevel = "LOW";
        }

        // Ügyfél név lekérése
        String customerName = null;
        Optional<Customer> customerOpt = customerRepository.findByCustomerCodeAndCompanyId(customerId, companyId);
        if (customerOpt.isPresent()) {
            customerName = customerOpt.get().getName();
        }

        return CustomerRiskProfileDto.builder()
            .customerId(customerId)
            .customerName(customerName)
            .riskLevel(riskLevel)
            .last30DaysTotal(last30DaysTotal)
            .last30DaysTransactionCount((int) last30DaysCount)
            .dailyTotal(dailyTotal)
            .dailyTransactionCount((int) dailyCount)
            .annualTotal(getAnnualRollingTotal(customerId))
            .structuringDetected(structuring)
            .highFrequency(highFrequency)
            .highVolume(highVolume)
            .build();
    }

    // ============ BEJELENTÉSI HATÁRIDŐ (2017. LIII. tv. 33.§) ============

    /**
     * Magyar munkaszüneti napok — fix ünnepek + húsvét alapú mozgóünnepek.
     * Forrás: 2012. évi I. törvény a munka törvénykönyvéről, 102.§ (1).
     */
    private static final java.util.Set<java.time.MonthDay> HUNGARIAN_FIXED_HOLIDAYS = java.util.Set.of(
            java.time.MonthDay.of(1, 1),   // Újév
            java.time.MonthDay.of(3, 15),  // Nemzeti ünnep
            java.time.MonthDay.of(5, 1),   // Munka ünnepe
            java.time.MonthDay.of(8, 20),  // Államalapítás
            java.time.MonthDay.of(10, 23), // 1956-os forradalom
            java.time.MonthDay.of(11, 1),  // Mindenszentek
            java.time.MonthDay.of(12, 25), // Karácsony 1.
            java.time.MonthDay.of(12, 26)  // Karácsony 2.
    );

    /**
     * Húsvétvasárnap kiszámítása (Anonymous Gregorian algorithm).
     */
    private static LocalDate easterSunday(int year) {
        int a = year % 19;
        int b = year / 100;
        int c = year % 100;
        int d = b / 4;
        int e = b % 4;
        int f = (b + 8) / 25;
        int g = (b - f + 1) / 3;
        int h = (19 * a + b - d - g + 15) % 30;
        int i = c / 4;
        int k = c % 4;
        int l = (32 + 2 * e + 2 * i - h - k) % 7;
        int m = (a + 11 * h + 22 * l) / 451;
        int month = (h + l - 7 * m + 114) / 31;
        int day = ((h + l - 7 * m + 114) % 31) + 1;
        return LocalDate.of(year, month, day);
    }

    private boolean isHungarianHoliday(LocalDate date) {
        // Fix ünnepek
        if (HUNGARIAN_FIXED_HOLIDAYS.contains(java.time.MonthDay.from(date))) {
            return true;
        }
        // Mozgóünnepek: Nagypéntek (Easter-2), Húsvéthétfő (Easter+1), Pünkösdhétfő (Easter+50)
        LocalDate easter = easterSunday(date.getYear());
        return date.equals(easter.minusDays(2))   // Nagypéntek
                || date.equals(easter.plusDays(1))  // Húsvéthétfő
                || date.equals(easter.plusDays(50)); // Pünkösdhétfő
    }

    /**
     * Munkanap kiszámítása — hétvége + magyar munkaszüneti napok kihagyásával.
     */
    private LocalDateTime calculateBusinessDayDeadline(LocalDateTime from, int businessDays) {
        LocalDate date = from.toLocalDate();
        int added = 0;
        while (added < businessDays) {
            date = date.plusDays(1);
            if (isBusinessDay(date)) {
                added++;
            }
        }
        return date.atTime(from.toLocalTime());
    }

    /**
     * Munkanap-e a megadott nap a SAR-határidő szempontjából (#PP-17).
     *
     * <p>Elsőbbség: a kormányzati áthelyezés (shifted_calendar_day) FELÜLÍRJA a
     * naptári logikát — egy áthelyezett szombat munkanap, egy áthelyezett hétköznap
     * pedig pihenőnap. Áthelyezés hiányában a hagyományos szabály: hétvége és magyar
     * munkaszüneti nap kihagyva.</p>
     */
    private boolean isBusinessDay(LocalDate date) {
        Optional<ShiftedCalendarDay> shifted = shiftedCalendarDayRepository.findByCalendarDate(date);
        if (shifted.isPresent()) {
            return shifted.get().isWorkday();
        }
        java.time.DayOfWeek dow = date.getDayOfWeek();
        boolean weekend = dow == java.time.DayOfWeek.SATURDAY || dow == java.time.DayOfWeek.SUNDAY;
        return !weekend && !isHungarianHoliday(date);
    }

    /**
     * Lejárt (OVERDUE) bejelentések keresése és megjelölése.
     * Naponta futtatandó (@Scheduled).
     *
     * DRAFT státuszú, 2 munkanapnál régebbi bejelentések → OVERDUE.
     */
    @Transactional
    public int checkAndMarkOverdueReports() {
        LocalDateTime now = LocalDateTime.now();
        List<AmlReport> overdueReports = amlReportRepository.findOverdueReports(now);

        int count = 0;
        for (AmlReport report : overdueReports) {
            report.setStatus(AmlReportStatus.OVERDUE);
            amlReportRepository.save(report);
            count++;

            log.warn("AML OVERDUE: bejelentés id={}, customerId={}, deadline={}, most={}",
                report.getId(), report.getCustomerId(), report.getDeadlineAt(), now);

            auditLogService.log("AML_REPORT_OVERDUE",
                "AML bejelentési határidő lejárt: id=" + report.getId()
                    + ", deadline=" + report.getDeadlineAt(),
                report.getId().toString());
        }

        if (count > 0) {
            log.warn("AML OVERDUE: {} bejelentés határideje lejárt!", count);
        }

        return count;
    }

    /**
     * Cégszintű overdue bejelentések listája.
     */
    @Transactional(readOnly = true)
    public List<AmlReportDto> getOverdueReports() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return amlReportRepository.findOverdueByCompanyId(companyId, LocalDateTime.now())
            .stream().map(this::toDto).toList();
    }

    /**
     * AML bejelentés létrehozása.
     */
    public AmlReportDto submitReport(CreateAmlReportDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        hu.puzzleir.valuta.entity.Company company = new hu.puzzleir.valuta.entity.Company();
        company.setId(companyId);

        AmlReport report = AmlReport.builder()
            .company(company)
            .customerId(dto.getCustomerId())
            .reportType(AmlReportType.valueOf(dto.getReportType()))
            .riskLevel(dto.getRiskLevel() != null
                ? AmlRiskLevel.valueOf(dto.getRiskLevel())
                : AmlRiskLevel.LOW)
            .amountHuf(dto.getAmountHuf())
            .currencyCode(dto.getCurrencyCode())
            .originalAmount(dto.getOriginalAmount())
            .customerName(dto.getCustomerName())
            .documentType(dto.getDocumentType())
            .documentNumber(dto.getDocumentNumber())
            .workerNotes(dto.getWorkerNotes())
            .status(AmlReportStatus.DRAFT)
            .createdBy(workerCode)
            .build();

        if (dto.getTransactionId() != null) {
            // PP-03 IDOR: cég-szűrt lekérés. A nem létező és a más cég tranzakciója egyaránt
            // üres eredményt ad → azonos hiba, nincs oldalcsatorna (txId-enumeráció kizárva).
            Transaction tx = transactionRepository.findByIdAndCompanyId(dto.getTransactionId(), companyId)
                .orElseThrow(() -> {
                    log.warn("AML tranzakció-csatolás elutasítva (nem létező vagy kereszt-bérlő)! userCompany={}, txId={}",
                        companyId, dto.getTransactionId());
                    return new ValidationException("A megadott tranzakció nem kapcsolható össze ezzel a bejelentéssel!");
                });
            report.setTransaction(tx);
        }

        // Bejelentési határidő: 2 munkanap (2017. LIII. tv. 33.§)
        LocalDateTime createdNow = LocalDateTime.now();
        report.setDeadlineAt(calculateBusinessDayDeadline(createdNow, 2));

        AmlReport saved = amlReportRepository.save(report);
        log.info("AML bejelentés létrehozva: id={}, type={}, amount={}, deadline={}",
            saved.getId(), dto.getReportType(), dto.getAmountHuf(), saved.getDeadlineAt());
        return toDto(saved);
    }

    /**
     * Függő (DRAFT/SUBMITTED) bejelentések listája.
     */
    @Transactional(readOnly = true)
    public List<AmlReportDto> getPendingReports() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return amlReportRepository.findPendingByCompanyId(companyId)
            .stream().map(this::toDto).toList();
    }

    /**
     * Napi AML összesítő.
     */
    @Transactional(readOnly = true)
    public AmlDailySummaryDto getDailyAmlSummary(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);

        List<AmlReport> reports = amlReportRepository.findByCompanyIdAndDateRange(companyId, from, to);

        int pending = 0, submitted = 0, flagged = 0;
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (AmlReport r : reports) {
            switch (r.getStatus()) {
                case DRAFT -> pending++;
                case OVERDUE -> pending++;
                case SUBMITTED -> submitted++;
                case FLAGGED -> flagged++;
                default -> {}
            }
            totalAmount = totalAmount.add(r.getAmountHuf() != null ? r.getAmountHuf() : BigDecimal.ZERO);
        }

        long standardCount = amlReportRepository.countByCompanyIdAndDateRangeAndType(companyId, from, to, AmlReportType.STANDARD);
        long enhancedCount = amlReportRepository.countByCompanyIdAndDateRangeAndType(companyId, from, to, AmlReportType.ENHANCED);
        long suspiciousCount = amlReportRepository.countByCompanyIdAndDateRangeAndType(companyId, from, to, AmlReportType.SUSPICIOUS);
        long thresholdCount = amlReportRepository.countByCompanyIdAndDateRangeAndType(companyId, from, to, AmlReportType.THRESHOLD);

        return AmlDailySummaryDto.builder()
            .date(date)
            .totalReports(reports.size())
            .pendingReports(pending)
            .submittedReports(submitted)
            .flaggedReports(flagged)
            .standardChecks(standardCount)
            .enhancedChecks(enhancedCount)
            .suspiciousChecks(suspiciousCount)
            .thresholdChecks(thresholdCount)
            .totalAmountHuf(totalAmount)
            .build();
    }

    /**
     * Structuring detektálás: ha az ügyfél több kis tranzakcióval próbálja
     * elkerülni az azonosítási limitet (300K).
     *
     * Pl. 3 db 290K tranzakció egy napon = GYANÚS.
     */
    @Transactional(readOnly = true)
    public boolean isStructuring(String customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return isStructuringInternal(companyId, customerId, LocalDate.now());
    }

    private boolean isStructuringInternal(UUID companyId, String customerId, LocalDate date) {
        List<Transaction> dailyTxs = transactionRepository.findCustomerDailyTransactions(
            companyId, customerId, date);

        if (dailyTxs.size() < STRUCTURING_MIN_TRANSACTIONS) {
            return false;
        }

        // Ha a tranzakciók nagy része az IDENTIFICATION_LIMIT közelében van (80-99% közötti)
        BigDecimal limitThreshold = IDENTIFICATION_LIMIT.multiply(STRUCTURING_RATIO);
        long nearLimitCount = dailyTxs.stream()
            .filter(tx -> tx.getHufAmount() != null
                       && tx.getHufAmount().compareTo(limitThreshold) >= 0
                       && tx.getHufAmount().compareTo(IDENTIFICATION_LIMIT) < 0)
            .count();

        return nearLimitCount >= STRUCTURING_MIN_TRANSACTIONS;
    }

    // ============ HIGH RISK FLAG KEZELÉS ============

    /**
     * Ügyfél highRiskFlag beállítása, ha az éves göngyölt összeg eléri a limitet.
     * Meghívandó minden sikeres tranzakció könyvelésekor.
     *
     * @param customerId ügyfél azonosító
     * @param newAnnualTotal tranzakció utáni új éves összeg
     */
    public void setHighRiskFlagIfNeeded(String customerId, BigDecimal newAnnualTotal) {
        if (customerId == null || customerId.isBlank()) return;
        if (newAnnualTotal == null) return;

        if (newAnnualTotal.compareTo(ANNUAL_ROLLING_LIMIT) < 0) return;

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Optional<Customer> customerOpt = customerRepository.findByCustomerCodeAndCompanyId(customerId, companyId);
        if (customerOpt.isEmpty()) return;

        Customer customer = customerOpt.get();
        if (Boolean.TRUE.equals(customer.getHighRiskFlag())) return; // már be van állítva

        customer.setHighRiskFlag(true);
        customer.setHighRiskReason("Éves göngyölt összeg elérte a " + ANNUAL_ROLLING_LIMIT.toPlainString() + " Ft limitet (aktuális: " + newAnnualTotal.toPlainString() + " Ft)");
        customer.setHighRiskSetAt(LocalDateTime.now());
        customerRepository.save(customer);

        log.warn("AML: Ügyfél highRiskFlag beállítva — customerId={}, éves összeg={} Ft",
            customerId, newAnnualTotal);
        auditLogService.log("AML_HIGH_RISK_SET",
            "Ügyfél magas kockázatú jelölés beállítva: éves göngyölt=" + newAnnualTotal.toPlainString() + " Ft",
            customerId);
    }

    // ============ BEJELENTÉS ÉLETCIKLUS ============

    /**
     * AML bejelentés benyújtása hatósághoz: DRAFT → SUBMITTED.
     *
     * @param reportId AML bejelentés azonosítója
     * @param externalReference hatósági referenciaszám
     * @return frissített bejelentés DTO
     */
    public AmlReportDto submitToAuthority(UUID reportId, String externalReference) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        AmlReport report = amlReportRepository.findById(reportId)
            .orElseThrow(() -> new ValidationException("AML bejelentés nem található: " + reportId));

        if (!report.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Hozzáférés megtagadva: másik cég AML bejelentése");
        }

        if (report.getStatus() != AmlReportStatus.DRAFT && report.getStatus() != AmlReportStatus.OVERDUE) {
            throw new ValidationException("Csak DRAFT vagy OVERDUE státuszú bejelentés nyújtható be (aktuális: " + report.getStatus() + ")");
        }

        report.setStatus(AmlReportStatus.SUBMITTED);
        report.setSubmittedAt(LocalDateTime.now());
        if (externalReference != null && !externalReference.isBlank()) {
            report.setExternalReference(externalReference);
        }

        AmlReport saved = amlReportRepository.save(report);

        auditLogService.log("AML_REPORT_SUBMITTED",
            "AML bejelentés benyújtva hatósághoz: id=" + reportId + ", ref=" + externalReference,
            reportId.toString());

        log.info("AML bejelentés benyújtva: id={}, ref={}", reportId, externalReference);
        return toDto(saved);
    }

    /**
     * AML bejelentés visszaigazolása: SUBMITTED → ACKNOWLEDGED.
     *
     * @param reportId AML bejelentés azonosítója
     * @param externalReference hatósági visszaigazolási szám
     * @return frissített bejelentés DTO
     */
    public AmlReportDto acknowledgeReport(UUID reportId, String externalReference) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        AmlReport report = amlReportRepository.findById(reportId)
            .orElseThrow(() -> new ValidationException("AML bejelentés nem található: " + reportId));

        if (!report.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Hozzáférés megtagadva: másik cég AML bejelentése");
        }

        if (report.getStatus() != AmlReportStatus.SUBMITTED) {
            throw new ValidationException("Csak SUBMITTED státuszú bejelentés nyugtázható (aktuális: " + report.getStatus() + ")");
        }

        report.setStatus(AmlReportStatus.ACKNOWLEDGED);
        report.setAcknowledgedAt(LocalDateTime.now());
        if (externalReference != null && !externalReference.isBlank()) {
            report.setExternalReference(externalReference);
        }

        AmlReport saved = amlReportRepository.save(report);

        auditLogService.log("AML_REPORT_ACKNOWLEDGED",
            "AML bejelentés visszaigazolva: id=" + reportId + ", ref=" + externalReference,
            reportId.toString());

        log.info("AML bejelentés visszaigazolva: id={}, ref={}", reportId, externalReference);
        return toDto(saved);
    }

    // ============ NAPI EXPORT ============

    /**
     * Napi AML export generálása (hatóságnak küldendő összesítő).
     *
     * @param date exportálandó nap
     * @return napi export DTO
     */
    @Transactional(readOnly = true)
    public AmlDailyExportDto generateDailyExport(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);

        List<AmlReport> reports = amlReportRepository.findByCompanyIdAndDateRange(companyId, from, to);

        int draftCount = 0, submittedCount = 0, acknowledgedCount = 0, flaggedCount = 0;
        BigDecimal totalAmount = BigDecimal.ZERO;

        for (AmlReport r : reports) {
            switch (r.getStatus()) {
                case DRAFT -> draftCount++;
                case OVERDUE -> draftCount++;
                case SUBMITTED -> submittedCount++;
                case ACKNOWLEDGED -> acknowledgedCount++;
                case FLAGGED -> flaggedCount++;
            }
            totalAmount = totalAmount.add(r.getAmountHuf() != null ? r.getAmountHuf() : BigDecimal.ZERO);
        }

        List<AmlReportDto> reportDtos = reports.stream().map(this::toDto).toList();

        log.info("AML napi export generálva: dátum={}, összesen={} bejelentés", date, reports.size());

        return AmlDailyExportDto.builder()
            .exportDate(date)
            .companyId(companyId)
            .totalReports(reports.size())
            .draftCount(draftCount)
            .submittedCount(submittedCount)
            .acknowledgedCount(acknowledgedCount)
            .flaggedCount(flaggedCount)
            .totalAmountHuf(totalAmount)
            .reports(reportDtos)
            .generatedAt(LocalDateTime.now())
            .build();
    }

    // ============ DTO KONVERZIÓ ============

    private AmlReportDto toDto(AmlReport r) {
        return AmlReportDto.builder()
            .id(r.getId())
            .customerId(r.getCustomerId())
            .transactionId(r.getTransaction() != null ? r.getTransaction().getId() : null)
            .reportType(r.getReportType().name())
            .riskLevel(r.getRiskLevel().name())
            .amountHuf(r.getAmountHuf())
            .currencyCode(r.getCurrencyCode())
            .originalAmount(r.getOriginalAmount())
            .customerName(r.getCustomerName())
            .documentType(r.getDocumentType())
            .documentNumber(r.getDocumentNumber())
            .workerNotes(r.getWorkerNotes())
            .reviewedBy(r.getReviewedBy())
            .reviewedAt(r.getReviewedAt())
            .status(r.getStatus().name())
            .submittedAt(r.getSubmittedAt())
            .acknowledgedAt(r.getAcknowledgedAt())
            .externalReference(r.getExternalReference())
            .createdBy(r.getCreatedBy())
            .createdAt(r.getCreatedAt())
            .deadlineAt(r.getDeadlineAt())
            .overdue(r.getStatus() == AmlReportStatus.OVERDUE
                || (r.getDeadlineAt() != null
                    && r.getDeadlineAt().isBefore(LocalDateTime.now())
                    && r.getStatus() == AmlReportStatus.DRAFT))
            .build();
    }

    // ============ SPRINT 6.2: ROLLING WINDOW AUDIT ============

    /**
     * Sprint 6.2 C2 compliance audit: 8 napos gordulo limit felett levo ugyfelek listaja.
     * 
     * Pmt. (2017. LIII. tv.) szerint a fokozott atvilagitasu ugyfelek rendszeres
     * felulvizsgalat alatt kell legyenek. Ez a lista a hatosagi auditra hasznalhato.
     *
     * @param thresholdHuf opcionalis kuszob (alapertelmezett: ROLLING_WINDOW_LIMIT_HUF = 4.5M)
     * @return rolling window audit DTO-k listaja
     */
    @Transactional(readOnly = true)
    public java.util.List<hu.puzzleir.valuta.dto.aml.RollingWindowAuditDto> getRollingWindowAudit(BigDecimal thresholdHuf) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate sinceDate = LocalDate.now().minusDays(ROLLING_WINDOW_DAYS);

        // Sourcery PR #128 fix (P1 bug_risk): validate threshold > 0 before division.
        BigDecimal threshold = thresholdHuf != null ? thresholdHuf : ROLLING_WINDOW_LIMIT_HUF;
        if (threshold == null || threshold.compareTo(BigDecimal.ZERO) <= 0) {
            log.warn("getRollingWindowAudit: invalid threshold {}, falling back to ROLLING_WINDOW_LIMIT_HUF={}",
                thresholdHuf, ROLLING_WINDOW_LIMIT_HUF);
            threshold = ROLLING_WINDOW_LIMIT_HUF;
        }

        java.util.List<Object[]> rows = transactionRepository.findRollingWindowAuditCandidates(
            companyId, sinceDate, threshold);

        // Sourcery PR #128 fix: capture timestamp once, reuse for all DTOs (consistent auditAt).
        LocalDateTime auditAt = LocalDateTime.now();

        java.util.List<hu.puzzleir.valuta.dto.aml.RollingWindowAuditDto> result = new ArrayList<>();
        for (Object[] row : rows) {
            String customerId = (String) row[0];
            BigDecimal total = (BigDecimal) row[1];

            // Ugyfel info lekerese
            String customerName = null;
            boolean highRiskFlag = false;
            Optional<Customer> customerOpt = customerRepository.findByCustomerCodeAndCompanyId(customerId, companyId);
            if (customerOpt.isPresent()) {
                customerName = customerOpt.get().getName();
                highRiskFlag = Boolean.TRUE.equals(customerOpt.get().getHighRiskFlag());
            }

            // exceedPercent: threshold mar validalva > 0, igy nincs div-by-zero
            BigDecimal exceedPercent = total.multiply(new BigDecimal("100"))
                    .divide(threshold, 1, RoundingMode.HALF_UP);

            result.add(hu.puzzleir.valuta.dto.aml.RollingWindowAuditDto.builder()
                .customerId(customerId)
                .customerName(customerName)
                .rollingWindowTotalHuf(total)
                .rollingWindowLimitHuf(threshold)
                .exceedPercent(exceedPercent)
                .auditAt(auditAt)
                .sinceDate(sinceDate)
                .windowDays(ROLLING_WINDOW_DAYS)
                .highRiskFlag(highRiskFlag)
                .build());
        }

        log.info("Rolling window audit: company={}, threshold={}, {} candidate(s)",
                companyId, threshold, result.size());
        return result;
    }

    // ============ NAPI CACHE RESET (NAPZÁRÁS) ============

    /**
     * Napi AML ügyfél gyűjtők nullázása napzáráskor.
     * Legacy: NAPZAR.DLL — ugyfel napi gyujtok nullazasa.
     *
     * Az AmlService jelenleg nem tart in-memory cache-t (minden lekérdezés DB-ből fut);
     * ha a jövőben ConcurrentHashMap alapú napi cache kerül be, itt kell üríteni.
     */
    public void resetDailyCache() {
        log.info("AML napi cache reset: napi ügyfél gyűjtők nullázva (napzárás)");
        // Nincs in-memory cache jelenleg — DB alapú lekérdezések, a reset implicit
        // (az új napon a tranzactionDate = ma szűrő automatikusan üres lesz).
    }

    // ============ GÖNGYÖLÉS VISSZAVONÁS (STORNÓ AML) ============

    /**
     * Göngyölés visszavonása stornó esetén.
     * 
     * A Delphi SZTORNO.DLL meghívta a BIGCTRL.DLL-t göngyölés visszavonásra.
     * Ha az ügyfél éves göngyölt összege a limit alá csökken → "nagy ügyfél" jelölés törlése.
     * 
     * @param customerId Ügyfél azonosító
     * @param hufAmount Sztornózott összeg (HUF)
     * @param originalDate Eredeti tranzakció dátuma
     */
    public void reverseAccumulation(String customerId, BigDecimal hufAmount, LocalDateTime originalDate) {
        if (customerId == null || customerId.isBlank()) {
            log.warn("Göngyölés visszavonás: nincs ügyfél ID → skip");
            return;
        }

        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            log.warn("Göngyölés visszavonás: érvénytelen összeg → skip");
            return;
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        int year = originalDate.getYear();
        LocalDate yearStart = LocalDate.of(year, 1, 1);
        LocalDate yearEnd = LocalDate.of(year, 12, 31);

        // 1. Ügyfél éves göngyölt összege a sztornó UTÁN.
        // FONTOS (2026-05-27, architect-mode audit fix): mire idáig érünk, az eredeti tranzakció
        // státusza MÁR REVERSED (a hívó TransactionReversalService.executeReversal előbb állítja be),
        // a sumCustomerAnnualTotal pedig csak COMPLETED + financial_effective sorokat összegez → az
        // eredeti MÁR ki van zárva. A létrejött REVERSAL sor customerId-je null (nincs az ügyfélhez
        // kötve), így az SEM számít bele. Ezért ez a lekérdezés a sztornó UTÁNI tényleges összeg.
        BigDecimal postReversalTotal = transactionRepository.sumCustomerAnnualTotal(
            companyId, customerId, yearStart, yearEnd
        );
        if (postReversalTotal == null) {
            postReversalTotal = BigDecimal.ZERO;
        }

        // 2. A sztornó ELŐtti összeg = utáni + a visszavont tranzakció értéke.
        // (A korábbi kód a már-post értékből MÉG egyszer levonta a hufAmount-ot → kétszeres levonás,
        //  ami tévesen a limit alá vihette a számított összeget és így hibásan törölte a highRiskFlag-et.)
        BigDecimal preReversalTotal = postReversalTotal.add(hufAmount);

        log.info("AML göngyölés visszavonás: customerId={}, visszavontÖsszeg={}, sztornóElőtt={}, sztornóUtán={}",
            customerId, hufAmount, preReversalTotal, postReversalTotal);

        // 3. Ha a sztornó hatására a göngyölt összeg a limit (3.6M) alá esett → "nagy ügyfél" jelölés törlése
        BigDecimal newYearTotal = postReversalTotal;
        if (preReversalTotal.compareTo(ANNUAL_ROLLING_LIMIT) >= 0
            && postReversalTotal.compareTo(ANNUAL_ROLLING_LIMIT) < 0) {
            
            log.info("Ügyfél visszalép a göngyölési limit alá: customerId={}, newTotal={}",
                customerId, newYearTotal);

            // Customer entitás frissítése — highRiskFlag törlése
            Optional<Customer> customerOpt = customerRepository.findByCustomerCodeAndCompanyId(customerId, companyId);
            if (customerOpt.isPresent()) {
                Customer customer = customerOpt.get();
                if (Boolean.TRUE.equals(customer.getHighRiskFlag())) {
                    customer.setHighRiskFlag(false);
                    customer.setHighRiskReason(null);
                    customer.setHighRiskSetAt(null);
                    customerRepository.save(customer);
                    log.info("Ügyfél highRiskFlag törölve (göngyölési limit alá visszaesett): {}", customerId);
                } else {
                    log.info("Ügyfél 'nagy ügyfél' státusz törölve (már nem volt jelölve): {}", customerId);
                }
            }
        }

        // 4. Audit log
        String auditMessage = String.format(
            "AML göngyölés visszavonás: ügyfél=%s, sztornó összeg=%s, új éves összeg=%s",
            customerId, hufAmount, newYearTotal
        );
        
        log.info(auditMessage);
        
        // AuditLogService használata
        auditLogService.log("AML_REVERSE_ACCUMULATION", auditMessage, customerId);
    }
}
