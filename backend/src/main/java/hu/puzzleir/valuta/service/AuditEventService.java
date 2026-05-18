package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import io.micrometer.tracing.Tracer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * EBC Valutavalto - belso log+audit modul AUDIT-csatorna.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.)
 *
 * <p>Ez a service az UJ V234-es mezoket (event_id, ts, trace_id, before_state,
 * after_state, amount, currency, signed_by, etc) toltheti meg + hash-chain-be
 * kapcsolja a {@link AuditLog} entitast.
 *
 * <p>A meglevo {@link AuditLogService} PARALEL fut tovabb — azt a regi
 * audit-flow-k hasznaljak (action+entityType+changes szovegesen). Ez az uj
 * service a tervezet 4.3 szerint a `auditEvent({event_type, action,
 * after_state, ...})` API-t adja a kliensek + a backend belso szolgaltatasok
 * szamara.
 *
 * <p>Hash chain elve:
 * <ul>
 *   <li>Az elso esemeny {@code prev_hash = GENESIS} (64 db '0').</li>
 *   <li>Minden uj esemeny {@code prev_hash} = az elozo esemeny {@code this_hash}-e.</li>
 *   <li>{@code this_hash = SHA256(prev_hash || event_id || ts || event_type || after_state)}.</li>
 *   <li>Barmely sor utolagos modositasa detektalhato: a kovetkezo sor hash-e nem stimmel.</li>
 * </ul>
 *
 * <p>NEM thread-safe a multi-process production scenarioban — a PostgresSQL
 * `SERIALIZABLE` izolaciot kovetelo tranzakcio garantalja a sequence-t (a hash
 * chain a hivasi sorrendet kovetik).
 */
@Service
@RequiredArgsConstructor
public class AuditEventService {

    private static final VVLogger LOG = VVLogger.of(AuditEventService.class);
    private static final String GENESIS_PREV_HASH = "0".repeat(64);

    private final AuditLogRepository auditLogRepository;
    private final Tracer tracer;

    /**
     * Egy uj audit-esemeny rogzitese hash-chain-be kotelezo modon.
     *
     * @param request a kliens / backend altal kuldott esemeny-payload
     * @return a rogzitett {@link AuditLog} entitas
     */
    @Transactional(rollbackFor = Exception.class)
    public AuditLog appendEvent(AuditEventRequest request) {
        // 1. Trace context kiolvasasa (Micrometer Tracing automatikus)
        String traceId = currentTraceId();

        // 2. Elozo sor `entry_hash`-e a hash chain-bol (FOR UPDATE row-lock)
        // Codex+Copilot PR #681 P1 fix: a concurrent appendEvent() hivasok
        // ne forkoljak a hash lancot. A legacy AuditLogService is ezt a metodust
        // hasznalja (`findLastEntryHashForUpdate`), igy serialize-elunk a 2 utvonal kozott.
        String prevHash = auditLogRepository.findLastEntryHashForUpdate()
                .filter(s -> s != null && !s.isBlank())
                .orElse(GENESIS_PREV_HASH);

        // 3. Idoblyeg + event ID generalas (ha a kliens nem adott)
        Instant ts = request.ts() != null ? request.ts() : Instant.now();
        UUID eventId = request.eventId() != null ? request.eventId() : UUID.randomUUID();

        // 4. SecurityContext-bol worker_id / company_id (ha nincs, NULL)
        UUID workerIdResolved = request.workerId() != null ? request.workerId() : currentWorkerId();
        UUID companyIdResolved = request.companyId() != null ? request.companyId() : currentCompanyId();

        // 5. Hash chain szamitas: SHA-256(prev_hash || event_id || ts || event_type || after_state)
        String thisHash = computeHash(prevHash, eventId, ts, request.eventType(), request.afterStateJson());

        AuditLog entity = AuditLog.builder()
                .eventId(eventId)
                .ts(ts)
                .createdAt(LocalDateTime.ofInstant(ts, ZoneOffset.UTC))  // backward-compat
                .eventType(request.eventType())
                .action(request.action() != null ? request.action() : "CREATE")
                .entityType(request.entityType())
                .entityId(request.entityId() != null ? request.entityId().toString() : null)
                .beforeState(request.beforeStateJson())
                .afterState(request.afterStateJson())
                .amount(request.amount())
                .currency(request.currency())
                .receiptNumber(request.receiptNumber())
                .traceId(traceId)
                .clientContext(request.clientContext())
                .reason(request.reason())
                .signedBy(request.signedBy())
                .workerRole(request.workerRole())
                .companyId(companyIdResolved)
                .userId(workerIdResolved != null ? workerIdResolved.toString() : null)
                .userName(request.workerName())
                .branchId(request.branchId() != null ? request.branchId().toString() : null)
                .branchName(request.branchName())
                .ipAddress(request.ipAddress())
                .userAgent(request.userAgent())
                .previousHash(prevHash)        // H11 hash-chain backward-compat
                .entryHash(thisHash)           // H11 hash-chain backward-compat
                .build();

        AuditLog saved = auditLogRepository.save(entity);
        LOG.info(request.eventType(), java.util.Map.of(
                "audit_id", saved.getId(),
                "event_id", eventId.toString(),
                "trace_id", traceId != null ? traceId : "-",
                "hash", thisHash.substring(0, 16) + "..."
        ));
        return saved;
    }

