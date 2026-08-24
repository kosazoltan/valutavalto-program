package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FKH-040: ÁFA átadás-átvétel napló (Shipment-eredetű HUF-ellátmány mozgás).
 * Nincs calculated_fee — a rögzített HUF-összeg maga a tétel.
 */
@Entity
@Table(name = "shipment_vat_supply_item")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentVatSupplyItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "shipment_request_id", nullable = false, unique = true)
    private UUID shipmentRequestId;

    @Column(name = "from_branch_id", nullable = false)
    private UUID fromBranchId;

    @Column(name = "to_branch_id", nullable = false)
    private UUID toBranchId;

    @Column(name = "huf_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal hufAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ShipmentRequestStatus status;

    /**
     * true = a jóváhagyáskori készlet-mozgás már lefutott (idempotencia).
     */
    @Column(name = "stock_applied", nullable = false)
    @Builder.Default
    private boolean stockApplied = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;
}
