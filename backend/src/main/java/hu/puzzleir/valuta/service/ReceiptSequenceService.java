package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.ReceiptSequence;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Bizonylat szekvencia szolgáltatás — Delphi UTOLSOBLOKKOK kompatibilis.
 *
 * Formátum: PREFIX + branchCode(3 számjegy, 0-paddelt) + sorszám(6 számjegy, 0-paddelt)
 * Példa: E001100001 (eladás, 001-es pénztár, 100001-es sorszám)
 *
 * Prefix-ek:
 *   E  = Eladás (SELL)
 *   V  = Vétel (BUY)
 *   F  = Átadás (TRANSFER_OUT)
 *   U  = Átvétel (TRANSFER_IN)
 *   FF = Forint átadás (TRANSFER_OUT ha HUF)
 *   UF = Forint átvétel (TRANSFER_IN ha HUF)
 *   K  = Konverzió (CONVERSION)
 *   W  = Western Union (WU_SEND/WU_RECEIVE → vétel/eladás számláló)
 *   M  = MoneyGram (MG_SEND/MG_RECEIVE → vétel/eladás számláló)
 *
 * Stornó: az EREDETI típus számlálójából kap új sorszámot (NEM külön S prefix).
 *
 * Legacy bizonylat szám minta: "V105007798"
 *   V   = prefix (Vétel)
 *   105 = pénztár szám (branch code, 3 jegyű)
 *   007798 = sorszám (6 jegyű, 0-paddelt)
 *
 * PESSIMISTIC LOCK: SELECT FOR UPDATE az UTOLSOBLOKKOK táblán, hogy két párhuzamos
 * tranzakció ne kaphassa meg ugyanazt a sorszámot.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptSequenceService {

    private final ReceiptSequenceRepository receiptSequenceRepository;
    private final BranchRepository branchRepository;

    /**
     * Következő bizonylat szám generálása.
     *
     * @param branchId pénztár/iroda azonosító
     * @param transactionType tranzakció típusa (meghatározza a prefixet és a számlálót)
     * @return bizonylat szám (pl. "E001100001")
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public String generateReceiptNumber(UUID branchId, TransactionType transactionType) {
        // Branch kód lekérése
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch nem található: " + branchId));

        String branchCode = extractBranchCode(branch.getCode());

        // Szekvencia lekérése PESSIMISTIC LOCK-kal
        ReceiptSequence sequence = receiptSequenceRepository.findByBranchIdForUpdate(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Bizonylat szekvencia nem található branch-hez: " + branchId
                    + ". Futtassa a V42 migrációt!"));

        // Prefix és sorszám meghatározása a típus alapján
        String prefix = getPrefix(transactionType);
        long nextSeq = incrementSequence(sequence, transactionType);

        // Mentés (a tranzakció commitjakor persist-álódik)
        receiptSequenceRepository.save(sequence);

        // Formátum: PREFIX + branchCode(3) + sorszám(6)
        String receiptNumber = String.format("%s%s%06d", prefix, branchCode, nextSeq);

        log.debug("Bizonylat szám generálva: {} (branch={}, type={})",
                receiptNumber, branchCode, transactionType);

        return receiptNumber;
    }

    /**
     * Sztornó bizonylat szám generálása.
     * Az EREDETI típus számlálójából kap sorszámot, NEM külön S prefix.
     *
     * @param branchId pénztár/iroda azonosító
     * @param originalType az eredeti tranzakció típusa
     * @return bizonylat szám (az eredeti típus prefixével)
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public String generateReversalReceiptNumber(UUID branchId, TransactionType originalType) {
        return generateReceiptNumber(branchId, originalType);
    }

    // ============ HELPER METHODS ============

    /**
     * Branch kódból 3 jegyű számot képez (0-paddelt).
     * Ha a kód numerikus → azt használja.
     * Ha nem → hash alapú 3 jegyű kód.
     */
    private String extractBranchCode(String code) {
        if (code == null || code.isBlank()) {
            return "000";
        }

        // Próbáljuk numerikusként értelmezni
        try {
            int numericCode = Integer.parseInt(code.replaceAll("[^0-9]", ""));
            return String.format("%03d", numericCode % 1000);
        } catch (NumberFormatException e) {
            // Hash-alapú fallback (stabil, determinisztikus)
            int hash = Math.abs(code.hashCode()) % 1000;
            return String.format("%03d", hash);
        }
    }

    /**
     * Tranzakció típus → bizonylat prefix mapping.
     */
    private String getPrefix(TransactionType type) {
        return switch (type) {
            case SELL -> "E";
            case BUY -> "V";
            case CONVERSION -> "K";
            case TRANSFER_OUT -> "F";
            case TRANSFER_IN -> "U";
            // Western Union: W prefix, vétel/eladás számlálót használ (lásd incrementSequence)
            case WESTERN_UNION_SEND -> "W";
            case WESTERN_UNION_RECEIVE -> "W";
            // MoneyGram: M prefix
            case MONEYGRAM_SEND -> "M";
            case MONEYGRAM_RECEIVE -> "M";
            // Egyéb szolgáltatások: X prefix
            case VIGNETTE, PHONE_TOPUP, OTHER -> "X";
            // Sztornó: SOHA nem hívódhat közvetlenül — fail-fast!
            // Használd a generateReversalReceiptNumber() metódust, ami az eredeti típust adja át.
            case REVERSAL -> throw new IllegalArgumentException(
                "REVERSAL típushoz használd a generateReversalReceiptNumber() metódust!");
        };
    }

    /**
     * A megfelelő számláló léptetése a tranzakció típusa szerint.
     */
    private long incrementSequence(ReceiptSequence sequence, TransactionType type) {
        return switch (type) {
            case SELL -> sequence.nextSellSequence();
            case BUY -> sequence.nextBuySequence();
            case CONVERSION -> sequence.nextConversionSequence(); // saját számláló — NEM az eladásé!
            case TRANSFER_OUT -> sequence.nextTransferOutSequence();
            case TRANSFER_IN -> sequence.nextTransferInSequence();
            // WU/MG: a vétel/eladás számlálóját használják (legacy kompatibilitás)
            case WESTERN_UNION_SEND, MONEYGRAM_SEND -> sequence.nextSellSequence();
            case WESTERN_UNION_RECEIVE, MONEYGRAM_RECEIVE -> sequence.nextBuySequence();
            // Egyéb: az eladás számlálóját használja (fallback)
            case VIGNETTE, PHONE_TOPUP, OTHER -> sequence.nextSellSequence();
            case REVERSAL -> throw new IllegalArgumentException(
                "REVERSAL típushoz használd a generateReversalReceiptNumber() metódust!");
        };
    }
}
