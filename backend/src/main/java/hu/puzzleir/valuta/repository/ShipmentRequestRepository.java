package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Repository
public interface ShipmentRequestRepository extends JpaRepository<ShipmentRequest, UUID> {

    /**
     * Tenant-scoped shipment lookup az authoritative {@code shipment_request.company_id}
     * oszlopon. A branch-hivatkozások company-konzisztenciáját a service külön ellenőrzi.
     */
    @Query("SELECT sr FROM ShipmentRequest sr WHERE sr.id = :id AND sr.companyId = :companyId")
    Optional<ShipmentRequest> findByIdAndCompanyId(
            @Param("id") UUID id,
            @Param("companyId") UUID companyId);

    /**
     * Tenant-scoped pesszimista sor-zár a shipment státuszváltásokhoz. A company predicate
     * közvetlenül a {@code shipment_request.company_id} oszlopot képviselő entity-mezőre épül.
     * A {@code submit/deliver/cancel/reject} transition-ek ezzel töltik be a kérést — két párhuzamos
     * azonos átmenet közül a második a lock feloldása UTÁN a friss státuszt látja, így nincs
     * kétszeres készlet-könyvelés.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT sr FROM ShipmentRequest sr WHERE sr.id = :id AND sr.companyId = :companyId")
    Optional<ShipmentRequest> findByIdAndCompanyIdForUpdate(
            @Param("id") UUID id,
            @Param("companyId") UUID companyId);

    /**
     * @deprecated multi-tenant unsafe — minden cég összes shipment-jét visszaadja.
     * Használd a {@link #findByStatusAndCompanyId} változatot. v2.5.70 P0 audit fix.
     */
    @Deprecated
    Page<ShipmentRequest> findByStatus(ShipmentRequestStatus status, Pageable pageable);

