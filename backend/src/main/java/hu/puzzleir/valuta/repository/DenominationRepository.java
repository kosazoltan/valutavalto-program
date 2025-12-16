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
           "WHERE d.branch.id = :branchId " +
           "AND d.currency.id = :currencyId " +
           "AND d.active = true " +
           "ORDER BY d.faceValue DESC")
    List<Denomination> findByBranchAndCurrency(
        @Param("branchId") UUID branchId,
        @Param("currencyId") Long currencyId
    );

    /**
     * Összes címlet egy fiókhoz
     */
    @Query("SELECT d FROM Denomination d " +
           "WHERE d.branch.id = :branchId " +
           "AND d.active = true " +
           "ORDER BY d.currency.displayOrder, d.faceValue DESC")
    List<Denomination> findByBranchId(@Param("branchId") UUID branchId);

    /**
     * Alacsony készletű címletek
     */
    @Query("SELECT d FROM Denomination d " +
           "WHERE d.company.id = :companyId " +
           "AND d.quantity <= d.minQuantity " +
           "AND d.minQuantity IS NOT NULL " +
           "AND d.active = true")
    List<Denomination> findLowStock(@Param("companyId") UUID companyId);
}
