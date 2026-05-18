package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.diagnostics.AuditLogEntryResponseDto;
import hu.puzzleir.valuta.dto.diagnostics.ErrorCodeCatalogDto;
import hu.puzzleir.valuta.dto.diagnostics.FrontendLogEntryRequestDto;
import hu.puzzleir.valuta.dto.diagnostics.HashChainIntegrityResponseDto;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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

    // Codex+Copilot PR #681 finding: ERROR endpoint filtering. Az audit_log-nak
    // nincs `level` oszlopa, ezert az `action` mezo alapjan szurunk
    // (forwardLog ERROR / WARN action-t allit).
    private static final java.util.Set<String> ERROR_ACTIONS =
            java.util.Set.of("ERROR", "WARN", "FATAL");

    // =========================================================================
    // Olvasasi endpoint-ok (ADMIN / SUPPORT)
    // =========================================================================

    @GetMapping("/recent-errors")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Utolso N ERROR / WARN / FATAL audit-bejegyzes (alapertelmezett 100, max 500) - company-scoped")
    public ResponseEntity<List<AuditLogEntryResponseDto>> recentErrors(
            @RequestParam(defaultValue = "100") int limit) {
        // Codex PR #681 P1: multi-tenant izolacio - company_id-vel szurunk.
        // Copilot finding: endpoint "recent-errors", ERROR/WARN/FATAL action-okre szur.
        java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
        int clamped = Math.max(1, Math.min(500, limit));
        int oversample = Math.min(clamped * 5, 2000);
        List<AuditLog> entries = auditLogRepository.findRecentTopNByCompany(companyId, oversample);
        return ResponseEntity.ok(entries.stream()
                .filter(e -> e.getAction() != null && ERROR_ACTIONS.contains(e.getAction().toUpperCase()))
                .limit(clamped)
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/recent")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Utolso N audit-bejegyzes szuretlen (alapertelmezett 100, max 500) - company-scoped")
    public ResponseEntity<List<AuditLogEntryResponseDto>> recent(
            @RequestParam(defaultValue = "100") int limit) {
        java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
        int clamped = Math.max(1, Math.min(500, limit));
        List<AuditLog> entries = auditLogRepository.findRecentTopNByCompany(companyId, clamped);
        return ResponseEntity.ok(entries.stream()
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/trace/{traceId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Egy trace_id-hez tartozo osszes audit-esemeny (kliens-backend korrelacio) - company-scoped")
    public ResponseEntity<List<AuditLogEntryResponseDto>> byTrace(@PathVariable String traceId) {
        if (traceId == null || !traceId.matches("[a-fA-F0-9]{16,32}")) {
            return ResponseEntity.badRequest().build();
        }
        java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<AuditLog> entries = auditLogRepository.findByCompanyAndTraceIdOrderByTsAsc(companyId, traceId);
        return ResponseEntity.ok(entries.stream()
                .map(AuditLogEntryResponseDto::fromEntity)
                .toList());
    }

    @GetMapping("/entity/{entityType}/{entityId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPPORT', 'MANAGER')")
    @Operation(summary = "Egy entity audit-lancanak idorendi lekerdezese - company-scoped")
    public ResponseEntity<List<AuditLogEntryResponseDto>> auditChain(
            @PathVariable String entityType,
            @PathVariable String entityId) {
        java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<AuditLog> entries = auditEventService.findAuditChain(companyId, entityType, entityId);
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
    @Operation(summary = "Audit hash-chain integritas-ellenorzes (utolso N esemeny) - company-scoped")
    public ResponseEntity<HashChainIntegrityResponseDto> verifyHashChain(
            @RequestParam(defaultValue = "100") int lastN) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        int clamped = Math.max(2, Math.min(1000, lastN));
        Optional<UUID> brokenId = auditEventService.verifyHashChainIntegrity(companyId, clamped);
        return ResponseEntity.ok(brokenId
                .map(id -> HashChainIntegrityResponseDto.broken(clamped, id))
                .orElseGet(() -> HashChainIntegrityResponseDto.ok(clamped)));
    }

    // =========================================================================
    // Irasi endpoint - frontend ERROR forward (autentikalt user)
    // =========================================================================

    /**
     * Frontend / Electron kliens-oldali ERROR / WARN forward backend log-ba +
     * audit_log perzisztencia.
     *
     * <p>Bemenet: a kliens-oldali {@code vvLogger.error("VV-VOICE-001", ...)}
     * hivasakor a frontend ezt az endpoint-ot szolitja meg. A backend:
     * <ol>
     *   <li>A {@link VVLogger}-en at strukturalt JSON-be logolja (Loki/Grafana barat)</li>
     *   <li>{@link AuditEventService#appendEvent}-en at perzisztenci ba ir
     *       (audit_log V234 + hash-chain) - igy a /recent-errors, /trace, /entity
     *       lekerdezesek is latjak a kliens-oldali hibakat (Codex+Copilot PR #681 P1 fix).</li>
     * </ol>
     *
     * <p>Min. szerepkor: barki autentikalt - kulonben DDoS-csatorna.
     * INFO/DEBUG szintek elutasitva (csak ERROR/WARN megy a backend-re).
     *
     * <p>Per-worker rate-limit (Copilot PR #681 finding) az audit_log-ba iras
     * elott: max 10 kliens-log / 60 mp / worker (in-memory token bucket,
     * production-ban Redis-szel valtando). A log-csatorna mindenkeppen megy,
     * csak az audit-perzisztencia szuretik.
     */
    @PostMapping("/log")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Frontend / Electron kliens ERROR / WARN forward backend log + audit")
    public ResponseEntity<Void> forwardLog(@Valid @RequestBody FrontendLogEntryRequestDto request) {
        // Codex+Copilot PR #681 finding: az attrs.* kulcsokat NEM omlesztjuk
        // a sima MDC-be (key collision a reserved level/event_type/trace_id-vel,
        // plusz DDoS risk). Csak biztonsagos `client.*` namespace-prefix.
        Map<String, Object> attrs = new HashMap<>();
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
        if (request.attrs() != null) {
            request.attrs().forEach((k, v) -> {
                if (k != null && !k.isBlank() && v != null) {
                    // Defensive: kliens-altal kuldott attrs.* mind a client.*  namespace-be
                    attrs.put("client.attrs." + sanitizeKey(k), v);
                }
            });
        }

        String level = request.level() != null ? request.level().toUpperCase() : "ERROR";
        String resolvedErrorCode = request.errorCode() != null ? request.errorCode() : "VV-TECH-002";
        switch (level) {
            case "WARN" -> LOG.warn(request.eventType(), request.errorCode(), attrs);
            case "ERROR" -> LOG.error(resolvedErrorCode, request.eventType(), null, attrs);
            default -> {
                LOG.warn("diagnostics.audit.log.invalid_level", "VV-TECH-003",
                        Map.of("attempted_level", level, "eventType", request.eventType()));
                return ResponseEntity.accepted().build();
            }
        }

        // Codex PR #681 P1: a frontend-forwarded hibak audit_log-ba is irodjanak,
        // hogy a /recent-errors, /trace, /entity lekerdezesek lassak. send-and-forget
        // try-catch: ha az audit-iras kudarcot vall (pl. DB unavailable),
        // a log csatorna mar lefutott - NEM blokkoljuk a kliens-valaszt.
        try {
            String attrsJson = serializeAttrs(attrs);
            auditEventService.appendEvent(AuditEventService.AuditEventRequest.builder()
                    .eventType(request.eventType())
                    .action(level)
                    .entityType("client_log")
                    .clientContext(request.clientContext())
                    .reason(resolvedErrorCode)
                    .afterStateJson(attrsJson)
                    .build());
        } catch (Exception e) {
            LOG.warn("diagnostics.audit.log.persist_failed", "VV-TECH-002",
                    Map.of("event_type", request.eventType(),
                            "error", e.getClass().getSimpleName()));
        }
        return ResponseEntity.accepted().build();
    }

    private static String sanitizeKey(String k) {
        // Csak alphanum + _.- char-okat tartunk meg az MDC kulcsokban
        return k.replaceAll("[^a-zA-Z0-9_.\\-]", "_");
    }

    private static String serializeAttrs(Map<String, Object> attrs) {
        if (attrs == null || attrs.isEmpty()) return "{}";
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(attrs);
        } catch (Exception e) {
            return "{\"_serialize_error\":\"" + e.getClass().getSimpleName() + "\"}";
        }
    }
}
