package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ExchangeRateMaster;
import hu.puzzleir.valuta.entity.ExchangeRateMaster.MasterRateStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Árfolyam törzs repository.
 */
@Repository
public interface ExchangeRateMasterRepository extends JpaRepository<ExchangeRateMaster, UUID> {

    /**
     * Aktuális aktív törzs árfolyamok egy céghez
     */
    @Query("SELECT m FROM ExchangeRateMaster m " +
           "WHERE m.companyId = :companyId " +
           "AND m.isActive = true " +
           "AND m.status = 'PUBLISHED' " +
           "ORDER BY m.validFrom DESC")
    List<ExchangeRateMaster> findActivePublished(@Param("companyId") UUID companyId);

    /**
     * Aktív törzs árfolyam egy valutához
     */
    @Query("SELECT m FROM ExchangeRateMaster m " +
           "WHERE m.companyId = :companyId " +
           "AND m.currencyId = :currencyId " +
           "AND m.isActive = true " +
           "AND m.status = 'PUBLISHED' " +
           "ORDER BY m.validFrom DESC")
    List<ExchangeRateMaster> findActivePublishedByCurrency(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId
    );

    /**
     * Legutolsó aktív törzs árfolyam egy valutához
     */
    default Optional<ExchangeRateMaster> findLatestPublished(UUID companyId, Long currencyId) {
        List<ExchangeRateMaster> rates = findActivePublishedByCurrency(companyId, currencyId);
        return rates.isEmpty() ? Optional.empty() : Optional.of(rates.get(0));
    }

    /**
     * Státusz szerinti lekérdezés
     */
    List<ExchangeRateMaster> findByCompanyIdAndStatusOrderByCreatedAtDesc(
        UUID companyId, MasterRateStatus status
    );

    /**
     * Összes törzs árfolyam (minden státusz)
     */
    @Query("SELECT m FROM ExchangeRateMaster m " +
           "WHERE m.companyId = :companyId " +
           "ORDER BY m.createdAt DESC")
    List<ExchangeRateMaster> findAllByCompany(@Param("companyId") UUID companyId);

    /**
     * Korábbi aktív árfolyamok inaktiválása egy valutához
     */
    @Query("SELECT m FROM ExchangeRateMaster m " +
           "WHERE m.companyId = :companyId " +
           "AND m.currencyId = :currencyId " +
           "AND m.isActive = true " +
           "AND m.id <> :excludeId")
    List<ExchangeRateMaster> findOtherActiveRates(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("excludeId") UUID excludeId
    );
}
