package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "banknote_inventory", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"branch_id", "currency_id", "face_value"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BanknoteInventory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "face_value", nullable = false, precision = 19, scale = 4)
    private BigDecimal faceValue;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    @Column(name = "total_value", precision = 19, scale = 4)
    private BigDecimal totalValue;

    @Column(name = "min_quantity")
    private Integer minQuantity;

    @Column(name = "max_quantity")
    private Integer maxQuantity;

    @Column(name = "availability_did", length = 20)
    @Builder.Default
    private String availabilityDid = "COMMON";

    @Column(name = "last_counted_at")
    private LocalDateTime lastCountedAt;

    @Column(name = "last_counted_by")
    private String lastCountedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        recalculate();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        recalculate();
    }

    private void recalculate() {
        if (faceValue != null && quantity != null) {
            totalValue = faceValue.multiply(BigDecimal.valueOf(quantity));
        }
    }

    public boolean isLowStock() {
        return minQuantity != null && quantity != null && quantity < minQuantity;
    }

    public boolean isOverStock() {
        return maxQuantity != null && quantity != null && quantity > maxQuantity;
    }

    public void addQuantity(int amount) {
        if (amount <= 0) throw new IllegalArgumentException("amount must be positive");
        // CodeQL java/tainted-arithmetic fix: Math.addExact() ArithmeticException-t dob
        // overflow eseten, igy a tainted user-input (amount) nem koppintja az integer
        // hatart silent wrap-aroundolva.
        int current = this.quantity != null ? this.quantity : 0;
        this.quantity = Math.addExact(current, amount);
        recalculate();
    }

    public void removeQuantity(int amount) {
        if (amount <= 0) throw new IllegalArgumentException("amount must be positive");
        if (this.quantity == null || this.quantity < amount) {
            throw new IllegalStateException("Insufficient stock: have " + this.quantity + ", need " + amount);
        }
        this.quantity -= amount;
        recalculate();
    }
}
