package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
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
     * Nyitó egyenleg számítása
     */
    private BigDecimal calculateOpeningBalance(UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        // Csak HUF egyenleg (currency_id = 1 feltételezve, vagy code = 'HUF')
        return balances.stream()
                .filter(cb -> "HUF".equals(cb.getCurrency().getCode()))
                .map(CashBalance::getCurrentBalance)
                .findFirst()
                .orElse(BigDecimal.ZERO);
    }

    /**
     * Záró egyenleg számítása
     */
    private BigDecimal calculateClosingBalance(UUID branchId) {
        return calculateOpeningBalance(branchId); // Ugyanaz a logika
    }

    /**
     * Kassza egyenlegek frissítése nyitáskor
     */
    private void updateCashBalancesForOpening(UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        for (CashBalance balance : balances) {
            balance.setDailyOpening();
            cashBalanceRepository.save(balance);
        }
    }

    /**
     * Session történet lekérése
     */
    @Transactional(readOnly = true)
    public List<DailySession> getSessionHistory(LocalDate startDate, LocalDate endDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return dailySessionRepository.findByDateRange(companyId, startDate, endDate);
    }
}
