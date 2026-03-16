package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Anyag bevételi / kiadási bizonylat.
 * Legacy MATBIZONYLAT megfelelő.
 * B = bevétel (készlet nő), K = kiadás (készlet csökken).
 */
@Entity
@Table(name = "material_receipt")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class MaterialReceipt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "receipt_number", nullable = false, length = 30)
    private String receiptNumber;

    /**
     * B = bevétel (incoming), K = kiadás (outgoing)
     */
    @Column(name = "receipt_type", nullable = false, length = 1)
    private String receiptType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vault_territory_id")
    private VaultTerritory vaultTerritory;

    @Column(name = "branch_code", length = 10)
    private String branchCode;

    @Column(name = "counterpart_name", length = 200)
    private String counterpartName;

    @Column(length = 500)
    private String note;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "finalized_at")
    private LocalDateTime finalizedAt;

    @Column(name = "created_by")
    private Long createdBy;

    @OneToMany(mappedBy = "receipt", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<MaterialReceiptLine> lines = new ArrayList<>();
}
