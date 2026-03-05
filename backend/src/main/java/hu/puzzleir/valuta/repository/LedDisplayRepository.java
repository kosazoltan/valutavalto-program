package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.LedDisplay;
import hu.puzzleir.valuta.entity.LedDisplayType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LedDisplayRepository extends JpaRepository<LedDisplay, UUID> {

    List<LedDisplay> findByBranchId(UUID branchId);

    Optional<LedDisplay> findByBranchIdAndDisplayType(UUID branchId, LedDisplayType displayType);
}
