package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyChecklistItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * Napi checklist tétel repository.
 */
@Repository
public interface DailyChecklistItemRepository extends JpaRepository<DailyChecklistItem, UUID> {

    Optional<DailyChecklistItem> findByChecklistIdAndItemNumber(UUID checklistId, int itemNumber);
}
