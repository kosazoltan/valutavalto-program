package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RoundingRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Kerekítési szabályok repository.
 */
@Repository
public interface RoundingRuleRepository extends JpaRepository<RoundingRule, Long> {

    /**
     * Kerekítési szabály keresése valutakód alapján
     */
    Optional<RoundingRule> findByCurrencyCode(String currencyCode);
}
