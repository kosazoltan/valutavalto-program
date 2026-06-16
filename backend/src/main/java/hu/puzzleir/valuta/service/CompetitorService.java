package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompetitorRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CompetitorService {

    private final CompetitorRepository repository;
    // IDOR-fix (audit 2026-06-15, FINDING #8): a Competitor tenancy-je a branch_id-n keresztül él
    // (nincs közvetlen company_id), ezért a hívó cégének branch-tulajdonát ellenőrizzük.
    private final BranchRepository branchRepository;

    public List<Competitor> findAll() {
        // A listát a hívó cégéhez tartozó branch-ekre szűkítjük (cross-tenant lista-szivárgás ellen).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repository.findByIsActiveTrueOrderByNameAsc().stream()
                .filter(c -> c.getBranchId() != null
                        && branchRepository.existsByIdAndCompanyId(c.getBranchId(), companyId))
                .toList();
    }

    public Competitor findById(UUID id) {
        Competitor competitor = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Competitor not found: " + id));
        assertOwned(competitor, id);
        return competitor;
    }

    @Transactional(rollbackFor = Exception.class)
    public Competitor create(Competitor entity) {
        assertBranchInCurrentCompany(entity.getBranchId());
        return repository.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public Competitor update(UUID id, Competitor updated) {
        Competitor existing = findById(id);
        // Az ÚJ branch-hozzárendelés is a hívó cégéhez kell tartozzon (nem köthető át idegen céghez).
        assertBranchInCurrentCompany(updated.getBranchId());
        existing.setName(updated.getName());
        existing.setWebsite(updated.getWebsite());
        existing.setBranchId(updated.getBranchId());
        existing.setIsActive(updated.getIsActive());
        return repository.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        Competitor existing = findById(id);
        existing.setIsActive(false);
        repository.save(existing);
    }

    /**
     * Betöltött Competitor tulajdon-ellenőrzése: a branch-én keresztül a hívó cégéhez tartozzon.
     * Cross-tenant (vagy branch nélküli, nem scope-olható) rekordnál — az enumeráció elkerülésére —
     * ugyanaz a "not found" hiba, mint a nem létezőnél.
     */
    private void assertOwned(Competitor competitor, UUID id) {
        if (competitor.getBranchId() == null
                || !branchRepository.existsByIdAndCompanyId(
                        competitor.getBranchId(), SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Competitor not found: " + id);
        }
    }

    /** User által megadott branchId (create/update) a hívó cégéhez kötése. */
    private void assertBranchInCurrentCompany(UUID branchId) {
        if (branchId == null
                || !branchRepository.existsByIdAndCompanyId(branchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Branch not found: " + branchId);
        }
    }
}
