package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ProfitLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProfitLogRepository extends JpaRepository<ProfitLog, Long> {

    List<ProfitLog> findByBranchIdAndCreatedAtBetween(UUID branchId, LocalDateTime from, LocalDateTime to);

    List<ProfitLog> findByCompanyIdAndCreatedAtBetween(UUID companyId, LocalDateTime from, LocalDateTime to);

    /** A6 (b8 FR-8): egy tranzakció profit-tételei — sztornó/refund-kompenzáció alapja. */
    List<ProfitLog> findByTransactionId(Long transactionId);

    boolean existsByCompensationKey(String compensationKey);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.branchId = :branchId AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByBranch(
            @Param("branchId") UUID branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.company.id = :companyId AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByCompany(
            @Param("companyId") UUID companyId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.branchId IN :branchIds AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByBranches(
            @Param("branchIds") List<UUID> branchIds,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);
}
