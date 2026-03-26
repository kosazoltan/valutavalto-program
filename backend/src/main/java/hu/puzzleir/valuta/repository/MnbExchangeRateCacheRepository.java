package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * MNB árfolyam cache repository.
 */
@Repository
public interface MnbExchangeRateCacheRepository extends JpaRepository<MnbExchangeRateCache, Long> {

    /**
     * Adott dátumra és valutára cache-elt árfolyam.
     */
    Optional<MnbExchangeRateCache> findByCurrencyCodeAndRateDate(String currencyCode, LocalDate rateDate);

    /**
     * Adott dátumra, valutára és forrásra cache-elt árfolyam.
     * Használandó ha MNB és RAIFFEISEN is írhat azonos dátumra.
     */
    Optional<MnbExchangeRateCache> findByCurrencyCodeAndRateDateAndSource(String currencyCode, LocalDate rateDate, String source);

    /**
     * Adott dátum összes cache-elt árfolyama.
     */
    List<MnbExchangeRateCache> findByRateDate(LocalDate rateDate);

    /**
     * Létezik-e cache az adott dátumra (bármely valutára).
     */
    boolean existsByRateDate(LocalDate rateDate);

    /**
     * Utolsó elérhető árfolyam keresése egy valutához (fallback).
     * Ha az adott napra nincs, a legutolsó cache-elt értéket adja vissza.
     */
    @Query("SELECT m FROM MnbExchangeRateCache m " +
            "WHERE m.currencyCode = :currencyCode AND m.rateDate <= :date " +
            "ORDER BY m.rateDate DESC LIMIT 1")
    Optional<MnbExchangeRateCache> findLatestByCurrencyCode(
            @Param("currencyCode") String currencyCode,
            @Param("date") LocalDate date);

    /**
     * Adott dátumtól visszamenőleg legutolsó cache-elt nap összes árfolyama
     * (fallback).
     */
    @Query("SELECT m FROM MnbExchangeRateCache m " +
            "WHERE m.rateDate = (SELECT MAX(m2.rateDate) FROM MnbExchangeRateCache m2 WHERE m2.rateDate <= :date)")
    List<MnbExchangeRateCache> findLatestRates(@Param("date") LocalDate date);

    // ============ SOURCE-SZŰRT LEKÉRDEZÉSEK (Raiffeisen integráció) ============

    /**
     * Adott dátum cache-elt árfolyamai forrás szerint szűrve.
     */
    @Query("SELECT m FROM MnbExchangeRateCache m " +
            "WHERE m.rateDate = :date AND m.source = :source")
    List<MnbExchangeRateCache> findByRateDateAndSource(
            @Param("date") LocalDate date,
            @Param("source") String source);

    /**
     * Legutolsó elérhető árfolyamok forrás szerint szűrve (fallback).
     */
    @Query("SELECT m FROM MnbExchangeRateCache m " +
            "WHERE m.source = :source " +
            "AND m.rateDate = (SELECT MAX(m2.rateDate) FROM MnbExchangeRateCache m2 " +
            "WHERE m2.source = :source AND m2.rateDate <= :date)")
    List<MnbExchangeRateCache> findLatestRatesBySource(
            @Param("date") LocalDate date,
            @Param("source") String source);
}
