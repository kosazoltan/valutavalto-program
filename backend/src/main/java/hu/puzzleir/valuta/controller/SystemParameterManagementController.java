package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.systemparameter.BulkUpdateDto;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.service.SystemParameterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Rendszer paraméterek kezelés — bővített API.
 */
@RestController
@RequestMapping("/api/v1/system-params")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
public class SystemParameterManagementController {

    private final SystemParameterService service;

    @GetMapping
    public ResponseEntity<List<SystemParameter>> getAll() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<SystemParameter>> getByCategory(@PathVariable String category) {
        return ResponseEntity.ok(service.listByCategory(category));
    }

    @PutMapping("/{key}")
    public ResponseEntity<SystemParameter> updateByKey(
            @PathVariable String key,
            @RequestBody Map<String, String> body) {
        SystemParameter existing = service.getByKey(key);
        return ResponseEntity.ok(service.update(
                existing.getId(),
                body.get("value"),
                body.get("description")));
    }

    @PostMapping("/bulk-update")
    public ResponseEntity<Map<String, String>> bulkUpdate(@RequestBody BulkUpdateDto dto) {
        int updated = 0;
        for (Map.Entry<String, String> entry : dto.getParameters().entrySet()) {
            try {
                SystemParameter existing = service.getByKey(entry.getKey());
                service.update(existing.getId(), entry.getValue(), null);
                updated++;
            } catch (Exception e) {
                // Skip non-existent keys
            }
        }
        return ResponseEntity.ok(Map.of("updated", String.valueOf(updated)));
    }
}
