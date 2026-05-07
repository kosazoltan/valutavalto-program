package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.service.MnbReportService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MnbReportControllerTest {

    private final MnbReportService mnbReportService = mock(MnbReportService.class);
    private final MnbReportController controller = new MnbReportController(mnbReportService);

    @Test
    void submitReportReturnsOkForSuccessfulSubmission() {
        UUID reportId = UUID.randomUUID();
        MnbSubmissionResult success = MnbSubmissionResult.builder()
                .success(true)
                .referenceNumber("MNB-123")
                .build();
        when(mnbReportService.submitReport(reportId)).thenReturn(success);

        ResponseEntity<MnbSubmissionResult> response = controller.submitReport(reportId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(success);
    }

    @Test
    void submitReportReturnsServiceUnavailableForFailedSubmission() {
        UUID reportId = UUID.randomUUID();
        MnbSubmissionResult failed = MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("MNB transport rejected")
                .build();
        when(mnbReportService.submitReport(reportId)).thenReturn(failed);

        ResponseEntity<MnbSubmissionResult> response = controller.submitReport(reportId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isSameAs(failed);
    }
}
