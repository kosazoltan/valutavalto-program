package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchivedTransaction;
import hu.puzzleir.valuta.service.ArchivingService;
import hu.puzzleir.valuta.service.MonthlyArchiveService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Archiválás controller — task-alapú + havi archiválás.
 */
@RestController
@RequestMapping("/api/v1/archiving")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class ArchivingController {

    private final ArchivingService archivingService;
    private final MonthlyArchiveService monthlyArchiveService;

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

    // ============ HAVI ARCHIVÁLÁS (MonthlyArchiveService) ============

    /**
     * Havi tranzakció archiválás végrehajtása.
     * POST /api/v1/archiving/monthly
     * Body: { "branchId": "uuid", "yearMonth": "2026-02" }
     */
    @PostMapping("/monthly")
    public ResponseEntity<Map<String, Object>> archiveMonth(
            @RequestBody Map<String, String> body) {
        UUID branchId = UUID.fromString(body.get("branchId"));
        YearMonth yearMonth = YearMonth.parse(body.get("yearMonth"));
        int count = monthlyArchiveService.archiveMonth(branchId, yearMonth);
        return ResponseEntity.ok(Map.of(
                "branchId", branchId.toString(),
                "yearMonth", yearMonth.toString(),
                "archivedCount", count
        ));
    }

    /**
     * Archivált tranzakciók lekérdezése hónap szerint.
     * GET /api/v1/archiving/monthly/{branchId}/{yearMonth}
     */
    @GetMapping("/monthly/{branchId}/{yearMonth}")
    public ResponseEntity<List<ArchivedTransaction>> getArchivedTransactions(
            @PathVariable UUID branchId,
            @PathVariable String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        return ResponseEntity.ok(monthlyArchiveService.getArchivedTransactions(branchId, ym));
    }

    /**
     * Ellenőrzés: archivált-e már a hónap.
     * GET /api/v1/archiving/monthly/{branchId}/{yearMonth}/status
     */
    @GetMapping("/monthly/{branchId}/{yearMonth}/status")
    public ResponseEntity<Map<String, Object>> isMonthArchived(
            @PathVariable UUID branchId,
            @PathVariable String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        boolean archived = monthlyArchiveService.isMonthArchived(branchId, ym);
        return ResponseEntity.ok(Map.of("archived", archived, "yearMonth", yearMonth));
    }
}
