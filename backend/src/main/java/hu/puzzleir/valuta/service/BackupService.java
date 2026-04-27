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

    @Value("${spring.datasource.url:}")
    private String datasourceUrl;

    @Value("${spring.datasource.username:}")
    private String datasourceUsername;

    @Value("${spring.datasource.password:}")
    private String datasourcePassword;

    @Value("${app.backup.pg-dump-path:pg_dump}")
    private String pgDumpPath;

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

        // Valódi pg_dump mentés
        try {
            Path targetPath = Paths.get(filePath);
            String dbName = extractDbName(datasourceUrl);
            String host = extractHost(datasourceUrl);
            String port = extractPort(datasourceUrl);

            // AUDIT (audit-NO-GO-iter3 P1, 2026-04-27 + CodeQL java/relative-path-command):
            // a `pgDumpPath` default `"pg_dump"` (relativ utvonal). PATH-bol indulo
            // process-bedobas potencialisan manipulalhato (PATH override). A binarist
            // explicit absolute utvonalra resolveoljuk a hivas elott.
            String resolvedPgDumpPath = resolveAbsoluteExecutablePath(pgDumpPath, "pg_dump");

            ProcessBuilder pb = new ProcessBuilder(
                    resolvedPgDumpPath,
                    "-h", host,
                    "-p", port,
                    "-U", datasourceUsername,
                    "-d", dbName,
                    "-F", type == BackupType.FULL ? "c" : "p",  // custom format for FULL, plain SQL for others
                    "-f", targetPath.toString()
            );
            pb.environment().put("PGPASSWORD", datasourcePassword);
            pb.redirectErrorStream(true);

            log.info("pg_dump indítás: host={}, port={}, db={}, file={}", host, port, dbName, filePath);

            Process process = pb.start();
            String output = new String(process.getInputStream().readAllBytes());
            int exitCode = process.waitFor();

            if (exitCode != 0) {
                throw new IOException("pg_dump exit code: " + exitCode + ", output: " + output);
            }

            File file = targetPath.toFile();
            if (!file.exists() || file.length() == 0) {
                throw new IOException("pg_dump nem hozott létre érvényes fájlt: " + filePath);
            }

            record.setFileSizeBytes(file.length());
            record.setStatus(BackupStatus.COMPLETED);
            record.setCompletedAt(LocalDateTime.now());

            log.info("Backup sikeresen létrehozva: id={}, type={}, file={}, size={}",
                    record.getId(), type, filePath, file.length());
        } catch (IOException | InterruptedException | IllegalStateException e) {
            // IllegalStateException: resolveAbsoluteExecutablePath dobja, ha pg_dump
            // binary nem talalhato (audit-NO-GO-iter3 P1, CodeQL relative-path-command).
            record.setStatus(BackupStatus.FAILED);
            record.setCompletedAt(LocalDateTime.now());
            log.error("Backup mentés sikertelen: id={}, error={}", record.getId(), e.getMessage(), e);
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
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

        // Valódi pg_restore futtatás
        log.warn("Backup visszaállítás indítva: id={}, file={}", backupId, record.getFilePath());
        try {
            String dbName = extractDbName(datasourceUrl);
            String host = extractHost(datasourceUrl);
            String port = extractPort(datasourceUrl);

            ProcessBuilder pb = new ProcessBuilder(
                    "pg_restore",
                    "-h", host,
                    "-p", port,
                    "-U", datasourceUsername,
                    "-d", dbName,
                    "--clean",
                    "--if-exists",
                    record.getFilePath()
            );
            pb.environment().put("PGPASSWORD", datasourcePassword);
            pb.redirectErrorStream(true);

            Process process = pb.start();
            String output = new String(process.getInputStream().readAllBytes());
            int exitCode = process.waitFor();

            if (exitCode != 0) {
                throw new BusinessException("pg_restore hiba (exit " + exitCode + "): " + output, "RESTORE_FAILED");
            }

            log.info("Backup visszaállítás sikeres: id={}", backupId);
        } catch (IOException | InterruptedException e) {
            log.error("Backup visszaállítás sikertelen: id={}, error={}", backupId, e.getMessage(), e);
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new BusinessException("Visszaállítás sikertelen: " + e.getMessage(), "RESTORE_FAILED");
        }
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

    /**
     * JDBC URL-ből DB név kinyerése.
     * jdbc:postgresql://host:port/dbname?... → dbname
     */
    private String extractDbName(String jdbcUrl) {
        // jdbc:postgresql://host:port/dbname
        String withoutPrefix = jdbcUrl.replaceFirst("jdbc:postgresql://", "");
        String afterSlash = withoutPrefix.contains("/") ? withoutPrefix.substring(withoutPrefix.indexOf('/') + 1) : "valuta";
        return afterSlash.contains("?") ? afterSlash.substring(0, afterSlash.indexOf('?')) : afterSlash;
    }

    private String extractHost(String jdbcUrl) {
        String withoutPrefix = jdbcUrl.replaceFirst("jdbc:postgresql://", "");
        String hostPort = withoutPrefix.contains("/") ? withoutPrefix.substring(0, withoutPrefix.indexOf('/')) : withoutPrefix;
        return hostPort.contains(":") ? hostPort.substring(0, hostPort.indexOf(':')) : hostPort;
    }

    private String extractPort(String jdbcUrl) {
        String withoutPrefix = jdbcUrl.replaceFirst("jdbc:postgresql://", "");
        String hostPort = withoutPrefix.contains("/") ? withoutPrefix.substring(0, withoutPrefix.indexOf('/')) : withoutPrefix;
        return hostPort.contains(":") ? hostPort.substring(hostPort.indexOf(':') + 1) : "5432";
    }

    /**
     * Audit-fix (CodeQL java/relative-path-command, audit-NO-GO-iter3 P1, 2026-04-27):
     * relativ utvonal eseten a binarist explicit System.getenv("PATH")-bol resolveolja
     * absolute path-ra, igy a ProcessBuilder mar nem fugg a JVM `PATH` hasznalattol
     * (ami theoretice manipulalhato lenne pl. egy malicious local dir-rel).
     *
     * @param configured a `@Value`-bol erkezo (potencialisan relativ) ut
     * @param expectedBinaryName a binaris neve (pg_dump / psql) — ha a relativ eredetit
     *                           csak a binaris neve adja meg, ezzel keressuk a PATH-on
     * @return absolute, executable file path
     * @throws IllegalStateException ha a binaris nem talalhato
     */
    private String resolveAbsoluteExecutablePath(String configured, String expectedBinaryName) {
        if (configured == null || configured.isBlank()) {
            throw new IllegalStateException(expectedBinaryName + " path nincs konfiguralva");
        }
        Path configuredPath = Paths.get(configured);
        if (configuredPath.isAbsolute()) {
            if (Files.isExecutable(configuredPath)) {
                return configuredPath.toString();
            }
            throw new IllegalStateException(expectedBinaryName + " absolute path nem futtathato: " + configured);
        }
        // Relativ — explicit PATH lookup
        String pathEnv = System.getenv("PATH");
        if (pathEnv == null || pathEnv.isBlank()) {
            throw new IllegalStateException("PATH environment variable nincs beallitva, " + expectedBinaryName + " nem resolveable");
        }
        String[] suffixes = isWindows() ? new String[]{"", ".exe", ".bat", ".cmd"} : new String[]{""};
        for (String dir : pathEnv.split(java.io.File.pathSeparator)) {
            if (dir == null || dir.isBlank()) continue;
            for (String suffix : suffixes) {
                Path candidate = Paths.get(dir, configured + suffix);
                if (Files.isRegularFile(candidate) && Files.isExecutable(candidate)) {
                    return candidate.toAbsolutePath().toString();
                }
            }
        }
        throw new IllegalStateException(expectedBinaryName + " nem talalhato a PATH-on: " + configured);
    }

    private boolean isWindows() {
        String os = System.getProperty("os.name", "").toLowerCase(java.util.Locale.ROOT);
        return os.contains("win");
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
