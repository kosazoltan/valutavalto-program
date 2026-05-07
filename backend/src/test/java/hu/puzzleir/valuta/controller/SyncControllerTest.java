package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.service.SyncService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SyncControllerTest {

    private final SyncService syncService = mock(SyncService.class);
    private final SyncController controller = new SyncController(syncService);

    @Test
    void syncFullReturnsOkForCompletedJob() {
        UUID branchId = UUID.randomUUID();
        SyncLogDto completed = SyncLogDto.builder()
                .branchId(branchId)
                .status("COMPLETED")
                .build();
        when(syncService.syncAll(branchId)).thenReturn(completed);

        ResponseEntity<SyncLogDto> response = controller.syncFull(branchId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(completed);
    }

    @Test
    void syncFullReturnsServiceUnavailableForFailedJob() {
        UUID branchId = UUID.randomUUID();
        SyncLogDto failed = SyncLogDto.builder()
                .branchId(branchId)
                .status("FAILED")
                .errorMessage("artifact write failed")
                .build();
        when(syncService.syncAll(branchId)).thenReturn(failed);

        ResponseEntity<SyncLogDto> response = controller.syncFull(branchId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }
}
