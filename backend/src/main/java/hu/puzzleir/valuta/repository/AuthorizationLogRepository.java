package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AuthorizationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuthorizationLogRepository extends JpaRepository<AuthorizationLog, UUID> {

    List<AuthorizationLog> findByRepresentativeIdOrderByPerformedAtDesc(UUID representativeId);
}
