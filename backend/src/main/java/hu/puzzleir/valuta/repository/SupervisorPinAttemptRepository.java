package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SupervisorPinAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface SupervisorPinAttemptRepository extends JpaRepository<SupervisorPinAttempt, Long> {

    long countByWorkerIdAndSuccessFalseAndAttemptAtAfter(Long workerId, LocalDateTime since);
}
