package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Napi WU/ÁFA forgalmi tétel archívum (Delphi: WuniCopy).
 *
 * Legacy: WUNI{ÉÉVV} tábla — napi WU és ÁFA forgalmi bizonylatok.
 * A Delphi rendszer a WUAFAFORG munkatáblát másolja ide, majd törli.
 *
 * Modern: a tranzakciók a Transaction táblában maradnak,
 * de a WU/ÁFA-specifikus mezők (biztípus, pénztár) itt rögzítődnek snapshot-ként.
 */
@Entity
@Table(name = "daily_wu_afa_transaction", indexes = {
    @Index(name = "idx_wu_afa_tx_branch_date", columnList = "branch_id, transaction_date"),
    @Index(name = "idx_wu_afa_tx_receipt", columnList = "receipt_number")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyWuAfaTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    @Column(name = "receipt_number", nullable = false, length = 30)
    private String receiptNumber;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /** +/- (Delphi: ELOJEL) */
    @Column(name = "sign", nullable = false, length = 1)
    private String sign;

    @Column(nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal amount = BigDecimal.ZERO;

    /** WU/ÁFA/BOTH (Delphi: BIZTIPUS) */
    @Column(name = "receipt_type", nullable = false, length = 10)
    private String receiptType;

    /** Al-pénztár kód (Delphi: PENZTAR) */
    @Column(name = "register_code", length = 10)
    private String registerCode;

    @Column(nullable = false)
    @Builder.Default
    private Integer storno = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
