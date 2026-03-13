package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztárgép esemény entity.
 * NAV online pénztárgép kötelező a pénzváltóknál (magyar jogszabály).
 * A tényleges hardware kommunikáció abstract — egyelőre mock/log implementáció.
 */
@Entity
@Table(name = "cash_register_event", indexes = {
    @Index(name = "idx_cash_register_event_branch", columnList = "branch_id"),
    @Index(name = "idx_cash_register_event_type", columnList = "event_type"),
    @Index(name = "idx_cash_register_event_timestamp", columnList = "event_timestamp")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CashRegisterEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 30)
    private CashRegisterEventType eventType;

    @Column(name = "receipt_number", length = 100)
    private String receiptNumber;

    @Column(precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency_code", length = 3)
    private String currencyCode;

    @Column(name = "amount_huf", precision = 18, scale = 2)
    private BigDecimal amountHuf;

    @Column(name = "tax_number", length = 20)
    private String taxNumber;

    @Column(name = "cash_register_id", length = 50)
    private String cashRegisterId;

    @Column(name = "event_timestamp", nullable = false)
    @Builder.Default
    private LocalDateTime eventTimestamp = LocalDateTime.now();

    @Column(name = "raw_response", columnDefinition = "TEXT")
    private String rawResponse;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
