package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ScheduledTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ScheduledTaskRepository extends JpaRepository<ScheduledTask, UUID> {

    List<ScheduledTask> findByIsActiveTrueOrderByNextRunAtAsc();

    List<ScheduledTask> findAllByOrderByCreatedAtDesc();

    List<ScheduledTask> findByTaskType(ScheduledTask.TaskType taskType);
}
