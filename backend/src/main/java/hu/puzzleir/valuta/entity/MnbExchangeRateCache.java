package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * MNB hivatalos árfolyam cache entity.
 *
 * A havi záráshoz szükséges MNB középárfolyamok helyi tárolása.
 * Az MNB SOAP API-ból letöltött adatok cache-elése,
 * hogy ne kelljen minden alkalommal újra lekérdezni.
 */
@Entity
@Table(name = "mnb_exchange_rate_cache", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "currency_code", "rate_date", "source" })
}, indexes = {
        @Index(name = "idx_mnb_rate_date", columnList = "rate_date"),
        @Index(name = "idx_mnb_rate_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MnbExchangeRateCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Valuta kód (pl. "EUR", "USD", "GBP", "CHF")
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Az MNB által közzétett árfolyam dátuma
     */
    @Column(name = "rate_date", nullable = false)
    private LocalDate rateDate;

    /**
     * MNB hivatalos középárfolyam (1 egységre vetítve)
     * Pl. EUR/HUF = 395.12 → officialRate = 395.12, unit = 1
     * Pl. JPY/HUF = 2.65 → officialRate = 265.00, unit = 100
     */
    @Column(name = "official_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal officialRate;

    /**
     * Egység (pl. CZK, JPY esetén 100)
     */
    @Column(nullable = false)
    @Builder.Default
    private Integer unit = 1;

    /**
     * Forrás: "MNB" vagy "RAIFFEISEN"
     */
    @Column(name = "source", nullable = false, length = 20)
    @Builder.Default
    private String source = "MNB";

    /**
     * Letöltés időpontja
     */
    @Column(name = "fetched_at", nullable = false)
    @Builder.Default
    private LocalDateTime fetchedAt = LocalDateTime.now();

    /**
     * 1 egységre vetített árfolyam kiszámítása.
     * Ha unit=100 és officialRate=265.00, akkor ez 2.65-öt ad vissza.
     */
    public BigDecimal getRatePerUnit() {
        if (unit == null || unit <= 1) {
            return officialRate;
        }
        return officialRate.divide(BigDecimal.valueOf(unit), 4, java.math.RoundingMode.HALF_UP);
    }
}
