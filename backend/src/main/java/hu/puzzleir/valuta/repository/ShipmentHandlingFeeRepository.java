package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface ShipmentHandlingFeeRepository extends JpaRepository<ShipmentHandlingFee, UUID> {

    Set<ShipmentRequestStatus> KPI_COUNTED_STATUSES = Collections.unmodifiableSet(EnumSet.of(
            ShipmentRequestStatus.SUBMITTED,
            ShipmentRequestStatus.APPROVED,
            ShipmentRequestStatus.IN_TRANSIT,
            ShipmentRequestStatus.DELIVERED));

    /** Tenant-safe egyetlen olvasási belépési pont. */
    Optional<ShipmentHandlingFee> findByShipmentRequestIdAndCompanyId(
            UUID shipmentRequestId, UUID companyId);

    /**
     * FR-6 kezelési díj KPI Shipment-eredetű része.
     *
     * <p>D-0: az összeg a fizikailag átvett, 5 Ft-ra kerekített {@code hufAmount}, nem a
     * bizonylati kontrollérték {@code calculatedFee}. TBD-1: a gazdasági esemény napja a
     * {@code createdAt} szerinti félig nyílt időablak. TBD-2: csak a pozitív, fail-closed státusz-
     * whitelist számít. TBD-3: a díj a fogadó {@code ShipmentRequest.toBranchId} dashboardján
     * jelenik meg, nem a küldő branchén.</p>
     *
     * <p>A companyId-szűrés a multi-tenant invariáns #1 miatt kötelező. Az autoritatív
     * tenant-kulcs a {@code ShipmentHandlingFee.companyId}; a join-olt ShipmentRequest nullable
     * companyId-ja szándékosan nem vesz részt a tenant-szűrésben.</p>
     */
    @Query("""
            SELECT COALESCE(SUM(f.hufAmount), 0)
            FROM ShipmentHandlingFee f, ShipmentRequest r
            WHERE r.id = f.shipmentRequestId
              AND f.companyId = :companyId
              AND r.toBranchId = :branchId
              AND f.createdAt >= :from
              AND f.createdAt < :to
              AND f.status IN :statuses
            """)
    BigDecimal sumReceivedFeesForBranchAndPeriod(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);

    default BigDecimal sumDailyReceivedFees(UUID companyId, UUID branchId, LocalDate date) {
        LocalDateTime from = date.atStartOfDay();
        return sumReceivedFeesForBranchAndPeriod(
                companyId,
                branchId,
                from,
                date.plusDays(1).atStartOfDay(),
                KPI_COUNTED_STATUSES);
    }
}
