package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.GoogleLoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.VaultWorkerSelectRequestDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.GoogleLoginService;
import hu.puzzleir.valuta.service.RefreshCookieService;
import hu.puzzleir.valuta.util.AppModeRoleConstants;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
public class GoogleAuthController {

    private final GoogleLoginService googleLoginService;
    private final RefreshCookieService refreshCookieService;
    private final WorkerRepository workerRepository;

    @PostMapping("/google-login")
    public ResponseEntity<LoginResponseDto> googleLogin(
            @Valid @RequestBody GoogleLoginRequestDto requestDto,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        // 1. Login flow — a service dob AuthenticationException-t / ConflictException-t,
        //    a GlobalExceptionHandler 401/409-re mappolja.
        LoginResponseDto response = googleLoginService.loginWithGoogle(
                requestDto.getIdToken(),
                httpRequest,
                requestDto.getAppMode(),
                Boolean.TRUE.equals(requestDto.getSupportsVaultWorkerSelection()));

        // FK-ÉRTÉKTÁR (V285): intézményi fiók → dolgozóválasztó. NINCS végleges session/token,
        // ezért a refresh cookie-t töröljük és NEM keresünk workert (a response.worker null).
        if (Boolean.TRUE.equals(response.getVaultWorkerSelectionRequired())) {
            refreshCookieService.clearCookie(httpRequest, httpResponse);
            return ResponseEntity.ok(response);
        }

        enforceAppModeForLoginResponse(response, requestDto.getAppMode());

        // 2. HttpOnly refresh cookie — ugyanaz a 7-napos `refreshToken` mint AuthController.login.
        //    Audit P0.2 kovetelmeny: production-ben `Secure` flag aktiv (a `forward-headers-strategy=framework`
        //    miatt a `request.isSecure()` HTTPS proxy mogul jovo kerelemre true-t ad vissza).
        // Fail-closed: ha a refresh token/cookie nem hozhato letre, a login nem stabil.
        // Ilyenkor nincs felig sikeres belepes, ami az elso silent refreshnel varatlanul kidobna a usert.
        // Multi-role Google login eseten a valasz tokenje ideiglenes; a kozos
        // /auth/login/select-role endpoint adja ki a tartos refresh cookie-t.
        if (!Boolean.TRUE.equals(response.getRoleSelectionRequired())) {
            Worker worker = workerRepository.findByIdWithCompanyAndBranch(response.getWorker().getId())
                    .orElseThrow(() -> new AuthenticationException("Worker nem talalhato login utan."));
            refreshCookieService.issueOrThrow(
                    worker,
                    httpRequest,
                    httpResponse,
                    response.getActiveRole(),
                    requestDto.getAppMode(),
                    "HttpOnly refresh cookie kiadas Google login utan bukott",
                    "Google belépés nem véglegesíthető: a biztonságos munkamenet cookie kiadása sikertelen.");
        } else {
            refreshCookieService.clearCookie(httpRequest, httpResponse);
        }

        return ResponseEntity.ok(response);
    }

    /**
     * FK-ÉRTÉKTÁR (V285): a kétlépcsős értéktári belépés 2. fázisa — a Google OAuth után kiválasztott
     * SZEMÉLYES dolgozó jelszavas hitelesítése. Siker esetén végleges JWT + HttpOnly refresh cookie,
     * a session a személyes workerhez tartozik (a naplózás/audit valós személyt mutat).
     */
    @PostMapping("/google-vault/select-worker")
    public ResponseEntity<LoginResponseDto> selectVaultWorker(
            @Valid @RequestBody VaultWorkerSelectRequestDto requestDto,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        LoginResponseDto response = googleLoginService.selectVaultWorker(
                requestDto.getIdToken(),
                requestDto.getWorkerId(),
                requestDto.getPassword(),
                httpRequest,
                requestDto.getAppMode());
        enforceAppModeForLoginResponse(response, requestDto.getAppMode());

        // HttpOnly refresh cookie — ugyanaz a minta mint a google-login non-role-selection ágán.
        if (!Boolean.TRUE.equals(response.getRoleSelectionRequired())) {
            Worker worker = workerRepository.findByIdWithCompanyAndBranch(response.getWorker().getId())
                    .orElseThrow(() -> new AuthenticationException("Worker nem talalhato login utan."));
            refreshCookieService.issueOrThrow(
                    worker,
                    httpRequest,
                    httpResponse,
                    response.getActiveRole(),
                    requestDto.getAppMode(),
                    "HttpOnly refresh cookie kiadas ertektari belepes utan bukott",
                    "Értéktári belépés nem véglegesíthető: a biztonságos munkamenet cookie kiadása sikertelen.");
        } else {
            refreshCookieService.clearCookie(httpRequest, httpResponse);
        }

        return ResponseEntity.ok(response);
    }

    private static void enforceAppModeForLoginResponse(LoginResponseDto response, String appMode) {
        String appModeValidationError = AppModeRoleConstants.validateLoginRolesForAppMode(
                response.getRoles(),
                response.getActiveRole(),
                Boolean.TRUE.equals(response.getRoleSelectionRequired()),
                appMode);
        if (appModeValidationError != null) {
            throw new ValidationException(appModeValidationError);
        }
    }
}
