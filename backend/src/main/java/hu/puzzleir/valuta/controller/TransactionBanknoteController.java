package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transaction.TransactionBanknoteDto;
import hu.puzzleir.valuta.entity.TransactionBanknote;
import hu.puzzleir.valuta.repository.TransactionBanknoteRepository;
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

    /**
     * Tranzakció bankjegyeinek listázása.
     */
    @GetMapping
    public ResponseEntity<List<TransactionBanknoteDto>> findByTransaction(
            @PathVariable Long transactionId,
            @RequestParam(required = false) String direction) {
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
            @RequestBody TransactionBanknoteDto dto) {
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
