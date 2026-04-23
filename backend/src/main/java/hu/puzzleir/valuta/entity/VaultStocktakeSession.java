package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Ertektar leltar (stocktake) fejleg - Sprint 7.1
 * 
 * Workflow: OPEN -> IN_PROGRESS -> REVIEW -> CLOSED (vagy CANCELLED)
 * Legacy: LELTAR.DLL
 */
@Entity
@Table(name = "vault_stocktake_session")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultStocktakeSession {

    public enum Status {
        OPEN,         // uj, tetelek varhatoan
        IN_PROGRESS,  // felvetel alatt
        REVIEW,       // ellenorzes
        CLOSED,       // lezart
        CANCELLED     // megszakitott
    }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    @JsonIgnore
    private Company company;

    @JsonProperty("companyId")
    @Transient
    public UUID getCompanyIdForJson() {
        return company != null ? company.getId() : null;
    }

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id")
    @JsonIgnore
    private Branch branch;

    @JsonProperty("branchId")
    @Transient
    public UUID getBranchIdForJson() {
        return branch != null ? branch.getId() : null;
    }

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "territory_id")
    @JsonIgnore
    private VaultTerritory territory;

    @JsonProperty("territoryId")
    @Transient
    public Integer getTerritoryIdForJson() {
        return territory != null ? territory.getId() : null;
    }

    @Column(name = "session_name", nullable = false, length = 200)
    private String sessionName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Status status = Status.OPEN;

    @Column(name = "started_at", nullable = false)
    @Builder.Default
    private LocalDateTime startedAt = LocalDateTime.now();

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "started_by", nullable = false, length = 100)
    private String startedBy;

    @Column(name = "reviewed_by", length = 100)
    private String reviewedBy;

    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "discrepancy_total_huf", precision = 20, scale = 2)
    @Builder.Default
    private BigDecimal discrepancyTotalHuf = BigDecimal.ZERO;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Version
    @Column(name = "version")
    @Builder.Default
    private Long version = 0L;

    @OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JsonIgnore
    @Builder.Default
    private List<VaultStocktakeItem> items = new ArrayList<>();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
