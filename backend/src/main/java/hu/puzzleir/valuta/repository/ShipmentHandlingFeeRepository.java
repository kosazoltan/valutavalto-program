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

    /**
     * FKH-036 FR-6: volt-e aznap KK kezelési díj mozgás a KÜLDŐ (source) branchről.
     *
     * <p>B2 FIX (terv 10. döntése): az ÜZLETI DÁTUM a szülő {@code ShipmentRequest.requestDate},
     * NEM az {@code f.createdAt} audit-időbélyeg. A {@code ShipmentHandlingFee}-nek nincs saját
     * üzleti dátum oszlopa; a díjsor a {@code ShipmentHandlingFeeService.create}-ben, a frissen
     * mentett kéréshez keletkezik, tehát a kéréshez tartozó üzleti nap az irányadó. Így a
     * kötelező valuta-halmaz és a {@code handlingFeeRequired} UGYANARRA a napra dönt — éjfél
     * körül sem csúszhatnak szét.</p>
     *
     * <p>TENANT (invariáns #1): az autoritatív kulcs az {@code f.companyId}. A join-olt
     * ShipmentRequest companyId-ja NULLABLE (ld. a {@link #sumReceivedFeesForBranchAndPeriod}
     * javadocját), ezért az {@code r} SOHA nem lehet a tenant-predikátum — kizárólag a
     * requestDate/serialPrefix forrása.</p>
     *
     * <p>A KK-prefix szűrés explicit: a díj-vertikum saját bizonylattípusa
     * ({@code ShipmentHandlingFeeService.SERIAL_PREFIX_HANDLING_FEE}).</p>
     *
     * <p>MEGJEGYZÉS: a fenti KPI-lekérdezés ({@code sumReceivedFeesForBranchAndPeriod}) a saját,
     * dokumentált TBD-1 döntésével ({@code createdAt} félig nyílt időablak) VÁLTOZATLAN marad —
     * ez a metódus additív, és kizárólag az FKH-036 záró-kapu használja.</p>
     */
    @Query("""
            SELECT COUNT(f) > 0
            FROM ShipmentHandlingFee f, ShipmentRequest r
            WHERE r.id = f.shipmentRequestId
              AND f.companyId = :companyId
              AND f.sourceBranchId = :branchId
              AND r.serialPrefix = 'KK'
              AND r.requestDate = :date
              AND f.status IN :statuses
            """)
    boolean existsMovementForBranchAndDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);

    /** FKH-036 FR-6: a fail-closed státusz-whitelist egyetlen közös forrása. */
    default boolean existsDailyMovementForSourceBranch(UUID companyId, UUID branchId, LocalDate date) {
        return existsMovementForBranchAndDate(companyId, branchId, date, KPI_COUNTED_STATUSES);
    }
}
