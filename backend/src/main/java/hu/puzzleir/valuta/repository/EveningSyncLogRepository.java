package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EveningSyncLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EveningSyncLogRepository extends JpaRepository<EveningSyncLog, Long> {

    Optional<EveningSyncLog> findByBranchIdAndSyncDate(UUID branchId, LocalDate syncDate);

    boolean existsByBranchIdAndSyncDateAndStatus(UUID branchId, LocalDate syncDate, String status);
}
