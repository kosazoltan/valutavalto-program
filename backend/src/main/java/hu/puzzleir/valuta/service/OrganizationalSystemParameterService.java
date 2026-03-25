package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.OrganizationalSystemParameter;
import hu.puzzleir.valuta.repository.OrganizationalSystemParameterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OrganizationalSystemParameterService {

    private final OrganizationalSystemParameterRepository repository;

    public List<OrganizationalSystemParameter> findAll(UUID organizationId) {
        if (organizationId != null) {
            return repository.findByOrganizationIdAndIsActiveTrueOrderByParameterKeyAsc(organizationId);
        }
        return repository.findByIsActiveTrueOrderByOrganizationIdAscParameterKeyAsc();
    }

    public OrganizationalSystemParameter findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("OrganizationalSystemParameter not found: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public OrganizationalSystemParameter create(OrganizationalSystemParameter entity) {
        return repository.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public OrganizationalSystemParameter update(UUID id, OrganizationalSystemParameter updated) {
        OrganizationalSystemParameter existing = findById(id);
        existing.setOrganizationId(updated.getOrganizationId());
        existing.setParameterKey(updated.getParameterKey());
        existing.setParameterValue(updated.getParameterValue());
        existing.setCurrencyId(updated.getCurrencyId());
        existing.setValidFrom(updated.getValidFrom());
        existing.setValidTo(updated.getValidTo());
        existing.setIsActive(updated.getIsActive());
        return repository.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        OrganizationalSystemParameter existing = findById(id);
        existing.setIsActive(false);
        repository.save(existing);
    }
}
