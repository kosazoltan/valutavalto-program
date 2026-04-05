package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface DailyDenominationSnapshotRepository extends JpaRepository<DailyDenominationSnapshot, UUID> {

    List<DailyDenominationSnapshot> findByBranchIdAndSnapshotDate(UUID branchId, LocalDate snapshotDate);

    boolean existsByBranchIdAndSnapshotDate(UUID branchId, LocalDate snapshotDate);

    List<DailyDenominationSnapshot> findByBranchIdAndSnapshotDateAndClosingType(
            UUID branchId, LocalDate snapshotDate, Integer closingType);

    /**
     * Év-nyitó: régi snapshot-ok törlése adott dátum előtt (tenant-izolált).
     */
    @Modifying
    @Query("DELETE FROM DailyDenominationSnapshot d WHERE d.branchId IN :branchIds AND d.snapshotDate < :cutoffDate")
    int deleteByBranchIdsAndSnapshotDateBefore(@Param("branchIds") List<UUID> branchIds, @Param("cutoffDate") LocalDate cutoffDate);
}
