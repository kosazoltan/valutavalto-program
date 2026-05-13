package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DenominationRuleRepository extends JpaRepository<DenominationRule, UUID> {

    Optional<DenominationRule> findByRuleName(String ruleName);

    List<DenominationRule> findByIsActiveTrueOrderByPriorityAsc();

    /**
     * A leginkább specifikus aktív szabályt választja egy tranzakcióhoz.
     * Prioritás (kisebb = fontosabb), majd specifikusság: branch-specifikus → currency-specifikus → általános.
     */
    @Query("""
        SELECT r FROM DenominationRule r
        WHERE r.isActive = true
          AND (r.branchId IS NULL OR r.branchId = :branchId)
          AND (r.currencyId IS NULL OR r.currencyId = :currencyId)
          AND (r.minAmount IS NULL OR :hufAmount >= r.minAmount)
          AND (r.maxAmount IS NULL OR :hufAmount <= r.maxAmount)
        ORDER BY
          CASE WHEN r.branchId IS NOT NULL THEN 0 ELSE 1 END,
          CASE WHEN r.currencyId IS NOT NULL THEN 0 ELSE 1 END,
          r.priority ASC
    """)
    List<DenominationRule> findMatchingRules(
            @Param("branchId") UUID branchId,
            @Param("currencyId") Long currencyId,
            @Param("hufAmount") BigDecimal hufAmount);
}
