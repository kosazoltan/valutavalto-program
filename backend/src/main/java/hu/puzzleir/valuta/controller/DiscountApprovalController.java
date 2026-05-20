package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ApprovalLevel;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.DiscountApprovalService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Kedvezmény jóváhagyási szint REST endpoint — Sprint 4 P2-D (DiscountApprovalService) exponálása.
 *
 * <p>v2.5.73: a DiscountApprovalService eddig dead-code volt (no callers). Ez a controller
 * exponálja a frontend pre-check-hez: a pénztáros a kedvezmény-tranzakció ELŐTT lekérdezheti,
 * milyen jóváhagyási szint kell, és hogy a saját szintje elég-e.</p>
 *
 * <p>KÜLÖNBÖZIK a DiscountThresholdController-től (ami összeg-alapú automatikus fee-kedvezmény);
 * ez a worker-role-alapú jóváhagyási szint (0-2% CASHIER, 2-5% SUPERVISOR, stb.).</p>
 */
@RestController
@RequestMapping("/api/v1/discount-approval")
@RequiredArgsConstructor
@Tag(name = "Kedvezmény jóváhagyás", description = "Worker-role-alapú kedvezmény jóváhagyási szint (P2-D)")
public class DiscountApprovalController {

    private final DiscountApprovalService discountApprovalService;

    /**
     * Visszaadja, milyen jóváhagyási szint szükséges egy adott kedvezmény %-hoz, és hogy a
     * jelenlegi worker szintje elég-e (a SecurityUtils-ból kiolvasott szerepkör alapján).
     */
    @GetMapping("/required-level")
    @PreAuthorize("hasAnyRole('CASHIER','CASHIER_SUPERVISOR','SUPERVISOR','MANAGER',"
            + "'TREASURY_MANAGER','MAIN_TREASURY','REGIONAL_MANAGER','ADMIN')")
    @Operation(summary = "Kedvezmény %-hoz szükséges jóváhagyási szint + a jelenlegi worker képessége")
    public ResponseEntity<Map<String, Object>> requiredLevel(@RequestParam BigDecimal discountPercent) {
        ApprovalLevel required = discountApprovalService.getRequiredLevel(discountPercent);

        String currentRole = resolveRole();
        ApprovalLevel workerLevel = discountApprovalService.mapRoleToLevel(currentRole);

        // Copilot P2 #711: a 15% hard cap (DISCOUNT_MAX_PCT) konzisztens a /validate-tel.
        // E fölött SENKI nem alkalmazhat kedvezményt → canApprove=false + exceedsMaxCap=true.
        BigDecimal maxAllowed = discountApprovalService.getMaxAllowedPercent();
        boolean exceedsMaxCap = discountPercent != null && discountPercent.compareTo(maxAllowed) > 0;
        boolean canApprove = !exceedsMaxCap && workerLevel.satisfies(required);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("discountPercent", discountPercent);
        body.put("requiredLevel", required.name());
        body.put("workerLevel", workerLevel.name());
        body.put("maxAllowedPercent", maxAllowed);
        body.put("exceedsMaxCap", exceedsMaxCap);
        body.put("canApprove", canApprove);
        return ResponseEntity.ok(body);
    }

    /**
     * Worker szerepkör feloldása a kedvezmény-jóváhagyáshoz.
     *
     * <p>Copilot P2 #711: a {@code getActiveOperationalRole()} lehet null (backward-compat
     * ctor activeRole=null) — ekkor a {@code getCurrentRole()}-ra fallback-elünk, hogy NE
     * némán CASHIER-re degradáljon (ami téves canApprove=false-t adna egy MANAGER-nek).</p>
     *
     * <p>MEGJEGYZÉS (C.25 subagent review): ha SEM operational SEM canonical role nincs
     * (azaz nincs bejelentkezett user), a {@code getCurrentRole()} <b>ValidationException-t
     * dob</b> ("Nincs bejelentkezett felhasználó!") → HTTP 400, NEM néma CASHIER. Ez
     * elfogadható, mert mindkét endpoint {@code @PreAuthorize}-gated, így auth nélkül
     * nem is érhető el.</p>
     */
    private String resolveRole() {
        String operational = SecurityUtils.getActiveOperationalRole();
        if (operational != null && !operational.isBlank()) {
            return operational;
        }
        // getCurrentRole() ValidationException-t dob ha nincs auth (gated endpoint → 400, OK)
        return SecurityUtils.getCurrentRole();
    }

    /**
     * Validálja, hogy a jelenlegi worker alkalmazhatja-e a megadott kedvezmény %-ot.
     * Ha NEM (vagy a % meghaladja a 15% hard cap-et) → 400 ValidationException.
     */
    @PostMapping("/validate")
    @PreAuthorize("hasAnyRole('CASHIER','CASHIER_SUPERVISOR','SUPERVISOR','MANAGER',"
            + "'TREASURY_MANAGER','MAIN_TREASURY','REGIONAL_MANAGER','ADMIN')")
    @Operation(summary = "Kedvezmény validálása a jelenlegi worker szerepkörével (400 ha nem engedélyezett)")
    public ResponseEntity<Map<String, Object>> validate(@RequestParam BigDecimal discountPercent) {
        String currentRole = resolveRole();
        // Dobhat ValidationException-t → GlobalExceptionHandler 400-at ad vissza.
        discountApprovalService.validateApprovalLevel(discountPercent, currentRole);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("discountPercent", discountPercent);
        body.put("approved", true);
        body.put("workerLevel", discountApprovalService.mapRoleToLevel(currentRole).name());
        return ResponseEntity.ok(body);
    }
}
