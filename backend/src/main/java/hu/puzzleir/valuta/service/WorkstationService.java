package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Workstation;
import hu.puzzleir.valuta.repository.WorkstationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WorkstationService {

    private final WorkstationRepository repo;

    public List<Workstation> listAll() {
        return repo.findAll();
    }

    public List<Workstation> listActive() {
        return repo.findByIsActiveTrue();
    }

    public Workstation getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Munkaállomás nem található: " + id));
    }

    @Transactional
    public Workstation create(Workstation entity) {
        entity.setId(null);
        if (entity.getIsActive() == null) entity.setIsActive(true);
        return repo.save(entity);
    }

    @Transactional
    public Workstation update(UUID id, Workstation entity) {
        Workstation existing = getById(id);
        existing.setCode(entity.getCode());
        existing.setName(entity.getName());
        existing.setBranchId(entity.getBranchId());
        existing.setIpAddress(entity.getIpAddress());
        existing.setMacAddress(entity.getMacAddress());
        existing.setIsActive(entity.getIsActive());
        return repo.save(existing);
    }

    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
