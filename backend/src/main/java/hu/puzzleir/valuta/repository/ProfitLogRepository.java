package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ProfitLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProfitLogRepository extends JpaRepository<ProfitLog, Long> {

    List<ProfitLog> findByBranchIdAndCreatedAtBetween(UUID branchId, LocalDateTime from, LocalDateTime to);

    List<ProfitLog> findByCompanyIdAndCreatedAtBetween(UUID companyId, LocalDateTime from, LocalDateTime to);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.branchId = :branchId AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByBranch(UUID branchId, LocalDateTime from, LocalDateTime to);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.company.id = :companyId AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByCompany(UUID companyId, LocalDateTime from, LocalDateTime to);

    @Query("SELECT COALESCE(SUM(p.realizedProfit), 0) FROM ProfitLog p " +
           "WHERE p.branchId IN :branchIds AND p.createdAt BETWEEN :from AND :to")
    BigDecimal sumProfitByBranches(List<UUID> branchIds, LocalDateTime from, LocalDateTime to);
}
