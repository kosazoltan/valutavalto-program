package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MonthlyClosing;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MonthlyClosingRepository extends JpaRepository<MonthlyClosing, UUID> {

    Optional<MonthlyClosing> findByBranchIdAndYearMonth(UUID branchId, String yearMonth);

    List<MonthlyClosing> findByBranchIdOrderByYearMonthDesc(UUID branchId);

    boolean existsByBranchIdAndYearMonth(UUID branchId, String yearMonth);

    List<MonthlyClosing> findByCompanyIdAndClosingYearOrderByClosingMonthDesc(UUID companyId, Integer year);

    List<MonthlyClosing> findByCompanyIdOrderByYearMonthDesc(UUID companyId);
}
