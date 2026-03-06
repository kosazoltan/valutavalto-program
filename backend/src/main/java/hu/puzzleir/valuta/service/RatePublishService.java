package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.entity.RatePublication;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.repository.RatePublicationRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RatePublishService {

    private final RateTemplateRepository templateRepository;
    private final RateWorkgroupRepository workgroupRepository;
    private final RatePublicationRepository publicationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Publish approved rate templates for a workgroup.
     */
    @Transactional
    public RatePublication publish(UUID workgroupId, List<UUID> templateIds, String notes) {
        RateWorkgroup workgroup = workgroupRepository.findById(workgroupId)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + workgroupId));

        List<RateTemplate> templates = new ArrayList<>();
        for (UUID templateId : templateIds) {
            RateTemplate template = templateRepository.findById(templateId)
                    .orElseThrow(() -> new ValidationException("Sablon nem található: " + templateId));

            if (template.getStatus() != RateTemplate.RateTemplateStatus.APPROVED
                    && template.getStatus() != RateTemplate.RateTemplateStatus.DRAFT) {
                throw new ValidationException("Csak DRAFT vagy APPROVED sablon publikálható: " + templateId);
            }

            template.setStatus(RateTemplate.RateTemplateStatus.PUBLISHED);
            template.setPublishedAt(LocalDateTime.now());
            templateRepository.save(template);
            templates.add(template);
        }

        // Create publication record
        int affectedBranches = workgroup.getBranches() != null ? workgroup.getBranches().size() : 0;
        RatePublication publication = RatePublication.builder()
                .workgroupId(workgroupId)
                .publishedBy(SecurityUtils.getCurrentWorkerId())
                .affectedBranches(affectedBranches)
                .notes(notes)
                .build();

        if (!templateIds.isEmpty()) {
            publication.setTemplateId(templateIds.get(0));
        }

        publication = publicationRepository.save(publication);

        // WebSocket broadcast
        broadcastRateUpdate(workgroupId, templates);

        log.info("Árfolyamok publikálva: workgroup={}, templates={}, branches={}",
                workgroup.getCode(), templates.size(), affectedBranches);

        return publication;
    }

    /**
     * Broadcast rate update via WebSocket.
     */
    private void broadcastRateUpdate(UUID workgroupId, List<RateTemplate> templates) {
        List<RateUpdateMessage.RateEntry> entries = templates.stream()
                .map(t -> RateUpdateMessage.RateEntry.builder()
                        .currencyId(t.getCurrencyId())
                        .buyRate(t.getBaseBuyRate().add(t.getBuySpread()))
                        .sellRate(t.getBaseSellRate().add(t.getSellSpread()))
                        .roundingRule(t.getRoundingRule())
                        .build())
                .toList();

        RateUpdateMessage message = RateUpdateMessage.builder()
                .workgroupId(workgroupId)
                .publishedAt(LocalDateTime.now())
                .rates(entries)
                .build();

        try {
            messagingTemplate.convertAndSend("/topic/rate-updates/" + workgroupId, message);
            log.debug("WebSocket rate update küldve: workgroup={}", workgroupId);
        } catch (Exception e) {
            log.warn("WebSocket rate update sikertelen: {}", e.getMessage());
        }
    }

    /**
     * Get publication history.
     */
    @Transactional(readOnly = true)
    public List<RatePublication> getPublicationHistory(UUID workgroupId) {
        if (workgroupId != null) {
            return publicationRepository.findByWorkgroupIdOrderByPublishedAtDesc(workgroupId);
        }
        return publicationRepository.findTop20ByOrderByPublishedAtDesc();
    }
}
