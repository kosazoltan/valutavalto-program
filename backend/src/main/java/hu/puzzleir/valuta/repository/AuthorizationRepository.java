package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Authorization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuthorizationRepository extends JpaRepository<Authorization, UUID> {

    List<Authorization> findByRepresentativeId(UUID representativeId);

    List<Authorization> findByRepresentativeIdAndStatusDid(UUID representativeId, String statusDid);

    List<Authorization> findByRepresentativeIdAndOperationDid(UUID representativeId, String operationDid);
}
