package hu.puzzleir.valuta.dto;

import hu.puzzleir.valuta.dto.user.ChangePasswordRequest;
import hu.puzzleir.valuta.dto.user.CreateUserRequest;
import hu.puzzleir.valuta.dto.user.UpdateMyPasswordRequest;
import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PasswordPolicyDtoValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void userCreationRequiresAtLeastEightCharacterPassword() {
        CreateUserRequest request = new CreateUserRequest(
                "P001", "Teszt Elek", "teszt@example.com", "1234567", "CASHIER", null);

        assertThat(validator.validate(request)).anyMatch(v -> "password".equals(v.getPropertyPath().toString()));
    }

    @Test
    void adminPasswordChangeRequiresAtLeastEightCharacters() {
        ChangePasswordRequest request = new ChangePasswordRequest("1234567");

        assertThat(validator.validate(request)).anyMatch(v -> "newPassword".equals(v.getPropertyPath().toString()));
    }

    @Test
    void ownPasswordChangeRequiresAtLeastEightCharacters() {
        UpdateMyPasswordRequest request = new UpdateMyPasswordRequest("old-password", "1234567");

        assertThat(validator.validate(request)).anyMatch(v -> "newPassword".equals(v.getPropertyPath().toString()));
    }

    @Test
    void workerPasswordChangeRequiresAtLeastEightCharacters() {
        ChangePasswordDto request = new ChangePasswordDto("old-password", "1234567");

        assertThat(validator.validate(request)).anyMatch(v -> "newPassword".equals(v.getPropertyPath().toString()));
    }
}
