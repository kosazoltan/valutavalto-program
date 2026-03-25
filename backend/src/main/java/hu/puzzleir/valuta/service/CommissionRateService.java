package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.CommissionRate;
import hu.puzzleir.valuta.repository.CommissionRateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommissionRateService {

    private final CommissionRateRepository repository;

    public List<CommissionRate> findAll() {
        return repository.findByIsActiveTrueOrderByValidFromDesc();
    }

    public CommissionRate findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("CommissionRate not found: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public CommissionRate create(CommissionRate entity) {
        return repository.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public CommissionRate update(UUID id, CommissionRate updated) {
        CommissionRate existing = findById(id);
        existing.setEntityType(updated.getEntityType());
        existing.setEntityId(updated.getEntityId());
        existing.setCurrencyId(updated.getCurrencyId());
        existing.setRate(updated.getRate());
        existing.setValidFrom(updated.getValidFrom());
        existing.setValidTo(updated.getValidTo());
        existing.setIsActive(updated.getIsActive());
        return repository.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        CommissionRate existing = findById(id);
        existing.setIsActive(false);
        repository.save(existing);
    }
}
