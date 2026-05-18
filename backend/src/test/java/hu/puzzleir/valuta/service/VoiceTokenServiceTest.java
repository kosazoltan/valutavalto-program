package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * EBC Hangsegéd Voice Token szolgáltatás unit tesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 2 acceptance.
 *
 * <p>Megjegyzés: a tényleges OpenAI API hívást NEM teszteljük (külső szolgáltatás).
 * Csak a service guard-jait (config-check, mode-validation) ellenőrizzük.
 */
class VoiceTokenServiceTest {

    private VoiceTokenService service;

    @BeforeEach
    void setUp() {
        service = new VoiceTokenService(new ObjectMapper());
    }

    @Test
    void requestEphemeralToken_kikapcsolt_szolgaltatas_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", false);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        assertThatThrownBy(() -> service.requestEphemeralToken("install"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("nincs engedélyezve");
    }

    @Test
    void requestEphemeralToken_hianyzo_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "");

        assertThatThrownBy(() -> service.requestEphemeralToken("install"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_null_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", null);

        assertThatThrownBy(() -> service.requestEphemeralToken("install"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_ervenytelen_mod_dob_ValidationException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        assertThatThrownBy(() -> service.requestEphemeralToken("invalid-mode"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Érvénytelen mód");

        assertThatThrownBy(() -> service.requestEphemeralToken(null))
                .isInstanceOf(ValidationException.class);

        assertThatThrownBy(() -> service.requestEphemeralToken(""))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    void requestEphemeralToken_3_ervenyes_mod_atengedi_a_validaciot() {
        // A "install", "test", "support" mind érvényes — de a service utána
        // hívja az OpenAI-t, ami NEM elérhető test-environmentben.
        // Ezért csak azt teszteljük hogy a mode-validation utáni hibatípus
        // NEM ValidationException, hanem BusinessException (upstream error).
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        for (String mode : new String[]{"install", "test", "support"}) {
            assertThatThrownBy(() -> service.requestEphemeralToken(mode))
                    .isInstanceOf(BusinessException.class);  // NEM ValidationException
        }
    }
}
