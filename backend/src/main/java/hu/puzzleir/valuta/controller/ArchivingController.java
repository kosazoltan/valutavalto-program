package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.service.ArchivingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Archiválás controller.
 */
@RestController
@RequestMapping("/api/v1/archiving")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class ArchivingController {

    private final ArchivingService archivingService;

    /**
     * Összes archiválási feladat listázása.
     * GET /api/v1/archiving/tasks
     */
    @GetMapping("/tasks")
    public ResponseEntity<List<ArchiveTask>> getAllTasks() {
        return ResponseEntity.ok(archivingService.getAllTasks());
    }

    /**
     * Új archiválási feladat létrehozása.
     * POST /api/v1/archiving/tasks
     */
    @PostMapping("/tasks")
    public ResponseEntity<ArchiveTask> createTask(@Valid @RequestBody ArchiveTask task) {
        return ResponseEntity.status(HttpStatus.CREATED).body(archivingService.createTask(task));
    }

    /**
     * Archiválási feladat végrehajtása.
     * POST /api/v1/archiving/tasks/{id}/execute
     */
    @PostMapping("/tasks/{id}/execute")
    public ResponseEntity<ArchiveTask> executeTask(@PathVariable UUID id) {
        return ResponseEntity.ok(archivingService.executeTask(id));
    }
}
