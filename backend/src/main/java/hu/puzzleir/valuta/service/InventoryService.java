package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.inventory.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Készlet mozgás kezelő service.
 *
 * Legacy: keszup.dll (bank↔pénztár), atadvet.dll (irodák közti),
 * keszedit.dll (korrekció), penztarak.dll (összesítő nézet)
 */
@Service
@RequiredArgsConstructor
public class InventoryService {

    private static final Logger log = LoggerFactory.getLogger(InventoryService.class);

    private final InventoryMovementRepository movementRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final WorkerRepository workerRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final AuditLogRepository auditLogRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final hu.puzzleir.valuta.repository.CurrencyStockRepository currencyStockRepository;

    private static final DateTimeFormatter REF_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    // ============ BANK OPERATIONS ============

    /**
     * Bank → pénztár valuta kivét kérés (PENDING státusz).
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto requestBankWithdraw(BankWithdrawRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(null) // bank = null
                .toBranch(branch)
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(calculateHufValue(currency, dto.getAmount()))
                .movementType(MovementType.BANK_WITHDRAW)
                .status(MovementStatus.PENDING)
                .initiatedBy(worker)
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    /**
     * Pénztár → bank befizetés (PENDING státusz — négy-szem elv).
     * A CashBalance csökkentés csak jóváhagyáskor (approveMovement) történik.
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto depositToBank(BankDepositRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        // Ellenőrzés: van-e elegendő készlet
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));

        if (balance.getCurrentBalance().compareTo(dto.getAmount()) < 0) {
            throw new ValidationException("Nincs elegendő készlet! Egyenleg: "
                    + balance.getCurrentBalance().setScale(4, RoundingMode.HALF_UP)
                    + ", kért: " + dto.getAmount());
        }

        // Négy-szem elv: PENDING státusz, CashBalance csökkentés NEM történik most
        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(branch)
                .toBranch(null) // bank = null
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(calculateHufValue(currency, dto.getAmount()))
                .movementType(MovementType.BANK_DEPOSIT)
                .status(MovementStatus.PENDING)
                .initiatedBy(worker)
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ BRANCH TRANSFER ============

    /**
     * Irodák közti szállítás (PENDING státusz).
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto transferBetweenBranches(BranchTransferRequestDto dto, Long workerId) {
        Branch fromBranch = findBranch(dto.getFromBranchId());
        Branch toBranch = findBranch(dto.getToBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        if (fromBranch.getId().equals(toBranch.getId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet azonos!");
        }

        // Forrás iroda készlet ellenőrzés
        CashBalance sourceBalance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                fromBranch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg a forrás irodánál ehhez a valutához: " + currency.getCode()));

        if (sourceBalance.getCurrentBalance().compareTo(dto.getAmount()) < 0) {
            throw new ValidationException("Nincs elegendő készlet a forrás irodánál! Egyenleg: "
                    + sourceBalance.getCurrentBalance().setScale(4, RoundingMode.HALF_UP)
                    + ", kért: " + dto.getAmount());
        }

        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currency(currency)
                .amount(dto.getAmount())
                .hufValue(calculateHufValue(currency, dto.getAmount()))
                .movementType(MovementType.BRANCH_TRANSFER)
                .status(MovementStatus.PENDING)
                .initiatedBy(worker)
                .referenceNumber(generateReferenceNumber())
                .notes(dto.getNotes())
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ STATUS TRANSITIONS ============

    /**
     * Mozgás jóváhagyása (PENDING → APPROVED).
     * Pessimistic lock-kal védve a race condition ellen.
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto approveMovement(Long movementId, Long workerId) {
        InventoryMovement movement = findMovementForUpdate(movementId);
        Worker worker = findWorker(workerId);

        // Stornó védelem: véglegesen lezárt mozgás nem módosítható
        validateNotFinalized(movement);

        if (movement.getStatus() != MovementStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő mozgás hagyható jóvá! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }

        movement.setStatus(MovementStatus.APPROVED);
        movement.setApprovedBy(worker);
        movement.setApprovedAt(LocalDateTime.now());

        // Bank befizetés jóváhagyásakor CashBalance csökkentés (négy-szem elv)
        if (movement.getMovementType() == MovementType.BANK_DEPOSIT) {
            if (movement.getFromBranch() == null) {
                throw new ValidationException("Bank befizetés mozgásnál a forrás iroda (fromBranch) nem lehet null!");
            }
            updateCashBalance(movement.getFromBranch().getId(),
                    movement.getCurrency().getId(), movement.getAmount(), false);
        }

        // Bank kivét és irodák közti szállítás jóváhagyáskor automatikusan IN_TRANSIT
        if (movement.getMovementType() == MovementType.BANK_WITHDRAW
                || movement.getMovementType() == MovementType.BRANCH_TRANSFER) {
            movement.setStatus(MovementStatus.IN_TRANSIT);
        }

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    /**
     * Mozgás fogadása (IN_TRANSIT → RECEIVED) — CashBalance frissítéssel!
     * Pessimistic lock-kal védve a race condition ellen.
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto receiveMovement(Long movementId, Long workerId, ReceiveMovementDto dto) {
        InventoryMovement movement = findMovementForUpdate(movementId);
        Worker worker = findWorker(workerId);

        // Stornó védelem: véglegesen lezárt mozgás nem módosítható
        validateNotFinalized(movement);

        if (movement.getStatus() != MovementStatus.IN_TRANSIT
                && movement.getStatus() != MovementStatus.APPROVED) {
            throw new ValidationException("Csak szállítás alatt lévő vagy jóváhagyott mozgás fogadható! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }

        movement.setStatus(MovementStatus.RECEIVED);
        movement.setReceivedBy(worker);
        movement.setReceivedAt(LocalDateTime.now());

        BigDecimal receivedAmount = dto.getReceivedAmount();

        // Audit-finding 2026-05-31 (P1): a forrás az eredeti amount-tal terhelődik, de a cél a
        // kliens által megadott receivedAmount-tal íródik jóvá. Ha ezek eltérnek, a különbség eddig
        // NYOM NÉLKÜL eltűnt (nincs difference-rekord, nincs audit) → "készlet = SUM(tx)" sérülés és
        // manipulációs felület. Mostantól rögzítjük a fogadott összeget + a különbséget, és minden
        // fogadást auditálunk (a Transfer alrendszer received_amount/difference mintája).
        BigDecimal difference = receivedAmount.subtract(movement.getAmount());
        movement.setReceivedAmount(receivedAmount);
        movement.setDifference(difference);

        // CashBalance frissítés a mozgás típusa alapján
        switch (movement.getMovementType()) {
            case BANK_WITHDRAW -> {
                // Bank → pénztár: cél iroda készlet növelése
                if (movement.getToBranch() == null) {
                    throw new ValidationException("Bank kivét mozgásnál a cél iroda (toBranch) nem lehet null!");
                }
                updateCashBalance(movement.getToBranch().getId(),
                        movement.getCurrency().getId(), receivedAmount, true);
            }
            case BRANCH_TRANSFER -> {
                // Irodák közti: forrás csökkentés, cél növelés — NPE védelem
                if (movement.getFromBranch() == null || movement.getToBranch() == null) {
                    throw new ValidationException(
                            "Irodák közti mozgásnál fromBranch és toBranch nem lehet null!");
                }
                updateCashBalance(movement.getFromBranch().getId(),
                        movement.getCurrency().getId(), movement.getAmount(), false);
                updateCashBalance(movement.getToBranch().getId(),
                        movement.getCurrency().getId(), receivedAmount, true);
            }
            default -> {
                // BANK_DEPOSIT, CORRECTION, INITIAL_STOCK — nem ide tartozik
            }
        }

        movement = movementRepository.save(movement);

        writeReceiveAuditLog(movement, worker, receivedAmount, difference);
        return toDto(movement);
    }

    /**
     * Készletmozgás-fogadás audit-bejegyzése (KÖTELEZŐ). A különbséget (difference) explicit
     * rögzíti, így egy receivedAmount ≠ amount eltérés utólag detektálható és reconcile-olható.
     */
    private void writeReceiveAuditLog(InventoryMovement movement, Worker worker,
                                      BigDecimal receivedAmount, BigDecimal difference) {
        Branch receivingBranch = movement.getToBranch() != null
                ? movement.getToBranch() : movement.getFromBranch();
        boolean hasShortage = difference.signum() != 0;
        AuditLog auditLog = AuditLog.builder()
                .action(hasShortage ? "INVENTORY_MOVEMENT_RECEIVED_DIFF" : "INVENTORY_MOVEMENT_RECEIVED")
                .entityType("InventoryMovement")
                .entityId(movement.getId() != null ? movement.getId().toString() : null)
                .userId(worker.getId().toString())
                .userName(worker.getName())
                .branchId(receivingBranch != null ? receivingBranch.getId().toString() : null)
                .branchName(receivingBranch != null ? receivingBranch.getName() : null)
                .changes("Típus: " + movement.getMovementType().name()
                        + ", Valuta: " + movement.getCurrency().getCode()
                        + ", Küldött (amount): " + movement.getAmount().setScale(4, RoundingMode.HALF_UP)
                        + ", Fogadott (received): " + receivedAmount.setScale(4, RoundingMode.HALF_UP)
                        + ", Eltérés (difference): " + difference.setScale(4, RoundingMode.HALF_UP)
                        + ", Ref: " + movement.getReferenceNumber())
                .build();
        auditLogRepository.save(auditLog);
    }

