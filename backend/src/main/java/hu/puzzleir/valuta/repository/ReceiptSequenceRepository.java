package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ReceiptSequence;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * ReceiptSequence repository — PESSIMISTIC LOCK a sorszámozás atomicitásáért.
 *
 * Legacy: UTOLSOBLOKKOK tábla — SELECT FOR UPDATE locking.
 */
@Repository
public interface ReceiptSequenceRepository extends JpaRepository<ReceiptSequence, Long> {

    /**
     * Branch szekvencia lekérése PESSIMISTIC WRITE LOCK-kal.
     * Ez garantálja, hogy két párhuzamos tranzakció nem kaphat azonos sorszámot.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT rs FROM ReceiptSequence rs WHERE rs.branchId = :branchId")
    Optional<ReceiptSequence> findByBranchIdForUpdate(@Param("branchId") UUID branchId);

    /**
     * Branch szekvencia lekérése (lock nélkül, lekérdezéshez).
     */
    Optional<ReceiptSequence> findByBranchId(UUID branchId);
}
