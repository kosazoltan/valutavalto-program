package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ChainOfCustodyRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChainOfCustodyRepository extends JpaRepository<ChainOfCustodyRecord, UUID> {

    List<ChainOfCustodyRecord> findByExportRequestIdOrderByEventTimestampAsc(UUID exportRequestId);

    List<ChainOfCustodyRecord> findByBranchIdOrderByEventTimestampDesc(UUID branchId);

    List<ChainOfCustodyRecord> findByBranchIdAndCameraIdOrderByEventTimestampDesc(UUID branchId, String cameraId);

    List<ChainOfCustodyRecord> findByActorOrderByEventTimestampDesc(String actor);
}
