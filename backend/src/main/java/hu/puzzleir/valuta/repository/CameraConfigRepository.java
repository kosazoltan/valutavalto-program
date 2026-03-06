package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CameraConfigRepository extends JpaRepository<CameraConfig, UUID> {
    List<CameraConfig> findByBranchId(UUID branchId);
    Optional<CameraConfig> findByBranchIdAndCameraId(UUID branchId, String cameraId);
    List<CameraConfig> findByBranchIdAndEnabled(UUID branchId, Boolean enabled);
}
