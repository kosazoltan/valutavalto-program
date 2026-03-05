package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerCompetition;
import hu.puzzleir.valuta.entity.WorkerCompetition.CompetitionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface WorkerCompetitionRepository extends JpaRepository<WorkerCompetition, UUID> {

    List<WorkerCompetition> findByStatusOrderByStartDateDesc(CompetitionStatus status);

    List<WorkerCompetition> findAllByOrderByCreatedAtDesc();
}
