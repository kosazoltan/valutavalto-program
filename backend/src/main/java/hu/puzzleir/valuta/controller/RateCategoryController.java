package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratecategory.CreateRateCategoryDto;
import hu.puzzleir.valuta.dto.ratecategory.RateCategoryDto;
import hu.puzzleir.valuta.service.RateCategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Árfolyam kategória REST végpontok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/rate-categories")
@RequiredArgsConstructor
public class RateCategoryController {

    private final RateCategoryService rateCategoryService;

    @GetMapping
    public ResponseEntity<RateCategoryDto> getForAmount(
            @RequestParam UUID branchId,
            @RequestParam String currency,
            @RequestParam BigDecimal amount) {
        return ResponseEntity.ok(rateCategoryService.getRateForAmount(branchId, currency, amount));
    }

    @GetMapping("/all")
    public ResponseEntity<List<RateCategoryDto>> getAll(@RequestParam UUID branchId) {
        return ResponseEntity.ok(rateCategoryService.getAll(branchId));
    }

    @PostMapping
    public ResponseEntity<RateCategoryDto> create(@Valid @RequestBody CreateRateCategoryDto dto) {
        return ResponseEntity.ok(rateCategoryService.setRateCategory(dto));
    }
}
