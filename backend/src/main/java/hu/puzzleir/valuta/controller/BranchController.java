package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.dto.CreateBranchDto;
import hu.puzzleir.valuta.dto.CreateSimpleCashierBranchDto;
import hu.puzzleir.valuta.dto.UpdateBranchDto;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.BranchService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/branches")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("isAuthenticated()")
public class BranchController {

    private final BranchService branchService;
    private final AccessScopeService accessScopeService;

    /**
     * GET /api/v1/branches/my-territory
     * FK-005/B4: az átadás-átvétel és hasonló dropdownokhoz — az aktuális felhasználó
     * TERÜLETILEG illetékes aktív pénztárai. Ha a felhasználó értéktárosként
     * (ERTEKTAR/FOERTEKTAR authority) operál → CSAK a saját region_code-jához tartozó
     * pénztárak (+ saját fiók) — akkor is, ha a base-role cég-szintű (a vault-authority
     * precedál, lásd AccessScopeService). Egyébként (nem értéktári kontextus) → összes aktív
     * fiók. Így az "Új szállítmányigény" legördülőjében nem az ORSZÁG ÖSSZES pénztára jelenik
     * meg, csak a saját értéktárhoz tartozók.
     */
    @GetMapping("/my-territory")
    public ResponseEntity<List<BranchDto>> getMyTerritoryBranches(
            @RequestParam(required = false) String clientType) {
        List<BranchDto> active = excludeVirtualIfCentral(branchService.findAllActive(), clientType);
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (scope == null) {
            return ResponseEntity.ok(active);
        }
        List<BranchDto> filtered = active.stream()
                .filter(b -> b.getId() != null && scope.contains(b.getId()))
                .toList();
        return ResponseEntity.ok(filtered);
    }

    /**
     * FK-016 (2026-06-03): a Központi Munkaállomás kliens (clientType=CENTRAL) felületein
     * KIZÁRÓLAG a valódi fizikai irodák (értéktár + pénztár) jelenhetnek meg; a virtuális
     * partnerek (könyvelési entitások: ERB/FRB/RB/JRB/PRB/TRB/MNB/UPT/TH/FOP1) nem.
     *
     * <p><b>Tényalapú megoldás:</b> ezeket a partnereket a repo MÁR megkülönbözteti a
     * {@code branchType.code = 'VAULT_COUNTERPARTY'} diszkriminátorral (V277 seed; ugyanezt
     * használja a {@code findByCompanyIdAndIsActiveTrueExcludingCounterparties}, a
     * RateCreationService és a ClosingControlService is). Külön {@code is_virtual} flag
     * REDUNDÁNS lenne (szinkronban tartandó duplikált állapot → drift), ezért a meglévő
     * diszkriminátorra szűrünk. Az értéktári/pénztári kliens NEM ad clientType=CENTRAL-t,
     * így ott a partnerek változatlanul megmaradnak (FK-016 regresszió-mentesség).</p>
     */
    private List<BranchDto> excludeVirtualIfCentral(List<BranchDto> branches, String clientType) {
        if (!"CENTRAL".equalsIgnoreCase(clientType)) {
            return branches;
        }
        return branches.stream()
                .filter(b -> !"VAULT_COUNTERPARTY".equals(b.getBranchTypeCode()))
                .toList();
    }

    /** CodeQL log-injection elleni semlegesítés: a felhasználói input sortörés-karaktereit cseréli. */
    private static String sanitizeForLog(String value) {
        return value == null ? null : value.replaceAll("[\\r\\n]", "_");
    }

    /**
     * GET /api/v1/branches/cashier-shipment-targets
     *
     * <p>Bali Henriett / Kasza Helga FK-013 (2026-05-28) PÉNZTÁRI OLDAL: a pénztári F4
     * "Átadás-átvétel" menü "Cél iroda" legördülő — 3 elem:
     * saját értéktár (regionCode-egyezés) + TH + 1-es főpénztár.</p>
     */
    @GetMapping("/cashier-shipment-targets")
    @PreAuthorize("hasAnyRole('CASHIER', 'PENZTAR', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<BranchDto>> getCashierShipmentTargets() {
        log.info("GET /api/v1/branches/cashier-shipment-targets (FK-013 pénztári oldal)");
        return ResponseEntity.ok(branchService.findCashierShipmentTargets());
    }

