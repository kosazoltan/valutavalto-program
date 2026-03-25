package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HandoverSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface HandoverSheetRepository extends JpaRepository<HandoverSheet, UUID> {
    List<HandoverSheet> findAllByCompanyId(UUID companyId);
}
