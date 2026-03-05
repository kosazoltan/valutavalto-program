package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ArchiveTaskRepository extends JpaRepository<ArchiveTask, UUID> {

    List<ArchiveTask> findByStatus(ArchiveTaskStatus status);
}