    /**
     * Egy entity audit-lancanak lekerdezese (entity_type + entity_id alapjan).
     * Idorendben rendezett (legregebbi elsoként).
     */
    @Transactional(readOnly = true)
    public List<AuditLog> findAuditChain(String entityType, String entityId) {
        return auditLogRepository.findByEntityTypeAndEntityIdOrderByTsAsc(entityType, entityId);
    }

    /**
     * Hash-chain integritas ellenorzes egy adott idoszakban.
     *
     * @return Optional.empty() ha minden OK, vagy az elso problémás bejegyzés id-je
     */
    @Transactional(readOnly = true)
    public Optional<UUID> verifyHashChainIntegrity(int lastN) {
        List<AuditLog> chain = auditLogRepository.findTopNByOrderByCreatedAtDesc(lastN);
        if (chain.isEmpty()) return Optional.empty();
        // Idorendbe rendezzuk (legregebbi -> legujabb)
        java.util.Collections.reverse(chain);
        for (int i = 1; i < chain.size(); i++) {
            AuditLog prev = chain.get(i - 1);
            AuditLog curr = chain.get(i);
            if (prev.getEntryHash() == null || !prev.getEntryHash().equals(curr.getPreviousHash())) {
                return Optional.of(curr.getId());
            }
            // Csak az uj V234-mezos sorokat tudjuk recomputalni (eventId + ts)
            if (curr.getEventId() != null && curr.getTs() != null) {
                String recomputed = computeHash(
                        curr.getPreviousHash(),
                        curr.getEventId(),
                        curr.getTs(),
                        curr.getEventType(),
                        curr.getAfterState()
                );
                if (!recomputed.equals(curr.getEntryHash())) {
                    return Optional.of(curr.getId());
                }
            }
        }
        return Optional.empty();
    }

    // ------------------- private helpers -------------------

    private String currentTraceId() {
        if (tracer == null) return null;
        var span = tracer.currentSpan();
        if (span == null) return null;
        var ctx = span.context();
        return ctx != null ? ctx.traceId() : null;
    }

    private UUID currentWorkerId() {
        try {
            String workerCode = SecurityUtils.getCurrentWorkerCode();
            return workerCode != null ? safeParseUuid(workerCode) : null;
        } catch (Exception e) {
            return null;
        }
    }

    private UUID currentCompanyId() {
        try {
            return SecurityUtils.getCurrentCompanyId();
        } catch (Exception e) {
            return null;
        }
    }

    private UUID safeParseUuid(String s) {
        try { return UUID.fromString(s); } catch (Exception e) { return null; }
    }

