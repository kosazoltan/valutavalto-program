package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.CameraExportRequest;
import hu.puzzleir.valuta.entity.CameraExportStatus;
import hu.puzzleir.valuta.service.CameraExportService;
import hu.puzzleir.valuta.service.CameraHashChainService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CameraExportControllerTest {

    private final CameraExportService exportService = mock(CameraExportService.class);
    private final CameraHashChainService hashChainService = mock(CameraHashChainService.class);
    private final CameraExportController controller = new CameraExportController(exportService, hashChainService);

    @Test
    void executeReturnsOkForCompletedExport() {
        UUID requestId = UUID.randomUUID();
        CameraExportRequest completed = CameraExportRequest.builder()
                .id(requestId)
                .status(CameraExportStatus.COMPLETED)
                .build();
        when(exportService.executeExport(requestId)).thenReturn(completed);

        ResponseEntity<CameraExportRequest> response = controller.execute(requestId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(completed);
    }

    @Test
    void executeReturnsServiceUnavailableForFailedExport() {
        UUID requestId = UUID.randomUUID();
        CameraExportRequest failed = CameraExportRequest.builder()
                .id(requestId)
                .status(CameraExportStatus.FAILED)
                .errorMessage("manifest write failed")
                .build();
        when(exportService.executeExport(requestId)).thenReturn(failed);

        ResponseEntity<CameraExportRequest> response = controller.execute(requestId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
        assertThat(response.getBody()).extracting(CameraExportRequest::getErrorMessage)
                .isEqualTo("manifest write failed");
    }

    @Test
    void executeReturnsAcceptedForExportingRequest() {
        UUID requestId = UUID.randomUUID();
        CameraExportRequest exporting = CameraExportRequest.builder()
                .id(requestId)
                .status(CameraExportStatus.EXPORTING)
                .build();
        when(exportService.executeExport(requestId)).thenReturn(exporting);

        ResponseEntity<CameraExportRequest> response = controller.execute(requestId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.ACCEPTED);
        assertThat(response.getBody()).isSameAs(exporting);
    }

    @Test
    void executeReturnsServiceUnavailableWhenStatusMissing() {
        UUID requestId = UUID.randomUUID();
        CameraExportRequest missingStatus = CameraExportRequest.builder()
                .id(requestId)
                .build();
        missingStatus.setStatus(null);
        when(exportService.executeExport(requestId)).thenReturn(missingStatus);

        ResponseEntity<CameraExportRequest> response = controller.execute(requestId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(missingStatus);
    }
}