    /**
     * GET /api/v1/branches/vault-counterparties
     *
     * <p>Bali Henriett / Kasza Helga FK-013 (2026-05-28): az egységes értéktári
     * átadás-átvétel "Cél iroda" legördülő tartalma, 3 csoportban:
     * territorialCashiers / peerVaults / fixedCounterparties (10 fix banki partner).</p>
     *
     * <p>Engedélyezett role-ok: az ÉRTÉKTÁR / FŐÉRTÉKTÁR és a cég-szintű operatív
     * role-ok (a régi {@code listMyTerritory} mintájához igazítva). Pénztáros
     * (CASHIER/PENZTAR) nem fér hozzá — neki a régi {@code listMyTerritory} az aktuális.</p>
     */
    @GetMapping("/vault-counterparties")
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR', 'MANAGER')")
    public ResponseEntity<hu.puzzleir.valuta.dto.VaultCounterpartiesDto> getVaultCounterparties() {
        log.info("GET /api/v1/branches/vault-counterparties (FK-013)");
        return ResponseEntity.ok(branchService.findVaultCounterparties());
    }

    /**
     * GET /api/v1/branches
     * Összes fiók lekérése (opcionális szűrőkkel)
     */
    @GetMapping
    public ResponseEntity<List<BranchDto>> getAllBranches(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(required = false, defaultValue = "false") boolean activeOnly,
            @RequestParam(required = false) String clientType
    ) {
        // CodeQL (log-injection): a query-paraméterek felhasználói inputok — a logolás előtt a
        // sortörés-karaktereket semlegesítjük, hogy ne lehessen hamis log-bejegyzést injektálni.
        log.info("GET /api/v1/branches - type: {}, status: {}, search: {}, activeOnly: {}, clientType: {}",
                sanitizeForLog(type), sanitizeForLog(status), sanitizeForLog(search), activeOnly,
                sanitizeForLog(clientType));

        List<BranchDto> branches;

        if (search != null && !search.trim().isEmpty()) {
            branches = branchService.search(search);
        } else if (type != null && !type.trim().isEmpty()) {
            branches = branchService.findByType(type);
        } else if (status != null && !status.trim().isEmpty()) {
            branches = branchService.findByStatus(status);
        } else if (activeOnly) {
            branches = branchService.findAllActive();
        } else {
            branches = branchService.findAll();
        }

        // FK-016: Központi Munkaállomás (clientType=CENTRAL) → virtuális partnerek kizárása.
        return ResponseEntity.ok(excludeVirtualIfCentral(branches, clientType));
    }

    /**
     * GET /api/v1/branches/vault-only
     * v2.5.1-C B6: Csak ÉRTÉKTÁRI (is_vault=TRUE) fiókok.
     */
    @GetMapping("/vault-only")
    public ResponseEntity<List<BranchDto>> getVaultBranches(
            @RequestParam(required = false, defaultValue = "true") boolean activeOnly
    ) {
        log.info("GET /api/v1/branches/vault-only - activeOnly: {}", activeOnly);
        return ResponseEntity.ok(branchService.findVaultBranches(activeOnly));
    }

    /**
     * PATCH /api/v1/branches/{id}/is-vault
     * v2.5.1-C B6: is_vault flag toggle (admin/foertektar/ugyvezeto).
     */
    @PatchMapping("/{id}/is-vault")
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BranchDto> updateIsVault(
            @PathVariable UUID id,
            @RequestBody UpdateIsVaultRequest body
    ) {
        log.info("PATCH /api/v1/branches/{}/is-vault - isVault: {}", id, body.isVault());
        return ResponseEntity.ok(branchService.updateIsVault(id, body.isVault()));
    }

    /** v2.5.1-C: PATCH /is-vault request body. */
    public record UpdateIsVaultRequest(boolean isVault) {}

