package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import hu.puzzleir.valuta.entity.DenominationRule;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.entity.DenominationRuleType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DenominationOptimizationRepository;
import hu.puzzleir.valuta.repository.DenominationRuleRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
 */
@RestController
@RequestMapping("/api/v1/admin/denomination")
@RequiredArgsConstructor
public class DenominationOptimizationController {

    private final DenominationOptimizationRepository optimizationRepository;
    private final DenominationRuleRepository ruleRepository;
    private final DenominationRuleSelectionService selectionService;
    private final BranchRepository branchRepository;

    /**
     * IDOR-guard a fiók-scope-os szabály-műveletekhez. A {@link DenominationRule} a tenancyt a
     * {@code branchId}-n keresztül hordozza; ha a user-megadott branchId nem null, annak az
     * aktuális céghez kell tartoznia. {@code branchId == null} = cég-globális szabály (a végpontok
     * már ADMIN/MANAGER/MAIN_TREASURY-re korlátozottak). Cross-tenant → ResourceNotFoundException.
     */
    private void assertBranchInCurrentCompany(UUID branchId) {
        if (branchId == null) {
            return;
        }
        if (!branchRepository.existsByIdAndCompanyId(branchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Fiók nem található: " + branchId);
        }
    }

    // ==========================================================================
    // Optimization (stratégia konfigurációk)
    // ==========================================================================

    @GetMapping("/optimizations")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISOR','MANAGER','TREASURY_MANAGER','MAIN_TREASURY')")
    public List<DenominationOptimization> listOptimizations() {
        return optimizationRepository.findByIsActiveTrueOrderByNameAsc();
    }

    @PostMapping("/optimizations")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationOptimization> createOptimization(
            @Valid @RequestBody OptimizationCreateRequest req) {
        DenominationOptimization opt = DenominationOptimization.builder()
                .name(req.getName())
                .description(req.getDescription())
                .strategy(req.getStrategy())
                .priorityOrderJson(req.getPriorityOrderJson())
                .minCoins(Boolean.TRUE.equals(req.getMinCoins()))
                .minBanknotes(Boolean.TRUE.equals(req.getMinBanknotes()))
                .minTotalCount(Boolean.TRUE.equals(req.getMinTotalCount()))
                .isDefault(Boolean.TRUE.equals(req.getIsDefault()))
                .isActive(true)
                .build();
        return ResponseEntity.ok(optimizationRepository.save(opt));
    }

    @PutMapping("/optimizations/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationOptimization> updateOptimization(
            @PathVariable UUID id,
            @Valid @RequestBody OptimizationCreateRequest req) {
        return optimizationRepository.findById(id).map(opt -> {
            opt.setName(req.getName());
            opt.setDescription(req.getDescription());
            opt.setStrategy(req.getStrategy());
            opt.setPriorityOrderJson(req.getPriorityOrderJson());
            opt.setMinCoins(Boolean.TRUE.equals(req.getMinCoins()));
            opt.setMinBanknotes(Boolean.TRUE.equals(req.getMinBanknotes()));
            opt.setMinTotalCount(Boolean.TRUE.equals(req.getMinTotalCount()));
            opt.setIsDefault(Boolean.TRUE.equals(req.getIsDefault()));
            return ResponseEntity.ok(optimizationRepository.save(opt));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ==========================================================================
    // Rules (szabályok)
    // ==========================================================================

    @GetMapping("/rules")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISOR','MANAGER','TREASURY_MANAGER','MAIN_TREASURY')")
    public List<DenominationRule> listRules() {
        return ruleRepository.findByIsActiveTrueOrderByPriorityAsc();
    }

    @PostMapping("/rules")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<DenominationRule> createRule(@Valid @RequestBody RuleCreateRequest req) {
        // IDOR-guard: a user-megadott branchId-t cég-scope-ra kell validálni a rögzítés előtt.
        assertBranchInCurrentCompany(req.getBranchId());
        DenominationOptimization opt = optimizationRepository.findById(req.getOptimizationId())
                .orElseThrow(() -> new IllegalArgumentException("Optimization nem található: " + req.getOptimizationId()));
        DenominationRule rule = DenominationRule.builder()
                .ruleName(req.getRuleName())
                .currencyId(req.getCurrencyId())
                .ruleType(req.getRuleType())
                .minAmount(req.getMinAmount())
                .maxAmount(req.getMaxAmount())
                .branchId(req.getBranchId())
                .optimization(opt)
                .ruleConfigJson(req.getRuleConfigJson())
                .priority(req.getPriority() != null ? req.getPriority() : 100)
                .isActive(true)
                .build();
        return ResponseEntity.ok(ruleRepository.save(rule));
    }

    @DeleteMapping("/rules/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','MAIN_TREASURY')")
    public ResponseEntity<Void> deleteRule(@PathVariable UUID id) {
        return ruleRepository.findById(id).map(rule -> {
            // IDOR-guard: a rule tenancyje a branchId-n keresztül — cross-tenant törlés tiltva.
            assertBranchInCurrentCompany(rule.getBranchId());
            rule.setIsActive(false);
            ruleRepository.save(rule);
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
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
        // IDOR-guard: a preview a user-megadott branchId-re fut — cég-scope ellenőrzés előbb.
        assertBranchInCurrentCompany(branchId);
        return selectionService.selectStrategy(branchId, currencyId, hufAmount);
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
