package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Tranzakciós bankjegy-részletezés entity.
 * Egy tranzakcióhoz tartozó bankjegyek/érmék címletenkénti bontása.
 *
 * Legacy: BLOKKCIMLET tábla — a pénztáros rögzíti, milyen címletekben adta/kapta a valutát.
 * Irány: IN = beérkező (ügyféltől), OUT = kiadandó (ügyfélnek)
 */
@Entity
@Table(name = "transaction_banknote", indexes = {
    @Index(name = "idx_txbn_transaction", columnList = "transaction_id"),
    @Index(name = "idx_txbn_currency", columnList = "currency_code")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionBanknote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Szülő tranzakció
     */
    @Column(name = "transaction_id", nullable = false)
    private Long transactionId;

    /**
     * Tranzakciós sor (opcionális — ha több valutanem van egy bizonylaton)
     */
    @Column(name = "transaction_line_id")
    private Long transactionLineId;

    /**
     * Valuta kód (ISO 4217)
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Címlet értéke (pl. 10000, 5000, 100, 0.50)
     */
    @Column(name = "face_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal faceValue;

    /**
     * Darabszám
     */
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Irány: IN (beérkező/ügyféltől) vagy OUT (kiadandó/ügyfélnek)
     */
    @Column(nullable = false, length = 3)
    private String direction;

    /**
     * Teljes érték (face_value × quantity — számított, de denormalizálva a gyorsaságért)
     */
    @Column(name = "total_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalValue;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // ============ HELPER ============

    @PrePersist
    public void calculateTotalValue() {
        if (faceValue != null && quantity != null) {
            this.totalValue = faceValue.multiply(BigDecimal.valueOf(quantity));
        }
    }
}
