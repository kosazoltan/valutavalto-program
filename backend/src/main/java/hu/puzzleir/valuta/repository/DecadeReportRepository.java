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

    Optional<DecadeReport> findByBranchIdAndYearAndDecade(UUID branchId, int year, int decade);
}
