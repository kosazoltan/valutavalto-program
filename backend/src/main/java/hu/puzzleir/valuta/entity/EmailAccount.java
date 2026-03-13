package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.config.EncryptedStringConverter;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Gmail fiók entitás — szervezeti egységhez (branch/vaultTerritory/ownCompany) vagy worker-hez kötött.
 * FONTOS: Pontosan EGY a 4 FK-ból (branch, vaultTerritory, ownCompany, worker) kitöltve!
 * Validáció a service rétegben történik.
 */
@Entity
@Table(name = "email_account")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EmailAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Pénztár/iroda hozzárendelés (nullable — pontosan 1 FK kitöltve!)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id")
    private Branch branch;

    /**
     * Értéktári terület hozzárendelés (nullable)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vault_territory_id")
    private VaultTerritory vaultTerritory;

    /**
     * Saját cég hozzárendelés (nullable)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "own_company_id")
    private OwnCompany ownCompany;

    /**
     * Worker hozzárendelés (nullable)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id")
    private Worker worker;

    @Column(name = "gmail_address", nullable = false, length = 255)
    private String gmailAddress;

    @Column(name = "display_name", length = 200)
    private String displayName;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "oauth_access_token", columnDefinition = "TEXT")
    private String oauthAccessToken;

    @Convert(converter = EncryptedStringConverter.class)
    @Column(name = "oauth_refresh_token", columnDefinition = "TEXT")
    private String oauthRefreshToken;

    @Column(name = "oauth_token_expiry")
    private LocalDateTime oauthTokenExpiry;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "last_sync_at")
    private LocalDateTime lastSyncAt;

    @Column(name = "sync_error", columnDefinition = "TEXT")
    private String syncError;

    /**
     * Melyik worker konfigurálta ezt a fiókot.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "configured_by_worker_id")
    private Worker configuredByWorker;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
