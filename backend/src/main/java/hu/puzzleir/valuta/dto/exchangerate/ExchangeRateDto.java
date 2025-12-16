package hu.puzzleir.valuta.dto.exchangerate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Árfolyam DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExchangeRateDto {
    private Long id;

    // Valuta
    private Long currencyId;
    private String currencyCode;
    private String currencyName;

    // Érvényesség
    private LocalDate validDate;
    private LocalTime validTime;

    // Alap árfolyam
    private BigDecimal baseBuyRate;
    private BigDecimal baseSellRate;

    // Limit szintek
    private BigDecimal limit1Amount;
    private BigDecimal limit1BuyRate;
    private BigDecimal limit1SellRate;

    private BigDecimal limit2Amount;
    private BigDecimal limit2BuyRate;
    private BigDecimal limit2SellRate;

    private BigDecimal limit3Amount;
    private BigDecimal limit3BuyRate;
    private BigDecimal limit3SellRate;

    // Egyéb
    private BigDecimal officialRate;
    private Boolean active;
    private String createdBy;
    private LocalDateTime createdAt;
}
