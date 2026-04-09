package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.CreateAnonymousReportRequest;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.AnonymousReport;
import hu.puzzleir.valuta.entity.AnonymousReportStatus;
import hu.puzzleir.valuta.repository.AnonymousReportRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AnonymousReportService {

    private final AnonymousReportRepository repo;

    public List<AnonymousReport> listAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findAllByCompanyId(companyId);
    }

    public AnonymousReport getById(UUID id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Anonim bejelentés nem található: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public AnonymousReport create(CreateAnonymousReportRequest request) {
        AnonymousReport entity = new AnonymousReport();
        entity.setReportType(request.getReportType());
        entity.setSubject(request.getSubject());
        entity.setDescription(request.getDescription());
        entity.setStatus(AnonymousReportStatus.NEW);
        entity.setCompanyId(SecurityUtils.getCurrentCompanyId());
        return repo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public AnonymousReport assign(UUID id, Long assignedToId) {
        AnonymousReport report = getById(id);
        report.setAssignedToId(assignedToId);
        report.setStatus(AnonymousReportStatus.IN_PROGRESS);
        return repo.save(report);
    }

    @Transactional(rollbackFor = Exception.class)
    public AnonymousReport resolve(UUID id, String resolution) {
        AnonymousReport report = getById(id);
        report.setResolution(resolution);
        report.setStatus(AnonymousReportStatus.RESOLVED);
        return repo.save(report);
    }
}
