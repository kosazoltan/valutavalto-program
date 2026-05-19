package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Átlag árfolyam riport DTO — legacy ATLAGARF modul (46K, 71f) parity.
 *
 * <p>v2.5.66+ Sprint A P2.5: súlyozott átlagárfolyam időszak + iroda + valuta szerint.
 * A súlyozás a tranzakciók HUF összegével történik (nagy tranzakció nagyobb súlyú).</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AverageRateReportDto {

    /** Időszak kezdete. */
    private LocalDate periodStart;

    /** Időszak vége. */
    private LocalDate periodEnd;

    /** Iroda UUID-ja (null = összes irodát aggregálja). */
    private UUID branchId;

    /** Iroda kódja megjelenítéshez. */
    private String branchCode;

    /** Valuta ID. */
    private Long currencyId;

    /** Valuta kódja (HUF, EUR, USD, ...). */
    private String currencyCode;

    /** Tranzakciók típusa: BUY / SELL / null=mind. */
    private String transactionType;

    /** Tranzakciók darabszáma az időszakban. */
    private Long transactionCount;

    /** Összes deviza-mennyiség. */
    private BigDecimal totalCurrencyAmount;

    /** Összes HUF egyenérték (díj nélkül, a tranzakciós nominális). */
    private BigDecimal totalHufAmount;

    /**
     * Súlyozott átlagárfolyam: SUM(huf_amount) / SUM(currency_amount).
     *
     * <p>Ez **NEM** a tranzakciós exchange_rate-ek számtani átlaga (az torz lenne,
     * mert kis és nagy tranzakciók ugyanúgy súlyoznának). A HUF-súlyozott átlag
     * a valódi pénzügyi átlagárfolyam, amit a Cégbíróság, NAV és üzleti vezetés vár.</p>
     */
    private BigDecimal weightedAverageRate;
}
