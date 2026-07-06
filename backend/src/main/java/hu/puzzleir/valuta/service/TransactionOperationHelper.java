package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.logging.VVLogger;
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
    private final AmlApprovalService amlApprovalService;
    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final BranchRepository branchRepository;
    private final VaultStockFlowService vaultStockFlowService;
    private final ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    // A4 (b9-korlevelek FR-02): kötelező körlevél-nyugtázás gate a multi-line / konverzió / sztornó
    // úton is. Flag-gated (default OFF) → a `systemParameterService != null` guard miatt a meglévő
    // (e service-t nem teljesen mockoló) tesztek nem törnek; a circularRepository CSAK enforce=true ágon.
    private final SystemParameterService systemParameterService;
    private final hu.puzzleir.valuta.repository.CircularRepository circularRepository;
    private final ValueBandService valueBandService;

    private static final VVLogger VV_LOG = VVLogger.of(TransactionOperationHelper.class);

    // Napi sztorno ABSZOLUT plafon (audit #2, 2026-05-31): aznap max ennyi sztorno lehetseges.
    // Az utolso (limit-edik) supervisori jovahagyast igenyel; a plafon felett supervisorral sem.
    private static final int DAILY_REVERSAL_LIMIT = 3;


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
        // Backward-compat: ország-adat nélkül (FATF NONE). A FATF-bekötött hívók a 6-arg-ot hívják.
        return performAmlCheck(hufAmount, customerId, customerName, documentNumber, currencyCode, null);
    }

    public AmlService.AmlBasicCheckResult performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode,
                                 String customerNationality) {
        // Backward-compat: engedélyező nélkül (a requiresApproval-ág a meglévő blokkoló viselkedést tartja).
        return performAmlCheck(hufAmount, customerId, customerName, documentNumber, currencyCode,
                customerNationality, null, null);
    }

    public AmlService.AmlBasicCheckResult performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode,
                                 String customerNationality, Long approverWorkerId, String approvalSessionId) {
        // A4 (b9-korlevelek FR-02): kötelező körlevél-nyugtázás gate. Ezt a performAmlCheck-et a
        // multi-line (TransactionMultiLineService) ÉS a konverzió (TransactionConversionService) hívja.
        // (A sztornó/reversal NEM ezen az AML-úton megy → nincs gate-elve, by-design.)
        // Feature-flag mögött (CIRCULAR_ACK_BLOCKING_ENFORCEMENT, default false). A circularRepository
        // CSAK enforce=true ágon dereferálódik → flag-off (vagy nem mockolt függőség) esetén no-op.
        boolean circularEnforce = systemParameterService != null && circularRepository != null
                && "true".equalsIgnoreCase(systemParameterService.getValue(
                        TransactionService.CIRCULAR_ACK_BLOCKING_PARAM,
                        TransactionService.CIRCULAR_ACK_BLOCKING_DEFAULT));
        if (circularEnforce) {
            java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
            Long workerId = SecurityUtils.getCurrentWorkerId();
            java.util.UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
            String circularBlock = TransactionService.circularAckBlockReason(
                    circularRepository.findUnacknowledgedMandatoryForWorker(companyId, workerId, branchId,
                            hu.puzzleir.valuta.util.LegacyCompanyIdentityCodec.toLegacyInt(companyId)),
                    true);
            if (circularBlock != null) {
                throw new ValidationException(circularBlock);
            }
        }

        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber, currencyCode, customerNationality);

        if (basicResult == null) {
            // Audit 2026-05-31 (P2): a VV-AML-004 (FATAL) MÁR a katalógusban van — strukturált
            // VV_LOG.fatal kell (NEM nyers log.error), hogy a Loki/Grafana audit-keresés
            // error_code='VV-AML-004' szerint lássa ezt a FATAL AML-blokkot (a TransactionService
            // azonos ágával egyezően, PR #682). A tranzakciót a dobott ValidationException blokkolja.
            VV_LOG.fatal("VV-AML-004", "aml.service_unavailable_tx_blocked", null,
                    java.util.Map.of("policy", "FAIL_CLOSED"));
            throw new ValidationException("AML ellenorzes nem elerheto, a tranzakcio nem hajthato vegre!");
        }

        if (!basicResult.isApproved()) {
            throw new ValidationException(basicResult.getRejectionReason() != null
                    ? basicResult.getRejectionReason()
                    : "AML ellenorzes sikertelen!");
        }

        // Egyszeri jóváhagyás-rögzítés flag (a TransactionService single-line ágával azonos logika): ha a
        // tranzakció a basicResult- ÉS a threshold-kaput is megüti, a 4-szem-elvű jóváhagyást csak EGYSZER rögzítjük.
        boolean approvalRecorded = false;

        if (basicResult.isRequiresApproval()) {
            // Pmt. 14/A. § (4) / MNB 14/2025 V.2.6: a magas-kockázatú tranzakció (multi-line / konverzió út)
            // kizárólag a kijelölt felelős vezető jóváhagyásával teljesíthető. Érvényes POS-engedélyezőnél
            // INSERT-only audit-rekordba rögzítjük (névvel) és engedjük; különben elutasul (a TransactionService
            // single-line ágával azonos logika). A recordSeniorApproval validál (multi-tenant + szerep + 4-szem).
            String approvalReason = basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor jovahagyas szukseges (AML limit)!";
            if (approverWorkerId == null || amlApprovalService == null) {
                throw new ValidationException(approvalReason);
            }
            amlApprovalService.recordSeniorApproval(
                    approverWorkerId, approvalReason, hufAmount, customerName, null, approvalSessionId);
            approvalRecorded = true;
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

                // Sprint 5.3 C2: 8 napos gordulo limit + manager approval kotelezoseg.
                // Konzisztencia: érvényes POS-engedélyezőnél a 4-szem-elvű jóváhagyást rögzítjük és engedünk
                // (ne blokkoljon csak azért, mert a pénztáros maga nem supervisor); engedélyező nélkül a
                // meglévő szerepkör-alapú blokk marad.
                if (thresholdResult.isRequiresManagerApproval()
                        && !hu.puzzleir.valuta.security.SecurityUtils.isSupervisorOrAbove()) {
                    String reason = thresholdResult.getManagerApprovalReason() != null
                            ? thresholdResult.getManagerApprovalReason()
                            : "Supervisor/Manager jovahagyas szukseges (AML magas kockazatu tranzakcio)";
                    if (!approvalRecorded && approverWorkerId != null && amlApprovalService != null
                            && amlApprovalService.isValidSeniorApprover(approverWorkerId)) {
                        amlApprovalService.recordSeniorApproval(
                                approverWorkerId, reason, hufAmount, customerName, null, approvalSessionId);
                        approvalRecorded = true;
                    } else {
                        throw new ValidationException(reason);
                    }
                }
            }
        }

        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: Reszletes azonositas szukseges - {} Ft, ugyfel: {}", hufAmount, customerId);
        }

        return basicResult;
    }

    /**
     * A3 (Pmt. 50M, b4-foglalo FR-16): forrás-igazolás gate a multi-line / aggregált úton (a single-line
     * TransactionService.enforceSourceOfFunds párja). A flag (AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT, default
     * false) mögött; flag-off vagy nem mockolt systemParameterService esetén no-op. A blokkoló szabályt a
     * TransactionService.sourceOfFundsBlockReason statikus metódus mondja ki (egyetlen igazságforrás).
     */
    public void enforceSourceOfFunds(BigDecimal hufAmount, String docType, java.time.LocalDate docDate) {
        if (!TransactionService.isSourceOfFundsEnforcementEnabled(systemParameterService)) {
            return;
        }
        String reason = TransactionService.sourceOfFundsBlockReason(
                hufAmount, docType, docDate, java.time.LocalDate.now(), true);
        if (reason != null) {
            throw new ValidationException(reason);
        }
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
        BigDecimal limit = getIdentificationLimit();
        if (hufAmount.compareTo(limit) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakciohoz ugyfel azonositas kotelezony!",
                        limit.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakciohoz igazolvany szam kotelezony!",
                        limit.toPlainString()));
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

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato"));
        vaultStockFlowService.validateVaultStockCoverage(branch, currency.getCode(), amount);
    }

    /**
     * Kassza frissitese.
     */
    public void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        // Pessimistic lock hasznalata race condition elkerulesere
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato"));
        BigDecimal normalizedAmount = amount.abs();

        if (!isIncoming) {
            vaultStockFlowService.validateVaultStockCoverage(branch, currency.getCode(), normalizedAmount);
        }

        balance.updateBalance(normalizedAmount, isIncoming);
        cashBalanceRepository.save(balance);

        if (Boolean.TRUE.equals(branch.getIsVault())) {
            vaultStockFlowService.applyGenericVaultStock(branch, currency.getCode(), normalizedAmount, isIncoming);
        }
    }

    /**
     * Cash_balance SOR megszerzese PESSIMISTIC_WRITE lockkal — MUTACIO NELKUL.
     *
     * Codex P1 (2026-05-31, #944 round-3 review) — LOCK-ORDERING / deadlock-megelozes: a normal
     * vetel/eladas (TransactionService.executeBuy/executeSell) eloszor a cash_balance sorokat lockolja
     * (updateCashBalance), majd a vegen irja a daily_session-t (updateSessionStats) — sorrend:
     * cash_balance -> daily_session. A sztorno (TransactionReversalService.executeReversal) viszont a
     * napi sztorno-plafon ellenorzesehez a daily_session sort lockolja; ha ezt a cash_balance lock ELOTT
     * tenne, az ELLENTETES sorrend (daily_session -> cash_balance) a normal tranzakcioval keresztezve
     * adatbazis-deadlockot okozhatna. Ezert a sztorno a daily_session lock ELOTT EZZEL elo-lockolja a
     * majdan modositando cash_balance sorokat (azonos currencyId -> HUF sorrendben), igy a GLOBALIS
     * lock-sorrend mindenhol cash_balance -> daily_session. A kesobbi updateCashBalance ugyanezt a sort
     * mar lockoltan kapja (no-op re-lock), majd mutalja.
     */
    public void lockCashBalance(UUID branchId, Long currencyId) {
        cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem talalhato"));
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
        return ValueBandService.resolve(valueBandService).identificationLimitHuf();
    }
}
