package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Contribution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface ContributionRepository extends JpaRepository<Contribution, UUID> {

    @Query("SELECT c FROM Contribution c WHERE " +
           "(:branchId IS NULL OR c.branchId = :branchId) " +
           "AND (:contributionType IS NULL OR c.contributionType = :contributionType) " +
           "ORDER BY c.periodStart DESC")
    List<Contribution> findWithFilters(
            @Param("branchId") UUID branchId,
            @Param("contributionType") String contributionType);

    @Query("SELECT c FROM Contribution c WHERE " +
           "c.branchId = :branchId " +
           "AND c.periodStart = :periodStart " +
           "AND c.periodEnd = :periodEnd " +
           "ORDER BY c.contributionType")
    List<Contribution> findByBranchAndPeriod(
            @Param("branchId") UUID branchId,
            @Param("periodStart") LocalDate periodStart,
            @Param("periodEnd") LocalDate periodEnd);
}
