package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FeeRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface FeeRateRepository extends JpaRepository<FeeRate, UUID> {
    List<FeeRate> findByBranchIdIn(List<UUID> branchIds);
}
