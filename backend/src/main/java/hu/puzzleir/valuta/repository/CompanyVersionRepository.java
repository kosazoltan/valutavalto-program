package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CompanyVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CompanyVersionRepository extends JpaRepository<CompanyVersion, Long> {

    Optional<CompanyVersion> findTopByCompanyIdOrderByVersionNoDesc(UUID companyId);

    /** MULTI-TENANT: companyId-szűrt (invariáns #1). */
    List<CompanyVersion> findByCompanyIdOrderByVersionNoDesc(UUID companyId);

    Optional<CompanyVersion> findByCompanyIdAndVersionNo(UUID companyId, Long versionNo);
}
