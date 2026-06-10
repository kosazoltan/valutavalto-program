package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.StornoApproval;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Sztornó jóváhagyás repository.
 */
@Repository
public interface StornoApprovalRepository extends JpaRepository<StornoApproval, UUID> {

    /**
     * Pénztáros napi sztornóinak keresése
     */
    @Query("SELECT sa FROM StornoApproval sa " +
           "WHERE sa.worker.id = :workerId " +
           "AND sa.branch.id = :branchId " +
           "AND CAST(sa.createdAt AS localdate) = :date")
    List<StornoApproval> findDailyByWorkerAndBranch(
        @Param("workerId") Long workerId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Adott tranzakcióhoz tartozó jóváhagyások
     */
    @Query("SELECT sa FROM StornoApproval sa WHERE sa.transaction.id = :transactionId")
    List<StornoApproval> findByTransactionId(@Param("transactionId") Long transactionId);

    /**
     * Iroda függő (PENDING) sztornó-jóváhagyási kérései — a supervisor jóváhagyó-listájához.
     * Legrégebbi elöl (FIFO feldolgozás).
     */
    @Query("SELECT sa FROM StornoApproval sa " +
           "WHERE sa.branch.id = :branchId " +
           "AND sa.approvalStatus.code = 'PENDING' " +
           "ORDER BY sa.createdAt ASC")
    List<StornoApproval> findPendingByBranch(@Param("branchId") UUID branchId);
}
