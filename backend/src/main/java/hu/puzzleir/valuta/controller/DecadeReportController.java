package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.dto.decade.GenerateDecadeReportDto;
import hu.puzzleir.valuta.service.DecadeReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Dekádjelentés REST végpontok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/decade-reports")
@RequiredArgsConstructor
public class DecadeReportController {

    private final DecadeReportService decadeReportService;

    @PostMapping("/generate")
    public ResponseEntity<DecadeReportDto> generate(@Valid @RequestBody GenerateDecadeReportDto dto) {
        return ResponseEntity.ok(
            decadeReportService.generateDecadeReport(dto.getBranchId(), dto.getYear(), dto.getDecade()));
    }

    @PostMapping("/{id}/close")
    public ResponseEntity<DecadeReportDto> close(@PathVariable UUID id) {
        return ResponseEntity.ok(decadeReportService.closeDecade(id));
    }

    @GetMapping
    public ResponseEntity<Page<DecadeReportDto>> list(
            @RequestParam UUID branchId,
            @RequestParam int year,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "36") int size) {
        return ResponseEntity.ok(decadeReportService.getDecadeReports(branchId, year, page, size));
    }
}
