package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.dto.admin.*;
import hu.puzzleir.valuta.dto.customer.CustomerVersionDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.service.CompanyAdminService;
import hu.puzzleir.valuta.service.CompanyVersionService;
import hu.puzzleir.valuta.security.SecurityUtils;
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
    private final CompanyVersionService companyVersionService;

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

    /** FS-3 (D1): cég verziótörténet. Same-tenant guard (invariáns #1, fail-closed). */
    @GetMapping("/companies/{id}/versions")
    public ResponseEntity<List<CustomerVersionDto>> getCompanyVersions(@PathVariable UUID id) {
        requireSameTenant(id);
        List<CustomerVersionDto> dtos = companyVersionService.listVersions(id).stream()
                .map(v -> CustomerVersionDto.builder()
                        .versionNo(v.getVersionNo())
                        .changedBy(v.getChangedBy())
                        .changedAt(v.getChangedAt())
                        .changeSource(v.getChangeSource().name())
                        .build())
                .toList();
        return ResponseEntity.ok(dtos);
    }

    /** FS-3 (D1): egy konkrét cégállapot megtekintése snapshot JSON-nal. */
    @GetMapping("/companies/{id}/versions/{versionNo}")
    public ResponseEntity<CustomerVersionDto> getCompanyVersion(
            @PathVariable UUID id,
            @PathVariable Long versionNo) {
        requireSameTenant(id);
        return companyVersionService.getVersion(id, versionNo)
                .map(v -> ResponseEntity.ok(CustomerVersionDto.builder()
                        .versionNo(v.getVersionNo())
                        .changedBy(v.getChangedBy())
                        .changedAt(v.getChangedAt())
                        .changeSource(v.getChangeSource().name())
                        .snapshot(v.getSnapshot())
                        .build()))
                .orElseThrow(() -> new ResourceNotFoundException("Verzió nem található: " + versionNo));
    }

    private void requireSameTenant(UUID id) {
        if (!SecurityUtils.getCurrentCompanyId().equals(id)) {
            throw new ResourceNotFoundException("Cég nem található: " + id);
        }
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
     * Összes fiók statisztikákkal (lista-nézet ADMIN STAT oszlop: dolgozószám + szinkron állapot).
     * GET /api/v1/admin/branches
     *
     * FK-043: a szinkron állapot és a dolgozószám felügyeleti adat, amelyet a
     * főértéktárosnak és az ügyvezetőnek is látnia kell. A metódus-szintű
     * {@code @PreAuthorize} FELÜLÍRJA az osztály-szintű {@code hasRole('ADMIN')}-t
     * KIZÁRÓLAG ezen a végponton — a controller többi végpontja ADMIN-only marad.
     * A tenant-izolációt a service {@code company_id}-szűrése biztosítja (NFR-4).
     */
    @GetMapping("/branches")
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<BranchWithStatsDto>> getAllBranchesWithStats() {
        return ResponseEntity.ok(companyAdminService.getAllBranchesWithStats());
    }
}