    /**
     * Fail-closed multi-tenant filter Branch.company FK-on át: mindkét hivatkozott branchnek
     * a paraméterként kapott céghez kell tartoznia.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE sr.status = :status " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findByStatusAndCompanyId(
            @Param("status") ShipmentRequestStatus status,
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * @deprecated multi-tenant unsafe. Használd a {@link #findAllOrderedByCompanyId}-t.
     */
    @Deprecated
    @Query("SELECT sr FROM ShipmentRequest sr ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findAllOrdered(Pageable pageable);

    /**
     * Fail-closed multi-tenant filter Branch.company FK-on át.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findAllOrderedByCompanyId(
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * F2 (2026-06-01): natív, DB-szintű branch-szűrő — a fromBranchId VAGY toBranchId egyezik a
     * megadott branchId-val. Megszünteti a kliens-oldali "összes shipment letöltése + filter"
     * mintát (memóriaszivárgás / silent truncation). Multi-tenant: mindkét végpont a cég
     * branch-ei között kell legyen (azonos izoláció mint findAllOrderedByCompanyId). A status
     * opcionális (null → minden státusz).
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE (sr.fromBranchId = :branchId OR sr.toBranchId = :branchId) " +
           "AND (:status IS NULL OR sr.status = :status) " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findByBranchAndCompanyId(
            @Param("branchId") UUID branchId,
            @Param("status") ShipmentRequestStatus status,
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * Territory-scope-olt listázás (2026-07-15 hardening): mindkét végpont tenant-kötött,
     * és a tétel CSAK akkor látható, ha BÁRMELYIK vége
     * (from VAGY to) a hívó region-scope-jában van. A branchId/status opcionális szűrők a
     * findByBranchAndCompanyId-vel azonos szemantikájúak. Üres branchIds-szel TILOS hívni.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE (sr.fromBranchId IN :branchIds OR sr.toBranchId IN :branchIds) " +
           "AND (:branchId IS NULL OR sr.fromBranchId = :branchId OR sr.toBranchId = :branchId) " +
           "AND (:status IS NULL OR sr.status = :status) " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findScopedByCompanyId(
            @Param("branchIds") Collection<UUID> branchIds,
            @Param("branchId") UUID branchId,
            @Param("status") ShipmentRequestStatus status,
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * FKH-018: a hitelesített célfiók átvehető shipmentjei. Mindkét branch tenant-kötött,
     * így hibás/cross-tenant adatsor sem szivároghat a pending listába.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE sr.toBranchId = :toBranchId " +
           "AND sr.status IN :statuses " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND sr.toBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    List<ShipmentRequest> findPendingForToBranch(
            @Param("companyId") UUID companyId,
            @Param("toBranchId") UUID toBranchId,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(sr.requestNumber, LENGTH(:prefix) + 1) AS integer)), 0) " +
           "FROM ShipmentRequest sr WHERE sr.requestNumber LIKE CONCAT(:prefix, '%')")
    int findMaxRequestNumber(@Param("prefix") String prefix);

    @Query("""
            SELECT DISTINCT sr FROM ShipmentRequest sr
            LEFT JOIN FETCH sr.items
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.requestDate = :date
              AND ((sr.serialPrefix = 'FF' AND sr.fromBranchId = :branchId)
                OR (sr.serialPrefix = 'UF' AND sr.toBranchId = :branchId))
            ORDER BY sr.createdAt ASC, sr.serialNumber ASC
            """)
    List<ShipmentRequest> findHufDaybookShipmentsForDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date);

    /**
     * FKH-030 FR-3/FR-6/FR-7: Penzforgalom riport — shipment-tetelek DATUMTARTOMANYRA es
     * BRANCH-HALMAZRA.
     *
     * <p>A {@code serialPrefix IN ('FF','UF')} szures VALTOZATLANUL atveve a naplokonyvbol,
     * es ez teljesiti az FR-7-et: a KK (kezelesi dij) prefixu shipment-tetelek IGY NEM
     * kerulnek be a riportba (kulon tema: FKH-025). A TBD-1-ben nyitva hagyott
     * {@code SHR}/{@code AV} shipment-prefixek SZANDEKOSAN kimaradnak — a felterkepezes nem
     * tudta megerositeni a jelentesuket, es a fail-closed valasztas az, hogy csak a
     * bizonyitottan penzmozgas jellegu prefixek szerepeljenek.</p>
     */
    @Query("""
            SELECT DISTINCT sr FROM ShipmentRequest sr
            LEFT JOIN FETCH sr.items
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.requestDate BETWEEN :from AND :to
              AND (sr.fromBranchId IN :branchIds OR sr.toBranchId IN :branchIds)
            ORDER BY sr.requestDate ASC, sr.createdAt ASC, sr.serialNumber ASC
            """)
    List<ShipmentRequest> findCashFlowReportShipments(
            @Param("companyId") UUID companyId,
            @Param("branchIds") java.util.Collection<UUID> branchIds,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);

    @Query("""
            SELECT DISTINCT sr FROM ShipmentRequest sr
            LEFT JOIN FETCH sr.items
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.cancelledAt >= :from
              AND sr.cancelledAt < :to
              AND ((sr.serialPrefix = 'FF' AND sr.fromBranchId = :branchId)
                OR (sr.serialPrefix = 'UF' AND sr.toBranchId = :branchId))
            ORDER BY sr.cancelledAt ASC, sr.serialNumber ASC
            """)
    List<ShipmentRequest> findCancelledHufDaybookShipmentsForDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * FKH-022 FR-K5: a naplókönyv Nyitó egyenlegének shipment-oldali, ELŐJELES összege a
     * megadott nap ELŐTTI eredeti bizonylatokból (UF = átvétel +, FF = átadás −).
     * Szűrők a napi lista-lekérdezéssel ({@link #findHufDaybookShipmentsForDate}) azonosak,
     * csak a nap-egyenlőség helyett {@code requestDate < :date} (implicit horgony — nincs
     * dátum-alsókorlát). A null hufValue-jú tételsort a SUM kihagyja (a napi
     * összegzéssel konzisztensen).
     */
    @Query("""
            SELECT COALESCE(SUM(CASE WHEN sr.serialPrefix = 'UF' THEN i.hufValue ELSE -i.hufValue END), 0)
            FROM ShipmentRequest sr JOIN sr.items i
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.requestDate < :date
              AND ((sr.serialPrefix = 'FF' AND sr.fromBranchId = :branchId)
                OR (sr.serialPrefix = 'UF' AND sr.toBranchId = :branchId))
            """)
    BigDecimal sumHufDaybookSignedHufBeforeDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date);

    /**
     * FKH-022 FR-K5: a nap ELŐTTI shipment-SZTORNÓ-események előjeles NETTÓ hatása —
     * az eredetivel ellentétes előjellel (UF-sztornó −, FF-sztornó +), a sztornó-sor
     * nap-hozzárendelése a {@code cancelledAt} (FR-K6/11-gyel konzisztensen).
     */
    @Query("""
            SELECT COALESCE(SUM(CASE WHEN sr.serialPrefix = 'UF' THEN -i.hufValue ELSE i.hufValue END), 0)
            FROM ShipmentRequest sr JOIN sr.items i
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.cancelledAt < :before
              AND ((sr.serialPrefix = 'FF' AND sr.fromBranchId = :branchId)
                OR (sr.serialPrefix = 'UF' AND sr.toBranchId = :branchId))
            """)
    BigDecimal sumCancelledHufDaybookSignedHufBefore(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("before") LocalDateTime before);

    /**
     * FKH-036 FR-1: az aznapi ELKÉSZÍTETT CSOMAGOK előnézeti vetülete (a "Készített
     * csomagok" táblázat forrása).
     *
     * <p>Irány-szabály (terv 9. döntése): KIZÁRÓLAG FF (kimenő) — az UF sor bejövő
     * szállítmány, nem "készített csomag". Tenant: {@code sr.companyId} (invariáns #1).</p>
     *
     * <p>ORDER BY: a {@code serialNumber} NULLABLE (régi/importált sorok), ezért a
     * {@code createdAt} az elsődleges kulcs és a {@code requestNumber} a végső, MINDIG
     * kitöltött tie-breaker — így a lista sorrendje determinisztikus akkor is, ha a
     * {@code serialNumber} null (Postgres default: NULLS LAST ASC).</p>
     */
    @Query("""
            SELECT sr.requestNumber, c.code, i.requestedAmount, sr.sealNumber, b.name
            FROM ShipmentRequest sr
              JOIN sr.items i
              JOIN Currency c ON c.id = i.currencyId
              LEFT JOIN Branch b ON b.id = sr.toBranchId
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix = 'FF'
              AND sr.fromBranchId = :branchId
              AND sr.requestDate = :date
              AND sr.status IN :statuses
            ORDER BY sr.createdAt ASC, sr.serialNumber ASC, sr.requestNumber ASC
            """)
    List<Object[]> findOutgoingPackageRowsForDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);

    /**
     * FKH-036 FR-5: az aznapi FF/UF shipment-MOZGÁS valutakódjai (mintája:
     * {@link #findHufDaybookShipmentsForDate}).
     *
     * <p>Irány-szabály (terv 11. döntése): MINDKÉT irány (FF kimenő + UF bejövő) —
     * bármelyik irányú mozgás megváltoztatja a fizikai készletet, tehát becímletezési
     * kötelezettséget teremt (szemben a csak-FF előnézeti csomaglistával).</p>
     *
     * <p>Üzleti dátum: {@code sr.requestDate} (terv 10. döntése — a kezelési díj
     * lekérdezés UGYANEZT használja, így a kötelező halmaz és a handlingFeeRequired
     * mindig ugyanarra a napra dönt). Státusz-whitelist: fail-closed, a pénztár
     * {@code KPI_COUNTED_STATUSES} konstansát paraméterként kapja (terv 13. döntése:
     * a DRAFT/CANCELLED/REJECTED soha nem mozgatott pénzt, ezért nem teremthet
     * kötelezettséget).</p>
     */
    @Query("""
            SELECT DISTINCT c.code
            FROM ShipmentRequest sr
              JOIN sr.items i
              JOIN Currency c ON c.id = i.currencyId
            WHERE sr.companyId = :companyId
              AND sr.serialPrefix IN ('FF', 'UF')
              AND sr.requestDate = :date
              AND sr.status IN :statuses
              AND ((sr.serialPrefix = 'FF' AND sr.fromBranchId = :branchId)
                OR (sr.serialPrefix = 'UF' AND sr.toBranchId  = :branchId))
            """)
    List<String> findMovedCurrencyCodesForDate(
            @Param("companyId") UUID companyId,
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date,
            @Param("statuses") Collection<ShipmentRequestStatus> statuses);
}
