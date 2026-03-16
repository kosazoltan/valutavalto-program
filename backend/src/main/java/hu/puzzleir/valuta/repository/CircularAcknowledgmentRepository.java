package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CircularAcknowledgment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CircularAcknowledgmentRepository extends JpaRepository<CircularAcknowledgment, Long> {

    Optional<CircularAcknowledgment> findByCircularIdAndWorkerId(Long circularId, Long workerId);

    List<CircularAcknowledgment> findByCircularId(Long circularId);

    @Query("SELECT ca.circular.id FROM CircularAcknowledgment ca WHERE ca.workerId = :workerId")
    List<Long> findAcknowledgedCircularIdsByWorkerId(@Param("workerId") Long workerId);

    long countByCircularId(Long circularId);
}
