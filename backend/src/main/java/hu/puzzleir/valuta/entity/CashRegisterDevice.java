package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Penztar-client Electron eszkoz nyilvantartas (V100).
 * SetupWizard online-regisztracioja hozza letre; a SyncEngine heartbeat-ezi a last_seen_at-et.
 */
@Entity
@Table(name = "cash_register_device")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CashRegisterDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(nullable = false, length = 40)
    private String code;

    @Column(length = 200)
    private String name;

    /** penztar | ertektar | ertekszallito | full */
    @Column(name = "app_mode", nullable = false, length = 30)
    @Builder.Default
    private String appMode = "penztar";

    @Column(name = "app_version", length = 30)
    private String appVersion;

    @Column(name = "device_fingerprint", length = 255)
    private String deviceFingerprint;

    @Column(name = "os_info", length = 255)
    private String osInfo;

    @Column(name = "registered_by_worker_id")
    private Long registeredByWorkerId;

    @Column(name = "installed_at", nullable = false)
    @Builder.Default
    private LocalDateTime installedAt = LocalDateTime.now();

    @Column(name = "last_seen_at")
    private LocalDateTime lastSeenAt;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}