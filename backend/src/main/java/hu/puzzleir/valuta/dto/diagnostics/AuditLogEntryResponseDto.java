package hu.puzzleir.valuta.dto.diagnostics;

import hu.puzzleir.valuta.entity.AuditLog;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Audit-log bejegyzes diagnosztikai API-valasz - belso log+audit modul.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.5)
 *
 * <p>Csak a V234-ben hozzaadott, AI-olvashato mezoket exportalja + az
 * entry_hash + previous_hash backward-compat ertekeket. A regi `changes` /
 * `oldValue` / `newValue` mezok NEM kerulnek bele (helyettesitve `before_state`
 * / `after_state` JSONB-vel).
 */
public record AuditLogEntryResponseDto(
        UUID id,
        UUID eventId,
        Instant ts,
        String eventType,
        String action,
        String entityType,
        String entityId,
        String beforeState,
        String afterState,
        BigDecimal amount,
        String currency,
        String receiptNumber,
        String traceId,
        String clientContext,
        String reason,
        String signedBy,
        String workerRole,
        UUID companyId,
        String branchName,
        String userName,
        String entryHash,
        String previousHash
) {
    public static AuditLogEntryResponseDto fromEntity(AuditLog e) {
        return new AuditLogEntryResponseDto(
                e.getId(),
                e.getEventId(),
                e.getTs(),
                e.getEventType(),
                e.getAction(),
                e.getEntityType(),
                e.getEntityId(),
                e.getBeforeState(),
                e.getAfterState(),
                e.getAmount(),
                e.getCurrency(),
                e.getReceiptNumber(),
                e.getTraceId(),
                e.getClientContext(),
                e.getReason(),
                e.getSignedBy(),
                e.getWorkerRole(),
                e.getCompanyId(),
                e.getBranchName(),
                e.getUserName(),
                e.getEntryHash(),
                e.getPreviousHash()
        );
    }
}
