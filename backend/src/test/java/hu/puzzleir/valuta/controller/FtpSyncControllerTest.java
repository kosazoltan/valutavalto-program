package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ftpsync.FtpSyncResultDto;
import hu.puzzleir.valuta.service.FtpSyncService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class FtpSyncControllerTest {

    private final FtpSyncService ftpSyncService = mock(FtpSyncService.class);
    private final FtpSyncController controller = new FtpSyncController(ftpSyncService);

    @Test
    void syncRatesReturnsOkForSuccess() {
        UUID branchId = UUID.randomUUID();
        FtpSyncResultDto success = FtpSyncResultDto.builder()
                .success(true)
                .message("ok")
                .build();
        when(ftpSyncService.syncRateFile(branchId)).thenReturn(success);

        ResponseEntity<FtpSyncResultDto> response = controller.syncRates(branchId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(success);
    }

    @Test
    void syncRatesReturnsServiceUnavailableForFailure() {
        UUID branchId = UUID.randomUUID();
        FtpSyncResultDto failed = FtpSyncResultDto.builder()
                .success(false)
                .message("artifact write failed")
                .build();
        when(ftpSyncService.syncRateFile(branchId)).thenReturn(failed);

        ResponseEntity<FtpSyncResultDto> response = controller.syncRates(branchId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }
}