    /**
     * Mozgás visszavonása (PENDING → CANCELLED).
     * Pessimistic lock-kal védve a race condition ellen.
     */
    @Transactional(rollbackFor = Exception.class)
    public void cancelMovement(Long movementId) {
        InventoryMovement movement = findMovementForUpdate(movementId);

        // Stornó védelem: véglegesen lezárt mozgás nem módosítható
        validateNotFinalized(movement);

        if (movement.getStatus() != MovementStatus.PENDING) {
            throw new ValidationException("Csak függőben lévő mozgás vonható vissza! Jelenlegi státusz: "
                    + movement.getStatus().getDisplayName());
        }
        movement.setStatus(MovementStatus.CANCELLED);
        movementRepository.save(movement);
    }

    // ============ CORRECTION ============

    /**
     * Manuális készlet korrekció — CashBalance update + AuditLog bejegyzés.
     */
    @Transactional(rollbackFor = Exception.class)
    public InventoryMovementDto correctInventory(CorrectionRequestDto dto, Long workerId) {
        Branch branch = findBranch(dto.getBranchId());
        Currency currency = findCurrency(dto.getCurrencyId());
        Worker worker = findWorker(workerId);

        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(
                branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));

        BigDecimal oldAmount = balance.getCurrentBalance();
        BigDecimal correctionDiff = dto.getNewAmount().subtract(oldAmount)
                .setScale(4, RoundingMode.HALF_UP);

