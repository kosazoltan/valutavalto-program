package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.SelectRoleRequestDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.servlet.http.HttpServletRequest;
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
    
    /**
     * Login endpoint
     * 
     * POST /api/v1/auth/login
     * Body: { "companyCode": "BEST", "workerCode": "P001", "password": "1234" }
     */
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(
            @Valid @RequestBody LoginRequestDto dto,
            HttpServletRequest request) {
        
        String ipAddress = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        
        LoginResponseDto response = workerService.login(dto, ipAddress, userAgent);
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
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        // JWT kinyerése a headerből — blacklisting-hez
        String token = null;
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        }
        workerService.logout(token);
        return ResponseEntity.noContent().build();
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
}
