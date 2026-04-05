package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.YearOpeningService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Év-nyitó workflow controller.
 *
 * Legacy: evnyito/unit1.pas + newyear/unit1.pas
 * Csak ADMIN futtathatja.
 */
@RestController
@RequestMapping("/api/v1/year-opening")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Slf4j
public class YearOpeningController {

    private final YearOpeningService yearOpeningService;

    /**
     * Év-nyitó workflow végrehajtása.
     * POST /api/v1/year-opening/execute?targetYear=2027
     *
     * FONTOS: Ez egy DESTRUKTÍV művelet (sorszámok nullázása, archiválás).
     * Csak ADMIN jogosultsággal, évenként egyszer futtatható.
     */
    @PostMapping("/execute")
    public ResponseEntity<Map<String, Object>> executeYearOpening(
            @RequestParam int targetYear) {
        log.info("Év-nyitó kérés: targetYear={}", targetYear);
        Map<String, Object> result = yearOpeningService.executeYearOpening(targetYear);
        return ResponseEntity.ok(result);
    }

    /**
     * Év-nyitó állapot: utolsó futás, futtathatóság.
     * GET /api/v1/year-opening/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        Map<String, Object> status = yearOpeningService.getLastExecution();
        return ResponseEntity.ok(status);
    }
}
