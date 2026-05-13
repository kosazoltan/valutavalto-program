package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DenominationOptimizationRepository extends JpaRepository<DenominationOptimization, UUID> {

    Optional<DenominationOptimization> findByName(String name);

    Optional<DenominationOptimization> findByIsDefaultTrueAndIsActiveTrue();

    List<DenominationOptimization> findByIsActiveTrueOrderByNameAsc();
}
