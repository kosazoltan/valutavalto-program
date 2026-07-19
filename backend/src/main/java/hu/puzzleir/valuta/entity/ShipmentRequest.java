package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
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
    @Index(name = "idx_shipment_request_company_number", columnList = "company_id, request_number", unique = true),
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

    @Column(name = "request_number", nullable = false, length = 50)
    private String requestNumber;

    @Column(name = "company_id", updatable = false)
    private UUID companyId;

    @Column(name = "serial_prefix", length = 4)
    private String serialPrefix;

    @Column(name = "serial_number")
    private Long serialNumber;

    @Column(name = "from_branch_id", nullable = false)
    private UUID fromBranchId;

    @Column(name = "to_branch_id", nullable = false)
    private UUID toBranchId;

    /**
     * FR-1 (Értéktár Shipment készletkönyvelés): az átadás iránya — a készletkönyvelés
     * ebből tudja, melyik készlet-típust mozgassa az átadó/átvevő oldalon.
     * Értékek: {@code VAULT_TO_BRANCH | BRANCH_TO_VAULT | BRANCH_TO_BRANCH | VAULT_TO_VAULT}.
     *
     * <p>A {@code ShipmentService.create()} szerveroldalon DERIVÁLJA a from/to {@link Branch#getIsVault()}
     * flag-ekből (kliens nem hamisíthatja). Régi (V336 előtti) rekordok NULL-ok lehetnek (az oszlop
     * nullable a backward-compat miatt); új rögzítésnél a service mindig kitölti.</p>
     */
    @Column(name = "transfer_type", length = 20)
    private String transferType;

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

    // FR-1..3 (átadás-átvétel, FK02): a fizikai szállítást végző neve + a szállítmány plombaszáma —
    // KÖTELEZŐ minden szállítmány-igény (átadás) létrehozásnál (@Valid a create/update endpointon).
    // Az oszlop nullable (régi rekordok null-ok lehetnek); az új-rekord-kötelezőséget a Bean Validation adja.
    @NotBlank(message = "A szállító neve kötelező")
    @Size(max = 128, message = "A szállító neve legfeljebb 128 karakter lehet")
    @Column(name = "carrier_name", length = 128)
    private String carrierName;

    @NotBlank(message = "A plombaszám kötelező")
    @Size(max = 64, message = "A plombaszám legfeljebb 64 karakter lehet")
    @Pattern(regexp = "^[A-Za-z0-9\\-/]+$", message = "A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat")
    @Column(name = "seal_number", length = 64)
    private String sealNumber;

    // F3 (2026-06-01): dedikált elutasítás (reject) audit-mezői — elkülönítve a cancel-től.
    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "rejected_by_worker_id")
    private Long rejectedByWorkerId;

    /** FKH-018: a küldői sztornót rögzítő hitelesített dolgozó és az esemény időpontja. */
    @Column(name = "cancelled_by_worker_id")
    private Long cancelledByWorkerId;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

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

    /**
     * Prod-hiba fix (2026-07-16, 11 éles 500-as): a Jackson 3 JSON-deszerializálás
     * (POST/PUT /api/v1/shipments, @RequestBody ShipmentRequest) a Lombok-generált
     * konstruktor/builder útvonalon tölti az {@code items} listát, és SOSEM hívja
     * az {@link #addItem} / {@link #setItems} helpert — így az itemek
     * {@code shipmentRequest} back-reference-e null marad, és a mentés a
     * shipment_request_item.shipment_request_id NOT NULL constraintjén bukik el
     * (DataIntegrityViolationException → 500). Ez a hook MINDEN konstrukciós
     * útvonalat lefed (JSON, builder, teszt, jövőbeli kód): flush előtt minden
     * itemre beállítja a szülő-referenciát. Idempotens; a DB not-null constraint
     * változatlanul marad fail-closed védőhálónak.
     */
    @PrePersist
    @PreUpdate
    protected void wireItemBackReferences() {
        if (items == null) {
            return;
        }
        for (ShipmentRequestItem item : items) {
            if (item != null && item.getShipmentRequest() != this) {
                item.setShipmentRequest(this);
            }
        }
    }
}
