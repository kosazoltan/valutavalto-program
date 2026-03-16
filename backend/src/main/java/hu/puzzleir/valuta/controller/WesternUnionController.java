package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.wu.WuBalanceDto;
import hu.puzzleir.valuta.dto.wu.WuDailyReportDto;
import hu.puzzleir.valuta.dto.wu.WuTransactionDto;
import hu.puzzleir.valuta.entity.WuBalance;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.service.WesternUnionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Western Union controller — WU forgalom végpontjai.
 *
 * Legacy: WU modul DLL.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/western-union")
@RequiredArgsConstructor
public class WesternUnionController {

    private final WesternUnionService westernUnionService;

    /**
     * WU küldés rögzítése.
     * POST /api/v1/western-union/send
     */
    @PostMapping("/send")
    public ResponseEntity<WuTransactionDto> recordSend(
            @Valid @RequestBody WuTransactionDto request) {
        WuTransaction tx = westernUnionService.recordSend(request);
        return ResponseEntity.ok(toDto(tx));
    }

    /**
     * WU fogadás rögzítése.
     * POST /api/v1/western-union/receive
     */
    @PostMapping("/receive")
    public ResponseEntity<WuTransactionDto> recordReceive(
            @Valid @RequestBody WuTransactionDto request) {
        WuTransaction tx = westernUnionService.recordReceive(request);
        return ResponseEntity.ok(toDto(tx));
    }

    /**
     * WU tranzakciók lekérdezése.
     * GET /api/v1/western-union/transactions
     */
    @GetMapping("/transactions")
    public ResponseEntity<Page<WuTransactionDto>> getTransactions(
            @RequestParam UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<WuTransaction> result = westernUnionService.getTransactions(branchId, from, to, PageRequest.of(page, size));
        return ResponseEntity.ok(result.map(this::toDto));
    }

    /**
     * WU napi riport.
     * GET /api/v1/western-union/daily-report
     */
    @GetMapping("/daily-report")
    public ResponseEntity<WuDailyReportDto> getDailyReport(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        WuDailyReportDto report = westernUnionService.getDailyReport(branchId, date);
        return ResponseEntity.ok(report);
    }

    /**
     * WU egyenleg lekérdezése.
     * GET /api/v1/western-union/balance
     */
    @GetMapping("/balance")
    public ResponseEntity<List<WuBalanceDto>> getBalance(@RequestParam UUID branchId) {
        List<WuBalance> balances = westernUnionService.getBalance(branchId);
        return ResponseEntity.ok(balances.stream().map(this::toBalanceDto).collect(Collectors.toList()));
    }

    // ============ DTO KONVERZIÓ ============

    private WuTransactionDto toDto(WuTransaction tx) {
        return WuTransactionDto.builder()
                .id(tx.getId())
                .branchId(tx.getBranch() != null ? tx.getBranch().getId() : null)
                .wuCustomerId(tx.getWuCustomer() != null ? tx.getWuCustomer().getId() : null)
                .transactionType(tx.getTransactionType())
                .mtcn(tx.getMtcn())
                .amountUsd(tx.getAmountUsd())
                .amountHuf(tx.getAmountHuf())
                .exchangeRate(tx.getExchangeRate())
                .feeAmount(tx.getFeeAmount())
                .senderName(tx.getSenderName())
                .receiverName(tx.getReceiverName())
                .destinationCountry(tx.getDestinationCountry())
                .receiptNumber(tx.getReceiptNumber())
                .status(tx.getStatus() != null ? tx.getStatus().name() : null)
                .workerId(tx.getWorker() != null ? tx.getWorker().getId() : null)  // Worker.id is Long
                .transactionDate(tx.getTransactionDate())
                .createdAt(tx.getCreatedAt())
                .build();
    }

    private WuBalanceDto toBalanceDto(WuBalance balance) {
        return WuBalanceDto.builder()
                .id(balance.getId())
                .branchId(balance.getBranch() != null ? balance.getBranch().getId() : null)
                .usdBalance(balance.getUsdBalance())
                .hufBalance(balance.getHufBalance())
                .lastReceiptSell(balance.getLastReceiptSell())
                .lastReceiptBuy(balance.getLastReceiptBuy())
                .lastReceiptCustomerIn(balance.getLastReceiptCustomerIn())
                .lastReceiptCustomerOut(balance.getLastReceiptCustomerOut())
                .updatedAt(balance.getUpdatedAt())
                .build();
    }
}
