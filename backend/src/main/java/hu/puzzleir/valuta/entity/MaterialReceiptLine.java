package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Bizonylat tételsor — egy valutanem és összeg a bizonylaton.
 */
@Entity
@Table(name = "material_receipt_line")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class MaterialReceiptLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receipt_id", nullable = false)
    private MaterialReceipt receipt;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;

    @Column(name = "exchange_rate", precision = 12, scale = 4)
    private BigDecimal exchangeRate;

    @Column(name = "huf_equivalent", precision = 18, scale = 2)
    private BigDecimal hufEquivalent;
}
