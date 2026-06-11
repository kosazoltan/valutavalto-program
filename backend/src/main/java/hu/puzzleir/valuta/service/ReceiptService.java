package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.receipt.CancelledTransactionReceiptRequest;
import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ReceiptRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
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
    private final AuditLogService auditLogService;
    // FR-BSZUR-05 (V312): ENGEDÉLYEZŐ-dúsítás a jóváhagyás audit-rekordokból
    private final hu.puzzleir.valuta.repository.TransactionAmlApprovalRepository amlApprovalRepository;

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    /** v2.3.48: receipt list limit a frontend ReceiptPage NEM-paginalt UI-ahoz. */
    private static final int RECEIPT_LIST_LIMIT = 500;
    private static final DateTimeFormatter CANCELLED_RECEIPT_TS = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");

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
    /** Backward-compat: dátum-szűrés nélküli lista (a régi hívók/tesztek számára). */
    public List<Receipt> list(UUID transactionId) {
        return list(transactionId, null, null, java.util.Collections.emptyMap());
    }

    /** Backward-compat: dátum-tartomány, ügyfél-adatlap szűrő nélkül. */
    public List<Receipt> list(UUID transactionId, LocalDate fromDate, LocalDate toDate) {
        return list(transactionId, fromDate, toDate, java.util.Collections.emptyMap());
    }

    /**
     * EXCMD b5b FR-BSZUR-02/03: bizonylat-lista dátum-tartomány + ügyfél-adatlap szűréssel.
     *
     * @param fromDate        opcionális alsó dátumhatár (inkluzív, NULL = nyitott)
     * @param toDate          opcionális felső dátumhatár (inkluzív, NULL = nyitott)
     * @param customerFilters mezőkulcs → részleges érték (customerName..customerDocumentNumber).
     *                        A LIKE-szűrés a synthesized DB-query-ben fut (FR-BSZUR-03, Codex P2),
     *                        hogy a top-500 limit a SZŰRT halmazra vonatkozzon (ne csonkoljon előtte).
     */
    public List<Receipt> list(UUID transactionId, LocalDate fromDate, LocalDate toDate,
                              java.util.Map<String, String> customerFilters) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (transactionId != null) {
            // EXCMD b5b (Codex/Copilot P2): a tranzakció-szűrt ágat is dúsítjuk, különben a
            // GET /api/v1/receipts?transactionId=... úton a materializált real receipt-ek
            // customerName/hufAmount-ja null marad (ügyfél-oszlop + 10M AML-jelölő hiányozna).
            List<Receipt> filtered = new ArrayList<>(repo.findByCompanyIdAndTransactionId(companyId, transactionId));
            // EXCMD b5b FR-BSZUR-02 (Codex P2): ha a from/to is meg van adva a transactionId mellett,
            // azt is tiszteletben tartjuk (szerződés-konzisztencia). A lista kicsi (egy tranzakció
            // bizonylatai), ezért issueDate-re Java-szűrés elég.
            if (fromDate != null || toDate != null) {
                filtered.removeIf(r -> !isWithinRange(r.getIssueDate(), fromDate, toDate));
            }
            enrichRealReceipts(filtered, companyId);
            // EXCMD b5b FR-BSZUR-03 (Codex P2): ha customer-szűrő is jön a transactionId mellett, azt is
            // tiszteletben tartjuk (szerződés-konzisztencia a nem-transactionId úttal). Enrich UTÁN, a
            // dúsított @Transient mezőkből.
            if (customerFilters != null && !customerFilters.isEmpty()) {
                filtered.removeIf(r -> !receiptMatchesCustomerFilters(r, customerFilters));
            }
            enrichApprovers(filtered, companyId); // FR-BSZUR-05 (V312)
            return filtered;
        }

        // Real (materializált) Receipt rekordok a DB-bol — EXCMD b5b FR-BSZUR-02 (Codex P2): a real
        // receipt-eket IS a DB szűri az issueDate-tartományra (nem csak a synthesized ágat), különben a
        // ?from=&to= az időszakon kívüli materializált bizonylatokat is visszaadná (és a teljes táblát
        // betöltené). NULL határ = nyitott vég → mindkettő NULL esetén a teljes lista (változatlan).
        List<Receipt> realReceipts = new ArrayList<>(repo.findByCompanyIdAndIssueDateRange(companyId, fromDate, toDate));

        // Mely Transaction-ok vannak mar materializalva real Receipt-ben?
        // A materializaltakat az `id` mezo synthesizedUuid alakjarol ismerjuk fel
        // (a print() lazy-materialize a Receipt.id-jat synthesizedUuid-ra allitja).
        Set<Long> materializedTxIds = new HashSet<>();
        for (Receipt r : realReceipts) {
            if (r.getId() != null && isSynthesizedUuid(r.getId())) {
                materializedTxIds.add(decodeTransactionId(r.getId()));
            }
        }

        // Synthesized Receipt-ek a Transaction-bol — kihagyva a mar materializaltakat.
        // EXCMD b5b FR-BSZUR-02 (Codex P2): a dátum-szűrést a DB-be toljuk, hogy a top-500 limit a
        // KIVÁLASZTOTT időszakon BELÜL érvényesüljön — különben egy régi hónap/tartomány csendben
        // hiányos lenne (a szűrés a már 500-ra csonkolt listán futna). NULL határ = nyitott vég.
        // EXCMD b5b FR-BSZUR-03 (Codex P2): az ügyfél-adatlap LIKE-szűrők IS a DB-ben futnak a
        // synthesized ágon — különben a 500-as csonkolás UTÁN, kliens-oldalon szűrve egy >500-as
        // időszakban egy régi egyező ügyfél-rekord kimaradna. A real (materializált) ág nincs
        // csonkolva → ott a kliens-oldali matchesCustomerFilters elég.
        List<Transaction> txList = transactionRepository.findReceiptListByCompanyIdAndDateRange(
                companyId, fromDate, toDate,
                likeParam(customerFilters, "customerName"),
                likeParam(customerFilters, "customerMotherName"),
                likeParam(customerFilters, "customerBirthPlace"),
                likeParam(customerFilters, "customerBirthDate"),
                likeParam(customerFilters, "customerNationality"),
                likeParam(customerFilters, "customerAddress"),
                likeParam(customerFilters, "customerDocumentType"),
                likeParam(customerFilters, "customerDocumentNumber"),
                likeParam(customerFilters, "customerActorName"),
                PageRequest.of(0, RECEIPT_LIST_LIMIT));

        List<Receipt> synthesized = new ArrayList<>();
        for (Transaction tx : txList) {
            if (!materializedTxIds.contains(tx.getId())) {
                synthesized.add(synthesizeReceipt(tx));
            }
        }

        // EXCMD b5b (FR-BSZUR-01 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő):
        // a REAL Receipt-eket a kapcsolt Transaction-ből dúsítjuk customerName + hufAmount
        // @Transient mezőkkel. N+1 ELKERÜLÉSE: a real receipt-ek transactionId-jait EGY
        // cég-szűrt batch query-ben töltjük be (findAllByIdInAndCompanyId), majd id→Transaction
        // map-ből töltjük. A synthesized Receipt-ek már dúsítva vannak (synthesizeReceipt
        // kézben tartja a tx-et).
        enrichRealReceipts(realReceipts, companyId);

        // EXCMD b5b FR-BSZUR-03 (Codex P2): a materializált (real) receipt-eket IS szűrjük az
        // ügyfél-adatlap szűrőkre — különben a GET /receipts?customerName=... az adatlap-szűrőnek NEM
        // megfelelő real bizonylatokat is visszaadná (a synthesized ág már DB-szinten szűrt). A real
        // ág nincs csonkolva (findByCompanyIdAndIssueDateRange limit nélkül) → Java-szűrés helyes és
        // teljes; a dúsított @Transient mezőkből (applyCustomerSnapshot) dolgozik, így a synthesized
        // DB-LIKE-kal konzisztens (azonos tx-snapshot, részleges + kis/nagybetű-érzéketlen egyezés).
        if (customerFilters != null && !customerFilters.isEmpty()) {
            realReceipts.removeIf(r -> !receiptMatchesCustomerFilters(r, customerFilters));
        }

        List<Receipt> result = new ArrayList<>(realReceipts.size() + synthesized.size());
        result.addAll(realReceipts);
        result.addAll(synthesized);
        enrichApprovers(result, companyId); // FR-BSZUR-05 (V312) — real + synthesized egyben
        return result;
    }

    /**
     * EXCMD b5b FR-BSZUR-03: egy (már dúsított) Receipt megfelel-e az ÖSSZES (nem üres) ügyfél-adatlap
     * szűrőnek. Részleges (contains), kis/nagybetű-érzéketlen egyezés — a synthesized DB-LIKE-kal és a
     * kliens-oldali matchesCustomerFilters-szel azonos szemantika. A születési dátumot stringgé alakítjuk.
     */
    private static boolean receiptMatchesCustomerFilters(Receipt r, java.util.Map<String, String> f) {
        return matchesField(r.getCustomerName(), f.get("customerName"))
            && matchesField(r.getCustomerMotherName(), f.get("customerMotherName"))
            && matchesField(r.getCustomerBirthPlace(), f.get("customerBirthPlace"))
            && matchesField(r.getCustomerBirthDate() == null ? null : r.getCustomerBirthDate().toString(),
                            f.get("customerBirthDate"))
            && matchesField(r.getCustomerNationality(), f.get("customerNationality"))
            && matchesField(r.getCustomerAddress(), f.get("customerAddress"))
            && matchesField(r.getCustomerDocumentType(), f.get("customerDocumentType"))
            && matchesField(r.getCustomerDocumentNumber(), f.get("customerDocumentNumber"))
            && matchesField(r.getCustomerActorName(), f.get("customerActorName"));
    }

    /** Üres/hiányzó szűrő → nem szűkít (true). Egyébként részleges, kis/nagybetű-érzéketlen contains. */
    private static boolean matchesField(String value, String filter) {
        if (filter == null || filter.isBlank()) {
            return true;
        }
        if (value == null) {
            return false;
        }
        return value.toLowerCase().contains(filter.trim().toLowerCase());
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
                applyCustomerSnapshot(r, tx);
            }
        }
    }

    /**
     * EXCMD b5b FR-BSZUR-02/03/05: a Receipt @Transient ügyfél-/összeg-mezőit a kapcsolt
     * Transaction-snapshotból tölti (read-through view layer). EGY helyen, hogy a synthesized
     * és a materializált (real) dúsítási út ne driftelhessen szét. Csak skalár mezőket olvas.
     */
    private static void applyCustomerSnapshot(Receipt r, Transaction tx) {
        r.setCustomerName(tx.getCustomerName());
        r.setHufAmount(tx.getHufAmount());
        // FR-BSZUR-03 természetes személy szűrőmezők (LEÁNYKORI NEVE nincs a tx-snapshotban → defer)
        r.setCustomerMotherName(tx.getCustomerMotherName());
        r.setCustomerBirthPlace(tx.getCustomerBirthPlace());
        r.setCustomerBirthDate(tx.getCustomerBirthDate());
        r.setCustomerNationality(tx.getCustomerNationality());
        r.setCustomerAddress(tx.getCustomerAddress());
        r.setCustomerDocumentType(tx.getCustomerDocumentType());
        r.setCustomerDocumentNumber(tx.getCustomerDocumentNumber());
        // FR-BSZUR-04: képviselő / meghatalmazott neve (jogi személy képviselője is ide kerül).
        r.setCustomerActorName(tx.getCustomerActorName());
        // FR-BSZUR-05 (V312): a jóváhagyás-session kulcs — az enrichApprovers ebből oldja fel
        // az ENGEDÉLYEZŐ nevét + beosztását (a kulcs maga @JsonIgnore, nem megy ki a kliensnek).
        r.setApprovalSessionId(tx.getApprovalSessionId());
    }

    /**
     * EXCMD b5b FR-BSZUR-05 (V312): a bizonylatok ENGEDÉLYEZŐ-mezőinek (név + beosztás)
     * dúsítása a {@code transaction_aml_approval} audit-rekordokból. N+1 ELKERÜLÉSE: az
     * összes session-kulcsot EGY cég-szűrt batch query-vel oldjuk fel. Jóváhagyás nélküli
     * bizonylatnál a mezők null-ok maradnak (a UI "—"-t mutat).
     */
    private void enrichApprovers(List<Receipt> receipts, UUID companyId) {
        Set<String> sessionIds = new HashSet<>();
        for (Receipt r : receipts) {
            if (r.getApprovalSessionId() != null && !r.getApprovalSessionId().isBlank()) {
                sessionIds.add(r.getApprovalSessionId());
            }
        }
        if (sessionIds.isEmpty()) {
            return;
        }
        // Copilot review: a grant single-use (consumeApprovalGrant) miatt sessionönként 1 jóváhagyás
        // várható, de az adatbázis ezt nem kényszeríti ki — duplikátumnál DETERMINISZTIKUSAN a
        // legkorábbi (első) jóváhagyás nyer (approvedAt szerint), nem a query sorrendje.
        java.util.Map<String, hu.puzzleir.valuta.entity.TransactionAmlApproval> bySession =
                new java.util.HashMap<>();
        for (hu.puzzleir.valuta.entity.TransactionAmlApproval approval :
                amlApprovalRepository.findByCompanyIdAndApprovalSessionIdIn(companyId, sessionIds)) {
            bySession.merge(approval.getApprovalSessionId(), approval, (existing, candidate) -> {
                if (existing.getApprovedAt() == null) {
                    return candidate;
                }
                if (candidate.getApprovedAt() == null) {
                    return existing;
                }
                return candidate.getApprovedAt().isBefore(existing.getApprovedAt()) ? candidate : existing;
            });
        }
        for (Receipt r : receipts) {
            hu.puzzleir.valuta.entity.TransactionAmlApproval approval =
                    r.getApprovalSessionId() != null ? bySession.get(r.getApprovalSessionId()) : null;
            if (approval != null) {
                r.setApprovedByName(approval.getApprovedByName());
                r.setApprovedByRole(approval.getApprovedByRole());
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

    /**
     * EXCMD b5b FR-BSZUR-02: egy bizonylat-dátum a [from, to] (inkluzív, nyitott végek megengedettek)
     * tartományba esik-e. NULL dátum + bármely határ → nincs benne (defenzív: nem provábilhatóan benne).
     */
    private static boolean isWithinRange(LocalDate date, LocalDate from, LocalDate to) {
        if (date == null) {
            return from == null && to == null;
        }
        if (from != null && date.isBefore(from)) {
            return false;
        }
        return to == null || !date.isAfter(to);
    }

    /**
     * EXCMD b5b FR-BSZUR-03: egy ügyfél-adatlap szűrőértéket a synthesized JPQL-query LIKE-mintájára
     * képez: üres/hiányzó → NULL (nincs szűrés), egyébként {@code %érték%} kisbetűsítve (a query LOWER-rel
     * hasonlít). Így a részleges, kis/nagybetű-érzéketlen egyezés a kliens-oldali matchesCustomerFilters-szel
     * konzisztens.
     */
    private static String likeParam(java.util.Map<String, String> filters, String key) {
        String v = filters == null ? null : filters.get(key);
        if (v == null || v.isBlank()) {
            return null;
        }
        return "%" + v.trim().toLowerCase() + "%";
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
     * P1 Product Ready: MEGSEM / megszakitott penzvaltas bizonylat.
     *
     * <p>Nem irunk felkesz {@link Transaction} rekordot, mert az keszletet, forgalmat es napzarast
     * torzitana. A megszakitas nulla penzmozgasu, onallo {@link Receipt} rekordkent materializalodik,
     * tenant-szurt companyId-vel es audit hash-chain bejegyzessel.</p>
     */
    @Transactional(rollbackFor = Exception.class)
    public Receipt createCancelledTransactionReceipt(CancelledTransactionReceiptRequest request) {
        if (request == null) {
            throw new ValidationException("A megszakitott bizonylat kerese nem lehet ures.");
        }
        if (!hasAtLeastOneLine(request)) {
            throw new ValidationException("Megszakitott bizonylat csak megkezdett tranzakciohoz rogzithet.");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        String workerCode = SecurityUtils.getCurrentWorkerCode();
        LocalDateTime now = LocalDateTime.now();

        String receiptNumber = generateCancelledReceiptNumber(now);
        Receipt receipt = Receipt.builder()
                .companyId(companyId)
                .receiptNumber(receiptNumber)
                .receiptType("CANCELLED_TRANSACTION")
                .issueDate(now.toLocalDate())
                .content(buildCancelledReceiptContent(request, receiptNumber, now, branchId, workerId, workerCode))
                .isPrinted(false)
                .build();

        Receipt saved = repo.save(receipt);
        auditLogService.log(
                "CANCELLED_TRANSACTION_RECEIPT_CREATED",
                "RECEIPT",
                saved.getId() != null ? saved.getId().toString() : saved.getReceiptNumber(),
                workerId != null ? workerId.toString() : null,
                workerCode,
                branchId != null ? branchId.toString() : null,
                null,
                "Megszakitott tranzakcio bizonylat rogzítve: " + saved.getReceiptNumber(),
                null,
                null);
        return saved;
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

    private static boolean hasAtLeastOneLine(CancelledTransactionReceiptRequest request) {
        if (request.getLines() == null || request.getLines().isEmpty()) {
            return false;
        }
        return request.getLines().stream().anyMatch(line ->
                (line.getCurrencyCode() != null && !line.getCurrencyCode().isBlank())
                        || line.getForeignAmount() != null
                        || line.getRate() != null
                        || line.getHufAmount() != null);
    }

    private static String generateCancelledReceiptNumber(LocalDateTime now) {
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return "M-" + now.format(CANCELLED_RECEIPT_TS) + "-" + suffix;
    }

    private static String buildCancelledReceiptContent(
            CancelledTransactionReceiptRequest request,
            String receiptNumber,
            LocalDateTime now,
            UUID branchId,
            Long workerId,
            String workerCode) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("receiptNumber", receiptNumber);
        payload.put("receiptType", "CANCELLED_TRANSACTION");
        payload.put("title", "MEGSZAKITOTT TRANZAKCIO BIZONYLAT");
        payload.put("mode", request.getMode());
        payload.put("reason", blankToDefault(request.getReason(), "USER_CANCELLED"));
        payload.put("cancelledAt", now.toString());
        payload.put("branchId", branchId != null ? branchId.toString() : null);
        payload.put("workerId", workerId);
        payload.put("workerCode", workerCode);
        payload.put("customerName", blankToNull(request.getCustomerName()));
        payload.put("customerDocumentNumber", blankToNull(request.getCustomerDocumentNumber()));
        payload.put("lines", request.getLines() == null ? List.of() : request.getLines());
        payload.put("financialEffect", "NONE");

        try {
            return OBJECT_MAPPER.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new ValidationException("A megszakitott bizonylat tartalma nem serializalhato.");
        }
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

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
        Receipt r = Receipt.builder()
                .id(encodeTransactionId(tx.getId()))
                .companyId(tx.getCompany() != null ? tx.getCompany().getId() : null)
                .receiptNumber(tx.getReceiptNumber())
                .receiptType(tx.getTransactionType() != null
                        ? tx.getTransactionType().name() : "UNKNOWN")
                .issueDate(tx.getTransactionDate())
                .isPrinted(false)
                .build();
        // EXCMD b5b (FR-BSZUR-02/03/05): @Transient ügyfél-/összeg-mezők a kapcsolt tx-ből
        // (a tx már kézben van — nincs extra query). Közös helper a real-úttal (no drift).
        applyCustomerSnapshot(r, tx);
        return r;
    }

    /** Test-only — segit egy Transaction-bol synthesized UUID-t generaalni. */
    @SuppressWarnings("unused")
    static UUID synthesizedUuidFor(long transactionId) {
        return new UUID(0L, transactionId);
    }
}
