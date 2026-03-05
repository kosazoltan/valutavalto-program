package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CommissionCalculation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CommissionCalculationRepository extends JpaRepository<CommissionCalculation, UUID> {

    Optional<CommissionCalculation> findByWorkerIdAndPeriod(Long workerId, String period);

    @Query("SELECT c FROM CommissionCalculation c " +
           "WHERE c.branchId = :branchId AND c.period = :period " +
           "ORDER BY c.workerId")
    List<CommissionCalculation> findByBranchIdAndPeriod(
            @Param("branchId") UUID branchId,
            @Param("period") String period);

    boolean existsByWorkerIdAndPeriod(Long workerId, String period);
}
