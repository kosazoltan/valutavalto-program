package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.voice.VoiceAssistantMode;
import hu.puzzleir.valuta.dto.voice.VoiceTokenResponseDto;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * EBC Hangsegéd Voice Token szolgáltatás.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §3.4
 *
 * <p>Az OpenAI Realtime API ephemeral session token-eket állít elő. A master
 * {@code OPENAI_API_KEY} CSAK ezen a backend-szolgáltatáson keresztül használható
 * — frontendre sosem kerül ki. A frontend egy 1-perces életű client_secret-et
 * kap vissza, amivel WebRTC-vel csatlakozik a Realtime API-hoz.
 *
 * <p>OpenAI endpoint: {@code POST https://api.openai.com/v1/realtime/sessions}
 *
 * <p>Model: {@code gpt-realtime-2} (2026-05-07 GA, GPT-5 class reasoning)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VoiceTokenService {

    private static final String OPENAI_SESSIONS_URL = "https://api.openai.com/v1/realtime/sessions";
    private static final String MODEL = "gpt-realtime-2";
    private static final String VOICE = "shimmer";
    private static final String TRANSCRIPTION_MODEL = "gpt-realtime-whisper";

    private final ObjectMapper objectMapper;

    @Value("${voice.openai.api-key:}")
    private String openAiApiKey;

    @Value("${voice.openai.enabled:false}")
    private boolean voiceEnabled;

    /**
     * Per-worker rate-limit: max token-kéres / ablak.
     * <p>Copilot PR #659: az `isAuthenticated()` egyedüli gate-en egyetlen
     * worker (vagy compromised JWT) korlátlan ephemeral tokent mintezhetne,
     * és minden hivás OpenAI Realtime session-koltseggel jar a master kulcson.
     */
    @Value("${voice.openai.rate-limit.max-per-hour:10}")
    private int rateLimitMaxPerHour;

    @Value("${voice.openai.rate-limit.window-seconds:3600}")
    private long rateLimitWindowSeconds;

    /**
     * Per-worker sliding window timestamp deque.
     * Thread-safe ConcurrentHashMap; a Deque-t a hivasi pontban synchronize-aljuk.
     */
    private final Map<String, Deque<Instant>> rateLimitBuckets = new ConcurrentHashMap<>();

    /**
     * Thread-safe, egyetlen példányban tartott RestClient — connection-pool
     * újrahasználás miatt {@link PostConstruct}-ben építjük fel.
     */
    private RestClient restClient;

    @PostConstruct
    void initRestClient() {
        if (openAiApiKey == null || openAiApiKey.isBlank()) {
            log.warn("VoiceTokenService: voice.openai.api-key üres — RestClient lazy módon épül később.");
            return;
        }
        this.restClient = RestClient.builder()
                .baseUrl(OPENAI_SESSIONS_URL)
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + openAiApiKey)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    /**
     * Ephemeral token kérése az OpenAI-tól.
     *
     * @param mode 'install' | 'test' | 'support'
     * @param workerCode rate-limit kulcsa (Copilot PR #659)
     * @return ephemeral client_secret + lejárati idő
     */
    public VoiceTokenResponseDto requestEphemeralToken(String mode, String workerCode) {
        if (!voiceEnabled) {
            throw new BusinessException(
                    "A hangsegéd szolgáltatás jelenleg nincs engedélyezve.",
                    "VOICE_ASSISTANT_DISABLED"
            );
        }
        if (openAiApiKey == null || openAiApiKey.isBlank()) {
            log.error("VoiceTokenService: voice.openai.api-key nincs konfigurálva!");
            throw new BusinessException(
                    "A hangsegéd backend hibás konfigurációval rendelkezik.",
                    "VOICE_ASSISTANT_MISCONFIGURED"
            );
        }
        // Copilot PR #659: egyetlen forrás a megengedett módokra (VoiceAssistantMode enum)
        VoiceAssistantMode parsedMode = VoiceAssistantMode.tryParse(mode).orElseThrow(() ->
                new ValidationException("Érvénytelen mód: " + mode + ". Megengedett: install, test, support."));

        // Copilot PR #659: per-worker rate-limit — védi a master OPENAI_API_KEY-t
        checkRateLimit(workerCode);

        Map<String, Object> requestBody = Map.of(
                "model", MODEL,
                "voice", VOICE,
                "modalities", new String[]{"audio", "text"},
                "input_audio_transcription", Map.of("model", TRANSCRIPTION_MODEL),
                "turn_detection", Map.of("type", "server_vad", "threshold", 0.5),
                "reasoning", Map.of("effort", parsedMode.usesMediumReasoning() ? "medium" : "low")
        );

        if (restClient == null) {
            initRestClient();
        }

        try {
            String response = restClient.post()
                    .body(requestBody)
                    .retrieve()
                    .body(String.class);

            JsonNode json = objectMapper.readTree(response);
            JsonNode clientSecret = json.get("client_secret");

            if (clientSecret == null || clientSecret.get("value") == null) {
                log.error("VoiceTokenService: hibás OpenAI válasz, hiányzó client_secret: {}", response);
                throw new BusinessException(
                        "Az OpenAI nem adott vissza érvényes ephemeral token-t.",
                        "VOICE_ASSISTANT_API_ERROR"
                );
            }

            return VoiceTokenResponseDto.builder()
                    .clientSecret(VoiceTokenResponseDto.ClientSecret.builder()
                            .value(clientSecret.get("value").asText())
                            .expiresAt(clientSecret.has("expires_at")
                                    ? clientSecret.get("expires_at").asLong()
                                    : null)
                            .build())
                    .model(MODEL)
                    .mode(parsedMode.getWireName())
                    .build();
        } catch (HttpClientErrorException ex) {
            log.error("VoiceTokenService: OpenAI HTTP {} válasz: {}", ex.getStatusCode(), ex.getResponseBodyAsString());
            if (ex.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                throw new BusinessException(
                        "A hangsegéd backend API-kulcsa érvénytelen.",
                        "VOICE_ASSISTANT_UNAUTHORIZED"
                );
            }
            throw new BusinessException(
                    "Az OpenAI Realtime API kliens-hibát adott (" + ex.getStatusCode() + ").",
                    "VOICE_ASSISTANT_UPSTREAM_ERROR"
            );
        } catch (RestClientException ex) {
            log.error("VoiceTokenService: OpenAI API hiba (RestClientException)", ex);
            throw new BusinessException(
                    "Az OpenAI Realtime API jelenleg nem elérhető. Próbáld újra perceken belül.",
                    "VOICE_ASSISTANT_UPSTREAM_ERROR"
            );
        } catch (IOException ex) {
            log.error("VoiceTokenService: OpenAI válasz JSON-parser hiba", ex);
            throw new BusinessException(
                    "Az OpenAI válasza nem értelmezhető JSON.",
                    "VOICE_ASSISTANT_API_ERROR"
            );
        }
    }

    /**
     * Per-worker sliding-window rate-limit (Copilot PR #659).
     *
     * <p>Védi a master OPENAI_API_KEY-t — egyetlen compromised JWT-vel sem
     * tud egy attacker korlátlan ephemeral session-t kérni.
     *
     * @param workerCode rate-limit kulcs (`SecurityUtils.getCurrentWorkerCode()`)
     * @throws BusinessException ha a worker túllépte a limitet
     */
    private void checkRateLimit(String workerCode) {
        String key = workerCode != null && !workerCode.isBlank() ? workerCode : "anonymous";
        Instant now = Instant.now();
        Duration window = Duration.ofSeconds(rateLimitWindowSeconds);

        Deque<Instant> bucket = rateLimitBuckets.computeIfAbsent(key, k -> new ArrayDeque<>());
        synchronized (bucket) {
            // sliding window: ablakon kivuli timestampek eltavolitasa
            Instant cutoff = now.minus(window);
            while (!bucket.isEmpty() && bucket.peekFirst().isBefore(cutoff)) {
                bucket.pollFirst();
            }
            if (bucket.size() >= rateLimitMaxPerHour) {
                log.warn("VoiceTokenService: rate-limit lépve worker={} (max {}/{}s)",
                        key, rateLimitMaxPerHour, rateLimitWindowSeconds);
                throw new BusinessException(
                        "Túl sok hangsegéd-token kérés rövid idő alatt. Próbáld újra később.",
                        "VOICE_ASSISTANT_RATE_LIMIT"
                );
            }
            bucket.addLast(now);
        }
    }

    /** Test-only: bucket clear, hogy ne sertesek az egysegtesztekben. */
    void clearRateLimitForTesting() {
        rateLimitBuckets.clear();
    }
}
