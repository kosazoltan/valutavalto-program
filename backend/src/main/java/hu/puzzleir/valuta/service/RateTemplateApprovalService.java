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

        // State machine = egyetlen igazságforrás (VV-ELVI v2 5.2): jóváhagyás csak DRAFT→APPROVED.
        // A status oszlop nullable (DEFAULT 'DRAFT'), ezért NULL-t is kezelünk (érvénytelen átmenet).
        RateTemplate.RateTemplateStatus current = template.getStatus();
        if (current == null || !current.canTransitionTo(RateTemplate.RateTemplateStatus.APPROVED)) {
            throw new ValidationException("Csak DRAFT státuszú sablon hagyható jóvá! Jelenlegi állapot: "
                    + current);
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

        // State machine = egyetlen igazságforrás (VV-ELVI v2 5.2): DRAFT nem vonható vissza,
        // a REVOKED terminális — visszavonás csak APPROVED/PUBLISHED→REVOKED.
        // NULL status (nullable oszlop) = nem visszavonható.
        RateTemplate.RateTemplateStatus current = template.getStatus();
        if (current == null || !current.canTransitionTo(RateTemplate.RateTemplateStatus.REVOKED)) {
            throw new ValidationException("Ez az állapot nem vonható vissza! Jelenlegi állapot: "
                    + current);
        }

        template.setStatus(RateTemplate.RateTemplateStatus.REVOKED);
        RateTemplate saved = templateRepository.save(template);
        log.info("Árfolyam sablon visszavonva: {}", templateId);
        return saved;
    }
}
