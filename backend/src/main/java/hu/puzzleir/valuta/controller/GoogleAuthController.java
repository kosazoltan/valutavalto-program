package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.GoogleLoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.GoogleLoginService;
import hu.puzzleir.valuta.service.RefreshTokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

/**
 * Google OAuth dolgozoi belepes controller (refaktor V178/V179, 2026-05-03).
 *
 * <p>Vekony controller — a teljes login flow {@link GoogleLoginService}-ben van. A controller
 * felelossege csak az HTTP kontrakt:
 * <ul>
 *   <li>Endpoint kithelyezes</li>
 *   <li>Request DTO validation</li>
 *   <li>HttpOnly refresh cookie kibocsatasa (ugyanaz a minta mint AuthController.login)</li>
 *   <li>LoginResponseDto kimenet</li>
 * </ul>
 *
 * <p>Audit changes:
 * <ul>
 *   <li>Korabbi `fetchTokenInfo` (https://oauth2.googleapis.com/tokeninfo) HTTP hivas
 *       eltavolitva — most {@link com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier}
 *       vegezi a signature/audience/issuer/expiry validaciot lokalisan, JWK-cache-elt modon.</li>
 *   <li>HttpOnly refresh cookie kibocsatas a sikeres login utan — ugyanaz a 7-napos
 *       `refreshToken` cookie, mint a jelszavas login. Igy a frontend silent refresh ugyanugy
 *       mukodik mindket login flow utan.</li>
 *   <li>Sub-binding kezelve a {@link GoogleLoginService}-ben (whitelist-only, NEM auto-create).</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@PreAuthorize("permitAll()")
@Slf4j
public class GoogleAuthController {

    private final GoogleLoginService googleLoginService;
    private final RefreshTokenService refreshTokenService;
    private final WorkerRepository workerRepository;

    @PostMapping("/google-login")
    public ResponseEntity<LoginResponseDto> googleLogin(
            @Valid @RequestBody GoogleLoginRequestDto requestDto,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        // 1. Login flow — a service dob AuthenticationException-t / ConflictException-t,
        //    a GlobalExceptionHandler 401/409-re mappolja.
        LoginResponseDto response = googleLoginService.loginWithGoogle(requestDto.getIdToken(), httpRequest);

        // 2. HttpOnly refresh cookie — ugyanaz a 7-napos `refreshToken` mint AuthController.login.
        //    Audit P0.2 kovetelmeny: production-ben `Secure` flag aktiv (a `forward-headers-strategy=framework`
        //    miatt a `request.isSecure()` HTTPS proxy mogul jovo kerelemre true-t ad vissza).
        // Sourcery PR #361 follow-up #3: NEM nyelhetjuk el az AuthenticationException-t a workerRepository
        // hibaja eseten — ez data integrity problema, NEM cookie-issue problema. A worker not-found
        // konkretat propagaljuk, a tobbi (RefreshTokenService failure) marad warn+continue.
        Worker worker = workerRepository.findById(response.getWorker().getId())
                .orElseThrow(() -> new AuthenticationException("Worker nem talalhato login utan."));
        try {
            RefreshTokenService.IssuedToken issued = refreshTokenService.issue(worker, httpRequest);
            ResponseCookie cookie = ResponseCookie.from("refreshToken", issued.rawUuid())
                    .httpOnly(true)
                    .secure(httpRequest.isSecure())
                    .sameSite("Strict")
                    .path("/api/v1/auth")
                    .maxAge(Duration.ofDays(7))
                    .build();
            httpResponse.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        } catch (Exception ex) {
            // A login mar sikeres — a refresh cookie hibaja NE buktassa el a teljes loginot.
            // A user JWT access tokent kap, a silent refresh majd 401-en logout-ol.
            log.warn("HttpOnly refresh cookie kiadas Google login utan bukott: {}", ex.getMessage());
        }

        return ResponseEntity.ok(response);
    }
}
