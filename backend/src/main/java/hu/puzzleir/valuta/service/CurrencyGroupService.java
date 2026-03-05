package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CurrencyGroup;
import hu.puzzleir.valuta.repository.CurrencyGroupRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CurrencyGroupService {

    private final CurrencyGroupRepository repository;

    public List<CurrencyGroup> findAll() {
        return repository.findByIsActiveTrueOrderByNameAsc();
    }

    public CurrencyGroup findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("CurrencyGroup not found: " + id));
    }

    @Transactional
    public CurrencyGroup create(CurrencyGroup entity) {
        return repository.save(entity);
    }

    @Transactional
    public CurrencyGroup update(UUID id, CurrencyGroup updated) {
        CurrencyGroup existing = findById(id);
        existing.setCode(updated.getCode());
        existing.setName(updated.getName());
        existing.setDescription(updated.getDescription());
        existing.setCurrencyIds(updated.getCurrencyIds());
        existing.setIsActive(updated.getIsActive());
        return repository.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        CurrencyGroup existing = findById(id);
        existing.setIsActive(false);
        repository.save(existing);
    }
}
