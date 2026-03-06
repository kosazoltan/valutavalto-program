package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LedDisplayConfigRepository extends JpaRepository<LedDisplayConfig, UUID> {

    Optional<LedDisplayConfig> findByBranchId(UUID branchId);
}
