package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Rendőrségi adatkérés entity.
 *
 * Hatósági megkeresések nyilvántartása — ügyfél és tranzakció keresés.
 */
@Entity
@Table(name = "police_request", indexes = {
    @Index(name = "idx_police_request_status", columnList = "status"),
    @Index(name = "idx_police_request_date", columnList = "request_date")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PoliceRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "request_number", nullable = false, length = 100)
    private String requestNumber;

    @Column(name = "request_date", nullable = false)
    private LocalDate requestDate;

    /** Rendőr neve / jelvényszáma */
    @Column(name = "requested_by", nullable = false, length = 200)
    private String requestedBy;

    @Column(name = "customer_name", length = 200)
    private String customerName;

    @Column(name = "document_number", length = 100)
    private String documentNumber;

    @Column(name = "date_range_from")
    private LocalDate dateRangeFrom;

    @Column(name = "date_range_to")
    private LocalDate dateRangeTo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private PoliceRequestStatus status = PoliceRequestStatus.RECEIVED;

    /** Talált tranzakciók (JSON) */
    @Column(name = "response_data", columnDefinition = "TEXT")
    private String responseData;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private Worker createdByWorker;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
