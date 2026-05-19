package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BankOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BankOrderRepository extends JpaRepository<BankOrder, UUID> {

    /**
     * Tenant-safe findById — csak a saját cég branch-eihez tartozó bank order-t adja vissza.
     * Audit P0 fix (2026-05-19): a {@link #findById(Object)} cross-tenant IDOR-t okozott
     * (SUPERVISOR Company A APPROVE-olhatott Company B bank order-t a {@code BankOrderService}-en át).
     * Mintát követi: {@link RateApprovalRepository#findByIdAndBranch_Company_Id}.
     */
    Optional<BankOrder> findByIdAndBranch_Company_Id(UUID id, UUID companyId);

    /**
     * Tenant-safe lapozható lista — saját cég bank order-jai, opcionális status szűréssel.
     * A {@code status} paraméter NULL → minden status visszaadása.
     */
    @Query("SELECT bo FROM BankOrder bo "
            + "WHERE bo.branch.company.id = :companyId "
            + "AND (:status IS NULL OR bo.status = :status) "
            + "ORDER BY bo.requestedAt DESC")
    Page<BankOrder> findByCompanyAndOptionalStatus(
            @Param("companyId") UUID companyId,
            @Param("status") BankOrder.Status status,
            Pageable pageable);

    // ============ DEPRECATED legacy metódusok ============
    // Audit P0 finding (2026-05-19): cross-tenant data leak — SUPERVISOR/MANAGER/ADMIN
    // role hasAnyRole guard önmagában NEM elég, a company_id szűrés is kötelező.
    // Új kódban TILOS használni. Service-ek migrálva a tenant-safe variánsokra.

    /** @deprecated audit P0 — use {@link #findByCompanyAndOptionalStatus} (branch must belong to current company) */
    @Deprecated
    Page<BankOrder> findByBranchIdOrderByRequestedAtDesc(UUID branchId, Pageable pageable);

    /** @deprecated audit P0 — use {@link #findByCompanyAndOptionalStatus} */
    @Deprecated
    Page<BankOrder> findByStatusOrderByRequestedAtDesc(BankOrder.Status status, Pageable pageable);

    /** @deprecated audit P0 — currently no caller; if reintroduced, must include companyId filter */
    @Deprecated
    List<BankOrder> findByStatusAndUrgencyOrderByRequestedAtAsc(
            BankOrder.Status status, BankOrder.Urgency urgency);
}
