package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.PoliceRequest;
import hu.puzzleir.valuta.entity.PoliceRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface PoliceRequestRepository extends JpaRepository<PoliceRequest, UUID> {

    Page<PoliceRequest> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<PoliceRequest> findByStatusOrderByCreatedAtDesc(PoliceRequestStatus status, Pageable pageable);
}
