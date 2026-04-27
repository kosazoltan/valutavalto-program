package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashbalance.AdjustBalanceDto;
import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.service.CashBalanceService;
import hu.puzzleir.valuta.util.OptimisticLockRetry;
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
@PreAuthorize("isAuthenticated()") // v2.3.1 audit: class-level baseline (defense-in-depth)
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
        CashBalance balance = OptimisticLockRetry.execute(
                () -> cashBalanceService.adjustBalance(cashBalanceMapper.toServiceRequest(dto)),
                "adjustBalance");
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

    /**
     * Részletes pillanat állás HUF egyenértékekkel
     *
     * GET /api/v1/cash-balances/position
     *
     * Legacy: PILLALL - pillanat állás részletes
     */
    @GetMapping("/position")
    public ResponseEntity<CashBalanceService.DetailedCashPosition> getDetailedCashPosition() {
        CashBalanceService.DetailedCashPosition position = cashBalanceService.getDetailedCashPosition();
        return ResponseEntity.ok(position);
    }

    /**
     * Cég szintű pillanat állás (összes iroda összesítve)
     *
     * GET /api/v1/cash-balances/company-position
     */
    @GetMapping("/company-position")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CashBalanceService.CompanyCashPosition> getCompanyCashPosition() {
        CashBalanceService.CompanyCashPosition position = cashBalanceService.getCompanyCashPosition();
        return ResponseEntity.ok(position);
    }

    /**
     * Issue #110: kassza egyenleg inicializálás egy adott iroda számára.
     *
     * Idempotens — minden aktív valutához 0-ás balance rekordot hoz létre,
     * ha még nincs. Ha van, átugorja (nem módosít létező balance-t).
     *
     * POST /api/v1/cash-balances/init-branch/{branchId}
     *
     * @return inicializált (új) cash_balance rekordok száma
     */
    @PostMapping("/init-branch/{branchId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<java.util.Map<String, Object>> initBranchBalances(@PathVariable java.util.UUID branchId) {
        int created = cashBalanceService.initializeBranchBalances(branchId);
        return ResponseEntity.ok(java.util.Map.of(
                "branchId", branchId,
                "created", created,
                "idempotent", true
        ));
    }

    /**
     * Issue #110: cég összes aktív branch-jére cash_balance bulk init.
     *
     * Idempotens — csak a hiányzó (branch, currency) párosokhoz hoz létre rekordot.
     * Használat: deploy utáni egyszeri "retrofit" régebbi branch-ekre.
     *
     * POST /api/v1/cash-balances/init-all-branches
     *
     * Sourcery PR #112: service BulkInitResult record single-sourced totalCreated.
     *
     * @return (branchId -> new_records_count) map + summary
     */
    @PostMapping("/init-all-branches")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<java.util.Map<String, Object>> initAllBranchBalances() {
        CashBalanceService.BulkInitResult result =
                cashBalanceService.initializeAllBranchBalancesForCurrentCompany();
        return ResponseEntity.ok(java.util.Map.of(
                "perBranch", result.perBranch(),
                "totalCreated", result.totalCreated(),
                "branchCount", result.branchCount(),
                "idempotent", true
        ));
    }
}
