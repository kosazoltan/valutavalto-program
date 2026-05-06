package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BankOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BankOrderRepository extends JpaRepository<BankOrder, UUID> {

    Page<BankOrder> findByBranchIdOrderByRequestedAtDesc(UUID branchId, Pageable pageable);

    Page<BankOrder> findByStatusOrderByRequestedAtDesc(BankOrder.Status status, Pageable pageable);

    @Query("SELECT bo FROM BankOrder bo "
            + "WHERE bo.branch.company.id = :companyId "
            + "AND (:status IS NULL OR bo.status = :status) "
            + "ORDER BY bo.requestedAt DESC")
    Page<BankOrder> findByCompanyAndOptionalStatus(
            @Param("companyId") UUID companyId,
            @Param("status") BankOrder.Status status,
            Pageable pageable);

    List<BankOrder> findByStatusAndUrgencyOrderByRequestedAtAsc(
            BankOrder.Status status, BankOrder.Urgency urgency);
}
