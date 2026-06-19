package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraRecording;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CameraRecordingRepository extends JpaRepository<CameraRecording, UUID> {
    Optional<CameraRecording> findByIdAndBranchId(UUID id, UUID branchId);

    List<CameraRecording> findByBranchIdAndCameraIdAndStartTimeBetween(
        UUID branchId, String cameraId, LocalDateTime start, LocalDateTime end);

    List<CameraRecording> findByBranchIdAndStartTimeBetween(
        UUID branchId, LocalDateTime start, LocalDateTime end);

    List<CameraRecording> findByExpiresAtBeforeAndStatusNot(
        LocalDate date, CameraRecording.RecordingStatus status);

    List<CameraRecording> findByUploadedToServerFalseAndStatusIn(
        List<CameraRecording.RecordingStatus> statuses);

    @Query("SELECT COALESCE(SUM(r.fileSizeBytes), 0) FROM CameraRecording r WHERE r.branchId = :branchId")
    Long getTotalStorageByBranch(@Param("branchId") UUID branchId);

    List<CameraRecording> findByBranchIdAndStatus(UUID branchId, CameraRecording.RecordingStatus status);
}
