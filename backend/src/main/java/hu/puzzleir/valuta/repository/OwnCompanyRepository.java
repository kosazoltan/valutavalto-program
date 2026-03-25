package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.OwnCompany;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OwnCompanyRepository extends JpaRepository<OwnCompany, UUID> {
    List<OwnCompany> findByIsActiveTrue();
    List<OwnCompany> findAllByCompanyId(UUID companyId);
    List<OwnCompany> findByCompanyIdAndIsActiveTrue(UUID companyId);
}
