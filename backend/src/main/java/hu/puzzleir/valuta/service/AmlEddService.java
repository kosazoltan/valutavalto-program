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
    /** Az EDD-ablak hossza. */
    static final int EDD_WINDOW_YEARS = 1;

    /** A scheduler is Europe/Budapest zónával fut — a scan-dátum ugyanabban a zónában képződik. */
    static final java.time.ZoneId BUSINESS_ZONE = java.time.ZoneId.of("Europe/Budapest");

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

        if (marked + extended > 0) {
            log.warn("EDD-scan: day={}, új ablak={}, hosszabbítás={}, változatlan={}",
                    day, marked, extended, unchanged);
        } else {
            log.info("EDD-scan: day={}, nincs új EDD-trigger (változatlan: {})", day, unchanged);
        }
        return new AmlEddScanResult(day, true, marked, extended, unchanged);
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
                customerCode + ":" + newUntil,
                companyId);
        return wasActive ? MarkOutcome.EXTENDED : MarkOutcome.MARKED;
    }

    /** Aktív-e az ügyfél EDD-ablaka az adott napon. */
    public static boolean isEddActive(Customer customer, LocalDate today) {
        return customer != null && customer.getEddUntil() != null
                && !customer.getEddUntil().isBefore(today);
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
