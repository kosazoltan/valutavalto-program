package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import hu.puzzleir.valuta.entity.DenominationCategory;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Pénztárgép címlet egyenleg repository.
 */
@Repository
public interface DenominationBalanceRepository extends JpaRepository<DenominationBalance, UUID> {

    /**
     * Pénztárgép összes címlet egyenlege
     */
    List<DenominationBalance> findByCashDeskId(UUID cashDeskId);

    /**
     * Pénztárgép adott valutájú címletei
     */
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :cashDeskId " +
           "AND db.denomination.currency.id = :currencyId")
    List<DenominationBalance> findByCashDeskIdAndCurrencyId(
        @Param("cashDeskId") UUID cashDeskId,
        @Param("currencyId") Long currencyId
    );

    /**
     * FK-078 (FR-3) / FKH-033: kategória-tudatos egyedi rekord — pénztár + címlet + kategória.
     *
     * <p>Ez az EGYETLEN megengedett upsert-lookup a {@code denomination_balance} táblára.
     * A korábbi, kategória-mentes párja ({@code findByCashDeskIdAndDenominationId}) az ELSŐ
     * találatot adta vissza kategóriától függetlenül, ezért egy {@code HANDLING_FEE} mentés
     * felülírhatta az {@code EVENING} sort — illetve új sort próbált beszúrni, amit a V75-ös
     * kategória-mentes egyedi kulcs elutasított (500 a napi zárásban). A V378 óta a DB-kulcs
     * is {@code (cash_desk_id, denomination_id, denomination_category)}; a kategória-mentes
     * metódus SZÁNDÉKOSAN nem létezik, hogy ne lehessen visszacsúszni a hibás mintába.</p>
     */
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :cashDeskId " +
           "AND db.denomination.id = :denominationId " +
           "AND db.denominationCategory = :category")
    Optional<DenominationBalance> findByCashDeskIdAndDenominationIdAndCategory(
        @Param("cashDeskId") UUID cashDeskId,
        @Param("denominationId") Long denominationId,
        @Param("category") DenominationCategory category
    );

    /**
     * Pénztárgép adott valutájú címletek teljes értékének összege
     */
    @Query("SELECT COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :cashDeskId " +
           "AND db.denomination.currency.id = :currencyId")
    BigDecimal sumTotalValueByCashDeskIdAndCurrencyId(
        @Param("cashDeskId") UUID cashDeskId,
        @Param("currencyId") Long currencyId
    );

    // ============ NAPZARAS QUERY-K ============


    /**
     * Van-e adott kategóriájú cimletez es?
     * A DailyClosingService String-ként adja át a kategóriát (pl. "HANDLING_FEE", "WESTERN_UNION").
     */
    @Query("SELECT COUNT(db) > 0 FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.updatedAt >= CAST(:date AS timestamp) " +
           "AND CAST(db.denominationCategory AS string) = :type")
    boolean existsByBranchIdAndDateAndType(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("type") String type
    );

    /**
     * Van-e adott kategóriájú cimletez es? (enum típusú paraméterrel)
     */
    @Query("SELECT COUNT(db) > 0 FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND db.denominationCategory = :category")
    boolean existsByBranchIdAndDateAndCategory(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * Cimletezett osszeg a napzarashoz (String kategória — backwards compatible).
     */
    @Query("SELECT COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND CAST(db.denominationCategory AS string) = :type")
    BigDecimal sumDenominatedAmount(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("type") String type
    );

    /**
     * Cimletezett osszeg a napzarashoz (enum kategória).
     */
    @Query("SELECT COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND db.denominationCategory = :category")
    BigDecimal sumDenominatedAmountByCategory(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * Adott iroda/pénztárgép adott üzleti napra beküldött cimlet egyenlegei az esti záráshoz.
     */
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND db.quantity > 0")
    List<DenominationBalance> findByBranchIdAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date
    );

    /**
     * Adott iroda aznapi adott kategóriájú cimlet egyenlegei.
     */
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND db.denominationCategory = :category " +
           "AND db.quantity > 0")
    List<DenominationBalance> findByBranchIdAndDateAndCategory(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * FK-046 FR-2: a záráskori (EVENING) fizikailag leszámolt készlet (SZÁMZÁR) valutakódonként
     * összesítve — egy branch + egy nap. A címletenkénti {@code totalValue} sorokat a valuta kódja
     * szerint csoportosítja, így a kliens metódus valutánként megkapja a leszámolt záró készletet.
     * A pontos üzleti dátum szűrés miatt a következő napi snapshot NEM szivárog be.
     * Visszaad: [currencyCode, SUM(totalValue)] sorok.
     */
    @Query("SELECT db.denomination.currency.code, COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.submissionDate = :date " +
           "AND db.denominationCategory = :category " +
           "GROUP BY db.denomination.currency.code")
    List<Object[]> sumActualStockByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("category") DenominationCategory category
    );
}
