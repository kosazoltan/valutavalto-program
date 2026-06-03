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
 * Vétel request DTO
 * (Ügyfél valutát ad el, cég HUF-ot fizet)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BuyRequestDto {

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

    // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) — szerver autoritatív (HandlingFeeOverrideService).
    private hu.puzzleir.valuta.entity.HandlingFeeOverrideType handlingFeeOverrideType;
    private hu.puzzleir.valuta.entity.HandlingFeeOverrideReason handlingFeeOverrideReason;
    @Size(max = 100, message = "A kártyaszám max 100 karakter")
    private String customerCardNumber;

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

    /**
     * A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum típusa az 50M Ft feletti ügylet
     * szerver-oldali validációjához. Elfogadható: MAGANOKIRAT_KOZJEGYZO / MAGANOKIRAT_UGYVED / BANK_SZLIP
     * (KET_TANU TILOS). A tényleges blokkolást az AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT flag vezérli.
     */
    @Size(max = 50, message = "Forrás-dokumentum típus max 50 karakter")
    private String sourceOfFundsDocType;

    /** A3 (Pmt. 50M): banki bizonylat (szlip) kiállítási dátuma — max. 3 év a tranzakcióhoz képest. */
    private java.time.LocalDate sourceOfFundsDocDate;

    /** AML felsővezetői jóváhagyás (Pmt. 14/A.§(4), MNB 14/2025 V.2.6): a POS-on jóváhagyó vezető workerId-ja. */
    private Long approverWorkerId;

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

    // ============ V235: PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19) ============

    /**
     * HIBA #15: PEP minoseg. Ha customerIsPep=TRUE kotelezo. Ervenyes ertekek:
     * CSALADTAG, KOZELI_MUNKATARS, KORMANYFO, PARLAMENTI, NAV_VEZETO, EGYEB.
     */
    // Copilot P2 (PR #695): a `?$` (üres group) miatt üres string is átment a
    // validáción, de a V235 DB CHECK csak NULL-t vagy ervenyes enumot fogad el
    // → runtime DB constraint violation. Most: NEM-üres karakter → muszáj enum.
    @Pattern(regexp = "^(CSALADTAG|KOZELI_MUNKATARS|KORMANYFO|PARLAMENTI|NAV_VEZETO|EGYEB)$",
            message = "Érvénytelen PEP minőség — csak CSALADTAG/KOZELI_MUNKATARS/KORMANYFO/PARLAMENTI/NAV_VEZETO/EGYEB engedélyezett")
    private String customerPepKind;

    /** HIBA #17: actor (kepviselt fel) teljes azonositasa, ha customerOnOwnBehalf=FALSE. */
    @Size(max = 255) private String customerActorBirthPlace;
    private java.time.LocalDate customerActorBirthDate;
    @Size(max = 255) private String customerActorMotherName;
    @Size(max = 100) private String customerActorNationality;
    @Size(max = 50)  private String customerActorDocumentType;
    @Size(max = 100) private String customerActorDocumentNumber;
    @Size(max = 500) private String customerActorAddress;

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
