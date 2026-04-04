package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface DailyDenominationSnapshotRepository extends JpaRepository<DailyDenominationSnapshot, UUID> {

    List<DailyDenominationSnapshot> findByBranchIdAndSnapshotDate(UUID branchId, LocalDate snapshotDate);

    boolean existsByBranchIdAndSnapshotDate(UUID branchId, LocalDate snapshotDate);

    List<DailyDenominationSnapshot> findByBranchIdAndSnapshotDateAndClosingType(
            UUID branchId, LocalDate snapshotDate, Integer closingType);
}
