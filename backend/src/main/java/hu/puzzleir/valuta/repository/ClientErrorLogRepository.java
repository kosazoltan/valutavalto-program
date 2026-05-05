package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ClientErrorLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ClientErrorLogRepository extends JpaRepository<ClientErrorLog, Long> {
}
