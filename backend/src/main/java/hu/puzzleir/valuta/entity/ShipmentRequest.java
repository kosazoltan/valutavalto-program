package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Szállítmánykérés entity.
 * Fiókok közötti valuta szállítmány igénylés.
 */
@Entity
@Table(name = "shipment_request", indexes = {
    @Index(name = "idx_shipment_request_number", columnList = "request_number", unique = true),
    @Index(name = "idx_shipment_request_status", columnList = "status")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "request_number", nullable = false, unique = true, length = 50)
    private String requestNumber;

    @Column(name = "from_branch_id", nullable = false)
    private UUID fromBranchId;

    @Column(name = "to_branch_id", nullable = false)
    private UUID toBranchId;

    @Column(name = "requested_by_id", nullable = false)
    private Long requestedById;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ShipmentRequestStatus status = ShipmentRequestStatus.DRAFT;

    @Column(name = "request_date", nullable = false)
    private LocalDate requestDate;

    @Column(name = "delivery_date")
    private LocalDate deliveryDate;

    @Column(columnDefinition = "TEXT")
    private String notes;

    // F3 (2026-06-01): dedikált elutasítás (reject) audit-mezői — elkülönítve a cancel-től.
    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "rejected_by_worker_id")
    private Long rejectedByWorkerId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "shipmentRequest", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ShipmentRequestItem> items = new ArrayList<>();

    /**
     * Helper: item hozzáadása a kéréshez.
     */
    public void addItem(ShipmentRequestItem item) {
        items.add(item);
        item.setShipmentRequest(this);
    }

    /**
     * Helper: összes item beállítása.
     */
    public void setItems(List<ShipmentRequestItem> newItems) {
        this.items.clear();
        if (newItems != null) {
            for (ShipmentRequestItem item : newItems) {
                addItem(item);
            }
        }
    }
}
