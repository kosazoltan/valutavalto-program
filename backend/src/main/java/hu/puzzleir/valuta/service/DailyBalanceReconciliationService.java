package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Napi mérleg egyeztetési szolgáltatás.
 *
 * Összehasonlítja a számított záró egyenleget (DailyBalance.closingBalance)
 * a tényleges kassza egyenleggel (CashBalance.currentBalance), és eltérés esetén
 * riasztást generál.
 *
 * Tűréshatár: 0.01 (kerekítési különbségek figyelmen kívül hagyása).
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyBalanceReconciliationService {

    /** Kerekítési tűréshatár — ennél kisebb eltérést nem riasztjuk */
    static final BigDecimal TOLERANCE = new BigDecimal("0.01");

    private final DailyBalanceRepository dailyBalanceRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final AuditLogService auditLogService;

    /**
     * Egyeztetés futtatása egy iroda + dátumra.
     *
     * @param branchId Iroda azonosító
     * @param date     Dátum
     * @return Az eltéréseket tartalmazó riasztások listája (üres, ha minden egyezik)
     */
    public List<ReconciliationAlert> reconcile(UUID branchId, LocalDate date) {
        log.info("Napi egyeztetés indítva: branchId={}, date={}", branchId, date);

        List<DailyBalance> dailyBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(branchId, date);

        if (dailyBalances.isEmpty()) {
            log.debug("Nincs napi mérleg egyeztetéshez: branchId={}, date={}", branchId, date);
            return List.of();
        }

        // CashBalance indexelés valuta kód szerint
        List<CashBalance> cashBalances = cashBalanceRepository.findAllByBranchId(branchId);
        Map<String, BigDecimal> actualByCode = cashBalances.stream()
            .filter(cb -> cb.getCurrency() != null && cb.getCurrency().getCode() != null)
            .collect(Collectors.toMap(
                cb -> cb.getCurrency().getCode(),
                CashBalance::getCurrentBalance,
                (a, b) -> a  // duplikátum esetén az első érték marad
            ));

        List<ReconciliationAlert> alerts = new ArrayList<>();

        for (DailyBalance db : dailyBalances) {
            String currencyCode = db.getCurrencyCode();
            BigDecimal calculated = db.getClosingBalance();
            BigDecimal actual = actualByCode.get(currencyCode);

            if (actual == null) {
                log.debug("Nincs CashBalance adat: branchId={}, currency={} — egyeztetés kihagyva",
                    branchId, currencyCode);
                continue;
            }

            BigDecimal difference = calculated.subtract(actual).abs();

            if (difference.compareTo(TOLERANCE) > 0) {
                BigDecimal signedDiff = calculated.subtract(actual);
                ReconciliationAlert alert = new ReconciliationAlert(
                    branchId, currencyCode, date, calculated, actual, signedDiff
                );
                alerts.add(alert);

                log.warn("Napi egyeztetési eltérés: branchId={}, date={}, currency={}, " +
                         "számított={}, tényleges={}, eltérés={}",
                    branchId, date, currencyCode, calculated, actual, signedDiff);

                auditLogService.log(
                    "DAILY_BALANCE_RECONCILIATION_MISMATCH",
                    String.format(
                        "Egyeztetési eltérés (%s / %s): számított=%s, tényleges=%s, diff=%s",
                        date, currencyCode, calculated, actual, signedDiff
                    ),
                    branchId.toString()
                );
            } else {
                log.debug("Egyeztetés OK: branchId={}, date={}, currency={}, egyenleg={}",
                    branchId, date, currencyCode, calculated);
            }
        }

        if (alerts.isEmpty()) {
            log.info("Napi egyeztetés sikeres (nincs eltérés): branchId={}, date={}, {} valuta ellenőrizve",
                branchId, date, dailyBalances.size());
        } else {
            log.warn("Napi egyeztetés befejezve {} eltéréssel: branchId={}, date={}",
                alerts.size(), branchId, date);
        }

        return alerts;
    }

    // ============================================================
    // Inner class: ReconciliationAlert
    // ============================================================

    /**
     * Egyeztetési eltérés riasztás.
     */
    public static class ReconciliationAlert {

        private final UUID branchId;
        private final String currencyCode;
        private final LocalDate date;
        private final BigDecimal calculatedBalance;
        private final BigDecimal actualBalance;
        private final BigDecimal difference;

        public ReconciliationAlert(
            UUID branchId,
            String currencyCode,
            LocalDate date,
            BigDecimal calculatedBalance,
            BigDecimal actualBalance,
            BigDecimal difference
        ) {
            this.branchId = branchId;
            this.currencyCode = currencyCode;
            this.date = date;
            this.calculatedBalance = calculatedBalance;
            this.actualBalance = actualBalance;
            this.difference = difference;
        }

        public UUID getBranchId() { return branchId; }
        public String getCurrencyCode() { return currencyCode; }
        public LocalDate getDate() { return date; }
        public BigDecimal getCalculatedBalance() { return calculatedBalance; }
        public BigDecimal getActualBalance() { return actualBalance; }
        public BigDecimal getDifference() { return difference; }

        /**
         * Túlfizetés: a számított egyenleg magasabb a ténylegnél.
         */
        public boolean isOverage() {
            return difference.compareTo(BigDecimal.ZERO) > 0;
        }

        /**
         * Hiány: a számított egyenleg alacsonyabb a ténylegnél.
         */
        public boolean isShortage() {
            return difference.compareTo(BigDecimal.ZERO) < 0;
        }

        @Override
        public String toString() {
            return String.format("ReconciliationAlert{branch=%s, currency=%s, date=%s, " +
                    "calculated=%s, actual=%s, diff=%s, overage=%s}",
                branchId, currencyCode, date, calculatedBalance, actualBalance, difference, isOverage());
        }
    }
}
