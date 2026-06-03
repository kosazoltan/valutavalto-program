package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.inventory.InventoryBalanceDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.InventoryMovement;
import hu.puzzleir.valuta.entity.MovementType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Készlet mozgás napló service.
 * Minden mozgást naplóz a balance before/after értékekkel.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryMovementService {

    private final InventoryMovementRepository movementRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final BranchRepository branchRepository;

    /**
     * Multi-tenant izoláció (audit/Codex P1 #934): a branchId-vel paraméterezett lekérdezések
     * KÖTELEZŐEN a hívó cégének irodájára szólnak. Tenant-idegen iroda → 404 (id-enumeráció ellen).
     * Enélkül a getDailyBalance a cashBalanceRepository.findByBranchId-n át idegen cég egyenlegét
     * szivárogtatta volna (a mozgás-query scope-olása nem fedte a cash-balance lookupot).
     */
    private UUID requireOwnBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId == null || !branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        return companyId;
    }

    /**
     * Mozgások listázása branchId + currency + date alapján
     */
    @Transactional(readOnly = true)
    public List<InventoryMovementDto> getMovements(UUID branchId, String currency, LocalDate date) {
        // Multi-tenant izoláció (audit 2026-05-31, P1 IDOR): a kért iroda a hívó cégéé kell legyen,
        // és a mozgás-query is a cégre szűr.
        UUID companyId = requireOwnBranch(branchId);
        return movementRepository.search(companyId, branchId, date, date, null, null,
                        org.springframework.data.domain.Pageable.unpaged())
                .stream()
                .filter(m -> currency == null || currency.isEmpty()
                        || m.getCurrency().getCode().equalsIgnoreCase(currency))
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Napi egyenleg számítása egy irodára és valutára
     */
    @Transactional(readOnly = true)
    public InventoryBalanceDto getDailyBalance(UUID branchId, String currency, LocalDate date) {
        // A branchId tulajdonosát is validáljuk (Codex P1 #934): a cashBalanceRepository.findByBranchId
        // lookup különben idegen cég záró/nyitó egyenlegét adta volna vissza.
        UUID companyId = requireOwnBranch(branchId);
        List<InventoryMovement> movements = movementRepository.search(
                        companyId, branchId, date, date, null, null,
                        org.springframework.data.domain.Pageable.unpaged())
                .stream()
                .filter(m -> currency == null || m.getCurrency().getCode().equalsIgnoreCase(currency))
                .toList();

        BigDecimal totalIn = BigDecimal.ZERO;
        BigDecimal totalOut = BigDecimal.ZERO;

        for (InventoryMovement m : movements) {
            boolean isIncoming = (m.getToBranch() != null && m.getToBranch().getId().equals(branchId));
            boolean isOutgoing = (m.getFromBranch() != null && m.getFromBranch().getId().equals(branchId));

            if (isIncoming) {
                totalIn = totalIn.add(m.getAmount());
            }
            if (isOutgoing) {
                totalOut = totalOut.add(m.getAmount());
            }
        }

        // Aktuális egyenleg a CashBalance-ből
        BigDecimal currentBalance = BigDecimal.ZERO;
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        for (CashBalance cb : balances) {
            if (currency == null || cb.getCurrency().getCode().equalsIgnoreCase(currency)) {
                currentBalance = currentBalance.add(cb.getCurrentBalance());
            }
        }

        return InventoryBalanceDto.builder()
                .branchId(branchId)
                .currencyCode(currency)
                .openingBalance(currentBalance.subtract(totalIn).add(totalOut)
                        .setScale(4, RoundingMode.HALF_UP))
                .closingBalance(currentBalance.setScale(4, RoundingMode.HALF_UP))
                .totalIn(totalIn.setScale(4, RoundingMode.HALF_UP))
                .totalOut(totalOut.setScale(4, RoundingMode.HALF_UP))
                .date(date.toString())
                .build();
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
                .receivedAmount(m.getReceivedAmount())
                .difference(m.getDifference())
                .build();
    }
}
