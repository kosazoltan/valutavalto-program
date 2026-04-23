package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.VaultTerritoryRequestDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
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
    private final CurrencyStockRepository currencyStockRepository;  // v2.2.2 hotfix

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

        // Sourcery + Codex PR #129 fix: trim egyszer, hasznosits mindenhol
        // (validacio, DB duplikacio check, ERROR msg, persistence).
        if (request.getName() == null || request.getName().isBlank()) {
            throw new ValidationException("Terulet neve kotelezo");
        }
        String normalizedName = request.getName().trim();
        if (normalizedName.isEmpty()) {
            throw new ValidationException("Terulet neve nem lehet csak whitespace");
        }

        // DB-szintu duplikacio check (Sourcery PR #125 performance).
        // A (company_id, name) unique constraint a vegso safety-net, race condition ellen.
        boolean nameTaken = vaultTerritoryRepository
                .existsByCompanyIdAndNameIgnoreCase(companyId, normalizedName);
        if (nameTaken) {
            throw new ValidationException("Mar letezik ertektari terulet ezzel a nevvel: " + normalizedName);
        }

        VaultTerritory territory = VaultTerritory.builder()
                .company(company)
                .name(normalizedName)  // trimmed - consistent DB storage
                .baseCapital(request.getBaseCapital())
                .baseCapitalApprovedAt(request.getBaseCapitalApprovedAt())
                .active(true)
                .build();

        VaultTerritory saved = vaultTerritoryRepository.save(territory);
        log.info("Uj vault_territory letrehozva: id={}, name={}, company={}",
                saved.getId(), saved.getName(), companyId);

        // v2.2.2 hotfix: HUF CurrencyStock auto-init a baseCapital-lal,
        // hogy a VaultBankTransaction.createBankTransaction BUY ne dobjon 500-at.
        if (saved.getBaseCapital() != null && saved.getBaseCapital().signum() > 0) {
            CurrencyStock hufStock = CurrencyStock.builder()
                    .company(Company.builder().id(companyId).build())
                    .entityType("VAULT")
                    .entityId(saved.getId().toString())
                    .currencyCode("HUF")
                    .quantity(saved.getBaseCapital())
                    .weightedAvgCost(java.math.BigDecimal.ONE)
                    .lastUpdated(java.time.LocalDateTime.now())
                    .build();
            currencyStockRepository.save(hufStock);
            log.info("Vault HUF stock inicializalva: territory={}, baseCapital={}",
                    saved.getId(), saved.getBaseCapital());
        }
        return saved;
    }
}