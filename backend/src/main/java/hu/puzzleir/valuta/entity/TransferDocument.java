package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Értékszállítási bizonylat.
 * Valuta mozgatás nyomon követése: bank→értéktár→pénztár és vissza.
 * PIN-alapú biztonsági megerősítéssel.
 */
@Entity
@Table(name = "transfer_document", indexes = {
    @Index(name = "idx_transfer_doc_status", columnList = "status"),
    @Index(name = "idx_transfer_doc_courier", columnList = "courier_id, status"),
    @Index(name = "idx_transfer_doc_company", columnList = "company_id, created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransferDocument {

    public enum Status {
        PENDING, PICKED_UP, DELIVERED, CONFIRMED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Bizonylat szám: SZ-YYYYMMDD-XXXX
     */
    @Column(name = "document_number", nullable = false, length = 30)
    private String documentNumber;

    // ---- Résztvevők ----

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private Worker sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courier_id")
    private Worker courier;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id")
    private Worker receiver;

    // ---- Honnan-hová ----

    @Column(name = "source_type", nullable = false, length = 20)
    private String sourceType;

    @Column(name = "source_id", length = 36)
    private String sourceId;

    @Column(name = "destination_type", nullable = false, length = 20)
    private String destinationType;

    @Column(name = "destination_id", length = 36)
    private String destinationId;

    // ---- Tartalom ----

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal quantity;

    @Column(name = "wac_at_transfer", precision = 12, scale = 4)
    private BigDecimal wacAtTransfer;

    // ---- Státusz ----

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Status status = Status.PENDING;

    // ---- Időbélyegek ----

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "picked_up_at")
    private LocalDateTime pickedUpAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    // ---- PIN biztonság ----

    @Column(name = "courier_pin_hash", length = 128)
    private String courierPinHash;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
