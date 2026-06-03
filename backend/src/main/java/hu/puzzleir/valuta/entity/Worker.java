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
     * BCrypt jelszó hash.
     * Nullable: first-time-setup előtt a seed password törölhető (V196),
     * ilyenkor a WorkerFirstTimeSetupService jelszó nélkül engedi az új jelszó beállítást.
     */
    @Column(nullable = true)
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

    /**
     * F-001 átmeneti grace (V279): TRUE, ha a dolgozó a fix deploy-pillanatában már null-hash
     * (folyamatban lévő first-time setup). Ilyenkor a bootstrap-lezárt utáni null-hash setup
     * EGYSZER setup-token NÉLKÜL is engedélyezett — a sikeres beállításkor a guard lezárja
     * (false). Minden ezt követő (új) null-hash reset már setup-tokent igényel.
     */
    // @Builder.Default KÖTELEZŐ: e nélkül a Lombok @Builder figyelmen kívül hagyja a `= false`
    // inicializálót → a builderrel épített Worker (pl. WorkerService.createWorker) setupGrace=null-t
    // kapna, ami a NOT NULL oszlopon (V279) INSERT-kor constraint-sértést okozna. (A testvér boolean
    // mezők — otpEnabled/googleLoginEnabled/sharedAccount/active — már helyesen @Builder.Default-osak.)
    @Column(name = "setup_grace", nullable = false)
    @Builder.Default
    private Boolean setupGrace = false;

    // ============ SUPERVISOR PIN (V188, 2026-05-06 P2-2) ============

    /**
     * 4-6 számjegyű supervisor PIN BCrypt hash-e. NULL = nincs PIN beállítva.
     * NEM helyettesíti a jelszót — gyors-engedélyhez (sztornó, supervisor jóváhagyás).
     */
    @Column(name = "supervisor_pin", length = 60)
    private String supervisorPin;

    @Column(name = "supervisor_pin_changed_at")
    private LocalDateTime supervisorPinChangedAt;

    @Column(name = "supervisor_pin_last_used_at")
    private LocalDateTime supervisorPinLastUsedAt;

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
     * FK-ÉRTÉKTÁR (V285, 2026-06-02): intézményi (közös) Google-fiók jelölés.
     * Ha true, a Google-login NEM ad végleges sessiont, hanem a kétlépcsős értéktári
     * belépés indul: a felhasználó kiválasztja a SAJÁT (személyes) workerét + jelszó.
     * A személyes workerek shared_account = false.
     */
    @Column(name = "shared_account", nullable = false)
    @Builder.Default
    private Boolean sharedAccount = false;

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
