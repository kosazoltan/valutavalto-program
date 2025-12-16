package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashbalance.AdjustBalanceDto;
import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.service.CashBalanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Kassza egyenleg controller
 *
 * Legacy: PENZTAR, PILLALL funkciók
 */
@RestController
@RequestMapping("/api/v1/cash-balances")
@RequiredArgsConstructor
public class CashBalanceController {

    private final CashBalanceService cashBalanceService;
    private final CashBalanceMapper cashBalanceMapper;

    /**
     * Aktuális iroda egyenlegei
     *
     * GET /api/v1/cash-balances
     */
    @GetMapping
    public ResponseEntity<List<CashBalanceDto>> getCurrentBranchBalances() {
        List<CashBalance> balances = cashBalanceService.getCurrentBranchBalances();
        List<CashBalanceDto> dtos = balances.stream()
                .map(cashBalanceMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Egyenleg valuta ID alapján
     *
     * GET /api/v1/cash-balances/currency/{currencyId}
     */
    @GetMapping("/currency/{currencyId}")
    public ResponseEntity<CashBalanceDto> getBalanceByCurrency(@PathVariable Long currencyId) {
        CashBalance balance = cashBalanceService.getBalanceByCurrency(currencyId);
        return ResponseEntity.ok(cashBalanceMapper.toDto(balance));
    }

    /**
     * Egyenleg valuta kód alapján
     *
     * GET /api/v1/cash-balances/code/{currencyCode}
     */
    @GetMapping("/code/{currencyCode}")
    public ResponseEntity<CashBalanceDto> getBalanceByCurrencyCode(@PathVariable String currencyCode) {
        CashBalance balance = cashBalanceService.getBalanceByCurrencyCode(currencyCode);
        return ResponseEntity.ok(cashBalanceMapper.toDto(balance));
    }

    /**
     * Cég összes egyenlege (minden iroda)
     *
     * GET /api/v1/cash-balances/company
     */
    @GetMapping("/company")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashBalanceDto>> getCompanyBalances() {
        List<CashBalance> balances = cashBalanceService.getCompanyBalances();
        List<CashBalanceDto> dtos = balances.stream()
                .map(cashBalanceMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Alacsony készlet figyelmeztetések
     *
     * GET /api/v1/cash-balances/alerts/low
     */
    @GetMapping("/alerts/low")
    public ResponseEntity<List<CashBalanceDto>> getLowBalanceAlerts() {
        List<CashBalance> balances = cashBalanceService.getLowBalanceAlerts();
        List<CashBalanceDto> dtos = balances.stream()
                .map(cashBalanceMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Magas készlet figyelmeztetések
     *
     * GET /api/v1/cash-balances/alerts/high
     */
    @GetMapping("/alerts/high")
    public ResponseEntity<List<CashBalanceDto>> getHighBalanceAlerts() {
        List<CashBalance> balances = cashBalanceService.getHighBalanceAlerts();
        List<CashBalanceDto> dtos = balances.stream()
                .map(cashBalanceMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Egyenleg kézi módosítása (feltöltés/levétel)
     *
     * POST /api/v1/cash-balances/adjust
     *
     * Csak MANAGER, ADMIN
     */
    @PostMapping("/adjust")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CashBalanceDto> adjustBalance(@Valid @RequestBody AdjustBalanceDto dto) {
        CashBalance balance = cashBalanceService.adjustBalance(cashBalanceMapper.toServiceRequest(dto));
        return ResponseEntity.ok(cashBalanceMapper.toDto(balance));
    }

    /**
     * Iroda összesítés
     *
     * GET /api/v1/cash-balances/summary
     */
    @GetMapping("/summary")
    public ResponseEntity<CashBalanceService.BranchBalanceSummary> getBranchSummary() {
        CashBalanceService.BranchBalanceSummary summary = cashBalanceService.getBranchSummary();
        return ResponseEntity.ok(summary);
    }

    /**
     * Cég szintű összesítés valutánként
     *
     * GET /api/v1/cash-balances/company-totals
     */
    @GetMapping("/company-totals")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashBalanceService.CurrencyTotalBalance>> getCompanyTotals() {
        List<CashBalanceService.CurrencyTotalBalance> totals = cashBalanceService.getCompanyTotals();
        return ResponseEntity.ok(totals);
    }
}
