package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyChecklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * Napi checklist repository.
 */
@Repository
public interface DailyChecklistRepository extends JpaRepository<DailyChecklist, UUID> {

    Optional<DailyChecklist> findByBranchIdAndChecklistDateAndCompanyId(
            UUID branchId, LocalDate checklistDate, UUID companyId);

    boolean existsByBranchIdAndChecklistDateAndCompanyId(
            UUID branchId, LocalDate checklistDate, UUID companyId);
}
