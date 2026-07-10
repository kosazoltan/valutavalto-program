package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraReviewStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CameraReviewStatusRepository extends JpaRepository<CameraReviewStatus, UUID> {

    Optional<CameraReviewStatus> findByCompanyIdAndBranchIdAndReviewDate(
            UUID companyId, UUID branchId, LocalDate reviewDate);

    List<CameraReviewStatus> findByCompanyIdAndReviewDateBetween(UUID companyId, LocalDate start, LocalDate end);
}
