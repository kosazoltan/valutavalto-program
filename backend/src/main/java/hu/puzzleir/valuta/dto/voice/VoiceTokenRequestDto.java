package hu.puzzleir.valuta.dto.voice;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * EBC Hangsegéd Voice Token kérés.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §3.4
 * <p>A frontend kéri ezt az endpointot egy ephemeral OpenAI Realtime API
 * client tokenért. A token ~1 perces életű, és csak az adott munkamenethez
 * érvényes.</p>
 *
 * <p>Copilot PR #689 P2 finding: a korábbi `String mode` + `@Pattern` regex
 * duplikálta a `VoiceAssistantMode` enum-ot. Most a Jackson `@JsonCreator`
 * (lásd {@link VoiceAssistantMode#fromWireName(String)}) végzi a validációt,
 * és érvénytelen érték esetén `HttpMessageNotReadableException` → HTTP 400.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceTokenRequestDto {

    /**
     * Asszisztens mód: install / test / support / unified.
     *
     * <p>A backend a mód alapján állítja be a reasoning effort-et:
     * - install: low (latency-kritikus, telepítés)
     * - test: medium (strukturált hibajegy)
     * - support: low (gyors válaszok)
     * - unified: medium (egyesített mód — Kósa Zoltán direktíva 2026-05-18).
     */
    @NotNull(message = "A mód kötelező.")
    @JsonProperty("mode")
    private VoiceAssistantMode mode;
}
