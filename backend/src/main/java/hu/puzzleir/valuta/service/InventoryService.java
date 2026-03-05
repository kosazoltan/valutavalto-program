package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.inventory.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Készlet mozgás kezelő service.
 *
 * Legacy: keszup.dll (bank↔pénztár), atadvet.dll (irodák közti),
 * keszedit.dll (korrekció), penztarak.dll (összesítő nézet)
 */
@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryMovementRepository movementRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final AuditLogRepository auditLogRepository;

    private static final DateTimeFormatter REF_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    // ============ BANK OPERATIONS ============

    /**
     * Bank → pénztár valuta kivét kérés (PENDING státusz).
     */
    @Transactional
    public InventoryMovementDto requestBankWithdraw(BankWithdrawRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(null) // bank = null
                .toBranch(branch)
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(BigDecimal.ZERO)
                .movementType(MovementType.BANK_WITHDRAW)
                .status(MovementStatus.PENDING)
                .initiatedBy(worker)
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    /**
     * Pénztár → bank befizetés (APPROVED azonnal).
     */
    @Transactional
    public InventoryMovementDto depositToBank(BankDepositRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        // Ellenőrzés: van-e elegendő készlet
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));

        if (balance.getCurrentBalance().compareTo(dto.getAmount()) < 0) {
            throw new ValidationException("Nincs elegendő készlet! Egyenleg: "
                    + balance.getCurrentBalance().setScale(4, RoundingMode.HALF_UP)
                    + ", kért: " + dto.getAmount());
        }

        // Készlet csökkentés
        balance.subtractBalance(dto.getAmount());
        cashBalanceRepository.save(balance);

        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(branch)
                .toBranch(null) // bank = null
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(BigDecimal.ZERO)
                .movementType(MovementType.BANK_DEPOSIT)
                .status(MovementStatus.APPROVED)
                .initiatedBy(worker)
                .approvedBy(worker)
                .approvedAt(LocalDateTime.now())
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ BRANCH TRANSFER ============

    /**
     * Irodák közti szállítás (PENDING státusz).
     */
    @Transactional
    public InventoryMovementDto transferBetweenBranches(BranchTransferRequestDto dto, Long workerId) {
        Branch fromBranch = findBranch(dto.getFromBranchId());
        Branch toBranch = findBranch(dto.getToBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        if (fromBranch.getId().equals(toBranch.getId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet azonos!");
        }

        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(BigDecimal.ZERO)
                .movementType(MovementType.BRANCH_TRANSFER)
                .status(MovementStatus.PENDING)
                .initiatedBy(worker)
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ STATUS TRANSITIONS ============

    /**
     * Mozgás jóváhagyása (PENDING → APPROVED).
     */
    @Transactional
    public InventoryMovementDto approveMovement(Long movementId, Long workerId) {
        InventoryMovement movement = findMovement(movementId);
        Worker worker = findWorker(workerId);

        if (movement.getStatus() != MovementStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő mozgás hagyható jóvá! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }

        movement.setStatus(MovementStatus.APPROVED);
        movement.setApprovedBy(worker);
        movement.setApprovedAt(LocalDateTime.now());

        // Bank kivét jóváhagyáskor automatikusan IN_TRANSIT
        if (movement.getMovementType() == MovementType.BANK_WITHDRAW
                || movement.getMovementType() == MovementType.BRANCH_TRANSFER) {
            movement.setStatus(MovementStatus.IN_TRANSIT);
        }

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    /**
     * Mozgás fogadása (IN_TRANSIT → RECEIVED) — CashBalance frissítéssel!
     */
    @Transactional
    public InventoryMovementDto receiveMovement(Long movementId, Long workerId, ReceiveMovementDto dto) {
        InventoryMovement movement = findMovement(movementId);
        Worker worker = findWorker(workerId);

        if (movement.getStatus() != MovementStatus.IN_TRANSIT
                && movement.getStatus() != MovementStatus.APPROVED) {
            throw new ValidationException("Csak szállítás alatt lévő vagy jóváhagyott mozgás fogadható! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }

        movement.setStatus(MovementStatus.RECEIVED);
        movement.setReceivedBy(worker);
        movement.setReceivedAt(LocalDateTime.now());

        BigDecimal receivedAmount = dto.getReceivedAmount();

        // CashBalance frissítés a mozgás típusa alapján
        switch (movement.getMovementType()) {
            case BANK_WITHDRAW -> {
                // Bank → pénztár: cél iroda készlet növelése
                updateCashBalance(movement.getToBranch().getId(),
                        movement.getCurrency().getId(), receivedAmount, true);
            }
            case BRANCH_TRANSFER -> {
                // Irodák közti: forrás csökkentés, cél növelés
                updateCashBalance(movement.getFromBranch().getId(),
                        movement.getCurrency().getId(), movement.getAmount(), false);
                updateCashBalance(movement.getToBranch().getId(),
                        movement.getCurrency().getId(), receivedAmount, true);
            }
            default -> {
                // BANK_DEPOSIT, CORRECTION, INITIAL_STOCK — nem ide tartozik
            }
        }

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    /**
     * Mozgás visszavonása (PENDING → CANCELLED).
     */
    @Transactional
    public void cancelMovement(Long movementId) {
        InventoryMovement movement = findMovement(movementId);
        if (movement.getStatus() != MovementStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő mozgás vonható vissza! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }
        movement.setStatus(MovementStatus.CANCELLED);
        movementRepository.save(movement);
    }

    // ============ CORRECTION ============

    /**
     * Manuális készlet korrekció — CashBalance update + AuditLog bejegyzés.
     */
    @Transactional
    public InventoryMovementDto correctInventory(CorrectionRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));

        BigDecimal oldAmount = balance.getCurrentBalance();
        BigDecimal correctionDiff = dto.getNewAmount().subtract(oldAmount)
                .setScale(4, RoundingMode.HALF_UP);

        // CashBalance frissítés
        balance.setCurrentBalance(dto.getNewAmount().setScale(4, RoundingMode.HALF_UP));
        balance.setLastTransactionAt(LocalDateTime.now());
        cashBalanceRepository.save(balance);

        // AuditLog bejegyzés — KÖTELEZŐ
        AuditLog auditLog = AuditLog.builder()
                .action("INVENTORY_CORRECTION")
                .entityType("CashBalance")
                .entityId(balance.getId().toString())
                .userId(worker.getId().toString())
                .userName(worker.getName())
                .branchId(branch.getId().toString())
                .branchName(branch.getName())
                .changes("Valuta: " + currency.getCode()
                        + ", Régi érték: " + oldAmount.setScale(4, RoundingMode.HALF_UP)
                        + ", Új érték: " + dto.getNewAmount().setScale(4, RoundingMode.HALF_UP)
                        + ", Különbség: " + correctionDiff
                        + ", Ok: " + dto.getReason())
                .build();
        auditLogRepository.save(auditLog);

        // InventoryMovement rekord
        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(branch)
                .toBranch(branch)
                .currency(currency)
                .amount(correctionDiff.abs())
                .hufValue(BigDecimal.ZERO)
                .movementType(MovementType.CORRECTION)
                .status(MovementStatus.RECEIVED) // korrekció azonnal RECEIVED
                .initiatedBy(worker)
                .approvedBy(worker)
                .receivedBy(worker)
                .approvedAt(LocalDateTime.now())
                .receivedAt(LocalDateTime.now())
                .referenceNumber(generateReferenceNumber())
                .notes("Korrekció: " + dto.getReason()
                        + " | Régi: " + oldAmount.setScale(4, RoundingMode.HALF_UP)
                        + " → Új: " + dto.getNewAmount().setScale(4, RoundingMode.HALF_UP))
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ QUERIES ============

    /**
     * Egy iroda készlete (CashBalance lista).
     */
    public List<CashBalance> getCurrentStock(UUID branchId) {
        return cashBalanceRepository.findByBranchId(branchId);
    }

    /**
     * Összes iroda × összes valuta mátrix.
     */
    public StockMatrixDto getStockMatrix() {
        List<CashBalance> allBalances = cashBalanceRepository.findAll();
        Map<String, Map<String, BigDecimal>> matrix = new LinkedHashMap<>();

        for (CashBalance cb : allBalances) {
            String branchId = cb.getBranch().getId().toString();
            String currencyCode = cb.getCurrency().getCode();
            matrix.computeIfAbsent(branchId, k -> new LinkedHashMap<>())
                    .put(currencyCode, cb.getCurrentBalance()
                            .setScale(4, RoundingMode.HALF_UP));
        }

        return StockMatrixDto.builder().matrix(matrix).build();
    }

    /**
     * Mozgás részletei.
     */
    public InventoryMovementDto getMovement(Long id) {
        return toDto(findMovement(id));
    }

    /**
     * Mozgás történet (paginated, filtered).
     */
    public Page<InventoryMovementDto> searchMovements(UUID branchId, LocalDate startDate,
            LocalDate endDate, MovementStatus status, MovementType type, Pageable pageable) {
        return movementRepository.search(branchId, startDate, endDate, status, type, pageable)
                .map(this::toDto);
    }

    // ============ HELPERS ============

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseThrow(() -> new ValidationException(
                        "Kassza egyenleg nem található: branchId=" + branchId + ", currencyId=" + currencyId));
        balance.updateBalance(amount.setScale(4, RoundingMode.HALF_UP), isIncoming);
        cashBalanceRepository.save(balance);
    }

    private String generateReferenceNumber() {
        String prefix = "INV-" + LocalDate.now().format(REF_DATE_FORMAT) + "-";
        long max = movementRepository.findMaxReferenceNumber(prefix);
        return prefix + String.format("%04d", max + 1);
    }

    private Branch findBranch(String branchId) {
        return branchRepository.findById(UUID.fromString(branchId))
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private Currency findCurrency(Long currencyId) {
        return currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyId));
    }

    private Worker findWorker(Long workerId) {
        return workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));
    }

    private InventoryMovement findMovement(Long id) {
        return movementRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Készlet mozgás nem található: " + id));
    }

    private InventoryMovementDto toDto(InventoryMovement m) {
        return InventoryMovementDto.builder()
                .id(m.getId())
                .fromBranchId(m.getFromBranch() != null ? m.getFromBranch().getId().toString() : null)
                .fromBranchName(m.getFromBranch() != null ? m.getFromBranch().getName() : "Bank")
                .toBranchId(m.getToBranch() != null ? m.getToBranch().getId().toString() : null)
                .toBranchName(m.getToBranch() != null ? m.getToBranch().getName() : "Bank")
                .currencyId(m.getCurrency().getId())
                .currencyCode(m.getCurrency().getCode())
                .currencyName(m.getCurrency().getName())
                .amount(m.getAmount())
                .hufValue(m.getHufValue())
                .movementType(m.getMovementType().name())
                .movementTypeDisplay(m.getMovementType().getDisplayName())
                .status(m.getStatus().name())
                .statusDisplay(m.getStatus().getDisplayName())
                .initiatedById(m.getInitiatedBy().getId())
                .initiatedByName(m.getInitiatedBy().getName())
                .approvedById(m.getApprovedBy() != null ? m.getApprovedBy().getId() : null)
                .approvedByName(m.getApprovedBy() != null ? m.getApprovedBy().getName() : null)
                .receivedById(m.getReceivedBy() != null ? m.getReceivedBy().getId() : null)
                .receivedByName(m.getReceivedBy() != null ? m.getReceivedBy().getName() : null)
                .referenceNumber(m.getReferenceNumber())
                .notes(m.getNotes())
                .movementDate(m.getMovementDate().toString())
                .movementTime(m.getMovementTime().toString())
                .approvedAt(m.getApprovedAt() != null ? m.getApprovedAt().toString() : null)
                .receivedAt(m.getReceivedAt() != null ? m.getReceivedAt().toString() : null)
                .createdAt(m.getCreatedAt() != null ? m.getCreatedAt().toString() : null)
                .build();
    }
}
