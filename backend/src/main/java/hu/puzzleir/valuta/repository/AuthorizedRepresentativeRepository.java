package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AuthorizedRepresentative;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuthorizedRepresentativeRepository extends JpaRepository<AuthorizedRepresentative, UUID> {

    List<AuthorizedRepresentative> findByCustomerId(Long customerId);

    List<AuthorizedRepresentative> findByIsActiveTrue();

    List<AuthorizedRepresentative> findAllByCompanyId(UUID companyId);
    List<AuthorizedRepresentative> findByCompanyIdAndCustomerId(UUID companyId, Long customerId);
}
