package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.voice.VoiceAssistantMode;
import hu.puzzleir.valuta.exception.BusinessException;
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
 *
 * <p>Copilot PR #689 P2 finding (2026-05-18): a `String mode` átírva `VoiceAssistantMode`-ra.
 * A mode-validacio mar a Jackson @JsonCreator szinten megtortenik a DTO bind-koron,
 * ezert a service-tesztben mar VoiceAssistantMode enum-ot adunk at.
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

        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("nincs engedélyezve");
    }

    @Test
    void requestEphemeralToken_hianyzo_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "");

        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_null_api_kulcs_dob_BusinessException() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", null);

        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, TEST_WORKER))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hibás konfigurációval");
    }

    @Test
    void requestEphemeralToken_4_ervenyes_mod_atengedi_a_validaciot() {
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        // A 4 ervenyes mod (install / test / support / unified) atmegy a guard-on
        // es eljut az OpenAI API hivasig — ami a fake kulcs miatt BusinessException-t dob,
        // NEM ValidationException-t. (A mod-validacio mar a DTO szinten megtortent.)
        for (VoiceAssistantMode mode : VoiceAssistantMode.values()) {
            String worker = "W-" + mode.getWireName();
            assertThatThrownBy(() -> service.requestEphemeralToken(mode, worker))
                    .isInstanceOf(BusinessException.class);
        }
    }

    @Test
    void requestEphemeralToken_unified_mode_medium_reasoning_atengedi_a_validaciot() {
        // Copilot PR #689 P2 finding: unified mode (Kosa Zoltan 2026-05-18 directive)
        // medium reasoning-gel fut, ami a TEST mode-dal egyezo viselkedes.
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");

        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.UNIFIED, "unified-worker"))
                .isInstanceOf(BusinessException.class);  // NEM ValidationException — atjut a guard-on
    }

    @Test
    void requestEphemeralToken_rate_limit_lepes_eseten_BusinessException() {
        // Copilot PR #659: per-worker rate-limit védi a master OPENAI_API_KEY-t
        ReflectionTestUtils.setField(service, "voiceEnabled", true);
        ReflectionTestUtils.setField(service, "openAiApiKey", "sk-test-dummy");
        ReflectionTestUtils.setField(service, "rateLimitMaxPerHour", 3);

        // 3 sikertelen kérés (OpenAI auth-error) — de a rate-limit bucket számolódik
        for (int i = 0; i < 3; i++) {
            assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, "limited-worker"))
                    .isInstanceOf(BusinessException.class);
        }

        // 4. hívás → rate-limit error, NEM upstream error
        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, "limited-worker"))
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
            assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, "worker-A"))
                    .isInstanceOf(BusinessException.class);
        }
        // Worker A 3. → rate-limit
        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, "worker-A"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Túl sok");

        // Worker B külön bucket — még enged
        assertThatThrownBy(() -> service.requestEphemeralToken(VoiceAssistantMode.INSTALL, "worker-B"))
                .isInstanceOf(BusinessException.class)
                // NEM "Túl sok", hanem upstream / unauthorized error
                .satisfies(e -> {
                    String msg = e.getMessage();
                    org.assertj.core.api.Assertions.assertThat(msg)
                            .doesNotContain("Túl sok");
                });
    }
}
