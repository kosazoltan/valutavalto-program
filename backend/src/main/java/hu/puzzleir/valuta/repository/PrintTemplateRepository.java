package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.PrintTemplate;
import hu.puzzleir.valuta.entity.PrintTemplateType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PrintTemplateRepository extends JpaRepository<PrintTemplate, UUID> {

    List<PrintTemplate> findByTemplateType(PrintTemplateType templateType);

    Optional<PrintTemplate> findByTemplateTypeAndCompanyId(PrintTemplateType templateType, Integer companyId);

    List<PrintTemplate> findByIsDefaultTrue();

    Optional<PrintTemplate> findByTemplateTypeAndIsDefaultTrue(PrintTemplateType templateType);

    List<PrintTemplate> findByCompanyId(Integer companyId);
}
