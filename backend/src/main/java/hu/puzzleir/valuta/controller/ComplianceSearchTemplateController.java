package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchTemplateDto;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchTemplateDto;
import hu.puzzleir.valuta.service.ComplianceSearchTemplateService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * FS-11 S2a: mentett compliance szűrő-sablon endpointok.
 * Cég-scope a service-ben, a SecurityContextből (requestben SOHA nincs companyId).
 */
@RestController
@RequestMapping("/api/v1/compliance/search-templates")
@RequiredArgsConstructor
public class ComplianceSearchTemplateController {

    private static final String ROLES = "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','MANAGER','ADMIN',"
            + "'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO')";

    private final ComplianceSearchTemplateService service;

    @PostMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance szűrő-sablon mentése (dátum nélkül, cégszinten közös)")
    public ResponseEntity<ComplianceSearchTemplateDto> create(
            @RequestBody CreateComplianceSearchTemplateDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(dto));
    }

    @GetMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance szűrő-sablonok listája (criteria visszatöltéshez)")
    public ResponseEntity<List<ComplianceSearchTemplateDto>> list() {
        return ResponseEntity.ok(service.listForCurrentCompany());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance szűrő-sablon törlése")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
