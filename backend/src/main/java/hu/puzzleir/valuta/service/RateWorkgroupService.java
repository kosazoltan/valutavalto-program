package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateWorkgroupService {

    private final RateWorkgroupRepository workgroupRepository;
    private final CompanyRepository companyRepository;

    @Transactional(readOnly = true)
    public List<RateWorkgroup> getAllActive() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workgroupRepository.findByCompanyIdAndActiveTrue(companyId);
    }

    @Transactional(readOnly = true)
    public List<RateWorkgroup> getAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workgroupRepository.findByCompanyId(companyId);
    }

    @Transactional(readOnly = true)
    public RateWorkgroup getById(UUID id) {
        RateWorkgroup wg = workgroupRepository.findById(id)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + id));
        verifyCompanyAccess(wg);
        return wg;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateWorkgroup create(RateWorkgroup workgroup) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // A kód-egyediség a (company_id, code) páron van — cégen belül kell ellenőrizni,
        // különben egy másik cég azonos kódjára adnánk fals "már létezik" hibát.
        if (workgroupRepository.findByCompanyIdAndCode(companyId, workgroup.getCode()).isPresent()) {
            throw new ValidationException("Már létezik munkacsoport ezzel a kóddal: " + workgroup.getCode());
        }
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található"));
        workgroup.setCompany(company);
        RateWorkgroup saved = workgroupRepository.save(workgroup);
        log.info("Munkacsoport létrehozva: {} ({})", saved.getName(), saved.getCode());
        return saved;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateWorkgroup update(UUID id, RateWorkgroup update) {
        RateWorkgroup existing = getById(id);
        existing.setName(update.getName());
        existing.setActive(update.getActive());
        existing.setTileColor(update.getTileColor());
        return workgroupRepository.save(existing);
    }

    /**
     * FK-02: munkacsoport "törlése" — FK-006 elv szerint inaktiválás (nem fizikai törlés),
     * az árfolyam-előzmények (rate_template, publikációk) megőrzéséhez. A branch-hozzárendelés
     * feloldódik, hogy a pénztárak más munkacsoportba átsorolhatók legyenek (V242 exkluzivitás).
     */
    @Transactional(rollbackFor = Exception.class)
    public void softDelete(UUID id) {
        RateWorkgroup existing = getById(id);
        existing.setActive(false);
        existing.getBranches().clear();
        workgroupRepository.save(existing);
        log.info("Munkacsoport inaktiválva (soft-delete): {} ({})", existing.getName(), existing.getCode());
    }

    private void verifyCompanyAccess(RateWorkgroup wg) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (wg.getCompany() != null && !wg.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a munkacsoporthoz");
        }
    }
}
