package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.LiveCashPositionDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.LiveCashPositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * G9: Pillanatnyi pénztárállás (Delphi: PenztarAllas) — az aktuális iroda napi
 * valutánkénti NYITÓ/BEVÉTEL/KIADÁS/ZÁRÓ + kezelési-díj egyenlege egy nézetben.
 */
@RestController
@RequestMapping("/api/v1/reports/live-cash-position")
@RequiredArgsConstructor
public class LiveCashPositionController {

    private final LiveCashPositionService liveCashPositionService;

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LiveCashPositionDto> getLivePosition() {
        return ResponseEntity.ok(liveCashPositionService.getLivePosition(SecurityUtils.getCurrentBranchId()));
    }
}
