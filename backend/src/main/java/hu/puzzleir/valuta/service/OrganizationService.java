package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Organization;
import hu.puzzleir.valuta.repository.OrganizationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrganizationService {

    private final OrganizationRepository repo;

    public List<Organization> listAll() {
        return repo.findAll();
    }

    public List<Organization> listActive() {
        return repo.findByIsActiveTrue();
    }

    public List<Organization> listRoots() {
        return repo.findByParentIdIsNull();
    }

    public Organization getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szervezet nem található: " + id));
    }

    @Transactional
    public Organization create(Organization entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional
    public Organization update(UUID id, Organization entity) {
        Organization existing = getById(id);
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setDescription(entity.getDescription());
        existing.setParentId(entity.getParentId());
        existing.setOrganizationTypeDid(entity.getOrganizationTypeDid());
        existing.setIsActive(entity.getIsActive());
        return repo.save(existing);
    }

    @Transactional
    public Organization archive(UUID id) {
        Organization existing = getById(id);
        existing.setIsActive(false);
        return repo.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
