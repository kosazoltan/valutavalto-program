package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.entity.CommissionRule;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CommissionCalculationRepository;
import hu.puzzleir.valuta.repository.CommissionRuleRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;

/**
 * Jutalék számítás szolgáltatás.
 *
 * Legacy: forrasok/SZERVER/ujdll/jutszamito
 * - JutSzamitas(): penztaros havi forgalma -> tier besorolas -> jutalek %
 * - Bonusz: ha eleri a kuszobot, extra % jar
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CommissionCalculationService {

    private final CommissionCalculationRepository commissionCalcRepo;
    private final CommissionRuleRepository commissionRuleRepo;
    private final TransactionRepository transactionRepository;
    private final WorkerRepository workerRepository;

    /**
     * Egyetlen pénztáros havi jutalékának számítása.
     */
    @Transactional(rollbackFor = Exception.class)
    public CommissionCalculation calculateMonthly(Long workerId, String yearMonth, UUID companyId) {
        YearMonth ym = parseYearMonth(yearMonth);

        // Már létezik?
        if (commissionCalcRepo.existsByWorkerIdAndPeriod(workerId, yearMonth)) {
            throw new ValidationException("Már létezik jutalék számítás erre az időszakra: " + yearMonth);
        }

        // #PP-18: a jutalékot a dolgozó SAJÁT fiókjához kell allokálni, NEM a
        // számítást futtató munkamenet (SecurityUtils) fiókjához. Különben (a)
        // @Scheduled háttérfolyamatban nincs Security Context → branchId=null →
        // NOT NULL constraint sértés, (b) ha területi/központi user futtatja, a
        // riport rossz fiókhoz allokál → a dolgozó fiókvezetője nem látja.
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));
        // Copilot #830: multi-tenant guard — a workerId a controllerből szabadon jön,
        // ezért ellenőrizni kell, hogy a dolgozó a hívó cégéhez tartozik (cross-tenant
        // jutalék-számítás megakadályozása).
        if (worker.getCompany() == null || !companyId.equals(worker.getCompany().getId())) {
            throw new ResourceNotFoundException("Pénztáros nem található: " + workerId);
        }
        UUID workerActualBranchId = worker.getBranch().getId();

        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        // H-7: Pénztáros tranzakcióinak összegyűjtése egyetlen range query-vel (N+1 fix)
        List<Transaction> allTransactions = transactionRepository.findByCompanyIdAndWorkerIdAndTransactionDateBetween(
                companyId, workerId, monthStart, monthEnd);

        List<Transaction> active = allTransactions.stream()
                .filter(Transaction::isActive)
                .toList();

        // Forgalom számítás
        BigDecimal totalBuy = active.stream()
                .filter(t -> t.getTransactionType().isBuyType())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSell = active.stream()
                .filter(t -> t.getTransactionType().isSellType())
                .map(Transaction::getHufAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalVolume = totalBuy.add(totalSell);
        int totalTx = active.size();

        // Tier besorolás
        List<CommissionRule> rules = commissionRuleRepo.findActiveRules(companyId, monthEnd);
        BigDecimal rate = new BigDecimal("0.001"); // default 0.1%
        BigDecimal bonusAmount = BigDecimal.ZERO;

        for (CommissionRule rule : rules) {
            boolean aboveMin = totalVolume.compareTo(rule.getMinVolumeHuf()) >= 0;
            boolean belowMax = rule.getMaxVolumeHuf() == null
                    || totalVolume.compareTo(rule.getMaxVolumeHuf()) <= 0;

            if (aboveMin && belowMax) {
                rate = rule.getRatePercent().divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);

                // Bónusz ellenőrzés
                if (rule.getBonusThreshold() != null
                        && totalVolume.compareTo(rule.getBonusThreshold()) >= 0
                        && rule.getBonusPercent() != null
                        && rule.getBonusPercent().compareTo(BigDecimal.ZERO) > 0) {
                    bonusAmount = totalVolume.multiply(
                            rule.getBonusPercent().divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP)
                    ).setScale(2, RoundingMode.HALF_UP);
                }
                break;
            }
        }

        BigDecimal commissionAmount = totalVolume.multiply(rate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal netCommission = commissionAmount.add(bonusAmount);

        CommissionCalculation calc = CommissionCalculation.builder()
                .workerId(workerId)
                .branchId(workerActualBranchId)
                .period(yearMonth)
                .calculationType(CommissionCalculation.CalculationType.MONTHLY)
                .totalTransactions(totalTx)
                .totalVolumeHuf(totalVolume)
                .commissionRate(rate)
                .commissionAmount(commissionAmount)
                .bonusAmount(bonusAmount)
                .deductions(BigDecimal.ZERO)
                .netCommission(netCommission)
                .status(CommissionCalculation.CommissionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();

        CommissionCalculation saved = commissionCalcRepo.save(calc);
        log.info("Jutalék számítva: worker={}, period={}, volume={}, rate={}, amount={}, bonus={}",
                workerId, yearMonth, totalVolume, rate, commissionAmount, bonusAmount);

        return saved;
    }

    /**
     * Iroda összes pénztárosának jutalék számítása.
     */
    @Transactional(rollbackFor = Exception.class)
    public List<CommissionCalculation> calculateAllWorkers(UUID branchId, String yearMonth, UUID companyId) {
        YearMonth ym = parseYearMonth(yearMonth);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        // Összes aktív pénztáros azonosítása a havi tranzakciókból
        List<Transaction> monthTx = transactionRepository.findByBranchAndMonth(branchId, monthStart, monthEnd);
        Set<Long> workerIds = new HashSet<>();
        monthTx.forEach(t -> workerIds.add(t.getWorker().getId()));

        List<CommissionCalculation> results = new ArrayList<>();
        for (Long workerId : workerIds) {
            if (!commissionCalcRepo.existsByWorkerIdAndPeriod(workerId, yearMonth)) {
                try {
                    results.add(calculateMonthly(workerId, yearMonth, companyId));
                } catch (Exception e) {
                    log.warn("Jutalék számítás sikertelen: worker={}, period={}, hiba={}",
                            workerId, yearMonth, e.getMessage());
                }
            }
        }

        log.info("Összes jutalék számítva: branch={}, period={}, workers={}", branchId, yearMonth, results.size());
        return results;
    }

    /**
     * Jutalék jóváhagyása.
     */
    @Transactional(rollbackFor = Exception.class)
    public CommissionCalculation approveCommission(UUID calcId) {
        CommissionCalculation calc = commissionCalcRepo.findById(calcId)
                .orElseThrow(() -> new ValidationException("Jutalék számítás nem található: " + calcId));

        if (calc.getStatus() != CommissionCalculation.CommissionStatus.CALCULATED) {
            throw new ValidationException("Csak CALCULATED státuszú jutalék hagyható jóvá!");
        }

        calc.setStatus(CommissionCalculation.CommissionStatus.APPROVED);
        calc.setApprovedBy(SecurityUtils.getCurrentWorkerId());
        calc.setApprovedAt(LocalDateTime.now());

        return commissionCalcRepo.save(calc);
    }

    /**
     * Jutalék riport lekérdezés (iroda + időszak).
     */
    @Transactional(readOnly = true)
    public List<CommissionCalculation> getCommissionReport(UUID branchId, String yearMonth) {
        return commissionCalcRepo.findByBranchIdAndPeriod(branchId, yearMonth);
    }

    private YearMonth parseYearMonth(String yearMonth) {
        try {
            return YearMonth.parse(yearMonth);
        } catch (Exception e) {
            throw new ValidationException("Érvénytelen év-hónap formátum: " + yearMonth + " (elvárt: YYYY-MM)");
        }
    }
}
