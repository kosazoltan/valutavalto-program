package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import hu.puzzleir.valuta.dto.worker.CreateWorkerDto;
import hu.puzzleir.valuta.dto.worker.UpdateWorkerDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.WorkerRoleDefinition;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.WorkerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Worker controller - dolgozó management.
 * 
 * Csak SUPERVISOR és feljebb használhatja!
 */
@RestController
@RequestMapping("/api/v1/workers")
@RequiredArgsConstructor
@Slf4j
public class WorkerController {
    
    private final WorkerService workerService;
    private final WorkerRepository workerRepository;
    private final WorkerRoleService workerRoleService;
    
    /**
     * Új dolgozó létrehozás
     * 
     * POST /api/v1/workers
     * Body: CreateWorkerDto
     * 
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WorkerDto> createWorker(@Valid @RequestBody CreateWorkerDto dto) {
        WorkerDto created = workerService.createWorker(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    /**
     * Dolgozó módosítás
     * 
     * PUT /api/v1/workers/{id}
     * Body: UpdateWorkerDto
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WorkerDto> updateWorker(
            @PathVariable Long id,
            @Valid @RequestBody UpdateWorkerDto dto) {
        WorkerDto updated = workerService.updateWorker(id, dto);
        return ResponseEntity.ok(updated);
    }
    
    /**
     * Dolgozó lekérdezés ID alapján
     * 
     * GET /api/v1/workers/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<WorkerDto> getWorker(@PathVariable Long id) {
        WorkerDto worker = workerService.findById(id);
        return ResponseEntity.ok(worker);
    }
    
    /**
     * Company összes dolgozója
     * 
     * GET /api/v1/workers
     */
    @GetMapping
    public ResponseEntity<List<WorkerDto>> getAllWorkers() {
        List<WorkerDto> workers = workerService.findAllByCompany();
        return ResponseEntity.ok(workers);
    }
    
    /**
     * Aktív dolgozók
     * 
     * GET /api/v1/workers/active
     */
    @GetMapping("/active")
    public ResponseEntity<List<WorkerDto>> getActiveWorkers() {
        List<WorkerDto> workers = workerService.findActiveWorkers();
        return ResponseEntity.ok(workers);
    }
    
    /**
     * Dolgozók egy irodában
     * 
     * GET /api/v1/workers/branch/{branchId}
     */
    @GetMapping("/branch/{branchId}")
    public ResponseEntity<List<WorkerDto>> getWorkersByBranch(@PathVariable UUID branchId) {
        List<WorkerDto> workers = workerService.findByBranch(branchId);
        return ResponseEntity.ok(workers);
    }
    
    /**
     * Dolgozó inaktiválás
     * 
     * POST /api/v1/workers/{id}/deactivate
     * 
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deactivateWorker(@PathVariable Long id) {
        workerService.deactivateWorker(id);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Dolgozó aktiválás
     *
     * POST /api/v1/workers/{id}/activate
     *
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping("/{id}/activate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> activateWorker(@PathVariable Long id) {
        workerService.activateWorker(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * v2.5.4 (D opció): Login-lockout manuális unlock.
     *
     * POST /api/v1/workers/{id}/unlock-login
     *
     * A WorkerService.loginAttempts in-memory map-ban a worker bejegyzését
     * törli, így a következő login-próbálkozás 0 számolóval indul.
     *
     * Csak ADMIN — a kollégák zárolt account-ját az adminisztrátor oldhatja fel.
     *
     * @return remainingSeconds (másodperc): mennyi volt még hátra a lockoutból (0 ha nem volt lock)
     */
    @PostMapping("/{id}/unlock-login")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Long>> unlockLogin(@PathVariable Long id) {
        long remainingSeconds = workerService.unlockLogin(id);
        return ResponseEntity.ok(Map.of("remainingSeconds", remainingSeconds));
    }
    