        // CashBalance frissítés
        balance.setCurrentBalance(dto.getNewAmount().setScale(4, RoundingMode.HALF_UP));
        balance.setLastTransactionAt(LocalDateTime.now());
        cashBalanceRepository.save(balance);

        // AuditLog bejegyzés — KÖTELEZŐ
        AuditLog auditLog = AuditLog.builder()
                .action("INVENTORY_CORRECTION")
                .entityType("CashBalance")
                .entityId(balance.getId().toString())
                .userId(worker.getId().toString())
                .userName(worker.getName())
                .branchId(branch.getId().toString())
                .branchName(branch.getName())
                .changes("Valuta: " + currency.getCode()
                        + ", Régi érték: " + oldAmount.setScale(4, RoundingMode.HALF_UP)
                        + ", Új érték: " + dto.getNewAmount().setScale(4, RoundingMode.HALF_UP)
                        + ", Különbség: " + correctionDiff
                        + ", Ok: " + dto.getReason())
                .build();
        auditLogRepository.save(auditLog);

        // InventoryMovement rekord
        InventoryMovement movement = InventoryMovement.builder()
                .fromBranch(branch)
                .toBranch(branch)
                .currency(currency)
                .amount(correctionDiff.abs())
                .hufValue(calculateHufValue(currency, correctionDiff.abs()))
                .movementType(MovementType.CORRECTION)
                .status(MovementStatus.RECEIVED) // korrekció azonnal RECEIVED
                .initiatedBy(worker)
                .approvedBy(worker)
                .receivedBy(worker)
                .approvedAt(LocalDateTime.now())
                .receivedAt(LocalDateTime.now())
                .referenceNumber(generateReferenceNumber())
                .notes("Korrekció: " + dto.getReason()
                        + " | Régi: " + oldAmount.setScale(4, RoundingMode.HALF_UP)
                        + " → Új: " + dto.getNewAmount().setScale(4, RoundingMode.HALF_UP))
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();

