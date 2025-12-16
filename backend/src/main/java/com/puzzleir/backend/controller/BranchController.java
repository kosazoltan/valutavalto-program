package com.puzzleir.backend.controller;

import com.puzzleir.backend.dto.BranchDto;
import com.puzzleir.backend.dto.CreateBranchDto;
import com.puzzleir.backend.dto.UpdateBranchDto;
import com.puzzleir.backend.service.BranchService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/branches")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class BranchController {

    private final BranchService branchService;

    /**
     * GET /api/v1/branches
     * Összes fiók lekérése (opcionális szűrőkkel)
     */
    @GetMapping
    public ResponseEntity<List<BranchDto>> getAllBranches(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(required = false, defaultValue = "false") boolean activeOnly
    ) {
        log.info("GET /api/v1/branches - type: {}, status: {}, search: {}, activeOnly: {}", 
                type, status, search, activeOnly);

        List<BranchDto> branches;

        if (search != null && !search.trim().isEmpty()) {
            branches = branchService.search(search);
        } else if (type != null && !type.trim().isEmpty()) {
            branches = branchService.findByType(type);
        } else if (status != null && !status.trim().isEmpty()) {
            branches = branchService.findByStatus(status);
        } else if (activeOnly) {
            branches = branchService.findAllActive();
        } else {
            branches = branchService.findAll();
        }

        return ResponseEntity.ok(branches);
    }

    /**
     * GET /api/v1/branches/roots
     * Gyökér fiókok (nincs szülő)
     */
    @GetMapping("/roots")
    public ResponseEntity<List<BranchDto>> getRootBranches() {
        log.info("GET /api/v1/branches/roots");
        List<BranchDto> roots = branchService.findRootBranches();
        return ResponseEntity.ok(roots);
    }

    /**
     * GET /api/v1/branches/{id}
     * Fiók lekérése ID alapján
     */
    @GetMapping("/{id}")
    public ResponseEntity<BranchDto> getBranchById(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}", id);
        BranchDto branch = branchService.findById(id);
        return ResponseEntity.ok(branch);
    }

    /**
     * GET /api/v1/branches/code/{code}
     * Fiók lekérése kód alapján
     */
    @GetMapping("/code/{code}")
    public ResponseEntity<BranchDto> getBranchByCode(@PathVariable String code) {
        log.info("GET /api/v1/branches/code/{}", code);
        BranchDto branch = branchService.findByCode(code);
        return ResponseEntity.ok(branch);
    }

    /**
     * GET /api/v1/branches/{id}/children
     * Szülő alatti közvetlen gyermekek
     */
    @GetMapping("/{id}/children")
    public ResponseEntity<List<BranchDto>> getChildren(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}/children", id);
        List<BranchDto> children = branchService.findChildren(id);
        return ResponseEntity.ok(children);
    }

    /**
     * GET /api/v1/branches/{id}/path
     * Útvonal a gyökérig (breadcrumb)
     */
    @GetMapping("/{id}/path")
    public ResponseEntity<List<BranchDto>> getPathToRoot(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}/path", id);
        List<BranchDto> path = branchService.findPathToRoot(id);
        return ResponseEntity.ok(path);
    }

    /**
     * POST /api/v1/branches
     * Új fiók létrehozása
     */
    @PostMapping
    public ResponseEntity<BranchDto> createBranch(@Valid @RequestBody CreateBranchDto dto) {
        log.info("POST /api/v1/branches - code: {}", dto.getCode());
        BranchDto created = branchService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/v1/branches/{id}
     * Fiók frissítése
     */
    @PutMapping("/{id}")
    public ResponseEntity<BranchDto> updateBranch(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBranchDto dto
    ) {
        log.info("PUT /api/v1/branches/{}", id);
        BranchDto updated = branchService.update(id, dto);
        return ResponseEntity.ok(updated);
    }

    /**
     * DELETE /api/v1/branches/{id}
     * Fiók törlése (soft delete)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBranch(@PathVariable UUID id) {
        log.info("DELETE /api/v1/branches/{}", id);
        branchService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
