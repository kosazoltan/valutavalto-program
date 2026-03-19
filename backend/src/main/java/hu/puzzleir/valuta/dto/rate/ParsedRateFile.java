package hu.puzzleir.valuta.dto.rate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Teljes feldolgozott árfolyamfájl a legacy GETARF modulból.
 *
 * Tartalmazza az összes valutanem árfolyamait és a feldolgozás metaadatait.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParsedRateFile {

    /** Feldolgozott valutánkénti árfolyamok */
    @Builder.Default
    private List<ParsedCurrencyRate> rates = new ArrayList<>();

    /** Feldolgozás időbélyege */
    private LocalDateTime parsedAt;

    /** Sikeresen feldolgozott sorok száma */
    private int parsedLineCount;

    /** Kihagyott (hibás) sorok száma */
    private int skippedLineCount;

    /**
     * Adott valutakód árfolyamának keresése.
     */
    public Optional<ParsedCurrencyRate> findByCurrencyCode(String currencyCode) {
        return rates.stream()
                .filter(r -> r.getCurrencyCode().equalsIgnoreCase(currencyCode))
                .findFirst();
    }
}
