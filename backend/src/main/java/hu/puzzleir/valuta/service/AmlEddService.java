package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Megerősített eljárás (EDD) követés — EBC szabályzat V.2.7 / AML-go-live-terv 4) pont (V309).
 *
 * <p>Napi scan (AmlEddScheduler) jelöli az ügyfélen az 1 éves EDD-ablakot:</p>
 * <ul>
 *   <li>a) &ge;50M Ft egyedi tranzakció (előző nap) → 1 év</li>
 *   <li>b) &ge;100M Ft naptári havi készpénzforgalom → 1 év</li>
 * </ul>
 *
 * <p>A jelölés extend-only (a meglévő ablakot soha nem rövidíti) és természetesen idempotens:
 * audit-rekord csak tényleges változáskor készül. Az aktív ablakot az
 * {@link AmlService#checkAllThresholds} érvényesíti fokozott átvilágításként — az adat-vezérelt
 * olvasó-ág flag nélkül is inert, amíg a scan (AML_EDD_TRACKING_ENFORCEMENT) nem jelölt.</p>
 *
 * <p>A c) eset (Pmt. 30.§ (1) bejelentett ügyfél) manuális compliance-művelet — a mezők
 * ugyanazok, a jelölő UI/endpoint követő kör.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AmlEddService {

    static final String AUDIT_ACTION = "AML_EDD_WINDOW_SET";
    static final String EDD_TRACKING_PARAM = "AML_EDD_TRACKING_ENFORCEMENT";
    static final String EDD_TRACKING_DEFAULT = "false";

    /** V.2.7 a): egyedi tranzakció küszöb. */
    static final BigDecimal EDD_SINGLE_TX_THRESHOLD_HUF = new BigDecimal("50000000");
    /** V.2.7 b): naptári havi kumulált készpénzforgalom küszöb. */
    static final BigDecimal EDD_MONTHLY_THRESHOLD_HUF = new BigDecimal("100000000");

    // V.2.7 f)/g) (V311): a numerikus értékek SystemParameter-ben hangolhatók — a szabályzat
    // a f)-nél 24-72h ablakot nevez meg, a g)-nél számszerű küszöböt nem; engineering defaultok.
    static final String EDD_PASSTHROUGH_MIN_PARAM = "AML_EDD_PASSTHROUGH_MIN_HUF";
    static final String EDD_PASSTHROUGH_MIN_DEFAULT = "5000000";
    /** f) pass-through ablak: a szabályzati 24-72h felső határa (konzervatív — többet fog). */
    static final int EDD_PASSTHROUGH_WINDOW_DAYS = 3;
    static final String EDD_PROFILE_MULTIPLIER_PARAM = "AML_EDD_PROFILE_OUTLIER_MULTIPLIER";
    static final String EDD_PROFILE_MULTIPLIER_DEFAULT = "5";
    static final String EDD_PROFILE_MIN_PARAM = "AML_EDD_PROFILE_OUTLIER_MIN_HUF";
    static final String EDD_PROFILE_MIN_DEFAULT = "10000000";
    /** g) profil-átlag visszatekintési ablaka: az előző 6 teljes naptári hónap. */
    static final int EDD_PROFILE_HISTORY_MONTHS = 6;
    /** Az EDD-ablak hossza. */
    static final int EDD_WINDOW_YEARS = 1;

    /** A scheduler is Europe/Budapest zónával fut — a scan-dátum ugyanabban a zónában képződik. */
    public static final java.time.ZoneId BUSINESS_ZONE = java.time.ZoneId.of("Europe/Budapest");

    private final TransactionRepository transactionRepository;
    private final CustomerRepository customerRepository;
    private final AuditLogService auditLogService;
    private final SystemParameterService systemParameterService;

    @Transactional(rollbackFor = Exception.class)
    public AmlEddScanResult scanYesterday() {
        return scanDate(LocalDate.now(BUSINESS_ZONE).minusDays(1));
    }

    /**
     * Az adott nap triggereinek kiértékelése és az EDD-ablakok jelölése.
     * Flag-gated: AML_EDD_TRACKING_ENFORCEMENT=false esetén no-op.
     */
    @Transactional(rollbackFor = Exception.class)
    public AmlEddScanResult scanDate(LocalDate day) {
        if (day == null) {
            throw new IllegalArgumentException("day nem lehet null");
        }
        boolean enabled = systemParameterService != null && "true".equalsIgnoreCase(
                systemParameterService.getValue(EDD_TRACKING_PARAM, EDD_TRACKING_DEFAULT));
        if (!enabled) {
            log.debug("EDD-scan kihagyva (flag kikapcsolva), day={}", day);
            return new AmlEddScanResult(day, false, 0, 0, 0);
        }

        int marked = 0;
        int extended = 0;
        int unchanged = 0;

        // a) >=50M egyedi tranzakció — nap-horgonyzott ablak (a query csak az adott nap
        // triggereit adja, így az újrafutás természetesen idempotens)
        for (Object[] row : transactionRepository.findEddSingleTransactionTriggers(
                day, EDD_SINGLE_TX_THRESHOLD_HUF)) {
            String reason = "V.2.7 a): >=50M Ft egyedi tranzakció (" + day + ")";
            switch (markEdd((UUID) row[0], (String) row[1], day, day.plusYears(EDD_WINDOW_YEARS), reason)) {
                case MARKED -> marked++;
                case EXTENDED -> extended++;
                default -> unchanged++;
            }
        }

        // b) >=100M naptári havi kumulált KÉSZPÉNZ-forgalom — HÓNAP-stabil horgonyzás
        // (Codex review): az ablak vége hónapvége+1év, így a hónap további napjain az
        // ismételt scan ugyanazt az ablakot számolja → UNCHANGED, nincs napi csúsztatás
        // és audit-spam. A hónapvége-horgony minden hónapon belüli trigger-napra >=1 évet fed.
        LocalDate monthStart = day.withDayOfMonth(1);
        LocalDate monthAnchorUntil = day.withDayOfMonth(day.lengthOfMonth()).plusYears(EDD_WINDOW_YEARS);
        for (Object[] row : transactionRepository.findEddMonthlyCumulativeTriggers(
                monthStart, day, EDD_MONTHLY_THRESHOLD_HUF)) {
            String reason = "V.2.7 b): >=100M Ft havi készpénzforgalom (" + monthStart
                    + " hónap, összesen " + row[2] + " Ft)";
            switch (markEdd((UUID) row[0], (String) row[1], day, monthAnchorUntil, reason)) {
                case MARKED -> marked++;
                case EXTENDED -> extended++;
                default -> unchanged++;
            }
        }

        // f) pass-through (V311): 72h-n belül MINDKÉT irányban >=küszöb forgalom —
        // áteresztő-számla gyanú. Hónapvége-horgony (a b)-vel azonos idempotencia-minta).
        BigDecimal passThroughMin = paramAsBigDecimal(EDD_PASSTHROUGH_MIN_PARAM, EDD_PASSTHROUGH_MIN_DEFAULT);
        LocalDate windowStart = day.minusDays(EDD_PASSTHROUGH_WINDOW_DAYS - 1L);
        for (Object[] row : transactionRepository.findEddPassThroughTriggers(
                windowStart, day, passThroughMin)) {
            String reason = "V.2.7 f): pass-through gyanú — 72h-n belül vétel " + row[2]
                    + " Ft ÉS eladás " + row[3] + " Ft (küszöb: " + passThroughMin.toPlainString() + " Ft)";
            switch (markEdd((UUID) row[0], (String) row[1], day, monthAnchorUntil, reason)) {
                case MARKED -> marked++;
                case EXTENDED -> extended++;
                default -> unchanged++;
            }
        }

        // g) profil-kiugrás (V311): aktuális havi forgalom >= szorzó × előző 6 hónap havi
        // átlaga (és >= zaj-szűrő minimum). Új ügyfélnél (nincs előzmény) nem értelmezett —
        // a nagy összegeket az a)/b) szabály fogja.
        BigDecimal profileMin = paramAsBigDecimal(EDD_PROFILE_MIN_PARAM, EDD_PROFILE_MIN_DEFAULT);
        BigDecimal multiplier = paramAsBigDecimal(EDD_PROFILE_MULTIPLIER_PARAM, EDD_PROFILE_MULTIPLIER_DEFAULT);
        LocalDate histStart = monthStart.minusMonths(EDD_PROFILE_HISTORY_MONTHS);
        LocalDate histEnd = monthStart.minusDays(1);
        for (Object[] row : transactionRepository.findEddMonthlyTurnoverTriggers(
                monthStart, day, profileMin)) {
            UUID companyId = (UUID) row[0];
            String customerCode = (String) row[1];
            BigDecimal currentMonth = (BigDecimal) row[2];
            // Tenant-helyes előzmény: a query company-szűrt (generikus dátum-tartomány összeg)
            BigDecimal histTotal = transactionRepository.sumCustomerQuarterlyTotal(
                    companyId, customerCode, histStart, histEnd);
            if (histTotal == null || histTotal.compareTo(BigDecimal.ZERO) <= 0) {
                continue; // nincs profil-előzmény — a kiugrás nem értelmezhető
            }
            BigDecimal monthlyAvg = histTotal.divide(
                    BigDecimal.valueOf(EDD_PROFILE_HISTORY_MONTHS), 2, java.math.RoundingMode.HALF_UP);
            if (currentMonth.compareTo(monthlyAvg.multiply(multiplier)) < 0) {
                continue;
            }
            String reason = "V.2.7 g): profil-kiugrás — aktuális havi forgalom " + currentMonth
                    + " Ft >= " + multiplier.toPlainString() + "× a 6 havi átlag (" + monthlyAvg.toPlainString() + " Ft)";
            switch (markEdd(companyId, customerCode, day, monthAnchorUntil, reason)) {
                case MARKED -> marked++;
                case EXTENDED -> extended++;
                default -> unchanged++;
            }
        }

        if (marked + extended > 0) {
            log.warn("EDD-scan: day={}, új ablak={}, hosszabbítás={}, változatlan={}",
                    day, marked, extended, unchanged);
        } else {
            log.info("EDD-scan: day={}, nincs új EDD-trigger (változatlan: {})", day, unchanged);
        }
        return new AmlEddScanResult(day, true, marked, extended, unchanged);
    }

    /**
     * Pmt. 30.§ (1) szerinti bejelentett ügyfél manuális EDD-jelölése (V.2.7 c) eset.
     * Compliance-művelet: a flag-állástól FÜGGETLENÜL elérhető (a flag csak az automatikus
     * scant kapcsolja), supervisor+ jogosultsággal a controller-rétegben védve.
     * Tenant-guard: csak a saját cég ügyfele jelölhető (cross-tenant 404).
     */
    @Transactional(rollbackFor = Exception.class)
    public Customer markManualEdd(Long customerId, String reason) {
        if (reason == null || reason.isBlank()) {
            throw new hu.puzzleir.valuta.exception.ValidationException("Az EDD-jelölés indoka kötelező");
        }
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        Customer customer = customerRepository.findById(customerId)
                .filter(c -> c.getCompany() != null && c.getCompany().getId().equals(companyId))
                .orElseThrow(() -> new hu.puzzleir.valuta.exception.ResourceNotFoundException(
                        "Ügyfél nem található: " + customerId));

        LocalDate today = LocalDate.now(BUSINESS_ZONE);
        String fullReason = "Pmt. 30.§ (1) bejelentés (V.2.7 c): " + reason.trim();
        MarkOutcome outcome = applyEddWindow(
                customer, companyId, today, today.plusYears(EDD_WINDOW_YEARS), fullReason);
        // Codex P2: a Pmt.30-bejelentés AKKOR IS audit-köteles, ha a meglévő (hosszabb)
        // ablak miatt az ablak-mezők változatlanok — a bejelentés ténye 8 évig megőrzendő.
        if (outcome == MarkOutcome.UNCHANGED) {
            auditLogService.logForCompany(
                    AUDIT_ACTION,
                    "Pmt. 30.§ (1) bejelentés rögzítve — a meglévő EDD-ablak ("
                            + customer.getEddUntil() + ") hosszabb, mezők változatlanok. " + fullReason,
                    customer.getCustomerCode() + ":" + customer.getEddUntil(),
                    companyId);
        }
        return customer;
    }

    /**
     * EDD-ablak jelölése az ügyfélen — extend-only: a meglévő, későbbi lejáratot nem rövidíti.
     */
    private MarkOutcome markEdd(UUID companyId, String customerCode, LocalDate triggerDay,
                                LocalDate newUntil, String reason) {
        Customer customer = customerRepository
                .findByCustomerCodeAndCompanyId(customerCode, companyId)
                .orElse(null);
        if (customer == null) {
            log.warn("EDD-trigger ismeretlen ügyfélre: company={}, customerCode={}", companyId, customerCode);
            return MarkOutcome.UNCHANGED;
        }
        return applyEddWindow(customer, companyId, triggerDay, newUntil, reason);
    }

    /** A közös extend-only ablak-alkalmazó (scan + manuális Pmt.30 út). */
    private MarkOutcome applyEddWindow(Customer customer, UUID companyId, LocalDate triggerDay,
                                       LocalDate newUntil, String reason) {
        LocalDate current = customer.getEddUntil();
        if (current != null && !current.isBefore(newUntil)) {
            return MarkOutcome.UNCHANGED; // már fedett ablak — idempotens újrafutás
        }

        // Sourcery/Copilot review: minden időbélyeg a BUSINESS_ZONE-ban képződik,
        // hogy UTC JVM-en se csússzon el a scan-dátumhoz képest.
        LocalDateTime nowBusiness = LocalDateTime.now(BUSINESS_ZONE);
        boolean wasActive = current != null && !current.isBefore(triggerDay);
        customer.setEddUntil(newUntil);
        customer.setEddReason(reason);
        customer.setEddSetAt(nowBusiness);
        // V.2.7: az EDD alatt álló ügyfél magas kockázatúként kezelendő
        customer.setHighRiskFlag(true);
        if (customer.getHighRiskReason() == null || customer.getHighRiskReason().isBlank()) {
            customer.setHighRiskReason(reason);
            customer.setHighRiskSetAt(nowBusiness);
        }
        customerRepository.save(customer);

        auditLogService.logForCompany(
                AUDIT_ACTION,
                "Megerősített eljárás (EDD) ablak " + (wasActive ? "hosszabbítva" : "beállítva")
                        + " eddig: " + newUntil + " — " + reason,
                customer.getCustomerCode() + ":" + newUntil,
                companyId);
        return wasActive ? MarkOutcome.EXTENDED : MarkOutcome.MARKED;
    }

    /**
     * Numerikus SystemParameter biztonságos olvasása. Sourcery review: a nem-pozitív érték
     * (0/negatív) a szabályt "mindig-igaz"-zá tenné → hibás/degenerált konfignál a pozitív
     * engineering default lép életbe (warn-nal).
     */
    private BigDecimal paramAsBigDecimal(String key, String defaultValue) {
        String raw = systemParameterService.getValue(key, defaultValue);
        try {
            BigDecimal value = new BigDecimal(raw.trim());
            if (value.compareTo(BigDecimal.ZERO) <= 0) {
                log.warn("Nem-pozitív paraméter {}={} — degenerált konfig, default ({}) használata",
                        key, value.toPlainString(), defaultValue);
                return new BigDecimal(defaultValue);
            }
            return value;
        } catch (NumberFormatException | NullPointerException e) {
            log.warn("Érvénytelen numerikus paraméter {}='{}' — default ({}) használata", key, raw, defaultValue);
            return new BigDecimal(defaultValue);
        }
    }

    /** Aktív-e az ügyfél EDD-ablaka az adott napon (delegál az entity-helperre). */
    public static boolean isEddActive(Customer customer, LocalDate today) {
        return customer != null && customer.isEddActiveOn(today);
    }

    private enum MarkOutcome { MARKED, EXTENDED, UNCHANGED }

    public record AmlEddScanResult(
            LocalDate day,
            boolean enabled,
            int marked,
            int extended,
            int unchanged) {
    }
}
