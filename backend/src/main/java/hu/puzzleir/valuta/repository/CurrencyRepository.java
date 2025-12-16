package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Currency;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
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
    List<Currency> searchByCodeOrName(String search);
}
