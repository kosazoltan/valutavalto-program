package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Workstation;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.WorkstationRepository;
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
public class WorkstationService {

    private final WorkstationRepository repo;
    private final BranchRepository branchRepository;

    public List<Workstation> listAll() {
        List<UUID> branchIds = getCurrentCompanyBranchIds();
        if (branchIds.isEmpty()) {
            return Collections.emptyList();
        }
        return repo.findByBranchIdIn(branchIds);
    }

    public List<Workstation> listActive() {
        List<UUID> branchIds = getCurrentCompanyBranchIds();
        if (branchIds.isEmpty()) {
            return Collections.emptyList();
        }
        return repo.findByBranchIdInAndIsActiveTrue(branchIds);
    }

    public Workstation getById(UUID id) {
        Workstation workstation = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Munkaállomás nem található: " + id));

        Set<UUID> allowedBranchIds = getCurrentCompanyBranchIds().stream().collect(Collectors.toSet());
        if (!allowedBranchIds.contains(workstation.getBranchId())) {
            throw new ResourceNotFoundException("Munkaállomás nem található: " + id);
        }

        return workstation;
    }

    @Transactional
    public Workstation create(Workstation entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        validateBranchInCurrentCompany(entity.getBranchId());
        return repo.save(entity);
    }

    @Transactional
    public Workstation update(UUID id, Workstation entity) {
        Workstation existing = getById(id);
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());

        validateBranchInCurrentCompany(entity.getBranchId());
        existing.setBranchId(entity.getBranchId());

        existing.setIpAddress(entity.getIpAddress());
        existing.setMacAddress(entity.getMacAddress());
        existing.setIsActive(entity.getIsActive());
        return repo.save(existing);
    }

    @Transactional
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

    private void validateBranchInCurrentCompany(UUID branchId) {
        Set<UUID> allowedBranchIds = getCurrentCompanyBranchIds().stream().collect(Collectors.toSet());
        if (!allowedBranchIds.contains(branchId)) {
            throw new ResourceNotFoundException("Iroda nem található a jelenlegi cégben: " + branchId);
        }
    }
}
