package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Kassza egyenleg szolgáltatás.
 *
 * Legacy: PENZTAR tábla kezelés, PILLALL (pillanat állapot)
 * - Valutánkénti készlet nyilvántartás
 * - Alacsony/magas készlet figyelmeztetés
 * - Napi nyitó/záró egyenleg
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class CashBalanceService {

    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final AuditLogService auditLogService;
    // FK-075 FR-5/FR-6: élő „Mai statisztika" — tranzakció-alapú összesítés a mai napra.
    private final TransactionRepository transactionRepository;

    /**
     * FK-075: a „Mai statisztika" típus-halmazai a DailySession-szemantikából
     * ({@link TransactionType#isBuyType()} / {@link TransactionType#isSellType()}) származtatva:
     * BUY/WU_RECEIVE/MG_RECEIVE illetve SELL/WU_SEND/MG_SEND.
     */
    private static final List<TransactionType> BUY_TYPES =
            Arrays.stream(TransactionType.values()).filter(TransactionType::isBuyType).toList();
    private static final List<TransactionType> SELL_TYPES =
            Arrays.stream(TransactionType.values()).filter(TransactionType::isSellType).toList();
    private static final List<TransactionType> BUY_AND_SELL_TYPES = buildBuyAndSellTypes();

    private static List<TransactionType> buildBuyAndSellTypes() {
        List<TransactionType> all = new ArrayList<>(BUY_TYPES);
        all.addAll(SELL_TYPES);
        return List.copyOf(all);
    }

    /**
     * Aktuális iroda összes egyenlegének lekérése
     *
     * <p>FK-074 FR-1/FR-2 (2026-08-06): a pénztári „Kassza / készlet" lista
     * ({@code GET /api/v1/cash-balances} → CashDeskPage) SZŰRVE: az inaktív
     * valutájú, nulla egyenlegű sorok nem jelennek meg; az inaktív, de nem nulla
     * egyenlegű sorok igen (adatvesztés elleni védelem). A szűrés MANDATÓRIUSAN
     * backend-oldali (FK-074 §9.4) — a frontend (CashDeskPage.tsx) változatlan.</p>
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getCurrentBranchBalances() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findByBranchIdAndCompanyIdForCashDesk(branchId, companyId);
    }

    /**
     * Egyenleg lekérése valuta alapján
     */
    @Transactional(readOnly = true)
    public CashBalance getBalanceByCurrency(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // #865: WithDetails JOIN FETCH — a controller a session lezárása UTÁN mappel DTO-ra (OSIV=false),
        // ezért a branch+currency proxynak betöltve kell lennie, különben LazyInit 500.
        return cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdWithDetails(branchId, currencyId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException(
                    "Kassza egyenleg nem található ehhez a valutához"));
    }

    /**
     * Egyenleg lekérése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public CashBalance getBalanceByCurrencyCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getBalanceByCurrency(currency.getId());
    }

    /**
     * Összes egyenleg lekérése a céghez — ÉRTÉKTÁR (is_vault=TRUE) branch-ek KIZÁRVA.
     *
     * FK-038 (2026-06-21): ez az endpoint (GET /cash-balances/company) a Dashboard „TOP Irodák",
     * „Zárási állapot (ma)" widget és a StockMatrix forrása. A cég-szintű kassza-nézet per
     * definíció PÉNZTÁR-only; az értéktár-készlet a currency_stock/vault_territory úton él, és a
     * V334/FK-036 invariáns szerint értéktárnak nincs is cash_balance sora. Defense-in-depth: ha
     * mégis „beszivárogna" ilyen sor (mint a V247-bugnál a BR020-ba), a widget akkor se listázza
     * tévesen az értéktárat. A FK-036 mintát (InventoryService.getAllStock activeNonVaultBranch)
     * követi: a kizárás a fogyasztó-specifikus metódusban, nem a megosztott findByCompanyId-ben.
     * FKH-029 kieg. óta a totals/position aggregátumok IS a kizáró queryt használják — a V371
     * után a vault cash_balance sorok könyvelési rétegként léteznek, nem pénztári készletként.
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getCompanyBalances() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findByCompanyIdExcludingVault(companyId);
    }

    /**
     * Alacsony készletű valuták
     *
     * Legacy: FIGYELMEZTETÉS - alacsony készlet
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getLowBalanceAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findLowBalances(companyId);
    }

    /**
     * Magas készletű valuták
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getHighBalanceAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return cashBalanceRepository.findHighBalances(companyId);
    }

    /**
     * Egyenleg inicializálása új irodához (Issue #110).
     *
     * A company-t a Branch entity-ből veszi — NEM függ SecurityContext-től,
     * így startup hook-ból és admin endpoint-ból is hívható egyaránt.
     *
     * Multi-tenant-safe: ha van autentikált user, a saját cégére kell, hogy érvényes legyen.
     * Ha nincs (pl. startup hook), akkor a branch.company a forrás.
     *
     * 2026-04-29 v2.3.29 (Codex P1 PR #292 follow-up):
     * `Propagation.REQUIRES_NEW` — a `BranchService.create()` parent tx-étől
     * függetlenül fut. Spring iparági pattern: ha az aux init dob, csak a saját
     * tx-et rollback-olja, a parent commit NEM kerül `UnexpectedRollbackException`-ba.
     *
     * @param branchId iroda ID
     * @return inicializált cash_balance-ok száma (0 = minden már létezett, idempotens)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public int initializeBranchBalances(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        if (branch.getCompany() == null) {
            throw new ValidationException("Branch company nincs beállítva: " + branchId);
        }

        // Multi-tenant security: ha van SecurityContext, cross-tenant init tiltott.
        // Sourcery PR #112: AccessDeniedException (401/403 HTTP) security-specific exception.
        // Audit P0.7 (2026-05-03): a korabbi `try { getCurrentCompanyId() } catch (IllegalStateException)`
        // minta TOROTT volt, mert a SecurityUtils `ValidationException`-t dob (nem `IllegalStateException`-t),
        // igy a catch SOHA nem fogott — startup/async eseten a method `ValidationException`-nel bukott el.
        //
        // Codex P1 PR #354 follow-up: `getCurrentCompanyIdOrNull()` ket eltero esetben ad null-t:
        //   1. legitim startup/async (NINCS Authentication a SecurityContext-ben)
        //   2. authentikalt request, de a JWT-bol hianyzik a companyId (rare bug/attacker)
        // A #2-es eset NEM szabad bypass-elja a tenant guard-ot. Ezert explicit auth-check:
        //   - ha NINCS authentikacio -> startup/async, skip (legitim)
        //   - ha VAN authentikacio -> `getCurrentCompanyId()` (dob ValidationException ha hianyzik)
        //     es ezutan a cross-tenant ellenorzes
        org.springframework.security.core.Authentication auth =
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        boolean hasAuthenticatedUser = auth != null
                && auth.isAuthenticated()
                && !"anonymousUser".equals(auth.getPrincipal());
        if (!hasAuthenticatedUser) {
            // Nincs autentikált user (pl. startup/async hook) — branch.company megfelelő forrás
            log.debug("initializeBranchBalances SecurityContext nélkül fut (startup/async): {}", branchId);
        } else {
            // Authentikalt: a companyId kotelezoen jelen kell legyen — `getCurrentCompanyId()` dob,
            // ha hianyzik (Codex P1 #354: malformed JWT NEM bypass-elheti a tenant guard-ot).
            UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
            if (!currentCompanyId.equals(branch.getCompany().getId())) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "Csak saját cég branch-eire inicializálhat kassza egyenleget (cross-tenant tiltott)");
            }
        }

        // FK-038 (2026-06-21): ÉRTÉKTÁR (is_vault=TRUE) branch-nek NEM szabad cash_balance
        // (pénztár-kassza) sora legyen — az értéktár-készlet a currency_stock/vault_territory
        // úton él (V334/FK-036 invariáns). Ez a write-oldali GYÖKÉR-gate: a branch-létrehozás
        // (BranchService), a bulk-init (initializeAllBranchBalancesForCurrentCompany) és a
        // session-nyitás lazy-init útvonala mind ezen a metóduson megy át, ezért itt EGY ponton
        // megakadályozzuk, hogy értéktár cash_balance sort kapjon (a V247-típusú szivárgás megelőzése).
        // Idempotens szemantika: 0 = nem jött létre rekord.
        if (Boolean.TRUE.equals(branch.getIsVault())) {
            log.info("initializeBranchBalances: ÉRTÉKTÁR branch (id={}, {}) kihagyva — értéktárnak nincs cash_balance (FK-038 invariáns)",
                    branchId, branch.getName());
            return 0;
        }

        Company company = branch.getCompany();

        // Összes aktív valutához egyenleg létrehozása
        List<Currency> currencies = currencyRepository.findAllActiveOrdered();
        int created = 0;

        for (Currency currency : currencies) {
            // Ellenőrzés, hogy nincs-e már
            if (cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(
                    branchId, currency.getId(), company.getId()).isEmpty()) {
                CashBalance balance = CashBalance.builder()
                        .company(company)
                        .branch(branch)
                        .currency(currency)
                        .currentBalance(BigDecimal.ZERO)
                        .openingBalance(BigDecimal.ZERO)
                        .build();
                cashBalanceRepository.save(balance);
                created++;
                log.debug("Kassza egyenleg inicializálva: {} - {}", branch.getName(), currency.getCode());
            }
        }

        log.info("Iroda kassza egyenlegek inicializálva: {} ({} új rekord)", branch.getName(), created);
        return created;
    }

    /**
     * Issue #110: cég összes aktív branch-jére cash_balance init (admin bulk op).
     *
     * Idempotens: csak a hiányzó (branch, currency) párosokra hoz létre 0-ás balance rekordot.
     * Használat: új currency hozzáadása után, vagy új branch létrehozása után,
     * vagy deploy utáni egyszeri "retrofit" bestelés.
     *
     * Sourcery PR #112: dedikált result record (totalCreated single-sourced).
     */
    public BulkInitResult initializeAllBranchBalancesForCurrentCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // FK-032 (2026-06-16, Codex P2 #1195): a bulk-init a VAULT_COUNTERPARTY virtuális partnereket
        // (MNB, Raiffeisen alszámlák, Úton lévő pénztár stb.) KIZÁRJA — ezek nem valódi pénztárak/értéktárak,
        // nincs készletük, ezért nem szabad cash_balance sort létrehozni nekik (különben az Országos készlet
        // FK-029/FK-032 „BESOROLATLAN" tünete VALÓDI sorokból is visszatérne, a forrásnál). A getAllStock
        // defense-in-depth csak elrejti a tünetet; ez a forrás-szintű gyökér-fix.
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);

        Map<UUID, Integer> perBranch = new LinkedHashMap<>();
        int totalCreated = 0;

        for (Branch branch : branches) {
            int created = initializeBranchBalances(branch.getId());
            perBranch.put(branch.getId(), created);
            totalCreated += created;
        }

        log.info("initializeAllBranchBalancesForCurrentCompany: company={}, {} branch, {} új rekord",
                companyId, branches.size(), totalCreated);
        return new BulkInitResult(perBranch, totalCreated, branches.size());
    }

    /**
     * Issue #110 bulk init result record — Sourcery PR #112 feedback
     * (single-sourced totalCreated, nem kell a controller-ben újraszámolni).
     */
    public record BulkInitResult(Map<UUID, Integer> perBranch, int totalCreated, int branchCount) {}

    /**
     * FK-074 FR-3 (2026-08-06): valuta aktiválásakor automatikus {@code cash_balance}
     * sor-létrehozás az aktiváló felhasználó cégének MINDEN AKTÍV branch-ére —
     * ÉRTÉKTÁRAKRA (is_vault=TRUE) IS — ha az adott valutára még nincs sor.
     *
     * <p><b>Miért NEM a {@link #initializeBranchBalances(UUID)} mintát hívja:</b> az az
     * FK-038-gátat (vault-kihagyás, ~193-197. sor) is tartalmazza, amit ez az FR NEM
     * örökölhet — a 2026-08-05-én bemergelt FKH-029/V371 architektúra-fordulat óta az
     * Értéktáraknak VAN cash_balance könyvelési rétegük, és a kihagyásuk új deviza
     * aktiválásakor visszahozná a „Kassza egyenleg nem található" hibát
     * (TransferService increase/decreaseCashBalance). Ezért EZ a metódus saját,
     * vault-t is bevonó útvonal: {@link CashBalanceRepository#insertIfAbsent}
     * branch-enként, a {@code findByCompanyIdAndIsActiveTrueExcludingCounterparties}
     * (FK-032: VAULT_COUNTERPARTY virtuális partnerek kizárva) aktív branch-halmazán.</p>
     *
     * <p><b>Idempotencia (NFR-2/FR-5):</b> {@code INSERT ... ON CONFLICT (branch_id,
     * currency_id) DO NOTHING} — dupla aktiválás NEM duplikál sort, meglévő egyenleget
     * NEM ír felül.</p>
     *
     * <p><b>Tranzakcionalitás (NFR-4):</b> a Propagation alap (REQUIRED), így a hívó
     * (AdminCurrencyService.setActive) tranzakciójában fut — bármely branch hibája
     * az egész aktiválást (az {@code is_active} állítást is) visszagörgeti.</p>
     *
     * <p><b>Cross-tenant (§6.b):</b> kizárólag a JWT-ből feloldott
     * {@code SecurityUtils.getCurrentCompanyId()} cég branch-jeit érinti.</p>
     *
     * <p><b>Audit (§3, KAT=TX):</b> aktiválási eseményenként EGY audit_log bejegyzés,
     * amely jelzi, hány fiókban jött létre új sor.</p>
     *
     * @param currency az épp aktivált valuta
     * @return az újonnan létrehozott cash_balance sorok száma (0 = minden már létezett)
     */
    public int initializeCurrencyBalancesForActiveBranches(Currency currency) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches =
                branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
        int created = 0;
        for (Branch branch : branches) {
            created += cashBalanceRepository.insertIfAbsent(companyId, branch.getId(), currency.getId());
        }
        auditLogService.log("CASH_BALANCE_AUTO_INIT",
                "FK-074: valuta aktiválása (" + sanitizeForAudit(currency.getCode())
                        + ") — automatikus cash_balance inicializálás: " + created
                        + " új sor " + branches.size() + " aktív fiókból (Értéktárakat is beleértve)",
                currency.getId());
        log.info("FK-074 CASH_BALANCE_AUTO_INIT: currency={} company={} — {} új cash_balance sor {} aktív fiókból",
                sanitizeForAudit(currency.getCode()), companyId, created, branches.size());
        return created;
    }

    /** CodeQL log/audit-injection guard: CRLF + control character stripping (AdminCurrencyService mintája). */
    private static String sanitizeForAudit(String value) {
        if (value == null) return "<null>";
        return value.replaceAll("[\\r\\n\\t\\x00-\\x1F\\x7F]", "_");
    }

    /**
     * HIGH FIX #9: Negatív készlet ellenőrzés ELADÁSNÁL.
     * Ellenőrzi, hogy az adott valutából van-e elegendő készlet a kiadáshoz.
     *
     * @param currencyId valuta ID
     * @param amount     kiadandó összeg
     * @throws ValidationException ha nincs elegendő készlet (negatívba menne)
     */
    public void validateSufficientBalance(Long currencyId, BigDecimal amount) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CashBalance balance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException(String.format(
                "Nincs elegendő %s készlet! Jelenlegi: %s, szükséges: %s",
                balance.getCurrency().getCode(),
                balance.getCurrentBalance().toPlainString(),
                amount.toPlainString()));
        }
    }

    /**
     * Egyenleg kézi módosítása (pénztár feltöltés/levétel)
     *
     * Legacy: PENZTARFELTOLTES, PENZTARLEVONÁS
     */
    public CashBalance adjustBalance(AdjustBalanceRequest request) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        // Manager vagy magasabb szint kell
        if (!SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Egyenleg módosításhoz manager jogosultság szükséges!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CashBalance balance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, request.getCurrencyId(), companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        BigDecimal oldBalance = balance.getCurrentBalance();

        if (request.isIncoming()) {
            balance.addBalance(request.getAmount());
            log.info("Kassza feltöltés: {} {} - {} -> {}",
                    balance.getCurrency().getCode(), request.getAmount(),
                    oldBalance, balance.getCurrentBalance());
        } else {
            // HIGH FIX #9: Negatív készlet ellenőrzés — ne lehessen mínuszba menni
            if (balance.getCurrentBalance().compareTo(request.getAmount()) < 0) {
                throw new ValidationException(String.format(
                    "Nincs elegendő %s egyenleg a levonáshoz! Jelenlegi: %s, kért: %s",
                    balance.getCurrency().getCode(),
                    balance.getCurrentBalance().toPlainString(),
                    request.getAmount().toPlainString()));
            }
            balance.subtractBalance(request.getAmount());
            log.info("Kassza levonás: {} {} - {} -> {}",
                    balance.getCurrency().getCode(), request.getAmount(),
                    oldBalance, balance.getCurrentBalance());
        }

        CashBalance saved = cashBalanceRepository.save(balance);
        auditCashBalanceAdjust(saved, oldBalance, request);
        // #865: a controller (POST /adjust) a session lezárása UTÁN mappel DTO-ra (OSIV=false) →
        // a lazy branch/currency proxyt itt, a tranzakción belül inicializáljuk a LazyInit 500 ellen.
        org.hibernate.Hibernate.initialize(saved.getBranch());
        org.hibernate.Hibernate.initialize(saved.getCurrency());
        return saved;
    }

    private void auditCashBalanceAdjust(CashBalance saved, BigDecimal oldBalance, AdjustBalanceRequest request) {
        BigDecimal newBalance = saved.getCurrentBalance();
        String direction = request.isIncoming() ? "feltöltés" : "levonás";
        String currencyCode = saved.getCurrency() != null && saved.getCurrency().getCode() != null
                ? saved.getCurrency().getCode()
                : String.valueOf(request.getCurrencyId());
        String message = String.format("Kassza %s: %s %s (%s -> %s)",
                direction,
                request.getAmount().toPlainString(),
                currencyCode,
                oldBalance.toPlainString(),
                newBalance.toPlainString());
        if (request.getReason() != null && !request.getReason().isBlank()) {
            message = message + "; indok: " + request.getReason();
        }

        auditLogService.logWithDetails(
                "CASH_BALANCE_ADJUST",
                "CASH_BALANCE",
                saved.getId() != null ? saved.getId().toString() : null,
                SecurityUtils.getCurrentWorkerId().toString(),
                SecurityUtils.getCurrentWorkerCode(),
                saved.getBranch() != null && saved.getBranch().getId() != null
                        ? saved.getBranch().getId().toString()
                        : SecurityUtils.getCurrentBranchId().toString(),
                saved.getBranch() != null ? saved.getBranch().getName() : null,
                oldBalance.toPlainString(),
                newBalance.toPlainString(),
                message,
                null);
    }

    /**
     * Min/max limitek beállítása
     */
    public CashBalance setLimits(SetLimitsRequest request) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        if (!SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Limit beállításhoz manager jogosultság szükséges!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CashBalance balance = cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, request.getCurrencyId(), companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        if (request.getMinBalance() != null) {
            balance.setMinBalance(request.getMinBalance());
        }
        if (request.getMaxBalance() != null) {
            balance.setMaxBalance(request.getMaxBalance());
        }

        log.info("Kassza limitek frissítve: {} - min: {}, max: {}",
                balance.getCurrency().getCode(), balance.getMinBalance(), balance.getMaxBalance());

        return cashBalanceRepository.save(balance);
    }

    /**
     * Kassza összesítő (összes PÉNZTÁRI iroda).
     *
     * FKH-029 kieg. (FR-6 kiterjesztés): a V371 óta minden Értéktárnak van cash_balance
     * KÖNYVELÉSI sora, és a Transfer forgalmat is könyvel rá — a korábbi „szándékosan sima
     * findByCompanyId" döntés ezért megfordult. A pénztári cégösszesítő
     * (GET /cash-balances/company-totals — TreasuryDashboard valutaszám-kártya) a
     * vault+VAULT_COUNTERPARTY-kizáró queryből aggregál, konzisztensen a
     * TreasuryDashboardService.isExcludedFromCashierTotals (FKH-029 FR-6) szűrésével.
     * A vault-készlet helyes megjelenítési helye a currency_stock-alapú vault-nézet.
     */
    @Transactional(readOnly = true)
    public List<CurrencyTotalBalance> getCompanyTotals() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyIdExcludingVault(companyId);

        return allBalances.stream()
                .collect(Collectors.groupingBy(
                    cb -> cb.getCurrency().getCode(),
                    Collectors.reducing(
                        BigDecimal.ZERO,
                        CashBalance::getCurrentBalance,
                        BigDecimal::add
                    )
                ))
                .entrySet().stream()
                .map(e -> new CurrencyTotalBalance(e.getKey(), e.getValue()))
                .collect(Collectors.toList());
    }

    /**
     * Napi egyenleg pillanatkép
     *
     * Legacy: PILLALL - pillanat állás
     */
    @Transactional(readOnly = true)
    public BranchBalanceSummary getBranchSummary() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);

        BigDecimal totalHuf = BigDecimal.ZERO;
        int lowAlerts = 0;
        int highAlerts = 0;

        for (CashBalance balance : balances) {
            if ("HUF".equals(balance.getCurrency().getCode())) {
                totalHuf = balance.getCurrentBalance();
            }
            if (balance.isLowBalance()) lowAlerts++;
            if (balance.isHighBalance()) highAlerts++;
        }

        return BranchBalanceSummary.builder()
                .totalCurrencies(balances.size())
                .hufBalance(totalHuf)
                .lowBalanceAlerts(lowAlerts)
                .highBalanceAlerts(highAlerts)
                .balances(balances)
                .build();
    }

    /**
     * FK-075 FR-5/FR-6 (2026-08-06): élő „Mai statisztika" a CashDeskPage-nek.
     *
     * <p>A pénztári „Kassza / készlet" oldal Mai statisztika panelje korábban a tárolt
     * napi-munkamenet-számlálókból (DailySession.transactionCount / buyTurnoverHuf /
     * sellTurnoverHuf / handlingFeeTotal) élt. Ez a metódus Ehelyett a mai nap tényleges,
     * aktuális fiókra szűrt tranzakcióiból számol ÉLŐBEN — a {@code GET /daily-sessions/current}
     * végpont változatlan marad (MainLayout fejléc is használja).</p>
     *
     * <p>Szemantika (DailySession.addTransaction mintájára):</p>
     * <ul>
     *   <li>Tranzakció-darabszám: BUY/SELL típuscsalád ({@link TransactionType#isBuyType()} /
     *       {@link TransactionType#isSellType()}) — a panel Vétel/Eladás összegeivel koherens
     *       halmaz. A konverzió BUY+SELL lábai külön-külön számítanak (ahogy a DailySessionnél).</li>
     *   <li>Vétel/Eladás összesen: header-szintű hufAmount összeg (multi-line fej = teljes HUF).</li>
     *   <li>Kezelési díj: header-szintű handlingFee összeg ugyanerre a halmazra — megegyezik a
     *       DailySession.handlingFeeTotal képzési szabályával (a sztornó 0 díjat ad).</li>
     * </ul>
     *
     * <p>Tudatos eltérések a tárolt DailySession-számlálóktól (dokumentált döntés):</p>
     * <ul>
     *   <li>Csak {@code COMPLETED} státuszú tranzakciók számítanak — a sztornózott
     *       ({@code REVERSED}) tételek nem növelik az élő statisztikát, míg a tárolt
     *       számlálókat a sztornó nem csökkentette.</li>
     *   <li>A darabszám a BUY/SELL családra szűk — REVERSAL/PARTIAL_REFUND/TRANSFER stb.
     *       nem szerepel benne (a tárolt transactionCount ezeket is számolta).</li>
     * </ul>
     */
    @Transactional(readOnly = true)
    public TodayStats getTodayStats() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();

        long transactions = transactionRepository.countCompletedByBranchAndDateAndTypes(
                companyId, branchId, today, BUY_AND_SELL_TYPES);
        BigDecimal buyTotal = transactionRepository.sumCompletedTurnoverByBranchAndDateAndTypes(
                companyId, branchId, today, BUY_TYPES);
        BigDecimal sellTotal = transactionRepository.sumCompletedTurnoverByBranchAndDateAndTypes(
                companyId, branchId, today, SELL_TYPES);
        BigDecimal handlingFee = transactionRepository.sumCompletedHandlingFeeByBranchAndDateAndTypes(
                companyId, branchId, today, BUY_AND_SELL_TYPES);

        return TodayStats.builder()
                .transactions(transactions)
                .buyTotal(buyTotal)
                .sellTotal(sellTotal)
                .handlingFee(handlingFee)
                .build();
    }

    /**
     * Részletes pillanat állás HUF egyenértékekkel
     *
     * Legacy: PILLALL - pillanat állás részletes
     * - Minden valuta egyenleg
     * - Aktuális árfolyam
     * - HUF egyenérték
     * - Napi változás
     */
    @Transactional(readOnly = true)
    public DetailedCashPosition getDetailedCashPosition() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        List<CashPositionItem> items = new ArrayList<>();

        BigDecimal totalHufValue = BigDecimal.ZERO;
        BigDecimal totalOpeningHufValue = BigDecimal.ZERO;
        int lowAlerts = 0;
        int highAlerts = 0;

        for (CashBalance balance : balances) {
            Currency currency = balance.getCurrency();
            BigDecimal currentBalance = balance.getCurrentBalance();
            BigDecimal openingBalance = balance.getOpeningBalance() != null ? balance.getOpeningBalance() : BigDecimal.ZERO;

            // Árfolyam lekérése
            BigDecimal rate = BigDecimal.ONE; // HUF-nak 1
            BigDecimal buyRate = BigDecimal.ONE;
            BigDecimal sellRate = BigDecimal.ONE;

            if (!"HUF".equals(currency.getCode())) {
                Optional<ExchangeRate> exchangeRate = exchangeRateRepository.findLatestRate(companyId, currency.getId(), branchId);
                if (exchangeRate.isPresent()) {
                    ExchangeRate er = exchangeRate.get();
                    if (er.getBaseBuyRate() != null && er.getBaseSellRate() != null) {
                        buyRate = er.getBaseBuyRate();
                        sellRate = er.getBaseSellRate();
                        // Középárfolyam HUF értékhez
                        rate = buyRate.add(sellRate).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
                    }
                }
            }

            // HUF egyenérték számítás
            BigDecimal hufValue = currentBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal openingHufValue = openingBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal dailyChange = currentBalance.subtract(openingBalance);
            BigDecimal dailyChangeHuf = hufValue.subtract(openingHufValue);

            totalHufValue = totalHufValue.add(hufValue);
            totalOpeningHufValue = totalOpeningHufValue.add(openingHufValue);

            if (balance.isLowBalance()) lowAlerts++;
            if (balance.isHighBalance()) highAlerts++;

            CashPositionItem item = CashPositionItem.builder()
                    .currencyId(currency.getId())
                    .currencyCode(currency.getCode())
                    .currencyName(currency.getName())
                    .currentBalance(currentBalance)
                    .openingBalance(openingBalance)
                    .dailyChange(dailyChange)
                    .buyRate(buyRate)
                    .sellRate(sellRate)
                    .midRate(rate)
                    .hufValue(hufValue)
                    .openingHufValue(openingHufValue)
                    .dailyChangeHuf(dailyChangeHuf)
                    .minBalance(balance.getMinBalance())
                    .maxBalance(balance.getMaxBalance())
                    .isLowBalance(balance.isLowBalance())
                    .isHighBalance(balance.isHighBalance())
                    .lastTransactionAt(balance.getLastTransactionAt())
                    .build();

            items.add(item);
        }

        return DetailedCashPosition.builder()
                .branchId(branchId)
                .timestamp(LocalDateTime.now())
                .items(items)
                .totalHufValue(totalHufValue)
                .totalOpeningHufValue(totalOpeningHufValue)
                .totalDailyChangeHuf(totalHufValue.subtract(totalOpeningHufValue))
                .currencyCount(items.size())
                .lowBalanceAlerts(lowAlerts)
                .highBalanceAlerts(highAlerts)
                .build();
    }

    /**
     * Cég szintű pillanat állás (összes PÉNZTÁRI iroda összesítve).
     *
     * FKH-029 kieg.: a TreasuryDashboard fő „Összes készletérték" számának forrása
     * (GET /cash-balances/company-position). Vault+VAULT_COUNTERPARTY-kizárással aggregál,
     * különben az értéktári könyvelési sorok az első valós vault-forgalomnál beömlenének, és a
     * /treasury/dashboard (FR-6-szűrt) számaival szétcsúszna ugyanazon az oldalon.
     */
    @Transactional(readOnly = true)
    public CompanyCashPosition getCompanyCashPosition() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyIdExcludingVault(companyId);

        // Csoportosítás valutánként
        List<CompanyCurrencyPosition> currencyPositions = allBalances.stream()
                .collect(Collectors.groupingBy(cb -> cb.getCurrency().getCode()))
                .entrySet().stream()
                .map(entry -> {
                    String currencyCode = entry.getKey();
                    List<CashBalance> balances = entry.getValue();

                    BigDecimal totalBalance = balances.stream()
                            .map(CashBalance::getCurrentBalance)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    int branchCount = balances.size();

                    // Árfolyam (első elem alapján)
                    BigDecimal rate = BigDecimal.ONE;
                    if (!"HUF".equals(currencyCode) && !balances.isEmpty()) {
                        CashBalance first = balances.get(0);
                        Optional<ExchangeRate> er = exchangeRateRepository.findLatestRate(
                                companyId, first.getCurrency().getId(), first.getBranch().getId());
                        if (er.isPresent()
                                && er.get().getBaseBuyRate() != null
                                && er.get().getBaseSellRate() != null) {
                            rate = er.get().getBaseBuyRate().add(er.get().getBaseSellRate())
                                    .divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
                        }
                    }

                    BigDecimal hufValue = totalBalance.multiply(rate).setScale(0, RoundingMode.HALF_UP);

                    return CompanyCurrencyPosition.builder()
                            .currencyCode(currencyCode)
                            .totalBalance(totalBalance)
                            .branchCount(branchCount)
                            .hufValue(hufValue)
                            .build();
                })
                .collect(Collectors.toList());

        BigDecimal grandTotalHuf = currencyPositions.stream()
                .map(CompanyCurrencyPosition::getHufValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CompanyCashPosition.builder()
                .companyId(companyId)
                .timestamp(LocalDateTime.now())
                .currencyPositions(currencyPositions)
                .grandTotalHuf(grandTotalHuf)
                .build();
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class AdjustBalanceRequest {
        private Long currencyId;
        private BigDecimal amount;
        private boolean incoming;
        private String reason;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SetLimitsRequest {
        private Long currencyId;
        private BigDecimal minBalance;
        private BigDecimal maxBalance;
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    public static class CurrencyTotalBalance {
        private String currencyCode;
        private BigDecimal totalBalance;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BranchBalanceSummary {
        private int totalCurrencies;
        private BigDecimal hufBalance;
        private int lowBalanceAlerts;
        private int highBalanceAlerts;
        private List<CashBalance> balances;
    }

    /**
     * FK-075 FR-5/FR-6 (2026-08-06): a Mai statisztika panel élő, tranzakció-alapú adatai.
     * JSON: { transactions, buyTotal, sellTotal, handlingFee }.
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class TodayStats {
        private long transactions;
        private BigDecimal buyTotal;
        private BigDecimal sellTotal;
        private BigDecimal handlingFee;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CashPositionItem {
        private Long currencyId;
        private String currencyCode;
        private String currencyName;
        private BigDecimal currentBalance;
        private BigDecimal openingBalance;
        private BigDecimal dailyChange;
        private BigDecimal buyRate;
        private BigDecimal sellRate;
        private BigDecimal midRate;
        private BigDecimal hufValue;
        private BigDecimal openingHufValue;
        private BigDecimal dailyChangeHuf;
        private BigDecimal minBalance;
        private BigDecimal maxBalance;
        private boolean isLowBalance;
        private boolean isHighBalance;
        private LocalDateTime lastTransactionAt;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DetailedCashPosition {
        private UUID branchId;
        private LocalDateTime timestamp;
        private List<CashPositionItem> items;
        private BigDecimal totalHufValue;
        private BigDecimal totalOpeningHufValue;
        private BigDecimal totalDailyChangeHuf;
        private int currencyCount;
        private int lowBalanceAlerts;
        private int highBalanceAlerts;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CompanyCurrencyPosition {
        private String currencyCode;
        private BigDecimal totalBalance;
        private int branchCount;
        private BigDecimal hufValue;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class CompanyCashPosition {
        private UUID companyId;
        private LocalDateTime timestamp;
        private List<CompanyCurrencyPosition> currencyPositions;
        private BigDecimal grandTotalHuf;
    }
}
