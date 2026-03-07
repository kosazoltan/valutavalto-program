package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.employee.*;
import hu.puzzleir.valuta.entity.FeorCode;
import hu.puzzleir.valuta.service.EmployeeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Employee HR törzsadat controller.
 *
 * Endpoints:
 *   GET    /api/v1/employees           — lista (szűrhető: organizationUnit, jobTitle, active, name)
 *   GET    /api/v1/employees/{id}      — részletes nézet (címekkel + bankszámlákkal)
 *   POST   /api/v1/employees           — létrehozás
 *   PUT    /api/v1/employees/{id}      — módosítás
 *   DELETE /api/v1/employees/{id}      — soft delete (active=false)
 *   POST   /api/v1/employees/import    — JSON import
 *   GET    /api/v1/employees/feor-codes — FEOR referencia lista
 *
 * Jogosultság: MANAGER, ADMIN
 */
@RestController
@RequestMapping("/api/v1/employees")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class EmployeeController {

    private final EmployeeService employeeService;

    /**
     * Dolgozók listázása szűréssel.
     *
     * GET /api/v1/employees?organizationUnit=Szekszárd&jobTitle=pénztáros&active=true&name=Kiss
     */
    @GetMapping
    public ResponseEntity<List<EmployeeListDto>> listEmployees(
            @RequestParam(required = false) String organizationUnit,
            @RequestParam(required = false) String jobTitle,
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) String name) {

        if (name != null && !name.isBlank()) {
            return ResponseEntity.ok(employeeService.searchByName(name));
        }
        return ResponseEntity.ok(employeeService.listEmployees(organizationUnit, jobTitle, active));
    }

    /**
     * Dolgozó részletes lekérdezés ID alapján.
     *
     * GET /api/v1/employees/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<EmployeeDto> getEmployee(@PathVariable Long id) {
        return ResponseEntity.ok(employeeService.getById(id));
    }

    /**
     * Új dolgozó létrehozása.
     *
     * POST /api/v1/employees
     * Body: CreateEmployeeDto
     */
    @PostMapping
    public ResponseEntity<EmployeeDto> createEmployee(@Valid @RequestBody CreateEmployeeDto dto) {
        EmployeeDto created = employeeService.createEmployee(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Dolgozó módosítása.
     *
     * PUT /api/v1/employees/{id}
     * Body: UpdateEmployeeDto
     */
    @PutMapping("/{id}")
    public ResponseEntity<EmployeeDto> updateEmployee(
            @PathVariable Long id,
            @Valid @RequestBody UpdateEmployeeDto dto) {
        return ResponseEntity.ok(employeeService.updateEmployee(id, dto));
    }

    /**
     * Dolgozó soft delete (active = false).
     *
     * DELETE /api/v1/employees/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEmployee(@PathVariable Long id) {
        employeeService.deleteEmployee(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * JSON import — EBC dolgozói adatok betöltése.
     *
     * POST /api/v1/employees/import
     * Body: JSON string (az ebc_employees.json tartalma)
     */
    @PostMapping("/import")
    public ResponseEntity<Map<String, Object>> importEmployees(@Valid @RequestBody String jsonContent) {
        int count = employeeService.importFromJson(jsonContent);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "imported", count,
                "message", count + " dolgozó sikeresen importálva"
        ));
    }

    /**
     * FEOR kód referencia lista.
     *
     * GET /api/v1/employees/feor-codes
     */
    @GetMapping("/feor-codes")
    public ResponseEntity<List<FeorCode>> getFeorCodes() {
        return ResponseEntity.ok(employeeService.getAllFeorCodes());
    }
}
