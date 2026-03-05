package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.AnonymousReport;
import hu.puzzleir.valuta.entity.AnonymousReportStatus;
import hu.puzzleir.valuta.repository.AnonymousReportRepository;
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
        return repo.findAll();
    }

    public AnonymousReport getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Anonim bejelentés nem található: " + id));
    }

    @Transactional
    public AnonymousReport create(AnonymousReport entity) {
        entity.setId(null);
        entity.setStatus(AnonymousReportStatus.NEW);
        return repo.save(entity);
    }

    @Transactional
    public AnonymousReport assign(UUID id, Long assignedToId) {
        AnonymousReport report = getById(id);
        report.setAssignedToId(assignedToId);
        report.setStatus(AnonymousReportStatus.IN_PROGRESS);
        return repo.save(report);
    }

    @Transactional
    public AnonymousReport resolve(UUID id, String resolution) {
        AnonymousReport report = getById(id);
        report.setResolution(resolution);
        report.setStatus(AnonymousReportStatus.RESOLVED);
        return repo.save(report);
    }
}
