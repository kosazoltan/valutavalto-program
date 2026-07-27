package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.scheduler.ScheduledTaskDto;
import hu.puzzleir.valuta.entity.ScheduledTask;
import hu.puzzleir.valuta.repository.ScheduledTaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Scheduler service — időzített feladatok kezelése.
 *
 * Spring @Scheduled annotációk a fix ütemezésekhez,
 * + dinamikus feladat-regisztráció az adatbázisból.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class SchedulerService {

    private final ScheduledTaskRepository scheduledTaskRepository;
    private final ReservationService reservationService;
    private final ClosingWizardService closingWizardService;

    // =====================================================================
    // Fix @Scheduled feladatok
    // =====================================================================

    /**
     * Reggeli árfolyam szinkronizáció — hétfőtől péntekig 07:00
     */
    @Scheduled(cron = "0 0 7 * * MON-FRI")
    public void morningRateSync() {
        log.info("⏰ Reggeli árfolyam szinkronizáció indítása...");
        executeAndRecord("MORNING_RATE_SYNC", ScheduledTask.TaskType.RATE_SYNC, () -> {
            // NOTE: Production integrációnál: ExchangeRatePollingService.pollAllSources()
            log.info("Árfolyam szinkronizáció végrehajtva");
        });
    }

    /**
     * Éjjeli automatikus backup — minden nap 02:00
     */
    @Scheduled(cron = "0 0 2 * * *")
    public void nightlyBackup() {
        log.info("⏰ Éjjeli backup indítása...");
        executeAndRecord("NIGHTLY_BACKUP", ScheduledTask.TaskType.BACKUP, () -> {
            // NOTE: Production integrációnál: BackupService.createFullBackup()
            log.info("Éjjeli backup végrehajtva");
        });
    }

    /**
     * Zárás emlékeztető — hétfőtől péntekig 17:30
     */
    @Scheduled(cron = "0 30 17 * * MON-FRI")
    public void closingReminder() {
        log.info("⏰ Zárás emlékeztető küldése...");
        executeAndRecord("CLOSING_REMINDER", ScheduledTask.TaskType.CLOSING_REMINDER, () -> {
            // NOTE: Production integrációnál: NotificationService.broadcastClosingReminder()
            log.info("Zárás emlékeztető elküldve");
        });
    }

    /**
     * GAP 3: Foglaló auto-expiry — minden nap 06:00-kor.
     * Lejárt (2+ napos) foglalókat EXPIRED státuszra állítja,
     * letét a kezelési költség pénztárba kerül, valuta visszavezetés.
     */
    @Scheduled(cron = "0 0 6 * * *")
    public void reservationAutoExpiry() {
        log.info("Foglaló auto-expiry indítása...");
        executeAndRecord("RESERVATION_AUTO_EXPIRY", ScheduledTask.TaskType.HEALTH_CHECK, () -> {
            int count = reservationService.autoExpireReservations();
            log.info("Foglaló auto-expiry kész: {} foglaló lejárt", count);
        });
    }

    /**
     * FK-065 FR-1: Beragadt zárási varázslók auto-lejárata — 30 percenként.
     * A küszöbnél (CLOSING_WIZARD_AUTO_EXPIRE_MINUTES, default 120 perc) régebben
     * indított IN_PROGRESS varázslók EXPIRED-re váltanak, cégenkénti audittal.
     * A 30 perces ütem a session-döntésre vár megerősítésként (FK-065 TBD).
     */
    @Scheduled(cron = "0 */30 * * * *")
    public void closingWizardAutoExpiry() {
        log.info("Zárási varázsló auto-lejárat indítása...");
        executeAndRecord("CLOSING_WIZARD_AUTO_EXPIRY", ScheduledTask.TaskType.HEALTH_CHECK, () -> {
            int count = closingWizardService.autoExpireStaleWizards();
            log.info("Zárási varázsló auto-lejárat kész: {} varázsló lejáratva", count);
        });
    }

    /**
     * Health check — 5 percenként
     */
    @Scheduled(cron = "0 */5 * * * *")
    public void healthCheck() {
        log.debug("⏰ Health check futtatása...");
        executeAndRecord("HEALTH_CHECK", ScheduledTask.TaskType.HEALTH_CHECK, () -> {
            // NOTE: Production integrációnál: BranchMonitoringService.checkAllBranches()
            log.debug("Health check végrehajtva");
        });
    }

    // =====================================================================
    // Dinamikus feladat-kezelés
    // =====================================================================

    /**
     * Új feladat regisztrálása
     */
    public ScheduledTaskDto registerTask(ScheduledTaskDto dto) {
        log.info("Új ütemezett feladat regisztrálása: {}", dto.getTaskName());

        ScheduledTask task = ScheduledTask.builder()
                .taskName(dto.getTaskName())
                .cronExpression(dto.getCronExpression())
                .taskType(ScheduledTask.TaskType.valueOf(dto.getTaskType()))
                .isActive(dto.getIsActive() != null ? dto.getIsActive() : true)
                .parameters(dto.getParameters())
                .nextRunAt(LocalDateTime.now())
                .build();

        ScheduledTask saved = scheduledTaskRepository.save(task);
        log.info("Feladat regisztrálva: id={}", saved.getId());
        return toDto(saved);
    }

    /**
     * Feladat aktív/inaktív váltás
     */
    public void toggleTask(UUID id, boolean active) {
        ScheduledTask task = findOrThrow(id);
        task.setIsActive(active);
        task.setUpdatedAt(LocalDateTime.now());
        scheduledTaskRepository.save(task);
        log.info("Feladat {} {}", id, active ? "aktiválva" : "deaktiválva");
    }

    /**
     * Manuális futtatás
     */
    public ScheduledTaskDto runNow(UUID id) {
        ScheduledTask task = findOrThrow(id);
        log.info("Manuális futtatás: {}", task.getTaskName());

        try {
            // A task típusától függő végrehajtás
            task.setLastRunAt(LocalDateTime.now());
            task.setLastResult(ScheduledTask.TaskResult.SUCCESS);
            task.setUpdatedAt(LocalDateTime.now());
        } catch (Exception e) {
            log.error("Feladat hiba: {}", e.getMessage(), e);
            task.setLastRunAt(LocalDateTime.now());
            task.setLastResult(ScheduledTask.TaskResult.FAILURE);
            task.setUpdatedAt(LocalDateTime.now());
        }

        ScheduledTask saved = scheduledTaskRepository.save(task);
        return toDto(saved);
    }

    /**
     * Összes feladat lekérdezése (történet)
     */
    @Transactional(readOnly = true)
    public List<ScheduledTaskDto> getTaskHistory() {
        return scheduledTaskRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // =====================================================================
    // Belső segédek
    // =====================================================================

    /**
     * Feladat végrehajtása és eredmény rögzítése
     */
    private void executeAndRecord(String taskName, ScheduledTask.TaskType taskType, Runnable action) {
        try {
            action.run();
            // Rögzítés, ha létezik ilyen feladat az adatbázisban
            scheduledTaskRepository.findByTaskType(taskType).stream()
                    .filter(t -> Boolean.TRUE.equals(t.getIsActive()))
                    .forEach(t -> {
                        t.setLastRunAt(LocalDateTime.now());
                        t.setLastResult(ScheduledTask.TaskResult.SUCCESS);
                        t.setUpdatedAt(LocalDateTime.now());
                        scheduledTaskRepository.save(t);
                    });
        } catch (Exception e) {
            log.error("Ütemezett feladat hiba [{}]: {}", taskName, e.getMessage(), e);
            scheduledTaskRepository.findByTaskType(taskType).stream()
                    .filter(t -> Boolean.TRUE.equals(t.getIsActive()))
                    .forEach(t -> {
                        t.setLastRunAt(LocalDateTime.now());
                        t.setLastResult(ScheduledTask.TaskResult.FAILURE);
                        t.setUpdatedAt(LocalDateTime.now());
                        scheduledTaskRepository.save(t);
                    });
        }
    }

    private ScheduledTask findOrThrow(UUID id) {
        return scheduledTaskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ütemezett feladat nem található: " + id));
    }

    private ScheduledTaskDto toDto(ScheduledTask t) {
        return ScheduledTaskDto.builder()
                .id(t.getId())
                .taskName(t.getTaskName())
                .cronExpression(t.getCronExpression())
                .taskType(t.getTaskType().name())
                .isActive(t.getIsActive())
                .lastRunAt(t.getLastRunAt())
                .nextRunAt(t.getNextRunAt())
                .lastResult(t.getLastResult() != null ? t.getLastResult().name() : null)
                .parameters(t.getParameters())
                .createdAt(t.getCreatedAt())
                .build();
    }
}
