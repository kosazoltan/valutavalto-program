package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Currency;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Currency repository.
 */
@Repository
public interface CurrencyRepository extends JpaRepository<Currency, Long> {

    /**
     * Keresés kód alapján (pl. EUR, USD)
     */
    Optional<Currency> findByCode(String code);

    /**
     * Kód létezik-e
     */
    boolean existsByCode(String code);

    /**
     * Aktív valuták
     */
    List<Currency> findByActiveTrueOrderByDisplayOrderAsc();

    /**
     * Összes valuta megjelenítési sorrendben
     */
    List<Currency> findAllByOrderByDisplayOrderAsc();

    /**
     * Keresés név vagy kód alapján
     */
    @Query("SELECT c FROM Currency c WHERE LOWER(c.code) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(c.name) LIKE LOWER(CONCAT('%', :search, '%'))")
    List<Currency> searchByCodeOrName(@Param("search") String search);

    /**
     * FK04 (FR-7): display_order foglaltság-ellenőrzés — a V318 UNIQUE constraint
     * service-szintű előszűrése, hogy 500 (constraint violation) helyett beszédes
     * 409 + VV-VALID-003 választ adjunk.
     */
    boolean existsByDisplayOrder(Integer displayOrder);

    /**
     * FK04: a legnagyobb foglalt display_order (üres táblánál 0) — az új valuta
     * alapértelmezett sorrendje max+1 (a korábbi fix 99 default a UNIQUE constraint
     * mellett a második sorrend-nélküli felvételnél ütközne).
     */
    @Query("SELECT COALESCE(MAX(c.displayOrder), 0) FROM Currency c")
    int findMaxDisplayOrder();

    /**
     * Összes aktív valuta rendezve (alias)
     */
    default List<Currency> findAllActiveOrdered() {
        return findByActiveTrueOrderByDisplayOrderAsc();
    }

    /**
     * Aktív valuták company szerint (multi-tenant kompatibilis)
     * Ha nincs company-hoz kötve a Currency, visszaadja az összes aktívat.
     */
    @Query("SELECT c FROM Currency c WHERE c.active = true " +
           "ORDER BY c.displayOrder ASC")
    List<Currency> findActiveByCompany(java.util.UUID companyId);
}
