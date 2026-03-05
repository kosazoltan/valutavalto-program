package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SanctionScreeningLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface SanctionScreeningLogRepository extends JpaRepository<SanctionScreeningLog, UUID> {

    Page<SanctionScreeningLog> findByResultNotOrderByCreatedAtDesc(String result, Pageable pageable);

    Page<SanctionScreeningLog> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
