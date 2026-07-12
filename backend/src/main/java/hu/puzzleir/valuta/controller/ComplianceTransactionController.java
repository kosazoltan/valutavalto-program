package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.service.ComplianceTransactionExportService;
import hu.puzzleir.valuta.service.ComplianceTransactionSearchService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * FS-11 S1: cégszintű compliance tranzakció-kereső + export.
 * KÜLÖN endpoint a branch-scoped /api/v1/transactions-tól (B17 IDOR-hardening érintetlen).
 * Cég-scope a SecurityContextből a service-ben — a requestben SOHA nincs companyId.
 */
@RestController
@RequestMapping("/api/v1/compliance/transactions")
@RequiredArgsConstructor
public class ComplianceTransactionController {

    private static final String ROLES = "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','MANAGER','ADMIN',"
            + "'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO')";
    private static final DateTimeFormatter FILE_DATE = DateTimeFormatter.ISO_LOCAL_DATE;

    private final ComplianceTransactionSearchService searchService;
    private final ComplianceTransactionExportService exportService;

    @GetMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance tranzakció-kereső (cégszintű, lapozott)")
    public ResponseEntity<Page<ComplianceTransactionRowDto>> search(
            @ModelAttribute ComplianceTransactionSearchCriteria criteria,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(searchService.search(criteria, PageRequest.of(page, size)));
    }

    @GetMapping("/export/csv")
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance tranzakció-lista CSV export (UTF-8 BOM, ;)")
    public ResponseEntity<byte[]> exportCsv(@ModelAttribute ComplianceTransactionSearchCriteria criteria) {
        byte[] body = exportService.toCsv(searchService.searchForExport(criteria));
        String filename = "compliance_tranzakciok_" + LocalDate.now().format(FILE_DATE) + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(body);
    }

    @GetMapping("/export/xlsx")
    @PreAuthorize(ROLES)
    @Operation(summary = "Compliance tranzakció-lista XLSX export")
    public ResponseEntity<byte[]> exportXlsx(@ModelAttribute ComplianceTransactionSearchCriteria criteria) {
        byte[] body = exportService.toXlsx(searchService.searchForExport(criteria));
        String filename = "compliance_tranzakciok_" + LocalDate.now().format(FILE_DATE) + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(body);
    }
}
