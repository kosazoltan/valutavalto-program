package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraExportRequest;
import hu.puzzleir.valuta.entity.CameraExportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CameraExportRequestRepository extends JpaRepository<CameraExportRequest, UUID> {

    List<CameraExportRequest> findByBranchIdOrderByCreatedAtDesc(UUID branchId);

    List<CameraExportRequest> findByStatusOrderByCreatedAtAsc(CameraExportStatus status);

    List<CameraExportRequest> findByRequestedByOrderByCreatedAtDesc(String requestedBy);
}