        movement = movementRepository.save(movement);
        return toDto(movement);
    }

    // ============ QUERIES ============

    /**
     * v2.5.1-D B6: a lokál értéktáros (mode='ertektar') worker területi szűrésére használt
     * roles set — ezek a NEM-központi role-ok, akiknek csak a saját területük látszódhat.
     *
     * <p>A foertektar / ugyvezeto / admin "központi" szerepkörök NINCSENEK ebben a halmazban,
     * ők MINDENT látnak (multi-tenant scope-on belül).</p>
     */
    private static final java.util.Set<String> TERRITORY_SCOPED_ROLES = java.util.Set.of(
            "ertektar", "ERTEKTAR", "ertektaros", "VAULT_KEEPER", "vault_keeper",
            "irodavezeto", "IRODAVEZETO"
    );

    /**
     * v2.5.1-D B6: a bejelentkezett worker vault_territory_id-je, ha a role-ja territory-scoped.
     *
     * <p>Visszaad null-t (= nincs területi szűrés) ha:
     *  - a worker role-ja "központi" (foertektar/ugyvezeto/admin) — ők mindent látnak,
     *  - a worker branch-ének nincs vault_territory_id-je,
     *  - nincs bejelentkezett user (pl. test context, scheduler).</p>
     *
     * <p>Defensive: minden exception-t elnyel és null-t ad vissza, hogy ne dobja meg
     * a meglévő endpoint flow-t. Smoke teszt v2.5.0-nál ezt elmulasztotta — most
     * try/catch + log.warn helyettesít.</p>
     */
    /**
     * FK-ÉRTÉKTÁR (2026-06-02): az aktuális role territory-scoped-e (ertektar/irodavezeto stb.).
     * A {@link #getCurrentTerritoryFilterOrNull()} null-t ad vissza KÖZPONTI role-ra ÉS territory-
     * scoped role-ra is, ha nincs vault_territory — ez a metódus a kettő megkülönböztetésére kell
     * (fail-closed döntéshez). Defenzív: exception esetén false (nincs téves szűkítés a teszt/
     * scheduler kontextusban).
     */
    private boolean isCurrentRoleTerritoryScoped() {
        try {
            String activeRole = hu.puzzleir.valuta.security.SecurityUtils.getActiveOperationalRole();
            String currentRole = hu.puzzleir.valuta.security.SecurityUtils.getCurrentRole();
            String role = activeRole != null ? activeRole : currentRole;
            return role != null && TERRITORY_SCOPED_ROLES.contains(role);
        } catch (Exception e) {
            return false;
        }
    }

    private Integer getCurrentTerritoryFilterOrNull() {
        try {
            String activeRole = hu.puzzleir.valuta.security.SecurityUtils.getActiveOperationalRole();
            String currentRole = hu.puzzleir.valuta.security.SecurityUtils.getCurrentRole();
            String role = activeRole != null ? activeRole : currentRole;
            log.info("FK-005 territoryFilter: activeRole={}, currentRole={}, effectiveRole={}",
                    activeRole, currentRole, role);
            if (role == null || !TERRITORY_SCOPED_ROLES.contains(role)) {
                log.info("FK-005 territoryFilter: role NEM territory-scoped → null (központi role)");
                return null; // központi role — nincs területi szűrés
            }
            UUID branchId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentBranchIdOrNull();
            log.info("FK-005 territoryFilter: territory-scoped role={}, user branchId={}", role, branchId);
            if (branchId == null) {
                log.warn("FK-005 territoryFilter: territory-scoped role-nak NINCS user branchId-je → null (defensive)");
                return null;
            }
            Integer filter = branchRepository.findById(branchId)
                    .map(Branch::getVaultTerritoryId)
                    .orElse(null);
            log.info("FK-005 territoryFilter: branch.vaultTerritoryId={}", filter);
            return filter;
        } catch (Exception e) {
            log.warn("FK-005 territoryFilter: exception (defensive null fallback): {}", e.getMessage());
            return null;
        }
    }

    /**
     * Összes iroda teljes készlete (CashBalance lista) - multi-tenant + területi szűréssel.
     *
     * <p>v2.5.1-D B6: territory-scoped role esetén csak a worker vault_territory_id-jával
     * egyező fiókok cash_balance rekordjait adja vissza. Központi role-nál minden látszik.</p>
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getAllStock() {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        Integer territoryFilter = getCurrentTerritoryFilterOrNull();
        // FK-005 diagnostic (Kasza Helga 2026-05-26 ÉLES BUG): az Országos készlet 0 Ft-ot
        // mutatott. A diagnosztikához részletes INFO-log: companyId + territoryFilter +
        // a teljes findByCompanyId rekord-szám + szűrés utáni rekord-szám + per-branch
        // breakdown. A logokat a Hetzner prod-on érhető el a `journalctl -u valuta-backend`.
        log.info("FK-005 getAllStock START: companyId={}, territoryFilter={}", companyId, territoryFilter);

        java.util.function.Predicate<CashBalance> activeBranch =
                cb -> cb.getBranch() != null && Boolean.TRUE.equals(cb.getBranch().getIsActive());

        List<CashBalance> allRaw = cashBalanceRepository.findByCompanyId(companyId);
        log.info("FK-005 getAllStock: findByCompanyId returned {} cash_balance rows", allRaw.size());
        if (allRaw.isEmpty()) {
            log.warn("FK-005 getAllStock: 0 cash_balance rows from findByCompanyId — possible: "
                    + "(a) wrong companyId in JWT, (b) cb.company_id NULL DB-szinten, (c) no data.");
        }

        // Per-branch előszűrés-stat (csak ha üres / kicsi az eredmény — diagnosztikai cél).
        if (allRaw.size() <= 5) {
            allRaw.forEach(cb -> log.info("FK-005 getAllStock raw row: id={}, branchId={}, branchName={}, "
                            + "branchActive={}, currencyCode={}, balance={}",
                    cb.getId(),
                    cb.getBranch() != null ? cb.getBranch().getId() : null,
                    cb.getBranch() != null ? cb.getBranch().getName() : "NULL-BRANCH",
                    cb.getBranch() != null ? cb.getBranch().getIsActive() : null,
                    cb.getCurrency() != null ? cb.getCurrency().getCode() : "NULL-CURRENCY",
                    cb.getCurrentBalance()));
        }

        if (territoryFilter == null) {
            List<CashBalance> result = allRaw.stream().filter(activeBranch).toList();
            log.info("FK-005 getAllStock END (no territory): {} rows after activeBranch filter (was {})",
                    result.size(), allRaw.size());
            // FK-029: a hívó scope-ján belül minden aktív, nem-vault branch × aktív valuta kapjon
            // (szintetikus, NEM perzisztált) 0-sort, ha nincs valódi cash_balance rekordja.
            return appendSyntheticZeroRows(result, companyId, null);
        }
        var territoryBranchIds = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, territoryFilter)
                .stream().map(Branch::getId).collect(java.util.stream.Collectors.toSet());
        log.info("FK-005 getAllStock: territoryBranchIds={} (territoryFilter={})",
                territoryBranchIds.size(), territoryFilter);
        List<CashBalance> result = allRaw.stream()
                .filter(activeBranch)
                .filter(cb -> territoryBranchIds.contains(cb.getBranch().getId()))
                .toList();
        log.info("FK-005 getAllStock END (territory={}): {} rows after activeBranch+territory filter (was {})",
                territoryFilter, result.size(), allRaw.size());
        // FK-029: territory-scope-helyes szintézis (ugyanaz a territoryFilter, mint a valódi soroknál).
        return appendSyntheticZeroRows(result, companyId, territoryFilter);
    }

    /**
     * FK-029 (2026-06-15): az Országos készlet / Pénztári készletek nézet adat-fedettségének
     * helyreállítása. A {@code cash_balance} sorok csak futásidejű inicializálással keletkeznek
     * (munkamenet-nyitás, tranzakció, admin retrofit); a V145 SQL-seedből jött irodák ezt
     * megkerülték, így sok aktív pénztár sosem kapott sort és hiányzott a nézetből.
     *
     * <p>Ez a metódus a {@code realRows} (valódi, már scope-szűrt sorok) mellé <b>szintetikus,
     * NEM perzisztált</b> 0-egyenlegű {@link CashBalance} sorokat tesz minden aktív,
     * {@code is_vault=FALSE} branch × aktív valuta párra, amelyre nincs valódi sor. A szintézis
     * tisztán in-memory — a {@code cash_balance} táblába semmit nem ír (FR-3, NFR-5).</p>
     *
     * <p>Scope-helyesség (FR-5a/FR-5b 1. réteg): a branch-lista a hívó {@code companyId}-jára és
     * ugyanarra a {@code territoryFilter}-re szűr, mint a valódi sorok. A controller-szintű
     * {@code AccessScopeService.isBranchVisible()} (2. réteg) ezután a szintetikus sorokra is lefut.</p>
     *
     * <p>Vault-branch-ekre (FR-1, TBD-3) a szintézis NEM terjed ki — azokat a frontend FK-007
     * üres-kártya fallback-je fedi.</p>
     */
    private List<CashBalance> appendSyntheticZeroRows(List<CashBalance> realRows, UUID companyId,
                                                      Integer territoryFilter) {
        // 1. réteg scope: ugyanaz a territory-szűrés, mint a realRows-nál; csak AKTÍV, NEM-vault branch.
        // FK-032 (2026-06-16): a központi (territoryFilter==null) ágon a VAULT_COUNTERPARTY virtuális
        // partnereket (PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1, V277 seed) KIZÁRJUK a szintetikus 0-sor
        // generálásból — különben az Országos készletben „BESOROLATLAN" szekcióként jelennek meg (FK-029
        // regresszió). Ezek is_vault=FALSE, így a lenti !isVault szűrőn átmennének. A territory-ág eleve
        // kizárja őket (nincs vault_territory_id-juk). A kizáró metódus FK-014 óta bevált (StockSnapshotService).
        List<Branch> scopeBranches = (territoryFilter == null)
                ? branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId)
                : branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, territoryFilter).stream()
                        .filter(b -> Boolean.TRUE.equals(b.getIsActive()))
                        .toList();
        List<Branch> targetBranches = scopeBranches.stream()
                .filter(b -> !Boolean.TRUE.equals(b.getIsVault()))
                .toList();
        // FK-032 defense-in-depth (Codex P2 #1195): a VALÓDI sorokból is kizárjuk a scope-on kívüli
        // branch-eket — a központi ágon a VAULT_COUNTERPARTY-t (a scopeBranches már kizárta őket). Így a
        // virtuális partnerek akkor sem szivárognak be, ha valaha valódi cash_balance-t kapnának (FR-1
        // „sem valós, sem szintetikus"). A territory-ág realRows-a már territory-szűrt → ott változatlan.
        List<CashBalance> scopedReal = realRows;
        if (territoryFilter == null) {
            java.util.Set<UUID> allowedBranchIds = scopeBranches.stream()
                    .map(Branch::getId).collect(java.util.stream.Collectors.toSet());
            scopedReal = realRows.stream()
                    .filter(cb -> cb.getBranch() != null && allowedBranchIds.contains(cb.getBranch().getId()))
                    .toList();
        }
        if (targetBranches.isEmpty()) {
            return scopedReal;
        }
        // FR-7: a valuta-lista a futásidejű aktív katalógusból (nem hardcode-olt), RUB dinamikusan.
        List<hu.puzzleir.valuta.entity.Currency> activeCurrencies = currencyRepository.findAllActiveOrdered();
        // Meglévő (branchId, currencyId) párok a valódi sorokból — ezekre NEM kell szintetikus sor.
        java.util.Set<String> existing = scopedReal.stream()
                .filter(cb -> cb.getBranch() != null && cb.getCurrency() != null)
                .map(cb -> cb.getBranch().getId() + ":" + cb.getCurrency().getId())
                .collect(java.util.stream.Collectors.toSet());

        List<CashBalance> out = new java.util.ArrayList<>(scopedReal);
        int synth = 0;
        for (Branch b : targetBranches) {
            for (hu.puzzleir.valuta.entity.Currency cur : activeCurrencies) {
                if (existing.contains(b.getId() + ":" + cur.getId())) {
                    continue;
                }
                out.add(CashBalance.builder()
                        .company(b.getCompany())
                        .branch(b)
                        .currency(cur)
                        .currentBalance(java.math.BigDecimal.ZERO)
                        .openingBalance(java.math.BigDecimal.ZERO)
                        .build());
                synth++;
            }
        }
        log.info("FK-029 getAllStock: {} szintetikus 0-sor ({} aktiv nem-vault branch x {} aktiv valuta; {} valodi sor scope-szurt)",
                synth, targetBranches.size(), activeCurrencies.size(), scopedReal.size());
        return out;
    }

    /**
     * Egy iroda készlete (CashBalance lista).
     */
    @Transactional(readOnly = true)
    public List<CashBalance> getCurrentStock(UUID branchId) {
        return cashBalanceRepository.findByBranchId(branchId);
    }

    /**
     * Értéktár (VAULT entity_type) készlete soronként valutára bontva.
     *
     * <p>v2.4.9: az "Értéktári készlet" oldal adatforrása. A jelenlegi `quantity` értéket
     * `closing` mezőként adjuk vissza.</p>
     *
     * <p>v2.5.x P2 follow-up (2026-05-03): az opening / received / issued mezok mostantol
     * kiszamoltak a mai `inventory_movement` rekordokbol. Algoritmus:</p>
     * <ol>
     *   <li>Lekeri a vault branch-eket (`is_vault=TRUE`).</li>
     *   <li>Lekeri a mai `RECEIVED` statuszu mozgasokat a celcegen belul.</li>
     *   <li>Valutankent osszesiti:
     *     <ul>
     *       <li>received = sum(amount) ahol toBranch vault-branch (BANK_WITHDRAW vagy BRANCH_TRANSFER vault-be)</li>
     *       <li>issued   = sum(amount) ahol fromBranch vault-branch (BANK_DEPOSIT vagy BRANCH_TRANSFER vault-bol)</li>
     *     </ul>
     *   </li>
     *   <li>opening = closing - received + issued (derived, nem szukseges kulon snapshot-tabla)</li>
     *   <li>difference = 0 (a derived opening pontos, nincs eltere)</li>
     * </ol>
     */
    @Transactional(readOnly = true)
    public List<hu.puzzleir.valuta.dto.inventory.VaultStockRowDto> getVaultStockFlow() {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        java.time.LocalDate today = java.time.LocalDate.now();

        var stocks = currencyStockRepository.findByCompanyIdAndEntityType(companyId, "VAULT");

        // FK-ÉRTÉKTÁR (2026-06-02): territory-scoped role (pl. ERTEKTAR) csak a SAJÁT
        // vault_territory készletét látja. Központi role (foertektar/ugyvezeto/admin) → minden.
        boolean territoryScoped = isCurrentRoleTerritoryScoped();
        Integer territoryFilter = getCurrentTerritoryFilterOrNull();

        // FAIL-CLOSED (Codex/Copilot P1): ha a role territory-scoped, de nincs meghatározható
        // vault_territory (nincs branch / branch.vault_territory_id NULL), NE mutassunk semmit —
        // a felnyitott (null = minden) ág CSAK a központi role-oké. Így egy hibásan konfigurált
        // értéktáros NEM lát országos vault készletet.
        if (territoryScoped && territoryFilter == null) {
            log.warn("getVaultStockFlow: territory-scoped role vault_territory NÉLKÜL → fail-closed (üres lista)");
            return java.util.List.of();
        }

        // A currency_stock VAULT sorok entity_id-je a vault_territory.id (::TEXT) — NEM branch UUID
        // (kódbázis-konvenció, lásd VaultStockFlowService). Territory-scoped role esetén csak a saját
        // territory készlete (cross-territory NEM szivárog ki).
        if (territoryScoped) {
            String territoryEntityId = String.valueOf(territoryFilter);
            stocks = stocks.stream()
                    .filter(cs -> territoryEntityId.equals(cs.getEntityId()))
                    .toList();
        }

        // Vault branch-ek a mai mozgás-aggregációhoz (a movements branch-eket referál) — territory-
        // scoped esetén a saját terület vault-fiókjaira szűkítve.
        java.util.Set<UUID> vaultBranchIds = branchRepository
                .findByCompanyIdAndIsVaultTrueAndIsActiveTrue(companyId)
                .stream()
                .filter(b -> !territoryScoped || territoryFilter.equals(b.getVaultTerritoryId()))
                .map(Branch::getId)
                .collect(java.util.stream.Collectors.toSet());

        // Mai RECEIVED mozgasok a cegen belul, vault-branch-et erinto reszek
        var todayMovements = movementRepository
                .findCompletedByCompanyIdAndDate(companyId, today);

        // Aggregalt received + issued valutankent (currency code -> sum)
        java.util.Map<String, BigDecimal> receivedByCurrency = new java.util.HashMap<>();
        java.util.Map<String, BigDecimal> issuedByCurrency = new java.util.HashMap<>();
        for (var m : todayMovements) {
            if (m.getCurrency() == null || m.getAmount() == null) continue;
            String code = m.getCurrency().getCode();
            UUID fromId = (m.getFromBranch() != null) ? m.getFromBranch().getId() : null;
            UUID toId = (m.getToBranch() != null) ? m.getToBranch().getId() : null;
            boolean toVault = toId != null && vaultBranchIds.contains(toId);
            boolean fromVault = fromId != null && vaultBranchIds.contains(fromId);

            if (toVault) {
                receivedByCurrency.merge(code, m.getAmount(), BigDecimal::add);
            }
            if (fromVault) {
                issuedByCurrency.merge(code, m.getAmount(), BigDecimal::add);
            }
        }

        return stocks.stream()
                .map(cs -> {
                    var currency = currencyRepository.findByCode(cs.getCurrencyCode()).orElse(null);
                    String name = (currency != null) ? currency.getName() : cs.getCurrencyCode();
                    BigDecimal closing = cs.getQuantity();
                    BigDecimal received = receivedByCurrency.getOrDefault(cs.getCurrencyCode(), BigDecimal.ZERO);
                    BigDecimal issued = issuedByCurrency.getOrDefault(cs.getCurrencyCode(), BigDecimal.ZERO);
                    // opening = closing - received + issued (derived, snapshot-tabla nelkul)
                    BigDecimal opening = closing.subtract(received).add(issued);
                    return hu.puzzleir.valuta.dto.inventory.VaultStockRowDto.builder()
                            .currencyCode(cs.getCurrencyCode())
                            .currencyName(name)
                            .opening(opening)
                            .received(received)
                            .issued(issued)
                            .closing(closing)
                            .difference(java.math.BigDecimal.ZERO)
                            .lastUpdated(cs.getLastUpdated())
                            .build();
                })
                .sorted((a, b) -> a.getCurrencyCode().compareTo(b.getCurrencyCode()))
                .toList();
    }

    /**
     * Összes iroda × összes valuta mátrix - multi-tenant + területi szűréssel.
     *
     * <p>v2.5.1-D B6: territory-scoped role esetén csak az adott vault_territory-hoz
     * tartozó fiókok jelennek meg a mátrixban (központi role-nál minden).</p>
     */
    @Transactional(readOnly = true)
    public StockMatrixDto getStockMatrix() {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        Integer territoryFilter = getCurrentTerritoryFilterOrNull();
        List<CashBalance> allBalances = cashBalanceRepository.findByCompanyId(companyId);

        java.util.Set<UUID> allowedBranchIds = null;
        if (territoryFilter != null) {
            allowedBranchIds = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, territoryFilter)
                    .stream().map(Branch::getId).collect(java.util.stream.Collectors.toSet());
        }

        Map<String, Map<String, BigDecimal>> matrix = new LinkedHashMap<>();
        for (CashBalance cb : allBalances) {
            if (cb.getBranch() == null) continue;
            UUID bId = cb.getBranch().getId();
            if (allowedBranchIds != null && !allowedBranchIds.contains(bId)) continue;
            String branchIdStr = bId.toString();
            String currencyCode = cb.getCurrency().getCode();
            matrix.computeIfAbsent(branchIdStr, k -> new LinkedHashMap<>())
                    .put(currencyCode, cb.getCurrentBalance()
                            .setScale(4, RoundingMode.HALF_UP));
        }

        return StockMatrixDto.builder().matrix(matrix).build();
    }

    /**
     * Mozgás részletei.
     */
    @Transactional(readOnly = true)
    public InventoryMovementDto getMovement(Long id) {
        return toDto(findMovement(id));
    }

    /**
     * Mozgás történet (paginated, filtered).
     */
    @Transactional(readOnly = true)
    public Page<InventoryMovementDto> searchMovements(UUID branchId, LocalDate startDate,
            LocalDate endDate, MovementStatus status, MovementType type, Pageable pageable) {
        // Multi-tenant izoláció (CLAUDE.md B.3): a keresés KÖTELEZŐEN a hívó cégére szűr.
        // Audit-finding 2026-05-31 (P1 IDOR): a search query companyId-szűrés nélkül volt,
        // branchId=null esetén MINDEN cég összes mozgása kiszivárgott.
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        // Konkrét iroda-szűrésnél a tulajdonost is ellenőrizzük (tenant-idegen → 404).
        if (branchId != null) {
            Branch branch = branchRepository.findById(branchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
            assertBranchInCompany(branch);
        }
        return movementRepository.search(companyId, branchId, startDate, endDate, status, type, pageable)
                .map(this::toDto);
    }

    // ============ HELPERS ============

    /**
     * HUF értéket számít egy adott valuta összegéhez a legfrissebb közép-árfolyam alapján.
     * HUF esetén az összeget adja vissza változtatás nélkül.
     * Ha nincs elérhető árfolyam, ZERO-t ad vissza és figyelmeztetést naplóz.
     */
    private BigDecimal calculateHufValue(Currency currency, BigDecimal amount) {
        if ("HUF".equals(currency.getCode())) {
            return amount.setScale(0, RoundingMode.HALF_UP);
        }
        UUID companyId = null;
        try {
            companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        } catch (hu.puzzleir.valuta.exception.ValidationException ex) {
            // SecurityContext nem elérhető (pl. scheduled task) — global rate lookup
            log.debug("CompanyId nem elérhető HUF számításhoz — global rate lookup: {}", ex.getMessage());
        }
        Optional<BigDecimal> midRate = exchangeRateRepository
                .findLatestMidRateByCurrencyCode(companyId, currency.getCode());
        if (midRate.isEmpty()) {
            log.warn("Nem található árfolyam a HUF érték számításhoz: currency={}", currency.getCode());
            return BigDecimal.ZERO;
        }
        return amount.multiply(midRate.get()).setScale(0, RoundingMode.HALF_UP);
    }

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseThrow(() -> new ValidationException(
                        "Kassza egyenleg nem található: branchId=" + branchId + ", currencyId=" + currencyId));
        balance.updateBalance(amount.setScale(4, RoundingMode.HALF_UP), isIncoming);
        cashBalanceRepository.save(balance);
    }

    private String generateReferenceNumber() {
        String prefix = "INV-" + LocalDate.now().format(REF_DATE_FORMAT) + "-";
        long max = movementRepository.findMaxReferenceNumber(prefix);
        return prefix + String.format("%04d", max + 1);
    }

    private Branch findBranch(String branchId) {
        Branch branch = branchRepository.findById(UUID.fromString(branchId))
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        assertBranchInCompany(branch);
        return branch;
    }

    /**
     * Multi-tenant izoláció (CLAUDE.md B.3): a single-id-vel betöltött iroda CSAK a hívó
     * cégéhez tartozhat. Tenant-idegen iroda → 404 (id-enumeráció ellen, NEM 403).
     *
     * <p>Audit-finding 2026-05-31 (P1 IDOR): a findBranch a bank/transfer/korrekció úton
     * tulajdonos-ellenőrzés nélkül oldott fel tetszőleges branchId-t bármely cégből.</p>
     */
    private void assertBranchInCompany(Branch branch) {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        if (!branchBelongsToCompany(branch, companyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branch.getId());
        }
    }

    /**
     * Multi-tenant izoláció (CLAUDE.md B.3): a single-id-vel betöltött készletmozgás CSAK akkor
     * látható/módosítható, ha a forrás VAGY a cél irodája a hívó cégéhez tartozik (bank-műveletnél
     * az egyik oldal null). Tenant-idegen mozgás → 404 (id-enumeráció ellen).
     *
     * <p>Audit-finding 2026-05-31 (P0 IDOR): approve/receive/cancel/getMovement tenant-check
     * nélkül engedte idegen cég mozgásának státuszváltását (cash_balance-írás) és kiolvasását.</p>
     */
    private void assertMovementInCompany(InventoryMovement movement) {
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();
        // MINDEN nem-null oldalnak a hívó cégéhez kell tartoznia (bank-mozgásnál az egyik oldal null),
        // ÉS legalább az egyik oldal a cégé. Csak az egyik oldal egyezése NEM elég (Codex P1 #934):
        // egy (legacy / vulnerable-window) cross-tenant BRANCH_TRANSFER receiveMovement-je MINDKÉT
        // branch cash_balance-át írná — az idegen tenantét is. Tenant-idegen → 404 (id-enumeráció ellen).
        Branch from = movement.getFromBranch();
        Branch to = movement.getToBranch();
        boolean fromOk = from == null || branchBelongsToCompany(from, companyId);
        boolean toOk = to == null || branchBelongsToCompany(to, companyId);
        boolean anyOwnBranch = branchBelongsToCompany(from, companyId) || branchBelongsToCompany(to, companyId);
        if (!fromOk || !toOk || !anyOwnBranch) {
            throw new ResourceNotFoundException("Készlet mozgás nem található: " + movement.getId());
        }
    }

    private boolean branchBelongsToCompany(Branch branch, UUID companyId) {
        return branch != null && branch.getCompany() != null
                && branch.getCompany().getId().equals(companyId);
    }

    private Currency findCurrency(Long currencyId) {
        return currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyId));
    }

    private Worker findWorker(Long workerId) {
        return workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));
    }

    private InventoryMovement findMovement(Long id) {
        InventoryMovement movement = movementRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Készlet mozgás nem található: " + id));
        assertMovementInCompany(movement);
        return movement;
    }

    /**
     * Pessimistic lock-kal lekérdezi a mozgást — race condition elleni védelem.
     * Státusz váltó műveletekhez (approve, receive, cancel) KÖTELEZŐ ez a metódus!
     */
    private InventoryMovement findMovementForUpdate(Long id) {
        InventoryMovement movement = movementRepository.findByIdForUpdate(id)
                .orElseThrow(() -> new ResourceNotFoundException("Készlet mozgás nem található: " + id));
        assertMovementInCompany(movement);
        return movement;
    }

    /**
     * Stornó védelem: RECEIVED, CANCELLED és REJECTED státuszú mozgások
     * véglegesen lezártak — NEM módosíthatók.
     */
    private void validateNotFinalized(InventoryMovement movement) {
        if (movement.getStatus() == MovementStatus.RECEIVED
                || movement.getStatus() == MovementStatus.CANCELLED
                || movement.getStatus() == MovementStatus.REJECTED) {
            throw new ValidationException(
                    "A mozgás véglegesen lezárt, nem módosítható! Státusz: "
                            + movement.getStatus().getDisplayName());
        }
    }

    private InventoryMovementDto toDto(InventoryMovement m) {
        return InventoryMovementDto.builder()
                .id(m.getId())
                .fromBranchId(m.getFromBranch() != null ? m.getFromBranch().getId().toString() : null)
                .fromBranchName(m.getFromBranch() != null ? m.getFromBranch().getName() : "Bank")
                .toBranchId(m.getToBranch() != null ? m.getToBranch().getId().toString() : null)
                .toBranchName(m.getToBranch() != null ? m.getToBranch().getName() : "Bank")
                .currencyId(m.getCurrency().getId())
                .currencyCode(m.getCurrency().getCode())
                .currencyName(m.getCurrency().getName())
                .amount(m.getAmount())
                .hufValue(m.getHufValue())
                .movementType(m.getMovementType().name())
                .movementTypeDisplay(m.getMovementType().getDisplayName())
                .status(m.getStatus().name())
                .statusDisplay(m.getStatus().getDisplayName())
                .initiatedById(m.getInitiatedBy().getId())
                .initiatedByName(m.getInitiatedBy().getName())
                .approvedById(m.getApprovedBy() != null ? m.getApprovedBy().getId() : null)
                .approvedByName(m.getApprovedBy() != null ? m.getApprovedBy().getName() : null)
                .receivedById(m.getReceivedBy() != null ? m.getReceivedBy().getId() : null)
                .receivedByName(m.getReceivedBy() != null ? m.getReceivedBy().getName() : null)
                .referenceNumber(m.getReferenceNumber())
                .notes(m.getNotes())
                .movementDate(m.getMovementDate().toString())
                .movementTime(m.getMovementTime().toString())
                .approvedAt(m.getApprovedAt() != null ? m.getApprovedAt().toString() : null)
                .receivedAt(m.getReceivedAt() != null ? m.getReceivedAt().toString() : null)
                .createdAt(m.getCreatedAt() != null ? m.getCreatedAt().toString() : null)
                .receivedAmount(m.getReceivedAmount())
                .difference(m.getDifference())
                .build();
    }
}
