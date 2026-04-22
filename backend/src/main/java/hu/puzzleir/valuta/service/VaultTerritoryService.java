package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.VaultTerritoryRequestDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Ertektari terulet szolgaltatas.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VaultTerritoryService {

    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final CompanyRepository companyRepository;

    @Transactional(readOnly = true)
    public List<VaultTerritory> getAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId);
    }

    @Transactional(readOnly = true)
    public VaultTerritory getById(Integer id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultTerritory territory = vaultTerritoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Terulet nem talalhato: " + id));
        // Multi-tenant IDOR vedelme: csak sajat ceg teruletet adhatunk vissza
        if (territory.getCompany() != null && !territory.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Terulet nem talalhato: " + id);
        }
        return territory;
    }

    /**
     * Uj vault_territory letrehozasa a bejelentkezett ceghez.
     * Unique constraint: (company_id, name).
     */
    @Transactional(rollbackFor = Exception.class)
    public VaultTerritory create(VaultTerritoryRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Ceg nem talalhato: " + companyId));

        // Duplikacio ellenorzes (unique constraint amugy is nem engedne, de elegansabb elore)
        List<VaultTerritory> existing = vaultTerritoryRepository.findByCompanyId(companyId);
        boolean nameTaken = existing.stream()
                .anyMatch(vt -> vt.getName() != null && vt.getName().equalsIgnoreCase(request.getName()));
        if (nameTaken) {
            throw new ValidationException("Mar letezik ertektari terulet ezzel a nevvel: " + request.getName());
        }

        VaultTerritory territory = VaultTerritory.builder()
                .company(company)
                .name(request.getName())
                .baseCapital(request.getBaseCapital())
                .baseCapitalApprovedAt(request.getBaseCapitalApprovedAt())
                .active(true)
                .build();

        VaultTerritory saved = vaultTerritoryRepository.save(territory);
        log.info("Uj vault_territory letrehozva: id={}, name={}, company={}",
                saved.getId(), saved.getName(), companyId);
        return saved;
    }
}