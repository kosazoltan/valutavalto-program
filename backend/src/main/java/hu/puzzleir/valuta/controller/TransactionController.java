package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transaction.*;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TransactionService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import hu.puzzleir.valuta.util.OptimisticLockRetry;
import jakarta.servlet.http.HttpServletRequest;
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
import org.springframework.util.StringUtils;

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
    private final IdempotencyGuard idempotencyGuard;

    // Sourcery PR #358 follow-up: endpoint string konstansok — DRY, no string drift
    // ha az URL-t valaha modositjuk.
    private static final String ENDPOINT_BUY = "POST /api/v1/transactions/buy";
    private static final String ENDPOINT_SELL = "POST /api/v1/transactions/sell";
    private static final String ENDPOINT_REVERSAL = "POST /api/v1/transactions/reversal";
    private static final String ENDPOINT_CONVERSION = "POST /api/v1/transactions/conversion";

    /**
     * Vétel (ügyfél valutát ad el, cég HUF-ot fizet)
     *
     * POST /api/v1/transactions/buy
     */
    @PostMapping("/buy")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeBuy(
            @Valid @RequestBody BuyRequestDto dto,
            HttpServletRequest request) {
        String idempotencyKey = resolveIdempotencyKey(request);
        IdempotencyGuard.Acquired<TransactionDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, ENDPOINT_BUY, dto, TransactionDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }
        try {
            Transaction transaction = OptimisticLockRetry.execute(
                    () -> transactionService.executeBuy(transactionMapper.toBuyRequest(dto)),
                    "executeBuy");
            TransactionDto result = transactionMapper.toDto(transaction);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    /**
     * Eladás (ügyfél HUF-ot ad, cég valutát ad)
     *
     * POST /api/v1/transactions/sell
     */
    @PostMapping("/sell")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeSell(
            @Valid @RequestBody SellRequestDto dto,
            HttpServletRequest request) {
        String idempotencyKey = resolveIdempotencyKey(request);
        IdempotencyGuard.Acquired<TransactionDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, ENDPOINT_SELL, dto, TransactionDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }
        try {
            Transaction transaction = OptimisticLockRetry.execute(
                    () -> transactionService.executeSell(transactionMapper.toSellRequest(dto)),
                    "executeSell");
            TransactionDto result = transactionMapper.toDto(transaction);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    /**
     * Sztornó
     *
     * POST /api/v1/transactions/reversal
     */
    @PostMapping("/reversal")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeReversal(
            @Valid @RequestBody ReversalRequestDto dto,
            HttpServletRequest request) {
        String idempotencyKey = resolveIdempotencyKey(request);
        IdempotencyGuard.Acquired<TransactionDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, ENDPOINT_REVERSAL, dto, TransactionDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }
        try {
            Transaction transaction = OptimisticLockRetry.execute(
                    () -> transactionService.executeReversal(transactionMapper.toReversalRequest(dto)),
                    "executeReversal");
            TransactionDto result = transactionMapper.toDto(transaction);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    /**
     * Konverzió (valuta-valuta csere)
     *
     * POST /api/v1/transactions/conversion
     */
    @PostMapping("/conversion")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeConversion(
            @Valid @RequestBody ConversionRequestDto dto,
            HttpServletRequest request) {
        String idempotencyKey = resolveIdempotencyKey(request);
        IdempotencyGuard.Acquired<TransactionDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, ENDPOINT_CONVERSION, dto, TransactionDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }
        try {
            Transaction transaction = OptimisticLockRetry.execute(
                    () -> transactionService.executeConversion(transactionMapper.toConversionRequest(dto)),
                    "executeConversion");
            TransactionDto result = transactionMapper.toDto(transaction);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    /**
     * Tranzakció keresése bizonylat szám alapján
     *
     * GET /api/v1/transactions/receipt/{receiptNumber}
     */
    @GetMapping("/receipt/{receiptNumber}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
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
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
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
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Page<TransactionDto>> searchTransactions(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) TransactionType type,
            Pageable pageable) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
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
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionService.DailyTurnoverSummary> getDailyTurnover(
            @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE) java.time.LocalDate date) {
        TransactionService.DailyTurnoverSummary summary = (date != null)
                ? transactionService.getDailyTurnoverForDate(date)
                : transactionService.getDailyTurnover();
        return ResponseEntity.ok(summary);
    }

    private String resolveIdempotencyKey(HttpServletRequest request) {
        String key = request.getHeader("Idempotency-Key");
        if (StringUtils.hasText(key)) {
            return key;
        }
        return request.getHeader("X-Idempotency-Key");
    }
}
