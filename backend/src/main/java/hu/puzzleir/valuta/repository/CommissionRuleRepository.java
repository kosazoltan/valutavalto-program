package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CommissionRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * CommissionRule repository — tier-alapú jutalék szabályok.
 */
@Repository
public interface CommissionRuleRepository extends JpaRepository<CommissionRule, UUID> {

    @Query("SELECT r FROM CommissionRule r " +
           "WHERE r.companyId = :companyId " +
           "AND r.validFrom <= :date " +
           "AND (r.validTo IS NULL OR r.validTo >= :date) " +
           "ORDER BY r.tier ASC")
    List<CommissionRule> findActiveRules(
            @Param("companyId") UUID companyId,
            @Param("date") LocalDate date);
}
