package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Összegyűjtött tranzakció — másolat a központi DB-ben.
 *
 * Legacy: Adatgyűjtő DLL — iroda tranzakcióinak másolása a központba.
 */
@Entity
@Table(name = "collected_transaction", indexes = {
    @Index(name = "idx_ct_collection", columnList = "data_collection_id"),
    @Index(name = "idx_ct_original", columnList = "original_transaction_id"),
    @Index(name = "idx_ct_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CollectedTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Szülő adatgyűjtés
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "data_collection_id", nullable = false)
    private DataCollection dataCollection;

    /**
     * Eredeti tranzakció ID az iroda DB-ben
     */
    @Column(name = "original_transaction_id", nullable = false)
    private Long originalTransactionId;

    /**
     * Tranzakció típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 30)
    private TransactionType transactionType;

    /**
     * Valutanem kód
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Deviza összeg
     */
    @Column(name = "foreign_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal foreignAmount;

    /**
     * HUF összeg
     */
    @Column(name = "huf_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal hufAmount;

    /**
     * Alkalmazott árfolyam
     */
    @Column(name = "rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal rate;

    /**
     * Bizonylat szám
     */
    @Column(name = "receipt_number", length = 20)
    private String receiptNumber;

    /**
     * Ügyfél neve (nullable — nem minden tranzakciónál kötelező)
     */
    @Column(name = "customer_name", length = 200)
    private String customerName;

    /**
     * Tranzakció időpontja
     */
    @Column(name = "transaction_timestamp", nullable = false)
    private LocalDateTime transactionTimestamp;
}
