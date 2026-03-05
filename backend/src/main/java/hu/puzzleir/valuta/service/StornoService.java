package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.storno.StornoApprovalDto;
import hu.puzzleir.valuta.dto.storno.StornoCheckResultDto;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import hu.puzzleir.valuta.entity.StornoApproval;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.StornoApprovalRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Sztornó szolgáltatás.
 * Sztornó ellenőrzés, jóváhagyás kérés, jóváhagyás, végrehajtás.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class StornoService {

    private final TransactionRepository transactionRepository;
    private final StornoApprovalRepository stornoApprovalRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final TransactionService transactionService;

    // Napi sztornó limit supervisor jóváhagyás nélkül
    private static final int DAILY_STORNO_LIMIT = 3;

    /**
     * Sztornó ellenőrzés - szükséges-e jóváhagyás?
     */
    @Transactional(readOnly = true)
    public StornoCheckResultDto checkStorno(Long transactionId, Long workerId) {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        UUID branchId = SecurityUtils.getCurrentBranchId();
        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(branchId, LocalDate.now());

        boolean requiresApproval = dailyCount >= DAILY_STORNO_LIMIT
                || !transaction.getTransactionDate().equals(LocalDate.now());

        String message;
        if (transaction.isReversed()) {
            message = "Ez a tranzakció már sztornózva lett!";
        } else if (transaction.isReversal()) {
            message = "Sztornó tranzakció nem sztornózható!";
        } else if (requiresApproval) {
            message = String.format("Napi sztornó szám (%d) elérte a limitet vagy korábbi napi tranzakció. Supervisor jóváhagyás szükséges.", dailyCount);
        } else {
            message = "Sztornó végrehajtható.";
        }

        return StornoCheckResultDto.builder()
                .requiresApproval(requiresApproval)
                .dailyStornoCount(dailyCount)
                .transactionId(String.valueOf(transactionId))
                .transactionNumber(transaction.getReceiptNumber())
                .message(message)
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
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        int dailyCount = (int) transactionRepository.countReversalsByBranchAndDate(branchId, LocalDate.now());

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

        Worker approver = workerRepository.findById(approvedByWorkerId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyó pénztáros nem található: " + approvedByWorkerId));

        approval.setApprovedByWorker(approver);
        approval.setApprovedAt(LocalDateTime.now());

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

        TransactionService.ReversalRequest reversalRequest = TransactionService.ReversalRequest.builder()
                .originalTransactionId(transactionId)
                .reason(reason)
                .approvedBy(String.valueOf(workerId))
                .build();

        Transaction reversal = transactionService.executeReversal(reversalRequest);
        log.info("POS sztornó végrehajtva: eredeti={}, sztornó={}", posTransactionId, reversal.getReceiptNumber());

        return reversal;
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
