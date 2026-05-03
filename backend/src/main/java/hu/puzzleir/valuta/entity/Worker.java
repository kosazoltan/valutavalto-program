package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Munkavállaló (pénztáros) entity.
 * 
 * Multi-tenant support: company_id kötelező!
 * 
 * Legacy mapping:
 * - code: prosbe.dll PtarosKod (_taros_id)
 * - name: PtarosNev (_taros)
 * - passwordHash: prosbe.dll password check
 * - role: _alapjog, _fonokrend
 * - branch: PENZTAR kapcsolat
 * - otpUserId: OTP terminal ID (_otp)
 */
@Entity
@Table(name = "worker", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"company_id", "code"})
})
@EntityListeners(AuditingEntityListener.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Worker {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    /**
     * MULTI-TENANT: Cég kapcsolat (kötelező!)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;
    
    /**
     * Pénztáros azonosító kód (pl. "P001", "P002")
     * Egyedi company-n belül!
     */
    @Column(nullable = false, length = 10)
    private String code;
    
    /**
     * Teljes név
     */
    @Column(nullable = false, length = 100)
    private String name;
    
    /**
     * BCrypt jelszó hash
     */
    @Column(nullable = false)
    private String passwordHash;
    
    /**
     * Szerepkör (CASHIER, SUPERVISOR, MANAGER, ADMIN)
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private WorkerRole role;
    
    /**
     * Munkahely (iroda/fiók)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;
    
    /**
     * Aktív státusz (false = inaktív dolgozó)
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    /** Region identifier (BEKESCSABA, DEBRECEN, NYIREGYHAZA, KECSKEMET, SZEGED, KAPOSVAR, PECS, SZEKSZARD, IRODA). */
    @Column(name = "region", length = 40)
    private String region;
    
    /**
     * Telefonszám
     */
    @Column(length = 20)
    private String phone;
    
    /**
     * Email cím
     */
    @Column(length = 100)
    private String email;
    
    /**
     * OTP terminal user ID (Phase 9 - opcionális)
     * Legacy: _otp változó
     */
    @Column(name = "otp_user_id", length = 50)
    private String otpUserId;
    
    /**
     * OTP engedélyezve
     */
    @Column(name = "otp_enabled")
    @Builder.Default
    private Boolean otpEnabled = false;
    
    /**
     * Utolsó belépés időpontja
     */
    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    /**
     * Jelszó utolsó módosítás időpontja
     */
    @Column(name = "password_changed_at")
    private LocalDateTime passwordChangedAt;

    // ============ GOOGLE OAUTH WHITELIST (V178, 2026-05-03) ============

    /**
     * Google OAuth `sub` claim — stabil, eletre szolo Google account azonosito.
     * Egy worker max EGY Google fiokhoz koheto (uq_worker_google_subject).
     * NULL = meg nem kotott (elso sikeres login utan toltodik fel, ha
     * `google.login.bind-sub-on-first-login=true`).
     */
    @Column(name = "google_subject", length = 255)
    private String googleSubject;

    /**
     * Whitelist flag: csak akkor enged be Google login, ha ez true.
     * Admin allitja explicit modon.
     */
    @Column(name = "google_login_enabled", nullable = false)
    @Builder.Default
    private Boolean googleLoginEnabled = false;

    /** Mikor kotottuk a Google fiok sub azonositot ehhez a workerhez. */
    @Column(name = "google_linked_at")
    private LocalDateTime googleLinkedAt;

    /** Utolso sikeres Google login idopontja. */
    @Column(name = "google_last_login_at")
    private LocalDateTime googleLastLoginAt;
    
    /**
     * Létrehozás időpontja
     */
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    /**
     * Utolsó módosítás időpontja
     */
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    /**
     * Létrehozó user
     */
    @Column(name = "created_by", length = 50)
    private String createdBy;
    
    /**
     * Módosító user
     */
    @Column(name = "updated_by", length = 50)
    private String updatedBy;
}
