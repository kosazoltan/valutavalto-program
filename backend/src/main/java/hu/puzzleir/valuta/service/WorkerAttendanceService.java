package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.worker.WorkerAttendanceDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerAttendance;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerAttendanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Jelenleti nyilvantartas service — penztaros bejelentkezes/kijelentkezes tracking.
 * Legacy: jelenlet/ + idbeiro/ (munkaid, Excel export)
 *
 * H1 gap megoldas: Controller + Service reteg a meglevo Entity/Repository fole.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class WorkerAttendanceService {

    private final WorkerAttendanceRepository attendanceRepository;
    private final WorkerRepository workerRepository;

    /**
     * Bejelentkezes rogzitese — automatikusan hivodik login-nal.
     */
    @Transactional
    public WorkerAttendanceDto recordLogin(String ipAddress, String userAgent) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        UUID branchId = SecurityUtils.getCurrentBranchId();

        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        WorkerAttendance attendance = WorkerAttendance.builder()
                .worker(worker)
                .branchId(branchId)
                .loginAt(LocalDateTime.now())
                .ipAddress(ipAddress)
                .userAgent(userAgent != null && userAgent.length() > 500 ? userAgent.substring(0, 500) : userAgent)
                .build();

        attendance = attendanceRepository.save(attendance);
        log.info("Jelenlét rögzítve: worker={}, branch={}, login={}", workerId, branchId, attendance.getLoginAt());
        return WorkerAttendanceDto.from(attendance);
    }

    /**
     * Kijelentkezes rogzitese — logout-nal vagy session lejaratkor.
     */
    @Transactional
    public WorkerAttendanceDto recordLogout(UUID attendanceId) {
        WorkerAttendance attendance = attendanceRepository.findById(attendanceId)
                .orElseThrow(() -> new ResourceNotFoundException("Jelenlét bejegyzés nem található: " + attendanceId));

        if (attendance.getLogoutAt() != null) {
            throw new ValidationException("A kijelentkezés már rögzítve van!");
        }

        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        if (!attendance.getWorker().getId().equals(currentWorkerId) && !SecurityUtils.isManagerOrAbove()) {
            throw new ValidationException("Nincs jogosultság más dolgozó kijelentkezéséhez!");
        }

        attendance.setLogoutAt(LocalDateTime.now());
        attendance = attendanceRepository.save(attendance);

        long minutes = ChronoUnit.MINUTES.between(attendance.getLoginAt(), attendance.getLogoutAt());
        log.info("Kijelentkezés rögzítve: worker={}, duration={}min", attendance.getWorker().getId(), minutes);
        return WorkerAttendanceDto.from(attendance);
    }

    /**
     * Sajat jelenleti naplo lekerdezese.
     */
    public Page<WorkerAttendanceDto> getMyAttendance(LocalDate from, LocalDate to, Pageable pageable) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return getAttendanceByWorker(workerId, from, to, pageable);
    }

    /**
     * Dolgozo jelenleti naplojanak lekerdezese (supervisor+).
     */
    public Page<WorkerAttendanceDto> getAttendanceByWorker(Long workerId, LocalDate from, LocalDate to,
                                                            Pageable pageable) {
        if (from != null && to != null) {
            LocalDateTime fromDt = from.atStartOfDay();
            LocalDateTime toDt = to.atTime(LocalTime.MAX);
            return attendanceRepository.findByWorkerIdAndDateRange(workerId, fromDt, toDt, pageable)
                    .map(WorkerAttendanceDto::from);
        }
        return attendanceRepository.findByWorkerId(workerId, pageable)
                .map(WorkerAttendanceDto::from);
    }
}
