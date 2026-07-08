package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ComplianceSearchAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ComplianceSearchAuditRepository extends JpaRepository<ComplianceSearchAudit, UUID> {

    /** Cég-scope-olt egyedi lekérés — cross-tenant IDOR tilos (invariáns #1). */
    Optional<ComplianceSearchAudit> findByIdAndCompanyId(UUID id, UUID companyId);

    List<ComplianceSearchAudit> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
}
