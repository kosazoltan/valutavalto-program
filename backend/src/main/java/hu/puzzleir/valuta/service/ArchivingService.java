package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import hu.puzzleir.valuta.repository.ArchiveTaskRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Archiválási szolgáltatás — multi-tenant izolált.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ArchivingService {

    private final ArchiveTaskRepository archiveTaskRepository;
    private final MonthlyArchiveService monthlyArchiveService;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

    @Transactional(readOnly = true)
    public List<ArchiveTask> getAllTasks() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return archiveTaskRepository.findByCompanyId(companyId);
    }

    public ArchiveTask createTask(ArchiveTask task) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));
        // Task hijacking prevention: kliens által küldött ID ignorálása (Copilot P1)
        task.setId(null);
        task.setCompany(company);
        task.setStatus(ArchiveTaskStatus.PENDING);
        log.info("Archiválási feladat létrehozva: type={}, entityType={}, companyId={}",
                task.getTaskType(), task.getEntityType(), companyId);
        return archiveTaskRepository.save(task);
    }

    /**
     * Feladat végrehajtása — valódi archiválás a MonthlyArchiveService-en keresztül.
     * A criteria mezőben JSON-ként tároljuk a paramétereket: branchId, yearMonth.
     */
    public ArchiveTask executeTask(UUID taskId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        ArchiveTask task = archiveTaskRepository.findByIdAndCompanyId(taskId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Archiválási feladat nem található: " + taskId));

        task.setStatus(ArchiveTaskStatus.RUNNING);
        task.setStartedAt(LocalDateTime.now());
        archiveTaskRepository.save(task);

        try {
            log.info("Archiválási feladat végrehajtása: id={}, type={}, entityType={}",
                    taskId, task.getTaskType(), task.getEntityType());

            int archivedCount = 0;

            if ("TRANSACTION".equalsIgnoreCase(task.getEntityType()) && task.getCriteria() != null) {
                // Criteria parsing: "branchId=UUID;yearMonth=YYYY-MM"
                String criteria = task.getCriteria();
                UUID branchId = null;
                java.time.YearMonth yearMonth = null;

                for (String part : criteria.split(";")) {
                    String[] kv = part.trim().split("=", 2);
                    if (kv.length == 2) {
                        if ("branchId".equals(kv[0].trim())) {
                            branchId = UUID.fromString(kv[1].trim());
                        } else if ("yearMonth".equals(kv[0].trim())) {
                            yearMonth = java.time.YearMonth.parse(kv[1].trim());
                        }
                    }
                }

                if (branchId != null && yearMonth != null) {
                    // Cross-tenant IDOR védelem: a branchId a jelenlegi céghez tartozzon (Copilot P1)
                    if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
                        throw new ResourceNotFoundException("Fiók nem található: " + branchId);
                    }
                    archivedCount = monthlyArchiveService.archiveMonth(branchId, yearMonth);
                } else {
                    throw new IllegalArgumentException(
                            "Hiányzó criteria paraméter: branchId és yearMonth kötelező. Kapott: " + criteria);
                }
            } else {
                log.warn("Ismeretlen entityType vagy hiányzó criteria: entityType={}, criteria={}",
                        task.getEntityType(), task.getCriteria());
            }

            task.setStatus(ArchiveTaskStatus.COMPLETED);
            task.setCompletedAt(LocalDateTime.now());
            task.setArchiveLocation("archive/" + task.getEntityType() + "/" + taskId
                    + " (" + archivedCount + " rekord)");

            log.info("Archiválási feladat sikeres: id={}, archivedCount={}", taskId, archivedCount);
        } catch (Exception e) {
            log.error("Archiválási feladat hiba: id={}, error={}", taskId, e.getMessage(), e);
            task.setStatus(ArchiveTaskStatus.FAILED);
            task.setCompletedAt(LocalDateTime.now());
            task.setArchiveLocation("FAILED: " + e.getMessage());
        }

        return archiveTaskRepository.save(task);
    }
}
