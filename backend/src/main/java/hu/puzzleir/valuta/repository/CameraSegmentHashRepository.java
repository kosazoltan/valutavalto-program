package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraSegmentHash;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CameraSegmentHashRepository extends JpaRepository<CameraSegmentHash, UUID> {

    /** Utolsó hash-lánc elem (a lánc folytatásához) */
    Optional<CameraSegmentHash> findTopByBranchIdAndCameraIdOrderBySequenceNumberDesc(
        UUID branchId, String cameraId);

    /** Teljes lánc sorrendben (integritás ellenőrzéshez) */
    List<CameraSegmentHash> findByBranchIdAndCameraIdOrderBySequenceNumberAsc(
        UUID branchId, String cameraId);

    /** Időszak szerinti lekérdezés (exporthoz) */
    List<CameraSegmentHash> findByBranchIdAndCameraIdAndCreatedAtBetweenOrderBySequenceNumberAsc(
        UUID branchId, String cameraId, LocalDateTime from, LocalDateTime to);

    /** Darabszám (sequence number kalkulációhoz) */
    int countByBranchIdAndCameraId(UUID branchId, String cameraId);

    /** Adott felvételhez tartozó hash-ek */
    List<CameraSegmentHash> findByRecordingId(UUID recordingId);
}
