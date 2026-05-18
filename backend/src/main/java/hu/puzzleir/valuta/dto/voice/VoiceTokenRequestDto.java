package hu.puzzleir.valuta.dto.voice;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * EBC Hangsegéd Voice Token kérés.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §3.4
 * <p>A frontend kéri ezt az endpointot egy ephemeral OpenAI Realtime API
 * client tokenért. A token ~1 perces életű, és csak az adott munkamenethez
 * érvényes.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceTokenRequestDto {

    /**
     * Asszisztens mód: install / test / support.
     *
     * <p>A backend a mód alapján állítja be a reasoning effort-et:
     * - install: low (latency-kritikus, telepítés)
     * - test: medium (strukturált hibajegy)
     * - support: low (gyors válaszok)
     */
    @NotNull
    @Pattern(regexp = "^(install|test|support)$",
             message = "A mód érvényes értékei: install, test, support.")
    @JsonProperty("mode")
    private String mode;
}
