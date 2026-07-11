package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Darius napi jelentés valutánkénti részletsor.
 *
 * Egy DariusDailyReport-hoz több sor tartozik — valutánként
 * egy bontás a vétel/eladás/konverzió összesítéssel.
 */
@Entity
@Table(name = "darius_report_line", indexes = {
    @Index(name = "idx_darius_line_report", columnList = "report_id"),
    @Index(name = "idx_darius_line_branch", columnList = "branch_id"),
    @Index(name = "ix_darius_line_company_report", columnList = "company_id, report_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusReportLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Tenant defense-in-depth (V356): a sor maga is hordozza a company_id-t. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** Szülő jelentés */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = false)
    private DariusDailyReport report;

    /** Iroda */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /** Iroda kód (denormalizált a riporthoz) */
    @Column(name = "branch_code", length = 20)
    private String branchCode;

    /** Valutakód (ISO 4217) */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /** Vétel darabszám */
    @Column(name = "buy_count")
    @Builder.Default
    private Integer buyCount = 0;

    /** Vétel deviza összeg */
    @Column(name = "buy_currency_amount", precision = 18, scale = 4)
    @Builder.Default
    private BigDecimal buyCurrencyAmount = BigDecimal.ZERO;

    /** Vétel HUF összeg */
    @Column(name = "buy_huf_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal buyHufAmount = BigDecimal.ZERO;

    /** Eladás darabszám */
    @Column(name = "sell_count")
    @Builder.Default
    private Integer sellCount = 0;

    /** Eladás deviza összeg */
    @Column(name = "sell_currency_amount", precision = 18, scale = 4)
    @Builder.Default
    private BigDecimal sellCurrencyAmount = BigDecimal.ZERO;

    /** Eladás HUF összeg */
    @Column(name = "sell_huf_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal sellHufAmount = BigDecimal.ZERO;

    /** Alkalmazott vételi árfolyam (súlyozott átlag) */
    @Column(name = "avg_buy_rate", precision = 12, scale = 4)
    private BigDecimal avgBuyRate;

    /** Alkalmazott eladási árfolyam (súlyozott átlag) */
    @Column(name = "avg_sell_rate", precision = 12, scale = 4)
    private BigDecimal avgSellRate;

    /** Kezelési díj HUF (valutára jutó) */
    @Column(name = "handling_fee_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal handlingFeeHuf = BigDecimal.ZERO;
}
