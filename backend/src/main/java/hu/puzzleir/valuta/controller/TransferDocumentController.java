package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.TransferDocument;
import hu.puzzleir.valuta.service.TransferDocumentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Értékszállítási bizonylat controller.
 *
 * Endpointok:
 * - POST /api/v1/transfer-documents          → létrehozás
 * - PUT  /{id}/pickup                        → értékszállító átveszi (PIN)
 * - PUT  /{id}/deliver                       → értékszállító leadja
 * - PUT  /{id}/confirm                       → átvevő megerősíti
 * - GET  /?status=&courierId=                → listázás
 * - GET  /{id}                               → részletek
 */
@RestController
@RequestMapping("/api/v1/transfer-documents")
@RequiredArgsConstructor
public class TransferDocumentController {

    private final TransferDocumentService transferDocumentService;

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDocument> create(@RequestBody CreateRequest request) {
        TransferDocument doc = transferDocumentService.createTransfer(
                request.senderId, request.currencyCode, request.quantity,
                request.sourceType, request.sourceId,
                request.destinationType, request.destinationId,
                request.courierPin, request.notes);
        return ResponseEntity.status(HttpStatus.CREATED).body(doc);
    }

    @PutMapping("/{id}/pickup")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDocument> pickup(
            @PathVariable Long id,
            @RequestBody PickupRequest request) {
        return ResponseEntity.ok(
                transferDocumentService.courierPickup(id, request.courierId, request.courierPin));
    }

    @PutMapping("/{id}/deliver")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDocument> deliver(@PathVariable Long id) {
        return ResponseEntity.ok(transferDocumentService.courierDeliver(id));
    }

    @PutMapping("/{id}/confirm")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDocument> confirm(
            @PathVariable Long id,
            @RequestBody ConfirmRequest request) {
        return ResponseEntity.ok(
                transferDocumentService.receiverConfirm(id, request.receiverId));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<TransferDocument>> list(
            @RequestParam(required = false) TransferDocument.Status status,
            @RequestParam(required = false) Long courierId) {
        return ResponseEntity.ok(transferDocumentService.findFiltered(status, courierId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDocument> getById(@PathVariable Long id) {
        return ResponseEntity.ok(transferDocumentService.getById(id));
    }

    // ============ REQUEST DTO-K ============

    @lombok.Data
    public static class CreateRequest {
        private Long senderId;
        private String currencyCode;
        private BigDecimal quantity;
        private String sourceType;
        private String sourceId;
        private String destinationType;
        private String destinationId;
        private String courierPin;
        private String notes;
    }

    @lombok.Data
    public static class PickupRequest {
        private Long courierId;
        private String courierPin;
    }

    @lombok.Data
    public static class ConfirmRequest {
        private Long receiverId;
    }
}
