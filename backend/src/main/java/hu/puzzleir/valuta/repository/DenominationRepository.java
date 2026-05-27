package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Denomination;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Denomination repository.
 */
@Repository
public interface DenominationRepository extends JpaRepository<Denomination, Long> {

    /**
     * Címlet keresése fiók, valuta és névérték alapján
     */
    Optional<Denomination> findByBranchIdAndCurrencyIdAndFaceValue(
        UUID branchId, Long currencyId, BigDecimal faceValue
    );

    /**
     * Összes címlet egy fiókhoz és valutához
     */
    @Query("SELECT d FROM Denomination d " +
           "LEFT JOIN FETCH d.branch " +
           "LEFT JOIN FETCH d.currency " +
           "WHERE d.branch.id = :branchId " +
           "AND d.currency.id = :currencyId " +
           "AND d.active = true " +
           "ORDER BY d.faceValue DESC")
    List<Denomination> findByBranchAndCurrency(
        @Param("branchId") UUID branchId,
        @Param("currencyId") Long currencyId
    );

    /**
     * Összes címlet egy fiókhoz és valutához — company-scope-pal (multi-tenant
     * defense-in-depth). A controller @PreAuthorize + a branch.company FK már izolál,
     * de a kanonikus elv szerint a tenant-szűrés a repository-rétegen is jelen van,
     * hogy egy más cégbe tartozó branchId/currencyId ne adjon vissza adatot.
     */
    @Query("SELECT d FROM Denomination d " +
           "LEFT JOIN FETCH d.branch " +
           "LEFT JOIN FETCH d.currency " +
           "WHERE d.branch.id = :branchId " +
           "AND d.currency.id = :currencyId " +
           "AND d.company.id = :companyId " +
           "AND d.active = true " +
           "ORDER BY d.faceValue DESC")
    List<Denomination> findByBranchAndCurrencyAndCompanyId(
        @Param("branchId") UUID branchId,
        @Param("currencyId") Long currencyId,
        @Param("companyId") UUID companyId
    );

    /**
     * Összes címlet egy fiókhoz
     */
    @Query("SELECT d FROM Denomination d " +
           "LEFT JOIN FETCH d.branch " +
           "LEFT JOIN FETCH d.currency " +
           "WHERE d.branch.id = :branchId " +
           "AND d.active = true " +
           "ORDER BY d.currency.displayOrder, d.faceValue DESC")
    List<Denomination> findByBranchId(@Param("branchId") UUID branchId);

    /**
     * Alacsony készletű címletek.
     *
     * #870 (élő-API teszt, HIBA #10): LEFT JOIN FETCH branch+currency — a
     * DenominationController.getLowStockAlerts a session lezárása UTÁN (OSIV=false) mappel
     * DTO-ra (DenominationMapper a branch.getName()/currency.getCode()-ot olvassa), ezért a
     * lazy proxyknak betöltve kell lenniük, különben LazyInitializationException → HTTP 500.
     * A testvér-finderek (findByBranchAndCurrency/findByBranchId) már JOIN FETCH-elnek.
     */
    @Query("SELECT d FROM Denomination d " +
           "LEFT JOIN FETCH d.branch " +
           "LEFT JOIN FETCH d.currency " +
           "WHERE d.company.id = :companyId " +
           "AND d.quantity <= d.minQuantity " +
           "AND d.minQuantity IS NOT NULL " +
           "AND d.active = true")
    List<Denomination> findLowStock(@Param("companyId") UUID companyId);

    /**
     * Aktiv cimletek valuta kod alapjan (cimlet kalkulator)
     */
    @Query("SELECT d FROM Denomination d " +
           "WHERE d.currency.code = :currencyCode " +
           "AND d.company.id = :companyId " +
           "AND d.active = true " +
           "ORDER BY d.faceValue DESC")
    List<Denomination> findByCompanyIdAndCurrencyCode(
        @Param("companyId") UUID companyId,
        @Param("currencyCode") String currencyCode
    );
}
