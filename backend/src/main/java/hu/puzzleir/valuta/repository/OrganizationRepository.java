package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrganizationRepository extends JpaRepository<Organization, UUID> {
    List<Organization> findByIsActiveTrue();
    List<Organization> findByParentIdIsNull();
    List<Organization> findAllByCompanyId(UUID companyId);
    List<Organization> findByCompanyIdAndIsActiveTrue(UUID companyId);
    List<Organization> findByCompanyIdAndParentIdIsNull(UUID companyId);
}
