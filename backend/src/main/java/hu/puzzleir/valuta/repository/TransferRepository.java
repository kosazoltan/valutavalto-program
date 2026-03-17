package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transfer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransferRepository extends JpaRepository<Transfer, Long> {

    Optional<Transfer> findByTransferNumber(String transferNumber);

    List<Transfer> findByStatus(Transfer.TransferStatus status);

    @Query("SELECT t FROM Transfer t WHERE " +
           "(t.fromBranch.company.id = :companyId OR t.toBranch.company.id = :companyId) " +
           "AND t.status = :status")
    List<Transfer> findByCompanyAndStatus(@Param("companyId") UUID companyId, @Param("status") Transfer.TransferStatus status);

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

    /** H-3: BejĂ¶vĹ‘ ĂˇtadĂˇsok Ă¶sszege (DailyBalanceService-hez) */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.toBranch.id = :branchId AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED'")
    BigDecimal sumTransfersIn(@Param("branchId") UUID branchId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /** H-3: KimenĹ‘ ĂˇtadĂˇsok Ă¶sszege (DailyBalanceService-hez) */
    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transfer t WHERE t.fromBranch.id = :branchId AND t.transferDate = :date AND t.currency.code = :currencyCode AND t.status = 'COMPLETED'")
    BigDecimal sumTransfersOut(@Param("branchId") UUID branchId, @Param("date") LocalDate date, @Param("currencyCode") String currencyCode);

    /** ReportService â€” kimenĹ‘ ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.fromBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByFromBranchIdOrderByCreatedAtDesc(@Param("branchId") UUID branchId);

    /** ReportService â€” bejĂ¶vĹ‘ ĂˇtadĂˇsok */
    @Query("SELECT t FROM Transfer t WHERE t.toBranch.id = :branchId ORDER BY t.createdAt DESC")
    List<Transfer> findByToBranchIdOrderByCreatedAtDesc(@Param("branchId") UUID branchId);
}
