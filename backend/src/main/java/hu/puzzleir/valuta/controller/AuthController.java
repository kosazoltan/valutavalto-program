package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.SelectRoleRequestDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
public class AuthController {
    
    private final WorkerService workerService;
    private final JwtTokenProvider jwtTokenProvider;
    private final WorkerRepository workerRepository;
    private final WorkerRoleService workerRoleService;
    
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
    public ResponseEntity<Void> logout() {
        workerService.logout();
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
        
        // Új token generálás
        String newToken = jwtTokenProvider.generateToken(worker);
        
        return ResponseEntity.ok(Map.of("token", newToken));
    }
}
