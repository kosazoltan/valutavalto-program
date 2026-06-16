package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.DataImportJobRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Import felíró szolgáltatás — fióki adatok importálása.
 *
 * Legacy: Import felíró DLL
 * - Napi zárások importja
 * - Készletadatok importja
 * - Tranzakciók importja
 * - Árfolyamok importja
 * - Teljes import (mindegyik egyben)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DataImportService {

    private final DataImportJobRepository dataImportJobRepository;
    private final BranchRepository branchRepository;

    @Value("${data-import.simulated-success-enabled:false}")
    private boolean simulatedSuccessEnabled;

    /**
     * Napi zárás import indítása.
     */
    @Transactional(rollbackFor = Exception.class)
    public DataImportJob importDailyClosing(UUID branchId, LocalDate date) {
        Branch branch = findBranch(branchId);
        DataImportJob job = createJob(branch, DataImportType.DAILY_CLOSING);

        try {
            job.setStatus(DataImportStatus.RUNNING);
            job.setStartedAt(LocalDateTime.now());
            dataImportJobRepository.save(job);

            // Szimuláció: tényleges import implementáció a fióki rendszerből
            int records = simulateImport("daily_closing", branchId, date);
            completeJob(job, records);
        } catch (Exception e) {
            failJob(job, e.getMessage());
        }

        return job;
    }

    /**
     * Készletadatok import.
     */
    @Transactional(rollbackFor = Exception.class)
    public DataImportJob importInventory(UUID branchId) {
        Branch branch = findBranch(branchId);
        DataImportJob job = createJob(branch, DataImportType.INVENTORY);

        try {
            job.setStatus(DataImportStatus.RUNNING);
            job.setStartedAt(LocalDateTime.now());
            dataImportJobRepository.save(job);

            int records = simulateImport("inventory", branchId, LocalDate.now());
            completeJob(job, records);
        } catch (Exception e) {
            failJob(job, e.getMessage());
        }

        return job;
    }

    /**
     * Tranzakciók import.
     */
    @Transactional(rollbackFor = Exception.class)
    public DataImportJob importTransactions(UUID branchId, LocalDate from, LocalDate to) {
        Branch branch = findBranch(branchId);
        DataImportJob job = createJob(branch, DataImportType.TRANSACTIONS);

        try {
            job.setStatus(DataImportStatus.RUNNING);
            job.setStartedAt(LocalDateTime.now());
            dataImportJobRepository.save(job);

            int records = simulateImport("transactions", branchId, from);
            completeJob(job, records);
        } catch (Exception e) {
            failJob(job, e.getMessage());
        }

        return job;
    }

    /**
     * Teljes import — minden típus egyben.
     */
    @Transactional(rollbackFor = Exception.class)
    public DataImportJob importAll(UUID branchId) {
        Branch branch = findBranch(branchId);
        DataImportJob job = createJob(branch, DataImportType.FULL);

        try {
            job.setStatus(DataImportStatus.RUNNING);
            job.setStartedAt(LocalDateTime.now());
            dataImportJobRepository.save(job);

            int records = simulateImport("full", branchId, LocalDate.now());
            completeJob(job, records);
        } catch (Exception e) {
            failJob(job, e.getMessage());
        }

        return job;
    }

    /**
     * Import történet lekérdezése.
     */
    @Transactional(readOnly = true)
    public Page<DataImportJob> getImportHistory(UUID branchId, Pageable pageable) {
        return dataImportJobRepository.findByBranchId(branchId, pageable);
    }

    /**
     * Sikertelen import újrapróbálása.
     */
    @Transactional(rollbackFor = Exception.class)
    public DataImportJob retryFailed(UUID jobId) {
        DataImportJob job = dataImportJobRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Import job not found: " + jobId));

        // IDOR guard: a jobId user @PathVariable; a job branch-én keresztül ellenőrizzük, hogy a
        // hívó cégéhez tartozik-e. Cross-tenant → ResourceNotFoundException (létezés-szivárgás ellen).
        UUID jobBranchId = job.getBranch() != null ? job.getBranch().getId() : null;
        if (jobBranchId == null
                || !branchRepository.existsByIdAndCompanyId(jobBranchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Import job not found: " + jobId);
        }

        if (job.getStatus() != DataImportStatus.FAILED) {
            throw new IllegalStateException("Only FAILED jobs can be retried. Current status: " + job.getStatus());
        }

        job.setStatus(DataImportStatus.PENDING);
        job.setErrorLog(null);
        job.setFailedRecords(0);
        dataImportJobRepository.save(job);

        // Újra indítás típus alapján
        try {
            job.setStatus(DataImportStatus.RUNNING);
            job.setStartedAt(LocalDateTime.now());
            dataImportJobRepository.save(job);

            int records = simulateImport(job.getImportType().name().toLowerCase(), job.getBranch().getId(), LocalDate.now());
            completeJob(job, records);
        } catch (Exception e) {
            failJob(job, e.getMessage());
        }

        return job;
    }

    // ============ PRIVATE HELPERS ============

    private Branch findBranch(UUID branchId) {
        // IDOR guard: a branchId user-kontrollált (request.getBranchId()) az import* végpontokon.
        // Csak a hívó cégének branch-jét engedjük; cross-tenant → ResourceNotFoundException.
        // (Nincs scheduled/auth-mentes import-hívó: minden import* a MANAGER/ADMIN-gated REST-en jön.)
        if (!branchRepository.existsByIdAndCompanyId(branchId, SecurityUtils.getCurrentCompanyId())) {
            throw new ResourceNotFoundException("Branch not found: " + branchId);
        }
        return branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch not found: " + branchId));
    }

    private DataImportJob createJob(Branch branch, DataImportType type) {
        DataImportJob job = DataImportJob.builder()
                .branch(branch)
                .importType(type)
                .status(DataImportStatus.PENDING)
                .sourceType(DataImportSourceType.API)
                .build();
        return dataImportJobRepository.save(job);
    }

    private void completeJob(DataImportJob job, int totalRecords) {
        job.setStatus(DataImportStatus.COMPLETED);
        job.setTotalRecords(totalRecords);
        job.setImportedRecords(totalRecords);
        job.setCompletedAt(LocalDateTime.now());
        dataImportJobRepository.save(job);
        log.info("Import job completed: {} for branch {}, {} records",
                job.getImportType(), job.getBranch().getId(), totalRecords);
    }

    private void failJob(DataImportJob job, String errorMessage) {
        job.setStatus(DataImportStatus.FAILED);
        job.setErrorLog(errorMessage);
        job.setCompletedAt(LocalDateTime.now());
        dataImportJobRepository.save(job);
        log.error("Import job failed: {} for branch {} — {}",
                job.getImportType(), job.getBranch().getId(), errorMessage);
    }

    /**
     * Szimulált import — a tényleges fióki rendszer hívás helyett.
     * Éles környezetben ez FTP/API/fájl olvasás lenne.
     */
    private int simulateImport(String type, UUID branchId, LocalDate date) {
        if (!simulatedSuccessEnabled) {
            throw new IllegalStateException(
                    "Data import driver nincs konfigurálva; szimulált COMPLETED import tiltva");
        }
        log.info("Simulating {} import for branch {} on {}", type, branchId, date);
        // A tényleges implementáció a Helga DLL logika szerint töltené be az adatokat
        return 0;
    }
}
