package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.PoliceRequest;
import hu.puzzleir.valuta.entity.PoliceRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PoliceRequestRepository extends JpaRepository<PoliceRequest, UUID> {

    @Deprecated
    Page<PoliceRequest> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @Deprecated
    Page<PoliceRequest> findByStatusOrderByCreatedAtDesc(PoliceRequestStatus status, Pageable pageable);

    // Multi-tenant scope (V270): a single-id + lista lekérdezések a hívó cégére szűrnek.
    Optional<PoliceRequest> findByIdAndCompanyId(UUID id, UUID companyId);

    Page<PoliceRequest> findByCompanyIdOrderByCreatedAtDesc(UUID companyId, Pageable pageable);
}
