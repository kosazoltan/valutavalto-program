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
     * v2.3.54 (Sourcery #318 P3): enum a tenant-guard log-operation-jenek
     * (typo-prevention + stable log values across versions).
     */
    enum ReceiptOperation {
        GET_BY_ID, PRINT
    }

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

        // EXCMD b5b (FR-BSZUR-02 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő):
        // a REAL Receipt-eket a kapcsolt Transaction-ből dúsítjuk customerName + hufAmount
        // @Transient mezőkkel. N+1 ELKERÜLÉSE: a real receipt-ek transactionId-jait EGY
        // batch query-ben töltjük be (findAllById), majd id→Transaction map-ből töltjük.
        // A synthesized Receipt-ek már dúsítva vannak (synthesizeReceipt kézben tartja a tx-et).
        enrichRealReceipts(realReceipts, companyId);

        List<Receipt> result = new ArrayList<>(realReceipts.size() + synthesized.size());
        result.addAll(realReceipts);
        result.addAll(synthesized);
        return result;
    }

    /**
     * EXCMD b5b: REAL Receipt-ek dúsítása customerName + hufAmount @Transient mezőkkel
     * a kapcsolt Transaction-ből. N+1 ELKERÜLÉS: az összes transactionId-t EGY
     * {@code findAllById} batch query-vel töltjük, majd id→Transaction map-ből osztjuk ki.
     *
     * <p>Defenzív: ha egy real receipt-nek nincs transactionId-ja VAGY a Transaction nem
     * található, a customerName/hufAmount null marad (a UI ilyenkor "—"-t mutat).</p>
     *
     * <p>DEFER (jövő increment): FR-BSZUR-05 "ENGEDÉLYEZŐ" (approver neve/beosztása) a
     * TransactionAmlApproval táblával való JOIN-t igényel — ez NEM ennek az increment-nek
     * a tárgya. Itt csak a 10M Ft küszöb-jelölőhöz szükséges hufAmount kerül kiosztásra.</p>
     */
    private void enrichRealReceipts(List<Receipt> realReceipts, UUID companyId) {
        Set<Long> txIds = new HashSet<>();
        for (Receipt r : realReceipts) {
            Long txId = resolveTransactionId(r);
            if (txId != null) {
                txIds.add(txId);
            }
        }
        if (txIds.isEmpty()) {
            return;
        }
        // Multi-tenant + OSIV-off safe (Codex P1+P2): a company-szűrés a QUERY-ben történik
        // (findAllByIdInAndCompanyId), NEM Java-ban a detached tx.getCompany() dereferálásával.
        // Ezzel (1) más cég tranzakciója nem kerül vissza (nincs ügyfél-név/összeg leak), és
        // (2) nem dobhat LazyInitializationException-t a lazy company-asszociáció a tranzakción
        // kívül (list() nem @Transactional, spring.jpa.open-in-view=false). Csak skalár
        // mezőket olvasunk (customerName, hufAmount), amelyeket a SELECT t betölt.
        java.util.Map<Long, Transaction> txById = new java.util.HashMap<>();
        for (Transaction tx : transactionRepository.findAllByIdInAndCompanyId(txIds, companyId)) {
            txById.put(tx.getId(), tx);
        }
        for (Receipt r : realReceipts) {
            Long txId = resolveTransactionId(r);
            if (txId == null) {
                continue;
            }
            Transaction tx = txById.get(txId);
            if (tx != null) {
                r.setCustomerName(tx.getCustomerName());
                r.setHufAmount(tx.getHufAmount());
            }
        }
    }

    /**
     * A real Receipt-hez tartozó Transaction.id (Long) feloldása, defenzíven.
     *
     * <p>A jelenlegi materialize-flow (print()) a receipt {@code id}-ját synthesizedUuid-ra
     * állítja (low 64 bit = Transaction.id), a {@code transactionId} oszlopot pedig null-on
     * hagyja. Ezért elsődlegesen a synthesizedUuid {@code id}-ból dekódolunk (ez egyezik a
     * list() materializált-detektálásával), és tartalékként a {@code transactionId} oszlopot
     * is megnézzük, ha az synthesizedUuid-ként van kódolva. Ha egyik sem értelmezhető → null
     * (a customerName/hufAmount null marad).</p>
     */
    private static Long resolveTransactionId(Receipt r) {
        if (r.getId() != null && isSynthesizedUuid(r.getId())) {
            return decodeTransactionId(r.getId());
        }
        UUID txUuid = r.getTransactionId();
        if (txUuid != null && isSynthesizedUuid(txUuid)) {
            return decodeTransactionId(txUuid);
        }
        return null;
    }

    public Receipt getById(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Real Receipt eloszor — multi-tenant safe lookup
        Receipt existing = repo.findById(id).orElse(null);
        if (existing != null) {
            assertOwnedByCompany(existing, companyId, id, ReceiptOperation.GET_BY_ID);
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
     * Multi-tenant safety (v2.3.50 P1 + v2.3.53 Codex P1):
     * - REAL Receipt path: assertOwnedByCompany() verify — DENY if company_id null OR mismatch
     * - SYNTHESIZED path: tx.company.id verify
     *
     * Fail-loud: orphan Receipt (company_id=null) is also DENIED, NOT bypass-ed.
     */
    @Transactional(rollbackFor = Exception.class)
    public Receipt print(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Real Receipt eseten csak isPrinted update — DE multi-tenant verify
        Receipt existing = repo.findById(id).orElse(null);
        if (existing != null) {
            assertOwnedByCompany(existing, companyId, id, ReceiptOperation.PRINT);
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
     * Multi-tenant Receipt ownership guard.
     *
     * Fail-loud: orphan Receipt (companyId == null) is REJECTED, NEM bypass-eljuk
     * (Codex P1 #315 finding — null-companyId tenant escape).
     *
     * Centralizalt validation, igy a getById/print divergencia kizart
     * (Sourcery #315 P3 finding).
     *
     * v2.3.54 (Sourcery #318 P3): operation enum (typo prevention) + redacted log
     * (NEM logoljuk a teljes companyId/receiptId-t shared infrastructure-on,
     * cross-tenant identifier leakage minimization).
     *
     * @param receipt the Receipt to check
     * @param currentCompanyId the current authenticated user's company
     * @param receiptId the receipt id (for log + exception message)
     * @param operation enum operation name for audit log
     * @throws ResourceNotFoundException if cross-tenant or null-tenant
     */
    private void assertOwnedByCompany(Receipt receipt, UUID currentCompanyId,
                                      UUID receiptId, ReceiptOperation operation) {
        UUID receiptCompanyId = receipt.getCompanyId();
        if (receiptCompanyId == null || !currentCompanyId.equals(receiptCompanyId)) {
            // [TENANT_GUARD] standardized log code — redacted: csak az operation
            // es a "denied" outcome szerepel, NEM a tenant-identifier-eket. Ha
            // bovebb diagnosis kell, DEBUG szinten lehet kapcsolni.
            log.warn("[TENANT_GUARD] Receipt cross-tenant access denied: op={} (orphan-or-mismatch)",
                    operation);
            if (log.isDebugEnabled()) {
                log.debug("[TENANT_GUARD] denied details: op={}, receipt.id={}, "
                        + "receipt.companyId={}, current.companyId={}",
                        operation, receiptId, receiptCompanyId, currentCompanyId);
            }
            throw new ResourceNotFoundException("Bizonylat nem található: " + receiptId);
        }
    }

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
                // EXCMD b5b (FR-BSZUR-02 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő):
                // @Transient mezők a kapcsolt tx-ből (a tx már kézben van — nincs extra query).
                .customerName(tx.getCustomerName())
                .hufAmount(tx.getHufAmount())
                .build();
    }

    /** Test-only — segit egy Transaction-bol synthesized UUID-t generaalni. */
    @SuppressWarnings("unused")
    static UUID synthesizedUuidFor(long transactionId) {
        return new UUID(0L, transactionId);
    }
}
