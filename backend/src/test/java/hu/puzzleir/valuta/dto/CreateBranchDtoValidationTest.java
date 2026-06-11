package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-025 TBD#1: a spec "BranchCreateRequest.java"-ja ebben a repóban a CreateBranchDto
 * (POST /api/v1/branches). Az opcionális mezők (shortName, phone, email) üres stringként
 * ("") érkezve nem okozhatnak 400-at (blank → null normalizálás, az UpdateBranchDto
 * mintája — commit 4cf0ebc6f); az üres openingDate Jackson-hiba helyett tiszta Bean
 * Validation hibaüzenetet adjon (@NotNull). A kötelező @NotBlank mezők ""-elutasítása
 * változatlan marad.
 *
 * A teszt a VALÓS utat járja: Jackson deszerializáció (setter-alapú) + jakarta Validator.
 */
class CreateBranchDtoValidationTest {

    private static ObjectMapper objectMapper;
    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        // Codex P1 (#1093) minta: a factory a tesztek alatt nyitva marad, @AfterAll zárja.
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        validatorFactory.close();
    }

    /** Minden kötelező mező kitöltve, az opcionálisak üres stringként (programmatic kliens mintája). */
    private static final String EMPTY_OPTIONALS_JSON = """
            {
              "code": "BR099",
              "companyId": "00000000-0000-0000-0000-000000000010",
              "bankCode": "210",
              "branchTypeId": "00000000-0000-0000-0000-000000000001",
              "name": "BR099 Teszt Iroda",
              "address": "6722 Szeged, Teszt utca 1.",
              "city": "Szeged",
              "zipCode": "6722",
              "countryId": "00000000-0000-0000-0000-000000000002",
              "branchStatusId": "00000000-0000-0000-0000-000000000003",
              "openingDate": "2020-01-15",
              "shortName": "",
              "phone": "",
              "email": ""
            }
            """;

    @Test
    @DisplayName("TBD#1: üres opcionális mezők (shortName/phone/email) → 0 violation, null-ra normalizálva")
    void emptyOptionalStrings_areNormalizedToNull_andValid() throws Exception {
        CreateBranchDto dto = objectMapper.readValue(EMPTY_OPTIONALS_JSON, CreateBranchDto.class);

        assertThat(dto.getShortName()).isNull();
        assertThat(dto.getPhone()).isNull();
        assertThat(dto.getEmail()).isNull();

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations).isEmpty();
    }

    @Test
    @DisplayName("FR-5 analóg: érvénytelen telefonszám ('nem-szam-abc') továbbra is hibát ad")
    void invalidPhone_stillRejected() throws Exception {
        String json = EMPTY_OPTIONALS_JSON.replace("\"phone\": \"\"", "\"phone\": \"nem-szam-abc\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("phone"));
    }

    @Test
    @DisplayName("FR-4 analóg: openingDate üres string → nincs Jackson-hiba, @NotNull ad tiszta hibaüzenetet")
    void blankOpeningDate_givesCleanNotNullViolation() throws Exception {
        String json = EMPTY_OPTIONALS_JSON.replace("\"openingDate\": \"2020-01-15\"", "\"openingDate\": \"\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        assertThat(dto.getOpeningDate()).isNull();
        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> {
                    assertThat(v.getPropertyPath().toString()).isEqualTo("openingDate");
                    assertThat(v.getMessage()).isEqualTo("A nyitás dátuma kötelező");
                });
    }

    @Test
    @DisplayName("Érvényes openingDate parse-olódik; jövőbeli dátum továbbra is hibát ad (@PastOrPresent)")
    void openingDate_parsedAndFutureStillRejected() throws Exception {
        CreateBranchDto parsed = objectMapper.readValue(EMPTY_OPTIONALS_JSON, CreateBranchDto.class);
        assertThat(parsed.getOpeningDate()).isEqualTo(LocalDate.of(2020, 1, 15));

        String futureJson = EMPTY_OPTIONALS_JSON.replace("2020-01-15", LocalDate.now().plusDays(30).toString());
        CreateBranchDto future = objectMapper.readValue(futureJson, CreateBranchDto.class);
        assertThat(validator.validate(future))
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("openingDate"));
    }

    @Test
    @DisplayName("Érvényes opcionális értékek trimmelve maradnak meg")
    void validValues_areTrimmedAndKept() throws Exception {
        String json = EMPTY_OPTIONALS_JSON
                .replace("\"shortName\": \"\"", "\"shortName\": \" BR099 \"")
                .replace("\"phone\": \"\"", "\"phone\": \"  +36 30 123 4567  \"")
                .replace("\"email\": \"\"", "\"email\": \" teszt@example.hu \"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        assertThat(dto.getShortName()).isEqualTo("BR099");
        assertThat(dto.getPhone()).isEqualTo("+36 30 123 4567");
        assertThat(dto.getEmail()).isEqualTo("teszt@example.hu");
        assertThat(validator.validate(dto)).isEmpty();
    }

    @Test
    @DisplayName("Kötelező mezők üres stringgel továbbra is hibát adnak (@NotBlank nem lazult)")
    void mandatoryBlankFields_stillRejected() throws Exception {
        String json = EMPTY_OPTIONALS_JSON
                .replace("\"code\": \"BR099\"", "\"code\": \"\"")
                .replace("\"bankCode\": \"210\"", "\"bankCode\": \"\"")
                .replace("\"name\": \"BR099 Teszt Iroda\"", "\"name\": \"\"")
                .replace("\"address\": \"6722 Szeged, Teszt utca 1.\"", "\"address\": \"\"")
                .replace("\"city\": \"Szeged\"", "\"city\": \"\"")
                .replace("\"zipCode\": \"6722\"", "\"zipCode\": \"\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations.stream().map(v -> v.getPropertyPath().toString()))
                .contains("code", "bankCode", "name", "address", "city", "zipCode");
    }
}
