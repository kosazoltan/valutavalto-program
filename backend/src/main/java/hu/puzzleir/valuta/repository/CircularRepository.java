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

    // === V88: Company szűréses lekérdezések ===

    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.archived = false ORDER BY c.createdAt DESC")
    List<Circular> findActiveByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.archived = true ORDER BY c.archivedAt DESC")
    List<Circular> findArchivedByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.category = :category AND c.archived = false ORDER BY c.createdAt DESC")
    List<Circular> findByCategoryAndCompanyId(@Param("companyId") UUID companyId, @Param("category") String category);

    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.archived = false " +
           "AND c.id NOT IN (SELECT ca.circular.id FROM CircularAcknowledgment ca WHERE ca.workerId = :workerId) " +
           "AND (c.target = 'ALL_BRANCHES' OR c.targetBranchId = :branchId " +
           "OR (c.target = 'COMPANY_SPECIFIC' AND c.targetCompanyId = :companyIdInt)) " +
           "ORDER BY c.priority DESC, c.urgent DESC, c.createdAt DESC")
    List<Circular> findUnacknowledgedForWorker(
            @Param("companyId") UUID companyId,
            @Param("workerId") Long workerId,
            @Param("branchId") UUID branchId,
            @Param("companyIdInt") Integer companyIdInt);

    /**
     * A4 (b9-korlevelek FR-02): a pénztáros olvasatlan, KÖTELEZŐ-nyugtázandó
     * (requires_acknowledgment=true) körlevelei — a tranzakció-blokkoló gate forrása.
     */
    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.archived = false " +
           "AND c.requiresAcknowledgment = true " +
           "AND c.id NOT IN (SELECT ca.circular.id FROM CircularAcknowledgment ca WHERE ca.workerId = :workerId) " +
           "AND (c.target = 'ALL_BRANCHES' OR c.targetBranchId = :branchId " +
           "OR (c.target = 'COMPANY_SPECIFIC' AND c.targetCompanyId = :companyIdInt)) " +
           "ORDER BY c.priority DESC, c.urgent DESC, c.createdAt DESC")
    List<Circular> findUnacknowledgedMandatoryForWorker(
            @Param("companyId") UUID companyId,
            @Param("workerId") Long workerId,
            @Param("branchId") UUID branchId,
            @Param("companyIdInt") Integer companyIdInt);

    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId AND c.archiveYear = :year ORDER BY c.createdAt DESC")
    List<Circular> findByArchiveYear(@Param("companyId") UUID companyId, @Param("year") Integer year);

    /**
     * Adott évben létrehozott körlevelek (év-nyitó archiváláshoz).
     */
    @Query("SELECT c FROM Circular c WHERE c.companyId = :companyId " +
           "AND YEAR(c.createdAt) = :year AND (c.archived IS NULL OR c.archived = false) " +
           "ORDER BY c.createdAt ASC")
    List<Circular> findByCompanyIdAndYear(@Param("companyId") UUID companyId, @Param("year") int year);
}
