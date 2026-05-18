package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.diagnostics.AuditLogEntryResponseDto;
import hu.puzzleir.valuta.dto.diagnostics.ErrorCodeCatalogDto;
import hu.puzzleir.valuta.dto.diagnostics.FrontendLogEntryRequestDto;
import hu.puzzleir.valuta.dto.diagnostics.HashChainIntegrityResponseDto;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.service.AuditEventService;
import hu.puzzleir.valuta.service.ErrorCodeCatalogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * EBC Valutavalto - belso log+audit modul AI-olvashato diagnosztikai REST API (V234).
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.5)
 *
 * <p>Az altalanos kliens-hibajelentes az {@link DiagnosticsController}-en megy
 * (`/api/v1/diagnostics/error-report` → `client_error_log` tabla).
 * Ez a kontroller a V234-es <b>strukturalt audit-log</b> + AI-fix-hint
 * katalogus + hash-chain integritas-ellenorzes diagnosztikara fokuszal.
 *
 * <p>Endpoint-ok prefix-e: {@code /api/v1/diagnostics/audit}
 * <ul>
 *   <li>{@code GET  .../recent-errors} - utolso N ERROR audit-bejegyzes</li>
 *   <li>{@code GET  .../trace/{traceId}} - egy trace_id-hez tartozo lanc</li>
 *   <li>{@code GET  .../entity/{entityType}/{entityId}} - entity audit-lanca</li>
 *   <li>{@code GET  .../error-codes} - YAML-bol toltott katalogus</li>
 *   <li>{@code GET  .../hash-chain-verify?lastN=N} - integritas-ellenorzes</li>
 *   <li>{@code POST .../log} - frontend ERROR forward backend log-ba</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/diagnostics/audit")
@RequiredArgsConstructor
@Tag(name = "Diagnostics-Audit", description = "Belso log+audit modul AI-olvashato diagnosztika (V234)")
public class AuditDiagnosticsController {

    private static final VVLogger LOG = VVLogger.of(AuditDiagnosticsController.class);

    private final AuditLogRepository auditLogRepository;
    private final AuditEventService auditEventService;
    private final ErrorCodeCatalogService errorCodeCatalog;

    // =========================================================================
    // Olvasasi endpoint-ok (ADMIN / SUPPORT)
    // =========================================================================

    @GetMapping("/recent-errors")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Utolso N audit-bejegyzes (alapertelmezett 100, max 500)")
    public ResponseEntity<List<AuditLogEntryResponseDto>> recentErrors(
            @RequestParam(defaultValue = "100") int limit) {
        int clamped = Math.max(1, Math.min(500, limit));
        List<AuditLog> entries = auditLogRepository.findRecentTopN(clamped);
        return ResponseEntity.ok(entries.stream()
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/trace/{traceId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Egy trace_id-hez tartozo osszes audit-esemeny (kliens-backend korrelacio)")
    public ResponseEntity<List<AuditLogEntryResponseDto>> byTrace(@PathVariable String traceId) {
        if (traceId == null || !traceId.matches("[a-fA-F0-9]{16,32}")) {
            return ResponseEntity.badRequest().build();
        }
        List<AuditLog> entries = auditLogRepository.findByTraceIdOrderByTsAsc(traceId);
        return ResponseEntity.ok(entries.stream()
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/entity/{entityType}/{entityId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Egy entity audit-lancanak idorendi lekerdezese")
    public ResponseEntity<List<AuditLogEntryResponseDto>> auditChain(
            @PathVariable String entityType,
            @PathVariable String entityId) {
        List<AuditLog> entries = auditEventService.findAuditChain(entityType, entityId);
        return ResponseEntity.ok(entries.stream()
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/error-codes")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "AI-olvashato hibakod-katalogus (packages/shared-logging/error-codes.yaml)")
    public ResponseEntity<ErrorCodeCatalogDto> errorCodes() {
        return ResponseEntity.ok(errorCodeCatalog.getCatalog());
    }

    @GetMapping("/hash-chain-verify")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Audit hash-chain integritas-ellenorzes (utolso N esemeny)")
    public ResponseEntity<HashChainIntegrityResponseDto> verifyHashChain(
            @RequestParam(defaultValue = "100") int lastN) {
        int clamped = Math.max(2, Math.min(1000, lastN));
        Optional<UUID> brokenId = auditEventService.verifyHashChainIntegrity(clamped);
        return ResponseEntity.ok(brokenId
                .map(id -> HashChainIntegrityResponseDto.broken(clamped, id))
                .orElseGet(() -> HashChainIntegrityResponseDto.ok(clamped)));
    }

    // =========================================================================
    // Irasi endpoint - frontend ERROR forward (autentikalt user)
    // =========================================================================

    /**
     * Frontend / Electron kliens-oldali ERROR / WARN forward backend log-ba.
     *
     * <p>Bemenet: a kliens-oldali {@code vvLogger.error("VV-VOICE-001", ...)}
     * hivasakor a frontend ezt az endpoint-ot szolitja meg. A backend a kapott
     * payload-ot a {@link VVLogger}-en at logolja (Logback JSON output + redactor).
     *
     * <p>Min. szerepkor: barki autentikalt - kulonben DDoS-csatorna lenne.
     * INFO/DEBUG szintek elutasitva (csak ERROR/WARN megy a backend-re).
     */
    @PostMapping("/log")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Frontend / Electron kliens ERROR / WARN forward backend log-ba")
    public ResponseEntity<Void> forwardLog(@Valid @RequestBody FrontendLogEntryRequestDto request) {
        Map<String, Object> attrs = new HashMap<>();
        if (request.attrs() != null) attrs.putAll(request.attrs());
        attrs.put("client.context", request.clientContext());
        attrs.put("client.version", request.clientVersion());
        if (request.traceId() != null) attrs.put("client.trace_id", request.traceId());
        if (request.clientTs() != null) attrs.put("client.ts", request.clientTs().toString());
        if (request.stackTrace() != null) {
            String st = request.stackTrace();
            attrs.put("client.stack",
                    st.length() > 2000 ? st.substring(0, 2000) + "...[truncated]" : st);
        }
        attrs.put("client.message", request.message());

        String level = request.level() != null ? request.level().toUpperCase() : "ERROR";
        switch (level) {
            case "WARN" -> LOG.warn(request.eventType(), request.errorCode(), attrs);
            case "ERROR" -> LOG.error(
                    request.errorCode() != null ? request.errorCode() : "VV-TECH-002",
                    request.eventType(),
                    null,
                    attrs);
            default -> LOG.warn("diagnostics.audit.log.invalid_level", "VV-TECH-003",
                    Map.of("attempted_level", level, "eventType", request.eventType()));
        }
        return ResponseEntity.accepted().build();
    }
}
