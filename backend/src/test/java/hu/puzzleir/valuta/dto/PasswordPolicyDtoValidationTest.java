package hu.puzzleir.valuta.dto;

import hu.puzzleir.valuta.dto.auth.BootstrapAdminRequestDto;
import hu.puzzleir.valuta.dto.auth.ResetPasswordRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.user.ChangePasswordRequest;
import hu.puzzleir.valuta.dto.user.CreateUserRequest;
import hu.puzzleir.valuta.dto.user.UpdateMyPasswordRequest;
import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import hu.puzzleir.valuta.dto.worker.CreateWorkerDto;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.validation.PasswordPolicy;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PasswordPolicyDtoValidationTest {

    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void createValidator() {
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void closeValidator() {
        validatorFactory.close();
    }

    @Test
    void userCreationRequiresAtLeastEightCharacters() {
        CreateUserRequest request = new CreateUserRequest(
                "P001", "Teszt Elek", "teszt@example.com", passwordOfLength(PasswordPolicy.MIN_LENGTH - 1),
                "CASHIER", null);

        assertPasswordViolation(request, "password");
    }

    @Test
    void adminPasswordChangeRequiresAtLeastEightCharacters() {
        ChangePasswordRequest request = new ChangePasswordRequest(passwordOfLength(PasswordPolicy.MIN_LENGTH - 1));

        assertPasswordViolation(request, "newPassword");
    }

    @Test
    void ownPasswordChangeRequiresAtLeastEightCharacters() {
        UpdateMyPasswordRequest request = new UpdateMyPasswordRequest(
                "old-password", passwordOfLength(PasswordPolicy.MIN_LENGTH - 1));

        assertPasswordViolation(request, "newPassword");
    }

    @Test
    void workerPasswordChangeRequiresAtLeastEightCharacters() {
        ChangePasswordDto request = new ChangePasswordDto(
                "old-password", passwordOfLength(PasswordPolicy.MIN_LENGTH - 1));

        assertPasswordViolation(request, "newPassword");
    }

    @Test
    void passwordDtosAcceptMinimumLengthPasswords() {
        assertPasswordDtosAccept(passwordOfLength(PasswordPolicy.MIN_LENGTH));
    }

    @Test
    void passwordDtosAcceptMaximumLengthPasswords() {
        assertPasswordDtosAccept(passwordOfLength(PasswordPolicy.MAX_LENGTH));
    }

    private void assertPasswordDtosAccept(String password) {
        assertValid(new CreateUserRequest("P001", "Teszt Elek", "teszt@example.com", password, "CASHIER", null));
        assertValid(new ChangePasswordRequest(password));
        assertValid(new UpdateMyPasswordRequest("old-password", password));
        assertValid(new ChangePasswordDto("old-password", password));
        assertValid(new CreateWorkerDto(
                UUID.randomUUID(), "P001", "Teszt Elek", password, WorkerRole.CASHIER, UUID.randomUUID(),
                null, null, null, null));
        assertValid(new BootstrapAdminRequestDto("COMPANY", "P001", "Teszt Elek", "teszt@example.com", password));
        assertValid(new WorkerFirstTimeSetupRequestDto("COMPANY", "P001", password, "current-password"));
        assertValid(new ResetPasswordRequestDto("reset-token", password));
    }

    private <T> void assertPasswordViolation(T request, String property) {
        assertThat(validator.validate(request)).anyMatch(v -> property.equals(v.getPropertyPath().toString()));
    }

    private <T> void assertValid(T request) {
        assertThat(validator.validate(request)).isEmpty();
    }

    private String passwordOfLength(int length) {
        return "A1" + "a".repeat(length - 2);
    }
}
