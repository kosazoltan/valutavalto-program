package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.denomination.DenominationDto;
import hu.puzzleir.valuta.dto.denomination.UpdateDenominationDto;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.mapper.DenominationMapper;
import hu.puzzleir.valuta.service.DenominationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Címletezés controller
 *
 * Legacy: CIMLET tábla kezelés - napi zárás címletvalidálás
 */
@RestController
@RequestMapping("/api/v1/denominations")
@RequiredArgsConstructor
public class DenominationController {

    private final DenominationService denominationService;
    private final DenominationMapper denominationMapper;

    /**
     * Címletek valuta ID alapján
     *
     * GET /api/v1/denominations/currency/{currencyId}
     */
    @GetMapping("/currency/{currencyId}")
    public ResponseEntity<List<DenominationDto>> getDenominationsByCurrency(@PathVariable Long currencyId) {
        List<Denomination> denominations = denominationService.getDenominations(currencyId);
        List<DenominationDto> dtos = denominations.stream()
                .map(denominationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Címletek valuta kód alapján
     *
     * GET /api/v1/denominations/code/{currencyCode}
     */
    @GetMapping("/code/{currencyCode}")
    public ResponseEntity<List<DenominationDto>> getDenominationsByCurrencyCode(@PathVariable String currencyCode) {
        List<Denomination> denominations = denominationService.getDenominationsByCurrencyCode(currencyCode.toUpperCase());
        List<DenominationDto> dtos = denominations.stream()
                .map(denominationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Összes címlet az aktuális irodához
     *
     * GET /api/v1/denominations
     */
    @GetMapping
    public ResponseEntity<List<DenominationDto>> getAllBranchDenominations() {
        List<Denomination> denominations = denominationService.getAllBranchDenominations();
        List<DenominationDto> dtos = denominations.stream()
                .map(denominationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Alacsony készlet figyelmeztetések
     *
     * GET /api/v1/denominations/alerts/low-stock
     */
    @GetMapping("/alerts/low-stock")
    public ResponseEntity<List<DenominationDto>> getLowStockAlerts() {
        List<Denomination> denominations = denominationService.getLowStockAlerts();
        List<DenominationDto> dtos = denominations.stream()
                .map(denominationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Címlet darabszám frissítése
     *
     * PUT /api/v1/denominations
     */
    @PutMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DenominationDto> updateDenomination(@Valid @RequestBody UpdateDenominationDto dto) {
        Denomination denomination = denominationService.updateDenominationQuantity(
                denominationMapper.toServiceRequest(dto));
        return ResponseEntity.ok(denominationMapper.toDto(denomination));
    }

    /**
     * Tömeges címlet frissítés (napi zárás)
     *
     * PUT /api/v1/denominations/bulk
     */
    @PutMapping("/bulk")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<DenominationDto>> bulkUpdateDenominations(
            @Valid @RequestBody List<UpdateDenominationDto> dtos) {
        List<DenominationService.UpdateDenominationRequest> requests = dtos.stream()
                .map(denominationMapper::toServiceRequest)
                .collect(Collectors.toList());
        List<Denomination> updated = denominationService.bulkUpdateDenominations(requests);
        List<DenominationDto> result = updated.stream()
                .map(denominationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    /**
     * Címletezés validálás (napi záráshoz)
     *
     * POST /api/v1/denominations/validate?currencyId=...&expectedBalance=...
     */
    @PostMapping("/validate")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DenominationService.DenominationValidationResult> validateDenomination(
            @RequestParam Long currencyId,
            @RequestParam BigDecimal expectedBalance) {
        DenominationService.DenominationValidationResult result =
                denominationService.validateDenomination(currencyId, expectedBalance);
        return ResponseEntity.ok(result);
    }

    /**
     * Címletezés összesítő
     *
     * GET /api/v1/denominations/summary/{currencyId}
     */
    @GetMapping("/summary/{currencyId}")
    public ResponseEntity<DenominationService.DenominationSummary> getDenominationSummary(
            @PathVariable Long currencyId) {
        DenominationService.DenominationSummary summary = denominationService.getDenominationSummary(currencyId);
        return ResponseEntity.ok(summary);
    }

    /**
     * Optimális visszajáró számítás
     *
     * GET /api/v1/denominations/optimal-change?currencyId=...&amount=...
     */
    @GetMapping("/optimal-change")
    public ResponseEntity<Map<BigDecimal, Integer>> calculateOptimalChange(
            @RequestParam Long currencyId,
            @RequestParam BigDecimal amount) {
        Map<BigDecimal, Integer> change = denominationService.calculateOptimalChange(currencyId, amount);
        return ResponseEntity.ok(change);
    }
}
