package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateApproval;
import hu.puzzleir.valuta.entity.RateApprovalStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RateApprovalRepository extends JpaRepository<RateApproval, UUID> {

    /**
     * Tenant-safe findById — csak a saját cég branch-eihez tartozó approval-okat adja vissza.
     * Audit P0.2 fix (2026-05-17): a korábbi {@code findById} cross-tenant data leak-et okozott.
     */
    Optional<RateApproval> findByIdAndBranch_Company_Id(UUID id, UUID companyId);

    /**
     * Tenant-safe pending approvals lekérdezés.
     */
    List<RateApproval> findByStatusAndBranch_Company_IdOrderByRequestedAtDesc(
            RateApprovalStatus status, UUID companyId);

    /**
     * Tenant-safe branch-szintű history.
     */
    List<RateApproval> findByBranchIdAndBranch_Company_IdOrderByRequestedAtDesc(
            UUID branchId, UUID companyId);

    /**
     * Tenant-safe company-szintű history (minden branch).
     */
    List<RateApproval> findByBranch_Company_IdOrderByRequestedAtDesc(UUID companyId);

    // ============ DEPRECATED legacy metódusok ============
    // A v2 audit P0.2 finding alapján ezek cross-tenant data leak-et okoznak.
    // Új kódban TILOS használni. Service-ek migrálva a tenant-safe variánsokra.
    // TODO: 2026-Q3 sprintben törölhetők ha minden hívó migrált.

    /** @deprecated audit P0.2 — use {@link #findByStatusAndBranch_Company_IdOrderByRequestedAtDesc} */
    @Deprecated
    List<RateApproval> findByStatusOrderByRequestedAtDesc(RateApprovalStatus status);

    /** @deprecated audit P0.2 — use {@link #findByBranchIdAndBranch_Company_IdOrderByRequestedAtDesc} */
    @Deprecated
    List<RateApproval> findByBranchIdOrderByRequestedAtDesc(UUID branchId);

    /** @deprecated audit P0.2 — use the tenant-safe variants */
    @Deprecated
    List<RateApproval> findByBranchIdAndStatusOrderByRequestedAtDesc(UUID branchId, RateApprovalStatus status);
}