    /**
     * Hash chain szamitas. A bemenetek osszefuzese a sorrendben:
     * prev_hash || event_id || ts.toString() || event_type || (after_state || "")
     */
    public static String computeHash(String prevHash, UUID eventId, Instant ts, String eventType, String afterState) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(prevHash != null ? prevHash.getBytes(StandardCharsets.UTF_8) : new byte[0]);
            md.update(eventId != null ? eventId.toString().getBytes(StandardCharsets.UTF_8) : new byte[0]);
            md.update(ts != null ? ts.toString().getBytes(StandardCharsets.UTF_8) : new byte[0]);
            md.update(eventType != null ? eventType.getBytes(StandardCharsets.UTF_8) : new byte[0]);
            md.update(afterState != null ? afterState.getBytes(StandardCharsets.UTF_8) : new byte[0]);
            byte[] hash = md.digest();
            StringBuilder sb = new StringBuilder(64);
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available in JDK", e);
        }
    }

    /**
     * Audit-esemeny request DTO. A kotelezo mezok: eventType + action.
     * A tobbi opcionalis (NULL = nincs informacio).
     */
    public record AuditEventRequest(
            UUID eventId,
            Instant ts,
            String eventType,
            String action,
            String entityType,
            UUID entityId,
            String beforeStateJson,
            String afterStateJson,
            BigDecimal amount,
            String currency,
            String receiptNumber,
            String clientContext,
            String reason,
            String signedBy,
            UUID workerId,
            String workerName,
            String workerRole,
            UUID companyId,
            UUID branchId,
            String branchName,
            String ipAddress,
            String userAgent
    ) {
        public static Builder builder() { return new Builder(); }

        public static class Builder {
            private UUID eventId;
            private Instant ts;
            private String eventType;
            private String action = "CREATE";
            private String entityType;
            private UUID entityId;
            private String beforeStateJson;
            private String afterStateJson;
            private BigDecimal amount;
            private String currency;
            private String receiptNumber;
            private String clientContext;
            private String reason;
            private String signedBy;
            private UUID workerId;
            private String workerName;
            private String workerRole;
            private UUID companyId;
            private UUID branchId;
            private String branchName;
            private String ipAddress;
            private String userAgent;

            public Builder eventId(UUID v) { this.eventId = v; return this; }
            public Builder ts(Instant v) { this.ts = v; return this; }
            public Builder eventType(String v) { this.eventType = v; return this; }
            public Builder action(String v) { this.action = v; return this; }
            public Builder entityType(String v) { this.entityType = v; return this; }
            public Builder entityId(UUID v) { this.entityId = v; return this; }
            public Builder beforeStateJson(String v) { this.beforeStateJson = v; return this; }
            public Builder afterStateJson(String v) { this.afterStateJson = v; return this; }
            public Builder amount(BigDecimal v) { this.amount = v; return this; }
            public Builder currency(String v) { this.currency = v; return this; }
            public Builder receiptNumber(String v) { this.receiptNumber = v; return this; }
            public Builder clientContext(String v) { this.clientContext = v; return this; }
            public Builder reason(String v) { this.reason = v; return this; }
            public Builder signedBy(String v) { this.signedBy = v; return this; }
            public Builder workerId(UUID v) { this.workerId = v; return this; }
            public Builder workerName(String v) { this.workerName = v; return this; }
            public Builder workerRole(String v) { this.workerRole = v; return this; }
            public Builder companyId(UUID v) { this.companyId = v; return this; }
            public Builder branchId(UUID v) { this.branchId = v; return this; }
            public Builder branchName(String v) { this.branchName = v; return this; }
            public Builder ipAddress(String v) { this.ipAddress = v; return this; }
            public Builder userAgent(String v) { this.userAgent = v; return this; }

            public AuditEventRequest build() {
                if (eventType == null || eventType.isBlank()) {
                    throw new IllegalArgumentException("AuditEventRequest.eventType kotelezo");
                }
                return new AuditEventRequest(
                        eventId, ts, eventType, action, entityType, entityId,
                        beforeStateJson, afterStateJson, amount, currency, receiptNumber,
                        clientContext, reason, signedBy, workerId, workerName, workerRole,
                        companyId, branchId, branchName, ipAddress, userAgent
                );
            }
        }
    }
}
