package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Vétel request DTO
 * (Ügyfél valutát ad el, cég HUF-ot fizet)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BuyRequestDto {

    @NotNull(message = "Valuta azonosító kötelező")
    private Long currencyId;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal currencyAmount;

    @DecimalMin(value = "0", message = "A kedvezmény nem lehet negatív")
    private BigDecimal discountPercent;

    @DecimalMin(value = "0", message = "A kezelési díj nem lehet negatív")
    private BigDecimal handlingFee;

    // Ügyfél adatok (300.000 Ft felett kötelező)
    private String customerId;
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
    private String customerNationality;

    private String notes;
}
