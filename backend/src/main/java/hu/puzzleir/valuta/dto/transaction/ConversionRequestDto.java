package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Konverzió request DTO (valuta-valuta csere)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversionRequestDto {

    private Long fromCurrencyId;
    private String fromCurrencyCode;

    private Long toCurrencyId;
    private String toCurrencyCode;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal fromAmount;

    @DecimalMin(value = "0", message = "A kezelési díj nem lehet negatív")
    private BigDecimal handlingFee;

    /**
     * A pénztáros által (címletezéshez) esetleg lefelé módosított cél-összeg.
     * Ha null, a rendszer a teljes forrás-fedezetből számolt maximumot használja.
     * Ha kisebb a maximumnál, a különbözet forintban visszajár az ügyfélnek.
     */
    @DecimalMin(value = "0.01", message = "A cél összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal toAmount;

    /** Ügyfél deviza-státusza (DOMESTIC = belföldi, FOREIGN = külföldi) — NGM/MNB statisztika. */
    @Pattern(regexp = "^(DOMESTIC|FOREIGN)$", message = "Érvénytelen deviza-státusz")
    private String foreignStatus;

    private String customerId;
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
    private String customerNationality;

    /** Pénzeszköz forrása — 300.000 Ft feletti tranzakciónál ajánlott (Pmt. parity) */
    private String sourceOfFunds;

    /** PEP (kiemelt közszereplő) státusz */
    private Boolean customerIsPep;

    // ============ V235 + V236: Konverzio Pmt. azonositas (HIBA #19 2026-05-19) ============
    // User-direktiva: konverzio (vetel + eladas aggregalt huf) 100k+ -> SIMPLIFIED,
    // 300k+ -> FULL azonositas. Eddig a konverzio csak customerName-t fogadott el,
    // de a Pmt. tv. szerint a konverzio EGYETLEN tranzakciokent szamit, igy a
    // teljes snapshot-set kell.

    @Size(max = 255) private String customerBirthPlace;
    private java.time.LocalDate customerBirthDate;
    @Size(max = 255) private String customerMotherName;
    @Size(max = 50)  private String customerDocumentType;
    private Boolean customerOnOwnBehalf;
    @Size(max = 255) private String customerActorName;

    // Copilot P2 (PR #695): üres-string DB CHECK violation fix.
    @Pattern(regexp = "^(CSALADTAG|KOZELI_MUNKATARS|KORMANYFO|PARLAMENTI|NAV_VEZETO|EGYEB)$",
            message = "Érvénytelen PEP minőség")
    private String customerPepKind;

    @Size(max = 255) private String customerActorBirthPlace;
    private java.time.LocalDate customerActorBirthDate;
    @Size(max = 255) private String customerActorMotherName;
    @Size(max = 100) private String customerActorNationality;
    @Size(max = 50)  private String customerActorDocumentType;
    @Size(max = 100) private String customerActorDocumentNumber;
    @Size(max = 500) private String customerActorAddress;
}
