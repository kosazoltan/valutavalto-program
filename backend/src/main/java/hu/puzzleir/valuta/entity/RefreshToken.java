package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Refresh token entitas (vezerlokonyv par.12.3).
 * BCrypt-hashelt token - az eredeti UUID csak a HttpOnly cookie-ban.
 */
@Entity
@Table(name = "refresh_token")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "token_hash", nullable = false, unique = true, length = 255)
    private String tokenHash;

    /**
     * Audit P0.3 (2026-05-03): selector pattern.
     * Indexed unique, NULL = legacy token (regi pre-V176 cookie-k).
     * Cookie format: `selector.verifier`, ahol a verifier BCrypt-hashelt a tokenHash-ben.
     */
    @Column(name = "selector", length = 64)
    private String selector;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /**
     * A refresh tokenhez tartozó végleges operatív szerepkör.
     * Multi-role login után ezt a role-select endpoint állítja be, hogy silent
     * refreshkor ugyanaz a Pénztár/Értéktár/Szerver szerepkör maradjon aktív.
     */
    @Column(name = "active_role", length = 64)
    private String activeRole;

    /**
     * FK-076: a tokent kibocsato kliens appMode-ja. A silent refresh ebbol szuri ujra a JWT
     * {@code grantedRoles} claim-et, kulonben a rotacio megkerulne az appMode-izolaciot.
     * NULL = legacy/ismeretlen appMode (nincs szures, mint a login-agon).
     */
    @Column(name = "app_mode", length = 32)
    private String appMode;

    @Column(name = "issued_at", nullable = false)
    private Instant issuedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Column(name = "replaced_by", length = 255)
    private String replacedBy;

    @Column(name = "user_agent", length = 512)
    private String userAgent;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    public boolean isActive() {
        return revokedAt == null && expiresAt.isAfter(Instant.now());
    }
}
