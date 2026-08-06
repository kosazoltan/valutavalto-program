package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.exception.ErrorResponse;
import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.CashBalanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
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
    private final AccessScopeService accessScopeService;
    // FK-075 FR-1: az IdempotencyGuard-injekció eltávolítva — az egyetlen fogyasztója a
    // letiltott POST /cash-balances/adjust volt (410 Gone).

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
    // FK-005/A1: az értéktáros (FOERTEKTAR/ERTEKTAR) és az ügyvezető is lekérdezheti az
    // összesített készletet (Dashboard "összesített készlet" + "TOP-irodák") — eddig 403-at
    // kapott ("Korlátozott jogosultság"). FK-005/A3: az értéktáros CSAK a saját region_code-
    // jához tartozó pénztárak egyenlegeit kapja (a frontend ebből számolja az összesítést és
    // a rangsort → automatikusan terület-szűkített). Cég-szintű role → null scope → teljes cég.
    @GetMapping("/company")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'UGYVEZETO', 'FOERTEKTAR', 'ERTEKTAR')")
    public ResponseEntity<List<CashBalanceDto>> getCompanyBalances() {
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        List<CashBalance> balances = cashBalanceService.getCompanyBalances();
        List<CashBalanceDto> dtos = balances.stream()
                .map(cashBalanceMapper::toDto)
                .filter(dto -> accessScopeService.isBranchVisible(scope, dto.getBranchId()))
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
     * Egyenleg kézi módosítása (feltöltés/levétel) — LETILTVA.
     *
     * POST /api/v1/cash-balances/adjust
     *
     * FK-075 FR-1 (2026-08-06): a kézi, szabad pénzmozgatás (Bevét/Kivét) kivezetésre került —
     * a pénztári „Kassza / készlet" oldalról a gomb és a modál eltávolítva, ez a végpont pedig
     * 410 Gone-nal utasít el minden közvetlen hívást (a Fázis 0 grep megerősítette: egyetlen
     * frontend-hívója a CashDeskPage.tsx volt, más kliens nem használja).
     *
     * Megjegyzés: a {@code cashBalanceService.adjustBalance(...)} service-metódus szándékosan
     * NEM került törlésre (audit-nyomvonal + esetleges jövőbeli, szabályozott újraengedés);
     * HTTP-szinten a végpont elérhetetlen. A letiltás ténye egyszeri audit-bejegyzésként
     * ebben a kódkommentben és a kapcsolódó PR/commit üzenetben dokumentált.
     */
    @PostMapping("/adjust")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ErrorResponse> adjustBalance() {
        return ResponseEntity.status(HttpStatus.GONE)
                .body(ErrorResponse.builder()
                        .timestamp(LocalDateTime.now())
                        .status(HttpStatus.GONE.value())
                        .error("Gone")
                        .message("A kézi egyenleg-módosítás (Bevét/Kivét) megszűnt (FK-075). "
                                + "A pénztárállást a tranzakciók és a napi zárás módosítják.")
                        .build());
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
     * FK-075 FR-5/FR-6 (2026-08-06): a „Mai statisztika" panel ÉLŐ, tranzakció-alapú adatai.
     *
     * GET /api/v1/cash-balances/today-stats
     *
     * Dedikált végpont — a {@code GET /daily-sessions/current} változatlan marad, mert a
     * MainLayout fejléc is fogyasztja. A számítás a mai nap és az aktuális fiók (JWT scope)
     * tranzakcióiból történik, nem tárolt napi-munkamenet-számlálókból.
     */
    @GetMapping("/today-stats")
    public ResponseEntity<CashBalanceService.TodayStats> getTodayStats() {
        return ResponseEntity.ok(cashBalanceService.getTodayStats());
    }

    /**
     * Cég szintű összesítés valutánként
     *
     * GET /api/v1/cash-balances/company-totals
     */
    @GetMapping("/company-totals")
    // FK-037 (2026-06-20): a kozponti ertektari vezetoi szerepkorok (FOERTEKTAR/UGYVEZETO) is
    // olvashatjak a cegszintu osszesitot — osszhangban a getCompanyBalances (83. sor) listaval.
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
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
    // FK-037 (2026-06-20): a kozponti ertektari vezetoi szerepkorok (FOERTEKTAR/UGYVEZETO) is
    // olvashatjak a cegszintu pillanatallast — osszhangban a getCompanyBalances (83. sor) listaval.
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
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
