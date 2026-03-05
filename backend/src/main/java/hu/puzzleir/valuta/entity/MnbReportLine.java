package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * MNB riport sor — egy valutanem összesítése a riport időszakára.
 *
 * Legacy: MNB gyűjtő DLL valutánkénti bontás.
 */
@Entity
@Table(name = "mnb_report_line", indexes = {
    @Index(name = "idx_mnb_line_report", columnList = "mnb_report_id"),
    @Index(name = "idx_mnb_line_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MnbReportLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Szülő MNB riport
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mnb_report_id", nullable = false)
    private MnbReport mnbReport;

    /**
     * Valutanem kód (ISO 4217, pl. EUR, USD)
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Vétel összeg (devizában)
     */
    @Column(name = "buy_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal buyAmount = BigDecimal.ZERO;

    /**
     * Eladás összeg (devizában)
     */
    @Column(name = "sell_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal sellAmount = BigDecimal.ZERO;

    /**
     * Átlagos vételi árfolyam
     */
    @Column(name = "buy_rate", precision = 12, scale = 4)
    @Builder.Default
    private BigDecimal buyRate = BigDecimal.ZERO;

    /**
     * Átlagos eladási árfolyam
     */
    @Column(name = "sell_rate", precision = 12, scale = 4)
    @Builder.Default
    private BigDecimal sellRate = BigDecimal.ZERO;

    /**
     * Tranzakciók száma ennél a valutánál
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;
}
