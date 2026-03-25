package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Organization;
import hu.puzzleir.valuta.repository.OrganizationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findAllByCompanyId(companyId);
    }

    public List<Organization> listActive() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findByCompanyIdAndIsActiveTrue(companyId);
    }

    public List<Organization> listRoots() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findByCompanyIdAndParentIdIsNull(companyId);
    }

    public Organization getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szervezet nem található: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public Organization create(Organization entity) {
        entity.setId(null);
        entity.setCompanyId(SecurityUtils.getCurrentCompanyId());
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
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

    @Transactional(rollbackFor = Exception.class)
    public Organization archive(UUID id) {
        Organization existing = getById(id);
        existing.setIsActive(false);
        return repo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
