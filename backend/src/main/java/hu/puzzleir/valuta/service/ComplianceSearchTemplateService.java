package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchTemplateDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchTemplateDto;
import hu.puzzleir.valuta.entity.ComplianceSearchTemplate;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ComplianceSearchTemplateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.UUID;

/**
 * FS-11 S2a: mentett compliance szűrő-sablonok — cégszinten közösek (D2).
 * P136: a sablon DÁTUM NÉLKÜL mentődik (startDate/endDate nullázva mentés előtt).
 * MINDEN lekérdezés companyId-szűrt (invariáns #1); a cég a SecurityContextből jön.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ComplianceSearchTemplateService {

    private static final int MAX_NAME_LENGTH = 100;
    private static final String ERROR_JSON = "COMPLIANCE_TEMPLATE_JSON";

    private final ComplianceSearchTemplateRepository templateRepository;
    private final ObjectMapper objectMapper;

    @Transactional(rollbackFor = Exception.class)
    public ComplianceSearchTemplateDto create(CreateComplianceSearchTemplateDto dto) {
        String name = normalizeName(dto.getName());
        ComplianceTransactionSearchCriteria criteria = dto.getCriteria();
        if (criteria == null) {
            throw new ValidationException("A sablon szűrő-feltételei kötelezőek");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (templateRepository.existsByCompanyIdAndName(companyId, name)) {
            throw new ValidationException("Ezen a néven már létezik sablon: " + name);
        }
        // P136: a sablon idő-független — a dátum-intervallum NEM része a mentett criteria-nak.
        criteria.setStartDate(null);
        criteria.setEndDate(null);
        ComplianceSearchTemplate template = ComplianceSearchTemplate.builder()
                .companyId(companyId)
                .name(name)
                .criteriaJson(writeCriteria(criteria))
                .createdByWorkerCode(SecurityUtils.getCurrentWorkerCode())
                .build();
        template = templateRepository.save(template);
        log.info("Compliance szűrő-sablon mentve: id={}, name={}", template.getId(), template.getName());
        return toDto(template);
    }

    @Transactional(readOnly = true)
    public List<ComplianceSearchTemplateDto> listForCurrentCompany() {
        return templateRepository
                .findByCompanyIdOrderByNameAsc(SecurityUtils.getCurrentCompanyId())
                .stream().map(this::toDto).toList();
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        ComplianceSearchTemplate template = templateRepository
                .findByIdAndCompanyId(id, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Szűrő-sablon nem található: " + id));
        templateRepository.delete(template);
        log.info("Compliance szűrő-sablon törölve: id={}, name={}", template.getId(), template.getName());
    }

    private static String normalizeName(String raw) {
        String name = raw == null ? "" : raw.trim();
        if (name.isEmpty()) {
            throw new ValidationException("A sablon neve nem lehet üres");
        }
        if (name.length() > MAX_NAME_LENGTH) {
            throw new ValidationException("A sablon neve legfeljebb " + MAX_NAME_LENGTH + " karakter lehet");
        }
        return name;
    }

    private String writeCriteria(ComplianceTransactionSearchCriteria criteria) {
        try {
            return objectMapper.writeValueAsString(criteria);
        } catch (JacksonException e) {
            throw new BusinessException("A sablon szűrő-feltételei nem menthetők", ERROR_JSON);
        }
    }

    private ComplianceTransactionSearchCriteria readCriteria(String json) {
        try {
            return objectMapper.readValue(json, ComplianceTransactionSearchCriteria.class);
        } catch (JacksonException e) {
            throw new BusinessException("A sablon szűrő-feltételei nem olvashatók", ERROR_JSON);
        }
    }

    private ComplianceSearchTemplateDto toDto(ComplianceSearchTemplate t) {
        return ComplianceSearchTemplateDto.builder()
                .id(t.getId())
                .name(t.getName())
                .criteria(readCriteria(t.getCriteriaJson()))
                .createdByWorkerCode(t.getCreatedByWorkerCode())
                .createdAt(t.getCreatedAt())
                .build();
    }
}
