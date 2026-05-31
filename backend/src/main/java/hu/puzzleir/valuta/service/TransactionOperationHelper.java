package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Tranzakcio muveletekhez szukseges segedmetodusok.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TransactionOperationHelper {

    private final DailySessionService dailySessionService;
    private final AmlService amlService;
    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;

    // Sztorno limit supervisor nelkul (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    // Azonositas nelkuli limit HUF-ban (300.000 Ft - NAV szabalyozas)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    // Max tetelsorok szama bizonylaton (Legacy: BLOKKTETEL limit)
    private static final int MAX_TRANSACTION_LINES = 6;

    // HUF currency ID cache - startup-kor betoltve, ne kelljen minden tranzakcionál DB-t kerdezni
    private volatile Long cachedHufCurrencyId;

    /**
     * Nyitott napi munkamenet ellenorzese.
     */
    public void validateOpenSession() {
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet! Eloszor nyissa meg a napot.");
        }
    }

    /**
     * AML ellenorzes a tranzakcio elott.
     *
     * Legacy parity (CB-018): a visszakapott `AmlBasicCheckResult` flagek
     * (`suspiciousFlag`, `annualLimitReached`) a hivo oldalon a Transaction entitasba
     * kerulnek, hogy a bizonylat tartalmazza az AML besorolast (legacy BIGCTRL mezokkel parity).
     */
    public AmlService.AmlBasicCheckResult performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode) {
        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber, currencyCode);

        if (basicResult == null) {
            log.error("AML checkTransaction null eredmenyt adott, tranzakcio blokkolva");
            throw new ValidationException("AML ellenorzes nem elerheto, a tranzakcio nem hajthato vegre!");
        }

        if (!basicResult.isApproved()) {
            throw new ValidationException(basicResult.getRejectionReason() != null
                    ? basicResult.getRejectionReason()
                    : "AML ellenorzes sikertelen!");
        }

        if (basicResult.isRequiresApproval()) {
            throw new ValidationException(basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor jovahagyas szukseges (AML limit)!");
        }

        if (customerId != null && !customerId.isBlank()) {
            var thresholdResult = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
            if (thresholdResult != null) {
                if (thresholdResult.isBlocked()) {
                    String warnings = thresholdResult.getWarnings() != null && !thresholdResult.getWarnings().isEmpty()
                            ? String.join("; ", thresholdResult.getWarnings())
                            : "AML szabaly alapjan blokkolva";
                    throw new ValidationException(warnings);
                }

                // Sprint 5.3 C2: 8 napos gordulo limit + manager approval kotelezoseg
                if (thresholdResult.isRequiresManagerApproval()
                        && !hu.puzzleir.valuta.security.SecurityUtils.isSupervisorOrAbove()) {
                    String reason = thresholdResult.getManagerApprovalReason() != null
                            ? thresholdResult.getManagerApprovalReason()
                            : "Supervisor/Manager jovahagyas szukseges (AML magas kockazatu tranzakcio)";
                    throw new ValidationException(reason);
                }
            }
        }

        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: Reszletes azonositas szukseges - {} Ft, ugyfel: {}", hufAmount, customerId);
        }

        return basicResult;
    }

    /**
     * Audit-finding 2026-05-31 (P1): a sikeres tranzakcio KONYVELESE UTAN frissiti az ugyfel
     * highRiskFlag-jet, ha az eves gongyolt elerte az AML limitet. Eddig az
     * {@code AmlService.setHighRiskFlagIfNeeded} SEHOL nem hivodott -> a fokozott atvilagitasi
     * (nagy-ugyfel) jeloles eles uzemben SOSEM aktivalodott (halott write-oldali AML-kontroll).
     * A save UTAN hivando, hogy a {@code getAnnualRollingTotal} a friss osszeget tukrozze.
     */
    public void flagHighRiskAfterBooking(String customerId) {
        if (customerId == null || customerId.isBlank()) {
            return;
        }
        amlService.setHighRiskFlagIfNeeded(customerId, amlService.getAnnualRollingTotal(customerId));
    }

    /**
     * Ugyfel azonositas ellenorzese.
     */
    public void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakciohoz ugyfel azonositas kotelezony!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakciohoz igazolvany szam kotelezony!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
        }
    }

    /**
     * Valuta keszlet ellenorzese.
     */
    public void validateCurrencyStock(UUID branchId, Long currencyId, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElse(null);

        if (balance == null || balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException("Nincs elegendo valuta keszlet!");
        }
    }

    /**
     * Kassza frissitese.
     */
    public void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        // Pessimistic lock hasznalata race condition elkerulesere
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem talalhato"));

        balance.updateBalance(amount.abs(), isIncoming);
        cashBalanceRepository.save(balance);
    }

    /**
     * Kamera bizonylat linkeles.
     */
    public void linkCameraEvidence(Transaction transaction) {
        if (cameraTransactionLinkerProvider == null) {
            return;
        }

        CameraTransactionLinker linker = cameraTransactionLinkerProvider.getIfAvailable();
        if (linker == null || transaction == null || transaction.getId() == null || transaction.getBranch() == null) {
            return;
        }

        LocalDate txDate = transaction.getTransactionDate();
        LocalTime txTime = transaction.getTransactionTime();
        if (txDate == null || txTime == null) {
            log.debug("Kamera linkeles kihagyva hianyzo datum/ido miatt: tx={}", transaction.getId());
            return;
        }

        try {
            linker.linkTransaction(
                    transaction.getId(),
                    transaction.getBranch().getId(),
                    txDate.atTime(txTime),
                    transaction.getReceiptNumber());
        } catch (Exception e) {
            log.error("Kamera-tranzakcio linkeles sikertelen: tx={}, receipt={}",
                    transaction.getId(), transaction.getReceiptNumber(), e);
        }
    }

    /**
     * HUF valuta ID lekerdezese.
     */
    public Long getHufCurrencyId() {
        if (cachedHufCurrencyId == null) {
            // Ujraprobálás: lehet hogy a DB-ben kesve kerult be a HUF valuta
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId == null) {
                throw new ValidationException("HUF valuta nem talalhato az adatbazisban! Kerjuk inicializalja a valuta tablat.");
            }
        }
        return cachedHufCurrencyId;
    }

    /**
     * Currency ID feloldasa.
     */
    public Long resolveCurrencyId(Long currencyId, String currencyCode) {
        if (currencyId != null && currencyId > 0) {
            return currencyId;
        }
        if (currencyCode != null && !currencyCode.isBlank()) {
            return currencyRepository.findByCode(currencyCode.toUpperCase())
                    .map(c -> c.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta kod: " + currencyCode));
        }
        throw new ValidationException("Valuta azonosito (currencyId) vagy valuta kod (currencyCode) kotelezony!");
    }

    /**
     * Napi sztorno limit lekerdezese.
     */
    public int getDailyReversalLimit() {
        return DAILY_REVERSAL_LIMIT;
    }

    /**
     * Max tetelsorok szama bizonylaton.
     */
    public int getMaxTransactionLines() {
        return MAX_TRANSACTION_LINES;
    }

    /**
     * Azonositas nelkuli limit HUF-ban.
     */
    public BigDecimal getIdentificationLimit() {
        return IDENTIFICATION_LIMIT;
    }
}
