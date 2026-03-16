package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Készletkorrekció — leltárkülönbözet rendezés.
 * Legacy KESZEDIT megfelelő.
 */
@Entity
@Table(name = "stock_correction")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class StockCorrection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "entity_type", nullable = false, length = 20)
    private String entityType;

    @Column(name = "entity_id", nullable = false, length = 36)
    private String entityId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "old_quantity", nullable = false, precision = 18, scale = 2)
    private BigDecimal oldQuantity;

    @Column(name = "new_quantity", nullable = false, precision = 18, scale = 2)
    private BigDecimal newQuantity;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal difference;

    @Column(nullable = false, length = 500)
    private String reason;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VaultOperationStatus status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "approved_by")
    private Long approvedBy;
}
