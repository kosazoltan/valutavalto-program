package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Versenytárs árfolyam DTO.
 *
 * Frontend interface CompetitorRateDTO:
 *   id, competitorName, competitorCode, currencyCode,
 *   buyRate, sellRate, middleRate, recordedAt, source
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompetitorRateDTO {

    /** CompetitorRate.id (UUID) */
    private UUID id;

    /** Versenytárs neve */
    private String competitorName;

    /** Versenytárs kódja (a neve alapján generált, pl. "OTP") */
    private String competitorCode;

    private String currencyCode;

    private BigDecimal buyRate;
    private BigDecimal sellRate;

    /** Közép-árfolyam ((buyRate + sellRate) / 2) */
    private BigDecimal middleRate;

    /** Rögzítés időpontja */
    private LocalDateTime recordedAt;

    /** Forrás (pl. "MANUAL", "WEBSITE") */
    private String source;

    /** Spread / margin — opcionális, belső számításhoz */
    private BigDecimal margin;

    // ---- Legacy alias mezők — meglévő hívások miatt ----

    /** @deprecated Használj id-t UUID-ként. Megtartva visszafelé kompatibilitáshoz. */
    @Deprecated
    public UUID getCompetitorId() { return id; }

    /** @deprecated Használj recordedAt-et. Megtartva visszafelé kompatibilitáshoz. */
    @Deprecated
    public LocalDateTime getLastUpdated() { return recordedAt; }
}
