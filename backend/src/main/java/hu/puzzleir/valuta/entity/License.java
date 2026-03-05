package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Szoftver licenc nyilvántartás.
 * Egy céghez tartozó licenc kulcs, érvényesség, max fiók/dolgozó szám és engedélyezett modulok.
 */
@Entity
@Table(name = "license")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class License {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private Integer companyId;

    @Column(name = "license_key", nullable = false, unique = true, length = 255)
    private String licenseKey;

    @Column(name = "valid_from", nullable = false)
    private LocalDate validFrom;

    @Column(name = "valid_to", nullable = false)
    private LocalDate validTo;

    @Column(name = "max_branches", nullable = false)
    private Integer maxBranches;

    @Column(name = "max_workers", nullable = false)
    private Integer maxWorkers;

    /** JSON tömb — engedélyezett modulok, pl. ["WU","HRK","STAMPS"] */
    @Column(columnDefinition = "TEXT")
    private String features;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "activated_at")
    private LocalDateTime activatedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (isActive == null) isActive = true;
        if (maxBranches == null) maxBranches = 1;
        if (maxWorkers == null) maxWorkers = 5;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
