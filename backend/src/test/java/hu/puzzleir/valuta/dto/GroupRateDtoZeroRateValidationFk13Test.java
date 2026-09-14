package hu.puzzleir.valuta.dto;

import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK13 (FR-6) — {@link GroupRateDTO.RateEntry} Bean Validation szerződés (RED, 2026-09-14).
 *
 * <p>Eldöntött irány: a DTO-szint a 0-t ELFOGADJA ({@code @Positive} → {@code @PositiveOrZero}), és a
 * "0 engedélyezett-e ezen a valután, ebben az irányban" döntés a service-rétegben, a currency-flag
 * alapján történik (RateCreationServiceTest FK13 esetei). A negatív érték és a hiányzó érték
 * elutasítása változatlanul DTO-szintű marad (FR-12 guard).</p>
 */
class GroupRateDtoZeroRateValidationFk13Test {

    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        validatorFactory.close();
    }

    private static GroupRateDTO.RateEntry entry(String buy, String sell) {
        return GroupRateDTO.RateEntry.builder()
                .currencyId(21L)
                .buyRate(buy == null ? null : new BigDecimal(buy))
                .sellRate(sell == null ? null : new BigDecimal(sell))
                .officialRate(new BigDecimal("7.50"))
                .build();
    }

    private static Set<String> violatedPaths(GroupRateDTO.RateEntry e) {
        Set<ConstraintViolation<GroupRateDTO.RateEntry>> violations = validator.validate(e);
        return violations.stream().map(v -> v.getPropertyPath().toString()).collect(java.util.stream.Collectors.toSet());
    }

    @Test
    @DisplayName("FK13 FR-6: buyRate = 0 DTO-szinten elfogadott (a policy-döntés a service dolga)")
    void zeroBuyRate_passesDtoValidation() {
        assertThat(violatedPaths(entry("0", "7.87")))
                .as("a 0 vételt a DTO nem utasíthatja el — különben a currency-flag soha nem érvényesülhet")
                .doesNotContain("buyRate");
    }

    @Test
    @DisplayName("FK13 FR-6: sellRate = 0 DTO-szinten elfogadott")
    void zeroSellRate_passesDtoValidation() {
        assertThat(violatedPaths(entry("7.20", "0"))).doesNotContain("sellRate");
    }

    @Test
    @DisplayName("FK13 FR-12 guard: negatív vétel/eladás továbbra is DTO-szintű hiba")
    void negativeRates_stillRejected() {
        assertThat(violatedPaths(entry("-0.01", "7.87"))).contains("buyRate");
        assertThat(violatedPaths(entry("7.20", "-1"))).contains("sellRate");
    }

    @Test
    @DisplayName("FK13 FR-12 guard: hiányzó (null) vétel/eladás továbbra is @NotNull hiba")
    void nullRates_stillRejected() {
        assertThat(violatedPaths(entry(null, "7.87"))).contains("buyRate");
        assertThat(violatedPaths(entry("7.20", null))).contains("sellRate");
    }

    @Test
    @DisplayName("FK13 FR-12 guard: pozitív pár változatlanul hibamentes")
    void positiveRates_valid() {
        assertThat(violatedPaths(entry("7.40", "7.60"))).isEmpty();
    }
}
