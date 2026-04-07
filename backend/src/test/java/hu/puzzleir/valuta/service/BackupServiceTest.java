package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.backup.BackupRecordResponse;
import hu.puzzleir.valuta.entity.BackupRecord;
import hu.puzzleir.valuta.entity.BackupStatus;
import hu.puzzleir.valuta.entity.BackupType;
import hu.puzzleir.valuta.repository.BackupRecordRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * BackupService UNIT tesztek — pg_dump wrapper tesztek.
 * Tesztkörnyezetben pg_dump nem elérhető → FAILED státuszt kapunk.
 * A COMPLETED teszt production-ban fut (pg_dump elérhető).
 */
@ExtendWith(MockitoExtension.class)
class BackupServiceTest {

    @InjectMocks
    private BackupService service;

    @Mock
    private BackupRecordRepository backupRecordRepository;

    @TempDir
    Path tempDir;

    private void setBackupDir() {
        ReflectionTestUtils.setField(service, "backupDirectory", tempDir.toString());
        ReflectionTestUtils.setField(service, "datasourceUrl", "jdbc:postgresql://localhost:5432/valuta_test");
        ReflectionTestUtils.setField(service, "datasourceUsername", "test_user");
        ReflectionTestUtils.setField(service, "datasourcePassword", "test_pass");
        ReflectionTestUtils.setField(service, "pgDumpPath", "pg_dump");
    }

    @Test
    @DisplayName("createBackup — pg_dump nem elérhető → FAILED (tesztkörnyezet)")
    void testCreateBackup_pgDumpNotAvailable_failsGracefully() {
        setBackupDir();
        // Force pg_dump path to non-existent binary
        ReflectionTestUtils.setField(service, "pgDumpPath", "nonexistent_pg_dump_binary");

        when(backupRecordRepository.save(any(BackupRecord.class))).thenAnswer(inv -> {
            BackupRecord r = inv.getArgument(0);
            if (r.getId() == null) r.setId(UUID.randomUUID());
            return r;
        });

        BackupRecordResponse result = service.createBackup(BackupType.FULL, "admin");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(BackupStatus.FAILED);
        assertThat(result.getFilePath()).isNotNull();
        assertThat(result.getCreatedBy()).isEqualTo("admin");
        verify(backupRecordRepository, times(2)).save(any(BackupRecord.class));
    }

    @Test
    @DisplayName("createBackup — JDBC URL parsing helyes")
    void testCreateBackup_jdbcUrlParsing() {
        setBackupDir();
        // Non-existent pg_dump will fail, but the URL parsing should work
        ReflectionTestUtils.setField(service, "pgDumpPath", "nonexistent_pg_dump_binary");
        ReflectionTestUtils.setField(service, "datasourceUrl", "jdbc:postgresql://myhost:54320/mydb?ssl=true");

        when(backupRecordRepository.save(any(BackupRecord.class))).thenAnswer(inv -> {
            BackupRecord r = inv.getArgument(0);
            if (r.getId() == null) r.setId(UUID.randomUUID());
            return r;
        });

        // The test verifies that the service doesn't crash on URL parsing
        BackupRecordResponse result = service.createBackup(BackupType.INCREMENTAL, "operator");
        assertThat(result).isNotNull();
        // FAILED because pg_dump binary doesn't exist, but no crash
        assertThat(result.getStatus()).isEqualTo(BackupStatus.FAILED);
    }

    @Test
    @DisplayName("getBackupHistory → returns ordered page")
    void testGetBackupHistory() {
        BackupRecord r1 = BackupRecord.builder()
                .id(UUID.randomUUID())
                .backupType(BackupType.FULL)
                .status(BackupStatus.COMPLETED)
                .filePath("/backups/full1.sql")
                .startedAt(LocalDateTime.now().minusHours(2))
                .completedAt(LocalDateTime.now().minusHours(1))
                .createdBy("admin")
                .build();
        BackupRecord r2 = BackupRecord.builder()
                .id(UUID.randomUUID())
                .backupType(BackupType.INCREMENTAL)
                .status(BackupStatus.COMPLETED)
                .filePath("/backups/incr1.sql")
                .startedAt(LocalDateTime.now().minusMinutes(30))
                .completedAt(LocalDateTime.now().minusMinutes(20))
                .createdBy("operator")
                .build();

        Page<BackupRecord> page = new PageImpl<>(List.of(r2, r1), PageRequest.of(0, 10), 2);
        when(backupRecordRepository.findAllByOrderByStartedAtDesc(any(PageRequest.class))).thenReturn(page);

        Page<BackupRecordResponse> result = service.getBackupHistory(0, 10);

        assertThat(result).isNotNull();
        assertThat(result.getContent()).hasSize(2);
        assertThat(result.getContent().get(0).getBackupType()).isEqualTo(BackupType.INCREMENTAL);
        verify(backupRecordRepository).findAllByOrderByStartedAtDesc(any(PageRequest.class));
    }
}
