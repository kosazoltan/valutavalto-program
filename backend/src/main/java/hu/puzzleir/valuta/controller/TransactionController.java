package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transaction.*;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Tranzakció controller - vétel/eladás/sztornó/konverzió
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL, STORNO.DLL
 */
@RestController
@RequestMapping("/api/v1/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final TransactionMapper transactionMapper;

    /**
     * Vétel (ügyfél valutát ad el, cég HUF-ot fizet)
     *
     * POST /api/v1/transactions/buy
     */
    @PostMapping("/buy")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeBuy(@Valid @RequestBody BuyRequestDto dto) {
        Transaction transaction = transactionService.executeBuy(transactionMapper.toBuyRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionMapper.toDto(transaction));
    }

    /**
     * Eladás (ügyfél HUF-ot ad, cég valutát ad)
     *
     * POST /api/v1/transactions/sell
     */
    @PostMapping("/sell")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeSell(@Valid @RequestBody SellRequestDto dto) {
        Transaction transaction = transactionService.executeSell(transactionMapper.toSellRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionMapper.toDto(transaction));
    }

    /**
     * Sztornó
     *
     * POST /api/v1/transactions/reversal
     */
    @PostMapping("/reversal")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeReversal(@Valid @RequestBody ReversalRequestDto dto) {
        Transaction transaction = transactionService.executeReversal(transactionMapper.toReversalRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionMapper.toDto(transaction));
    }

    /**
     * Konverzió (valuta-valuta csere)
     *
     * POST /api/v1/transactions/conversion
     */
    @PostMapping("/conversion")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeConversion(@Valid @RequestBody ConversionRequestDto dto) {
        Transaction transaction = transactionService.executeConversion(transactionMapper.toConversionRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionMapper.toDto(transaction));
    }

    /**
     * Tranzakció keresése bizonylat szám alapján
     *
     * GET /api/v1/transactions/receipt/{receiptNumber}
     */
    @GetMapping("/receipt/{receiptNumber}")
    public ResponseEntity<TransactionDto> findByReceiptNumber(@PathVariable String receiptNumber) {
        Transaction transaction = transactionService.findByReceiptNumber(receiptNumber);
        return ResponseEntity.ok(transactionMapper.toDto(transaction));
    }

    /**
     * Napi tranzakciók
     *
     * GET /api/v1/transactions/daily
     */
    @GetMapping("/daily")
    public ResponseEntity<List<TransactionDto>> getDailyTransactions() {
        List<Transaction> transactions = transactionService.getDailyTransactions();
        List<TransactionDto> dtos = transactions.stream()
                .map(transactionMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Tranzakciók szűrése (pageable)
     *
     * GET /api/v1/transactions?branchId=...&startDate=...&endDate=...&type=...
     */
    @GetMapping
    public ResponseEntity<Page<TransactionDto>> searchTransactions(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) TransactionType type,
            Pageable pageable) {
        Page<Transaction> page = transactionService.searchTransactions(branchId, startDate, endDate, type, pageable);
        Page<TransactionDto> dtoPage = page.map(transactionMapper::toDto);
        return ResponseEntity.ok(dtoPage);
    }

    /**
     * Napi forgalom összesítés
     *
     * GET /api/v1/transactions/daily-turnover
     */
    @GetMapping("/daily-turnover")
    public ResponseEntity<TransactionService.DailyTurnoverSummary> getDailyTurnover() {
        TransactionService.DailyTurnoverSummary summary = transactionService.getDailyTurnover();
        return ResponseEntity.ok(summary);
    }
}
