package hu.puzzleir.valuta.dto.voice;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * EBC Hangsegéd Voice Token válasz.
 *
 * <p>Az OpenAI Realtime API ephemeral client_secret tartalmazza:
 * <ul>
 *   <li>value: az ephemeral token (~1 perc életű)</li>
 *   <li>expires_at: Unix epoch másodperc (mikor jár le)</li>
 * </ul>
 * <p>A frontend ezzel a tokennel nyitja meg a WebRTC kapcsolatot
 * az OpenAI Realtime API-val.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VoiceTokenResponseDto {

    @JsonProperty("client_secret")
    private ClientSecret clientSecret;

    @JsonProperty("model")
    private String model;

    @JsonProperty("mode")
    private String mode;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClientSecret {
        @JsonProperty("value")
        private String value;

        @JsonProperty("expires_at")
        private Long expiresAt;
    }
}
