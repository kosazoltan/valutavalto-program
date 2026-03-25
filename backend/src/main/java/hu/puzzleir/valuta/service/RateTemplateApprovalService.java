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
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateTemplateApprovalService {

    private final RateTemplateRepository templateRepository;

    @Transactional(rollbackFor = Exception.class)
    public RateTemplate approve(UUID templateId) {
        RateTemplate template = templateRepository.findById(templateId)
                .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

        if (template.getStatus() != RateTemplate.RateTemplateStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú sablon hagyható jóvá!");
        }

        template.setStatus(RateTemplate.RateTemplateStatus.APPROVED);
        template.setApprovedBy(SecurityUtils.getCurrentWorkerId());
        template.setApprovedAt(LocalDateTime.now());

        RateTemplate saved = templateRepository.save(template);
        log.info("Árfolyam sablon jóváhagyva: {} by worker {}", templateId, template.getApprovedBy());
        return saved;
    }

    @Transactional(rollbackFor = Exception.class)
    public RateTemplate revoke(UUID templateId) {
        RateTemplate template = templateRepository.findById(templateId)
                .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

        if (template.getStatus() == RateTemplate.RateTemplateStatus.DRAFT) {
            throw new ValidationException("DRAFT státuszú sablon nem vonható vissza!");
        }

        template.setStatus(RateTemplate.RateTemplateStatus.REVOKED);
        RateTemplate saved = templateRepository.save(template);
        log.info("Árfolyam sablon visszavonva: {}", templateId);
        return saved;
    }
}
