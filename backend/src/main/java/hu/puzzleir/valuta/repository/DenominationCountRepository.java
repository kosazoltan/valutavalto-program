package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationCount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface DenominationCountRepository extends JpaRepository<DenominationCount, UUID> {

    List<DenominationCount> findBySessionIdOrderByFaceValueDesc(UUID sessionId);

    List<DenominationCount> findByBranchIdAndCountTypeOrderByCreatedAtDesc(UUID branchId, String countType);

    /**
     * Ellenőrzi, hány "nem kész" címletezés van az adott napon és típusra.
     * Legacy: NAPZAR validáció — minden kasszatípus címletezése kell.
     *
     * @param branchId iroda
     * @param date nap
     * @param typeCode kasszatípus kód (1=valuta, 2=kezelési díj, 3=WU, 4=ÁFA)
     * @return nem kész rekordok száma (0 = OK)
     */
    @Query(value = "SELECT COUNT(*) FROM denomination_count dc " +
           "WHERE dc.branch_id = :branchId " +
           "AND CAST(dc.created_at AS DATE) = :date " +
           "AND dc.count_type = CAST(:typeCode AS VARCHAR) " +
           "AND dc.quantity = 0", nativeQuery = true)
    long countNotReady(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("typeCode") int typeCode);

    // ============ KATEGÓRIA ALAPÚ LEKÉRDEZÉSEK ============

    /**
     * Adott iroda, dátum és kategória szerint meglévő címletezések.
     */
    @Query("SELECT dc FROM DenominationCount dc " +
           "WHERE dc.branchId = :branchId " +
           "AND CAST(dc.createdAt AS localdate) = :date " +
           "AND dc.denominationCategory = :category " +
           "ORDER BY dc.currencyCode, dc.faceValue DESC")
    List<DenominationCount> findByBranchIdAndDateAndCategory(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * Létezik-e címletezés adott irodára, dátumra és kategóriára?
     */
    @Query("SELECT COUNT(dc) > 0 FROM DenominationCount dc " +
           "WHERE dc.branchId = :branchId " +
           "AND CAST(dc.createdAt AS localdate) = :date " +
           "AND dc.denominationCategory = :category")
    boolean existsByBranchIdAndDateAndCategory(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * Címletezett összeg kategória szerint.
     */
    @Query("SELECT COALESCE(SUM(dc.faceValue * dc.quantity), 0) FROM DenominationCount dc " +
           "WHERE dc.branchId = :branchId " +
           "AND CAST(dc.createdAt AS localdate) = :date " +
           "AND dc.denominationCategory = :category")
    BigDecimal sumDenominatedAmountByCategory(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("category") DenominationCategory category
    );

    /**
     * Adott iroda és dátum összes címletezési kategóriája.
     */
    @Query("SELECT DISTINCT dc.denominationCategory FROM DenominationCount dc " +
           "WHERE dc.branchId = :branchId " +
           "AND CAST(dc.createdAt AS localdate) = :date")
    List<DenominationCategory> findDistinctCategoriesByBranchIdAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );
}
