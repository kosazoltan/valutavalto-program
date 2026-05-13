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

    // Codex P2 #570 fix: dual-approval pending list — REQUESTED + AWAITING_SECOND_APPROVAL.
    List<CameraExportRequest> findByStatusInOrderByCreatedAtAsc(List<CameraExportStatus> statuses);

    List<CameraExportRequest> findByRequestedByOrderByCreatedAtDesc(String requestedBy);
}
