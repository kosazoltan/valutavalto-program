package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.exception.ErrorResponse;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.EmailAccountService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class EmailAccountControllerTest {

    private final EmailAccountService emailAccountService = mock(EmailAccountService.class);
    private final EmailAccountController controller = new EmailAccountController(emailAccountService);

    @Test
    @DisplayName("Email admin endpoint null activeRole esetén ValidationException-t ad, nem NPE/500-at")
    void adminEndpointRejectsNullActiveRoleAsValidationError() {
        Authentication auth = authenticationWithBackwardCompatibleDetails();

        Throwable thrown = catchThrowable(() -> controller.delete(UUID.randomUUID(), auth));

        assertThat(thrown)
                .isInstanceOf(ValidationException.class)
                .hasMessage("Email fiók kezelés csak CHIEF_VAULT, REGIONAL_MGR vagy DIRECTOR jogosultsággal lehetséges!");
        ResponseEntity<ErrorResponse> response = new GlobalExceptionHandler().handleValidation((ValidationException) thrown);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(emailAccountService);
    }

    private static Authentication authenticationWithBackwardCompatibleDetails() {
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken("W001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(1L, UUID.randomUUID(), UUID.randomUUID(), "WORKER"));
        return auth;
    }
}
