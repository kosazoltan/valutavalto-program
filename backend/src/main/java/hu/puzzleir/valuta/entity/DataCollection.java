package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Adatgyűjtés entity — a szerver modul központi gyűjtő rekordja.
 *
 * Legacy: Adatgyűjtő szerver DLL — irodák napi adatainak összegyűjtése
 * a központi adatbázisba.
 */
@Entity
@Table(name = "data_collection", indexes = {
    @Index(name = "idx_dc_branch_date", columnList = "branch_id, collection_date"),
    @Index(name = "idx_dc_status", columnList = "status"),
    @Index(name = "idx_dc_type", columnList = "collection_type")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uq_dc_branch_date_type",
        columnNames = {"branch_id", "collection_date", "collection_type"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DataCollection {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Gyűjtés dátuma
     */
    @Column(name = "collection_date", nullable = false)
    private LocalDate collectionDate;

    /**
     * Státusz
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private DataCollectionStatus status = DataCollectionStatus.PENDING;

    /**
     * Gyűjtés típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "collection_type", nullable = false, length = 20)
    @Builder.Default
    private DataCollectionType collectionType = DataCollectionType.DAILY;

    /**
     * Összegyűjtött tranzakciók száma
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;

    /**
     * Összes vétel HUF
     */
    @Column(name = "total_buy_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    /**
     * Összes eladás HUF
     */
    @Column(name = "total_sell_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    /**
     * Gyűjtés indításának időpontja
     */
    @Column(name = "started_at")
    private LocalDateTime startedAt;

    /**
     * Gyűjtés befejezésének időpontja
     */
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    /**
     * Hibaüzenet (ha FAILED)
     */
    @Column(name = "error_message", length = 2000)
    private String errorMessage;

    /**
     * Összegyűjtött tranzakciók
     */
    @OneToMany(mappedBy = "dataCollection", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<CollectedTransaction> collectedTransactions = new ArrayList<>();

    /**
     * Összegyűjtött készletek
     */
    @OneToMany(mappedBy = "dataCollection", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<CollectedInventory> collectedInventories = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    public void addCollectedTransaction(CollectedTransaction ct) {
        collectedTransactions.add(ct);
        ct.setDataCollection(this);
    }

    public void addCollectedInventory(CollectedInventory ci) {
        collectedInventories.add(ci);
        ci.setDataCollection(this);
    }
}
