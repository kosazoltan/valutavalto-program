package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Worker MFA (Multi-Factor Authentication) konfiguráció.
 *
 * <p>v2.0 specifikáció + Anti masterplan §17 alapján: vezetői / admin /
 * compliance / export szerepköröknek MFA kötelező.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 3 (P2-A — MFA / TOTP).</p>
 *
 * <p>A `secret` Google Authenticator-kompatibilis Base32 string (RFC 6238 TOTP).
 * A `backupCodesHash` egyszer-használatos backup kódok bcrypt hash-ei (recovery).</p>
 */
@Entity
@Table(name = "worker_mfa", indexes = {
    @Index(name = "idx_worker_mfa_worker", columnList = "worker_id", unique = true),
    @Index(name = "idx_worker_mfa_enabled", columnList = "is_enabled")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkerMfa {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Worker FK (a `worker.id` Long-ja). */
    @Column(name = "worker_id", nullable = false, unique = true)
    private Long workerId;

    /** MFA típusa: TOTP, SMS, EMAIL. v2.5.50-ben csak TOTP támogatott. */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String type = "TOTP";

    /** TOTP secret (Base32 encoded, RFC 6238). */
    @Column(name = "secret", nullable = false, length = 64)
    private String secret;

    /** Backup recovery kódok hash-elt formában (JSON tömb bcrypt hash-ekkel). */
    @Column(name = "backup_codes_hash", columnDefinition = "TEXT")
    private String backupCodesHashJson;

    /** Beállítva-e (enrollment befejezve, első sikeres validation után true). */
    @Column(name = "is_enrolled", nullable = false)
    @Builder.Default
    private Boolean isEnrolled = false;

    /** Aktiválva van-e (admin enable). */
    @Column(name = "is_enabled", nullable = false)
    @Builder.Default
    private Boolean isEnabled = false;

    /** Utolsó sikeres MFA validáció. */
    @Column(name = "last_verified_at")
    private LocalDateTime lastVerifiedAt;

    /** Az utolsó sikeresen használt TOTP kód (replay-protection). */
    @Column(name = "last_used_code", length = 10)
    private String lastUsedCode;

    /** Enrollment kezdete (a secret generálásának időpontja). */
    @Column(name = "enrolled_at")
    private LocalDateTime enrolledAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Version
    private Long version;
}
