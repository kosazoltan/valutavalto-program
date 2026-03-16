package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArchivedMonthlyTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * ArchivedMonthlyTransaction repository.
 *
 * Legacy: NAPZAR.DLL CopyTables — havi gyűjtő táblák lekérdezése.
 */
@Repository
public interface ArchivedMonthlyTransactionRepository extends JpaRepository<ArchivedMonthlyTransaction, Long> {

    /**
     * Adott havi záráshoz tartozó archív tranzakciók.
     */
    List<ArchivedMonthlyTransaction> findByMonthlyClosingId(Long monthlyClosingId);

    /**
     * Adott branch + hónap archív tranzakciói.
     */
    List<ArchivedMonthlyTransaction> findByBranchIdAndYearMonth(UUID branchId, String yearMonth);

    /**
     * Archivált tranzakciók száma egy havi záráshoz.
     */
    long countByMonthlyClosingId(Long monthlyClosingId);

    /**
     * Már archivált-e egy adott branch-hónap kombináció.
     */
    boolean existsByBranchIdAndYearMonth(UUID branchId, String yearMonth);

    /**
     * Branch összes archivált hónapjának listája.
     */
    @Query("SELECT DISTINCT a.yearMonth FROM ArchivedMonthlyTransaction a " +
           "WHERE a.branchId = :branchId " +
           "ORDER BY a.yearMonth DESC")
    List<String> findDistinctYearMonthsByBranchId(@Param("branchId") UUID branchId);
}
