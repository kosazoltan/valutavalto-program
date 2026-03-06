package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Bizonylat sorszám szekvencia — UTOLSOBLOKKOK tábla.
 *
 * Legacy: UTOLSOBLOKKOK tábla a Delphi rendszerben.
 * Típusonként tárolja az utolsó kiadott bizonylat sorszámot.
 * A sorszámok 100000-tól indulnak és 999990 elérésekor wrap-olnak 100000-re.
 *
 * Formátum: PREFIX + pénztárkód(3) + sorszám(6)
 * Prefix-ek: E=eladás, V=vétel, F=átadás, U=átvétel, FF=forint átadás, UF=forint átvétel
 */
@Entity
@Table(name = "receipt_sequence", indexes = {
    @Index(name = "idx_receipt_seq_branch", columnList = "branch_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptSequence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Pénztár/iroda azonosítója
     */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /**
     * Utolsó eladás bizonylat sorszám
     * Legacy: lastSellReceipt — E prefix
     */
    @Column(name = "last_sell_receipt", nullable = false)
    @Builder.Default
    private Long lastSellReceipt = 100000L;

    /**
     * Utolsó vétel bizonylat sorszám
     * Legacy: lastBuyReceipt — V prefix
     */
    @Column(name = "last_buy_receipt", nullable = false)
    @Builder.Default
    private Long lastBuyReceipt = 100000L;

    /**
     * Utolsó átadás bizonylat sorszám
     * Legacy: lastTransferOutReceipt — F prefix
     */
    @Column(name = "last_transfer_out_receipt", nullable = false)
    @Builder.Default
    private Long lastTransferOutReceipt = 100000L;

    /**
     * Utolsó átvétel bizonylat sorszám
     * Legacy: lastTransferInReceipt — U prefix
     */
    @Column(name = "last_transfer_in_receipt", nullable = false)
    @Builder.Default
    private Long lastTransferInReceipt = 100000L;

    /**
     * Utolsó forint átadás bizonylat sorszám
     * Legacy: lastForintTransferOutReceipt — FF prefix
     */
    @Column(name = "last_forint_transfer_out_receipt", nullable = false)
    @Builder.Default
    private Long lastForintTransferOutReceipt = 100000L;

    /**
     * Utolsó forint átvétel bizonylat sorszám
     * Legacy: lastForintTransferInReceipt — UF prefix
     */
    @Column(name = "last_forint_transfer_in_receipt", nullable = false)
    @Builder.Default
    private Long lastForintTransferInReceipt = 100000L;

    /**
     * Utolsó konverzió bizonylat sorszám
     * K prefix — saját számláló (NEM az eladás számlálója!)
     */
    @Column(name = "last_conversion_receipt", nullable = false)
    @Builder.Default
    private Long lastConversionReceipt = 100000L;

    // ============ SORSZÁM LÉPTETÉS ============

    private static final long MIN_SEQUENCE = 100000L;
    private static final long MAX_SEQUENCE = 999990L;

    /**
     * Sorszám léptetés wrap-pel.
     * Ha eléri 999990-et, visszaugrik 100000-re.
     */
    private static long incrementWithWrap(long current) {
        long next = current + 1;
        return next > MAX_SEQUENCE ? MIN_SEQUENCE : next;
    }

    /**
     * Következő eladás sorszám lekérése és léptetése.
     */
    public long nextSellSequence() {
        lastSellReceipt = incrementWithWrap(lastSellReceipt);
        return lastSellReceipt;
    }

    /**
     * Következő vétel sorszám lekérése és léptetése.
     */
    public long nextBuySequence() {
        lastBuyReceipt = incrementWithWrap(lastBuyReceipt);
        return lastBuyReceipt;
    }

    /**
     * Következő átadás sorszám lekérése és léptetése.
     */
    public long nextTransferOutSequence() {
        lastTransferOutReceipt = incrementWithWrap(lastTransferOutReceipt);
        return lastTransferOutReceipt;
    }

    /**
     * Következő átvétel sorszám lekérése és léptetése.
     */
    public long nextTransferInSequence() {
        lastTransferInReceipt = incrementWithWrap(lastTransferInReceipt);
        return lastTransferInReceipt;
    }

    /**
     * Következő forint átadás sorszám lekérése és léptetése.
     */
    public long nextForintTransferOutSequence() {
        lastForintTransferOutReceipt = incrementWithWrap(lastForintTransferOutReceipt);
        return lastForintTransferOutReceipt;
    }

    /**
     * Következő forint átvétel sorszám lekérése és léptetése.
     */
    public long nextForintTransferInSequence() {
        lastForintTransferInReceipt = incrementWithWrap(lastForintTransferInReceipt);
        return lastForintTransferInReceipt;
    }

    /**
     * Következő konverzió sorszám lekérése és léptetése.
     * Saját számláló — NEM az eladás számlálója!
     */
    public long nextConversionSequence() {
        lastConversionReceipt = incrementWithWrap(lastConversionReceipt);
        return lastConversionReceipt;
    }
}
