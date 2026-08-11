package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import hu.puzzleir.valuta.entity.DenominationRule;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.entity.DenominationRuleType;
import hu.puzzleir.valuta.service.DenominationAdminService;
import hu.puzzleir.valuta.service.DenominationRuleSelectionService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * REST API a címletezési optimalizáció + szabályok admin szerkesztéséhez.
 *
 * <p>v2.0 spec 07_cimletkezeles.md alapján — Sprint 1 v2.5.50+.</p>
 *
 * <p><b>Réteg-megjegyzés.</b> Az adatelérés és az IDOR-guard a
 * {@link DenominationAdminService} use-case rétegébe került: az írási végpontok
 * korábban tranzakcióhatár nélkül futottak, így a guard-olvasás és az írás két külön
 * autocommit-tranzakció volt (TOCTOU-rés, nem visszagörgethető részírás).
 */
@RestController
@RequestMapping("/api/v1/admin/denomination")
@RequiredArgsConstructor
public class DenominationOptimizationController {

    private final DenominationAdminService denominationAdminService;
    private final DenominationRuleSelectionService selectionService;

    // ==========================================================================
    // Optimization (stratégia konfigurációk)
    // ==========================================================================

    @GetMapping("/optimizations")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISOR','MANAGER','TREASURY_MANAGER','MAIN_TREASURY')")
    public List<DenominationOptimization> listOptimizations() {
        return denominationAdminService.listActiveOptimizations();
    }

    @PostMapping("/optimizations")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationOptimization> createOptimization(
            @Valid @RequestBody OptimizationCreateRequest req) {
        return ResponseEntity.ok(denominationAdminService.createOptimization(toEntity(req)));
    }

    @PutMapping("/optimizations/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationOptimization> updateOptimization(
            @PathVariable UUID id,
            @Valid @RequestBody OptimizationCreateRequest req) {
        return denominationAdminService.updateOptimization(id, toEntity(req))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ==========================================================================
    // Rules (szabályok)
    // ==========================================================================

    @GetMapping("/rules")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISOR','MANAGER','TREASURY_MANAGER','MAIN_TREASURY')")
    public List<DenominationRule> listRules() {
        return denominationAdminService.listActiveRules();
    }

    @PostMapping("/rules")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationRule> createRule(@Valid @RequestBody RuleCreateRequest req) {
        // Az IDOR-guard (branchId ceg-scope) a service tranzakciojan belul fut.
        DenominationRule draft = DenominationRule.builder()
                .ruleName(req.getRuleName())
                .currencyId(req.getCurrencyId())
                .ruleType(req.getRuleType())
                .minAmount(req.getMinAmount())
                .maxAmount(req.getMaxAmount())
                .branchId(req.getBranchId())
                .ruleConfigJson(req.getRuleConfigJson())
                .priority(req.getPriority())
                .build();
        return ResponseEntity.ok(
                denominationAdminService.createRule(draft, req.getOptimizationId()));
    }

    @DeleteMapping("/rules/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<Void> deleteRule(@PathVariable UUID id) {
        return denominationAdminService.deactivateRule(id)
                ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }

    // ==========================================================================
    // Selection preview (admin teszt)
    // ==========================================================================

    @GetMapping("/selection-preview")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISOR','MANAGER','TREASURY_MANAGER','MAIN_TREASURY')")
    public DenominationRuleSelectionService.RuleSelectionResult previewSelection(
            @RequestParam UUID branchId,
            @RequestParam Long currencyId,
            @RequestParam BigDecimal hufAmount) {
        // IDOR-guard: a preview a user-megadott branchId-re fut — ceg-scope ellenorzes elobb.
        denominationAdminService.assertBranchInCurrentCompany(branchId);
        return selectionService.selectStrategy(branchId, currencyId, hufAmount);
    }

    /** A kérés-DTO leképezése entitásra. A {@code Boolean} mezők {@code null}-ja = false. */
    private DenominationOptimization toEntity(OptimizationCreateRequest req) {
        return DenominationOptimization.builder()
                .name(req.getName())
                .description(req.getDescription())
                .strategy(req.getStrategy())
                .priorityOrderJson(req.getPriorityOrderJson())
                .minCoins(Boolean.TRUE.equals(req.getMinCoins()))
                .minBanknotes(Boolean.TRUE.equals(req.getMinBanknotes()))
                .minTotalCount(Boolean.TRUE.equals(req.getMinTotalCount()))
                .isDefault(Boolean.TRUE.equals(req.getIsDefault()))
                .build();
    }

    // ==========================================================================
    // Request DTOs
    // ==========================================================================

    @Data @Builder @AllArgsConstructor @NoArgsConstructor
    public static class OptimizationCreateRequest {
        private String name;
        private String description;
        private OptimizationStrategy strategy;
        private String priorityOrderJson;
        private Boolean minCoins;
        private Boolean minBanknotes;
        private Boolean minTotalCount;
        private Boolean isDefault;
    }

    @Data @Builder @AllArgsConstructor @NoArgsConstructor
    public static class RuleCreateRequest {
        private String ruleName;
        private Long currencyId;
        private DenominationRuleType ruleType;
        private BigDecimal minAmount;
        private BigDecimal maxAmount;
        private UUID branchId;
        private UUID optimizationId;
        private String ruleConfigJson;
        private Integer priority;
    }
}
