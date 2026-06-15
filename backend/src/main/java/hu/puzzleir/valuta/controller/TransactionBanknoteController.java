package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transaction.TransactionBanknoteDto;
import hu.puzzleir.valuta.entity.TransactionBanknote;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.TransactionBanknoteRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Tranzakciós bankjegy-részletezés controller.
 * Címletszintű input/output bontás egy tranzakcióhoz.
 */
@RestController
@RequestMapping("/api/v1/transactions/{transactionId}/banknotes")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class TransactionBanknoteController {

    private final TransactionBanknoteRepository repository;
    private final TransactionRepository transactionRepository;

    /**
     * Multi-tenant IDOR guard: a path-param {@code transactionId} (Long → enumerálható)
     * a hívó cégéhez tartozik-e. A TransactionBanknote csak transactionId-t hordoz; a
     * tenant-izoláció a Transaction-on (company) él. Más cég VAGY nem létező tranzakció →
     * ResourceNotFoundException (a létezés se szivárogjon). Minden bankjegy-olvasás/-írás
     * előtt kötelező.
     */
    private void requireOwnTransaction(Long transactionId) {
        if (transactionId == null
                || transactionRepository.findByIdAndCompanyId(transactionId, SecurityUtils.getCurrentCompanyId()).isEmpty()) {
            throw new ResourceNotFoundException("Tranzakció nem található: " + transactionId);
        }
    }

    /**
     * Tranzakció bankjegyeinek listázása.
     */
    @GetMapping
    public ResponseEntity<List<TransactionBanknoteDto>> findByTransaction(
            @PathVariable Long transactionId,
            @RequestParam(required = false) String direction) {
        requireOwnTransaction(transactionId);
        List<TransactionBanknote> banknotes;
        if (direction != null) {
            banknotes = repository.findByTransactionIdAndDirection(transactionId, direction);
        } else {
            banknotes = repository.findByTransactionId(transactionId);
        }
        return ResponseEntity.ok(banknotes.stream().map(this::toDto).collect(Collectors.toList()));
    }

    /**
     * Bankjegy-részletezés rögzítése.
     */
    @PostMapping
    public ResponseEntity<TransactionBanknoteDto> create(
            @PathVariable Long transactionId,
            @Valid @RequestBody TransactionBanknoteDto dto) {
        requireOwnTransaction(transactionId);
        TransactionBanknote entity = TransactionBanknote.builder()
                .transactionId(transactionId)
                .transactionLineId(dto.getTransactionLineId())
                .currencyCode(dto.getCurrencyCode())
                .faceValue(dto.getFaceValue())
                .quantity(dto.getQuantity())
                .direction(dto.getDirection())
                .totalValue(dto.getFaceValue().multiply(java.math.BigDecimal.valueOf(dto.getQuantity())))
                .build();
        TransactionBanknote saved = repository.save(entity);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    private TransactionBanknoteDto toDto(TransactionBanknote entity) {
        return TransactionBanknoteDto.builder()
                .id(entity.getId())
                .transactionId(entity.getTransactionId())
                .transactionLineId(entity.getTransactionLineId())
                .currencyCode(entity.getCurrencyCode())
                .faceValue(entity.getFaceValue())
                .quantity(entity.getQuantity())
                .direction(entity.getDirection())
                .totalValue(entity.getTotalValue())
                .build();
    }
}
