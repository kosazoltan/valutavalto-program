package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArchivedTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface ArchivedTransactionRepository extends JpaRepository<ArchivedTransaction, Long> {

    /**
     * Egy hónap archivált tranzakcióinak lekérdezése
     */
    List<ArchivedTransaction> findByArchiveMonth(String archiveMonth);

    /**
     * Iroda szerint archivált tranzakciók
     */
    List<ArchivedTransaction> findByBranchIdAndArchiveMonth(UUID branchId, String archiveMonth);

    /**
     * Archivált tranzakciók száma egy hónapban
     */
    @Query("SELECT COUNT(a) FROM ArchivedTransaction a WHERE a.archiveMonth = :month AND a.branchId = :branchId")
    long countByMonthAndBranch(@Param("month") String month, @Param("branchId") UUID branchId);

    /**
     * Eredeti tranzakció ID alapján keresés (ellenőrzés, hogy már archivált-e)
     */
    boolean existsByOriginalId(Long originalId);

    /**
     * Bizonylat szám + archív hónap duplikáció ellenőrzés (napi archiváláshoz).
     */
    boolean existsByReceiptNumberAndArchiveMonth(String receiptNumber, String archiveMonth);

    /**
     * Időszak szerinti lekérdezés
     */
    @Query("SELECT a FROM ArchivedTransaction a WHERE a.originalDate BETWEEN :start AND :end ORDER BY a.originalDate")
    List<ArchivedTransaction> findByDateRange(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
}
