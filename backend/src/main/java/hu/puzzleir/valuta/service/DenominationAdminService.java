package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import hu.puzzleir.valuta.entity.DenominationRule;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DenominationOptimizationRepository;
import hu.puzzleir.valuta.repository.DenominationRuleRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Címletezési optimalizáció és szabályok admin use-case rétege.
 *
 * <p><b>Miért létezik.</b> A {@code DenominationOptimizationController} korábban három
 * repository-t injektált közvetlenül, és <b>írási</b> műveleteket (mentés, módosítás,
 * logikai törlés) hajtott végre tranzakcióhatár nélkül. Egy módosítás így két külön
 * autocommit-tranzakcióra bomlott (guard-olvasás, majd írás) — a kettő között az
 * állapot megváltozhatott (TOCTOU), és részleges írás sem volt visszagörgethető.
 *
 * <p><b>IDOR-guard.</b> A {@link DenominationRule} a tenancyt a {@code branchId}-n
 * keresztül hordozza. {@code branchId == null} = cég-globális szabály (a végpontok
 * ADMIN/MANAGER/MAIN_TREASURY-re korlátozottak). Cross-tenant → „nem található".
 * A guard és a hozzá tartozó írás mostantól <b>ugyanabban</b> a tranzakcióban fut.
 */
@Service
@RequiredArgsConstructor
public class DenominationAdminService {

    /** Új szabály alapértelmezett prioritása, ha a kérés nem adja meg. */
    public static final int DEFAULT_RULE_PRIORITY = 100;

    private final DenominationOptimizationRepository optimizationRepository;
    private final DenominationRuleRepository ruleRepository;
    private final BranchRepository branchRepository;

    /**
     * IDOR-guard: a user-megadott {@code branchId} az aktuális céghez tartozik-e.
     *
     * @param branchId a fiók azonosítója, vagy {@code null} cég-globális hatókörhöz
     */
    @Transactional(readOnly = true)
    public void assertBranchInCurrentCompany(UUID branchId) {
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

    @Transactional(readOnly = true)
    public List<DenominationOptimization> listActiveOptimizations() {
        return optimizationRepository.findByIsActiveTrueOrderByNameAsc();
    }

    @Transactional
    public DenominationOptimization createOptimization(DenominationOptimization draft) {
        draft.setIsActive(true);
        return optimizationRepository.save(draft);
    }

    /**
     * Meglévő optimalizáció módosítása.
     *
     * <p>Az olvasás és az írás egyetlen tranzakcióban — így a betöltött entitás nem
     * változhat meg a mentés előtt (a korábbi controller-változatban ez két külön
     * autocommit volt).
     *
     * @return a mentett entitás, vagy {@link Optional#empty()}, ha nincs ilyen id
     */
    @Transactional
    public Optional<DenominationOptimization> updateOptimization(
            UUID id, DenominationOptimization changes) {
        return optimizationRepository.findById(id).map(opt -> {
            opt.setName(changes.getName());
            opt.setDescription(changes.getDescription());
            opt.setStrategy(changes.getStrategy());
            opt.setPriorityOrderJson(changes.getPriorityOrderJson());
            opt.setMinCoins(changes.getMinCoins());
            opt.setMinBanknotes(changes.getMinBanknotes());
            opt.setMinTotalCount(changes.getMinTotalCount());
            opt.setIsDefault(changes.getIsDefault());
            return optimizationRepository.save(opt);
        });
    }

    // ==========================================================================
    // Rules (szabályok)
    // ==========================================================================

    @Transactional(readOnly = true)
    public List<DenominationRule> listActiveRules() {
        return ruleRepository.findByIsActiveTrueOrderByPriorityAsc();
    }

    /**
     * Új szabály rögzítése.
     *
     * <p>Az IDOR-guard, az optimalizáció feloldása és a mentés egyetlen tranzakcióban:
     * a hivatkozott optimalizáció nem tűnhet el a guard és az írás között.
     */
    @Transactional
    public DenominationRule createRule(DenominationRule draft, UUID optimizationId) {
        assertBranchInCurrentCompany(draft.getBranchId());
        DenominationOptimization opt = optimizationRepository.findById(optimizationId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Optimization nem található: " + optimizationId));
        draft.setOptimization(opt);
        if (draft.getPriority() == null) {
            draft.setPriority(DEFAULT_RULE_PRIORITY);
        }
        draft.setIsActive(true);
        return ruleRepository.save(draft);
    }

    /**
     * Szabály logikai törlése ({@code isActive = false}).
     *
     * <p>Üzleti rekord fizikailag nem törlődik — a szabály-előzmény auditálható marad.
     *
     * @return {@code true}, ha volt mit deaktiválni
     */
    @Transactional
    public boolean deactivateRule(UUID ruleId) {
        return ruleRepository.findById(ruleId).map(rule -> {
            assertBranchInCurrentCompany(rule.getBranchId());
            rule.setIsActive(false);
            ruleRepository.save(rule);
            return true;
        }).orElse(false);
    }
}
