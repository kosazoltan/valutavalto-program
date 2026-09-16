package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.HandlingFeeBalance;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.HandlingFeeBalanceRepository;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FKH-071: pessimistic-lock mutations of the rolled handling-fee drawer balance.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class HandlingFeeBalanceService {

    private final HandlingFeeBalanceRepository handlingFeeBalanceRepository;

    public void increase(UUID branchId, UUID companyId, BigDecimal amount) {
        BigDecimal rounded = HungarianRounding.roundToFive(amount);
        if (rounded.signum() <= 0) {
            return;
        }
        HandlingFeeBalance row = lockOrCreate(branchId, companyId);
        // SEC-001: a correction that the drawer could not cover is parked in deferredDeduction
        // and settled here FIRST, so a later FR-5 shipment cancellation cannot restore money the
        // reversal already cancelled (the +290/-290/-0/+290 phantom balance).
        BigDecimal remaining = rounded;
        BigDecimal deferred = nonNull(row.getDeferredDeduction());
        if (deferred.signum() > 0) {
            BigDecimal offset = deferred.min(remaining);
            row.setDeferredDeduction(deferred.subtract(offset));
            remaining = remaining.subtract(offset);
            log.info("HandlingFeeBalance deferred offset branch={} company={} offset={} deferredLeft={}",
                    branchId, companyId, offset, row.getDeferredDeduction());
        }
        if (remaining.signum() > 0) {
            row.setCurrentBalance(HungarianRounding.roundToFive(row.getCurrentBalance().add(remaining)));
        }
        row.setUpdatedAt(LocalDateTime.now());
        log.debug("HandlingFeeBalance increase branch={} company={} delta={} applied={} balance={}",
                branchId, companyId, rounded, remaining, row.getCurrentBalance());
    }

    public void decrease(UUID branchId, UUID companyId, BigDecimal amount) {
        BigDecimal rounded = HungarianRounding.roundToFive(amount);
        if (rounded.signum() <= 0) {
            return;
        }
        HandlingFeeBalance row = lockOrCreate(branchId, companyId);
        BigDecimal next = HungarianRounding.roundToFive(row.getCurrentBalance().subtract(rounded));
        if (next.signum() < 0) {
            throw new ValidationException(
                    "VV-VALID-009: A kezelési díj egyenlege nem mehet negatívba"
                            + " (elérhető: " + row.getCurrentBalance().toPlainString()
                            + " Ft, kért: " + rounded.toPlainString() + " Ft).");
        }
        row.setCurrentBalance(next);
        row.setUpdatedAt(LocalDateTime.now());
        log.debug("HandlingFeeBalance decrease branch={} company={} delta={} balance={}",
                branchId, companyId, rounded, row.getCurrentBalance());
    }

    public boolean exists(UUID branchId, UUID companyId) {
        return handlingFeeBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId).isPresent();
    }

    /**
     * Correction-path decrease: takes what the drawer holds, never throws, and PARKS the
     * uncovered remainder in {@code deferredDeduction} (V395).
     *
     * <p>SEC-AUDIT 2026-09-16 (FKH-071 follow-up). {@link #decrease} is the USER-REFUSABLE
     * path (FR-7: a KK shipment may not take out more than is accumulated). A reversal or a
     * downward supervisor fee override is not refusable: the money it corrects was already
     * booked into the transaction row, the cash balance and the audit trail inside the SAME
     * database transaction, so a {@code ValidationException} there rolls the whole storno
     * back and an office whose drawer was emptied by a KK shipment could no longer reverse
     * any fee-bearing transaction.</p>
     *
     * <p>Clamping alone would lose money truth: the FR-5 cancellation of that KK shipment later
     * restores its full amount, producing +290 / -290 / -0 / +290 = a phantom 290 instead of 0.
     * The uncovered part is therefore persisted and offset by {@link #increase} before any
     * later credit reaches the balance.</p>
     */
    public void settle(UUID branchId, UUID companyId, BigDecimal amount) {
        BigDecimal rounded = HungarianRounding.roundToFive(amount);
        if (rounded.signum() <= 0) {
            return;
        }
        HandlingFeeBalance row = lockOrCreate(branchId, companyId);
        BigDecimal available = nonNull(row.getCurrentBalance());
        BigDecimal applied = rounded.min(available);
        if (applied.signum() > 0) {
            row.setCurrentBalance(HungarianRounding.roundToFive(available.subtract(applied)));
        }
        BigDecimal uncovered = rounded.subtract(applied);
        if (uncovered.signum() > 0) {
            row.setDeferredDeduction(nonNull(row.getDeferredDeduction()).add(uncovered));
            log.warn("HandlingFeeBalance settle deferred branch={} company={} requested={} applied={}"
                            + " deferred={} balance={}",
                    branchId, companyId, rounded, applied, row.getDeferredDeduction(),
                    row.getCurrentBalance());
        } else {
            log.debug("HandlingFeeBalance settle branch={} company={} delta={} balance={}",
                    branchId, companyId, applied, row.getCurrentBalance());
        }
        row.setUpdatedAt(LocalDateTime.now());
    }

    private static BigDecimal nonNull(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private HandlingFeeBalance lockOrCreate(UUID branchId, UUID companyId) {
        handlingFeeBalanceRepository.insertIfAbsent(companyId, branchId);
        return handlingFeeBalanceRepository
                .findByBranchIdAndCompanyIdForUpdate(branchId, companyId)
                .orElseThrow(() -> new IllegalStateException(
                        "handling_fee_balance row missing after insertIfAbsent"
                                + " company=" + companyId + " branch=" + branchId));
    }
}
