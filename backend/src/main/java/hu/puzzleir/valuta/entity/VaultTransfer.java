package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Értéktárközi / irodaközi áttétel.
 * Legacy ATADVET (átadás-vétel) megfelelő.
 * Forrás és cél lehet értéktár (vault) vagy pénztár (branch).
 */
@Entity
@Table(name = "vault_transfer")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class VaultTransfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "transfer_number", nullable = false, length = 30)
    private String transferNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "source_vault_id")
    private VaultTerritory sourceVault;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_vault_id")
    private VaultTerritory targetVault;

    @Column(name = "source_branch_code", length = 10)
    private String sourceBranchCode;

    @Column(name = "target_branch_code", length = 10)
    private String targetBranchCode;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;

    /**
     * WAC a kiadás pillanatában (átadó bekerülési ára).
     */
    @Column(name = "wac_at_transfer", precision = 12, scale = 4)
    private BigDecimal wacAtTransfer;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VaultOperationStatus status;

    @Column(name = "requires_supervisor", nullable = false)
    @Builder.Default
    private Boolean requiresSupervisor = false;

    @Column(name = "supervisor_approved_by")
    private Long supervisorApprovedBy;

    @Column(name = "supervisor_approved_at")
    private LocalDateTime supervisorApprovedAt;

    @Column(length = 500)
    private String note;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "received_by")
    private Long receivedBy;

    @Column(name = "received_at")
    private LocalDateTime receivedAt;
}
