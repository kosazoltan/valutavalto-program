package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.service.SystemParameterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/system-parameters")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class SystemParameterController {

    private final SystemParameterService service;

    @GetMapping
    public ResponseEntity<List<SystemParameter>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/active")
    public ResponseEntity<List<SystemParameter>> listActive() {
        return ResponseEntity.ok(service.listActive());
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<SystemParameter>> listByCategory(@PathVariable String category) {
        return ResponseEntity.ok(service.listByCategory(category));
    }

    @GetMapping("/key/{key}")
    public ResponseEntity<SystemParameter> getByKey(@PathVariable String key) {
        return ResponseEntity.ok(service.getByKey(key));
    }

    @GetMapping("/value/{key}")
    public ResponseEntity<String> getValue(@PathVariable String key) {
        return ResponseEntity.ok(service.getValue(key));
    }

    @PostMapping
    public ResponseEntity<SystemParameter> create(@Valid @RequestBody Map<String, String> body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(
                body.get("parameterKey"), body.get("parameterValue"),
                body.get("parameterType"), body.get("category"), body.get("description"),
                parseIsActive(body.get("isActive"))));
    }

    /**
     * A létrehozó űrlap "Aktív" jelölőnégyzete (a frontend boolean-t küld, a Map&lt;String,String&gt;
     * body-ban "true"/"false" szövegként érkezik). Hiányzó, üres vagy nem értelmezhető érték →
     * {@code null}, amit a service aktív sorként hoz létre — elgépelés nem inaktiválhat némán
     * egy új paramétert, és a mezőt ma nem küldő hívók viselkedése változatlan.
     */
    private static Boolean parseIsActive(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        if ("false".equalsIgnoreCase(value)) {
            return Boolean.FALSE;
        }
        if ("true".equalsIgnoreCase(value)) {
            return Boolean.TRUE;
        }
        return null;
    }

    @PutMapping("/{id}")
    public ResponseEntity<SystemParameter> update(@PathVariable UUID id, @Valid @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(service.update(id, body.get("parameterValue"), body.get("description")));
    }

    @PostMapping("/{id}/toggle-active")
    public ResponseEntity<SystemParameter> toggleActive(@PathVariable UUID id) {
        return ResponseEntity.ok(service.toggleActive(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
