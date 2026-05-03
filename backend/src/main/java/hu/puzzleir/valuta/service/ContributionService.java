package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Contribution;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.ContributionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
public class ContributionService {

    /** Sprint 7.2 CB-016: konfigurálható MNB felügyeleti díj kulcs (alapértelmezett 0.01%) */
    private static final String MNB_FEE_RATE_KEY = "mnb.supervisory-fee-rate";
    private static final BigDecimal DEFAULT_MNB_FEE_RATE = new BigDecimal("0.0001");

    /** Sprint 7.2 CB-016: konfigurálható ÁFA kulcs (alapértelmezett 27%) */
    private static final String VAT_RATE_KEY = "nav.vat-rate.STANDARD";
    private static final BigDecimal DEFAULT_VAT_RATE = new BigDecimal("0.27");

    private final ContributionRepository repository;
    private final TransactionRepository transactionRepository;
    private final SystemParameterService systemParameterService;

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

        // Calculate total turnover for the period.
        // User-direktiva 2026-05-03: hozzajarulas-szamitas riport-celu — a parent CONVERSION
        // sorok (csak metadata) NEM duplazhatjak a forgalmat. `findFinanciallyEffectiveByBranchAndDate`
        // szuri.
        List<Transaction> transactions = new ArrayList<>();
        LocalDate current = periodStart;
        while (!current.isAfter(periodEnd)) {
            transactions.addAll(transactionRepository.findFinanciallyEffectiveByBranchAndDate(branchId, current));
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
                .amount(totalTurnover.multiply(resolveRate(MNB_FEE_RATE_KEY, DEFAULT_MNB_FEE_RATE)).setScale(2, RoundingMode.HALF_UP))
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
                .amount(totalFees.multiply(resolveRate(VAT_RATE_KEY, DEFAULT_VAT_RATE)).setScale(2, RoundingMode.HALF_UP))
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

    /**
     * Sprint 7.2 CB-016: SystemParameter-bol lekert kulcs (ÁFA, MNB díj).
     * Fallback ha nincs beállítva vagy hibás érték.
     *
     * @param key      SystemParameter kulcs (pl. "nav.vat-rate.STANDARD")
     * @param fallback default értek ha a paraméter hiányzik vagy érvénytelen
     * @return érvényes, nem-negatív BigDecimal
     */
    private BigDecimal resolveRate(String key, BigDecimal fallback) {
        String raw;
        try {
            raw = systemParameterService.getValue(key, null);
        } catch (org.springframework.dao.DataAccessException e) {
            // Sourcery PR #128 fix: narrower catch + key-specific logging
            log.warn("Rate parameter DB-hiba, fallback: key={}, fallback={}, hiba={}",
                    key, fallback, e.getMessage(), e);
            return fallback;
        }

        if (raw == null || raw.isBlank()) {
            log.debug("Rate parameter hianyzik, fallback: key={}, fallback={}", key, fallback);
            return fallback;
        }

        try {
            BigDecimal value = new BigDecimal(raw.trim());
            if (value.signum() < 0) {
                log.warn("Rate parameter negativ, fallback: key={}, raw={}, fallback={}", key, raw, fallback);
                return fallback;
            }
            return value;
        } catch (NumberFormatException e) {
            // Sourcery PR #128 fix: raw value-t is loggoljuk hogy visszakovetheto legyen
            log.warn("Rate parameter nem decimalis, fallback: key={}, raw='{}', fallback={}, hiba={}",
                    key, raw, fallback, e.getMessage());
            return fallback;
        }
    }
}
