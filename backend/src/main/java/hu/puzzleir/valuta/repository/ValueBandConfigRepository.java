package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ValueBandConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ValueBandConfigRepository extends JpaRepository<ValueBandConfig, UUID> {

    Optional<ValueBandConfig> findTopByEffectiveFromLessThanEqualOrderByEffectiveFromDesc(LocalDate date);

    boolean existsByEffectiveFrom(LocalDate effectiveFrom);

    List<ValueBandConfig> findAllByOrderByEffectiveFromDesc();
}
