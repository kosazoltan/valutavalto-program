package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AnonymousReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AnonymousReportRepository extends JpaRepository<AnonymousReport, UUID> {
    List<AnonymousReport> findAllByCompanyId(UUID companyId);
}
