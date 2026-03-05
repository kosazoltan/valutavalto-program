package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateApproval;
import hu.puzzleir.valuta.entity.RateApprovalStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RateApprovalRepository extends JpaRepository<RateApproval, UUID> {

    List<RateApproval> findByStatusOrderByRequestedAtDesc(RateApprovalStatus status);

    List<RateApproval> findByBranchIdOrderByRequestedAtDesc(UUID branchId);

    List<RateApproval> findByBranchIdAndStatusOrderByRequestedAtDesc(UUID branchId, RateApprovalStatus status);
}
