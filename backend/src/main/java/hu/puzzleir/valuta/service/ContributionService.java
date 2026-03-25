package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Contribution;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.ContributionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ContributionService {

    private final ContributionRepository repository;
    private final TransactionRepository transactionRepository;

    public List<Contribution> findAll(UUID branchId, String contributionType) {
        return repository.findWithFilters(branchId, contributionType);
    }

    public Contribution findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contribution not found: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public List<Contribution> calculate(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        List<Contribution> contributions = new ArrayList<>();

        // Calculate total turnover for the period
        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = periodStart;
        while (!current.isAfter(periodEnd)) {
            transactions.addAll(transactionRepository.findActiveByBranchAndDate(branchId, current));
            current = current.plusDays(1);
        }

        BigDecimal totalTurnover = transactions.stream()
                .map(t -> t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFees = transactions.stream()
                .map(t -> t.getHandlingFee() != null ? t.getHandlingFee() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // MNB contribution (PSZÁF díj) — simplified calculation
        Contribution mnbContribution = Contribution.builder()
                .contributionType("MNB_SUPERVISORY_FEE")
                .branchId(branchId)
                .amount(totalTurnover.multiply(new BigDecimal("0.0001")).setScale(2, RoundingMode.HALF_UP))
                .periodStart(periodStart)
                .periodEnd(periodEnd)
                .status(Contribution.ContributionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();
        contributions.add(repository.save(mnbContribution));

        // Handling fee contribution
        Contribution feeContribution = Contribution.builder()
                .contributionType("HANDLING_FEE_TAX")
                .branchId(branchId)
                .amount(totalFees.multiply(new BigDecimal("0.27")).setScale(2, RoundingMode.HALF_UP))
                .periodStart(periodStart)
                .periodEnd(periodEnd)
                .status(Contribution.ContributionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();
        contributions.add(repository.save(feeContribution));

        return contributions;
    }

    public List<Contribution> findByPeriod(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        return repository.findByBranchAndPeriod(branchId, periodStart, periodEnd);
    }
}
