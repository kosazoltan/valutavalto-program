package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraReviewMark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface CameraReviewMarkRepository extends JpaRepository<CameraReviewMark, UUID> {

    List<CameraReviewMark> findByCompanyIdAndBranchIdAndReviewDateAndDeletedAtIsNullOrderByMarkTimeAsc(
            UUID companyId, UUID branchId, LocalDate reviewDate);

    List<CameraReviewMark> findByCompanyIdAndReviewDateBetweenAndDeletedAtIsNull(
            UUID companyId, LocalDate start, LocalDate end);
}
