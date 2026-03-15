package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Dekád haszon — valutánkénti bontás.
 *
 * Nyitó készlet × MNB árfolyam vs. záró készlet × MNB árfolyam.
 * A különbség a „lefelözéses technológia" dekád haszna.
 */
@Entity
@Table(name = "decade_report_line", uniqueConstraints = {
    @UniqueConstraint(name = "uk_decade_line_report_currency",
                      columnNames = {"decade_report_id", "currency_code"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DecadeReportLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "decade_report_id", nullable = false)
    private DecadeReport decadeReport;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // --- Nyitó ---
    @Column(name = "opening_balance", precision = 18, scale = 4, nullable = false)
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    @Column(name = "opening_mnb_rate", precision = 12, scale = 4)
    private BigDecimal openingMnbRate;

    @Column(name = "opening_value_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal openingValueHuf = BigDecimal.ZERO;

    // --- Záró ---
    @Column(name = "closing_balance", precision = 18, scale = 4, nullable = false)
    @Builder.Default
    private BigDecimal closingBalance = BigDecimal.ZERO;

    @Column(name = "closing_mnb_rate", precision = 12, scale = 4)
    private BigDecimal closingMnbRate;

    @Column(name = "closing_value_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal closingValueHuf = BigDecimal.ZERO;

    // --- Haszon ---
    @Column(name = "profit_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal profitHuf = BigDecimal.ZERO;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
