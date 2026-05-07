package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.bankorder.BankOrderDto;
import hu.puzzleir.valuta.dto.bankorder.CreateBankOrderRequest;
import hu.puzzleir.valuta.entity.BankOrder;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BankOrderRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * E-B8 Banki rendelés workflow service (issue #279).
 *
 * <p>State machine:</p>
 * <pre>
 * PENDING ──approve──→ APPROVED ──execute──→ EXECUTED
 *    │                    │
 *    └─────cancel─────────┴────cancel──────→ CANCELLED
 * </pre>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BankOrderService {

    private final BankOrderRepository bankOrderRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final NotificationService notificationService;

    @Transactional
    public BankOrderDto create(CreateBankOrderRequest req) {
        Worker currentWorker = currentWorker();
        Branch branch = branchRepository.findById(req.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Branch nem található: " + req.getBranchId()));
        Currency currency = currencyRepository.findById(req.getCurrencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + req.getCurrencyId()));

        BankOrder order = BankOrder.builder()
                .branch(branch)
                .currency(currency)
                .amount(req.getAmount())
                .urgency(req.getUrgency() != null ? req.getUrgency() : BankOrder.Urgency.NORMAL)
                .status(BankOrder.Status.PENDING)
                .requestedBy(currentWorker)
                .requestedAt(LocalDateTime.now())
                .notes(req.getNotes())
                .build();

        BankOrder saved = bankOrderRepository.save(order);
        log.info("[bank-order] CREATE id={} branch={} amount={} {} urgency={} requestedBy={}",
                saved.getId(), auditLogValue(branch.getCode()), saved.getAmount(), auditLogValue(currency.getCode()),
                saved.getUrgency(), auditLogValue(currentWorker.getCode()));
        if (saved.getUrgency() == BankOrder.Urgency.EMERGENCY) {
            notifyEmergencyOrder(saved);
        }
        return BankOrderDto.from(saved);
    }

    @Transactional
    public BankOrderDto approve(UUID id) {
        BankOrder order = findOrThrow(id);
        if (order.getStatus() != BankOrder.Status.PENDING) {
            throw new ValidationException("Csak PENDING állapotú rendelés hagyható jóvá. Aktuális: " + order.getStatus());
        }
        Worker approver = currentWorker();
        order.setStatus(BankOrder.Status.APPROVED);
        order.setApprovedBy(approver);
        order.setApprovedAt(LocalDateTime.now());
        BankOrder saved = bankOrderRepository.save(order);
        log.info("[bank-order] APPROVE id={} by={}", saved.getId(), auditLogValue(approver.getCode()));
        return BankOrderDto.from(saved);
    }

    @Transactional
    public BankOrderDto execute(UUID id, String bankReference) {
        BankOrder order = findOrThrow(id);
        if (order.getStatus() != BankOrder.Status.APPROVED) {
            throw new ValidationException("Csak APPROVED állapotú rendelés futtatható. Aktuális: " + order.getStatus());
        }
        Worker executor = currentWorker();
        order.setStatus(BankOrder.Status.EXECUTED);
        order.setExecutedBy(executor);
        order.setExecutedAt(LocalDateTime.now());
        if (bankReference != null && !bankReference.isBlank()) {
            order.setBankReference(bankReference.trim());
        }
        BankOrder saved = bankOrderRepository.save(order);
        log.info("[bank-order] EXECUTE id={} by={} bankRef={}", saved.getId(), auditLogValue(executor.getCode()), auditLogValue(bankReference));
        return BankOrderDto.from(saved);
    }

    @Transactional
    public BankOrderDto cancel(UUID id, String reason) {
        BankOrder order = findOrThrow(id);
        if (order.getStatus() == BankOrder.Status.EXECUTED || order.getStatus() == BankOrder.Status.CANCELLED) {
            throw new ValidationException("EXECUTED / CANCELLED rendelés nem törölhető.");
        }
        Worker canceller = currentWorker();
        order.setStatus(BankOrder.Status.CANCELLED);
        order.setCancelledBy(canceller);
        order.setCancelledAt(LocalDateTime.now());
        order.setCancellationReason(reason);
        BankOrder saved = bankOrderRepository.save(order);
        log.info("[bank-order] CANCEL id={} by={} reason={}", saved.getId(), auditLogValue(canceller.getCode()), auditLogValue(reason));
        return BankOrderDto.from(saved);
    }

    @Transactional(readOnly = true)
    public Page<BankOrderDto> list(BankOrder.Status status, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), 200);
        Page<BankOrder> result = (status == null)
                ? bankOrderRepository.findAll(PageRequest.of(page, safeSize))
                : bankOrderRepository.findByStatusOrderByRequestedAtDesc(status, PageRequest.of(page, safeSize));
        return result.map(BankOrderDto::from);
    }

    @Transactional(readOnly = true)
    public BankOrderDto get(UUID id) {
        return BankOrderDto.from(findOrThrow(id));
    }

    private BankOrder findOrThrow(UUID id) {
        return bankOrderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bank order nem található: " + id));
    }

    private Worker currentWorker() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) {
            throw new ValidationException("Nincs bejelentkezett munkavállaló");
        }
        return workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));
    }

    private void notifyEmergencyOrder(BankOrder order) {
        UUID companyId = order.getBranch().getCompany().getId();
        String title = "Sürgős banki rendelés jóváhagyásra vár";
        String message = String.format("%s iroda: %s %s banki rendelés azonnali jóváhagyást kér.",
                order.getBranch().getCode(),
                order.getAmount().toPlainString(),
                order.getCurrency().getCode());
        for (Worker supervisor : workerRepository.findSupervisorsAndAbove(companyId)) {
            notificationService.sendToWorker(supervisor.getId(), title, message, "URGENT");
        }
    }

    private static String auditLogValue(String value) {
        if (value == null) {
            return "";
        }
        return value.replace('\r', ' ').replace('\n', ' ');
    }
}
