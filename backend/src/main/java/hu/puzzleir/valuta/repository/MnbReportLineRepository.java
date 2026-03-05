package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MnbReportLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * MNB riport sor repository.
 */
@Repository
public interface MnbReportLineRepository extends JpaRepository<MnbReportLine, UUID> {

    List<MnbReportLine> findByMnbReportId(UUID mnbReportId);
}
