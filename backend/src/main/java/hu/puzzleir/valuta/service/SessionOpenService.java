package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.session.SessionDataDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Pénztárnyitás szolgáltatás.
 *
 * Kezeli a napi munkamenet megnyitását:
 * - Ellenőrzi a lezáratlan korábbi session-öket
 * - Átveszi az előző záró készletet nyitó készletként
 * - Validálja a nyitás feltételeit
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class SessionOpenService {

    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    // Issue #110: lazy kassza egyenleg init ha a branch-en még nincs egy rekord sem.
    private final CashBalanceService cashBalanceService;

    /**
     * Pénztár megnyitása.
     *
     * @param workerId pénztáros ID
     * @param branchId iroda ID
     * @return session adat nyitó készlettel
     */
    public SessionDataDto openSession(Long workerId, UUID branchId) {
        Company company = companyRepository.findById(SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található!"));
        UUID companyId = company.getId();

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        // FK-038 (2026-06-21): értéktári (is_vault=TRUE) fiók NEM nyithat napi pénztári munkamenetet
        // (lásd DailySessionService.openDay) — még a cash_balance lazy-init (lentebb) ELŐTT, hogy egy
        // értéktár ne is kapjon pénztár-kassza sort, és ne keletkezzen vault daily_session (a Dashboard
        // „Zárási állapot" widget A-forrása).
        if (Boolean.TRUE.equals(branch.getIsVault())) {
            throw new ValidationException("Értéktári fiók nem nyithat napi pénztári munkamenetet");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        // Issue #110: lazy kassza egyenleg init — ha ez a branch még nem kapott
        // egy cash_balance rekordot sem, inicializálunk. Idempotens + safe.
        // Ez kezeli a régi (pre-Issue #110) branch-ek production-ba deployment-jét.
        // Sourcery PR #112: existsByBranchId (COUNT query) — nem kell az összes balance-t lekérni.
        if (!cashBalanceRepository.existsByBranchIdAndCompanyId(branchId, companyId)) {
            log.warn("Branch {} nem rendelkezik cash_balance rekorddal — auto-init (Issue #110 fallback)",
                    branchId);
            try {
                int created = cashBalanceService.initializeBranchBalances(branchId);
                log.info("Branch {} cash_balance lazy-init: {} új rekord", branchId, created);
            } catch (RuntimeException e) {
                log.error("Branch {} cash_balance lazy-init FAILED — munkamenet nyitás tiltva",
                        branchId, e);
                throw new ValidationException(
                        "Kasszaegyenlegek inicializálása sikertelen. Nyitás nem folytatható: "
                                + e.getMessage());
            }
        }

        LocalDate today = LocalDate.now();

        // FKH-051: the destructive stale-session force-close loop was REMOVED.
        // A past OPEN day now survives day-open; the caller sees the
        // validateSessionOpen warning and closes the day via the FKH-050
        // retroactive flow (/closing/retroactive).

        // Ellenőrzés: nincs-e lezáratlan MAI session
        if (dailySessionRepository.hasOpenSession(companyId, branchId)) {
            throw new ValidationException("Van lezáratlan korábbi munkamenet! Először zárja le!");
        }

        // REOPEN: ha mai session CLOSED → újranyitás engedélyezett
        Optional<DailySession> existingOpt = dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today);
        if (existingOpt.isPresent()) {
            DailySession existingSession = existingOpt.get();

            if (existingSession.getStatus() == DailySessionStatus.OPEN) {
                throw new ValidationException("Már van nyitott napi munkamenet ezen az irodán!");
            }

            if (existingSession.getStatus() == DailySessionStatus.CLOSED) {
                existingSession.setStatus(DailySessionStatus.OPEN);
                existingSession.setOpenedByWorker(worker);
                existingSession.setOpenedAt(LocalDateTime.now());
                existingSession.setClosedByWorker(null);
                existingSession.setClosedAt(null);
                existingSession.setClosingBalanceHuf(null);
                existingSession.setDenominationVerified(false);

                DailySession saved = dailySessionRepository.save(existingSession);

                // Null-safe kassza egyenleg nyitás — #4 fix
                updateCashBalancesForOpening(companyId, branchId);

                log.info("Pénztár újranyitás (REOPEN): iroda={}, pénztáros={}, dátum={}",
                        branch.getName(), worker.getName(), today);

                return SessionDataDto.builder()
                        .sessionId(saved.getId())
                        .branchId(branchId.toString())
                        .branchName(branch.getName())
                        .workerId(workerId)
                        .workerName(worker.getName())
                        .sessionDate(today)
                        .status(saved.getStatus().name())
                        .openedAt(saved.getOpenedAt())
                        .openingBalances(calculateOpeningBalances(branchId, companyId))
                        .warnings(validateSessionOpen(branchId))
                        .build();
            }

            throw new ValidationException("Mai napra már létezik munkamenet ezen az irodán! Státusz: "
                    + existingSession.getStatus().getDisplayName());
        }

        // Nyitó készlet: előző záró készlet átvétele
        Map<String, BigDecimal> openingBalances = calculateOpeningBalances(branchId, companyId);

        // HUF nyitó egyenleg
        BigDecimal openingHuf = openingBalances.getOrDefault("HUF", BigDecimal.ZERO);

        // Session létrehozása
        DailySession session = DailySession.builder()
                .company(company)
                .branch(branch)
                .sessionDate(today)
                .status(DailySessionStatus.OPEN)
                .openedByWorker(worker)
                .openedAt(LocalDateTime.now())
                .openingBalanceHuf(openingHuf)
                .build();

        DailySession saved = dailySessionRepository.save(session);

        // Kassza egyenlegek napi nyitás beállítása — null-safe
        updateCashBalancesForOpening(companyId, branchId);

        log.info("Pénztárnyitás: iroda={}, pénztáros={}, dátum={}, nyitó HUF={}",
                branch.getName(), worker.getName(), today, openingHuf);

        // Figyelmeztetések összegyűjtése
        List<String> warnings = validateSessionOpen(branchId);

        return SessionDataDto.builder()
                .sessionId(saved.getId())
                .branchId(branchId.toString())
                .branchName(branch.getName())
                .workerId(workerId)
                .workerName(worker.getName())
                .sessionDate(today)
                .status(saved.getStatus().name())
                .openedAt(saved.getOpenedAt())
                .openingBalances(openingBalances)
                .warnings(warnings)
                .build();
    }

    /**
     * Nyitó készlet lekérése (valutánként).
     */
    @Transactional(readOnly = true)
    public Map<String, BigDecimal> getOpeningBalance(Long sessionId) {
        DailySession session = dailySessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Munkamenet nem található: " + sessionId));

        // IDOR-guard: a sessionId szekvenciális/enumerálható, a DailySession branch→company
        // szerint multi-tenant. Cross-tenant session → ugyanaz a ResourceNotFoundException,
        // mint a nem létezőnél (nincs id-enumeráció oldalcsatorna). A LAZY company/branch
        // a readOnly tranzakción belül dereferálható (OSIV=off).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!session.getBranch().getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Munkamenet nem található: " + sessionId);
        }

        return calculateOpeningBalances(session.getBranch().getId(), companyId);
    }

    /**
     * Nyitás validáció — figyelmeztetések visszaadása.
     * Megjegyzés: REOPEN esetén a mai OPEN session nem hamis warning (#1 fix).
     */
    @Transactional(readOnly = true)
    public List<String> validateSessionOpen(UUID branchId) {
        List<String> warnings = new ArrayList<>();
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();

        // Előző nap lezárva? (csak korábbi napra vonatkozó session-ök)
        dailySessionRepository.findLatest(companyId, branchId).ifPresent(lastSession -> {
            // Csak korábbi dátumú session-ök relevánsak — a mai OPEN session REOPEN utáni normális állapot
            if (lastSession.getSessionDate() != null && lastSession.getSessionDate().isBefore(today)) {
                if (lastSession.getStatus() == DailySessionStatus.OPEN) {
                    warnings.add("⚠️ Az előző nap nincs lezárva! (Dátum: " + lastSession.getSessionDate() + ")");
                }
                if (lastSession.getStatus() == DailySessionStatus.PENDING_CLOSE) {
                    warnings.add("⚠️ Az előző nap zárás alatt áll! (Dátum: " + lastSession.getSessionDate() + ")");
                }
            }
        });

        // Mai session warning: csak PENDING_CLOSE/egyéb nem-normális állapotban releváns
        // OPEN vagy CLOSED mai session a normális működés része (nyitás/REOPEN), nem warning
        dailySessionRepository.findByBranchIdAndSessionDate(companyId, branchId, today).ifPresent(existing -> {
            if (existing.getStatus() != DailySessionStatus.OPEN && existing.getStatus() != DailySessionStatus.CLOSED) {
                warnings.add("⚠️ Mai napra már létezik munkamenet! Státusz: " + existing.getStatus().getDisplayName());
            }
        });

        // Készlet ellenőrzés - alacsony egyenleg
        List<CashBalance> lowBalances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId).stream()
                .filter(CashBalance::isLowBalance)
                .toList();
        if (!lowBalances.isEmpty()) {
            for (CashBalance cb : lowBalances) {
                warnings.add("⚠️ Alacsony készlet: " + cb.getCurrency().getCode() + " = " + cb.getCurrentBalance());
            }
        }

        return warnings;
    }

    // ============ PRIVATE METHODS ============

    /**
     * Kassza egyenlegek null-safe frissítése nyitáskor.
     * DailySessionService-ből átemelt logika a DRY és null-safety érdekében (#3, #4 fix).
     */
    private void updateCashBalancesForOpening(UUID companyId, UUID branchId) {
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

    private Map<String, BigDecimal> calculateOpeningBalances(UUID branchId, UUID companyId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId);
        Map<String, BigDecimal> result = new LinkedHashMap<>();

        for (CashBalance cb : balances) {
            result.put(cb.getCurrency().getCode(), cb.getCurrentBalance());
        }

        return result;
    }
}
