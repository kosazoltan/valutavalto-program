package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Eladás request DTO
 * (Ügyfél HUF-ot ad, cég valutát ad)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SellRequestDto {

    private Long currencyId;

    /** Valuta kód (pl. EUR, USD) — alternatíva a currencyId-hoz */
    private String currencyCode;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal currencyAmount;

    @DecimalMin(value = "0", message = "A kedvezmény nem lehet negatív")
    private BigDecimal discountPercent;

    @DecimalMin(value = "0", message = "A kezelési díj nem lehet negatív")
    private BigDecimal handlingFee;

    @DecimalMin(value = "0.0001", message = "Az egyedi árfolyamnak pozitívnak kell lennie")
    private BigDecimal customExchangeRate;

    // Ügyfél adatok (300.000 Ft felett kötelező)
    private String customerId;
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
    private String customerNationality;

    /** Pénzeszköz forrása — 300k+ Ft tranzakciónál kötelező (Legacy: Jogcimnyilatkozat) */
    @Size(max = 500, message = "Pénzeszköz forrás max 500 karakter")
    private String sourceOfFunds;

    /** Ügyfél PEP (kiemelt közszereplő) státusza */
    private Boolean customerIsPep;

    // ============ V229: Pmt. azonositasi snapshot mezok (HIBA #5+#7+#8 2026-05-15) ============
    @Size(max = 255) private String customerBirthPlace;
    private java.time.LocalDate customerBirthDate;
    @Size(max = 255) private String customerMotherName;
    @Size(max = 50)  private String customerDocumentType;
    /** 300k+ JOGCIM nyilatkozat: TRUE=sajat, FALSE=mas nevben (akkor customerActorName kotelezo) */
    private Boolean customerOnOwnBehalf;
    @Size(max = 255) private String customerActorName;

    private String notes;

    /** Penztarosi sav: egyedi arfolyam 400k+ Ft felett (napi 5x limit) */
    private Boolean cashierCustomRate;

    /**
     * Devizastatusz: DOMESTIC (belfoldi) / FOREIGN (kulfoldi).
     * Case-insensitive, a service normalizalja uppercase-re mentes elott.
     */
    @Pattern(regexp = "^(?i)(DOMESTIC|FOREIGN)?$",
            message = "Érvénytelen devizastátusz — csak DOMESTIC vagy FOREIGN engedélyezett")
    private String foreignStatus;

    /**
     * Multi-line bizonylat tetelsorai (max 6 sor).
     * Ha megadva, a currencyId/currencyCode/currencyAmount mezok figyelmen kivul maradnak
     * — a fejlec a sorok aggregaltjabol szamitodik.
     */
    @Valid
    @Size(max = 6, message = "Egy bizonylaton maximum 6 tetelsor lehet (BLOKKTETEL limit)")
    private List<TransactionLineRequestDto> lines;
}
