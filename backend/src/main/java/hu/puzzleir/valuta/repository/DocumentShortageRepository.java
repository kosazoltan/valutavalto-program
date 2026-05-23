package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DocumentShortage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DocumentShortageRepository extends JpaRepository<DocumentShortage, UUID> {

    List<DocumentShortage> findByCompanyIdOrderByRecordedAtDesc(UUID companyId);

    List<DocumentShortage> findByCompanyIdAndResolvedAtIsNullOrderByRecordedAtDesc(UUID companyId);
}
