package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ComplianceSearchTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ComplianceSearchTemplateRepository extends JpaRepository<ComplianceSearchTemplate, UUID> {

    /** Cég-scope-olt egyedi lekérés — cross-tenant IDOR tilos (invariáns #1). */
    Optional<ComplianceSearchTemplate> findByIdAndCompanyId(UUID id, UUID companyId);

    List<ComplianceSearchTemplate> findByCompanyIdOrderByNameAsc(UUID companyId);

    /** Duplikált név pre-check (trimmelt névre); a UNIQUE index a backstop. */
    boolean existsByCompanyIdAndName(UUID companyId, String name);
}
