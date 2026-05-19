package hu.puzzleir.valuta.dto.voice;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * EBC Hangsegéd VoiceAssistantMode enum direkt-assertion tesztek.
 *
 * <p>Copilot PR #691 P2 finding: a service-szintű tesztek a `BusinessException`
 * burok mögött nem tesztelték a reasoning-effort kontraktust. Ez a teszt
 * DIRECT a enum kontraktot ellenőrzi: a usesMediumReasoning() helyes-e
 * mind a 4 mode-ra, és a Jackson @JsonValue + @JsonCreator round-trip is.
 */
class VoiceAssistantModeTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Test
    void usesMediumReasoning_TEST_es_UNIFIED_eseten_true_egyebkent_false() {
        // Kosa Zoltan 2026-05-18 directive: az UNIFIED mode medium reasoning-gel fut.
        assertThat(VoiceAssistantMode.INSTALL.usesMediumReasoning()).isFalse();
        assertThat(VoiceAssistantMode.TEST.usesMediumReasoning()).isTrue();
        assertThat(VoiceAssistantMode.SUPPORT.usesMediumReasoning()).isFalse();
        assertThat(VoiceAssistantMode.UNIFIED.usesMediumReasoning()).isTrue();
    }

    @Test
    void getWireName_lowercase_a_konstans_nevvel_egyezo() {
        // A wire-name a JSON-on at megjeleno format - lowercase
        assertThat(VoiceAssistantMode.INSTALL.getWireName()).isEqualTo("install");
        assertThat(VoiceAssistantMode.TEST.getWireName()).isEqualTo("test");
        assertThat(VoiceAssistantMode.SUPPORT.getWireName()).isEqualTo("support");
        assertThat(VoiceAssistantMode.UNIFIED.getWireName()).isEqualTo("unified");
    }

    @Test
    void tryParse_a_4_wire_name_eseten_visszaad_megfelelo_enumot() {
        assertThat(VoiceAssistantMode.tryParse("install")).contains(VoiceAssistantMode.INSTALL);
        assertThat(VoiceAssistantMode.tryParse("test")).contains(VoiceAssistantMode.TEST);
        assertThat(VoiceAssistantMode.tryParse("support")).contains(VoiceAssistantMode.SUPPORT);
        assertThat(VoiceAssistantMode.tryParse("unified")).contains(VoiceAssistantMode.UNIFIED);
    }

    @Test
    void tryParse_ervenytelen_eseten_empty() {
        assertThat(VoiceAssistantMode.tryParse("invalid")).isEmpty();
        assertThat(VoiceAssistantMode.tryParse("INSTALL")).isEmpty();  // case-sensitive
        assertThat(VoiceAssistantMode.tryParse(null)).isEmpty();
        assertThat(VoiceAssistantMode.tryParse("")).isEmpty();
    }

    @Test
    void jackson_serialization_a_wire_name_et_irja() throws Exception {
        String json = MAPPER.writeValueAsString(VoiceAssistantMode.UNIFIED);
        assertThat(json).isEqualTo("\"unified\"");
    }

    @Test
    void jackson_deserialization_a_wire_name_bol_enum_ot_ad() throws Exception {
        VoiceAssistantMode parsed = MAPPER.readValue("\"unified\"", VoiceAssistantMode.class);
        assertThat(parsed).isEqualTo(VoiceAssistantMode.UNIFIED);
    }

    @Test
    void jackson_deserialization_ismeretlen_wire_name_dob_konkret_jackson_exceptiont() {
        // Copilot PR #692 P2: a korabbi `isInstanceOf(Exception.class)` mindig
        // igaz volt - tul gyenge. Konkret Jackson tipust + root-cause-t asserteljuk:
        //  - tipus: ValueInstantiationException (a @JsonCreator factory IAE-jet ebbe csomagolja Jackson)
        //  - root cause: IllegalArgumentException + uzenet tartalmazza a wire-name-et
        // Ezt a GlobalExceptionHandler@HttpMessageNotReadableException kapja el es
        // alakit a felhasznalo-barat "INVALID_ENUM_VALUE" 400 valassza.
        assertThatThrownBy(() -> MAPPER.readValue("\"unknown\"", VoiceAssistantMode.class))
                .isInstanceOf(com.fasterxml.jackson.databind.exc.ValueInstantiationException.class)
                .hasMessageContaining("VoiceAssistantMode")
                .satisfies(ex -> {
                    Throwable root = ex;
                    while (root.getCause() != null) root = root.getCause();
                    assertThat(root)
                            .as("root cause = a @JsonCreator factory altal dobott IllegalArgumentException")
                            .isInstanceOf(IllegalArgumentException.class);
                    assertThat(root.getMessage())
                            .as("root cause uzenete tartalmazza a beadott wire-name-et")
                            .contains("unknown");
                });
    }
}
