package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraAccessLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CameraAccessLogRepository extends JpaRepository<CameraAccessLog, UUID> {
    List<CameraAccessLog> findByRecordingIdOrderByCreatedAtDesc(UUID recordingId);
    List<CameraAccessLog> findByWorkerIdOrderByCreatedAtDesc(Long workerId);
}