    /**
     * GET /api/v1/branches/roots
     * Gyökér fiókok (nincs szülő)
     */
    @GetMapping("/roots")
    public ResponseEntity<List<BranchDto>> getRootBranches() {
        log.info("GET /api/v1/branches/roots");
        List<BranchDto> roots = branchService.findRootBranches();
        return ResponseEntity.ok(roots);
    }

    /**
     * GET /api/v1/branches/{id}
     * Fiók lekérése ID alapján
     */
    @GetMapping("/{id}")
    public ResponseEntity<BranchDto> getBranchById(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}", id);
        BranchDto branch = branchService.findById(id);
        return ResponseEntity.ok(branch);
    }

    /**
     * GET /api/v1/branches/code/{code}
     * Fiók lekérése kód alapján
     */
    @GetMapping("/code/{code}")
    public ResponseEntity<BranchDto> getBranchByCode(@PathVariable String code) {
        log.info("GET /api/v1/branches/code/{}", code);
        BranchDto branch = branchService.findByCode(code);
        return ResponseEntity.ok(branch);
    }

    /**
     * GET /api/v1/branches/{id}/children
     * Szülő alatti közvetlen gyermekek
     */
    @GetMapping("/{id}/children")
    public ResponseEntity<List<BranchDto>> getChildren(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}/children", id);
        List<BranchDto> children = branchService.findChildren(id);
        return ResponseEntity.ok(children);
    }

    /**
     * GET /api/v1/branches/{id}/path
     * Útvonal a gyökérig (breadcrumb)
     */
    @GetMapping("/{id}/path")
    public ResponseEntity<List<BranchDto>> getPathToRoot(@PathVariable UUID id) {
        log.info("GET /api/v1/branches/{}/path", id);
        List<BranchDto> path = branchService.findPathToRoot(id);
        return ResponseEntity.ok(path);
    }

    /**
     * POST /api/v1/branches
     * Új fiók létrehozása
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BranchDto> createBranch(@Valid @RequestBody CreateBranchDto dto) {
        log.info("POST /api/v1/branches - code: {}", dto.getCode());
        BranchDto created = branchService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * POST /api/v1/branches/simple-cashier
     *
     * <p>Bali Henriett 2. pont (2026-05-27): egyszerűsített lakossági pénztár-felrögzítés
     * értéktáros / főértéktáros által. Csak 3 kötelező mező (code, address, regionCode);
     * a service kitölti a default-okat (HU/PENZTAR/ACTIVE/today). A multi-tenant scope
     * automatikus (a jelenlegi felhasználó cége).</p>
     *
     * <p>Engedélyezett role-ok (FK-098, user directive 2026-08-28): a főértéktáros
     * (FOERTEKTAR, országos — bármelyik régióban rögzíthet) és a területi értéktáros
     * (ERTEKTAR — kizárólag a saját földrajzi területén, a service-beli fail-closed
     * guarddal). A Központi Iroda (ADMIN/UGYVEZETO) NEM hozhat létre valutaváltó
     * irodát (pénztárt) — ők könyvelési/háttérirodai szerepkörök.</p>
     */
    @PostMapping("/simple-cashier")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ERTEKTAR')")
    public ResponseEntity<BranchDto> createSimpleCashier(@Valid @RequestBody CreateSimpleCashierBranchDto dto) {
        log.info("POST /api/v1/branches/simple-cashier - code: {}, region: {}", dto.getCode(), dto.getRegionCode());
        BranchDto created = branchService.createSimpleCashier(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/v1/branches/{id}
     * Fiók frissítése
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BranchDto> updateBranch(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBranchDto dto
    ) {
        log.info("PUT /api/v1/branches/{}", id);
        BranchDto updated = branchService.update(id, dto);
        return ResponseEntity.ok(updated);
    }

    /**
     * DELETE /api/v1/branches/{id}
     * Fiók törlése (soft delete)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteBranch(@PathVariable UUID id) {
        log.info("DELETE /api/v1/branches/{}", id);
        branchService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
