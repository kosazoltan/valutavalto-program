package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.validation.PasswordPolicy;
import hu.puzzleir.valuta.service.WorkerManagementService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class WorkerManagementControllerTest {

    private final WorkerManagementService workerManagementService = mock(WorkerManagementService.class);
    private final WorkerManagementController controller = new WorkerManagementController(workerManagementService);

    @Test
    void resetPasswordRejectsShortPasswordBeforeServiceCall() {
        ResponseEntity<Void> response = controller.resetPassword(
                42L, Map.of("newPassword", passwordOfLength(PasswordPolicy.MIN_LENGTH - 1)));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(workerManagementService);
    }

    @Test
    void resetPasswordRejectsOverMaximumPasswordBeforeServiceCall() {
        ResponseEntity<Void> response = controller.resetPassword(
                42L, Map.of("newPassword", passwordOfLength(PasswordPolicy.MAX_LENGTH + 1)));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(workerManagementService);
    }

    @Test
    void resetPasswordAcceptsEightCharacterPassword() {
        String password = passwordOfLength(PasswordPolicy.MIN_LENGTH);

        ResponseEntity<Void> response = controller.resetPassword(42L, Map.of("newPassword", password));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(workerManagementService).resetPassword(42L, password);
    }

    private String passwordOfLength(int length) {
        return "A1" + "a".repeat(length - 2);
    }
}
