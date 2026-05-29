package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Worker first-time setup token persistence (F-001 fix).
 *
 * <p>Az admin által kiállított, egyszer használatos setup-token. A raw token csak a
 * kiállításkor kerül vissza az adminhoz; az adatbázis SHA-256 hash-t tárol (a token
 * magas-entrópiájú random adat — a {@link PasswordResetToken} mintáját követi).</p>
 *
 * <p>Cél: a {@code /api/v1/auth/first-time-worker-setup} endpoint null-hash ágában a
 * publikus fiókátvétel megakadályozása — a bootstrap-lezárt utáni null-hash setuphoz
 * érvényes, le nem járt, fel nem használt token kell.</p>
 */
@Entity
@Table(name = "worker_setup_token", indexes = {
        @Index(name = "uq_worker_setup_token_hash", columnList = "token_hash", unique = true),
        @Index(name = "idx_worker_setup_token_worker_active", columnList = "worker_id, used_at, expires_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkerSetupToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** A kiállító admin worker id-ja (audit). */
    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "issued_at", nullable = false)
    private Instant issuedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;
}
