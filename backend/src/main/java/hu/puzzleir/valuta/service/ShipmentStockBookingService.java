package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * FK (Értéktár Shipment készletkönyvelés) — az Átadás-átvétel folyamat készlet-könyvelő motorja.
 *
 * <p>A {@link ShipmentService} ezt delegálja, hogy a fő service diffje az NFR-8 (≤300 LOC) plafon
 * alatt maradjon. A könyvelés <b>szimmetrikus</b>: az átadó (from) készlete a beküldéskor csökken
 * (OUT), az átvevő (to) készlete a visszaigazoláskor nő (IN), mindkét irányban
 * (Értéktár↔Pénztár).</p>
 *
 * <h3>Készlet-típus kiválasztás (kódból verifikált konvenció)</h3>
 * A {@code VaultStockFlowService} dokumentált konvenciója az igazságforrás:
 * <pre>
 *   VAULT (értéktár) oldal   -&gt; currency_stock, entity_id = branch.vault_territory_id::TEXT (WAC)
 *   CASHIER (pénztár) oldal  -&gt; cash_balance, branch_id + currency_id
 * </pre>
 * Egy branch oldalát a {@link Branch#getIsVault()} flag dönti el — így a {@code transfer_type}
 * mező audit/olvashatóság célú (a tényleges típust per-branch a flag adja, ez a legrobusztusabb).
 *
 * <h3>Hibakódok</h3>
 * <ul>
 *   <li>FR-8 elégtelen készlet → {@link BusinessException} {@code VV-VALID-003} (HTTP 422) +
 *       audit {@code STOCK_INSUFFICIENT}</li>
 *   <li>FR-4 nem az átvevő igazol vissza → {@code AccessDeniedException} {@code VV-AUTH-001}
 *       (HTTP 403) — ezt a {@link ShipmentService#deliver} kezeli, ott van a branch-kontextus</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ShipmentStockBookingService {

    public static final String TRANSFER_VAULT_TO_BRANCH = "VAULT_TO_BRANCH";
    public static final String TRANSFER_BRANCH_TO_VAULT = "BRANCH_TO_VAULT";
    public static final String TRANSFER_BRANCH_TO_BRANCH = "BRANCH_TO_BRANCH";
    public static final String TRANSFER_VAULT_TO_VAULT = "VAULT_TO_VAULT";

    /** Audit action-ök (domain-szótár §8). */
    public static final String ACTION_STOCK_OUT = "SHIPMENT_STOCK_OUT";
    public static final String ACTION_STOCK_IN = "SHIPMENT_STOCK_IN";
    public static final String ACTION_STOCK_REVERSAL = "SHIPMENT_STOCK_REVERSAL";
    public static final String ACTION_STOCK_INSUFFICIENT = "STOCK_INSUFFICIENT";
    public static final String ACTION_AML_CHECK = "SHIPMENT_AML_CHECK";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";

    /** FR-8 hibakód: elégtelen készlet. */
    public static final String ERR_INSUFFICIENT = "VV-VALID-003";
    /** FR-4 hibakód: nem az átvevő branch próbál visszaigazolni. */
    public static final String ERR_NOT_RECEIVER = "VV-AUTH-001";
    /** Approve hibakód: nem az átadó/requester branch próbál jóváhagyni. */
    public static final String ERR_NOT_REQUESTER = "VV-AUTH-002";
    /** KK fee-approve hibakód: önjóváhagyás / nem bizonyítható négy-szem (jóváhagyó == rögzítő). */
    public static final String ERR_SELF_APPROVAL = "VV-AUTH-003";
    /** KK fee-approve hibakód: idegen (se from, se to, se nemzeti-szkópú) fiók próbál jóváhagyni. */
    public static final String ERR_FEE_BRANCH_SCOPE = "VV-AUTH-004";
    /** §6/§6b hibakód: idegen tenant branch-ére irányuló könyvelési kísérlet (404). */
    public static final String ERR_CROSS_TENANT = "VV-TENANT-001";

    private static final String ENTITY_TYPE_VAULT = "VAULT";
    private static final String AUDIT_ENTITY_TYPE = "ShipmentRequest";

    /** NFR-6 AML küszöbök (HUF). */
    private static final BigDecimal AML_THRESHOLD = new BigDecimal("100000");
    private static final BigDecimal AML_FULL_THRESHOLD = new BigDecimal("300000");

    private final BranchRepository branchRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditLogService auditLogService;

    // ======================================================================
    // transfer_type derivation (szerveroldal — kliens nem hamisíthatja)
    // ======================================================================

    /**
     * FR-1: a {@code transfer_type}-ot a from/to branch {@link Branch#getIsVault()} flag-jeiből
     * deriváljuk. Sosem a klienstől — így nem manipulálható a könyvelés iránya.
     */
    public String deriveTransferType(Branch from, Branch to) {
        boolean fromVault = Boolean.TRUE.equals(from.getIsVault());
        boolean toVault = Boolean.TRUE.equals(to.getIsVault());
        if (fromVault && toVault) {
            return TRANSFER_VAULT_TO_VAULT;
        }
        if (fromVault) {
            return TRANSFER_VAULT_TO_BRANCH;
        }
        if (toVault) {
            return TRANSFER_BRANCH_TO_VAULT;
        }
        return TRANSFER_BRANCH_TO_BRANCH;
    }

    // ======================================================================
    // Könyvelési belépési pontok
    // ======================================================================

    /**
     * FR-2 / FR-5 / FR-7 / FR-8: az ÁTADÓ (from) oldal készletének csökkentése a beküldéskor.
     * Pesszimista zárolással, elégség-ellenőrzéssel; minden tételhez audit {@code SHIPMENT_STOCK_OUT}.
     * NFR-6: a teljes HUF-érték AML-küszöb feletti részére audit-flag.
     *
     * <p>{@code @Transactional} (REQUIRED): ha a hívó ({@code ShipmentService.submit}) már tranzakciós,
     * abba olvad — így a több tételes könyvelés + a {@code FOR UPDATE} lockok egyetlen atomi egységben
     * futnak; ha valaha közvetlenül hívnák, akkor is saját tranzakciót nyit (GLM-review #6).</p>
     */
    @Transactional
    public void bookStockOut(ShipmentRequest req, UUID companyId) {
        Branch from = loadBranch(req.getFromBranchId(), companyId);
        amlCheck(req, companyId, from);
        for (ShipmentRequestItem item : sortedItems(req)) {
            String currencyCode = resolveCurrencyCode(item.getCurrencyId());
            applySide(from, companyId, item, currencyCode, req, false, ACTION_STOCK_OUT);
        }
    }

    /**
     * FR-3 / FR-5: az ÁTVEVŐ (to) oldal készletének növelése a visszaigazoláskor.
     * Get-or-create + pesszimista zárolás; minden tételhez audit {@code SHIPMENT_STOCK_IN}.
     */
    @Transactional
    public void bookStockIn(ShipmentRequest req, UUID companyId) {
        Branch to = loadBranch(req.getToBranchId(), companyId);
        for (ShipmentRequestItem item : sortedItems(req)) {
            String currencyCode = resolveCurrencyCode(item.getCurrencyId());
            applySide(to, companyId, item, currencyCode, req, true, ACTION_STOCK_IN);
        }
    }

    /**
     * FR-4: a visszaigazolást (DELIVERED) KIZÁRÓLAG az átvevő (to) branch felhasználója végezheti.
     * Ha az átadó (vagy bármely más branch) próbálja → {@code AccessDeniedException} {@code VV-AUTH-001}
     * (HTTP 403) + független tranzakcióban {@code ACCESS_DENIED} audit (a dobott kivétel rollbackje
     * ellenére megmarad a security trail). A teszt/rendszer-kontextusban (nincs branch a tokenben)
     * a hívás megtagadott — a deliver csak hiteles átvevő-branch tokennel mehet át.
     */
    public void assertReceiver(ShipmentRequest req) {
        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (currentBranchId == null || !currentBranchId.equals(req.getToBranchId())) {
            auditLogService.logInNewTransaction(
                    ACTION_ACCESS_DENIED, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                    workerIdStr(), null,
                    currentBranchId != null ? currentBranchId.toString() : null, null,
                    String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"shipment_request_id\":\"%s\","
                                    + "\"to_branch_id\":\"%s\",\"attempt_branch_id\":\"%s\"}",
                            ERR_NOT_RECEIVER, req.getId(), req.getToBranchId(),
                            currentBranchId != null ? currentBranchId.toString() : "null"));
            log.warn("FR-4 visszaigazolás megtagadva: shipment={}, toBranch={}, attemptBranch={}",
                    req.getRequestNumber(), req.getToBranchId(), currentBranchId);
            throw new AccessDeniedException(
                    ERR_NOT_RECEIVER + ": a szállítmány átvételét kizárólag az átvevő fiók igazolhatja vissza.");
        }
    }

    /**
     * A jóváhagyást KIZÁRÓLAG a kérő/átadó (from) branch felhasználója végezheti.
     * Hiányzó branch-kontextus esetén fail-closed: {@code VV-AUTH-002} + {@code ACCESS_DENIED} audit.
     */
    public void assertRequester(ShipmentRequest req) {
        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (currentBranchId == null || !currentBranchId.equals(req.getFromBranchId())) {
            auditLogService.logInNewTransaction(
                    ACTION_ACCESS_DENIED, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                    workerIdStr(), null,
                    currentBranchId != null ? currentBranchId.toString() : null, null,
                    String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"shipment_request_id\":\"%s\","
                                    + "\"from_branch_id\":\"%s\",\"attempt_branch_id\":\"%s\"}",
                            ERR_NOT_REQUESTER, req.getId(), req.getFromBranchId(),
                            currentBranchId != null ? currentBranchId.toString() : "null"));
            log.warn("Szállítmány jóváhagyás megtagadva: shipment={}, fromBranch={}, attemptBranch={}",
                    req.getRequestNumber(), req.getFromBranchId(), currentBranchId);
            throw new AccessDeniedException(
                    ERR_NOT_REQUESTER + ": a szállítmány jóváhagyását kizárólag a kérő (átadó) fiók végezheti.");
        }
    }

    /**
     * KK (kezelési díj) shipment jóváhagyás-guard (2026-07-15 user-döntés) — négy-szem elv:
     * a jóváhagyó worker NEM lehet a rögzítő ({@code requestedById}); fail-closed: hiányzó
     * worker-kontextus vagy hiányzó requestedById esetén megtagadás ({@code VV-AUTH-003}).
     * Branch-szkóp: engedett a nemzeti szkópú (null branch, Főértéktáros), a cél (to) és az
     * átadó (from) fiók NEM-rögzítő felhasználója; minden más fiók → {@code VV-AUTH-004}.
     * A készletmozgató shipment approve-ja NEM ezen fut — az marad {@link #assertRequester}.
     */
    public void assertFeeApprover(ShipmentRequest req) {
        Long currentWorkerId;
        try {
            currentWorkerId = SecurityUtils.getCurrentWorkerId();
        } catch (ValidationException e) {
            currentWorkerId = null; // fail-closed lentebb, 403-ként (nem 400)
        }
        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        Long requesterId = req.getRequestedById();

        if (currentWorkerId == null || requesterId == null || currentWorkerId.equals(requesterId)) {
            auditLogService.logInNewTransaction(
                    ACTION_ACCESS_DENIED, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                    currentWorkerId != null ? currentWorkerId.toString() : null, null,
                    currentBranchId != null ? currentBranchId.toString() : null, null,
                    String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"shipment_request_id\":\"%s\","
                                    + "\"requested_by_id\":\"%s\",\"attempt_worker_id\":\"%s\"}",
                            ERR_SELF_APPROVAL, req.getId(),
                            requesterId != null ? requesterId.toString() : "null",
                            currentWorkerId != null ? currentWorkerId.toString() : "null"));
            log.warn("KK fee-jóváhagyás megtagadva (négy-szem): shipment={}, requestedBy={}, attemptWorker={}",
                    req.getRequestNumber(), requesterId, currentWorkerId);
            throw new AccessDeniedException(
                    ERR_SELF_APPROVAL + ": a kezelési díjat nem hagyhatja jóvá a rögzítője (négy-szem elv).");
        }

        boolean branchAllowed = currentBranchId == null
                || currentBranchId.equals(req.getToBranchId())
                || currentBranchId.equals(req.getFromBranchId());
        if (!branchAllowed) {
            auditLogService.logInNewTransaction(
                    ACTION_ACCESS_DENIED, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                    currentWorkerId.toString(), null,
                    currentBranchId.toString(), null,
                    String.format("{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"shipment_request_id\":\"%s\","
                                    + "\"from_branch_id\":\"%s\",\"to_branch_id\":\"%s\",\"attempt_branch_id\":\"%s\"}",
                            ERR_FEE_BRANCH_SCOPE, req.getId(), req.getFromBranchId(),
                            req.getToBranchId(), currentBranchId));
            log.warn("KK fee-jóváhagyás megtagadva (fiók-szkóp): shipment={}, from={}, to={}, attemptBranch={}",
                    req.getRequestNumber(), req.getFromBranchId(), req.getToBranchId(), currentBranchId);
            throw new AccessDeniedException(
                    ERR_FEE_BRANCH_SCOPE + ": a kezelési díj jóváhagyása csak az érintett (átadó/cél) "
                            + "fiókból vagy nemzeti szkópból végezhető.");
        }
    }

    /**
     * TBD-1 döntés: ha egy már OUT-könyvelt (SUBMITTED/APPROVED/IN_TRANSIT) szállítmányt
     * elutasítanak (reject) vagy visszavonnak (cancel), az ÁTADÓ oldalra vissza kell pótolni
     * a készletet (különben elveszne). Audit {@code SHIPMENT_STOCK_REVERSAL}.
     */
    @Transactional
    public void reverseStockOut(ShipmentRequest req, UUID companyId) {
        Branch from = loadBranch(req.getFromBranchId(), companyId);
        for (ShipmentRequestItem item : sortedItems(req)) {
            String currencyCode = resolveCurrencyCode(item.getCurrencyId());
            applySide(from, companyId, item, currencyCode, req, true, ACTION_STOCK_REVERSAL);
        }
    }

    // ======================================================================
    // Készlet-mutáció egy oldalon (vault VAGY pénztár, irány a flag alapján)
    // ======================================================================

    /**
     * Egy branch-oldal készlet-mutációja. {@code increase=false} → OUT (csökkent, elégség-check),
     * {@code increase=true} → IN (növel, get-or-create). A branch {@code isVault} flag-je dönti el,
     * hogy {@code currency_stock} (WAC, vaultTerritoryId-kulcs) vagy {@code cash_balance} mozogjon.
     */
    private void applySide(Branch branch, UUID companyId, ShipmentRequestItem item,
                           String currencyCode, ShipmentRequest req, boolean increase, String action) {
        BigDecimal amount = item.getRequestedAmount();
        if (amount == null || amount.signum() <= 0) {
            throw new ValidationException("A szállítmány-tétel összege pozitív kell legyen (currencyId="
                    + item.getCurrencyId() + ")");
        }
        if (Boolean.TRUE.equals(branch.getIsVault())) {
            applyVaultStock(branch, companyId, item, currencyCode, amount, req, increase, action);
        } else {
            applyCashBalance(branch, companyId, item, currencyCode, amount, req, increase, action);
        }
    }

    /** VAULT oldal: currency_stock (WAC), entity_id = vault_territory_id. */
    private void applyVaultStock(Branch branch, UUID companyId, ShipmentRequestItem item,
                                 String currencyCode, BigDecimal amount, ShipmentRequest req,
                                 boolean increase, String action) {
        Integer territoryId = branch.getVaultTerritoryId();
        if (territoryId == null) {
            throw new ValidationException(String.format(
                    "Az értéktári fiók (%s) vault_territory_id mezője nincs kitöltve — a "
                            + "készletkönyvelés nem végezhető el (törzsadat-rendezés szükséges).",
                    branch.getCode()));
        }
        String entityId = territoryId.toString();
        if (increase) {
            receiveVaultStock(companyId, entityId, currencyCode, item, amount, action);
        } else {
            CurrencyStock stock = currencyStockRepository
                    .findForUpdate(companyId, ENTITY_TYPE_VAULT, entityId, currencyCode)
                    .orElseThrow(() -> insufficientStock(req, branch, item, currencyCode, amount, BigDecimal.ZERO));
            if (stock.getQuantity().compareTo(amount) < 0) {
                throw insufficientStock(req, branch, item, currencyCode, amount, stock.getQuantity());
            }
            stock.issueStock(amount);
            currencyStockRepository.save(stock);
        }
        writeStockAudit(action, req, branch, item, currencyCode, amount, increase);
    }

    /**
     * VAULT IN-bevételezés ON CONFLICT sor-garantálással és lockolt újraolvasással.
     * A korábbi saveAndFlush + DIVE-catch minta valós PG-n rollback-only tranzakciót okozott;
     * az insertIfAbsent kivétel nélkül garantálja a sort, majd a tényleges könyvelés a zárolt soron fut.
     */
    private void receiveVaultStock(UUID companyId, String entityId, String currencyCode,
                                   ShipmentRequestItem item, BigDecimal amount, String action) {
        CurrencyStock stock = currencyStockRepository
                .findForUpdate(companyId, ENTITY_TYPE_VAULT, entityId, currencyCode).orElse(null);
        if (stock == null) {
            // INVSTOCK-ROLLBACK fix (a GLM-review #9 saveAndFlush+DIVE-catch mintát váltja):
            // valós PG-n a flush-DIVE a tx-et rollback-only-ra jelölte, a javító save a
            // commitnál UnexpectedRollbackException-nel elveszett. Az ON CONFLICT DO NOTHING
            // sor-garantálással a kivétel létre sem jön; a sort zárolt újraolvasás adja.
            currencyStockRepository.insertIfAbsent(companyId, ENTITY_TYPE_VAULT, entityId, currencyCode);
            stock = currencyStockRepository
                    .findForUpdate(companyId, ENTITY_TYPE_VAULT, entityId, currencyCode)
                    .orElseThrow(() -> new IllegalStateException(
                            "currency_stock sor nem található közvetlenül a sor-garantálás után"));
        }
        stock.receiveStock(amount, resolveReceiveWac(stock, item, amount, action));
        currencyStockRepository.save(stock);
    }

    /** CASHIER oldal: cash_balance (branch_id + currency_id). */
    private void applyCashBalance(Branch branch, UUID companyId, ShipmentRequestItem item,
                                  String currencyCode, BigDecimal amount, ShipmentRequest req,
                                  boolean increase, String action) {
        Long currencyId = item.getCurrencyId();
        if (increase) {
            receiveCashBalance(branch, companyId, currencyId, amount);
        } else {
            CashBalance balance = cashBalanceRepository
                    .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branch.getId(), currencyId, companyId)
                    .orElseThrow(() -> insufficientStock(req, branch, item, currencyCode, amount, BigDecimal.ZERO));
            // FR-8: explicit elő-check VV-VALID-003 (422) — NEM a beépített subtractBalance
            // InsufficientBalanceException-ére (az 400-at adna, a spec 422-t kér).
            if (balance.getCurrentBalance().compareTo(amount) < 0) {
                throw insufficientStock(req, branch, item, currencyCode, amount, balance.getCurrentBalance());
            }
            balance.setCurrentBalance(balance.getCurrentBalance().subtract(amount));
            balance.setLastTransactionAt(LocalDateTime.now());
            cashBalanceRepository.save(balance);
        }
        writeStockAudit(action, req, branch, item, currencyCode, amount, increase);
    }

    /**
     * CASHIER IN-bevételezés ON CONFLICT sor-garantálással és lockolt újraolvasással
     * (a {@link #receiveVaultStock} cash-oldali párja).
     */
    private void receiveCashBalance(Branch branch, UUID companyId, Long currencyId, BigDecimal amount) {
        CashBalance locked = cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branch.getId(), currencyId, companyId).orElse(null);
        if (locked == null) {
            cashBalanceRepository.insertIfAbsent(companyId, branch.getId(), currencyId);
            locked = cashBalanceRepository
                    .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branch.getId(), currencyId, companyId)
                    .orElseThrow(() -> new IllegalStateException(
                            "cash_balance sor nem található közvetlenül a sor-garantálás után"));
        }
        locked.addBalance(amount);
        cashBalanceRepository.save(locked);
    }

    private Branch loadBranch(UUID branchId, UUID companyId) {
        return branchRepository.findByIdAndCompanyId(branchId, companyId)
                .orElseThrow(() -> new BusinessException(
                        "A szállítmány branch-e nem található a jelenlegi cégben: " + branchId,
                        ERR_CROSS_TENANT, org.springframework.http.HttpStatus.NOT_FOUND));
    }

    private String resolveCurrencyCode(Long currencyId) {
        if (currencyId == null) {
            throw new ValidationException("A szállítmány-tétel currencyId-je nem lehet üres.");
        }
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ValidationException("Ismeretlen valuta: currencyId=" + currencyId));
        return currency.getCode();
    }

    /**
     * Bevételezési WAC meghatározása (GLM-review #2/#9 — a két IN-útvonal eltér):
     * <ul>
     *   <li><b>Sztornó-reverzió</b> ({@code SHIPMENT_STOCK_REVERSAL}): a korábbi kiadás a WAC-ot nem
     *       változtatta, ezért a meglévő készlet-WAC-on vételezünk vissza — a sztornó nem torzíthatja
     *       az elszámoló árat. Ha a sor frissen jön létre (WAC=0), a tétel fajlagos HUF-értéke a
     *       fallback, végső esetben 0.</li>
     *   <li><b>Valódi átvevői bevételezés</b> ({@code SHIPMENT_STOCK_IN}): a szállítmány TÉNYLEGES
     *       értékelési rátáját ({@code hufValue / mennyiség}) használjuk, hogy a {@code receiveStock}
     *       a meglévő WAC-cal helyesen blendelje — különben az átvevő készlet elszámoló ára sosem
     *       tükrözné a bekerülési értéket (néma könyvelési hiba). Ha nincs HUF-érték, a meglévő WAC,
     *       végül 0.</li>
     * </ul>
     * Sosem önkényes konstans (a korábbi {@code BigDecimal.ONE} fallback megszűnt).
     */
    private BigDecimal resolveReceiveWac(CurrencyStock stock, ShipmentRequestItem item,
                                         BigDecimal amount, String action) {
        BigDecimal existingWac = stock.getWeightedAvgCost();
        BigDecimal unitHuf = unitHufValue(item, amount);
        if (ACTION_STOCK_REVERSAL.equals(action)) {
            // sztornó: a meglévő WAC az elsődleges (a kiadás nem mozdította); fallback a tétel rátája
            if (existingWac != null && existingWac.signum() > 0) {
                return existingWac;
            }
            return unitHuf != null ? unitHuf : BigDecimal.ZERO;
        }
        // valódi bevételezés: a szállítmány tényleges rátája az elsődleges; fallback a meglévő WAC
        if (unitHuf != null) {
            return unitHuf;
        }
        return existingWac != null && existingWac.signum() > 0 ? existingWac : BigDecimal.ZERO;
    }

    /** A tétel fajlagos HUF-értéke ({@code hufValue / mennyiség}), vagy {@code null} ha nem számítható. */
    private BigDecimal unitHufValue(ShipmentRequestItem item, BigDecimal amount) {
        BigDecimal hufValue = item.getHufValue();
        if (hufValue != null && hufValue.signum() > 0 && amount != null && amount.signum() > 0) {
            return hufValue.divide(amount, 4, java.math.RoundingMode.HALF_UP);
        }
        return null;
    }

    /**
     * NFR-7 deadlock-prevenció (GLM-review #8): a tételeket determinisztikus {@code currencyId}
     * sorrendben zároljuk, hogy két párhuzamos, ugyanazokat a devizákat eltérő sorrendben tartalmazó
     * szállítmány ne kereszt-zárolja egymást (lock-ordering deadlock). {@code null} currencyId előre.
     */
    private java.util.List<ShipmentRequestItem> sortedItems(ShipmentRequest req) {
        return req.getItems().stream()
                .sorted(java.util.Comparator.comparing(
                        ShipmentRequestItem::getCurrencyId,
                        java.util.Comparator.nullsFirst(java.util.Comparator.naturalOrder())))
                .toList();
    }

    /**
     * FR-8: elégtelen készlet → audit {@code STOCK_INSUFFICIENT} (független tranzakcióban, hogy a
     * dobott {@link BusinessException} rollbackje ELLENÉRE megmaradjon) + 422 {@code VV-VALID-003}.
     */
    private BusinessException insufficientStock(ShipmentRequest req, Branch branch, ShipmentRequestItem item,
                                                String currencyCode, BigDecimal requested, BigDecimal available) {
        auditLogService.logInNewTransaction(
                ACTION_STOCK_INSUFFICIENT, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                workerIdStr(), null, branchIdStr(branch.getId()), branch.getName(),
                String.format("{\"KAT\":\"VALID\",\"shipment_request_id\":\"%s\",\"branch_id\":\"%s\","
                                + "\"currency_id\":%d,\"currency\":\"%s\",\"requested\":%s,\"available\":%s}",
                        req.getId(), branch.getId(), item.getCurrencyId(), currencyCode,
                        requested.toPlainString(), available.toPlainString()));
        return new BusinessException(
                String.format("Nincs elegendő készlet a(z) %s átadásához: kért %s, elérhető %s (%s).",
                        currencyCode, requested.toPlainString(), available.toPlainString(), branch.getCode()),
                ERR_INSUFFICIENT);
    }

    /** FR-9: minden készletmozgás strukturált audit-bejegyzést kap (KAT=TX a changes JSON-ban). */
    private void writeStockAudit(String action, ShipmentRequest req, Branch branch, ShipmentRequestItem item,
                                 String currencyCode, BigDecimal amount, boolean increase) {
        String changes = String.format(
                "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"request_number\":\"%s\",\"branch_id\":\"%s\","
                        + "\"currency_id\":%d,\"currency\":\"%s\",\"amount\":%s,\"direction\":\"%s\","
                        + "\"transfer_type\":\"%s\"}",
                req.getId(), safe(req.getRequestNumber()), branch.getId(), item.getCurrencyId(),
                currencyCode, amount.toPlainString(), increase ? "IN" : "OUT", safe(req.getTransferType()));
        auditLogService.log(action, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                workerIdStr(), null, branchIdStr(branch.getId()), branch.getName(),
                changes, null, null);
    }

    /**
     * NFR-6: AML-küszöb ellenőrzés. A repóban NINCS dedikált AML-szolgáltatás, ezért a kötelező
     * AML-érintettséget audit-flaggel teljesítjük (≥100k részleges, ≥300k teljes), nem találunk ki
     * nemlétező AML-API-t. A teljes HUF-érték a tételek {@code hufValue}-jából (a create-kor beemelt
     * elszámoló árfolyamon számolt) adódik.
     */
    private void amlCheck(ShipmentRequest req, UUID companyId, Branch from) {
        BigDecimal totalHuf = BigDecimal.ZERO;
        for (ShipmentRequestItem item : req.getItems()) {
            if (item.getHufValue() != null) {
                totalHuf = totalHuf.add(item.getHufValue());
            }
        }
        if (totalHuf.compareTo(AML_THRESHOLD) < 0) {
            return;
        }
        String level = totalHuf.compareTo(AML_FULL_THRESHOLD) >= 0 ? "FULL" : "PARTIAL";
        auditLogService.log(ACTION_AML_CHECK, AUDIT_ENTITY_TYPE, idStr(req.getId()),
                workerIdStr(), null, branchIdStr(from.getId()), from.getName(),
                String.format("{\"KAT\":\"AML\",\"shipment_request_id\":\"%s\",\"total_huf\":%s,\"level\":\"%s\"}",
                        req.getId(), totalHuf.toPlainString(), level),
                null, null);
        log.info("Shipment AML-flag [{}]: shipment={}, totalHuf={}", level, req.getRequestNumber(), totalHuf);
    }

    private static String idStr(UUID id) {
        return id != null ? id.toString() : null;
    }

    private static String branchIdStr(UUID id) {
        return id != null ? id.toString() : null;
    }

    private static String workerIdStr() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return workerId != null ? workerId.toString() : null;
    }

    private static String safe(String s) {
        return s != null ? s : "";
    }
}
