package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kezelési díj tranzakció részletezés.
 * Minden tranzakcióhoz egy rekord a pontos díj kalkulációval.
 */
@Entity
@Table(name = "handling_fee_transaction", indexes = {
    @Index(name = "idx_hf_transaction_tx", columnList = "transaction_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HandlingFeeTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "transaction_id", nullable = false)
    private Long transactionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "fee_type", nullable = false, length = 20)
    @Builder.Default
    private HandlingFeeTransactionType feeType = HandlingFeeTransactionType.TIERED;

    @Column(nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal amount = BigDecimal.ZERO;

    @Column(name = "discount_percent", nullable = false)
    @Builder.Default
    private Integer discountPercent = 0;

    @Column(name = "discount_reason", length = 255)
    private String discountReason;

    @Column(name = "net_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal netFee = BigDecimal.ZERO;

    @Column(name = "worker_commission_share", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal workerCommissionShare = BigDecimal.ZERO;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public enum HandlingFeeTransactionType {
        FIXED, PERCENT, TIERED
    }
}
