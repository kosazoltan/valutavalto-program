package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DariusReportLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DariusReportLineRepository extends JpaRepository<DariusReportLine, UUID> {

    List<DariusReportLine> findByCompanyIdAndReportIdOrderByCurrencyCodeAsc(UUID companyId, UUID reportId);

    void deleteByCompanyIdAndReportId(UUID companyId, UUID reportId);
}