    /**
     * Jelszóváltoztatás
     * 
     * POST /api/v1/workers/{id}/change-password
     * Body: ChangePasswordDto
     * 
     * Saját jelszót bárki változtathat, másét csak ADMIN
     */
    @PostMapping("/{id}/change-password")
    public ResponseEntity<Void> changePassword(
            @PathVariable Long id,
            @Valid @RequestBody ChangePasswordDto dto) {
        
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        
        // Ha nem saját jelszó, akkor ADMIN jog kell
        if (!id.equals(currentWorkerId) && !SecurityUtils.isAdmin()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        workerService.changePassword(id, dto);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Saját profil lekérdezés
     * 
     * GET /api/v1/workers/me
     */
    @GetMapping("/me")
    public ResponseEntity<WorkerDto> getCurrentWorker() {
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        WorkerDto worker = workerService.findById(currentWorkerId);
        return ResponseEntity.ok(worker);
    }

    // ============================================================
    // V57: Operatív szerepkör kezelés
    // ============================================================

    /**
     * Worker operatív szerepkör listája
     * 
     * GET /api/v1/workers/{id}/roles
     */
    @GetMapping("/{id}/roles")
    public ResponseEntity<List<String>> getWorkerRoles(@PathVariable Long id) {
        // Multi-tenant IDOR védelem (self-review B1): a worker operatív szerepkör-kódjai csak a saját
        // céghez tartozó workerre kérhetők le. A WorkerRoleService.getRoleCodesForWorker maga NEM
        // companyId-scope-olt (login/first-time-setup/Google flow-k hívják auth-kontextus nélkül, ahol
        // még nincs bejelentkezett felhasználó), ezért a tenancy-t itt, az authentikált REST-úton a
        // companyId-scope-olt WorkerService.findById-vel kényszerítjük ki — idegen cég workerId-jére dob.
        workerService.findById(id);
        List<String> roles = workerRoleService.getRoleCodesForWorker(id);
        return ResponseEntity.ok(roles);
    }

    /**
     * Operatív szerepkör hozzáadás
     * 
     * POST /api/v1/workers/{id}/roles/{roleCode}
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping("/{id}/roles/{roleCode}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> assignRole(
            @PathVariable Long id,
            @PathVariable String roleCode) {
        workerRoleService.assignRole(id, roleCode);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /**
     * Operatív szerepkör eltávolítás
     * 
     * DELETE /api/v1/workers/{id}/roles/{roleCode}
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @DeleteMapping("/{id}/roles/{roleCode}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> removeRole(
            @PathVariable Long id,
            @PathVariable String roleCode) {
        workerRoleService.removeRole(id, roleCode);
        return ResponseEntity.noContent().build();
    }

    /**
     * v2.1.4: Bulk email import (admin) - CSV paste / Excel format.
     * PATCH /api/v1/workers/bulk-email
     * Body: [{"workerCode": "W007570", "email": "peldaul@gmail.com"}, ...]
     * Visszater: {"updated": N, "skipped": M, "errors": [...]}
     */
    @PatchMapping("/bulk-email")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<java.util.Map<String, Object>> bulkEmailUpdate(
            @RequestBody java.util.List<java.util.Map<String, String>> items) {
        int updated = 0;
        int skipped = 0;
        java.util.List<String> errors = new java.util.ArrayList<>();
        java.util.UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();

        for (java.util.Map<String, String> item : items) {
            String code = item.get("workerCode");
            String email = item.get("email");
            if (code == null || code.isBlank()) { skipped++; continue; }
            try {
                hu.puzzleir.valuta.entity.Worker w = workerRepository
                        .findByCompanyIdAndCodeIgnoreCase(companyId, code.trim())
                        .orElse(null);
                if (w == null) { errors.add(code + ": nem letezik"); skipped++; continue; }
                w.setEmail(email == null || email.isBlank() ? null : email.trim());
                workerRepository.save(w);
                updated++;
            } catch (Exception e) {
                // A hiba a válasz "errors" listájában is megjelenik, de admin bulk-mutációnál
                // szerver-oldali nyomot is hagyunk (megfigyelhetőség/audit). PII (email) NEM kerül logba.
                log.warn("Bulk email update sikertelen: workerCode={}, ok={}", code, e.getMessage());
                errors.add(code + ": " + e.getMessage());
                skipped++;
            }
        }

        java.util.Map<String, Object> response = new java.util.HashMap<>();
        response.put("updated", updated);
        response.put("skipped", skipped);
        response.put("errors", errors);
        return ResponseEntity.ok(response);
    }

}
