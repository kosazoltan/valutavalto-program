package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateTemplateService {

    private final RateTemplateRepository templateRepository;
    private final CompanyRepository companyRepository;

    @Transactional(readOnly = true)
    public List<RateTemplate> getTemplatesByWorkgroup(UUID workgroupId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return templateRepository.findByCompanyIdAndWorkgroupId(companyId, workgroupId);
    }

    @Transactional(readOnly = true)
    public List<RateTemplate> getTemplatesByStatus(RateTemplate.RateTemplateStatus status) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return templateRepository.findByCompanyIdAndStatus(companyId, status);
    }

    @Transactional(readOnly = true)
    public RateTemplate getTemplate(UUID id) {
        RateTemplate template = templateRepository.findById(id)
                .orElseThrow(() -> new ValidationException("Árfolyam sablon nem található: " + id));
        verifyCompanyAccess(template);
        return template;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateTemplate createTemplate(RateTemplate template) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található"));
        template.setCompany(company);
        template.setStatus(RateTemplate.RateTemplateStatus.DRAFT);
        template.setCreatedBy(SecurityUtils.getCurrentWorkerId());
        template.setCreatedAt(LocalDateTime.now());
        RateTemplate saved = templateRepository.save(template);
        log.info("Árfolyam sablon létrehozva: currency={}, workgroup={}",
                saved.getCurrencyId(), saved.getWorkgroupId());
        return saved;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateTemplate updateTemplate(UUID id, RateTemplate update) {
        RateTemplate existing = getTemplate(id);
        if (existing.getStatus() != RateTemplate.RateTemplateStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú sablon módosítható!");
        }
        existing.setBaseBuyRate(update.getBaseBuyRate());
        existing.setBaseSellRate(update.getBaseSellRate());
        existing.setBuySpread(update.getBuySpread());
        existing.setSellSpread(update.getSellSpread());
        existing.setRoundingRule(update.getRoundingRule());
        existing.setOfficialRate(update.getOfficialRate());
        existing.setLimit1Amount(update.getLimit1Amount());
        existing.setLimit1BuyRate(update.getLimit1BuyRate());
        existing.setLimit1SellRate(update.getLimit1SellRate());
        existing.setLimit2Amount(update.getLimit2Amount());
        existing.setLimit2BuyRate(update.getLimit2BuyRate());
        existing.setLimit2SellRate(update.getLimit2SellRate());
        existing.setLimit3Amount(update.getLimit3Amount());
        existing.setLimit3BuyRate(update.getLimit3BuyRate());
        existing.setLimit3SellRate(update.getLimit3SellRate());
        return templateRepository.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteTemplate(UUID id) {
        RateTemplate template = getTemplate(id);
        if (template.getStatus() == RateTemplate.RateTemplateStatus.PUBLISHED) {
            throw new ValidationException("Publikált sablon nem törölhető!");
        }
        templateRepository.delete(template);
        log.info("Árfolyam sablon törölve: {}", id);
    }

    private void verifyCompanyAccess(RateTemplate template) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (template.getCompany() != null && !template.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a sablonhoz");
        }
    }
}
