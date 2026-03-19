package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.eveningclosing.*;
import hu.puzzleir.valuta.service.EveningClosingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Esti zárás REST controller.
 *
 * Legacy: Delphi ESTIZAR modul → FTP-n bináris csomag.
 * Modern: REST API — JSON adatcsomag küldés a központnak.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/evening-closing")
@RequiredArgsConstructor
@Slf4j
public class EveningClosingController {

    private final EveningClosingService eveningClosingService;

    /**
     * Napi adatcsomag előkészítése (preview — nem küld).
     */
    @GetMapping("/{branchId}/{date}/preview")
    public ResponseEntity<DailyDataPackage> previewPackage(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("Esti zárás preview: branchId={}, datum={}", branchId, date);
        DailyDataPackage pkg = eveningClosingService.prepareDailyPackage(branchId, date);
        return ResponseEntity.ok(pkg);
    }

    /**
     * Napi adatcsomag összeállítása és küldése a központnak.
     *
     * POST /api/evening-closing/{branchId}/{date}/send
     */
    @PostMapping("/{branchId}/{date}/send")
    public ResponseEntity<DataSyncResult> sendPackage(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("Esti zárás küldés: branchId={}, datum={}", branchId, date);

        DailyDataPackage pkg = eveningClosingService.prepareDailyPackage(branchId, date);
        DataSyncResult result = eveningClosingService.sendToHeadquarters(pkg);

        if (result.isSuccess()) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.internalServerError().body(result);
        }
    }

    /**
     * Napi jelentés lekérése (forgalom összesítő + valutanem bontás).
     */
    @GetMapping("/{branchId}/{date}/report")
    public ResponseEntity<hu.puzzleir.valuta.dto.eveningclosing.DailyReport> getDailyReport(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("Napi jelentés lekérés: branchId={}, datum={}", branchId, date);
        hu.puzzleir.valuta.dto.eveningclosing.DailyReport report =
                eveningClosingService.generateDailyReport(branchId, date);
        return ResponseEntity.ok(report);
    }
}
