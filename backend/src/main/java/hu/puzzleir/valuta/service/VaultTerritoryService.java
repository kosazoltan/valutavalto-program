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
        // Codex AI review #125 P1 fix: multi-tenant szint query-ben, NEM Java-ban.
        // findByIdAndCompanyId garantalja, hogy cross-tenant rekord soha nem
        // kerul be az ORM cache-be, se a Hibernate L1 cache-be, se a logba.
        return vaultTerritoryRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Terulet nem talalhato: " + id));
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

        // Sourcery AI review #125 performance: DB-szintu duplikacio check.
        // Nem tolti be az osszes teruletet memoriaba (skalazodo + race condition csokkentes).
        // A (company_id, name) unique constraint a vegso safety-net.
        if (request.getName() == null || request.getName().isBlank()) {
            throw new ValidationException("Terulet neve kotelezo");
        }
        boolean nameTaken = vaultTerritoryRepository
                .existsByCompanyIdAndNameIgnoreCase(companyId, request.getName().trim());
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