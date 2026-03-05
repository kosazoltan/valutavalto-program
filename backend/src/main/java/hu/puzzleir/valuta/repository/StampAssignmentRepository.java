package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.StampAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface StampAssignmentRepository extends JpaRepository<StampAssignment, UUID> {

    Optional<StampAssignment> findBySerialNumber(String serialNumber);

    boolean existsBySerialNumber(String serialNumber);

    @Query("SELECT a FROM StampAssignment a WHERE a.stampBatch.id = :batchId " +
           "ORDER BY a.serialNumber ASC")
    List<StampAssignment> findByStampBatchId(@Param("batchId") UUID batchId);

    @Query("SELECT a FROM StampAssignment a WHERE a.transactionId IS NOT NULL " +
           "AND a.stampBatch.companyId = :companyId " +
           "ORDER BY a.assignedAt DESC")
    List<StampAssignment> findUsedByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT COUNT(a) FROM StampAssignment a WHERE a.stampBatch.id = :batchId")
    long countByBatchId(@Param("batchId") UUID batchId);
}
