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

import java.util.Collection;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShipmentRequestRepository extends JpaRepository<ShipmentRequest, UUID> {

    /**
     * P1 (Codex review, PR #1243): pesszimista sor-zár a shipment-re a státuszváltások előtt.
     * A {@code submit/deliver/cancel/reject} transition-ek ezzel töltik be a kérést — két párhuzamos
     * azonos átmenet (pl. dupla-klikk vagy retry) közül a második a lock feloldása UTÁN a FRISS
     * státuszt látja, így a {@code validateStatusTransition} elutasítja, és nincs kétszeres
     * készlet-könyvelés (a {@code bookStockOut} stock-lockja önmagában csak a stock-sort védi, a
     * shipment-állapotot nem).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT sr FROM ShipmentRequest sr WHERE sr.id = :id")
    Optional<ShipmentRequest> findByIdForUpdate(@Param("id") UUID id);

    /**
     * @deprecated multi-tenant unsafe — minden cég összes shipment-jét visszaadja.
     * Használd a {@link #findByStatusAndCompanyId} változatot. v2.5.70 P0 audit fix.
     */
    @Deprecated
    Page<ShipmentRequest> findByStatus(ShipmentRequestStatus status, Pageable pageable);

    /**
     * Multi-tenant filter Branch.company FK-on át — v2.5.70 P0 companyId audit fix.
     * A fromBranchId vagy toBranchId által hivatkozott Branch.company.id egyezik a paraméterrel.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE sr.status = :status " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
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
     * Multi-tenant filter Branch.company FK-on át — v2.5.70 P0 companyId audit fix.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findAllOrderedByCompanyId(
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * F2 (2026-06-01): natív, DB-szintű branch-szűrő — a fromBranchId VAGY toBranchId egyezik a
     * megadott branchId-val. Megszünteti a kliens-oldali "összes shipment letöltése + filter"
     * mintát (memóriaszivárgás / silent truncation). Multi-tenant: a fromBranchId a cég
     * branch-ei között kell legyen (azonos izoláció mint findAllOrderedByCompanyId). A status
     * opcionális (null → minden státusz).
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE (sr.fromBranchId = :branchId OR sr.toBranchId = :branchId) " +
           "AND (:status IS NULL OR sr.status = :status) " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findByBranchAndCompanyId(
            @Param("branchId") UUID branchId,
            @Param("status") ShipmentRequestStatus status,
            @Param("companyId") UUID companyId,
            Pageable pageable);

    /**
     * Territory-scope-olt listázás (2026-07-15 hardening): a meglévő tenant-klauzula
     * (fromBranchId a cég branch-ei közt) + a tétel CSAK akkor látható, ha BÁRMELYIK vége
     * (from VAGY to) a hívó region-scope-jában van. A branchId/status opcionális szűrők a
     * findByBranchAndCompanyId-vel azonos szemantikájúak. Üres branchIds-szel TILOS hívni.
     */
    @Query("SELECT sr FROM ShipmentRequest sr " +
           "WHERE (sr.fromBranchId IN :branchIds OR sr.toBranchId IN :branchIds) " +
           "AND (:branchId IS NULL OR sr.fromBranchId = :branchId OR sr.toBranchId = :branchId) " +
           "AND (:status IS NULL OR sr.status = :status) " +
           "AND sr.fromBranchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY sr.createdAt DESC")
    Page<ShipmentRequest> findScopedByCompanyId(
            @Param("branchIds") Collection<UUID> branchIds,
            @Param("branchId") UUID branchId,
            @Param("status") ShipmentRequestStatus status,
            @Param("companyId") UUID companyId,
            Pageable pageable);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(sr.requestNumber, LENGTH(:prefix) + 1) AS integer)), 0) " +
           "FROM ShipmentRequest sr WHERE sr.requestNumber LIKE CONCAT(:prefix, '%')")
    int findMaxRequestNumber(@Param("prefix") String prefix);
}
