package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transfer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransferRepository extends JpaRepository<Transfer, Long> {

    Optional<Transfer> findByTransferNumber(String transferNumber);

    List<Transfer> findByStatus(Transfer.TransferStatus status);

    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findOutgoingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    List<Transfer> findIncomingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT t FROM Transfer t WHERE " +
           "(:branchId IS NULL OR t.fromBranch.id = :branchId OR t.toBranch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transferDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transferDate <= :endDate) " +
           "AND (:status IS NULL OR t.status = :status) " +
           "AND (:type IS NULL OR t.transferType = :type)")
    Page<Transfer> search(
            @Param("branchId") UUID branchId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") Transfer.TransferStatus status,
            @Param("type") Transfer.TransferType type,
            Pageable pageable);

    @Query("SELECT COUNT(t) FROM Transfer t WHERE t.toBranch.id = :branchId AND t.status IN ('PENDING', 'IN_TRANSIT')")
    long countPendingByBranch(@Param("branchId") UUID branchId);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(t.transferNumber, 4) AS long)), 0) FROM Transfer t WHERE t.transferNumber LIKE :prefix%")
    long findMaxTransferNumber(@Param("prefix") String prefix);
}
