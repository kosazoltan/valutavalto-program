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
    public AmlCheckResult checkTransaction(
            BigDecimal hufAmount,
            String customerId,
            String customerName,
            String documentNumber) {

        AmlCheckResult.AmlCheckResultBuilder result = AmlCheckResult.builder()
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
    public static class AmlCheckResult {
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
}
