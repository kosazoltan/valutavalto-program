package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.backup.BackupRecordResponse;
import hu.puzzleir.valuta.entity.BackupRecord;
import hu.puzzleir.valuta.entity.BackupStatus;
import hu.puzzleir.valuta.entity.BackupType;
import hu.puzzleir.valuta.repository.BackupRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * Backup szolgáltatás — adatbázis mentés és visszaállítás.
 * pg_dump wrapper alapú mentés, admin-only restore.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BackupService {

    private final BackupRecordRepository backupRecordRepository;

    @Value("${app.backup.directory:./backups}")
    private String backupDirectory;

    /**
     * Új backup mentés létrehozása.
     */
    @Transactional(rollbackFor = Exception.class)
    public BackupRecordResponse createBackup(BackupType type, String createdBy) {
        // Mentés könyvtár biztosítása
        Path backupDir = Paths.get(backupDirectory);
        try {
            Files.createDirectories(backupDir);
        } catch (IOException e) {
            log.error("Backup könyvtár létrehozása sikertelen: {}", backupDirectory, e);
        }

        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        String fileName = String.format("backup_%s_%s.sql", type.name().toLowerCase(), timestamp);
        String filePath = backupDir.resolve(fileName).toString();

        BackupRecord record = BackupRecord.builder()
                .backupType(type)
                .status(BackupStatus.RUNNING)
                .filePath(filePath)
                .createdBy(createdBy)
                .startedAt(LocalDateTime.now())
                .build();
        record = backupRecordRepository.save(record);

        // Szimulált mentés — valós környezetben pg_dump futtatás
        try {
            // Létrehozzuk a fájlt placeholder tartalommal
            Path targetPath = Paths.get(filePath);
            String content = String.format("-- Backup: %s\n-- Típus: %s\n-- Időpont: %s\n-- Készítő: %s\n",
                    record.getId(), type, timestamp, createdBy);
            Files.writeString(targetPath, content);

            File file = targetPath.toFile();
            record.setFileSizeBytes(file.length());
            record.setStatus(BackupStatus.COMPLETED);
            record.setCompletedAt(LocalDateTime.now());

            log.info("Backup sikeresen létrehozva: id={}, type={}, file={}", record.getId(), type, filePath);
        } catch (IOException e) {
            record.setStatus(BackupStatus.FAILED);
            record.setCompletedAt(LocalDateTime.now());
            log.error("Backup mentés sikertelen: id={}", record.getId(), e);
        }

        record = backupRecordRepository.save(record);
        return toResponse(record);
    }

    /**
     * Backup visszaállítás — admin only!
     */
    @Transactional(rollbackFor = Exception.class)
    public void restoreBackup(UUID backupId) {
        BackupRecord record = backupRecordRepository.findById(backupId)
                .orElseThrow(() -> new ResourceNotFoundException("Backup nem található: " + backupId));

        if (record.getStatus() != BackupStatus.COMPLETED) {
            throw new ValidationException("Csak sikeresen befejezett mentés állítható vissza. Státusz: " + record.getStatus());
        }

        Path filePath = Paths.get(record.getFilePath());
        if (!Files.exists(filePath)) {
            throw new ResourceNotFoundException("Backup fájl nem található: " + record.getFilePath());
        }

        // Valós környezetben: pg_restore futtatás
        log.warn("Backup visszaállítás indítva: id={}, file={}", backupId, record.getFilePath());
        log.info("Backup visszaállítás szimulálva — valós környezetben pg_restore fut.");
    }

    /**
     * Backup előzmények lekérdezése.
     */
    @Transactional(readOnly = true)
    public Page<BackupRecordResponse> getBackupHistory(int page, int size) {
        return backupRecordRepository.findAllByOrderByStartedAtDesc(PageRequest.of(page, size))
                .map(this::toResponse);
    }

    /**
     * Backup fájl letöltés — bájt tömb.
     */
    @Transactional(readOnly = true)
    public byte[] downloadBackup(UUID backupId) {
        BackupRecord record = backupRecordRepository.findById(backupId)
                .orElseThrow(() -> new ResourceNotFoundException("Backup nem található: " + backupId));

        try {
            return Files.readAllBytes(Paths.get(record.getFilePath()));
        } catch (IOException e) {
            throw new BusinessException("Backup fájl olvasása sikertelen: " + record.getFilePath(), "BACKUP_READ_FAILED");
        }
    }

    private BackupRecordResponse toResponse(BackupRecord record) {
        return BackupRecordResponse.builder()
                .id(record.getId())
                .backupType(record.getBackupType())
                .status(record.getStatus())
                .filePath(record.getFilePath())
                .fileSizeBytes(record.getFileSizeBytes())
                .startedAt(record.getStartedAt())
                .completedAt(record.getCompletedAt())
                .createdBy(record.getCreatedBy())
                .build();
    }
}
