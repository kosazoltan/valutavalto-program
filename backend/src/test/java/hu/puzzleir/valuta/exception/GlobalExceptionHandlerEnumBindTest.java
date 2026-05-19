package hu.puzzleir.valuta.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.exc.MismatchedInputException;
import hu.puzzleir.valuta.dto.voice.VoiceAssistantMode;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * GlobalExceptionHandler enum bind-failure handler unit teszt.
 *
 * <p>Codex PR #692 P1 + Copilot PR #692 P1 finding:
 * A VoiceAssistantMode {@code @JsonCreator} factory metodus {@code IllegalArgumentException}-t
 * dob, amit Jackson {@link MismatchedInputException}-be csomagol — NEM
 * {@link com.fasterxml.jackson.databind.exc.InvalidFormatException}-be.
 *
 * <p>Ezert a handler-nek mind a ket exception tipust el kell kapnia, hogy a
 * felhasznalo actionable hibauzenetet kapjon
 * ("Megengedett értékek: install, test, support, unified.")
 * az "Hiányzó vagy érvénytelen request body" generikus szoveg helyett.
 *
 * <p>Ez a teszt UNIT-szinten ellenorzi a handler logikat:
 *  1. Letrehoz egy valos Jackson exception-t a VoiceAssistantMode deserializaciojanak failel-eszelevel
 *  2. Becsomagolja HttpMessageNotReadableException-be (ahogy Spring tenne)
 *  3. Direkt meghivja a handler-t es asserteli a vegeredmenyt
 */
class GlobalExceptionHandlerEnumBindTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void voiceAssistantMode_ervenytelen_wire_name_eseten_actionable_INVALID_ENUM_VALUE_uzenet() throws Exception {
        HttpMessageNotReadableException wrapped = simulateJacksonBindFailure("{\"mode\":\"foobar\"}");

        ResponseEntity<ErrorResponse> resp = handler.handleHttpMessageNotReadable(wrapped);

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        ErrorResponse body = resp.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getError()).isEqualTo("INVALID_ENUM_VALUE");
        // A felhasznalo lasson mind a 4 megengedett wire-name-et + a beadott rossz erteket
        assertThat(body.getMessage())
                .contains("foobar")
                .contains("install")
                .contains("test")
                .contains("support")
                .contains("unified");
    }

    @Test
    void enum_field_neve_szerepel_az_uzenetben_a_path_bol() throws Exception {
        HttpMessageNotReadableException wrapped = simulateJacksonBindFailure("{\"mode\":\"barbaz\"}");

        ResponseEntity<ErrorResponse> resp = handler.handleHttpMessageNotReadable(wrapped);

        assertThat(resp.getBody()).isNotNull();
        assertThat(resp.getBody().getMessage()).contains("'mode'");
    }

    @Test
    void nem_enum_hiba_eseten_a_generic_BAD_REQUEST_marad() {
        // A cause-lanc nem tartalmaz enum InvalidFormatException-t / MismatchedInputException-t
        HttpMessageNotReadableException ex = new HttpMessageNotReadableException(
                "Required request body is missing", new MockHttpInputMessage(new byte[0]));

        ResponseEntity<ErrorResponse> resp = handler.handleHttpMessageNotReadable(ex);

        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(resp.getBody()).isNotNull();
        assertThat(resp.getBody().getError()).isEqualTo("BAD_REQUEST");
        assertThat(resp.getBody().getMessage()).contains("érvénytelen request body");
    }

    /**
     * Letrehoz egy valos Jackson MismatchedInputException-t a VoiceAssistantMode
     * deserializacio failel-eszelesevel, es Spring HttpMessageNotReadableException-be
     * csomagolja (ahogy a Spring MVC tenne JSON request body-bol).
     */
    private HttpMessageNotReadableException simulateJacksonBindFailure(String invalidJson) {
        try {
            mapper.readValue(invalidJson, hu.puzzleir.valuta.dto.voice.VoiceTokenRequestDto.class);
            throw new IllegalStateException("Nem dobott exception-t — a teszt feltetel hibas");
        } catch (com.fasterxml.jackson.core.JsonProcessingException jackson) {
            HttpInputMessage stubMsg = new MockHttpInputMessage(invalidJson.getBytes());
            return new HttpMessageNotReadableException(jackson.getMessage(), jackson, stubMsg);
        } catch (java.io.IOException io) {
            throw new IllegalStateException("Unexpected IO error", io);
        }
    }
}
