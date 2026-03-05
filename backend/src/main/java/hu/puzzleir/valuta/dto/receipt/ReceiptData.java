package hu.puzzleir.valuta.dto.receipt;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Bizonylat adatstruktúra - nyomtatásra és PDF generálásra.
 *
 * Bizonylat számozási szabály:
 * - E-YYMMDD-XXXX: Eladási bizonylat (valuta eladás ügyfélnek)
 * - V-YYMMDD-XXXX: Vételi bizonylat (valuta vásárlás ügyféltől)
 * - A-YYMMDD-XXXX: Átvezetési bizonylat (irodák közti)
 * - S-YYMMDD-XXXX: Sztornó bizonylat
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptData {

    /** Bizonylat szám (E/V/A/S prefix + YYMMDD + sorszám) */
    private String receiptNumber;

    /** Bizonylat típus: SELL, BUY, TRANSFER, STORNO, CLOSING */
    private String receiptType;

    /** Cég neve */
    private String companyName;

    /** Fiók/iroda neve */
    private String branchName;

    /** Pénztáros neve */
    private String workerName;

    /** Bizonylat dátuma */
    private LocalDateTime date;

    /** Valuta kód */
    private String currencyCode;

    /** Deviza összeg */
    private BigDecimal foreignAmount;

    /** Alkalmazott árfolyam */
    private BigDecimal rate;

    /** HUF összeg */
    private BigDecimal hufAmount;

    /** Kezelési díj */
    @Builder.Default
    private BigDecimal handlingFee = BigDecimal.ZERO;

    /** Ügyfél neve */
    private String customerName;

    /** Ügyfél okmányszáma */
    private String customerIdNumber;

    /** Bizonylat sorok (tetszőleges extra sorok) */
    @Builder.Default
    private List<ReceiptLineData> lines = new ArrayList<>();

    /** QR kód tartalom (bizonylat azonosító) */
    private String qrCode;

    /** Aláírás hely szöveg */
    @Builder.Default
    private String signatureLine = "Aláírás: ____________________";

    /**
     * Bizonylat sor adat
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReceiptLineData {
        private String label;
        private String value;
    }
}
