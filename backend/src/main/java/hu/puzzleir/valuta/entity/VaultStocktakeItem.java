package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Ertektar leltar tétel - Sprint 7.1
 * Cimletenkent: expected vs. actual mennyiseg, eltéres számolás (generated columns).
 */
@Entity
@Table(name = "vault_stocktake_item", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"session_id", "currency_id", "face_value"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultStocktakeItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    @JsonIgnore
    private VaultStocktakeSession session;

    @JsonProperty("sessionId")
    @Transient
    public UUID getSessionIdForJson() {
        return session != null ? session.getId() : null;
    }

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "face_value", nullable = false, precision = 20, scale = 4)
    private BigDecimal faceValue;

    @Column(name = "expected_quantity", nullable = false)
    @Builder.Default
    private Integer expectedQuantity = 0;

    @Column(name = "actual_quantity")
    private Integer actualQuantity;

    /** Generated in DB: actual - expected. NEM modositando. */
    @Column(name = "discrepancy", insertable = false, updatable = false)
    private Integer discrepancy;

    /** Generated in DB: (actual - expected) * face_value. NEM modositando. */
    @Column(name = "discrepancy_value", insertable = false, updatable = false, precision = 20, scale = 2)
    private BigDecimal discrepancyValue;

    @Column(name = "counted_by", length = 100)
    private String countedBy;

    @Column(name = "counted_at")
    private LocalDateTime countedAt;

    @Column(columnDefinition = "TEXT")
    private String note;

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

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
