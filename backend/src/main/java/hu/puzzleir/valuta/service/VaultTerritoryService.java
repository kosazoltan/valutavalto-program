package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Értéktári terület szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VaultTerritoryService {

    private final VaultTerritoryRepository vaultTerritoryRepository;

    @Transactional(readOnly = true)
    public List<VaultTerritory> getAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId);
    }

    @Transactional(readOnly = true)
    public VaultTerritory getById(Integer id) {
        return vaultTerritoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Terület nem található: " + id));
    }
}
