package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.service.DariusReportService;
import hu.puzzleir.valuta.service.darius.DariusImportFileService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DariusReportControllerTest {

    private final DariusReportService dariusReportService = mock(DariusReportService.class);
    private final DariusImportFileService dariusImportFileService = mock(DariusImportFileService.class);
    private final DariusReportController controller =
            new DariusReportController(dariusReportService, dariusImportFileService);

    @Test
    void downloadImportFileReturnsAttachmentAndPassesParametersToService() {
        LocalDate date = LocalDate.of(2026, 7, 1);
        int erteknap = -1;
        byte[] content = "import-content".getBytes();
        when(dariusImportFileService.generateImportFile(date, erteknap))
                .thenReturn(new DariusImportFile("raiffeisen_import_BEST_2026-07-01.imp", content));

        ResponseEntity<byte[]> response = controller.downloadImportFile(date, erteknap);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getContentType()).isEqualTo(MediaType.APPLICATION_OCTET_STREAM);
        assertThat(response.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION))
                .isEqualTo("attachment; filename=\"raiffeisen_import_BEST_2026-07-01.imp\"");
        assertThat(response.getBody()).isEqualTo(content);
        verify(dariusImportFileService).generateImportFile(date, erteknap);
    }

    @Test
    void submitReturnsOkForSubmittedReport() {
        UUID reportId = UUID.randomUUID();
        DariusDailyReportDto submitted = DariusDailyReportDto.builder()
                .id(reportId)
                .status(DariusReportStatus.SUBMITTED.name())
                .build();
        when(dariusReportService.submitReport(reportId)).thenReturn(submitted);

        ResponseEntity<DariusDailyReportDto> response = controller.submit(reportId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(submitted);
    }

    @Test
    void submitReturnsServiceUnavailableForFailedReport() {
        UUID reportId = UUID.randomUUID();
        DariusDailyReportDto failed = DariusDailyReportDto.builder()
                .id(reportId)
                .status(DariusReportStatus.FAILED.name())
                .errorMessage("transport failed")
                .build();
        when(dariusReportService.submitReport(reportId)).thenReturn(failed);

        ResponseEntity<DariusDailyReportDto> response = controller.submit(reportId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }

    @Test
    void retryFailedReturnsServiceUnavailableWhenAnyReportFailed() {
        DariusDailyReportDto submitted = DariusDailyReportDto.builder()
                .status(DariusReportStatus.SUBMITTED.name())
                .build();
        DariusDailyReportDto failed = DariusDailyReportDto.builder()
                .status(DariusReportStatus.FAILED.name())
                .build();
        when(dariusReportService.retryFailedReports()).thenReturn(List.of(submitted, failed));

        ResponseEntity<List<DariusDailyReportDto>> response = controller.retryFailed();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).containsExactly(submitted, failed);
    }
}
