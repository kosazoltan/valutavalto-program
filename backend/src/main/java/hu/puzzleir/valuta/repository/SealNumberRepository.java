package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SealNumber;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SealNumberRepository extends JpaRepository<SealNumber, UUID> {

    Optional<SealNumber> findBySealNumber(String sealNumber);

    @Query("SELECT MAX(s.sealNumber) FROM SealNumber s WHERE s.branchId = :branchId " +
           "AND s.createdAt BETWEEN :dayStart AND :dayEnd")
    Optional<String> findLastSealNumberByBranchAndDay(
        @Param("branchId") UUID branchId,
        @Param("dayStart") LocalDateTime dayStart,
        @Param("dayEnd") LocalDateTime dayEnd);

    List<SealNumber> findByBranchIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID branchId);

    List<SealNumber> findByBranchIdAndCreatedAtBetweenOrderByCreatedAtDesc(
        UUID branchId, LocalDateTime from, LocalDateTime to);
}
