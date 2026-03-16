package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "seal_tracking", uniqueConstraints = {
    @UniqueConstraint(name = "uq_seal_tracking_company_seal", columnNames = {"company_id", "seal_number"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SealTracking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Version
    @Column(name = "version")
    private Long version;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "transfer_type", nullable = false, length = 20)
    private String transferType;

    @Column(name = "transfer_id", nullable = false)
    private Long transferId;

    @Column(name = "seal_number", nullable = false, length = 50)
    private String sealNumber;

    @Column(name = "sealed_at", nullable = false)
    private LocalDateTime sealedAt;

    @Column(name = "sealed_by", nullable = false)
    private Long sealedBy;

    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    @Column(name = "opened_by")
    private Long openedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "transit_status", nullable = false, length = 20)
    private SealTransitStatus transitStatus;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void prePersist() {
        createdAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
