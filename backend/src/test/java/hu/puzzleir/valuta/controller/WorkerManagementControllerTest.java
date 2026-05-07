package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.WorkerManagementService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class WorkerManagementControllerTest {

    private final WorkerManagementService workerManagementService = mock(WorkerManagementService.class);
    private final WorkerManagementController controller = new WorkerManagementController(workerManagementService);

    @Test
    void resetPasswordRejectsShortPasswordBeforeServiceCall() {
        ResponseEntity<Void> response = controller.resetPassword(42L, Map.of("newPassword", "1234567"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verify(workerManagementService, never()).resetPassword(42L, "1234567");
    }

    @Test
    void resetPasswordAcceptsEightCharacterPassword() {
        ResponseEntity<Void> response = controller.resetPassword(42L, Map.of("newPassword", "12345678"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(workerManagementService).resetPassword(42L, "12345678");
    }
}
