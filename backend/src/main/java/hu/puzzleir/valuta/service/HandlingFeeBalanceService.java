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
        row.setCurrentBalance(HungarianRounding.roundToFive(row.getCurrentBalance().add(rounded)));
        row.setUpdatedAt(LocalDateTime.now());
        log.debug("HandlingFeeBalance increase branch={} company={} delta={} balance={}",
                branchId, companyId, rounded, row.getCurrentBalance());
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
     * Correction-path decrease: takes what the drawer holds and clamps at zero instead of
     * throwing.
     *
     * <p>SEC-AUDIT 2026-09-16 (FKH-071 follow-up). {@link #decrease} is the USER-REFUSABLE
     * path (FR-7: a KK shipment may not take out more than is accumulated). A reversal or a
     * downward supervisor fee override is not refusable: the money it corrects was already
     * booked into the transaction row, the cash balance and the audit trail inside the SAME
     * database transaction, so a {@code ValidationException} there rolls the whole storno
     * back and an office whose drawer was emptied by a KK shipment could no longer reverse
     * any fee-bearing transaction. The unapplied remainder is logged at WARN so the
     * divergence between the rolled balance and the fee history stays auditable.</p>
     */
    public void settle(UUID branchId, UUID companyId, BigDecimal amount) {
        BigDecimal rounded = HungarianRounding.roundToFive(amount);
        if (rounded.signum() <= 0) {
            return;
        }
        HandlingFeeBalance row = lockOrCreate(branchId, companyId);
        BigDecimal available = row.getCurrentBalance();
        BigDecimal applied = rounded.min(available);
        if (applied.signum() <= 0) {
            log.warn("HandlingFeeBalance settle skipped (drawer empty) branch={} company={} requested={}",
                    branchId, companyId, rounded);
            return;
        }
        row.setCurrentBalance(HungarianRounding.roundToFive(available.subtract(applied)));
        row.setUpdatedAt(LocalDateTime.now());
        if (applied.compareTo(rounded) < 0) {
            log.warn("HandlingFeeBalance settle clamped branch={} company={} requested={} applied={} balance={}",
                    branchId, companyId, rounded, applied, row.getCurrentBalance());
        } else {
            log.debug("HandlingFeeBalance settle branch={} company={} delta={} balance={}",
                    branchId, companyId, applied, row.getCurrentBalance());
        }
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
