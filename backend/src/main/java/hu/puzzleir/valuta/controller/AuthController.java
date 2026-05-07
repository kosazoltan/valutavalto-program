package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.BootstrapAdminRequestDto;
import hu.puzzleir.valuta.dto.auth.BootstrapAdminResponseDto;
import hu.puzzleir.valuta.dto.auth.ForgotPasswordRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.ResetPasswordRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.SelectRoleRequestDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.AdminBootstrapService;
import hu.puzzleir.valuta.service.PasswordResetService;
import hu.puzzleir.valuta.service.WorkerFirstTimeSetupService;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import hu.puzzleir.valuta.service.RefreshTokenService;
import hu.puzzleir.valuta.entity.RefreshToken;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import java.time.Duration;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Auth controller - login/logout + role selection (V57).
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@PreAuthorize("permitAll()")
public class AuthController {
    
    private final WorkerService workerService;
    private final JwtTokenProvider jwtTokenProvider;
    private final WorkerRepository workerRepository;
    private final WorkerRoleService workerRoleService;
    private final TokenBlacklistService tokenBlacklistService;
    private final AdminBootstrapService adminBootstrapService;
    private final WorkerFirstTimeSetupService workerFirstTimeSetupService;
    private final PasswordResetService passwordResetService;
    private final RefreshTokenService refreshTokenService;
    /** Audit P1.4 SSOT: trusted-proxy-aware kliens IP feloldas. */
    private final ClientIpResolver clientIpResolver;
    // Audit P0.3 (2026-05-03): a `refreshTokenRepository` + `bcrypt10` direct hivatkozas
    // megszuntetve — a refresh-cookie endpoint mar a `refreshTokenService.findActiveBySelectorAndVerifier`
    // O(1) selector lookup-jat hasznalja.
    
    /**
     * Login endpoint
     * 
     * POST /api/v1/auth/login
     * Body: { "companyCode": "BEST", "workerCode": "P001", "password": "1234" }
     */
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(
            @Valid @RequestBody(required = false) LoginRequestDto dto,
            HttpServletRequest request,
            HttpServletResponse httpResponse) {
        
        if (dto == null) {
            throw new ValidationException("Hiányzó request body — companyCode, workerCode és jelszó kötelező");
        }
        
        // Audit P1.4: trusted-proxy-aware IP feloldas (ClientIpResolver SSOT).
        String ipAddress = clientIpResolver.resolveClientIp(request);
        String userAgent = request.getHeader("User-Agent");

        LoginResponseDto response = workerService.login(dto, ipAddress, userAgent);

        // HttpOnly refresh cookie (vezerlokonyv par.12.3)
        // A raw UUID csak a cookie-ban utazik; a DB-ben BCrypt-hashelve van.
        Worker worker = workerRepository.findById(response.getWorker().getId())
            .orElseThrow(() -> new BusinessException(
                    "Belépés nem véglegesíthető: a dolgozó rekord nem található.",
                    "LOGIN_SESSION_ISSUE_FAILED",
                    HttpStatus.SERVICE_UNAVAILABLE));
        try {
            RefreshTokenService.IssuedToken issued = refreshTokenService.issue(worker, request);
            ResponseCookie cookie = ResponseCookie.from("refreshToken", issued.rawUuid())
                .httpOnly(true)
                .secure(request.isSecure())
                .sameSite("Strict")
                .path("/api/v1/auth")
                .maxAge(Duration.ofDays(7))
                .build();
            httpResponse.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        } catch (Exception e) {
            org.slf4j.LoggerFactory.getLogger(AuthController.class)
                .error("HttpOnly refresh cookie kiadas bukott login utan: {}", e.getMessage(), e);
            throw new BusinessException(
                    "Belépés nem véglegesíthető: a biztonságos munkamenet cookie kiadása sikertelen.",
                    "LOGIN_SESSION_ISSUE_FAILED",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }

        return ResponseEntity.ok(response);
    }
    
    /**
     * Logout endpoint
     * 
     * POST /api/v1/auth/logout
     * Headers: Authorization: Bearer {token}
     */
    @PostMapping("/logout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> logout(HttpServletRequest request, HttpServletResponse httpResponse) {
        // JWT kinyerese a headerből - blacklisting-hez
        String token = null;
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        }
        workerService.logout(token);

        // Refresh cookie torlese + DB-ben revoke (vezerlokonyv par.12.3)
        String rawRefresh = extractRefreshCookie(request);
        if (rawRefresh != null && token != null) {
            try {
                Long workerId = jwtTokenProvider.getWorkerIdFromToken(token);
                if (workerId != null) {
                    refreshTokenService.findActiveForWorker(workerId, rawRefresh)
                        .ifPresent(refreshTokenService::revoke);
                }
            } catch (Exception ignore) { /* logout ne bukjon el rajta */ }
        }
        ResponseCookie clearCookie = ResponseCookie.from("refreshToken", "")
            .httpOnly(true).secure(request.isSecure()).sameSite("Strict")
            .path("/api/v1/auth").maxAge(0).build();
        httpResponse.addHeader(HttpHeaders.SET_COOKIE, clearCookie.toString());

        return ResponseEntity.noContent().build();
    }


