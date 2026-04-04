package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailySubledgerSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailySubledgerSnapshotRepository extends JpaRepository<DailySubledgerSnapshot, UUID> {

    List<DailySubledgerSnapshot> findByBranchIdAndSnapshotDate(UUID branchId, LocalDate snapshotDate);

    Optional<DailySubledgerSnapshot> findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
            UUID branchId, LocalDate snapshotDate, String subledgerType, String currencyCode);

    boolean existsByBranchIdAndSnapshotDateAndSubledgerType(
            UUID branchId, LocalDate snapshotDate, String subledgerType);

    /**
     * Havi range query: adott idoszak osszes snapshot-ja subledger tipus + valuta szerint.
     * N+1 query eliminacio — egyetlen DB hivas a napi iteracio helyett.
     */
    List<DailySubledgerSnapshot> findByBranchIdAndSnapshotDateBetweenAndSubledgerTypeAndCurrencyCode(
            UUID branchId, LocalDate startDate, LocalDate endDate,
            String subledgerType, String currencyCode);
}
