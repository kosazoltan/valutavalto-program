package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CustomerVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerVersionRepository extends JpaRepository<CustomerVersion, Long> {

    Optional<CustomerVersion> findTopByCustomerIdOrderByVersionNoDesc(Long customerId);

    /** MULTI-TENANT: companyId-szűrt (invariáns #1). */
    List<CustomerVersion> findByCustomerIdAndCompanyIdOrderByVersionNoDesc(Long customerId, UUID companyId);

    Optional<CustomerVersion> findByCustomerIdAndVersionNoAndCompanyId(Long customerId, Long versionNo, UUID companyId);
}
