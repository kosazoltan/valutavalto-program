package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratecreation.BankRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.CompetitorRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.service.RateCreationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Árfolyam-készítés controller.
 * Bank és versenytárs árfolyamok kezelése, tervezet generálás, csoportos publikálás.
 */
@RestController
@RequestMapping("/api/v1/rate-creation")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
public class RateCreationController {

    private final RateCreationService rateCreationService;

    /**
     * Bank árfolyamok lekérése.
     * GET /api/v1/rate-creation/bank-rates
     */
    @GetMapping("/bank-rates")
    public ResponseEntity<List<BankRateDTO>> getBankRates() {
        return ResponseEntity.ok(rateCreationService.getBankRates());
    }

    /**
     * Versenytárs árfolyamok lekérése.
     * GET /api/v1/rate-creation/competitor-rates
     */
    @GetMapping("/competitor-rates")
    public ResponseEntity<List<CompetitorRateDTO>> getCompetitorRates() {
        return ResponseEntity.ok(rateCreationService.getCompetitorRates());
    }

    /**
     * Árfolyam tervezet generálás — MNB + bank ráták alapján margin számolás.
     * POST /api/v1/rate-creation/prepare/all
     */
    @PostMapping("/prepare/all")
    public ResponseEntity<Map<String, Object>> prepareAllRates() {
        return ResponseEntity.ok(rateCreationService.prepareAllRates());
    }

    /**
     * Csoportos árfolyam publikálás.
     * POST /api/v1/rate-creation/publish-group-rate
     */
    @PostMapping("/publish-group-rate")
    public ResponseEntity<Void> publishGroupRate(@Valid @RequestBody GroupRateDTO groupRateDTO) {
        rateCreationService.publishGroupRate(groupRateDTO);
        return ResponseEntity.ok().build();
    }
}
