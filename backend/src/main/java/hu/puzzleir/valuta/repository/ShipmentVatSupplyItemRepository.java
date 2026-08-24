package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface ShipmentVatSupplyItemRepository extends JpaRepository<ShipmentVatSupplyItem, UUID> {

    Set<ShipmentRequestStatus> KPI_COUNTED_STATUSES = java.util.Collections.unmodifiableSet(EnumSet.of(
            ShipmentRequestStatus.SUBMITTED,
            ShipmentRequestStatus.APPROVED,
            ShipmentRequestStatus.IN_TRANSIT,
            ShipmentRequestStatus.DELIVERED));

    Optional<ShipmentVatSupplyItem> findByShipmentRequestIdAndCompanyId(UUID shipmentRequestId, UUID companyId);

    @Query("""
            SELECT CASE WHEN COUNT(i) > 0 THEN true ELSE false END
            FROM ShipmentVatSupplyItem i, ShipmentRequest r
            WHERE r.id = i.shipmentRequestId
              AND i.companyId = :companyId
              AND (i.fromBranchId = :branchId OR i.toBranchId = :branchId)
              AND r.serialPrefix = 'AS'
              AND r.requestDate = :date
              AND i.status IN :statuses
            """)
    boolean existsMovementForBranchAndDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") java.time.LocalDate date,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);

    default boolean existsDailyMovementForBranch(UUID companyId, UUID branchId, java.time.LocalDate date) {
        return existsMovementForBranchAndDate(companyId, branchId, date, KPI_COUNTED_STATUSES);
    }
}
