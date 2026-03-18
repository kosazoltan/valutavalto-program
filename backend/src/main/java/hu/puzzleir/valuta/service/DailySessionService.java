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
import java.util.UUID;

/**
 * Napi munkamenet szolgáltatás.
 *
 * Legacy: HARDWARE tábla MEGNYITOTTNAP, NAPZAR funkció
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DailySessionService {

    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final DenominationCountRepository denominationCountRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

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

        // Ellenőrzés: nincs-e már nyitott nap
        if (dailySessionRepository.hasOpenSession(branchId)) {
            throw new ValidationException("Már van nyitott napi munkamenet!");
        }

        // HIGH FIX #14: Ha ugyanaz a pénztáros megpróbálja KÉTSZER nyitni a napot → hiba
        dailySessionRepository.findByBranchIdAndSessionDate(branchId, today).ifPresent(existingSession -> {
            if (existingSession.getOpenedByWorker() != null
                    && existingSession.getOpenedByWorker().getId().equals(workerId)) {
                throw new ValidationException("Ez a pénztáros már nyitotta a mai napot!");
            }
            throw new ValidationException("Mai napra már létezik munkamenet ezen az irodán!");
        });

        // Ellenőrzés: előző nap le van-e zárva
        dailySessionRepository.findLatest(branchId).ifPresent(lastSession -> {
            if (lastSession.getStatus() == DailySessionStatus.OPEN) {
                throw new ValidationException("Az előző nap nincs lezárva!");
            }
        });

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Nyitó egyenleg számítása (HUF)
        BigDecimal openingBalance = calculateOpeningBalance(branchId);

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
        updateCashBalancesForOpening(branchId);

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
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        LocalDate today = LocalDate.now();

        // Aktuális session lekérése
        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, today)
                .orElseThrow(() -> new ValidationException("Nincs nyitott napi munkamenet!"));

        if (session.getStatus() != DailySessionStatus.OPEN) {
            throw new ValidationException("A nap már le van zárva!");
        }

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));

        // Záró egyenleg számítása
        BigDecimal closingBalance = calculateClosingBalance(branchId);

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
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDate(branchId, today)
                .filter(s -> s.getStatus() == DailySessionStatus.OPEN)
                .orElseThrow(() -> new ValidationException("Nincs nyitott napi munkamenet!"));
    }

    /**
     * Van-e nyitott session?
     */
    @Transactional(readOnly = true)
    public boolean hasOpenSession() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return dailySessionRepository.hasOpenSession(branchId);
    }

    /**
     * Session statisztikák frissítése tranzakció után
     */
    public void updateSessionStats(TransactionType type, BigDecimal hufAmount, BigDecimal handlingFee) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, today)
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
        UUID branchId = SecurityUtils.getCurrentBranchId();
        LocalDate today = LocalDate.now();

        return dailySessionRepository.findByBranchIdAndSessionDate(branchId, today)
                .map(DailySession::getReversalCount)
                .orElse(0);
    }

    /**
     * Nap zarasa (napzaras utan hivodik).
     * Legacy: HARDWARE.LEZARTNAP = aktualis datum
     */
    public void closeSession(LocalDate closingDate) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        DailySession session = dailySessionRepository.findByBranchIdAndSessionDate(branchId, closingDate)
                .orElseThrow(() -> new ValidationException("Nincs munkamenet erre a napra: " + closingDate));

        session.setStatus(DailySessionStatus.CLOSED);
        session.setClosedAt(LocalDateTime.now());
        session.setClosingBalanceHuf(calculateClosingBalance(branchId));

        dailySessionRepository.save(session);
        log.info("Napi munkamenet lezarva: datum={}, iroda={}", closingDate, branchId);
    }

    /**
     * Nyitó egyenleg számítása
     */
    private BigDecimal calculateOpeningBalance(UUID branchId) {
        // Legacy-parity: ha van lezart elozo napi session, annak zaro egyenlege lesz a nyito.
        var latestSessionOpt = dailySessionRepository.findLatest(branchId);
        if (latestSessionOpt.isPresent()) {
            DailySession latestSession = latestSessionOpt.get();
            if (latestSession.getStatus() == DailySessionStatus.CLOSED
                    && latestSession.getClosingBalanceHuf() != null) {
                return latestSession.getClosingBalanceHuf();
            }
        }

        // Fallback: aktualis kasszaegyenlegbol szamolunk.
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
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
    private BigDecimal calculateClosingBalance(UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        return balances.stream()
                .filter(this::isHufBalance)
                .map(cb -> cb.getCurrentBalance() != null ? cb.getCurrentBalance() : BigDecimal.ZERO)
                .findFirst()
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Kassza egyenlegek frissítése nyitáskor
     */
    private void updateCashBalancesForOpening(UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        for (CashBalance balance : balances) {
            if (balance.getCurrentBalance() == null) {
                String currencyCode = balance.getCurrency() != null ? balance.getCurrency().getCode() : "UNKNOWN";
                log.warn("CashBalance currentBalance null nyitáskor, null-safe korrekció: branchId={}, currency={}",
                        branchId, currencyCode);
                balance.setCurrentBalance(BigDecimal.ZERO);
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
        return dailySessionRepository.findByDateRange(companyId, startDate, endDate);
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
