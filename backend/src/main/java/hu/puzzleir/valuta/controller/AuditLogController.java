package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.audit.AuditLogEntryDto;
import hu.puzzleir.valuta.dto.audit.AuditSearchCriteria;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.service.AuditLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Audit log controller — érzékeny műveletek naplózásának lekérdezése.
 *
 * Szűrés: entitás, pénztáros, iroda, akció típus alapján.
 * Batch 6B: trail, search, worker, export endpoint-ok.
 */
@RestController
@RequestMapping("/api/v1/audit")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
@Tag(name = "Admin", description = "Audit napló kezelése")
public class AuditLogController {

    private final AuditLogService auditLogService;

    // ====================================================================
    // Meglévő endpoint-ok (régi /audit-log path-ról átmigrálva /audit-ra)
    // ====================================================================

    /**
     * Audit logok entitás szerint (backward compatible).
     * GET /api/v1/audit?entityId=xxx
     */
    @GetMapping
    @Operation(summary = "Audit logok entitás ID szerint")
    public ResponseEntity<List<AuditLog>> getByEntity(@RequestParam String entityId) {
        return ResponseEntity.ok(auditLogService.getByEntity(entityId));
    }

    /**
     * Audit logok pénztáros szerint (backward compatible).
     * GET /api/v1/audit/worker/{id}
     */
    @GetMapping("/worker/{id}")
    @Operation(summary = "Audit logok pénztáros (worker) szerint")
    public ResponseEntity<Page<AuditLogEntryDto>> getByWorker(
            @PathVariable String id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(auditLogService.getByWorkerDto(id, from, to, PageRequest.of(page, size)));
    }

    /**
     * Audit logok iroda szerint.
     * GET /api/v1/audit/branch/{id}
     */
    @GetMapping("/branch/{id}")
    @Operation(summary = "Audit logok iroda szerint")
    public ResponseEntity<Page<AuditLog>> getByBranch(
            @PathVariable String id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(auditLogService.getByBranch(id, from, to, PageRequest.of(page, size)));
    }

    /**
     * Audit logok akció típus szerint.
     * GET /api/v1/audit/action/{action}
     */
    @GetMapping("/action/{action}")
    @Operation(summary = "Audit logok akció típus szerint")
    public ResponseEntity<Page<AuditLog>> getByAction(
            @PathVariable String action,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(auditLogService.getByAction(action, from, to, PageRequest.of(page, size)));
    }

    // ====================================================================
    // Batch 6B — Új endpoint-ok
    // ====================================================================

    /**
     * Audit trail egy adott entitáshoz (entityType + entityId).
     * GET /api/v1/audit/trail/{entityType}/{entityId}
     */
    @GetMapping("/trail/{entityType}/{entityId}")
    @Operation(summary = "Audit trail — entitás típus és ID alapján")
    public ResponseEntity<List<AuditLogEntryDto>> getAuditTrail(
            @PathVariable String entityType,
            @PathVariable String entityId) {
        return ResponseEntity.ok(auditLogService.getAuditTrail(entityType, entityId));
    }

    /**
     * Összetett keresés az audit naplóban.
     * GET /api/v1/audit/search?dateFrom=&dateTo=&workerId=&entityType=&action=&keyword=
     */
    @GetMapping("/search")
    @Operation(summary = "Összetett audit napló keresés")
    public ResponseEntity<Page<AuditLogEntryDto>> searchAuditLog(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateTo,
            @RequestParam(required = false) String workerId,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {

        AuditSearchCriteria criteria = AuditSearchCriteria.builder()
                .dateFrom(dateFrom)
                .dateTo(dateTo)
                .workerId(workerId)
                .entityType(entityType)
                .action(action)
                .keyword(keyword)
                .build();

        return ResponseEntity.ok(auditLogService.searchAuditLog(criteria, PageRequest.of(page, size)));
    }

    /**
     * Audit log export CSV-be.
     * GET /api/v1/audit/export?dateFrom=&dateTo=
     */
    @GetMapping("/export")
    @Operation(summary = "Audit napló CSV export")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateTo) {

        byte[] csvBytes = auditLogService.exportFullCsv(dateFrom, dateTo);
        String filename = "audit_export_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".csv";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csvBytes);
    }
}
