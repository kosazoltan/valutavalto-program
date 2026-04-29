package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.WorkerCommission;
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

    public List<WorkerCommission> findAll(Long workerId, LocalDate periodStart, LocalDate periodEnd) {
        return repository.findWithFilters(workerId, periodStart, periodEnd);
    }

    public WorkerCommission findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("WorkerCommission not found: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public List<WorkerCommission> calculate(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
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
                workerTransactions.addAll(transactionRepository.findByWorkerAndDate(SecurityUtils.getCurrentCompanyId(), workerId, current));
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
        return repository.findByBranchAndPeriod(branchId, periodStart, periodEnd);
    }

    public List<Map<String, Object>> getAccountingList(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
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
}
