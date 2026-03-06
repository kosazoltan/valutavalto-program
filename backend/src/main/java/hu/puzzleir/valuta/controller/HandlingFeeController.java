package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.ApplyDiscountDto;
import hu.puzzleir.valuta.dto.handlingfee.CalculateFeeDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeReportDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeTransactionDto;
import hu.puzzleir.valuta.service.HandlingFeeTransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Kezelési díj REST végpontok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/handling-fees")
@RequiredArgsConstructor
public class HandlingFeeController {

    private final HandlingFeeTransactionService handlingFeeTransactionService;

    @PostMapping("/calculate")
    public ResponseEntity<HandlingFeeTransactionDto> calculate(@Valid @RequestBody CalculateFeeDto dto) {
        return ResponseEntity.ok(
            handlingFeeTransactionService.calculateFee(dto.getTransactionId(), dto.getHufAmount()));
    }

    @PostMapping("/{id}/discount")
    public ResponseEntity<HandlingFeeTransactionDto> applyDiscount(
            @PathVariable UUID id,
            @Valid @RequestBody ApplyDiscountDto dto) {
        return ResponseEntity.ok(
            handlingFeeTransactionService.applyDiscount(id, dto.getDiscountPercent(), dto.getReason()));
    }

    @GetMapping("/report")
    public ResponseEntity<HandlingFeeReportDto> report(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(handlingFeeTransactionService.getFeeReport(branchId, from, to));
    }
}
