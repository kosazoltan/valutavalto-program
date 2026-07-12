package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchAuditDto;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchAuditDto;
import hu.puzzleir.valuta.service.ComplianceSearchAuditPdfService;
import hu.puzzleir.valuta.service.ComplianceSearchAuditService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/compliance/search-audit")
@RequiredArgsConstructor
public class ComplianceSearchAuditController {

    private static final String ROLES = "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','MANAGER','ADMIN',"
            + "'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO')";

    private final ComplianceSearchAuditService auditService;
    private final ComplianceSearchAuditPdfService pdfService;

    @PostMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Keresés-eredmény mentése az audit naplóba (snapshot + cím + leírás)")
    public ResponseEntity<ComplianceSearchAuditDto> create(@RequestBody CreateComplianceSearchAuditDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(auditService.create(dto));
    }

    @GetMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Keresés-audit napló listája (criteria lenyitáshoz, snapshot nélkül)")
    public ResponseEntity<List<ComplianceSearchAuditDto>> list() {
        return ResponseEntity.ok(auditService.listForCurrentCompany());
    }

    @GetMapping("/{id}/pdf")
    @PreAuthorize(ROLES)
    @Operation(summary = "Audit-bejegyzés PDF-je a tárolt snapshotból (lekérdező + dátum a fejlécben)")
    public ResponseEntity<byte[]> pdf(@PathVariable UUID id) {
        byte[] body = pdfService.renderPdf(auditService.loadForPdf(id));
        String filename = "compliance_kereses_audit_" + id + ".pdf";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(body);
    }
}
