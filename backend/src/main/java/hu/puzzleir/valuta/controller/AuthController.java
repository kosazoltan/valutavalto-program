package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.service.WorkerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Auth controller - login/logout.
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final WorkerService workerService;
    
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
}
