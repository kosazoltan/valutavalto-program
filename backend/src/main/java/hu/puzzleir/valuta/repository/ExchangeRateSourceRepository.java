package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ExchangeRateSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ExchangeRateSource repository.
 */
@Repository
public interface ExchangeRateSourceRepository extends JpaRepository<ExchangeRateSource, Long> {

    Optional<ExchangeRateSource> findBySourceName(String sourceName);

    List<ExchangeRateSource> findByActiveTrue();
}
