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

    private HandlingFeeBalance lockOrCreate(UUID branchId, UUID companyId) {
        handlingFeeBalanceRepository.insertIfAbsent(companyId, branchId);
        return handlingFeeBalanceRepository
                .findByBranchIdAndCompanyIdForUpdate(branchId, companyId)
                .orElseThrow(() -> new IllegalStateException(
                        "handling_fee_balance row missing after insertIfAbsent"
                                + " company=" + companyId + " branch=" + branchId));
    }
}
