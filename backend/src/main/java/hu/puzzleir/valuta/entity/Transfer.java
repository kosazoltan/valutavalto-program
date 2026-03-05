package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import com.puzzleir.backend.entity.Branch;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "transfer")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Transfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "transfer_number", nullable = false, unique = true, length = 30)
    private String transferNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_branch_id", nullable = false)
    private Branch fromBranch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_branch_id", nullable = false)
    private Branch toBranch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_worker_id", nullable = false)
    private Worker fromWorker;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_worker_id")
    private Worker toWorker;

    @Enumerated(EnumType.STRING)
    @Column(name = "transfer_type", nullable = false, length = 20)
    private TransferType transferType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TransferStatus status;

    @Column(name = "transfer_date", nullable = false)
    private LocalDate transferDate;

    @Column(name = "transfer_time", nullable = false)
    private LocalTime transferTime;

    @Column(name = "received_date")
    private LocalDate receivedDate;

    @Column(name = "received_time")
    private LocalTime receivedTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal amount;

    @Column(name = "huf_value", precision = 18, scale = 2)
    private BigDecimal hufValue;

    @Column(name = "received_amount", precision = 18, scale = 4)
    private BigDecimal receivedAmount;

    @Column(name = "difference", precision = 18, scale = 4)
    private BigDecimal difference;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "handover_printed")
    private Boolean handoverPrinted = false;

    @Column(name = "receipt_printed")
    private Boolean receiptPrinted = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public enum TransferType {
        CURRENCY, CASH, HANDLING_FEE, VAULT_DEPOSIT, VAULT_WITHDRAW, CORRECTION, OTHER
    }

    public enum TransferStatus {
        PENDING, IN_TRANSIT, RECEIVED, COMPLETED, REJECTED, CANCELLED
    }
}
