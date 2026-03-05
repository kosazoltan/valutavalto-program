package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.PackagingRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface PackagingRecordRepository extends JpaRepository<PackagingRecord, UUID> {

    List<PackagingRecord> findByBranchIdAndPackagingDateBetweenOrderByPackagingDateDesc(
        UUID branchId, LocalDate from, LocalDate to);

    List<PackagingRecord> findByBranchIdOrderByPackagingDateDesc(UUID branchId);
}
