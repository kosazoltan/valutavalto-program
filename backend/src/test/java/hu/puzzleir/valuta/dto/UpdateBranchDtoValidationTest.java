package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-022 hotfix (FK-025 spec): az Iroda szerkesztése mentés 400-as hibájának regressziós tesztjei.
 *
 * A BranchEditPage az üres opcionális mezőket üres stringként ("") küldi
 * (BranchEditPage.tsx:102-108) — a DTO blank→null normalizálása után a Bean Validation
 * a null-t átengedi, így a mentés 200-zal megy át (FR-1..FR-4, FR-6), miközben az
 * érvénytelen ÉRTÉK továbbra is 400 (FR-5).
 *
 * A teszt a VALÓS utat járja: Jackson deszerializáció (setter-alapú) + jakarta Validator.
 */
class UpdateBranchDtoValidationTest {

    private static ObjectMapper objectMapper;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            validator = factory.getValidator();
        }
    }

    /** A BranchEditPage tényleges payload-mintája: minden opcionális mező üres string. */
    private static final String FE_EMPTY_OPTIONALS_JSON = """
            {
              "name": "BR020 Teszt Iroda",
              "address": "6722 Szeged, Teszt utca 1.",
              "shortName": "",
              "zipCode": "",
              "city": "",
              "phone": "",
              "email": "",
              "bankCode": "",
              "isVault": false,
              "isActive": true
            }
            """;

    @Test
    @DisplayName("FR-1..FR-3: üres rövid név / telefon / email (+zip/city) → 0 violation, mezők null-ra normalizálva")
    void emptyOptionalStrings_areNormalizedToNull_andValid() throws Exception {
        UpdateBranchDto dto = objectMapper.readValue(FE_EMPTY_OPTIONALS_JSON, UpdateBranchDto.class);

        assertThat(dto.getShortName()).isNull();
        assertThat(dto.getPhone()).isNull();
        assertThat(dto.getEmail()).isNull();
        assertThat(dto.getBankCode()).isNull();
        assertThat(dto.getZipCode()).isNull();
        assertThat(dto.getCity()).isNull();

        Set<ConstraintViolation<UpdateBranchDto>> violations = validator.validate(dto);
        assertThat(violations).isEmpty();
    }

    @Test
    @DisplayName("FR-5: érvénytelen telefonszám ('nem-szam-abc') továbbra is validációs hibát ad")
    void invalidPhone_stillRejected() throws Exception {
        String json = """
                { "phone": "nem-szam-abc" }
                """;
        UpdateBranchDto dto = objectMapper.readValue(json, UpdateBranchDto.class);

        Set<ConstraintViolation<UpdateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("phone"));
    }

    @Test
    @DisplayName("FR-6: bankCode='210' + többi opcionális üres → érvényes, bankCode megmarad")
    void bankCode210_withOtherOptionalsEmpty_isValid() throws Exception {
        String json = """
                { "bankCode": "210", "shortName": "", "phone": "", "email": "" }
                """;
        UpdateBranchDto dto = objectMapper.readValue(json, UpdateBranchDto.class);

        assertThat(dto.getBankCode()).isEqualTo("210");
        assertThat(dto.getShortName()).isNull();
        assertThat(validator.validate(dto)).isEmpty();
    }

    @Test
    @DisplayName("FR-4: openingDate üres string → null (nincs Jackson-hiba); érvényes dátum parse-olódik")
    void blankOpeningDate_deserializesToNull() throws Exception {
        UpdateBranchDto blank = objectMapper.readValue("{ \"openingDate\": \"\" }", UpdateBranchDto.class);
        assertThat(blank.getOpeningDate()).isNull();
        assertThat(validator.validate(blank)).isEmpty();

        UpdateBranchDto parsed = objectMapper.readValue("{ \"openingDate\": \"2020-01-15\" }", UpdateBranchDto.class);
        assertThat(parsed.getOpeningDate()).isEqualTo(LocalDate.of(2020, 1, 15));
    }

    @Test
    @DisplayName("Érvényes értékek trimmelve maradnak meg (pl. telefon szóközökkel)")
    void validValues_areTrimmedAndKept() throws Exception {
        String json = """
                { "phone": "  +36 30 123 4567  ", "email": " teszt@example.hu ", "city": " Szeged " }
                """;
        UpdateBranchDto dto = objectMapper.readValue(json, UpdateBranchDto.class);

        assertThat(dto.getPhone()).isEqualTo("+36 30 123 4567");
        assertThat(dto.getEmail()).isEqualTo("teszt@example.hu");
        assertThat(dto.getCity()).isEqualTo("Szeged");
        assertThat(validator.validate(dto)).isEmpty();
    }

    @Test
    @DisplayName("Jövőbeli openingDate továbbra is hibát ad (@PastOrPresent nem sérül)")
    void futureOpeningDate_stillRejected() throws Exception {
        String json = "{ \"openingDate\": \"" + LocalDate.now().plusDays(30) + "\" }";
        UpdateBranchDto dto = objectMapper.readValue(json, UpdateBranchDto.class);

        Set<ConstraintViolation<UpdateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("openingDate"));
    }
}
