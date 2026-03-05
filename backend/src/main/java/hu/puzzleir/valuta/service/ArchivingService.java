package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import hu.puzzleir.valuta.repository.ArchiveTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Archiválási szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class ArchivingService {

    private final ArchiveTaskRepository archiveTaskRepository;

    @Transactional(readOnly = true)
    public List<ArchiveTask> getAllTasks() {
        return archiveTaskRepository.findAll();
    }

    public ArchiveTask createTask(ArchiveTask task) {
        task.setStatus(ArchiveTaskStatus.PENDING);
        log.info("Archiválási feladat létrehozva: type={}, entityType={}",
                task.getTaskType(), task.getEntityType());
        return archiveTaskRepository.save(task);
    }

    /**
     * Feladat végrehajtása (státusz frissítés).
     * A tényleges archiválási logika később kerül implementálásra.
     */
    public ArchiveTask executeTask(UUID taskId) {
        ArchiveTask task = archiveTaskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Archiválási feladat nem található: " + taskId));

        task.setStatus(ArchiveTaskStatus.RUNNING);
        task.setStartedAt(LocalDateTime.now());
        archiveTaskRepository.save(task);

        try {
            // Placeholder: tényleges archiválás később
            log.info("Archiválási feladat végrehajtása: id={}, type={}", taskId, task.getTaskType());

            task.setStatus(ArchiveTaskStatus.COMPLETED);
            task.setCompletedAt(LocalDateTime.now());
            task.setArchiveLocation("archive/" + task.getEntityType() + "/" + taskId);
        } catch (Exception e) {
            log.error("Archiválási feladat hiba: id={}", taskId, e);
            task.setStatus(ArchiveTaskStatus.FAILED);
            task.setCompletedAt(LocalDateTime.now());
        }

        return archiveTaskRepository.save(task);
    }
}
