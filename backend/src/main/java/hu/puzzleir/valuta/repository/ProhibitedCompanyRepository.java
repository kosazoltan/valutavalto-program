package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ProhibitedCompany;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProhibitedCompanyRepository extends JpaRepository<ProhibitedCompany, UUID> {
    List<ProhibitedCompany> findAllByCompanyId(UUID companyId);
}
