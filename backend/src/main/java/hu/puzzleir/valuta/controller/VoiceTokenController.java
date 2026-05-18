package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.voice.VoiceTokenRequestDto;
import hu.puzzleir.valuta.dto.voice.VoiceTokenResponseDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.VoiceTokenService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * EBC Hangsegéd Voice Token REST endpoint.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §3.4
 *
 * <p>A frontend (Penztar / Kozponti / Arfolyamkeszito kliensek) hívja a
 * {@code POST /api/v1/voice/token}-t egy ephemeral OpenAI Realtime API
 * client_secret-ért. A master {@code OPENAI_API_KEY} CSAK backend-en él.
 *
 * <p>Auth: bármelyik aktív, bejelentkezett worker (JWT). A többi engedélyezési
 * logika (pl. role-szűrés a mód szerint, rate-limit) a service-szinten.
 */
@RestController
@RequestMapping("/api/v1/voice")
@RequiredArgsConstructor
@Slf4j
public class VoiceTokenController {

    private final VoiceTokenService voiceTokenService;

    /**
     * Ephemeral token kérése.
     *
     * @param request a kliens kérése — tartalmazza a módot
     * @return 200 OK + ephemeral client_secret
     */
    @PostMapping("/token")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<VoiceTokenResponseDto> requestToken(
            @Valid @RequestBody VoiceTokenRequestDto request) {

        String workerCode = SecurityUtils.getCurrentWorkerCode();
        log.info("VoiceTokenController: ephemeral token kérés, worker={}, mode={}",
                workerCode, request.getMode());

        VoiceTokenResponseDto response = voiceTokenService.requestEphemeralToken(request.getMode());

        log.info("VoiceTokenController: ephemeral token sikeresen kiadva worker={} számára", workerCode);
        return ResponseEntity.ok(response);
    }
}
