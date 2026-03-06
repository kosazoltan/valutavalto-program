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
 * BackupService UNIT tesztek — Mockito.
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
    }

    @Test
    @DisplayName("createBackup FULL → COMPLETED status, filePath set")
    void testCreateBackup_full() {
        setBackupDir();

        when(backupRecordRepository.save(any(BackupRecord.class))).thenAnswer(inv -> {
            BackupRecord r = inv.getArgument(0);
            if (r.getId() == null) r.setId(UUID.randomUUID());
            return r;
        });

        BackupRecordResponse result = service.createBackup(BackupType.FULL, "admin");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(BackupStatus.COMPLETED);
        assertThat(result.getFilePath()).isNotNull();
        assertThat(result.getFilePath()).contains("full");
        assertThat(result.getCreatedBy()).isEqualTo("admin");
        verify(backupRecordRepository, times(2)).save(any(BackupRecord.class));
    }

    @Test
    @DisplayName("createBackup INCREMENTAL → COMPLETED")
    void testCreateBackup_incremental() {
        setBackupDir();

        when(backupRecordRepository.save(any(BackupRecord.class))).thenAnswer(inv -> {
            BackupRecord r = inv.getArgument(0);
            if (r.getId() == null) r.setId(UUID.randomUUID());
            return r;
        });

        BackupRecordResponse result = service.createBackup(BackupType.INCREMENTAL, "operator");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(BackupStatus.COMPLETED);
        assertThat(result.getFilePath()).contains("incremental");
        verify(backupRecordRepository, times(2)).save(any(BackupRecord.class));
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
