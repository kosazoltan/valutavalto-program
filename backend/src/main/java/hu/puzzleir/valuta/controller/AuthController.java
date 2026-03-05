package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.WorkerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Auth controller - login/logout.
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final WorkerService workerService;
    private final JwtTokenProvider jwtTokenProvider;
    private final WorkerRepository workerRepository;
    
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
