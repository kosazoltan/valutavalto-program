package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.RateTemplate;
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

    @Transactional(readOnly = true)
    public List<RateTemplate> getTemplatesByWorkgroup(UUID workgroupId) {
        return templateRepository.findByWorkgroupId(workgroupId);
    }

    @Transactional(readOnly = true)
    public List<RateTemplate> getTemplatesByStatus(RateTemplate.RateTemplateStatus status) {
        return templateRepository.findByStatus(status);
    }

    @Transactional(readOnly = true)
    public RateTemplate getTemplate(UUID id) {
        return templateRepository.findById(id)
                .orElseThrow(() -> new ValidationException("Árfolyam sablon nem található: " + id));
    }

    @Transactional
    public RateTemplate createTemplate(RateTemplate template) {
        template.setStatus(RateTemplate.RateTemplateStatus.DRAFT);
        template.setCreatedBy(SecurityUtils.getCurrentWorkerId());
        template.setCreatedAt(LocalDateTime.now());
        RateTemplate saved = templateRepository.save(template);
        log.info("Árfolyam sablon létrehozva: currency={}, workgroup={}",
                saved.getCurrencyId(), saved.getWorkgroupId());
        return saved;
    }

    @Transactional
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
        return templateRepository.save(existing);
    }

    @Transactional
    public void deleteTemplate(UUID id) {
        RateTemplate template = getTemplate(id);
        if (template.getStatus() == RateTemplate.RateTemplateStatus.PUBLISHED) {
            throw new ValidationException("Publikált sablon nem törölhető!");
        }
        templateRepository.delete(template);
        log.info("Árfolyam sablon törölve: {}", id);
    }
}
