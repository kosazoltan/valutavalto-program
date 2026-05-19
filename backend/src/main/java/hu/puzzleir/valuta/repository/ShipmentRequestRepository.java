package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ShipmentRequestRepository extends JpaRepository<ShipmentRequest, UUID> {

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

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(sr.requestNumber, LENGTH(:prefix) + 1) AS integer)), 0) " +
           "FROM ShipmentRequest sr WHERE sr.requestNumber LIKE CONCAT(:prefix, '%')")
    int findMaxRequestNumber(@Param("prefix") String prefix);
}
