package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ExchangeRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * ExchangeRate repository.
 */
@Repository
public interface ExchangeRateRepository extends JpaRepository<ExchangeRate, Long> {

    /**
     * Aktuális árfolyam egy valutához (legutolsó aktív)
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "JOIN FETCH er.currency " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.active = true " +
           "AND (er.branch.id = :branchId OR er.branch IS NULL) " +
           "ORDER BY er.validDate DESC, er.validTime DESC")
    List<ExchangeRate> findCurrentRate(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("branchId") UUID branchId
    );

    /**
     * Összes aktív árfolyam egy céghez
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "JOIN FETCH er.currency " +
           "WHERE er.company.id = :companyId " +
           "AND er.active = true " +
           "AND er.validDate = :date " +
           "ORDER BY er.currency.displayOrder")
    List<ExchangeRate> findActiveRatesByDate(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date
    );

    /**
     * Árfolyam adott időpontra
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "JOIN FETCH er.currency " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.validDate = :date " +
           "AND er.validTime <= :time " +
           "ORDER BY er.validTime DESC")
    List<ExchangeRate> findRateAtTime(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("date") LocalDate date,
        @Param("time") LocalTime time
    );

    /**
     * Árfolyam történet egy valutához
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "JOIN FETCH er.currency " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.validDate BETWEEN :startDate AND :endDate " +
           "ORDER BY er.validDate DESC, er.validTime DESC")
    List<ExchangeRate> findRateHistory(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Összes aktív árfolyam dátumtól függetlenül (legfrissebb előre),
     * fiók-specifikus vagy globális
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "JOIN FETCH er.currency " +
           "WHERE er.company.id = :companyId " +
           "AND er.active = true " +
           "AND (er.branch.id = :branchId OR er.branch IS NULL) " +
           "ORDER BY er.currency.displayOrder, er.validDate DESC, er.validTime DESC")
    List<ExchangeRate> findAllActiveRates(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId
    );

    /**
     * Legutolsó árfolyam egy valutához
     */
    default Optional<ExchangeRate> findLatestRate(UUID companyId, Long currencyId, UUID branchId) {
        List<ExchangeRate> rates = findCurrentRate(companyId, currencyId, branchId);
        return rates.isEmpty() ? Optional.empty() : Optional.of(rates.get(0));
    }

    /**
     * Aktív árfolyamok egy valutához adott napon — ÖSSZES cég (rendszerszintű, MNB polling).
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.currency.id = :currencyId " +
           "AND er.active = true " +
           "AND er.validDate = :date")
    List<ExchangeRate> findActiveByCurrencyAndDate(
        @Param("currencyId") Long currencyId,
        @Param("date") LocalDate date
    );

    /**
     * Aktív árfolyamok egy valutához adott napon — multi-tenant szűréssel.
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.active = true " +
           "AND er.validDate = :date")
    List<ExchangeRate> findActiveByCurrencyAndDateForCompany(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("date") LocalDate date
    );

    /**
     * Aktív árfolyamok adott napon egy branch-hez (vagy branch IS NULL).
     * Branch implicit company szűrést biztosít.
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.active = true " +
           "AND er.validDate = :date " +
           "AND (er.branch IS NULL OR er.branch.id = :branchId)")
    List<ExchangeRate> findActiveByDateAndBranch(
        @Param("date") LocalDate date,
        @Param("branchId") UUID branchId
    );

    /**
     * Legutolsó aktív árfolyamok egy céghez — FALLBACK ha az adott napra nincs adat.
     * Az utolsó elérhető nap adatait adja vissza (DISTINCT ON currency_id).
     *
     * PostgreSQL-specifikus: DISTINCT ON + ORDER BY a legfrissebb per-valuta rekord kiválasztásához.
     */
    @Query(value = "SELECT DISTINCT ON (er.currency_id) er.* FROM exchange_rate er " +
           "WHERE er.company_id = :companyId " +
           "AND er.active = true " +
           "ORDER BY er.currency_id, er.valid_date DESC, er.valid_time DESC",
           nativeQuery = true)
    List<ExchangeRate> findLatestActiveRates(@Param("companyId") UUID companyId);

    /**
     * Legfrissebb közép-árfolyam — company-specific.
     */
    @Query(value = "SELECT (er.base_buy_rate + er.base_sell_rate) / 2 FROM exchange_rate er " +
           "WHERE er.company_id = :companyId " +
           "AND er.currency_id = (SELECT c.id FROM currency c WHERE c.code = :code) " +
           "AND er.active = true " +
           "ORDER BY er.valid_date DESC, er.valid_time DESC LIMIT 1",
           nativeQuery = true)
    Optional<BigDecimal> findLatestMidRateByCompanyAndCode(
        @Param("companyId") UUID companyId,
        @Param("code") String code
    );

    /**
     * Legfrissebb közép-árfolyam — global (company-független).
     */
    @Query(value = "SELECT (er.base_buy_rate + er.base_sell_rate) / 2 FROM exchange_rate er " +
           "WHERE er.currency_id = (SELECT c.id FROM currency c WHERE c.code = :code) " +
           "AND er.active = true " +
           "ORDER BY er.valid_date DESC, er.valid_time DESC LIMIT 1",
           nativeQuery = true)
    Optional<BigDecimal> findLatestMidRateByCodeGlobal(@Param("code") String code);

    /**
     * Legfrissebb közép-árfolyam — nullable companyId wrapper (index-barát).
     */
    default Optional<BigDecimal> findLatestMidRateByCurrencyCode(UUID companyId, String code) {
        return companyId != null
                ? findLatestMidRateByCompanyAndCode(companyId, code)
                : findLatestMidRateByCodeGlobal(code);
    }
}
