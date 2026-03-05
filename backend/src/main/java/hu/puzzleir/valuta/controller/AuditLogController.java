package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Audit log controller — érzékeny műveletek naplózásának lekérdezése.
 *
 * Szűrés: entitás, pénztáros, iroda, akció típus alapján.
 */
@RestController
@RequestMapping("/api/v1/audit-log")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class AuditLogController {

    private final AuditLogService auditLogService;

    /**
     * Audit logok entitás szerint.
     * GET /api/v1/audit-log?entityId=xxx
     */
    @GetMapping
    public ResponseEntity<List<AuditLog>> getByEntity(@RequestParam String entityId) {
        return ResponseEntity.ok(auditLogService.getByEntity(entityId));
    }

    /**
     * Audit logok pénztáros szerint.
     * GET /api/v1/audit-log/worker/{id}
     */
    @GetMapping("/worker/{id}")
    public ResponseEntity<Page<AuditLog>> getByWorker(
            @PathVariable String id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(auditLogService.getByWorker(id, from, to, PageRequest.of(page, size)));
    }

    /**
     * Audit logok iroda szerint.
     * GET /api/v1/audit-log/branch/{id}
     */
    @GetMapping("/branch/{id}")
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
     * GET /api/v1/audit-log/action/{action}
     */
    @GetMapping("/action/{action}")
    public ResponseEntity<Page<AuditLog>> getByAction(
            @PathVariable String action,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(auditLogService.getByAction(action, from, to, PageRequest.of(page, size)));
    }
}
