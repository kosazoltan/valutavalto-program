package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ComplianceQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ComplianceQuestionRepository extends JpaRepository<ComplianceQuestion, UUID> {

    /** Cég-scope-olt egyedi lekérés — cross-tenant IDOR tilos (invariáns #1). */
    Optional<ComplianceQuestion> findByIdAndCompanyId(UUID id, UUID companyId);

    /** Compliance-nézet: minden kérdés (inaktív is), sorrendben. */
    List<ComplianceQuestion> findByCompanyIdOrderByDisplayOrderAscCreatedAtAsc(UUID companyId);

    /** Pénztár-sync: csak aktív kérdések, sorrendben. */
    List<ComplianceQuestion> findByCompanyIdAndActiveTrueOrderByDisplayOrderAscCreatedAtAsc(UUID companyId);
}
