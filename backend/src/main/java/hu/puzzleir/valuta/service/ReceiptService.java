package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ReceiptRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * v2.3.48 (B7 audit fix): Bizonylatok lista a Transaction tablabol synthesizalva.
 *
 * Audit B7: a /api/v1/receipts endpoint korabban URES listat adott vissza,
 * mert a Receipt tablat (entity.Receipt) NEM frissitette a TransactionService
 * BUY/SELL flow-ja. Eredmény: 12+ tranzakcio a /transactions listán, DE
 * 0 bizonylat a /receipts oldalon → "Bizonylat-újranyomtatás (legacy
 * ReprintGomb) NEM működik" üzleti hatás.
 *
 * Iparági pattern: "Read-through view layer" — a Receipt entity egy denormalized
 * view a Transaction-rol. A list() endpoint synthesize Receipt-shape DTO-kat
 * a Transaction-bol, ha a Receipt tabla ures. A print() endpoint lazily
 * MATERIALIZE-elja a Receipt rekordot, ha a felhasznalo nyomtatja.
 *
 * UUID encoding: a synthesized Receipt-eken a UUID magasi 64 bit-je 0,
 * az alacsoni 64 bit a Transaction.id (Long). Igy a print() endpoint
 * detektalhatja a synthesized UUID-t es decode-olhatja a Transaction.id-t.
 *  - synthesized: `new UUID(0L, transactionId)`
 *  - real Receipt: random UUID (UUID v4) — magasi 64 bit nem 0 a generaalt v4 ID-knel
 *
 * Limit: top 500 most recent transaction (a frontend ReceiptPage NEM paginal).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptService {

    private final ReceiptRepository repo;
    private final TransactionRepository transactionRepository;

    /** v2.3.48: receipt list limit a frontend ReceiptPage NEM-paginalt UI-ahoz. */
    private static final int RECEIPT_LIST_LIMIT = 500;

    /**
     * Receipt list endpoint — visszaad real Receipt rekordokat ES synthesized
     * Receipt-eket a Transaction-bol (multi-tenant companyId szurt).
     *
     * @param transactionId opcionalis filter — ha megadva, csak az adott transaction Receipt-jeit
     * @return Receipt lista (list-merge: real + synthesized)
     */
    public List<Receipt> list(UUID transactionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (transactionId != null) {
            return repo.findByCompanyIdAndTransactionId(companyId, transactionId);
        }

        // Real Receipt rekordok a DB-bol
        List<Receipt> realReceipts = repo.findAllByCompanyId(companyId);

        // Mely Transaction-ok vannak mar materializalva real Receipt-ben?
        // A materializaltakat az `id` mezo synthesizedUuid alakjarol ismerjuk fel
        // (a print() lazy-materialize a Receipt.id-jat synthesizedUuid-ra allitja).
        Set<Long> materializedTxIds = new HashSet<>();
        for (Receipt r : realReceipts) {
            if (r.getId() != null && isSynthesizedUuid(r.getId())) {
                materializedTxIds.add(decodeTransactionId(r.getId()));
            }
        }

        // Synthesized Receipt-ek a Transaction-bol — kihagyva a mar materializaltakat
        List<Transaction> txList = transactionRepository.findReceiptListByCompanyId(
                companyId, PageRequest.of(0, RECEIPT_LIST_LIMIT));

        List<Receipt> synthesized = new ArrayList<>();
        for (Transaction tx : txList) {
            if (!materializedTxIds.contains(tx.getId())) {
                synthesized.add(synthesizeReceipt(tx));
            }
        }

        List<Receipt> result = new ArrayList<>(realReceipts.size() + synthesized.size());
        result.addAll(realReceipts);
        result.addAll(synthesized);
        return result;
    }

    public Receipt getById(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Real Receipt eloszor — multi-tenant safe lookup
        Receipt existing = repo.findById(id).orElse(null);
        if (existing != null) {
            // v2.3.50 (Sourcery #313 P1 SECURITY): companyId verify also for real receipts
            if (existing.getCompanyId() != null && !companyId.equals(existing.getCompanyId())) {
                throw new ResourceNotFoundException("Bizonylat nem található: " + id);
            }
            return existing;
        }
        // Synthesized: decode tx.id-t es synthesize a Transaction-bol
        if (isSynthesizedUuid(id)) {
            Long txId = decodeTransactionId(id);
            Transaction tx = transactionRepository.findById(txId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Bizonylat nem található (synthesized): " + id));
            // Multi-tenant verify
            if (tx.getCompany() == null || !companyId.equals(tx.getCompany().getId())) {
                throw new ResourceNotFoundException("Bizonylat nem található: " + id);
            }
            return synthesizeReceipt(tx);
        }
        throw new ResourceNotFoundException("Bizonylat nem található: " + id);
    }

    /**
     * Print mark — materializaalja a Receipt rekordot, ha synthesized UUID,
     * majd isPrinted=true-ra allitja.
     *
     * v2.3.50 (Sourcery #313 P1 SECURITY fix): companyId verify a REAL Receipt
     * eseten is — korabban csak a synthesized UUID-ra volt multi-tenant check,
     * REAL Receipt eseten egy mas tenant UUID-javal meg lehetett "fliplelni"
     * az isPrinted flag-et (cross-company tenant data corruption).
     */
    @Transactional(rollbackFor = Exception.class)
    public Receipt print(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Real Receipt eseten csak isPrinted update — DE multi-tenant verify
        Receipt existing = repo.findById(id).orElse(null);
        if (existing != null) {
            // v2.3.50 P1 SECURITY: cross-company print attempt rejected
            if (existing.getCompanyId() != null && !companyId.equals(existing.getCompanyId())) {
                log.warn("v2.3.50 P1 SECURITY: cross-company print attempt rejected — "
                        + "receipt.id={}, receipt.companyId={}, current.companyId={}",
                        id, existing.getCompanyId(), companyId);
                throw new ResourceNotFoundException("Bizonylat nem található: " + id);
            }
            existing.setIsPrinted(true);
            existing.setPrintedAt(LocalDateTime.now());
            return repo.save(existing);
        }

        // Synthesized: materialize + mark printed
        if (isSynthesizedUuid(id)) {
            Long txId = decodeTransactionId(id);
            Transaction tx = transactionRepository.findById(txId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Bizonylat nem található (synthesized print): " + id));
            // Multi-tenant verify
            if (tx.getCompany() == null || !companyId.equals(tx.getCompany().getId())) {
                throw new ResourceNotFoundException("Bizonylat nem található: " + id);
            }
            Receipt newReceipt = Receipt.builder()
                    .id(id)
                    .companyId(tx.getCompany().getId())
                    .receiptNumber(tx.getReceiptNumber())
                    .receiptType(tx.getTransactionType() != null
                            ? tx.getTransactionType().name() : "UNKNOWN")
                    .issueDate(tx.getTransactionDate())
                    .isPrinted(true)
                    .printedAt(LocalDateTime.now())
                    .build();
            log.info("v2.3.48 B7: lazy-materialize Receipt for tx={}, receiptNumber={}",
                    txId, tx.getReceiptNumber());
            return repo.save(newReceipt);
        }
        throw new ResourceNotFoundException("Bizonylat nem található: " + id);
    }

    // === Helpers ===

    /**
     * v2.3.48 B7: synthesized Receipt UUID encoding.
     * Magasi 64 bit = 0, alacsoni 64 bit = transaction.id (Long).
     * Real UUID v4 magasi bit-je nem nulla — igy detektalhato.
     */
    private static boolean isSynthesizedUuid(UUID uuid) {
        return uuid.getMostSignificantBits() == 0L;
    }

    private static Long decodeTransactionId(UUID synthesizedUuid) {
        return synthesizedUuid.getLeastSignificantBits();
    }

    private static UUID encodeTransactionId(Long transactionId) {
        return new UUID(0L, transactionId);
    }

    private Receipt synthesizeReceipt(Transaction tx) {
        return Receipt.builder()
                .id(encodeTransactionId(tx.getId()))
                .companyId(tx.getCompany() != null ? tx.getCompany().getId() : null)
                .receiptNumber(tx.getReceiptNumber())
                .receiptType(tx.getTransactionType() != null
                        ? tx.getTransactionType().name() : "UNKNOWN")
                .issueDate(tx.getTransactionDate())
                .isPrinted(false)
                .build();
    }

    /** Test-only — segit egy Transaction-bol synthesized UUID-t generaalni. */
    @SuppressWarnings("unused")
    static UUID synthesizedUuidFor(long transactionId) {
        return new UUID(0L, transactionId);
    }
}
