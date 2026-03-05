package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.StampBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface StampBatchRepository extends JpaRepository<StampBatch, UUID> {

    @Query("SELECT b FROM StampBatch b WHERE b.companyId = :companyId " +
           "ORDER BY b.receivedAt DESC")
    List<StampBatch> findByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT b FROM StampBatch b WHERE b.companyId = :companyId " +
           "AND b.branchId = :branchId ORDER BY b.receivedAt DESC")
    List<StampBatch> findByCompanyIdAndBranchId(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId);
}
