package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import hu.puzzleir.valuta.dto.worker.CreateWorkerDto;
import hu.puzzleir.valuta.dto.worker.UpdateWorkerDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.WorkerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Worker controller - dolgozó management.
 * 
 * Csak SUPERVISOR és feljebb használhatja!
 */
@RestController
@RequestMapping("/api/v1/workers")
@RequiredArgsConstructor
public class WorkerController {
    
    private final WorkerService workerService;
    
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
}
