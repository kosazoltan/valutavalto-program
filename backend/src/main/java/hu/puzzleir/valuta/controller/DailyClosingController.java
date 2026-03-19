package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.DailyClosingService;
import hu.puzzleir.valuta.service.DailyClosingService.ClosingWizardResult;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Napzarasi vegrehajtasi controller.
 *
 * Exponalja a DailyClosingService 9 lepepes belso ellenorzesi lancot,
 * amit a ClosingWizardPage frontend hiv a zaras tenyleges vegrehajtasahoz.
 *
 * Legacy: NAPZAR.DLL + CIMLCTRL.DLL
 */
@RestController
@RequestMapping("/api/v1/daily-closing")
@RequiredArgsConstructor
public class DailyClosingController {

    private final DailyClosingService dailyClosingService;

    /**
     * Napzaras vegrehajtasa: elinditja a 9 lepepes ellenorzesi lancot,
     * es ha minden PASS, vegrehajtja a tenyleges zarast.
     *
     * POST /api/v1/daily-closing/execute?date=2024-01-15
     */
    @PostMapping("/execute")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardResult> executeDailyClosing(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        ClosingWizardResult result = dailyClosingService.startDailyClosing(date);
        return ResponseEntity.ok(result);
    }
}
