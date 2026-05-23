package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.WuPartnerCompany;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WuPartnerCompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Western Union partner-cég törzs (legacy: WUCEGEK / GETWCEG.dll) — multi-tenant.
 *
 * <p>Lista + keresés + idempotens felvétel + deaktiválás. Minden művelet a hívó
 * cégére (SecurityUtils) szűr; IDOR-védelem a deaktiválásnál.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class WuPartnerCompanyService {

    private final WuPartnerCompanyRepository repository;
    private final CompanyRepository companyRepository;

    public List<WuPartnerCompany> list() {
        return repository.findByCompanyIdAndActiveTrueOrderByNameAsc(SecurityUtils.getCurrentCompanyId());
    }

    public List<WuPartnerCompany> search(String q) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (q == null || q.isBlank()) {
            return repository.findByCompanyIdAndActiveTrueOrderByNameAsc(companyId);
        }
        return repository.searchByName(companyId, q.trim());
    }

    /** Idempotens felvétel: ha a (cég, név) már létezik, a meglévőt adja vissza (újra-aktiválva). */
    @Transactional
    public WuPartnerCompany create(String name) {
        if (name == null || name.isBlank()) {
            throw new ValidationException("A partnercég neve kötelező!");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String trimmed = name.trim();
        return repository.findByCompanyIdAndNameIgnoreCase(companyId, trimmed)
                .map(existing -> {
                    if (Boolean.FALSE.equals(existing.getActive())) {
                        existing.setActive(true);
                        return repository.save(existing);
                    }
                    return existing;
                })
                .orElseGet(() -> {
                    Company company = companyRepository.findById(companyId)
                            .orElseThrow(() -> new ResourceNotFoundException("Cég nem található"));
                    return repository.save(WuPartnerCompany.builder()
                            .company(company)
                            .name(trimmed)
                            .active(true)
                            .build());
                });
    }

    @Transactional
    public void deactivate(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        WuPartnerCompany entity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Partnercég nem található"));
        // IDOR-védelem: csak a saját cég partnercégét lehet deaktiválni
        if (entity.getCompany() == null || !companyId.equals(entity.getCompany().getId())) {
            throw new ResourceNotFoundException("Partnercég nem található");
        }
        entity.setActive(false);
        repository.save(entity);
    }
}
