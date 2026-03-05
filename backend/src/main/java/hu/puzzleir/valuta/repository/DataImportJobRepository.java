package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DataImportJob;
import hu.puzzleir.valuta.entity.DataImportStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DataImportJobRepository extends JpaRepository<DataImportJob, UUID> {

    @Query("SELECT j FROM DataImportJob j WHERE j.branch.id = :branchId ORDER BY j.createdAt DESC")
    Page<DataImportJob> findByBranchId(@Param("branchId") UUID branchId, Pageable pageable);

    List<DataImportJob> findByStatus(DataImportStatus status);
}