    /**
     * Refresh endpoint - HttpOnly cookie path (vezerlokonyv par.12.3).
     *
     * <p>Ezt a silent refresh interceptor automatikusan hivja, ha a felhasznalo
     * hosszu idore pihent (access token lejart), de a 7 napos refresh cookie
     * meg aktiv. A tenyleges refresh tokent az agy a jelentkezes ota nem latta -
     * csak a browser cookie-jar tartja.</p>
     *
     * <p>POST /api/v1/auth/refresh-cookie</p>
     * <p>Cookie: refreshToken=uuid-v4</p>
     * <p>Response: {"token": "uj-access-jwt"} + Set-Cookie rotation</p>
     *
     * <p>Token rotation: a regi refresh token revoke-olva, uj random UUID jon.
     * Ha valaki ellopta a regi cookie-t, a refresh megvan, a regi mar nem
     * hasznalhato.</p>
     */
    @PostMapping("/refresh-cookie")
    @PreAuthorize("permitAll()")
    @Transactional
    public ResponseEntity<Map<String, String>> refreshCookie(
            HttpServletRequest request,
            HttpServletResponse httpResponse) {
        String rawRefresh = extractRefreshCookie(request);
        if (rawRefresh == null) return ResponseEntity.status(401).build();

        // Audit P0.3 (2026-05-03): O(1) selector lookup + EGYETLEN BCrypt verify.
        // Korabban `findAll().stream().filter(BCrypt.matches)` minden refresh-kor
        // futtatott BCrypt-et MINDEN aktiv tokenre — DoS-kockazat (~150ms/token).
        java.util.Optional<hu.puzzleir.valuta.entity.RefreshToken> matched =
            refreshTokenService.findActiveBySelectorAndVerifier(rawRefresh);
        if (matched.isEmpty()) return ResponseEntity.status(401).build();

        hu.puzzleir.valuta.entity.RefreshToken oldRefresh = matched.get();
        Worker worker = workerRepository.findById(oldRefresh.getWorkerId())
            .filter(w -> Boolean.TRUE.equals(w.getActive()))
            .orElse(null);
        if (worker == null) return ResponseEntity.status(401).build();

        // Uj access token generalas (aktiv role + permissions)
        java.util.List<String> roleCodes = workerRoleService.getRoleCodesForWorker(worker.getId());
        String defaultRole = roleCodes.isEmpty() ? null : roleCodes.get(0);
        java.util.List<String> perms = defaultRole != null
            ? workerRoleService.getPermissionCodesForRole(defaultRole)
            : java.util.List.of();
        String newAccess = jwtTokenProvider.generateToken(worker, defaultRole, perms);

        // Token rotation - regi revoke + uj issue
        RefreshTokenService.IssuedToken newIssued = refreshTokenService.rotate(oldRefresh, worker, request);
        ResponseCookie rotated = ResponseCookie.from("refreshToken", newIssued.rawUuid())
            .httpOnly(true).secure(request.isSecure()).sameSite("Strict")
            .path("/api/v1/auth").maxAge(Duration.ofDays(7)).build();
        httpResponse.addHeader(HttpHeaders.SET_COOKIE, rotated.toString());

        return ResponseEntity.ok(Map.of("token", newAccess));
    }

    /** Cookie-bol kiolvassa a refreshToken ertekt (null, ha nincs). */
    private static String extractRefreshCookie(HttpServletRequest request) {
        if (request.getCookies() == null) return null;
        for (jakarta.servlet.http.Cookie c : request.getCookies()) {
            if ("refreshToken".equals(c.getName())) return c.getValue();
        }
        return null;
    }
    
    /**
     * Role selection endpoint (V57)
     * 
     * POST /api/v1/auth/login/select-role
     * Body: { "token": "...", "roleCode": "CASHIER" }
     * 
     * Ha a login válaszban roleSelectionRequired = true,
     * a frontend ezzel az endpoint-tal választja ki az aktív operatív role-t.
     * Visszaad egy új JWT-t ami tartalmazza az activeRole-t és permissions-t.
     */
    @PostMapping("/login/select-role")
    public ResponseEntity<LoginResponseDto> selectRole(
            @Valid @RequestBody SelectRoleRequestDto dto) {
        
        // Token validálás
        if (!jwtTokenProvider.validateToken(dto.getToken())) {
            throw new ValidationException("Érvénytelen token!");
        }

        // 🔴 Blacklist ellenőrzés
        String oldTokenId = jwtTokenProvider.getTokenIdFromToken(dto.getToken());
        if (tokenBlacklistService.isBlacklisted(oldTokenId)) {
            throw new ValidationException("A token már érvénytelen!");
        }

        Long workerId = jwtTokenProvider.getWorkerIdFromToken(dto.getToken());
        if (workerId == null) {
            throw new ValidationException("Érvénytelen token — nincs worker ID!");
        }
        
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ValidationException("Worker nem található!"));
        
