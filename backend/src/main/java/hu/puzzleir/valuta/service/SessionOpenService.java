package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
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
@Transactional
@Slf4j
public class SessionOpenService {

    private final DailySessionRepository dailySessionRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

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

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));

        LocalDate today = LocalDate.now();

        // Ellenőrzés: nincs-e lezáratlan korábbi session
        if (dailySessionRepository.hasOpenSession(branchId)) {
            throw new ValidationException("Van lezáratlan korábbi munkamenet! Először zárja le!");
        }

        // Ellenőrzés: mai napra már létezik-e session
        dailySessionRepository.findByBranchIdAndSessionDate(branchId, today).ifPresent(existing -> {
            throw new ValidationException("Mai napra már létezik munkamenet ezen az irodán!");
        });

        // Nyitó készlet: előző záró készlet átvétele
        Map<String, BigDecimal> openingBalances = calculateOpeningBalances(branchId);

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

        // Kassza egyenlegek napi nyitás beállítása
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        for (CashBalance balance : balances) {
            balance.setDailyOpening();
            cashBalanceRepository.save(balance);
        }

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

        return calculateOpeningBalances(session.getBranch().getId());
    }

    /**
     * Nyitás validáció — figyelmeztetések visszaadása.
     */
    @Transactional(readOnly = true)
    public List<String> validateSessionOpen(UUID branchId) {
        List<String> warnings = new ArrayList<>();

        // Előző nap lezárva?
        dailySessionRepository.findLatest(branchId).ifPresent(lastSession -> {
            if (lastSession.getStatus() == DailySessionStatus.OPEN) {
                warnings.add("⚠️ Az előző nap nincs lezárva! (Dátum: " + lastSession.getSessionDate() + ")");
            }
            if (lastSession.getStatus() == DailySessionStatus.PENDING_CLOSE) {
                warnings.add("⚠️ Az előző nap zárás alatt áll! (Dátum: " + lastSession.getSessionDate() + ")");
            }
        });

        // Mai napra már van session?
        LocalDate today = LocalDate.now();
        dailySessionRepository.findByBranchIdAndSessionDate(branchId, today).ifPresent(existing -> {
            warnings.add("⚠️ Mai napra már létezik munkamenet! Státusz: " + existing.getStatus().getDisplayName());
        });

        // Készlet ellenőrzés - alacsony egyenleg
        List<CashBalance> lowBalances = cashBalanceRepository.findByBranchId(branchId).stream()
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

    private Map<String, BigDecimal> calculateOpeningBalances(UUID branchId) {
        List<CashBalance> balances = cashBalanceRepository.findByBranchId(branchId);
        Map<String, BigDecimal> result = new LinkedHashMap<>();

        for (CashBalance cb : balances) {
            result.put(cb.getCurrency().getCode(), cb.getCurrentBalance());
        }

        return result;
    }
}
