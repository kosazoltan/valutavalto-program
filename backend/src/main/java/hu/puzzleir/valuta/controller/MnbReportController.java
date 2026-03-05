package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.mnb.*;
import hu.puzzleir.valuta.entity.MnbReport;
import hu.puzzleir.valuta.entity.MnbReportStatus;
import hu.puzzleir.valuta.entity.MnbReportType;
import hu.puzzleir.valuta.service.MnbReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * MNB adatszolgáltatás controller.
 *
 * JOGSZABÁLYI KÖTELEZETTSÉG — kötelező MNB riportok kezelése.
 */
@RestController
@RequestMapping("/api/v1/mnb/reports")
@RequiredArgsConstructor
public class MnbReportController {

    private final MnbReportService mnbReportService;

    /**
     * MNB riport generálása.
     * POST /api/v1/mnb/reports/generate
     */
    @PostMapping("/generate")
    public ResponseEntity<MnbReportDto> generateReport(@Valid @RequestBody GenerateMnbReportDto request) {
        MnbReport report;

        String type = request.getReportType();
        if ("MONTHLY".equalsIgnoreCase(type)) {
            YearMonth month = YearMonth.from(request.getDate());
            report = mnbReportService.generateMonthlyReport(request.getBranchId(), month);
        } else {
            report = mnbReportService.generateDailyReport(request.getBranchId(), request.getDate());
        }

        return ResponseEntity.ok(toDto(report));
    }

    /**
     * Riportok listázása.
     * GET /api/v1/mnb/reports
     */
    @GetMapping
    public ResponseEntity<Page<MnbReportDto>> listReports(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) MnbReportType reportType,
            @RequestParam(required = false) MnbReportStatus status,
            @RequestParam(required = false) LocalDate dateFrom,
            @RequestParam(required = false) LocalDate dateTo,
            Pageable pageable) {

        Page<MnbReport> page = mnbReportService.listReports(
            branchId, reportType, status, dateFrom, dateTo, pageable);

        return ResponseEntity.ok(page.map(this::toDto));
    }

    /**
     * Riport részleteinek lekérése.
     * GET /api/v1/mnb/reports/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<MnbReportDto> getReport(@PathVariable UUID id) {
        MnbReport report = mnbReportService.getReportStatus(id);
        return ResponseEntity.ok(toDto(report));
    }

    /**
     * Riport beküldése az MNB-nek.
     * POST /api/v1/mnb/reports/{id}/submit
     */
    @PostMapping("/{id}/submit")
    public ResponseEntity<MnbSubmissionResult> submitReport(@PathVariable UUID id) {
        MnbSubmissionResult result = mnbReportService.submitReport(id);
        return ResponseEntity.ok(result);
    }

    /**
     * XML letöltése.
     * GET /api/v1/mnb/reports/{id}/xml
     */
    @GetMapping("/{id}/xml")
    public ResponseEntity<String> downloadXml(@PathVariable UUID id) {
        MnbReport report = mnbReportService.getReportStatus(id);
        String xml = report.getXmlContent();

        if (xml == null || xml.isBlank()) {
            return ResponseEntity.noContent().build();
        }

        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=mnb_report_" + report.getReportDate() + ".xml")
            .contentType(MediaType.APPLICATION_XML)
            .body(xml);
    }

    // ============ DTO KONVERZIÓ ============

    private MnbReportDto toDto(MnbReport report) {
        return MnbReportDto.builder()
            .id(report.getId())
            .reportType(report.getReportType().name())
            .reportDate(report.getReportDate())
            .status(report.getStatus().name())
            .branchId(report.getBranch() != null ? report.getBranch().getId() : null)
            .totalBuyHuf(report.getTotalBuyHuf())
            .totalSellHuf(report.getTotalSellHuf())
            .totalTransactions(report.getTotalTransactions())
            .submittedAt(report.getSubmittedAt())
            .acceptedAt(report.getAcceptedAt())
            .rejectionReason(report.getRejectionReason())
            .lines(report.getLines() != null
                ? report.getLines().stream().map(this::toLineDto).collect(Collectors.toList())
                : null)
            .createdAt(report.getCreatedAt())
            .build();
    }

    private MnbReportLineDto toLineDto(hu.puzzleir.valuta.entity.MnbReportLine line) {
        return MnbReportLineDto.builder()
            .id(line.getId())
            .currencyCode(line.getCurrencyCode())
            .buyAmount(line.getBuyAmount())
            .sellAmount(line.getSellAmount())
            .buyRate(line.getBuyRate())
            .sellRate(line.getSellRate())
            .transactionCount(line.getTransactionCount())
            .build();
    }
}
