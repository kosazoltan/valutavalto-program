package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.BootstrapAdminRequestDto;
import hu.puzzleir.valuta.dto.auth.BootstrapAdminResponseDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.SelectRoleRequestDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.AdminBootstrapService;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import hu.puzzleir.valuta.service.RefreshTokenService;
import hu.puzzleir.valuta.entity.RefreshToken;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import java.time.Duration;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    private final RefreshTokenService refreshTokenService;
    
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
        
        String ipAddress = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        
        LoginResponseDto response = workerService.login(dto, ipAddress, userAgent);

        // HttpOnly refresh cookie (vezerlokonyv par.12.3)
        // A raw UUID csak a cookie-ban utazik; a DB-ben BCrypt-hashelve van.
        try {
            Worker worker = workerRepository.findById(response.getWorker().getId())
                .orElseThrow(() -> new ValidationException("Worker nem talalhato login utan"));
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
                .warn("HttpOnly refresh cookie kiadas bukott: {}", e.getMessage());
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
}
