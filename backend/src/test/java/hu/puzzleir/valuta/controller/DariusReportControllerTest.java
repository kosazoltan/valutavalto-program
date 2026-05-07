package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.service.DariusReportService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DariusReportControllerTest {

    private final DariusReportService dariusReportService = mock(DariusReportService.class);
    private final DariusReportController controller = new DariusReportController(dariusReportService);

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

    @Test
    void retryFailedReturnsOkWhenAllReportsSubmitted() {
        DariusDailyReportDto firstSubmitted = DariusDailyReportDto.builder()
                .status(DariusReportStatus.SUBMITTED.name())
                .build();
        DariusDailyReportDto secondSubmitted = DariusDailyReportDto.builder()
                .status(DariusReportStatus.ACKNOWLEDGED.name())
                .build();
        when(dariusReportService.retryFailedReports()).thenReturn(List.of(firstSubmitted, secondSubmitted));

        ResponseEntity<List<DariusDailyReportDto>> response = controller.retryFailed();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsExactly(firstSubmitted, secondSubmitted);
    }
}
