package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateMakerSheet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

/**
 * Az árfolyamkészítő munkaív (rate-maker working sheet) repozitóriuma.
 * Cégenként egy aktív munkaív (uq_rate_maker_sheet_company).
 */
public interface RateMakerSheetRepository extends JpaRepository<RateMakerSheet, UUID> {

    Optional<RateMakerSheet> findByCompanyId(UUID companyId);
}
