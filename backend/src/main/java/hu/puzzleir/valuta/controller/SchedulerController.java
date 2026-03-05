package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.scheduler.ScheduledTaskDto;
import hu.puzzleir.valuta.service.SchedulerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Scheduler controller — időzített feladatok kezelése.
 */
@RestController
@RequestMapping("/api/v1/scheduler")
@RequiredArgsConstructor
public class SchedulerController {

    private final SchedulerService schedulerService;

    /**
     * GET /api/v1/scheduler/tasks — Összes feladat listázása
     */
    @GetMapping("/tasks")
    public ResponseEntity<List<ScheduledTaskDto>> getTasks() {
        return ResponseEntity.ok(schedulerService.getTaskHistory());
    }

    /**
     * POST /api/v1/scheduler/tasks — Új feladat regisztrálása
     */
    @PostMapping("/tasks")
    public ResponseEntity<ScheduledTaskDto> createTask(@RequestBody ScheduledTaskDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(schedulerService.registerTask(dto));
    }

    /**
     * PUT /api/v1/scheduler/tasks/{id}/toggle — Feladat aktív/inaktív váltás
     */
    @PutMapping("/tasks/{id}/toggle")
    public ResponseEntity<Void> toggleTask(
            @PathVariable UUID id,
            @RequestParam boolean active) {
        schedulerService.toggleTask(id, active);
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/v1/scheduler/tasks/{id}/run-now — Manuális futtatás
     */
    @PostMapping("/tasks/{id}/run-now")
    public ResponseEntity<ScheduledTaskDto> runNow(@PathVariable UUID id) {
        return ResponseEntity.ok(schedulerService.runNow(id));
    }
}
