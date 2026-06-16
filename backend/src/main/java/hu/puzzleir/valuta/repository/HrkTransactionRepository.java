package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HrkTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HrkTransactionRepository extends JpaRepository<HrkTransaction, UUID> {

    /**
     * IDOR-szűrt lekérés: a HrkTransaction NOT NULL companyId-jával cég-scope-olva.
     * Más cég tranzakciója és a nem létező tranzakció ugyanazt az üres eredményt adja
     * (nincs id-enumeráció oldalcsatorna).
     */
    Optional<HrkTransaction> findByIdAndCompanyId(UUID id, UUID companyId);

    List<HrkTransaction> findByBranchIdOrderByCreatedAtDesc(UUID branchId);

    List<HrkTransaction> findByBranchIdAndStatusOrderByCreatedAtDesc(UUID branchId, String status);

    @Query("SELECT h FROM HrkTransaction h WHERE h.branchId = :branchId " +
           "AND h.createdAt >= :startDate AND h.createdAt < :endDate " +
           "ORDER BY h.createdAt DESC")
    List<HrkTransaction> findByBranchIdAndDateRange(
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    @Query("SELECT COUNT(h) FROM HrkTransaction h WHERE h.branchId = :branchId " +
           "AND h.reference LIKE CONCAT(:prefix, '%')")
    long countByBranchIdAndReferencePrefix(
            @Param("branchId") UUID branchId,
            @Param("prefix") String prefix);
}