        if (!Boolean.TRUE.equals(worker.getActive())) {
            throw new ValidationException("Ez a pénztáros inaktív!");
        }
        
        // Ellenőrizzük, hogy a worker-nek van-e ez a role-ja
        List<String> roleCodes = workerRoleService.getRoleCodesForWorker(workerId);
        if (!roleCodes.contains(dto.getRoleCode())) {
            throw new ValidationException("Nincs ilyen szerepköre: " + dto.getRoleCode());
        }
        
        // Permission kódok az aktív role-hoz
        List<String> permissions = workerRoleService.getPermissionCodesForRole(dto.getRoleCode());
        
        // Új JWT generálás az aktív role-lal
        String newToken = jwtTokenProvider.generateToken(worker, dto.getRoleCode(), permissions);

        // 🔴 Régi token blacklistelése (role switch → token rotation)
        tokenBlacklistService.blacklistToken(oldTokenId, workerId, "ROLE_CHANGE", LocalDateTime.now().plusHours(24));

        long expiresInMs = 86400000L;
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(expiresInMs / 1000);
        
        return ResponseEntity.ok(LoginResponseDto.builder()
                .token(newToken)
                .worker(hu.puzzleir.valuta.dto.worker.WorkerDto.from(worker))
                .expiresIn(expiresInMs)
                .expiresAt(expiresAt.toString())
                .roles(roleCodes)
                .activeRole(dto.getRoleCode())
                .permissions(permissions)
                .roleSelectionRequired(false)
                .build());
    }

    /**
     * Token refresh endpoint
     * 
     * POST /api/v1/auth/refresh
     * Headers: Authorization: Bearer {token}
     * 
     * A meglévő valid JWT-ből kiolvassa a worker adatokat,
     * és új token-t generál.
     */
    @PostMapping("/refresh")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, String>> refreshToken(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).build();
        }
        
        String token = authHeader.substring(7);

        // Token validálás
        if (!jwtTokenProvider.validateToken(token)) {
            return ResponseEntity.status(401).build();
        }

        // 🔴 Blacklist ellenőrzés — blacklisted tokennel nem lehet refreshelni
        String oldTokenId = jwtTokenProvider.getTokenIdFromToken(token);
        if (tokenBlacklistService.isBlacklisted(oldTokenId)) {
            return ResponseEntity.status(401).build();
        }

        // Worker ID kinyerése a tokenből
        Long workerId = jwtTokenProvider.getWorkerIdFromToken(token);
        if (workerId == null) {
            return ResponseEntity.status(401).build();
        }

        // Worker betöltése DB-ből (friss adatokkal)
        Worker worker = workerRepository.findById(workerId)
                .orElse(null);
        if (worker == null || !Boolean.TRUE.equals(worker.getActive())) {
            return ResponseEntity.status(401).build();
        }

        // Aktív role és permissions megőrzése a régi tokenből
        String activeRole = jwtTokenProvider.getActiveRoleFromToken(token);
        java.util.List<String> permissions = jwtTokenProvider.getPermissionsFromToken(token);

        // Új token generálás az aktív role megtartásával
        String newToken = jwtTokenProvider.generateToken(worker, activeRole, permissions);

        // 🔴 Régi token blacklistelése (token rotation)
        tokenBlacklistService.blacklistToken(oldTokenId, workerId, "REFRESH", LocalDateTime.now().plusHours(24));

        return ResponseEntity.ok(Map.of("token", newToken));
    }

    /**
     * First-run setup wizard admin bootstrap endpoint.
     *
     * <p>POST /api/v1/auth/bootstrap-admin</p>
     *
     * <p>Body: {@link BootstrapAdminRequestDto}:
     * {@code companyCode, workerCode, workerName, email?, newPassword}</p>
     *
     * <p><strong>Egyszer használható:</strong> ha a
     * {@code system_parameter.auth.bootstrap-completed = true}, 400-at dob
     * (lásd {@link AdminBootstrapService#bootstrapAdmin}).</p>
     *
     * <p><strong>Biztonság:</strong> ez a végpont <em>szándékosan</em>
     * permitAll, mert a wizard még nem rendelkezik JWT-vel. A használatot
     * az idempotencia-flag korlátozza egy alkalomra. Ezenfelül a CORS és a
     * rate limit filter is aktív.</p>
     */
    @PostMapping("/bootstrap-admin")
    public ResponseEntity<BootstrapAdminResponseDto> bootstrapAdmin(
            @Valid @RequestBody BootstrapAdminRequestDto dto) {
        BootstrapAdminResponseDto response = adminBootstrapService.bootstrapAdmin(dto);
        return ResponseEntity.ok(response);
    }

    /**
     * Opcionális read-only check a wizard számára — true, ha már lefutott
     * a bootstrap és a {@code POST /bootstrap-admin} már 400-at dobna.
     *
     * <p>GET /api/v1/auth/bootstrap-status</p>
     */
    @GetMapping("/bootstrap-status")
    public ResponseEntity<Map<String, Boolean>> bootstrapStatus() {
        boolean completed = adminBootstrapService.isBootstrapAlreadyCompleted();
        return ResponseEntity.ok(Map.of("completed", completed));
    }

    /**
     * Worker first-time password setup — a telepito wizard-ban a kivalasztott
     * dolgozo elso jelszavanak beallitasa.
     *
     * <p>POST /api/v1/auth/first-time-worker-setup</p>
     *
     * <p>Body: {@link WorkerFirstTimeSetupRequestDto}:
     * {@code companyCode, workerCode, newPassword, currentPassword?}</p>
     *
     * <p>Kulonbseg a bootstrap-admin-tol:</p>
     * <ul>
     *   <li>NEM forcolja ADMIN role-t</li>
     *   <li>NEM one-shot — minden worker-nek kulon</li>
     *   <li>JWT token-t ad vissza auto-login-hoz</li>
     * </ul>
     */
    @PostMapping("/first-time-worker-setup")
    public ResponseEntity<WorkerFirstTimeSetupResponseDto> firstTimeWorkerSetup(
            @Valid @RequestBody WorkerFirstTimeSetupRequestDto dto,
            HttpServletRequest request,
            HttpServletResponse httpResponse) {
        WorkerFirstTimeSetupResponseDto response = workerFirstTimeSetupService.setupWorkerPassword(dto);
        Worker worker = workerRepository.findById(response.getWorkerId())
            .orElseThrow(() -> new BusinessException(
                    "Telepítés utáni belépés nem véglegesíthető: a dolgozó rekord nem található.",
                    "LOGIN_SESSION_ISSUE_FAILED",
                    HttpStatus.SERVICE_UNAVAILABLE));
        try {
            RefreshTokenService.IssuedToken issued = refreshTokenService.issue(worker, request);
            ResponseCookie cookie = ResponseCookie.from("refreshToken", issued.rawUuid())
                .httpOnly(true)
                .secure(request.isSecure())
                .sameSite("Strict")
                .path("/api/v1/auth")
                .maxAge(Duration.ofDays(7))
                .build();
            httpResponse.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        } catch (Exception e) {
            org.slf4j.LoggerFactory.getLogger(AuthController.class)
                .error("HttpOnly refresh cookie kiadas bukott first-time setup utan: {}", e.getMessage(), e);
            throw new BusinessException(
                    "Telepítés utáni belépés nem véglegesíthető: a biztonságos munkamenet cookie kiadása sikertelen.",
                    "LOGIN_SESSION_ISSUE_FAILED",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }
        return ResponseEntity.ok(response);
    }

    /**
     * Elfelejtett jelszo — reset tokent general, perzisztensen tarol, majd emailben kikuldi.
     *
     * <p>POST /api/v1/auth/forgot-password</p>
     * <p>Body: {"email": "user@example.com"}</p>
     * <p>Anti-enumeration: mindig 200-at ad vissza fuggetlenul hogy az email
     * regisztralt-e vagy sem.</p>
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, Object>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequestDto dto) {
        String token = passwordResetService.requestForgotPassword(dto.getEmail());
        // Dev/test celu response — production-ban a token csak email-ben megy
        Map<String, Object> response = new java.util.HashMap<>();
        response.put("message", "Ha az email regisztralt, a reset tokent kikuldtuk.");
        // A token csak dev/test celra jelenik meg a response-ban
        if (token != null && isDevProfile()) {
            response.put("token", token);
        }
        return ResponseEntity.ok(response);
    }

    /**
     * Reset-password vegrehajtas a token + uj jelszo alapjan.
     *
     * <p>POST /api/v1/auth/reset-password</p>
     * <p>Body: {"token": "...", "newPassword": "..."}</p>
     */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequestDto dto) {
        passwordResetService.resetPassword(dto.getToken(), dto.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "Jelszo sikeresen beallitva. Most mar bejelentkezhetsz."));
    }

    private boolean isDevProfile() {
        String profile = System.getProperty("spring.profiles.active", "");
        String envProfile = System.getenv().getOrDefault("SPRING_PROFILES_ACTIVE", "");
        return profile.contains("dev") || envProfile.contains("dev");
    }
}
