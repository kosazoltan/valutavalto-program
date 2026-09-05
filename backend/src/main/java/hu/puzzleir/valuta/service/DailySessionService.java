package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DenominationCountRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Napi munkamenet szolgáltatás.
 *
 * Legacy: HARDWARE tábla MEGNYITOTTNAP, NAPZAR funkció
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DailySessionService {

    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationCountRepository denominationCountRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    // Issue #110: auto-init cash_balance rekordok napnyitaskor, hogy a tranzakcio-sync
    // ne essen el 404-gyel uj branch-eken, ahol meg nincs inicializalva semmi.
    private final CashBalanceService cashBalanceService;
    // FKH-048: regional vault scope post-filter for the read side (getSessionHistory).
    private final AccessScopeService accessScopeService;

    /**
     * Napi nyitás
     *
     * Legacy: NAPIKEZD - VTEMP inicializálás
     */
    public DailySession openDay() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        LocalDate today = LocalDate.now();

        // FK-038 (2026-06-21): értéktári (is_vault=TRUE) fiók NEM nyithat napi pénztári munkamenetet.
        // Az értéktárnak nincs pénztári napizárása (a zárás a VaultClosingChecklist + ClosingControl
        // úton megy, a készlet a currency_stock/vault_territory-ban él), és egy vault daily_session
        // tévesen megjelenne a Dashboard „Zárási állapot (ma)" widget A-forrásában. A gate a metódus
        // ELEJÉN áll, hogy a REOPEN- és az új-session-ágat is fedje, bármilyen mellékhatás előtt.
        Branch vaultGuardBranch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (Boolean.TRUE.equals(vaultGuardBranch.getIsVault())) {
            throw new ValidationException("Értéktári fiók nem nyithat napi pénztári munkamenetet");
        }

        // FKH-051: the destructive stale-session force-close loop was REMOVED.
        // A past OPEN day now survives openDay; the retroactive closing flow
        // (FKH-050, /closing/retroactive) is the sanctioned way to close it.

        // Ellenőrzés: nincs-e már MAI session
        Optional<DailySession> existingOpt = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today);
        if (existingOpt.isPresent()) {
            DailySession existing = existingOpt.get();

            if (existing.getStatus() == DailySessionStatus.OPEN) {
                throw new ValidationException("Már van nyitott napi munkamenet!");
            }

            // REOPEN: ha mai session CLOSED → újranyitás engedélyezett
            if (existing.getStatus() == DailySessionStatus.CLOSED) {
                Worker worker = workerRepository.findById(workerId)
                        .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

                existing.setStatus(DailySessionStatus.OPEN);
                existing.setOpenedByWorker(worker);
                existing.setOpenedAt(LocalDateTime.now());
                existing.setClosedByWorker(null);
                existing.setClosedAt(null);
                existing.setClosingBalanceHuf(null);
                existing.setDenominationVerified(false);

                DailySession saved = dailySessionRepository.save(existing);

                // Kassza egyenlegek napi nyitás
                updateCashBalancesForOpening(companyId, branchId);

                log.info("Napi újranyitás (REOPEN): {} - {} - pénztáros: {}",
                        existing.getBranch().getName(), today, worker.getName());

                return saved;
            }

            // PENDING_CLOSE vagy egyéb → nem lehet nyitni
            throw new ValidationException("Mai napra már létezik munkamenet ezen az irodán! Státusz: "
                    + existing.getStatus().getDisplayName());
        }

        // FKH-051 (plan D1): the previous-day hard block ("Az előző nap nincs
        // lezárva!") was REMOVED — with the force-close loop gone it would newly
        // block openDay. Day-open stays warning-only (validateSessionOpen).

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        // FK-038: a branch-et a metódus elején már betöltöttük (vaultGuardBranch) — újrahasznosítjuk.
        Branch branch = vaultGuardBranch;

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Nyitó egyenleg számítása (HUF)
        BigDecimal openingBalance = calculateOpeningBalance(companyId, branchId);

        // Munkamenet létrehozása
        DailySession session = DailySession.builder()
                .company(company)
                .branch(branch)
                .sessionDate(today)
                .status(DailySessionStatus.OPEN)
                .openedByWorker(worker)
                .openedAt(LocalDateTime.now())
                .openingBalanceHuf(openingBalance)
                .build();

        DailySession saved = dailySessionRepository.save(session);

        // Kassza egyenlegek napi nyitása
        updateCashBalancesForOpening(companyId, branchId);

        log.info("Napi nyitás: {} - {} - nyitó egyenleg: {} HUF",
                branch.getName(), today, openingBalance);

        return saved;
    }

    /**
     * Napi zárás
     *
     * Legacy: NAPZAR - cimletezés validálás, adatfeltöltés
     */
    public DailySession closeDay(boolean denominationVerified) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        LocalDate today = LocalDate.now();

        // Aktuális session lekérése
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today)
                .orElseThrow(() -> new ValidationException("Nincs nyitott napi munkamenet!"));

        if (session.getStatus() != DailySessionStatus.OPEN) {
            throw new ValidationException("A nap már le van zárva!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Záró egyenleg számítása
        BigDecimal closingBalance = calculateClosingBalance(companyId, branchId);

        // Zárás
        session.setStatus(DailySessionStatus.CLOSED);
        session.setClosedByWorker(worker);
        session.setClosedAt(LocalDateTime.now());
        session.setClosingBalanceHuf(closingBalance);
        session.setDenominationVerified(denominationVerified);

        DailySession saved = dailySessionRepository.save(session);

        log.info("Napi zárás: {} - {} - záró egyenleg: {} HUF, tranzakciók: {}",
                session.getBranch().getName(), today, closingBalance, session.getTransactionCount());

        return saved;
    }

    /**
     * Aktuális nyitott session lekérése
     */
    @Transactional(readOnly = true)
    public DailySession getCurrentSession() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDateWithDetails(companyId, branchId, today)
                .filter(s -> s.getStatus() == DailySessionStatus.OPEN)
                .orElseThrow(() -> new ValidationException("Nincs nyitott napi munkamenet!"));
    }

    /**
     * A mai session lekérése BÁRMELY státusszal (kanban #4, FR-3).
     *
     * <p>A {@link #getCurrentSession()} csak OPEN státuszú sessiont ad vissza
     * (ugyanaz a query, státusz-szűrővel), ezért napzárás után mindig
     * {@link ValidationException}-t dob — a renderer ebből sosem tudhatná meg,
     * hogy a nap LEZÁRULT (a napzárás utáni telepítési ablak állapota,
     * {@code CLOSED_AFTER_DAY_END}). Ez a metódus ADDITÍV (FK-075 §7): a mai
     * sessiont bármely státusszal adja vissza, rekord hiányában
     * {@link Optional#empty()}-t — nem dob kivételt. A tenant-szűrés
     * (companyId + branchId) a security contextből jön, ugyanúgy, ahogy a
     * {@link #getCurrentSession()} esetén, így más cég/iroda rekordja nem
     * kerülhet vissza.
     */
    @Transactional(readOnly = true)
    public Optional<DailySession> findTodaySession() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDateWithDetails(companyId, branchId, today);
    }

    /**
     * Van-e nyitott session?
     */
    @Transactional(readOnly = true)
    public boolean hasOpenSession() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return dailySessionRepository.hasOpenSession(companyId, branchId);
    }

    /**
     * Session statisztikák frissítése tranzakció után
     */
    public void updateSessionStats(TransactionType type, BigDecimal hufAmount, BigDecimal handlingFee) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today)
                .orElseThrow(() -> new ValidationException("Nincs nyitott napi munkamenet!"));

        session.addTransaction(type, hufAmount, handlingFee);
        dailySessionRepository.save(session);
    }

    /**
     * Napi sztornók számának ellenőrzése
     *
     * Legacy: NAPISTORNO - 3+ napi sztornó után supervisor jóváhagyás kell
     */
    @Transactional(readOnly = true)
    public int getDailyReversalCount() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today)
                .map(DailySession::getReversalCount)
                .orElse(0);
    }

    /**
     * Napi sztornók számának lekérése PESSIMISTIC_WRITE lockkal — a sztornó-plafon
     * KIKÉNYSZERÍTÉSI útjához (TransactionReversalService.executeReversal).
     *
     * Codex P1 (2026-05-31, #944 review): a lock-mentes {@link #getDailyReversalCount()} csak
     * megjelenítésre jó (DailySessionController). A plafon-ellenőrzés ELŐTT ezt kell hívni: a
     * daily_session sorát SELECT ... FOR UPDATE lockolja, így a párhuzamos sztornó a lock mögött
     * sorba áll, és a count olvasása+növelése (updateSessionStats, ugyanaz a write-tranzakció)
     * szerializálódik → a nap nem kerülhet a max-3 plafon fölé. NEM readOnly: write-lockot szerez,
     * a hívó (executeReversal) @Transactional(rollbackFor=Exception.class) tranzakciójához
     * csatlakozik (REQUIRED), a lock annak commitjáig él.
     *
     * FAIL-LOUD (self-review P2, 2026-05-31): a hívó executeReversal MÁR elvégezte a
     * validateOpenSession()-t, ezért MAI napra MINDIG van OPEN sor a lock-pontnál. Ha a lockolt
     * lekérdezés mégis üres (pl. párhuzamos napzárás közben), az invariáns-sértés → DOBUNK, NEM
     * 0-t adunk vissza. A némán-0 a sztornó-plafont csendben kikerülné; a dobás inkább blokkolja a
     * sztornót (a helyes, biztonságos kimenet). A megjelenítő {@link #getDailyReversalCount()}
     * toleráns marad (0-t ad), mert ott nincs invariáns-kockázat.
     */
    public int getDailyReversalCountForUpdate() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDateAndCompanyIdForUpdate(branchId, today, companyId)
                .map(DailySession::getReversalCount)
                .orElseThrow(() -> new ValidationException(
                        "Nincs nyitott napi munkamenet a sztorno-plafon ellenorzesehez!"));
    }

    /**
     * Nap zarasa (napzaras utan hivodik).
     * Legacy: HARDWARE.LEZARTNAP = aktualis datum
     */
    public void closeSession(LocalDate closingDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, closingDate)
                .orElseThrow(() -> new ValidationException("Nincs munkamenet erre a napra: " + closingDate));

        session.setStatus(DailySessionStatus.CLOSED);
        session.setClosedAt(LocalDateTime.now());
        session.setClosingBalanceHuf(calculateClosingBalance(companyId, branchId));

        dailySessionRepository.save(session);
        log.info("Napi munkamenet lezarva: datum={}, iroda={}", closingDate, branchId);
    }

    /**
     * Nyitó egyenleg számítása
     */
    private BigDecimal calculateOpeningBalance(UUID companyId, UUID branchId) {
        // Legacy-parity: ha van lezart elozo napi session, annak zaro egyenlege lesz a nyito.
        var latestSessionOpt = dailySessionRepository.findLatest(companyId, branchId);
        if (latestSessionOpt.isPresent()) {
            DailySession latestSession = latestSessionOpt.get();
            if (latestSession.getStatus() == DailySessionStatus.CLOSED
                    && latestSession.getClosingBalanceHuf() != null) {
                return latestSession.getClosingBalanceHuf();
            }
        }

        // Fallback: aktualis kasszaegyenlegbol szamolunk.
        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        // Csak HUF egyenleg (currency_id = 1 feltételezve, vagy code = 'HUF')
        return balances.stream()
                .filter(this::isHufBalance)
                .map(cb -> cb.getCurrentBalance() != null ? cb.getCurrentBalance() : BigDecimal.ZERO)
                .findFirst()
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Záró egyenleg számítása
     *
     * A záró egyenleg a HUF kassza aktuális egyenlege, ami tartalmazza a nap folyamán
     * végrehajtott összes tranzakció (vétel, eladás, kezelési díjak stb.) hatását.
     */
    private BigDecimal calculateClosingBalance(UUID companyId, UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        return balances.stream()
                .filter(this::isHufBalance)
                .map(cb -> cb.getCurrentBalance() != null ? cb.getCurrentBalance() : BigDecimal.ZERO)
                .findFirst()
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Kassza egyenlegek frissítése nyitáskor.
     *
     * Issue #110: elso lepes az idempotens auto-init — ha uj branch,
     * minden aktiv currency-re letrehozza a 0-s balance rekordokat.
     * Igy a tranzakcio-sync nem esik el 404-gyel.
     */
    private void updateCashBalancesForOpening(UUID companyId, UUID branchId) {
        // Issue #110: idempotens auto-init
        cashBalanceService.initializeBranchBalances(branchId);

        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        for (CashBalance balance : balances) {
            if (balance.getCurrentBalance() == null) {
                String currencyCode = balance.getCurrency() != null ? balance.getCurrency().getCode() : "UNKNOWN";
                log.warn("CashBalance currentBalance null nyitáskor, null-safe korrekció: branchId={}, currency={}",
                        branchId, currencyCode);
                balance.setCurrentBalance(BigDecimal.ZERO);
            }
            if (balance.getVersion() == null) {
                String currencyCode = balance.getCurrency() != null ? balance.getCurrency().getCode() : "UNKNOWN";
                log.warn("CashBalance version null nyitáskor, optimistic-lock null-safe korrekció: branchId={}, currency={}",
                        branchId, currencyCode);
                balance.setVersion(0L);
            }
            balance.setDailyOpening();
            cashBalanceRepository.save(balance);
        }
    }

    private boolean isHufBalance(CashBalance cashBalance) {
        return cashBalance != null
                && cashBalance.getCurrency() != null
                && "HUF".equalsIgnoreCase(cashBalance.getCurrency().getCode());
    }

    /**
     * Session történet lekérése
     */
    @Transactional(readOnly = true)
    public List<DailySession> getSessionHistory(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // FK-038 (2026-06-21): az értéktár (is_vault=TRUE) kizárva — ez a Dashboard „Zárási állapot
        // (ma)" widget A-forrása; egy (legacy) vault daily_session sem jelenhet meg a pénztári
        // zárás-állapot csempén. Az értéktár pénztári napizárást eleve nem nyit (openDay/openSession
        // gate); ez a read-oldali defense-in-depth.
        List<DailySession> sessions =
                dailySessionRepository.findByDateRangeExcludingVault(companyId, startDate, endDate);
        // FKH-048: a regional vault worker must only see cash desks of their own region —
        // post-filter with the same AccessScopeService mechanism CashBalanceController.getCompanyBalances
        // uses. scope == null means company-wide (national vault / non-vault roles): return unchanged
        // (FR-3). An EMPTY scope is a real value meaning "see nothing" — never bypass it.
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope == null) {
            return sessions;
        }
        return sessions.stream()
                .filter(s -> accessScopeService.isBranchVisible(scope,
                        s.getBranch() == null ? null : s.getBranch().getId().toString()))
                .toList();
    }

    /**
     * Napi zárás validáció - címletezések ellenőrzése
     *
     * Legacy: NapzarControl hibakódok
     * - 0: rendben
     * - 1: esti címletezés hibás (valuta pénztár)
     * - 2: kezelési díj címletezés hibás
     * - 3: Western Union címletezés hibás
     * - 4: ÁFA pénztár címletezés hibás
     * - 5: e-kereskedelem címletezés hibás
     */
    @Transactional(readOnly = true)
    public DailyClosingValidation validateDailyClosing() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        DailyClosingValidation validation = new DailyClosingValidation();
        validation.setValidationDate(today);

        // 1. Valuta pénztár (esti zárás) ellenőrzés
        long currencyNotReady = denominationCountRepository.countNotReady(branchId, today, 1);
        validation.setCurrencyDenominationOk(currencyNotReady == 0);
        if (currencyNotReady > 0) {
            validation.setErrorCode(1);
            validation.setErrorMessage("Esti címletezés hibás - valuta pénztár nem egyezik");
            return validation;
        }

        // 2. Kezelési díj ellenőrzés
        long handlingFeeNotReady = denominationCountRepository.countNotReady(branchId, today, 2);
        validation.setHandlingFeeDenominationOk(handlingFeeNotReady == 0);
        if (handlingFeeNotReady > 0) {
            validation.setErrorCode(2);
            validation.setErrorMessage("Kezelési díj címletezés hibás");
            return validation;
        }

        // 3. Western Union ellenőrzés
        long wuNotReady = denominationCountRepository.countNotReady(branchId, today, 3);
        validation.setWesternUnionDenominationOk(wuNotReady == 0);
        if (wuNotReady > 0) {
            validation.setErrorCode(3);
            validation.setErrorMessage("Western Union címletezés hibás");
            return validation;
        }

        // 4. ÁFA pénztár ellenőrzés
        long vatNotReady = denominationCountRepository.countNotReady(branchId, today, 4);
        validation.setVatDenominationOk(vatNotReady == 0);
        if (vatNotReady > 0) {
            validation.setErrorCode(4);
            validation.setErrorMessage("ÁFA pénztár címletezés hibás");
            return validation;
        }

        // 5. E-kereskedelem ellenőrzés
        long ecomNotReady = denominationCountRepository.countNotReady(branchId, today, 6);
        validation.setEcommerceDenominationOk(ecomNotReady == 0);
        if (ecomNotReady > 0) {
            validation.setErrorCode(5);
            validation.setErrorMessage("E-kereskedelem címletezés hibás");
            return validation;
        }

        // Minden rendben
        validation.setErrorCode(0);
        validation.setErrorMessage("Minden címletezés rendben");
        validation.setAllValid(true);

        return validation;
    }

    /**
     * Napi zárás végrehajtása validációval
     *
     * Legacy: NAPZAR - teljes napi zárás folyamat
     */
    public DailySession closeDayWithValidation() {
        // Először validáljuk a címletezéseket
        DailyClosingValidation validation = validateDailyClosing();

        if (!validation.isAllValid()) {
            throw new ValidationException("Napi zárás nem lehetséges: " + validation.getErrorMessage());
        }

        // Ha minden rendben, zárjuk a napot
        return closeDay(true);
    }

    // ============ DTO-K ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyClosingValidation {
        private LocalDate validationDate;
        private int errorCode;
        private String errorMessage;
        private boolean allValid;
        private boolean currencyDenominationOk;
        private boolean handlingFeeDenominationOk;
        private boolean westernUnionDenominationOk;
        private boolean vatDenominationOk;
        private boolean ecommerceDenominationOk;
    }
}
