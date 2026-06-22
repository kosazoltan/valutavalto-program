package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CompetitorRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CompetitorRateRepository extends JpaRepository<CompetitorRate, UUID> {

    /**
     * @deprecated multi-tenant unsafe — globális query. v2.5.71 P0 companyId audit follow-up.
     * Használd a {@link #findByRateDateAndCompanyId} változatot.
     */
    @Deprecated
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.rateDate = :date " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findByRateDateWithDetails(@Param("date") LocalDate date);

    /**
     * Multi-tenant filter Competitor.branchId → Branch.company.id-n keresztül.
     * v2.5.71 P0 companyId audit fix (defense-in-depth).
     */
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.rateDate = :date " +
           "AND cr.competitor.branchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findByRateDateAndCompanyId(
            @Param("date") LocalDate date,
            @Param("companyId") UUID companyId);

    /**
     * @deprecated multi-tenant unsafe. Használd a {@link #findLatestRatesByCompanyId}-t.
     */
    @Deprecated
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.rateDate = (SELECT MAX(cr2.rateDate) FROM CompetitorRate cr2) " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findLatestRatesWithDetails();

    /**
     * v2.5.71 P0 fix: tenant-aware "legfrissebb" query.
     * A MAX(rateDate) subquery is company-scope-olva (csak a saját cég competitor-ai).
     */
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.competitor.branchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND cr.rateDate = (SELECT MAX(cr2.rateDate) FROM CompetitorRate cr2 " +
           "                   WHERE cr2.competitor.branchId IN (SELECT b2.id FROM Branch b2 WHERE b2.company.id = :companyId)) " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findLatestRatesByCompanyId(@Param("companyId") UUID companyId);

    /**
     * @deprecated multi-tenant unsafe. Használd a {@link #findLatestRatesByCurrencyIdAndCompanyId}-t.
     */
    @Deprecated
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.currency.id = :currencyId " +
           "AND cr.rateDate = (SELECT MAX(cr2.rateDate) FROM CompetitorRate cr2 WHERE cr2.currency.id = :currencyId) " +
           "ORDER BY cr.competitor.name")
    List<CompetitorRate> findLatestRatesByCurrencyId(@Param("currencyId") Long currencyId);

    /**
     * v2.5.71 P0 fix: tenant-aware legfrissebb-valuta-specifikus query.
     */
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.currency.id = :currencyId " +
           "AND cr.competitor.branchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND cr.rateDate = (SELECT MAX(cr2.rateDate) FROM CompetitorRate cr2 " +
           "                   WHERE cr2.currency.id = :currencyId " +
           "                     AND cr2.competitor.branchId IN (SELECT b2.id FROM Branch b2 WHERE b2.company.id = :companyId)) " +
           "ORDER BY cr.competitor.name")
    List<CompetitorRate> findLatestRatesByCurrencyIdAndCompanyId(
            @Param("currencyId") Long currencyId,
            @Param("companyId") UUID companyId);

    /**
     * FK-041/II upsert-kulcs: egy versenyhely adott valutára MAI (rateDate) legutóbb rögzített sora.
     * A táblán nincs unique constraint (competitor, currency, date) szinten, ezért a service-szintű
     * upsert a legutóbbit (createdAt DESC) frissíti, hogy ne keletkezzen duplikált mai sor.
     * A hívó hatókör-ellenőrzése (régió + companyId) a service-ben történik, mielőtt ide hív.
     */
    Optional<CompetitorRate> findFirstByCompetitorIdAndCurrencyIdAndRateDateOrderByCreatedAtDesc(
            UUID competitorId, Long currencyId, LocalDate rateDate);

    /**
     * FK-041/II: egy versenyhely MAI bevitt versenytárs-árfolyamai (előtöltéshez). A currency JOIN FETCH
     * az OSIV-off miatt; valutánként a legfrissebb (createdAt DESC) a mérvadó (a service dedup-ol).
     */
    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.competitor.id = :competitorId AND cr.rateDate = :rateDate " +
           "ORDER BY cr.currency.displayOrder, cr.createdAt DESC")
    List<CompetitorRate> findTodayByCompetitor(
            @Param("competitorId") UUID competitorId,
            @Param("rateDate") LocalDate rateDate);
}
