package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchGroup;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchGroupRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BranchGroupService {

    private final BranchGroupRepository repo;
    private final BranchRepository branchRepository;

    public List<BranchGroup> listAll() {
        List<UUID> branchIds = getCurrentCompanyBranchIds();
        if (branchIds.isEmpty()) {
            return Collections.emptyList();
        }
        return repo.findByAnyBranchIdIn(branchIds);
    }

    public List<BranchGroup> listActive() {
        List<UUID> branchIds = getCurrentCompanyBranchIds();
        if (branchIds.isEmpty()) {
            return Collections.emptyList();
        }
        return repo.findActiveByAnyBranchIdIn(branchIds);
    }

    public List<BranchGroup> listRoots() {
        List<UUID> branchIds = getCurrentCompanyBranchIds();
        if (branchIds.isEmpty()) {
            return Collections.emptyList();
        }
        return repo.findRootByAnyBranchIdIn(branchIds);
    }

    public BranchGroup getById(UUID id) {
        BranchGroup group = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiókcsoport nem található: " + id));

        Set<UUID> allowedBranchIds = getCurrentCompanyBranchIds().stream().collect(Collectors.toSet());
        List<UUID> groupBranchIds = group.getBranchIds() != null ? group.getBranchIds() : Collections.emptyList();
        boolean hasAccessibleBranch = groupBranchIds.stream().anyMatch(allowedBranchIds::contains);
        if (!hasAccessibleBranch) {
            throw new ResourceNotFoundException("Fiókcsoport nem található: " + id);
        }

        return group;
    }

    @Transactional(rollbackFor = Exception.class)
    public BranchGroup create(BranchGroup entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);

        validateBranchIdsInCurrentCompany(entity.getBranchIds());
        return repo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public BranchGroup update(UUID id, BranchGroup entity) {
        BranchGroup existing = getById(id);
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setDescription(entity.getDescription());
        existing.setGroupTypeDid(entity.getGroupTypeDid());
        existing.setParentGroupId(entity.getParentGroupId());
        existing.setIsActive(entity.getIsActive());

        validateBranchIdsInCurrentCompany(entity.getBranchIds());
        existing.setBranchIds(entity.getBranchIds());

        return repo.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        getById(id); // tenant check
        repo.deleteById(id);
    }

    private List<UUID> getCurrentCompanyBranchIds() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return branchRepository.findByCompanyId(companyId).stream()
                .map(Branch::getId)
                .toList();
    }

    private void validateBranchIdsInCurrentCompany(List<UUID> branchIds) {
        if (branchIds == null || branchIds.isEmpty()) {
            return;
        }

        Set<UUID> allowedBranchIds = getCurrentCompanyBranchIds().stream().collect(Collectors.toSet());
        boolean hasForeignBranch = branchIds.stream().anyMatch(id -> !allowedBranchIds.contains(id));
        if (hasForeignBranch) {
            throw new ResourceNotFoundException("Érvénytelen fiók hivatkozás a fiókcsoportban");
        }
    }
}
