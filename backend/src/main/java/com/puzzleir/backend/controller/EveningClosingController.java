package com.puzzleir.backend.controller;

import com.puzzleir.backend.dto.EveningClosingDto;
import com.puzzleir.backend.service.EveningClosingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/evening-closing")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class EveningClosingController {

    private final EveningClosingService eveningClosingService;

    // TODO: companyId a JWT-ből
    private static final UUID TEMP_COMPANY_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

    /**
     * POST /api/v1/evening-closing/prepare — Esti zárás előkészítése
     */
    @PostMapping("/prepare")
    public ResponseEntity<EveningClosingDto> prepare(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("POST /api/v1/evening-closing/prepare - branch: {}", branchId);
        LocalDate closingDate = date != null ? date : LocalDate.now();
        EveningClosingDto result = eveningClosingService.prepareEvening(TEMP_COMPANY_ID, branchId, closingDate);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * POST /api/v1/evening-closing/{id}/send — Csomag küldése
     */
    @PostMapping("/{id}/send")
    public ResponseEntity<EveningClosingDto> send(@PathVariable UUID id) {
        log.info("POST /api/v1/evening-closing/{}/send", id);
        EveningClosingDto result = eveningClosingService.sendPackage(id);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/v1/evening-closing/status — Esti zárás állapot
     */
    @GetMapping("/status")
    public ResponseEntity<EveningClosingDto> getStatus(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("GET /api/v1/evening-closing/status - branch: {}", branchId);
        LocalDate closingDate = date != null ? date : LocalDate.now();
        EveningClosingDto result = eveningClosingService.getEveningStatus(branchId, closingDate);
        return ResponseEntity.ok(result);
    }
}
