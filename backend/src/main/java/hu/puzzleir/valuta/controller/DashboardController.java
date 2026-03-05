package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.dashboard.DashboardSummaryDto;
import hu.puzzleir.valuta.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Dashboard controller — admin összesítő.
 */
@RestController
@RequestMapping("/api/v1/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService service;

    @GetMapping("/summary")
    public ResponseEntity<DashboardSummaryDto> getSummary(@RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.getSummary(branchId));
    }
}
