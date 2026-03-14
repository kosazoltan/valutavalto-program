package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.service.ReceiptGeneratorService;
import hu.puzzleir.valuta.service.ReceiptService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/receipts")
@RequiredArgsConstructor
public class ReceiptController {

    private final ReceiptService service;
    private final ReceiptGeneratorService receiptGeneratorService;

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Receipt>> list(@RequestParam(required = false) UUID transactionId) {
        return ResponseEntity.ok(service.list(transactionId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Receipt> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping("/{id}/print")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Receipt> print(@PathVariable UUID id) {
        return ResponseEntity.ok(service.print(id));
    }

    /**
     * Tranzakció bizonylat PDF letöltés
     * GET /api/v1/receipts/transaction/{transactionId}/pdf
     */
    @GetMapping("/transaction/{transactionId}/pdf")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> getTransactionPdf(@PathVariable Long transactionId) {
        byte[] pdf = receiptGeneratorService.generatePdfForTransaction(transactionId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=bizonylat-" + transactionId + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    /**
     * Tranzakció bizonylat ESC/POS formátum
     * GET /api/v1/receipts/transaction/{transactionId}/escpos
     */
    @GetMapping("/transaction/{transactionId}/escpos")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> getTransactionEscPos(@PathVariable Long transactionId) {
        byte[] escpos = receiptGeneratorService.generateEscPosForTransaction(transactionId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=bizonylat-" + transactionId + ".bin")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(escpos);
    }

    /**
     * Zárási bizonylat PDF
     * GET /api/v1/receipts/closing/{closingId}/pdf
     */
    @GetMapping("/closing/{closingId}/pdf")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> getClosingPdf(@PathVariable String closingId) {
        ReceiptGeneratorService.ClosingData closingData = ReceiptGeneratorService.ClosingData.builder()
                .companyName("Valutaváltó Kft.")
                .branchName("Központ")
                .workerName("")
                .closingDate(java.time.LocalDate.now())
                .transactionCount(0)
                .totalHufTurnover(java.math.BigDecimal.ZERO)
                .build();

        byte[] pdf = receiptGeneratorService.formatForPdf(
                receiptGeneratorService.generateClosingReceipt(closingData));

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=zaras-" + closingId + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}
