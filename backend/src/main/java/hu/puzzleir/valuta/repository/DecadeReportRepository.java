package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DecadeReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface DecadeReportRepository extends JpaRepository<DecadeReport, UUID> {

    Page<DecadeReport> findByBranchIdAndYear(UUID branchId, int year, Pageable pageable);

    /**
     * Multi-tenant-safe lista: a dekádjelentések csak a hívó cégének irodájára szólnak
     * (IDOR FINDING #5). A {@link #findByBranchIdAndYear(UUID, int, Pageable)} company-scope
     * nélkül idegen cég irodájának jelentéseit is visszaadta.
     */
    Page<DecadeReport> findByBranchIdAndYearAndBranchCompanyId(
        UUID branchId, int year, UUID companyId, Pageable pageable);

    Optional<DecadeReport> findByBranchIdAndYearAndDecade(UUID branchId, int year, int decade);
}
