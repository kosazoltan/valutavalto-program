package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * EBC Hangsegéd Voice Token szolgáltatás unit tesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 2 acceptance.
 *
 * <p>Megjegyzés: a tényleges OpenAI API hívást NEM teszteljük (külső szolgáltatás).
 * Csak a service guard-jait (config-check, mode-validation, rate-limit) ellenőrizzük.
 */
class VoiceTokenServiceTest {

    private static final String TEST_WORKER = "W-S011";

    private VoiceTokenService service;

    @BeforeEach
    void setUp() {
        service = new VoiceTokenService(new ObjectMapper());
        ReflectionTestUtils.setField(service, "rateLimitMaxPerHour", 10);
        ReflectionTestUtils.setField(service, "rateLimitWindowSeconds", 3600L);
    }

    @Test
    void requestEphemeralToken_kikapcsolt_szolgaltatas_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", false);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        assertThatThrownBy(() -> service.requestEphemeralToken("install", TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("nincs engedélyezve");
    }

    @Test
    void requestEphemeralToken_hianyzo_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "");

        assertThatThrownBy(() -> service.requestEphemeralToken("install", TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_null_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", null);

        assertThatThrownBy(() -> service.requestEphemeralToken("install", TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_ervenytelen_mod_dob_ValidationException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        assertThatThrownBy(() -> service.requestEphemeralToken("invalid-mode", TEST_WORKER))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Érvénytelen mód");

        assertThatThrownBy(() -> service.requestEphemeralToken(null, TEST_WORKER))
                .isInstanceOf(ValidationException.class);

        assertThatThrownBy(() -> service.requestEphemeralToken("", TEST_WORKER))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    void requestEphemeralToken_3_ervenyes_mod_atengedi_a_validaciot() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        for (String mode : new String[]{"install", "test", "support"}) {
            // Külön worker-kód, hogy a rate-limit ne lépjen be a 3 hívás között
            String worker = "W-" + mode;
            assertThatThrownBy(() -> service.requestEphemeralToken(mode, worker))
                    .isInstanceOf(BusinessException.class);  // NEM ValidationException
        }
    }

    @Test
    void requestEphemeralToken_rate_limit_lepes_eseten_BusinessException() {
        // Copilot PR #659: per-worker rate-limit védi a master OPENAI_API_KEY-t
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");
        ReflectionTestUtils.setField(service, "rateLimitMaxPerHour", 3);

        // 3 sikertelen kérés (OpenAI auth-error) — de a rate-limit bucket számolódik
        for (int i = 0; i < 3; i++) {
            assertThatThrownBy(() -> service.requestEphemeralToken("install", "limited-worker"))
                    .isInstanceOf(BusinessException.class);
        }

        // 4. hívás → rate-limit error, NEM upstream error
        assertThatThrownBy(() -> service.requestEphemeralToken("install", "limited-worker"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Túl sok hangsegéd-token kérés");
    }

    @Test
    void requestEphemeralToken_kulonbozo_worker_kodok_kulon_buckettel() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");
        ReflectionTestUtils.setField(service, "rateLimitMaxPerHour", 2);

        // Worker A: 2 kérés (limit határa)
        for (int i = 0; i < 2; i++) {
            assertThatThrownBy(() -> service.requestEphemeralToken("install", "worker-A"))
                    .isInstanceOf(BusinessException.class);
        }
        // Worker A 3. → rate-limit
        assertThatThrownBy(() -> service.requestEphemeralToken("install", "worker-A"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Túl sok");

        // Worker B külön bucket — még enged
        assertThatThrownBy(() -> service.requestEphemeralToken("install", "worker-B"))
                .isInstanceOf(BusinessException.class)
                // NEM "Túl sok", hanem upstream / unauthorized error
                .satisfies(e -> {
                    String msg = e.getMessage();
                    org.assertj.core.api.Assertions.assertThat(msg)
                            .doesNotContain("Túl sok");
                });
    }
}
