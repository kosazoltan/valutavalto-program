package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Circular;
import hu.puzzleir.valuta.entity.CircularType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CircularRepository extends JpaRepository<Circular, Long> {

    @Query("SELECT c FROM Circular c WHERE c.acknowledged = false ORDER BY c.urgent DESC, c.createdAt DESC")
    List<Circular> findUnacknowledged();

    @Query("SELECT c FROM Circular c ORDER BY c.createdAt DESC")
    List<Circular> findAllOrderByCreatedAtDesc();

    /** Típus szerinti szűrés */
    @Query("SELECT c FROM Circular c WHERE c.circularType = :type ORDER BY c.createdAt DESC")
    List<Circular> findByType(@Param("type") CircularType type);

    /** Cél iroda / cég szerinti szűrés (target_branch_id vagy target = ALL_BRANCHES) */
    @Query("SELECT c FROM Circular c WHERE " +
           "(c.target = 'ALL_BRANCHES' OR c.targetBranchId = :branchId " +
           "OR (c.target = 'COMPANY_SPECIFIC' AND c.targetCompanyId = :companyId)) " +
           "AND c.acknowledged = false " +
           "ORDER BY c.priority DESC, c.urgent DESC, c.createdAt DESC")
    List<Circular> findRelevantForBranch(
        @Param("branchId") UUID branchId,
        @Param("companyId") Integer companyId);

    /** Prioritás szerinti szűrés */
    @Query("SELECT c FROM Circular c WHERE c.priority = :priority ORDER BY c.createdAt DESC")
    List<Circular> findByPriority(@Param("priority") CircularType.CircularPriority priority);

    /** Iktatószám szerinti keresés */
    List<Circular> findByRegistrationNumberContainingIgnoreCase(String registrationNumber);
}
