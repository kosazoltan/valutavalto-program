package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.repository.CompetitorRepository;
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

    public List<Competitor> findAll() {
        return repository.findByIsActiveTrueOrderByNameAsc();
    }

    public Competitor findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Competitor not found: " + id));
    }

    @Transactional
    public Competitor create(Competitor entity) {
        return repository.save(entity);
    }

    @Transactional
    public Competitor update(UUID id, Competitor updated) {
        Competitor existing = findById(id);
        existing.setName(updated.getName());
        existing.setWebsite(updated.getWebsite());
        existing.setBranchId(updated.getBranchId());
        existing.setIsActive(updated.getIsActive());
        return repository.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        Competitor existing = findById(id);
        existing.setIsActive(false);
        repository.save(existing);
    }
}
