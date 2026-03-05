package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.nav.*;
import hu.puzzleir.valuta.entity.NavClosing;
import hu.puzzleir.valuta.entity.NavClosingStatus;
import hu.puzzleir.valuta.entity.NavClosingType;
import hu.puzzleir.valuta.service.NavClosingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * NAV zárás controller — adóhatósági kötelezettség.
 */
@RestController
@RequestMapping("/api/v1/nav/closings")
@RequiredArgsConstructor
public class NavClosingController {

    private final NavClosingService navClosingService;

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
