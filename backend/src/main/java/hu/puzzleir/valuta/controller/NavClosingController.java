package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.nav.*;
import hu.puzzleir.valuta.entity.NavClosing;
import hu.puzzleir.valuta.entity.NavClosingStatus;
import hu.puzzleir.valuta.entity.NavClosingType;
import hu.puzzleir.valuta.service.NavAbevXmlGenerator;
import hu.puzzleir.valuta.service.NavClosingDiscrepancyService;
import hu.puzzleir.valuta.service.NavClosingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * NAV zárás controller — adóhatósági kötelezettség.
 */
@PreAuthorize("hasRole('ADMIN')")
@RestController
@RequestMapping("/api/v1/nav/closings")
@RequiredArgsConstructor
public class NavClosingController {

    private final NavClosingService navClosingService;
    private final NavAbevXmlGenerator navAbevXmlGenerator;
    private final NavClosingDiscrepancyService navClosingDiscrepancyService;

    /**
     * Napi NAV zárás létrehozása.
     * POST /api/v1/nav/closings/daily
     */
    @PostMapping("/daily")
    public ResponseEntity<NavClosingDto> createDailyClosing(
            @Valid @RequestBody CreateNavClosingDto request) {
        NavClosing closing = navClosingService.createDailyNavClosing(
            request.getBranchId(), request.getDate());
        return ResponseEntity.ok(toDto(closing));
    }

    /**
     * Zárások listázása.
     * GET /api/v1/nav/closings
     */
    @GetMapping
    public ResponseEntity<Page<NavClosingDto>> listClosings(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) NavClosingType closingType,
            @RequestParam(required = false) NavClosingStatus status,
            @RequestParam(required = false) LocalDate dateFrom,
            @RequestParam(required = false) LocalDate dateTo,
            Pageable pageable) {

        Page<NavClosing> page = navClosingService.listClosings(
            branchId, closingType, status, dateFrom, dateTo, pageable);

        return ResponseEntity.ok(page.map(this::toDto));
    }

    /**
     * NAV zárás beküldése.
     * POST /api/v1/nav/closings/{id}/submit
     */
    @PostMapping("/{id}/submit")
    public ResponseEntity<NavSubmissionResult> submitClosing(@PathVariable UUID id) {
        NavSubmissionResult result = navClosingService.submitToNav(id);
        return ResponseEntity.ok(result);
    }

    /**
     * Napi összesítő lekérése.
     * GET /api/v1/nav/closings/{id}/summary
     */
    @GetMapping("/{id}/summary")
    public ResponseEntity<NavClosingSummaryDto> getClosingSummary(@PathVariable UUID id) {
        NavClosing closing = navClosingService.getClosingById(id);
        NavClosingSummaryDto summary = navClosingService.getDailyClosingSummary(
            closing.getBranch().getId(), closing.getClosingDate());
        return ResponseEntity.ok(summary);
    }

    // ============ ABEV XML GENERÁLÁS ============

    /**
     * Havi PTGSZLAH XML generálása (NAV adatszolgáltatás).
     * GET /api/v1/nav/closings/ptgszlah/monthly?year=2026&month=3
     *
     * Legacy: excold-exclusive-nav-data-provider-server / CompanyXMLGenerator.java
     */
    @GetMapping(value = "/ptgszlah/monthly", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<byte[]> generateMonthlyPtgszlah(
            @RequestParam int year, @RequestParam int month) {
        String xml = navAbevXmlGenerator.generateMonthlyPtgszlah(year, month);
        byte[] bytes = xml.getBytes(StandardCharsets.UTF_8);

        String filename = String.format("PTGSZLAH_%d_%02d.xml", year, month);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_XML)
                .body(bytes);
    }

    /**
     * Egyedi időszakra PTGSZLAH XML generálása.
     * GET /api/v1/nav/closings/ptgszlah/custom?from=2026-01-01&to=2026-03-15
     */
    @GetMapping(value = "/ptgszlah/custom", produces = MediaType.APPLICATION_XML_VALUE)
    public ResponseEntity<byte[]> generateCustomPtgszlah(
            @RequestParam LocalDate from, @RequestParam LocalDate to) {
        String xml = navAbevXmlGenerator.generateCustomPtgszlah(from, to);
        byte[] bytes = xml.getBytes(StandardCharsets.UTF_8);

        String filename = String.format("PTGSZLAH_%s_%s.xml", from, to);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_XML)
                .body(bytes);
    }

    // ============ NAV ZÁRÁS ELTÉRÉS-KEZELÉS ============

    /**
     * NAV záró összeg validálása.
     * POST /api/v1/nav/closings/validate-amount
     *
     * Legacy: NAVZARO.DLL — a pénztáros beüti a NAV pénztárgép záró összegét,
     * a rendszer összehasonlítja a nyilvántartás szerinti értékkel.
     */
    @PostMapping("/validate-amount")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR', 'MANAGER', 'CASHIER')")
    public ResponseEntity<NavClosingDiscrepancyService.NavClosingValidationResult> validateNavAmount(
            @RequestParam UUID branchId,
            @RequestParam LocalDate date,
            @RequestParam BigDecimal navAmount) {
        NavClosingDiscrepancyService.NavClosingValidationResult result =
                navClosingDiscrepancyService.validateNavClosingAmount(branchId, date, navAmount);
        return ResponseEntity.ok(result);
    }

    /**
     * NAV zárás eltérés jóváhagyása indoklással.
     * POST /api/v1/nav/closings/{id}/approve-discrepancy
     *
     * Eltérés esetén kötelező: legalább 20 karakteres indoklás.
     * Automatikus értesítés megy a területi vezetőnek.
     */
    @PostMapping("/{id}/approve-discrepancy")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR', 'MANAGER')")
    public ResponseEntity<Void> approveDiscrepancy(
            @PathVariable UUID id,
            @RequestParam BigDecimal navAmount,
            @RequestParam String justification) {
        navClosingDiscrepancyService.approveDiscrepancy(id, navAmount, justification);
        return ResponseEntity.ok().build();
    }

    // ============ DTO KONVERZIÓ ============

    private NavClosingDto toDto(NavClosing closing) {
        return NavClosingDto.builder()
            .id(closing.getId())
            .closingDate(closing.getClosingDate())
            .branchId(closing.getBranch() != null ? closing.getBranch().getId() : null)
            .closingType(closing.getClosingType().name())
            .totalRevenue(closing.getTotalRevenue())
            .totalExpense(closing.getTotalExpense())
            .handlingFeeTotal(closing.getHandlingFeeTotal())
            .vatAmount(closing.getVatAmount())
            .status(closing.getStatus().name())
            .navReferenceNumber(closing.getNavReferenceNumber())
            .closedById(closing.getClosedBy() != null ? closing.getClosedBy().getId() : null)
            .closedAt(closing.getClosedAt())
            .lines(closing.getLines() != null
                ? closing.getLines().stream().map(this::toLineDto).collect(Collectors.toList())
                : null)
            .createdAt(closing.getCreatedAt())
            .build();
    }

    private NavClosingLineDto toLineDto(hu.puzzleir.valuta.entity.NavClosingLine line) {
        return NavClosingLineDto.builder()
            .id(line.getId())
            .currencyCode(line.getCurrencyCode())
            .buyAmount(line.getBuyAmount())
            .sellAmount(line.getSellAmount())
            .buyHuf(line.getBuyHuf())
            .sellHuf(line.getSellHuf())
            .handlingFee(line.getHandlingFee())
            .transactionCount(line.getTransactionCount())
            .build();
    }
}
