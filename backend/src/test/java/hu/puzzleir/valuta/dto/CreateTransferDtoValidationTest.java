package hu.puzzleir.valuta.dto;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FR-1..3 / NFR-1,2 (átadás-átvétel szállító + plombaszám): a CreateTransferDto Bean Validation
 * szerződése — szállító/plomba kötelező, 128/64 hossz, plomba csak [A-Za-z0-9-/].
 */
class CreateTransferDtoValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    private CreateTransferDto.CreateTransferDtoBuilder valid() {
        return CreateTransferDto.builder()
                .toBranchId("11111111-1111-1111-1111-111111111111")
                .currencyId(1L)
                .amount(new BigDecimal("1000"))
                .transferType("CURRENCY")
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("ABC/12-3");
    }

    private boolean hasViolation(CreateTransferDto dto, String field) {
        return validator.validate(dto).stream().anyMatch(v -> field.equals(v.getPropertyPath().toString()));
    }

    @Test
    void validCarrierAndSeal_noViolations() {
        assertThat(validator.validate(valid().build())).isEmpty();
    }

    @Test
    void missingCarrierName_violation() {
        assertThat(hasViolation(valid().carrierName(null).build(), "carrierName")).isTrue();
        assertThat(hasViolation(valid().carrierName("   ").build(), "carrierName")).isTrue();
    }

    @Test
    void missingSealNumber_violation() {
        assertThat(hasViolation(valid().sealNumber(null).build(), "sealNumber")).isTrue();
        assertThat(hasViolation(valid().sealNumber("").build(), "sealNumber")).isTrue();
    }

    @Test
    void sealNumberInvalidChars_violation() {
        assertThat(hasViolation(valid().sealNumber("ABC 12").build(), "sealNumber")).isTrue();
        assertThat(hasViolation(valid().sealNumber("ABC_12").build(), "sealNumber")).isTrue();
        assertThat(hasViolation(valid().sealNumber("ABC#12").build(), "sealNumber")).isTrue();
    }

    @Test
    void carrierNameTooLong_violation() {
        assertThat(hasViolation(valid().carrierName("X".repeat(129)).build(), "carrierName")).isTrue();
    }

    @Test
    void sealNumberTooLong_violation() {
        assertThat(hasViolation(valid().sealNumber("A".repeat(65)).build(), "sealNumber")).isTrue();
    }

    @Test
    void validSealWithDashAndSlash_ok() {
        assertThat(hasViolation(valid().sealNumber("ABC/12-3").build(), "sealNumber")).isFalse();
        assertThat(hasViolation(valid().sealNumber("SEAL00099").build(), "sealNumber")).isFalse();
    }
}
