package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.worker.WorkerAttendanceDto;
import hu.puzzleir.valuta.dto.worker.WorkerBreakDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerAttendance;
import hu.puzzleir.valuta.entity.WorkerBreak;
import hu.puzzleir.valuta.repository.WorkerAttendanceRepository;
import hu.puzzleir.valuta.repository.WorkerBreakRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztáros kezelés — jelenlét napló, szünet kezelés, jelszó reset.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerManagementService {

    private final WorkerRepository workerRepository;
    private final WorkerAttendanceRepository attendanceRepository;
    private final WorkerBreakRepository breakRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditLogService auditLogService;

    /**
     * Jelenlét napló lekérdezés.
     */
    @Transactional(readOnly = true)
    public Page<WorkerAttendanceDto> getAttendance(Long workerId, Pageable pageable) {
        // Multi-tenant check
        Worker worker = getWorkerWithCheck(workerId);
        return attendanceRepository.findByWorkerId(workerId, pageable)
                .map(WorkerAttendanceDto::from);
    }

    /**
     * Jelszó reset (admin funkció).
     */
    @Transactional
    public void resetPassword(Long workerId, String newPassword) {
        Worker worker = getWorkerWithCheck(workerId);
        worker.setPasswordHash(passwordEncoder.encode(newPassword));
        worker.setPasswordChangedAt(LocalDateTime.now());
        workerRepository.save(worker);

        String userId = String.valueOf(SecurityUtils.getCurrentWorkerId());
        auditLogService.log(
                "PASSWORD_RESET",
                "WORKER",
                String.valueOf(workerId),
                userId,
                SecurityUtils.getCurrentWorkerCode(),
                null, null,
                "Jelszó reset: " + worker.getCode(),
                null, null
        );

        log.info("[WorkerMgmt] Jelszó reset: worker={} by={}", workerId, userId);
    }

    /**
     * Szünet indítás.
     */
    @Transactional
    public WorkerBreakDto startBreak(Long workerId, String reason) {
        Worker worker = getWorkerWithCheck(workerId);

        // Ellenőrzés: van-e már aktív szünet
        breakRepository.findActiveBreak(workerId).ifPresent(b -> {
            throw new ValidationException("A pénztárosnak már van aktív szünete!");
        });

        UUID branchId = SecurityUtils.getCurrentBranchId();

        WorkerBreak wb = WorkerBreak.builder()
                .worker(worker)
                .branchId(branchId)
                .breakStart(LocalDateTime.now())
                .reason(reason)
                .approvedBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        wb = breakRepository.save(wb);
        log.info("[WorkerMgmt] Szünet indítás: worker={} reason={}", workerId, reason);
        return WorkerBreakDto.from(wb);
    }

    /**
     * Szünet befejezés.
     */
    @Transactional
    public WorkerBreakDto endBreak(Long workerId) {
        getWorkerWithCheck(workerId);

        WorkerBreak wb = breakRepository.findActiveBreak(workerId)
                .orElseThrow(() -> new ValidationException("Nincs aktív szünet ehhez a pénztároshoz!"));

        wb.setBreakEnd(LocalDateTime.now());
        wb = breakRepository.save(wb);
        log.info("[WorkerMgmt] Szünet vége: worker={}", workerId);
        return WorkerBreakDto.from(wb);
    }

    /**
     * Worker lekérés multi-tenant ellenőrzéssel.
     */
    private Worker getWorkerWithCheck(Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        return worker;
    }
}
