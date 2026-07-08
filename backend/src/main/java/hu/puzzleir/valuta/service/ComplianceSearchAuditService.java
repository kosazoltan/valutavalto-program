package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchAuditDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchAuditDto;
import hu.puzzleir.valuta.entity.ComplianceSearchAudit;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ComplianceSearchAuditRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.JacksonException;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.UUID;

/**
 * FS-11 S2b: compliance keresés-audit napló. A bejegyzés a keresés PILLANATÁnak jogi
 * snapshotja (criteria dátumokkal + eredmény-sorok) — mentés után IMMUTABLE.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ComplianceSearchAuditService {

    private static final int MAX_TITLE_LENGTH = 200;
    private static final int MAX_DESCRIPTION_LENGTH = 2000;
    private static final String ERROR_JSON = "COMPLIANCE_AUDIT_JSON";

    private final ComplianceSearchAuditRepository auditRepository;
    private final ComplianceTransactionSearchService searchService;
    private final ObjectMapper objectMapper;

    @Transactional(rollbackFor = Exception.class)
    public ComplianceSearchAuditDto create(CreateComplianceSearchAuditDto dto) {
        String title = normalizeTitle(dto.getTitle());
        String description = normalizeDescription(dto.getDescription());
        ComplianceTransactionSearchCriteria criteria = dto.getCriteria();
        if (criteria == null) {
            throw new ValidationException("A keresési feltételek kötelezőek");
        }
        // Fail-closed: >EXPORT_MAX_ROWS esetén COMPLIANCE_EXPORT_TOO_LARGE propagál,
        // semmi nem perzisztálódik (nincs csonkolt audit). A criteria dátumai MARADNAK.
        List<ComplianceTransactionRowDto> rows = searchService.searchForExport(criteria);
        ComplianceSearchAudit audit = ComplianceSearchAudit.builder()
                .companyId(SecurityUtils.getCurrentCompanyId())
                .title(title)
                .description(description)
                .criteriaJson(writeJson(criteria))
                .resultSnapshotJson(writeJson(rows))
                .resultCount(rows.size())
                .createdByWorkerCode(SecurityUtils.getCurrentWorkerCode())
                .build();
        audit = auditRepository.save(audit);
        log.info("Compliance keresés-audit mentve: id={}, title={}, count={}",
                audit.getId(), audit.getTitle(), audit.getResultCount());
        return toDto(audit);
    }

    @Transactional(readOnly = true)
    public List<ComplianceSearchAuditDto> listForCurrentCompany() {
        return auditRepository
                .findByCompanyIdOrderByCreatedAtDesc(SecurityUtils.getCurrentCompanyId())
                .stream().map(this::toDto).toList();
    }

    /** A PDF-út betöltője: KIZÁRÓLAG a tárolt snapshotot adja, sosem keres újra. */
    @Transactional(readOnly = true)
    public ComplianceSearchAuditPdfData loadForPdf(UUID id) {
        ComplianceSearchAudit audit = auditRepository
                .findByIdAndCompanyId(id, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Audit-bejegyzés nem található: " + id));
        List<ComplianceTransactionRowDto> rows = readRows(audit.getResultSnapshotJson());
        return new ComplianceSearchAuditPdfData(audit.getTitle(), audit.getDescription(),
                audit.getCreatedByWorkerCode(), audit.getCreatedAt(), audit.getResultCount(), rows);
    }

    /** A PDF-render bemenete — a snapshot + a kötelező fejléc-metaadatok. */
    public record ComplianceSearchAuditPdfData(String title, String description,
            String createdByWorkerCode, java.time.LocalDateTime createdAt,
            Integer resultCount, List<ComplianceTransactionRowDto> rows) {
    }

    private static String normalizeTitle(String raw) {
        String title = raw == null ? "" : raw.trim();
        if (title.isEmpty()) {
            throw new ValidationException("Az audit-bejegyzés címe nem lehet üres");
        }
        if (title.length() > MAX_TITLE_LENGTH) {
            throw new ValidationException("A cím legfeljebb " + MAX_TITLE_LENGTH + " karakter lehet");
        }
        return title;
    }

    private static String normalizeDescription(String raw) {
        if (raw == null) {
            return null;
        }
        String description = raw.trim();
        if (description.isEmpty()) {
            return null;
        }
        if (description.length() > MAX_DESCRIPTION_LENGTH) {
            throw new ValidationException("A leírás legfeljebb " + MAX_DESCRIPTION_LENGTH + " karakter lehet");
        }
        return description;
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JacksonException e) {
            throw new BusinessException("Az audit-bejegyzés nem menthető", ERROR_JSON);
        }
    }

    private ComplianceTransactionSearchCriteria readCriteria(String json) {
        try {
            return objectMapper.readValue(json, ComplianceTransactionSearchCriteria.class);
        } catch (JacksonException e) {
            throw new BusinessException("Az audit-bejegyzés feltételei nem olvashatók", ERROR_JSON);
        }
    }

    private List<ComplianceTransactionRowDto> readRows(String json) {
        try {
            return objectMapper.readValue(json, new TypeReference<List<ComplianceTransactionRowDto>>() {});
        } catch (JacksonException e) {
            throw new BusinessException("Az audit-snapshot nem olvasható", ERROR_JSON);
        }
    }

    private ComplianceSearchAuditDto toDto(ComplianceSearchAudit a) {
        return ComplianceSearchAuditDto.builder()
                .id(a.getId())
                .title(a.getTitle())
                .description(a.getDescription())
                .criteria(readCriteria(a.getCriteriaJson()))
                .resultCount(a.getResultCount())
                .createdByWorkerCode(a.getCreatedByWorkerCode())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
