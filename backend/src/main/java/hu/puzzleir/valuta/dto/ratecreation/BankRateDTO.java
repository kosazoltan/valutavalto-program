package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Bank árfolyam DTO.
 *
 * Frontend interface BankRateDTO:
 *   id, bankName, bankCode, currencyCode,
 *   buyRate, sellRate, middleRate, validFrom, source
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BankRateDTO {

    /** ExchangeRate.id */
    private Long id;

    /** Bank neve (fiók neve, vagy alapértelmezett "EBC") */
    private String bankName;

    /** Bank kódja (cég kódja, vagy "EBC") */
    private String bankCode;

    // ---- meglévő mezők (visszafelé kompatibilis) ----

    private Long currencyId;
    private String currencyCode;

    /** Vételi árfolyam (alias: bankBuyRate → buyRate a frontendnek) */
    private BigDecimal buyRate;

    /** Eladási árfolyam (alias: bankSellRate → sellRate a frontendnek) */
    private BigDecimal sellRate;

    private BigDecimal middleRate;

    /** Érvényességi dátum-idő (validDate + validTime összevonva) */
    private LocalDateTime validFrom;

    /** Forrás megjelölés (pl. "MANUAL", "MNB") */
    private String source;

    // ---- Legacy alias mezők — meglévő hívások miatt ----

    /** @deprecated Használj buyRate-t. Megtartva visszafelé kompatibilitáshoz. */
    @Deprecated
    public BigDecimal getBankBuyRate() { return buyRate; }

    /** @deprecated Használj sellRate-t. Megtartva visszafelé kompatibilitáshoz. */
    @Deprecated
    public BigDecimal getBankSellRate() { return sellRate; }

    /** @deprecated Használj validFrom-ot. Megtartva visszafelé kompatibilitáshoz. */
    @Deprecated
    public LocalDateTime getLastUpdated() { return validFrom; }
}
