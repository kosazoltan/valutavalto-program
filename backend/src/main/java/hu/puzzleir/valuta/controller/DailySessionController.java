package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.dailysession.DailySessionDto;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.mapper.DailySessionMapper;
import hu.puzzleir.valuta.service.DailySessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Napi session controller - nyitás/zárás
 *
 * Legacy: NAPIKEZD, NAPZAR funkciók
 */
@RestController
@RequestMapping("/api/v1/daily-sessions")
@RequiredArgsConstructor
public class DailySessionController {

    private final DailySessionService dailySessionService;
    private final DailySessionMapper dailySessionMapper;

    /**
     * Napi nyitás
     *
     * POST /api/v1/daily-sessions/open
     */
    @PostMapping("/open")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailySessionDto> openDay() {
        DailySession session = dailySessionService.openDay();
        return ResponseEntity.status(HttpStatus.CREATED).body(dailySessionMapper.toDto(session));
    }

    /**
     * Napi zárás
     *
     * POST /api/v1/daily-sessions/close?denominationVerified=true
     */
    @PostMapping("/close")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailySessionDto> closeDay(
            @RequestParam(defaultValue = "false") boolean denominationVerified) {
        DailySession session = dailySessionService.closeDay(denominationVerified);
        return ResponseEntity.ok(dailySessionMapper.toDto(session));
    }

    /**
     * Napi zárás (POS kliens kompatibilis path sessionId-val)
     *
     * POST /api/v1/daily-sessions/{sessionId}/close
     */
    @PostMapping("/{sessionId}/close")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailySessionDto> closeDayById(
            @PathVariable Long sessionId,
            @RequestParam(defaultValue = "false") boolean denominationVerified) {
        DailySession session = dailySessionService.closeDay(denominationVerified);
        return ResponseEntity.ok(dailySessionMapper.toDto(session));
    }

    /**
     * Aktuális session lekérdezése
     *
     * GET /api/v1/daily-sessions/current
     */
    @GetMapping("/current")
    public ResponseEntity<DailySessionDto> getCurrentSession() {
        DailySession session = dailySessionService.getCurrentSession();
        return ResponseEntity.ok(dailySessionMapper.toDto(session));
    }

    /**
     * Van-e nyitott session?
     *
     * GET /api/v1/daily-sessions/is-open
     */
    @GetMapping("/is-open")
    public ResponseEntity<Boolean> hasOpenSession() {
        boolean hasOpen = dailySessionService.hasOpenSession();
        return ResponseEntity.ok(hasOpen);
    }

    /**
     * Napi sztornó számláló
     *
     * GET /api/v1/daily-sessions/reversal-count
     */
    @GetMapping("/reversal-count")
    public ResponseEntity<Integer> getReversalCount() {
        int count = dailySessionService.getDailyReversalCount();
        return ResponseEntity.ok(count);
    }

    /**
     * Session történet
     *
     * GET /api/v1/daily-sessions/history?startDate=...&endDate=...
     */
    // FK-005/A1 (HIBA 2026-05-26): az értéktári Dashboard „Zárási állapot" csempéje ezt hívja —
    // az értéktár-vezetői role-ok (UGYVEZETO/FOERTEKTAR/ERTEKTAR) is láthatják a zárás-állapotot.
    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'UGYVEZETO', 'FOERTEKTAR', 'ERTEKTAR')")
    public ResponseEntity<List<DailySessionDto>> getSessionHistory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<DailySession> sessions = dailySessionService.getSessionHistory(startDate, endDate);
        List<DailySessionDto> dtos = sessions.stream()
                .map(dailySessionMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Napi zárás validáció - címletezések ellenőrzése
     *
     * GET /api/v1/daily-sessions/validate-closing
     *
     * Legacy: NapzarControl - 5 típus ellenőrzés
     */
    @GetMapping("/validate-closing")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailySessionService.DailyClosingValidation> validateDailyClosing() {
        DailySessionService.DailyClosingValidation validation = dailySessionService.validateDailyClosing();
        return ResponseEntity.ok(validation);
    }

    /**
     * Napi zárás végrehajtása teljes validációval
     *
     * POST /api/v1/daily-sessions/close-with-validation
     *
     * Legacy: NAPZAR - teljes napi zárás validációkkal
     */
    @PostMapping("/close-with-validation")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailySessionDto> closeDayWithValidation() {
        DailySession session = dailySessionService.closeDayWithValidation();
        return ResponseEntity.ok(dailySessionMapper.toDto(session));
    }
}
