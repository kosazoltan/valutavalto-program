package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerCompetitionEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Repository
public interface WorkerCompetitionEntryRepository extends JpaRepository<WorkerCompetitionEntry, UUID> {

    List<WorkerCompetitionEntry> findByCompetitionIdOrderByScoreDesc(UUID competitionId);

    @Transactional
    void deleteByCompetitionId(UUID competitionId);
}
