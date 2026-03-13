package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.BranchGroup;
import hu.puzzleir.valuta.repository.BranchGroupRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BranchGroupService {

    private final BranchGroupRepository repo;

    public List<BranchGroup> listAll() {
        return repo.findAll();
    }

    public List<BranchGroup> listActive() {
        return repo.findByIsActiveTrue();
    }

    public List<BranchGroup> listRoots() {
        return repo.findByParentGroupIdIsNull();
    }

    public BranchGroup getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiókcsoport nem található: " + id));
    }

    @Transactional
    public BranchGroup create(BranchGroup entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional
    public BranchGroup update(UUID id, BranchGroup entity) {
        BranchGroup existing = getById(id);
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setDescription(entity.getDescription());
        existing.setGroupTypeDid(entity.getGroupTypeDid());
        existing.setParentGroupId(entity.getParentGroupId());
        existing.setIsActive(entity.getIsActive());
        existing.setBranchIds(entity.getBranchIds());
        return repo.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
