package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DocumentShortage;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DocumentShortageRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Okmányhiány-regiszter (legacy OKMANYHIANY / OKMCTRL.dll) — multi-tenant.
 *
 * <p>Rögzítés + lista (nyitott/összes) + lezárás (pótolva). IDOR-guard a lezárásnál.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DocumentShortageService {

    private final DocumentShortageRepository repository;
    private final CompanyRepository companyRepository;

    public List<DocumentShortage> list(boolean openOnly) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return openOnly
                ? repository.findByCompanyIdAndResolvedAtIsNullOrderByRecordedAtDesc(companyId)
                : repository.findByCompanyIdOrderByRecordedAtDesc(companyId);
    }

    @Transactional
    public DocumentShortage record(String missingDocument, String customerName, String customerId,
                                   String branchCode, String receiptNumber, String note) {
        if (missingDocument == null || missingDocument.isBlank()) {
            throw new ValidationException("A hiányzó okmány megnevezése kötelező!");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található"));
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return repository.save(DocumentShortage.builder()
                .company(company)
                .missingDocument(missingDocument.trim())
                .customerName(trimOrNull(customerName))
                .customerId(trimOrNull(customerId))
                .branchCode(trimOrNull(branchCode))
                .receiptNumber(trimOrNull(receiptNumber))
                .note(trimOrNull(note))
                .recordedBy(workerId != null ? String.valueOf(workerId) : null)
                .build());
    }

    @Transactional
    public DocumentShortage resolve(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DocumentShortage entity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Okmányhiány-tétel nem található"));
        if (entity.getCompany() == null || !companyId.equals(entity.getCompany().getId())) {
            throw new ResourceNotFoundException("Okmányhiány-tétel nem található");
        }
        if (entity.getResolvedAt() == null) {
            entity.setResolvedAt(LocalDateTime.now());
            repository.save(entity);
        }
        return entity;
    }

    private static String trimOrNull(String s) {
        return (s == null || s.isBlank()) ? null : s.trim();
    }
}
