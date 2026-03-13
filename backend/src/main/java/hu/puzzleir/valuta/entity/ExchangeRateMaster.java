package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyam törzs entity - a főértéktáros által beállított központi árfolyamok.
 *
 * Legacy mapping: ARFOLYAM tábla + ARFREG modul
 * A főértéktáros itt állítja be az árfolyamokat, amelyeket aztán a rendszer
 * automatikusan kiküldi a pénztáraknak (exchange_rate_distribution táblán keresztül).
 *
 * Workflow: DRAFT → APPROVED → PUBLISHED → ARCHIVED/REVOKED
 */
@Entity
@Table(name = "exchange_rate_master", indexes = {
    @Index(name = "idx_erm_company_currency", columnList = "company_id, currency_id"),
    @Index(name = "idx_erm_status", columnList = "status"),
    @Index(name = "idx_erm_active", columnList = "is_active, valid_from")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeRateMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    // ============ ALAP ÁRFOLYAMOK ============

    @Column(name = "base_buy_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal baseBuyRate;

    @Column(name = "base_sell_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal baseSellRate;

    @Column(name = "official_rate", precision = 18, scale = 6)
    private BigDecimal officialRate;

    // ============ LIMIT ÁRFOLYAMOK ============

    @Column(name = "limit1_amount", precision = 15, scale = 2)
    private BigDecimal limit1Amount;

    @Column(name = "limit1_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit1BuyRate;

    @Column(name = "limit1_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit1SellRate;

    @Column(name = "limit2_amount", precision = 15, scale = 2)
    private BigDecimal limit2Amount;

    @Column(name = "limit2_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit2BuyRate;

    @Column(name = "limit2_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit2SellRate;

    @Column(name = "limit3_amount", precision = 15, scale = 2)
    private BigDecimal limit3Amount;

    @Column(name = "limit3_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit3BuyRate;

    @Column(name = "limit3_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit3SellRate;

    // ============ ÁLLAPOT ============

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MasterRateStatus status = MasterRateStatus.DRAFT;

    @Column(name = "version_number", nullable = false)
    @Builder.Default
    private Integer versionNumber = 1;

    @Column(name = "valid_from", nullable = false)
    @Builder.Default
    private LocalDateTime validFrom = LocalDateTime.now();

    @Column(name = "valid_until")
    private LocalDateTime validUntil;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    // ============ AUDIT ============

    @Column(name = "created_by", nullable = false)
    private Long createdBy;

    @Column(name = "approved_by")
    private Long approvedBy;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(columnDefinition = "TEXT")
    private String notes;

    public enum MasterRateStatus {
        DRAFT, APPROVED, PUBLISHED, REVOKED, ARCHIVED
    }
}
