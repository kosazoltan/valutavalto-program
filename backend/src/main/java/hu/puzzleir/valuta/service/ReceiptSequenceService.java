package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.ReceiptSequence;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
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
    private final TransactionRepository transactionRepository;

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

        // Szekvencia lekérése PESSIMISTIC LOCK-kal, vagy auto-create ha nem létezik
        ReceiptSequence sequence = receiptSequenceRepository.findByBranchIdForUpdate(branchId)
                .orElseGet(() -> {
                    log.info("Bizonylat szekvencia auto-create branch-hez: {}", branchId);
                    ReceiptSequence newSeq = ReceiptSequence.builder()
                            .branchId(branchId)
                            .build();
                    return receiptSequenceRepository.save(newSeq);
                });

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

    /**
     * Bizonylat folytonossági ellenőrzés (gap detektálás) napzáráskor.
     * Legacy: NAPZAR.DLL — bizonylat gap check (CHECKLST.DLL).
     *
     * A metódus az iroda adott napi tranzakcióit prefix szerint csoportosítja,
     * majd minden prefixnél megkeresi a hiányzó sorszámokat a szekvenciában.
     *
     * @param branchId    Iroda ID
     * @param closingDate Vizsgált nap
     * @return Hiányzó bizonylat számok listája (pl. ["V001000042", "E001000017"])
     */
    @Transactional(readOnly = true)
    public List<String> checkReceiptContinuity(UUID branchId, LocalDate closingDate) {
        List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, closingDate);

        if (transactions.isEmpty()) {
            log.debug("Bizonylat gap check: nincs tranzakció: branchId={}, date={}", branchId, closingDate);
            return List.of();
        }

        // Prefix → (branchCodePart → TreeMap<sorszám, bizonylat>) csoportosítás
        // Bizonylat formátum: PREFIX(1-2 char) + branchCode(3) + sorszám(6)
        Map<String, TreeMap<Long, String>> prefixGroups = new TreeMap<>();

        for (Transaction tx : transactions) {
            String receipt = tx.getReceiptNumber();
            if (receipt == null || receipt.length() < 4) {
                continue;
            }

            // Prefix: első nem-numerikus karakter(ek), majd branchCode (3), majd sorszám (6)
            // FF és UF kétjegyű prefix, többi 1 jegyű
            String prefix;
            String numericPart;
            if (receipt.length() >= 2 && !Character.isDigit(receipt.charAt(1))
                    && receipt.charAt(0) != receipt.charAt(1)) {
                // Kétjegyű prefix (FF, UF)
                prefix = receipt.substring(0, 2);
                numericPart = receipt.substring(2);
            } else {
                // Egyjegyű prefix
                prefix = receipt.substring(0, 1);
                numericPart = receipt.substring(1);
            }

            // numericPart = branchCode(3) + sorszám(6) → sorszám az utolsó 6 jegy
            if (numericPart.length() < 6) {
                continue;
            }
            String seqStr = numericPart.substring(numericPart.length() - 6);
            try {
                long seq = Long.parseLong(seqStr);
                prefixGroups.computeIfAbsent(prefix, k -> new TreeMap<>()).put(seq, receipt);
            } catch (NumberFormatException e) {
                log.warn("Bizonylat gap check: nem értelmezhető sorszám: {}", receipt);
            }
        }

        List<String> gaps = new ArrayList<>();

        for (Map.Entry<String, TreeMap<Long, String>> entry : prefixGroups.entrySet()) {
            String prefix = entry.getKey();
            TreeMap<Long, String> seqMap = entry.getValue();

            if (seqMap.size() < 2) {
                continue; // Egyetlen bizonylat — nem lehet gap
            }

            // BranchCode kinyerése az első bizonylatból
            String firstReceipt = seqMap.firstEntry().getValue();
            String branchCodePart = (prefix.length() == 2)
                ? firstReceipt.substring(2, 5)
                : firstReceipt.substring(1, 4);

            long prev = seqMap.firstKey();
            for (long seq : seqMap.tailMap(prev + 1).keySet()) {
                // Ha gap van, minden hiányzó sorszámot felsorolunk (max 100 db/prefix)
                for (long missing = prev + 1; missing < seq && gaps.size() < 100; missing++) {
                    String missingReceipt = String.format("%s%s%06d", prefix, branchCodePart, missing);
                    gaps.add(missingReceipt);
                    log.warn("Bizonylat gap: hiányzó bizonylat szám: {}", missingReceipt);
                }
                prev = seq;
            }
        }

        if (!gaps.isEmpty()) {
            log.warn("Bizonylat gap check: {} hiányzó bizonylat találva: branchId={}, date={}",
                gaps.size(), branchId, closingDate);
        } else {
            log.info("Bizonylat gap check: nincs hiány: branchId={}, date={}", branchId, closingDate);
        }

        return gaps;
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
            // Részleges visszatérítés: PR prefix
            case PARTIAL_REFUND -> "PR";
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
            // Részleges visszatérítés: eladás számlálóját használja
            case PARTIAL_REFUND -> sequence.nextSellSequence();
            case REVERSAL -> throw new IllegalArgumentException(
                "REVERSAL típushoz használd a generateReversalReceiptNumber() metódust!");
        };
    }
}
