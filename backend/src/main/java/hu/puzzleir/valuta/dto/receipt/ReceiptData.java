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

    /** NAV nyugtaszám (Nyugtaszám a bizonylaton) */
    private String navReceiptNumber;

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

    /** Devizastatusz: DOMESTIC (belfoldi) / FOREIGN (kulfoldi) */
    private String foreignStatus;

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

    /** Ügyfél okmány típusa (személyi ig. / útlevél / jogosítvány) */
    private String customerDocType;

    /** Ügyfél lakcíme */
    private String customerAddress;

    /** Ügyfél anyja neve */
    private String customerMotherName;

    /** Ügyfél születési helye */
    private String customerBirthPlace;

    /** Ügyfél születési dátuma */
    private String customerBirthDate;

    /** Ügyfél állampolgársága */
    private String customerNationality;

    /** Cég teljes neve (pl. EXCLUSIVE BEST CHANGE ZRT.) */
    private String companyFullName;

    /** Cég telefonszáma */
    private String companyPhone;

    /** Cég adószáma */
    private String companyTaxNumber;

    /** Fiók/iroda kódja (pl. V105) */
    private String branchCode;

    /** Fiók/iroda címe */
    private String branchAddress;

    /** Fiók/iroda telefonszáma */
    private String branchPhone;

    /** Kerekített Ft összeg */
    private BigDecimal roundedHufAmount;

    /** Kerekítési különbözet */
    private BigDecimal roundingDiff;

    /** Plombaszám (KKTG átadás, belső átadás) */
    private String sealNumber;

    /** ÁFA-mentességi szöveg (törvényi kötelező valutaváltásnál) */
    @Builder.Default
    private String vatExemptionText = "Szj - 67.13.10.0\nAdómentes  a szolgáltatás nyújtása a 2007\nM.Á.A. evi CXVII tv. 86 § e) alapján\nmentes az adó alól";

    /** Bizonylat sorok (tetszőleges extra sorok) */
    @Builder.Default
    private List<ReceiptLineData> lines = new ArrayList<>();

    /** QR kód tartalom (bizonylat azonosító) */
    private String qrCode;

    /** Aláírás hely szöveg */
    @Builder.Default
    private String signatureLine = "Aláírás: ____________________";

    // ============ KIEGÉSZÍTŐ BIZONYLAT MEZŐK ============

    /**
     * Orosz/fehérorosz ügyfél (ISO='RU' vagy 'BY') — kötelező nyilatkozat blokk.
     * Ha igaz, a bizonylaton megjelenik a FATF/EU szankciós nyilatkozat.
     */
    @Builder.Default
    private Boolean requiresRuByDeclaration = false;

    /**
     * Jogi személy (cég) nyilatkozat blokk szükséges-e.
     * Ha igaz, megjelenik: cégnév, székhely, okiratszám, képviselő adatai.
     */
    @Builder.Default
    private Boolean requiresLegalEntityBlock = false;

    /** Jogi személy képviselőjének neve */
    private String legalRepresentativeName;

    /** Jogi személy okiratszáma */
    private String legalDeedNumber;

    /**
     * Kedvezményes árfolyam melléklet szükséges-e.
     * Ha igaz, a bizonylat tartalmaz egy külön mellékletet a kedvezményes árfolyamról.
     */
    @Builder.Default
    private Boolean hasDiscountedRate = false;

    /** Normál (listaáras) árfolyam (összehasonlításhoz a mellékletben) */
    private java.math.BigDecimal standardRate;

    /**
     * Másolat nyomtatás indoka.
     * Ha nem null, a bizonylat MÁSOLAT fejléccel és ezzel az indokkal jelenik meg.
     */
    private String copyReason;

    /**
     * Magyar + angol kétnyelvű tételsorok engedélyezve.
     */
    @Builder.Default
    private Boolean bilingualItems = false;

    // ============ PEP ÉS JOGCÍM NYILATKOZAT (G3-G4 Legacy Gap Fix) ============

    /**
     * PEP (kiemelt közszereplő) nyilatkozat szükséges-e.
     * Legacy: BLOKNYOM/KozszerepNyilatkozat — 300k+ tranzakciónál jogszabályi kötelezettség.
     */
    @Builder.Default
    private Boolean requiresPepDeclaration = false;

    /**
     * PEP státusz szöveg: "Nem közszereplő" vagy "Az ügyfél kiemelt közszereplő".
     */
    private String pepStatusText;

    /**
     * Jogcím nyilatkozat szükséges-e.
     * Legacy: BLOKNYOM/Jogcimnyilatkozat — 300k+ tranzakciónál kötelező.
     * Tartalma: "Büntetőjogi felelősségem tudatában nyilatkozom..."
     */
    @Builder.Default
    private Boolean requiresSourceDeclaration = false;

    /**
     * Pénzeszköz forrása (pl. "munkabér", "megtakarítás", "üzleti bevétel").
     * Legacy: _forras mező.
     */
    private String sourceOfFunds;

    /**
     * Ügyfél típusa a nyilatkozatban: true = jogi személy, false = természetes személy.
     * A jogcím nyilatkozat szövege eltérő a két típusnál.
     */
    @Builder.Default
    private Boolean isLegalEntityCustomer = false;

    /**
     * Jogi személy neve (jogcím nyilatkozatban: "XY nevében bonyolítom").
     */
    private String legalEntityName;

    /**
     * Bizonylat sor adat
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReceiptLineData {
        private String label;
        /** Opcionális angol felirat kétnyelvű módban */
        private String labelEn;
        private String value;
    }
}
