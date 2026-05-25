package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Bank;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BankRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Bank-törzs (FK-005/C1) — multi-tenant + területi.
 *
 * <p>A banki átadás-átvétel cél/forrás bankjainak listája. A lista TERÜLETI szűrésű:
 * az értéktáros (ERTEKTAR/FOERTEKTAR) a cég-szintű (region_code=NULL) bankokat ÉS a saját
 * region_code-jához tartozókat látja; cég-szintű role (MANAGER/ADMIN/UGYVEZETO) az összeset.
 * Az N4 (WuPartnerCompanyService) mintájára. Minden művelet a hívó cégére szűr; IDOR-védelem.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class BankService {

    private final BankRepository repository;
    private final CompanyRepository companyRepository;
    private final AccessScopeService accessScopeService;

    /** Területileg szűrt lista (értéktárosnál a saját régió + cég-szintű bankok). */
    public List<Bank> list() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String region = accessScopeService.vaultRegionCodeOrNull();
        if (region == null) {
            return repository.findByCompanyIdAndActiveTrueOrderByNameAsc(companyId);
        }
        return repository.findActiveByCompanyAndRegionOrGlobal(companyId, region);
    }

    public List<Bank> search(String q) {
        if (q == null || q.isBlank()) {
            return list();
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String region = accessScopeService.vaultRegionCodeOrNull();
        // Keresésnél is tartjuk a területi szűrést (vault user): a name-match eredményt
        // szűkítjük a látható (cég-szintű + saját régió) bankokra.
        List<Bank> matches = repository.searchByName(companyId, q.trim());
        if (region == null) {
            return matches;
        }
        return matches.stream()
                .filter(b -> b.getRegionCode() == null || region.equals(b.getRegionCode()))
                .toList();
    }

    /** Idempotens felvétel: ha a (cég, név) már létezik, a meglévőt adja vissza (újra-aktiválva). */
    @Transactional
    public Bank create(String name, String regionCode) {
        if (name == null || name.isBlank()) {
            throw new ValidationException("A bank neve kötelező!");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String trimmed = name.trim();
        String region = (regionCode != null && !regionCode.isBlank()) ? regionCode.trim() : null;
        return repository.findByCompanyIdAndNameIgnoreCase(companyId, trimmed)
                .map(existing -> {
                    boolean changed = false;
                    if (Boolean.FALSE.equals(existing.getActive())) {
                        existing.setActive(true);
                        changed = true;
                    }
                    if (region != null && !region.equals(existing.getRegionCode())) {
                        existing.setRegionCode(region);
                        changed = true;
                    }
                    return changed ? repository.save(existing) : existing;
                })
                .orElseGet(() -> {
                    Company company = companyRepository.findById(companyId)
                            .orElseThrow(() -> new ResourceNotFoundException("Cég nem található"));
                    return repository.save(Bank.builder()
                            .company(company)
                            .name(trimmed)
                            .regionCode(region)
                            .active(true)
                            .build());
                });
    }

    @Transactional
    public void deactivate(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Bank entity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bank nem található"));
        // IDOR-védelem: csak a saját cég bankját lehet deaktiválni
        if (entity.getCompany() == null || !companyId.equals(entity.getCompany().getId())) {
            throw new ResourceNotFoundException("Bank nem található");
        }
        entity.setActive(false);
        repository.save(entity);
    }
}
