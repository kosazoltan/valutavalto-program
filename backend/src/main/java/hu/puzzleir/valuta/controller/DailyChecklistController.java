package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.checklist.CheckItemRequest;
import hu.puzzleir.valuta.dto.checklist.DailyChecklistDto;
import hu.puzzleir.valuta.service.DailyChecklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

/**
 * Napi nyitási checklist controller (legacy: CHECKLST.DLL).
 *
 * 19 tételes ellenőrzőlista kezelése.
 */
@RestController
@RequestMapping("/api/v1/daily-checklist")
@RequiredArgsConstructor
public class DailyChecklistController {

    private final DailyChecklistService dailyChecklistService;

    /**
     * Checklist lekérése (ha nem létezik, automatikusan létrehozza).
     *
     * GET /api/v1/daily-checklist/{branchId}/{date}
     */
    @GetMapping("/{branchId}/{date}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailyChecklistDto> getChecklist(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        DailyChecklistDto result = dailyChecklistService.getChecklist(branchId, date);
        return ResponseEntity.ok(result);
    }

    /**
     * Tétel kipipálása / visszavonása.
     *
     * PUT /api/v1/daily-checklist/{checklistId}/items/{itemNumber}
     */
    @PutMapping("/{checklistId}/items/{itemNumber}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailyChecklistDto> checkItem(
            @PathVariable UUID checklistId,
            @PathVariable int itemNumber,
            @jakarta.validation.Valid @RequestBody CheckItemRequest request) {
        DailyChecklistDto result = dailyChecklistService.checkItem(
                checklistId, itemNumber, request.isChecked(), request.getNotes());
        return ResponseEntity.ok(result);
    }

    /**
     * Checklist lezárása (mind a 19 tételnek kipipáltnak kell lennie).
     *
     * POST /api/v1/daily-checklist/{checklistId}/complete
     */
    @PostMapping("/{checklistId}/complete")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailyChecklistDto> completeChecklist(@PathVariable UUID checklistId) {
        DailyChecklistDto result = dailyChecklistService.completeChecklist(checklistId);
        return ResponseEntity.ok(result);
    }

    /**
     * Checklist státusz lekérdezése (napzárás validációhoz).
     *
     * GET /api/v1/daily-checklist/{branchId}/{date}/status
     */
    @GetMapping("/{branchId}/{date}/status")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getChecklistStatus(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        boolean completed = dailyChecklistService.isChecklistCompleted(branchId, date);
        return ResponseEntity.ok(Map.of(
                "branchId", branchId,
                "date", date.toString(),
                "completed", completed));
    }
}
