package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Audit P0.5 (2026-05-03) — perzisztens idempotency rekord.
 *
 * <p>Multi-tenant scope: `(company_id, endpoint, idempotency_key)` UNIQUE.
 * Payload binding: `request_hash` SHA-256 a request body-bol.
 * Status: PROCESSING -> COMPLETED|FAILED. TTL: `expires_at` (default 24h).</p>
 */
@Entity
@Table(name = "idempotency_record")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IdempotencyRecord {

    public enum Status {
        PROCESSING,
        COMPLETED,
        FAILED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "endpoint", nullable = false, length = 255)
    private String endpoint;

    @Column(name = "idempotency_key", nullable = false, length = 255)
    private String idempotencyKey;

    @Column(name = "request_hash", nullable = false, length = 64)
    private String requestHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private Status status;

    /** A response_json JSON-szerializalt formaja a domain DTO-nak. */
    @Column(name = "response_json", columnDefinition = "TEXT")
    private String responseJson;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
}
