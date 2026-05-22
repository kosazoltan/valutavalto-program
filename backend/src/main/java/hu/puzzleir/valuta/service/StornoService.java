package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.storno.StornoApprovalDto;
import hu.puzzleir.valuta.dto.storno.StornoCheckResultDto;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.StornoApproval;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.StornoApprovalRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Sztornó szolgáltatás.
 * Sztornó ellenőrzés, jóváhagyás kérés, jóváhagyás, végrehajtás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class StornoService {

    private final TransactionRepository transactionRepository;
    private final StornoApprovalRepository stornoApprovalRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final TransactionService transactionService;
    private final DictionaryRepository dictionaryRepository;
    private final ExchangeRateRepository exchangeRateRepository;

    // Napi sztornó limit supervisor jóváhagyás nélkül — iroda szinten
    private static final int DAILY_STORNO_LIMIT_BRANCH = 3;

    // Napi sztornó limit supervisor jóváhagyás nélkül — pénztáros szinten
    // Legacy: a limit irodánként ÉS pénztárosonként is érvényes
    private static final int DAILY_STORNO_LIMIT_CASHIER = 2;

    /**
     * PR #115: Sztornó ellenőrzés receipt_number-rel VAGY id-vel.
     *
     * A frontend és Penztar-client a `tx.receiptNumber || tx.id` fallback-et
     * használja URL path param-ban — mindkét forma működik.
     */
    @Transactional(readOnly = true)
    public StornoCheckResultDto checkStorno(String transactionIdOrReceipt, Long workerId) {
        Transaction transaction = resolveTransaction(transactionIdOrReceipt);
        return doCheckStorno(transaction, workerId);
    }

    /**
     * Backward-compat overload: régi Long id-s hívás.
     */
    @Transactional(readOnly = true)
    public StornoCheckResultDto checkStorno(Long transactionId, Long workerId) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));
        return doCheckStorno(transaction, workerId);
    }

    /**
     * Tranzakció feloldás id (numerikus) VAGY receipt_number (string) alapján.
     */
    private Transaction resolveTransaction(String idOrReceipt) {
        if (idOrReceipt == null || idOrReceipt.isBlank()) {
            throw new ResourceNotFoundException("Tranzakció azonosító hiányzik");
        }
        try {
            Long id = Long.parseLong(idOrReceipt);
            return transactionRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + id));
        } catch (NumberFormatException e) {
            // Multi-tenant: receipt_number csak cégen belül egyedi.
            java.util.UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
            return transactionRepository.findByReceiptNumberAndCompanyId(idOrReceipt, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Tranzakció nem található bizonylat szám alapján: " + idOrReceipt));
        }
    }

    private StornoCheckResultDto doCheckStorno(Transaction transaction, Long workerId) {
        Long transactionId = transaction.getId();

        UUID branchId = SecurityUtils.getCurrentBranchId();

        // IDOR védelem: csak saját iroda tranzakciója ellenőrizhető
        if (!transaction.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        // 2026-04-29 v2.3.30 (Sourcery PR #293 P2): companyId egyszer extract,
        // NEM ismétlődő SecurityUtils.getCurrentCompanyId() inline minden hívásnál.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();
        // Napi sztornó számok — iroda szinten ÉS pénztáros szinten
        int dailyCountBranch = (int) transactionRepository.countReversalsByBranchAndDate(companyId, branchId, today);
        int dailyCountCashier = (int) transactionRepository.countReversalsByBranchAndWorkerAndDate(
                companyId, branchId, workerId, today);

        // HIGH FIX #8: Ha a tranzakció ALREADY_REVERSED → dobjon hibát, ne engedje tovább
        if (transaction.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett (REVERSED státusz)!");
        }
        if (transaction.isReversal()) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható!");
        }

        // Legacy: a limit irodánként ÉS pénztárosonként is érvényes
        boolean branchLimitReached = dailyCountBranch >= DAILY_STORNO_LIMIT_BRANCH;
        boolean cashierLimitReached = dailyCountCashier >= DAILY_STORNO_LIMIT_CASHIER;
        boolean isPreviousDay = !transaction.getTransactionDate().equals(LocalDate.now());

        boolean requiresApproval = branchLimitReached || cashierLimitReached || isPreviousDay;

        String message;
        if (requiresApproval) {
            List<String> reasons = new ArrayList<>();
            if (branchLimitReached) {
                reasons.add(String.format("irodai napi sztornó szám (%d) elérte a limitet (%d)",
                        dailyCountBranch, DAILY_STORNO_LIMIT_BRANCH));
            }
            if (cashierLimitReached) {
                reasons.add(String.format("pénztáros napi sztornó szám (%d) elérte a limitet (%d)",
                        dailyCountCashier, DAILY_STORNO_LIMIT_CASHIER));
            }
            if (isPreviousDay) {
                reasons.add("korábbi napi tranzakció");
            }
            message = "Supervisor jóváhagyás szükséges: " + String.join("; ", reasons) + ".";
        } else {
            message = "Sztornó végrehajtható.";
        }

        // Árfolyam-eltérés ellenőrzés (Felmérés: sztorno.docx követelmény)
        BigDecimal originalRate = transaction.getExchangeRate();
        BigDecimal currentRate = originalRate; // Default: eredeti
        BigDecimal rateDifference = BigDecimal.ZERO;
        boolean rateChanged = false;

        if (transaction.getCurrency() != null && originalRate != null) {
            // Aktuális árfolyam lekérése az ExchangeRateRepository-ból
            // 2026-04-29 v2.3.30: a `companyId` már a metódus elején extract,
            // NEM duplikál (Sourcery PR #293 P2 — companyId extract egyszer).
            try {
                var latestRateOpt = exchangeRateRepository.findLatestRate(
                        companyId, transaction.getCurrency().getId(), branchId);
                if (latestRateOpt.isPresent()) {
                    ExchangeRate latest = latestRateOpt.get();
                    // A tranzakció típusától és összegsávjától függően válasszuk az aktuális árfolyamot
                    BigDecimal latestApplicableRate = transaction.getTransactionType() == TransactionType.BUY
                            ? latest.getBuyRateForAmount(transaction.getHufAmount())
                            : latest.getSellRateForAmount(transaction.getHufAmount());
                    if (latestApplicableRate != null && latestApplicableRate.compareTo(BigDecimal.ZERO) > 0) {
                        currentRate = latestApplicableRate;
                        rateDifference = currentRate.subtract(originalRate);
                        rateChanged = rateDifference.abs().compareTo(BigDecimal.valueOf(0.01)) > 0;
                    }
                }
            } catch (Exception e) {
                log.warn("Árfolyam-eltérés ellenőrzés sikertelen: {}", e.getMessage());
            }
        }

        return StornoCheckResultDto.builder()
                .requiresApproval(requiresApproval)
                .dailyStornoCount(dailyCountBranch)
                .transactionId(String.valueOf(transactionId))
                .transactionNumber(transaction.getReceiptNumber())
                .message(message)
                .originalRate(originalRate)
                .currentRate(currentRate)
                .rateDifference(rateDifference)
                .rateChanged(rateChanged)
                .build();
    }

    /**
     * Sztornó jóváhagyás kérése
     */
    public StornoApprovalDto requestApproval(Long transactionId, Long workerId, String reason) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        UUID branchId = SecurityUtils.getCurrentBranchId();

        // IDOR védelem: csak saját iroda tranzakciója sztornózható
        if (!transaction.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());

        StornoApproval approval = StornoApproval.builder()
                .transaction(transaction)
                .worker(worker)
                .branch(branch)
                .dailyStornoCount(dailyCount)
                .requestReason(reason)
                .build();

        StornoApproval saved = stornoApprovalRepository.save(approval);
        log.info("Sztornó jóváhagyás kérve: tranzakció={}, pénztáros={}", transactionId, workerId);

        return toApprovalDto(saved);
    }

    /**
     * Sztornó jóváhagyása/elutasítása supervisor által
     */
    public StornoApprovalDto approve(UUID approvalId, Long approvedByWorkerId, boolean approved, String reason) {
        StornoApproval approval = stornoApprovalRepository.findById(approvalId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyási kérés nem található: " + approvalId));

        // IDOR védelem: csak saját iroda jóváhagyási kérése kezelhető
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!approval.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda jóváhagyási kéréséhez!");
        }

        Worker approver = workerRepository.findById(approvedByWorkerId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyó pénztáros nem található: " + approvedByWorkerId));

        approval.setApprovedByWorker(approver);
        approval.setApprovedAt(LocalDateTime.now());

        // M-3: ApprovalStatus beállítása
        String statusCode = approved ? "APPROVED" : "REJECTED";
        approval.setApprovalStatus(dictionaryRepository
                .findByCategoryAndCode("STORNO_APPROVAL_STATUS", statusCode)
                .orElseThrow(() -> new IllegalStateException(
                        "Hiányzó dictionary bejegyzés: STORNO_APPROVAL_STATUS/" + statusCode)));

        if (!approved) {
            approval.setRejectionReason(reason);
        }

        StornoApproval saved = stornoApprovalRepository.save(approval);
        log.info("Sztornó jóváhagyás {}: approvalId={}, által={}", approved ? "ELFOGADVA" : "ELUTASÍTVA", approvalId, approvedByWorkerId);

        return toApprovalDto(saved);
    }

    /**
     * Sztornó végrehajtása
     */
    public Transaction executeStorno(StornoRequestDto request, Long workerId) {
        Long transactionId = Long.parseLong(request.getTransactionId());

        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        // IDOR védelem: csak saját iroda tranzakciója sztornózható
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztornó tranzakció nem sztornózható!");
        }

        // Sztornó végrehajtás a TransactionService reversal metódusával
        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason(request.getReason())
                .approvedBy(String.valueOf(workerId))
                .useCurrentRate(request.getUseCurrentRate())
                .customExchangeRate(request.getCustomExchangeRate())
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);
        log.info("Sztornó végrehajtva: eredeti={}, sztornó={}", original.getReceiptNumber(), reversal.getReceiptNumber());

        return reversal;
    }

    /**
     * POS sztornó végrehajtása
     */
    public Transaction executePosStorno(String posTransactionId, Long workerId, String reason) {
        Long transactionId = Long.parseLong(posTransactionId);

        // IDOR védelem: csak saját iroda tranzakcióját lehet POS-sztornózni
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));
        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason(reason)
                .approvedBy(String.valueOf(workerId))
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);
        log.info("POS sztornó végrehajtva: eredeti={}, sztornó={}", posTransactionId, reversal.getReceiptNumber());

        return reversal;
    }

    // ============ OTP TERMINÁL INTEGRÁCIÓ (Legacy: STORNO.DLL + OTP terminál) ============

    /**
     * OTP terminál sztornó végrehajtása.
     * Legacy: VTEMP.OTPFUNCTYPE=100 → OtpTermStorno
     *
     * Ha a tranzakció bankkártyás volt (PaymentMethod.CARD),
     * az OTP terminálon is sztornózni kell.
     * A terminál POS referencia szám alapján azonosítja a tranzakciót.
     */
    public Transaction executeOtpTerminalStorno(Long transactionId, Long workerId, String reason) {
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }

        // Ellenőrzés: bankkártyás tranzakció volt-e
        if (original.getPaymentMethod() != hu.puzzleir.valuta.entity.PaymentMethod.CARD) {
            throw new ValidationException("OTP terminál sztornó csak bankkártyás tranzakcióra alkalmazható!");
        }

        if (original.getPosAuthorizationCode() == null || original.getPosAuthorizationCode().isBlank()) {
            throw new ValidationException("Hiányzó POS autorizációs kód — OTP terminál sztornó nem végrehajtható!");
        }

        // Napi sztornó számláló ellenőrzés (Legacy: NAPISTORNO > 2 → supervisor)
        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());
        if (dailyCount >= DAILY_STORNO_LIMIT_BRANCH) {
            log.warn("OTP terminál sztornó: napi limit ({}) elérve, supervisor jóváhagyás szükséges!",
                    DAILY_STORNO_LIMIT_BRANCH);
            throw new ValidationException(
                String.format("Napi OTP sztornó limit (%d) elérve — supervisor jóváhagyás szükséges!",
                    DAILY_STORNO_LIMIT_BRANCH));
        }

        // Sztornó végrehajtás
        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason("OTP_TERMINAL_STORNO: " + reason)
                .approvedBy(String.valueOf(workerId))
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);

        // POS terminál adatok másolása a sztornó tranzakcióra
        reversal.setPosAuthorizationCode(original.getPosAuthorizationCode());
        reversal.setPosReferenceNumber(original.getPosReferenceNumber());
        reversal.setPosTerminalId(original.getPosTerminalId());
        reversal.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
        transactionRepository.save(reversal);

        log.info("OTP terminál sztornó végrehajtva: eredeti={}, sztornó={}, POS ref={}",
                original.getReceiptNumber(), reversal.getReceiptNumber(), original.getPosReferenceNumber());

        return reversal;
    }

    /**
     * OTP áruvisszavét (árustornó).
     * Legacy: VTEMP.OTPFUNCTYPE=4 → OtpAruvisszavet
     *
     * Különbség a normál OTP sztornóhoz:
     * - Ha refundAmount == null VAGY refundAmount == originalHufAmount → teljes sztornó (backward compat)
     * - Ha 0 < refundAmount < originalHufAmount → részleges visszatérítés (PARTIAL_REFUND)
     *
     * P3-15 fix: a régi implementáció mindig executeReversal()-t hívott, figyelmen kívül hagyva
     * a refundAmount paramétert részleges esetben.
     */
    public Transaction executeOtpRefund(Long transactionId, Long workerId,
                                         BigDecimal refundAmount, String reason) {
        Transaction original = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        UUID branchId = SecurityUtils.getCurrentBranchId();
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Nincs jogosultság más iroda tranzakciójához!");
        }

        if (original.getPaymentMethod() != hu.puzzleir.valuta.entity.PaymentMethod.CARD) {
            throw new ValidationException("OTP áruvisszavét csak bankkártyás tranzakcióra alkalmazható!");
        }

        // 0 összeg nem megengedett
        if (refundAmount != null && refundAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Visszatérítés összege pozitív kell legyen!");
        }

        // Refund összeg nem haladhatja meg az eredetit
        if (refundAmount != null && refundAmount.compareTo(original.getHufAmount()) > 0) {
            throw new ValidationException(
                String.format("Visszatérítés összege (%s Ft) nem haladhatja meg az eredeti összeget (%s Ft)!",
                    refundAmount.toPlainString(), original.getHufAmount().toPlainString()));
        }

        boolean isPartial = refundAmount != null
                && refundAmount.compareTo(original.getHufAmount()) < 0;

        if (isPartial) {
            // Részleges visszatérítés: PARTIAL_REFUND tranzakció, kassza csak részleges korrekcióval,
            // az eredeti tranzakció NEM kerül REVERSED státuszba
            TransactionService.PartialRefundRequest partialRequest = TransactionService.PartialRefundRequest.builder()
                    .originalTransactionId(transactionId)
                    .refundHufAmount(refundAmount)
                    .reason("OTP_ARUVISSZAVET_RESZLEGES: " + reason)
                    .approvedBy(String.valueOf(workerId))
                    .build();

            Transaction partialRefundTx = transactionService.executePartialRefund(partialRequest);

            partialRefundTx.setPosAuthorizationCode(original.getPosAuthorizationCode());
            partialRefundTx.setPosReferenceNumber(original.getPosReferenceNumber());
            partialRefundTx.setPosTerminalId(original.getPosTerminalId());
            partialRefundTx.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
            transactionRepository.save(partialRefundTx);

            log.info("OTP részleges áruvisszavét végrehajtva: eredeti={}, visszatérítés={}, összeg={} Ft",
                    original.getReceiptNumber(), partialRefundTx.getReceiptNumber(), refundAmount.toPlainString());

            return partialRefundTx;
        } else {
            // Teljes sztornó (refundAmount == null VAGY refundAmount == originalHufAmount)
            TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(transactionId)
                    .reason("OTP_ARUVISSZAVET: " + reason)
                    .approvedBy(String.valueOf(workerId))
                    .build();

            Transaction reversal = transactionService.executeReversal(reversalRequest);

            reversal.setPosAuthorizationCode(original.getPosAuthorizationCode());
            reversal.setPosReferenceNumber(original.getPosReferenceNumber());
            reversal.setPosTerminalId(original.getPosTerminalId());
            reversal.setPaymentMethod(hu.puzzleir.valuta.entity.PaymentMethod.CARD);
            transactionRepository.save(reversal);

            log.info("OTP teljes áruvisszavét végrehajtva: eredeti={}, sztornó={}, összeg={}",
                    original.getReceiptNumber(), reversal.getReceiptNumber(),
                    refundAmount != null ? refundAmount.toPlainString() : "teljes");

            return reversal;
        }
    }

    /**
     * Supervisor jóváhagyás szükséges-e OTP sztornóhoz.
     * Legacy: NAPISTORNO > 2 → supervisor jelszó kell
     */
    @Transactional(readOnly = true)
    public boolean requiresOtpSupervisor(UUID branchId) {
        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(SecurityUtils.getCurrentCompanyId(), branchId, LocalDate.now());
        return dailyCount >= DAILY_STORNO_LIMIT_BRANCH;
    }

    // ============ HELPER ============

    private StornoApprovalDto toApprovalDto(StornoApproval entity) {
        return StornoApprovalDto.builder()
                .id(entity.getId().toString())
                .transactionId(String.valueOf(entity.getTransaction().getId()))
                .workerId(String.valueOf(entity.getWorker().getId()))
                .branchId(entity.getBranch().getId().toString())
                .dailyStornoCount(entity.getDailyStornoCount())
                .approvalStatusDid(entity.getApprovalStatus() != null ? entity.getApprovalStatus().getId().toString() : null)
                .requestReason(entity.getRequestReason())
                .rejectionReason(entity.getRejectionReason())
                .approvedByWorkerId(entity.getApprovedByWorker() != null ? String.valueOf(entity.getApprovedByWorker().getId()) : null)
                .approvedAt(entity.getApprovedAt())
                .build();
    }
}
