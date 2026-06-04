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
        Integer seq = workgroup.getLegacyGroupNumber();

        // FK02-D (FR-17): a kódot a SZERVER generálja a sorszámból (GROUP_NN); a klienstől
        // érkező kód-érték (a DEFAULT kivételével) NEM mérvadó. A meglévő DEFAULT csoport kódja megmarad.
        String code = generateWorkgroupCode(workgroup.getCode(), seq);
        workgroup.setCode(code);

        // FK02-D (FR-15): duplikált munkacsoport-sorszám tiltása cégen belül.
        if (seq != null && workgroupRepository.findByCompanyIdAndLegacyGroupNumber(companyId, seq).isPresent()) {
            throw new ValidationException("VV-VALID-003: Ez a sorszám már foglalt: " + seq);
        }
        // A kód-egyediség a (company_id, code) páron van — cégen belül kell ellenőrizni,
        // különben egy másik cég azonos kódjára adnánk fals "már létezik" hibát.
        if (workgroupRepository.findByCompanyIdAndCode(companyId, code).isPresent()) {
            throw new ValidationException("Már létezik munkacsoport ezzel a kóddal: " + code);
        }
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található"));
        workgroup.setCompany(company);
        RateWorkgroup saved = workgroupRepository.save(workgroup);
        log.info("Munkacsoport létrehozva: {} ({})", saved.getName(), saved.getCode());
        return saved;
    }

    /**
     * FK02-D (FR-17): a munkacsoport kódjának szerver-oldali generálása a sorszámból.
     * A DEFAULT csoport kódja megmarad; egyébként {@code GROUP_<kétjegyű sorszám>}. Ha nincs
     * sorszám (régi/edge flow), a kliens-kódra esünk vissza (ne törjön a meglévő hívás).
     */
    private String generateWorkgroupCode(String clientCode, Integer seq) {
        if (clientCode != null && "DEFAULT".equalsIgnoreCase(clientCode.trim())) {
            return "DEFAULT";
        }
        if (seq != null) {
            return String.format("GROUP_%02d", seq);
        }
        return clientCode;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateWorkgroup update(UUID id, RateWorkgroup update) {
        RateWorkgroup existing = getById(id);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        existing.setName(update.getName());
        existing.setActive(update.getActive());
        existing.setTileColor(update.getTileColor());
        // A sorszám (legacyGroupNumber) a csempén a fő azonosító — a szerkesztő módosíthatja.
        Integer newSeq = update.getLegacyGroupNumber();
        // FK02-D (FR-16): átnevezéskor/sorszám-módosításkor duplikált sorszám tiltása (self kizárva).
        if (newSeq != null) {
            workgroupRepository.findByCompanyIdAndLegacyGroupNumber(companyId, newSeq)
                    .filter(dup -> !dup.getId().equals(id))
                    .ifPresent(dup -> {
                        throw new ValidationException("VV-VALID-003: Ez a sorszám már foglalt: " + newSeq);
                    });
        }
        existing.setLegacyGroupNumber(newSeq);
        // FK02-D (FR-17): a kód a sorszámból generált (felhasználó nem szerkeszti); átnevezéskor
        // a sorszámhoz igazítjuk. A DEFAULT csoport kódja megmarad.
        if (!"DEFAULT".equalsIgnoreCase(existing.getCode())) {
            existing.setCode(generateWorkgroupCode(existing.getCode(), newSeq));
        }
        // FK-04/E: árfolyamvédelem flag — a csempe jobb felső checkbox-a vezérli.
        // Ha a DTO null-t küld (régi kliens), a meglévő értéket tartjuk.
        if (update.getProtectionEnabled() != null) {
            existing.setProtectionEnabled(update.getProtectionEnabled());
        }
        // FK-04/D: kedvezményhatárok (3 forint-küszöb). NULL-érték = "nem küldött",
        // a meglévőt tartjuk; egyébként felülírjuk (üres → BigDecimal(0) értelmezhetetlen,
        // a frontend explicit null-t küld, ha üres → szerkesztő gomb törléshez).
        if (update.getLimit1Boundary() != null) existing.setLimit1Boundary(update.getLimit1Boundary());
        if (update.getLimit2Boundary() != null) existing.setLimit2Boundary(update.getLimit2Boundary());
        if (update.getLimit3Boundary() != null) existing.setLimit3Boundary(update.getLimit3Boundary());
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
