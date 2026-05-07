package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.backup.BackupRecordResponse;
import hu.puzzleir.valuta.dto.backup.CreateBackupRequest;
import hu.puzzleir.valuta.entity.BackupStatus;
import hu.puzzleir.valuta.entity.BackupType;
import hu.puzzleir.valuta.service.BackupService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.security.Principal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BackupControllerTest {

    private final BackupService backupService = mock(BackupService.class);
    private final BackupController controller = new BackupController(backupService);
    private final Principal adminPrincipal = () -> "admin-user";

    @Test
    void createBackupReturnsOkForCompletedBackup() {
        CreateBackupRequest request = createRequest();
        BackupRecordResponse completed = BackupRecordResponse.builder()
                .backupType(BackupType.FULL)
                .status(BackupStatus.COMPLETED)
                .build();
        when(backupService.createBackup(BackupType.FULL, "admin-user")).thenReturn(completed);

        ResponseEntity<BackupRecordResponse> response = controller.createBackup(request, adminPrincipal);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(completed);
    }

    @Test
    void createBackupReturnsServiceUnavailableForFailedBackup() {
        CreateBackupRequest request = createRequest();
        BackupRecordResponse failed = BackupRecordResponse.builder()
                .backupType(BackupType.FULL)
                .status(BackupStatus.FAILED)
                .build();
        when(backupService.createBackup(BackupType.FULL, "admin-user")).thenReturn(failed);

        ResponseEntity<BackupRecordResponse> response = controller.createBackup(request, adminPrincipal);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }

    @Test
    void createBackupReturnsAcceptedForRunningBackup() {
        CreateBackupRequest request = createRequest();
        BackupRecordResponse running = BackupRecordResponse.builder()
                .backupType(BackupType.FULL)
                .status(BackupStatus.RUNNING)
                .build();
        when(backupService.createBackup(BackupType.FULL, "admin-user")).thenReturn(running);

        ResponseEntity<BackupRecordResponse> response = controller.createBackup(request, adminPrincipal);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ACCEPTED);
        assertThat(response.getBody()).isSameAs(running);
    }

    @Test
    void createBackupUsesUnknownWhenPrincipalMissing() {
        CreateBackupRequest request = createRequest();
        BackupRecordResponse completed = BackupRecordResponse.builder()
                .backupType(BackupType.FULL)
                .status(BackupStatus.COMPLETED)
                .build();
        when(backupService.createBackup(BackupType.FULL, "unknown")).thenReturn(completed);

        ResponseEntity<BackupRecordResponse> response = controller.createBackup(request, null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(completed);
    }

    private CreateBackupRequest createRequest() {
        CreateBackupRequest request = new CreateBackupRequest();
        request.setType(BackupType.FULL);
        return request;
    }
}
