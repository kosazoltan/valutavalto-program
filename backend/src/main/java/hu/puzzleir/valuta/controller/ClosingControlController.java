package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.AlertRequestDto;
import hu.puzzleir.valuta.dto.ClosingControlDto;
import hu.puzzleir.valuta.dto.ClosingMarkDoneRequestDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.ClosingControlService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/closing-control")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("isAuthenticated()")
public class ClosingControlController {

    private final ClosingControlService closingControlService;

    /**
     * GET /api/v1/closing-control/status — Összes iroda zárási állapota
     */
    @GetMapping("/status")
    public ResponseEntity<List<ClosingControlDto>> getAllStatus(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("GET /api/v1/closing-control/status");
        LocalDate controlDate = date != null ? date : LocalDate.now();
        List<ClosingControlDto> result = closingControlService.checkAllBranches(controlDate);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/v1/closing-control/branch/{id} — Egy iroda zárási állapota
     */
    @GetMapping("/branch/{id}")
    public ResponseEntity<ClosingControlDto> getBranchStatus(
            @PathVariable UUID id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("GET /api/v1/closing-control/branch/{}", id);
        LocalDate controlDate = date != null ? date : LocalDate.now();
        ClosingControlDto result = closingControlService.getBranchStatus(id, controlDate);
        return ResponseEntity.ok(result);
    }

    /**
     * POST /api/v1/closing-control/alert — Figyelmeztetés küldése
     */
    @PostMapping("/alert")
    public ResponseEntity<Void> sendAlert(@Valid @RequestBody AlertRequestDto dto) {
        log.info("POST /api/v1/closing-control/alert - branch: {}", dto.getBranchId());
        closingControlService.sendAlert(dto.getBranchId(), dto.getMessage());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/v1/closing-control/mark-done — ideiglenes admin/teszt zárásjelzés.
     */
    @PostMapping("/mark-done")
    @PreAuthorize("hasRole('FOERTEKTAR')")
    public ResponseEntity<ClosingControlDto> markDone(@Valid @RequestBody ClosingMarkDoneRequestDto dto) {
        log.info("POST /api/v1/closing-control/mark-done - branch: {}, type: {}", dto.getBranchId(), dto.getType());
        return ResponseEntity.ok(closingControlService.markClosingDone(
                SecurityUtils.getCurrentCompanyId(),
                dto.getBranchId(),
                dto.getDate(),
                dto.getType()));
    }
}
