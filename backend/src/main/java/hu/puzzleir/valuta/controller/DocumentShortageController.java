package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.DocumentShortage;
import hu.puzzleir.valuta.service.DocumentShortageService;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Okmányhiány-regiszter endpoint (legacy OKMANYHIANY / OKMCTRL.dll).
 */
@RestController
@RequestMapping("/api/v1/document-shortages")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','MANAGER','ADMIN','COMPLIANCE')")
public class DocumentShortageController {

    private final DocumentShortageService service;

    @GetMapping
    public ResponseEntity<List<Dto>> list(@RequestParam(name = "openOnly", defaultValue = "true") boolean openOnly) {
        List<Dto> dtos = service.list(openOnly).stream().map(Dto::of).toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping
    public ResponseEntity<Dto> create(@RequestBody CreateRequest req) {
        DocumentShortage e = service.record(req.getMissingDocument(), req.getCustomerName(),
                req.getCustomerId(), req.getBranchCode(), req.getReceiptNumber(), req.getNote());
        return ResponseEntity.ok(Dto.of(e));
    }

    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN','COMPLIANCE')")
    public ResponseEntity<Dto> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(Dto.of(service.resolve(id)));
    }

    @Value
    public static class Dto {
        UUID id;
        String branchCode;
        String customerName;
        String customerId;
        String receiptNumber;
        String missingDocument;
        String note;
        LocalDateTime recordedAt;
        LocalDateTime resolvedAt;

        static Dto of(DocumentShortage e) {
            return new Dto(e.getId(), e.getBranchCode(), e.getCustomerName(), e.getCustomerId(),
                    e.getReceiptNumber(), e.getMissingDocument(), e.getNote(), e.getRecordedAt(), e.getResolvedAt());
        }
    }

    @Data
    public static class CreateRequest {
        @NotBlank
        private String missingDocument;
        private String customerName;
        private String customerId;
        private String branchCode;
        private String receiptNumber;
        private String note;
    }
}
