package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.WorkerCommission;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerCommissionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WorkerCommissionService {

    private final WorkerCommissionRepository repository;
    private final TransactionRepository transactionRepository;
    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;

    public List<WorkerCommission> findAll(Long workerId, LocalDate periodStart, LocalDate periodEnd) {
        // Multi-tenant IDOR (NEW-3): a query company-scoped (branch→company join),
        // így a workerId-enumeráció más cég jutalékát nem adja vissza.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repository.findWithFilters(companyId, workerId, periodStart, periodEnd);
    }

    public WorkerCommission findById(UUID id) {
        WorkerCommission wc = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("WorkerCommission not found: " + id));
        // Multi-tenant IDOR (NEW-3): a jutalék branch-e a hívó cégéé-e?
        // Cross-tenant → ResourceNotFoundException (nem leak az erőforrás létezése).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branchRepository.existsByIdAndCompanyId(wc.getBranchId(), companyId)) {
            throw new ResourceNotFoundException("WorkerCommission not found: " + id);
        }
        return wc;
    }

    @Transactional(rollbackFor = Exception.class)
    public List<WorkerCommission> calculate(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        // 2026-04-29 v2.3.30 (Sourcery PR #293 P2): companyId egyszer extract,
        // NEM SecurityUtils.getCurrentCompanyId() inline minden ciklus-iterációban.
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Find all workers in branch (simplified — get distinct worker IDs from transactions)
        List<WorkerCommission> commissions = new ArrayList<>();

        Set<Long> workerIds = new HashSet<>();
        LocalDate current = periodStart;
        while (!current.isAfter(periodEnd)) {
            List<Transaction> dayTx = transactionRepository.findActiveByBranchAndDate(branchId, current);
            dayTx.forEach(t -> workerIds.add(t.getWorker().getId()));
            current = current.plusDays(1);
        }

        for (Long workerId : workerIds) {
            List<Transaction> workerTransactions = new ArrayList<>();
            current = periodStart;
            while (!current.isAfter(periodEnd)) {
                workerTransactions.addAll(transactionRepository.findByWorkerAndDate(companyId, workerId, current));
                current = current.plusDays(1);
            }

            List<Transaction> active = workerTransactions.stream()
                    .filter(Transaction::isActive)
                    .toList();

            BigDecimal totalSales = active.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.SELL)
                    .map(Transaction::getHufAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalBuys = active.stream()
                    .filter(t -> t.getTransactionType() == TransactionType.BUY)
                    .map(Transaction::getHufAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal totalFees = active.stream()
                    .map(t -> t.getHandlingFee() != null ? t.getHandlingFee() : BigDecimal.ZERO)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            // Default commission rate: 0.1% of total turnover
            BigDecimal commissionRate = new BigDecimal("0.001");
            BigDecimal totalTurnover = totalSales.add(totalBuys);
            BigDecimal commissionAmount = totalTurnover.multiply(commissionRate).setScale(2, RoundingMode.HALF_UP);

            WorkerCommission wc = WorkerCommission.builder()
                    .workerId(workerId)
                    .branchId(branchId)
                    .periodStart(periodStart)
                    .periodEnd(periodEnd)
                    .totalSales(totalSales)
                    .totalBuys(totalBuys)
                    .totalFees(totalFees)
                    .commissionRate(commissionRate)
                    .commissionAmount(commissionAmount)
                    .status(WorkerCommission.WorkerCommissionStatus.CALCULATED)
                    .build();

            commissions.add(repository.save(wc));
        }

        return commissions;
    }

    public List<WorkerCommission> findByPeriod(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        requireBranchInCurrentCompany(branchId);
        return repository.findByBranchAndPeriod(branchId, periodStart, periodEnd);
    }

    public List<Map<String, Object>> getAccountingList(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        requireBranchInCurrentCompany(branchId);
        List<WorkerCommission> commissions = repository.findByBranchAndPeriod(branchId, periodStart, periodEnd);
        List<Map<String, Object>> result = new ArrayList<>();

        for (WorkerCommission wc : commissions) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", wc.getId());
            m.put("workerId", wc.getWorkerId());
            m.put("periodStart", wc.getPeriodStart());
            m.put("periodEnd", wc.getPeriodEnd());
            m.put("totalSales", wc.getTotalSales());
            m.put("totalBuys", wc.getTotalBuys());
            m.put("totalFees", wc.getTotalFees());
            m.put("commissionRate", wc.getCommissionRate());
            m.put("commissionAmount", wc.getCommissionAmount());
            m.put("status", wc.getStatus().name());
            m.put("paidAt", wc.getPaidAt());
            result.add(m);
        }
        return result;
    }

    /**
     * Multi-tenant IDOR (NEW-3): branch-ownership guard.
     * Ellenőrzi, hogy a kért branchId a hívó cégéhez tartozik-e; ha nem,
     * ResourceNotFoundException (cross-tenant payroll-PII szivárgás ellen).
     */
    private void requireBranchInCurrentCompany(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Branch not found: " + branchId);
        }
    }
}
