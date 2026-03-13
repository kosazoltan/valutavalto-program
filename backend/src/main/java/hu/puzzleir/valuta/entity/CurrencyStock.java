package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

/**
 * Valutakészlet WAC (Weighted Average Cost) nyilvántartás.
 * Per entitás (pénztár/értéktár) per valutanem.
 */
@Entity
@Table(name = "currency_stock", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"company_id", "entity_type", "entity_id", "currency_code"})
}, indexes = {
    @Index(name = "idx_currency_stock_entity", columnList = "entity_type, entity_id, currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrencyStock {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Entitás típusa: 'CASHIER' (pénztár) vagy 'VAULT' (értéktár)
     */
    @Column(name = "entity_type", nullable = false, length = 20)
    private String entityType;

    /**
     * Entitás azonosító: branch.id (UUID string) vagy vault_territory.id (int string)
     */
    @Column(name = "entity_id", nullable = false, length = 36)
    private String entityId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal quantity = BigDecimal.ZERO;

    @Column(name = "weighted_avg_cost", nullable = false, precision = 12, scale = 4)
    @Builder.Default
    private BigDecimal weightedAvgCost = BigDecimal.ZERO;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;

    // ============ WAC LOGIKA ============

    /**
     * WAC frissítés bevételezéskor.
     * newWac = (currentQty * currentWac + receivedQty * receivedCost) / (currentQty + receivedQty)
     */
    public void receiveStock(BigDecimal receivedQty, BigDecimal costPerUnit) {
        if (receivedQty.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("A beérkező mennyiség nem lehet nulla vagy negatív!");
        }
        if (costPerUnit.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("A bekerülési ár nem lehet negatív!");
        }
        BigDecimal totalQty = this.quantity.add(receivedQty);
        if (totalQty.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal currentValue = this.quantity.multiply(this.weightedAvgCost);
            BigDecimal receivedValue = receivedQty.multiply(costPerUnit);
            this.weightedAvgCost = currentValue.add(receivedValue)
                    .divide(totalQty, 4, RoundingMode.HALF_UP);
        }
        this.quantity = totalQty;
        this.lastUpdated = LocalDateTime.now();
    }

    /**
     * Készlet csökkentése kiadáskor. A WAC nem változik.
     * @return az aktuális WAC (az átvevő bekerülési ára)
     */
    public BigDecimal issueStock(BigDecimal issuedQty) {
        if (this.quantity.compareTo(issuedQty) < 0) {
            throw new IllegalStateException(
                    "Nincs elegendő készlet: " + this.quantity + " < " + issuedQty
                    + " (" + currencyCode + ", " + entityType + "/" + entityId + ")");
        }
        BigDecimal wacAtIssue = this.weightedAvgCost;
        this.quantity = this.quantity.subtract(issuedQty);
        this.lastUpdated = LocalDateTime.now();
        return wacAtIssue;
    }
}
