package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.SuspiciousCustomerDto;
import hu.puzzleir.valuta.service.SuspiciousCustomerExportService;
import hu.puzzleir.valuta.service.SuspiciousCustomerService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * FS-12: gyanús ügyfél lekérdezés (3 minta) + hatályos értéksávot elért ügyfelek XLSX exportja.
 * Cég-scope a SecurityContextből a service-ben — a requestben SOHA nincs companyId.
 */
@RestController
@RequestMapping("/api/v1/compliance/suspicious-customers")
@RequiredArgsConstructor
public class SuspiciousCustomerController {

    private static final String ROLES = "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','MANAGER','ADMIN')";
    private static final DateTimeFormatter FILE_DATE = DateTimeFormatter.ISO_LOCAL_DATE;

    private final SuspiciousCustomerService suspiciousCustomerService;
    private final SuspiciousCustomerExportService exportService;

    @GetMapping
    @PreAuthorize(ROLES)
    @Operation(summary = "Gyanús ügyfelek (3 minta, cégszintű, lapozott)")
    public ResponseEntity<Page<SuspiciousCustomerDto>> search(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "true") boolean byTransactionCount,
            @RequestParam(required = false) Integer minTransactionCount,
            @RequestParam(defaultValue = "true") boolean byTotalValue,
            @RequestParam(required = false) BigDecimal minTotalHuf,
            @RequestParam(defaultValue = "true") boolean byBranchCount,
            @RequestParam(required = false) Integer minBranchCount,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(suspiciousCustomerService.search(
                startDate, endDate, byTransactionCount, minTransactionCount,
                byTotalValue, minTotalHuf, byBranchCount, minBranchCount,
                PageRequest.of(page, size)));
    }

    @GetMapping("/export/xlsx")
    @PreAuthorize(ROLES)
    @Operation(summary = "Hatályos értéksávot elért ügyfelek XLSX exportja")
    public ResponseEntity<byte[]> exportXlsx(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        byte[] body = exportService.toXlsx(
                suspiciousCustomerService.listValueBandReachedForExport(startDate, endDate));
        String filename = "gyanus_ugyfelek_ertekhatart_elertek_" + LocalDate.now().format(FILE_DATE) + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(body);
    }
}
