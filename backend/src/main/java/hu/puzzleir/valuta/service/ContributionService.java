package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Contribution;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ContributionRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
    // IDOR-fix (audit 2026-06-15, FINDING #9): a Contribution tenancy-je a branch_id-n keresztül él
    // (nincs közvetlen company_id); minden user-vezérelt branchId-t a hívó cégéhez kötünk.
    private final BranchRepository branchRepository;

    public List<Contribution> findAll(UUID branchId, String contributionType) {
        if (branchId != null) {
            assertBranchInCurrentCompany(branchId);
            return repository.findWithFilters(branchId, contributionType);
        }
        // branchId nélkül cég-szintű lista: a hívó cégéhez tartozó branch-ekre szűkítve
        // (a findWithFilters önmagában minden céget visszaadna — company_id oszlop hiányában szűrünk).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repository.findWithFilters(null, contributionType).stream()
                .filter(c -> branchRepository.existsByIdAndCompanyId(c.getBranchId(), companyId))
                .toList();
    }

    public Contribution findById(UUID id) {
        Contribution contribution = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contribution not found: " + id));
        // branch_id NOT NULL → mindig ellenőrizhető; cross-tenant esetén ugyanaz a "not found".
        if (!branchRepository.existsByIdAndCompanyId(
                contribution.getBranchId(), SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Contribution not found: " + id);
        }
        return contribution;
    }

    @Transactional(rollbackFor = Exception.class)
    public List<Contribution> calculate(UUID branchId, LocalDate periodStart, LocalDate periodEnd) {
        assertBranchInCurrentCompany(branchId);
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
        assertBranchInCurrentCompany(branchId);
        return repository.findByBranchAndPeriod(branchId, periodStart, periodEnd);
    }

    /** User által megadott branchId a hívó cégéhez kötése; cross-tenant → ResourceNotFoundException. */
    private void assertBranchInCurrentCompany(UUID branchId) {
        if (branchId == null
                || !branchRepository.existsByIdAndCompanyId(branchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Branch not found: " + branchId);
        }
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
