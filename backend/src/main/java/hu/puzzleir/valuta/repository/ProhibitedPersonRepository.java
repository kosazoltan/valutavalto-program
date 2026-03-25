package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ProhibitedPerson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProhibitedPersonRepository extends JpaRepository<ProhibitedPerson, UUID> {
    List<ProhibitedPerson> findAllByCompanyId(UUID companyId);
}
