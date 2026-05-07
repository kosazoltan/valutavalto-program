package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SelectRoleRequestDtoValidationTest {

    private static final ValidatorFactory VALIDATOR_FACTORY = Validation.buildDefaultValidatorFactory();
    private static final Validator VALIDATOR = VALIDATOR_FACTORY.getValidator();

    @AfterAll
    static void closeValidatorFactory() {
        VALIDATOR_FACTORY.close();
    }

    @Test
    void appModeRejectsValuesLongerThanThirtyTwoCharacters() {
        SelectRoleRequestDto request = new SelectRoleRequestDto(
                "token",
                "penztar",
                "x".repeat(33));

        assertThat(VALIDATOR.validate(request))
                .anyMatch(v -> "appMode".equals(v.getPropertyPath().toString()));
    }
}
