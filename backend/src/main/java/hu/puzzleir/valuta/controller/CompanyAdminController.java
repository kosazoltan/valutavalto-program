package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.dto.admin.*;
import hu.puzzleir.valuta.service.CompanyAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Cég és fiók adminisztráció REST controller.
 */
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class CompanyAdminController {

    private final CompanyAdminService companyAdminService;

    /**
     * Cég részletes adatai.
     * GET /api/v1/admin/companies/{id}
     */
    @GetMapping("/companies/{id}")
    public ResponseEntity<CompanyDetailsDto> getCompanyDetails(@PathVariable UUID id) {
        return ResponseEntity.ok(companyAdminService.getCompanyDetails(id));
    }

    /**
     * Cég adatainak frissítése.
     * PUT /api/v1/admin/companies/{id}
     */
    @PutMapping("/companies/{id}")
    public ResponseEntity<Void> updateCompany(
            @PathVariable UUID id,
            @Valid @RequestBody CompanyUpdateDto dto) {
        companyAdminService.updateCompany(id, dto);
        return ResponseEntity.ok().build();
    }

    /**
     * Fiók részletes adatai.
     * GET /api/v1/admin/branches/{id}
     */
    @GetMapping("/branches/{id}")
    public ResponseEntity<BranchDetailsDto> getBranchDetails(@PathVariable UUID id) {
        return ResponseEntity.ok(companyAdminService.getBranchDetails(id));
    }

    /**
     * Fiók adatainak frissítése.
     * PUT /api/v1/admin/branches/{id}
     */
    @PutMapping("/branches/{id}")
    public ResponseEntity<Void> updateBranch(
            @PathVariable UUID id,
            @Valid @RequestBody BranchUpdateDto dto) {
        companyAdminService.updateBranch(id, dto);
        return ResponseEntity.ok().build();
    }

    /**
     * Összes fiók statisztikákkal.
     * GET /api/v1/admin/branches
     */
    @GetMapping("/branches")
    public ResponseEntity<List<BranchWithStatsDto>> getAllBranchesWithStats() {
        return ResponseEntity.ok(companyAdminService.getAllBranchesWithStats());
    }
}
