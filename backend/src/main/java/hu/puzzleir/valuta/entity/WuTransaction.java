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
 * Western Union tranzakció entity.
 *
 * Legacy: WUMOZGAS tábla — WU küldés/fogadás nyilvántartás.
 */
@Entity
@Table(name = "wu_transactions", indexes = {
    @Index(name = "idx_wu_transactions_branch", columnList = "branch_id"),
    @Index(name = "idx_wu_transactions_date", columnList = "transaction_date"),
    @Index(name = "idx_wu_transactions_mtcn", columnList = "mtcn")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wu_customer_id")
    private WuCustomer wuCustomer;

    /** SEND, RECEIVE, IC_IN, IC_OUT, CUSTOMER_IN, CUSTOMER_OUT, STORNO */
    @Column(name = "transaction_type", nullable = false, length = 20)
    private String transactionType;

    @Column(name = "mtcn", length = 20)
    private String mtcn;

    @Column(name = "amount_usd", precision = 18, scale = 2)
    private BigDecimal amountUsd;

    @Column(name = "amount_huf", precision = 18, scale = 2)
    private BigDecimal amountHuf;

    @Column(name = "exchange_rate", precision = 18, scale = 6)
    private BigDecimal exchangeRate;

    @Column(name = "fee_amount", precision = 18, scale = 2)
    private BigDecimal feeAmount;

    @Column(name = "sender_name", length = 200)
    private String senderName;

    @Column(name = "receiver_name", length = 200)
    private String receiverName;

    @Column(name = "destination_country", length = 100)
    private String destinationCountry;

    @Column(name = "receipt_number", length = 50)
    private String receiptNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private WuTransactionStatus status = WuTransactionStatus.COMPLETED;

    /** Sztornó link: az a tranzakció, amelyet ez a sztornó visszavon. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reversed_transaction_id")
    private WuTransaction reversedTransaction;

    /** Sztornó indoklás. */
    @Column(name = "reversal_reason", length = 500)
    private String reversalReason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id")
    private Worker worker;

    @Column(name = "transaction_date", nullable = false)
    private LocalDateTime transactionDate;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
