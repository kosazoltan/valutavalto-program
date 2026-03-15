package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.auth.GoogleLoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerSession;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.WorkerRoleService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Google OAuth login controller.
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@PreAuthorize("permitAll()")
public class GoogleAuthController {

    private final WorkerRepository workerRepository;
    private final WorkerSessionRepository sessionRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final WorkerRoleService workerRoleService;

    @Value("${google.client.id:}")
    private String googleClientId;

    @PostMapping("/google-login")
    public ResponseEntity<?> googleLogin(
            @Valid @RequestBody GoogleLoginRequestDto request,
            HttpServletRequest httpRequest) {

        if (googleClientId == null || googleClientId.isBlank()) {
            throw new ValidationException("Google Client ID nincs konfigurálva!");
        }

        GoogleTokenInfo tokenInfo = fetchTokenInfo(request.getIdToken());
        if (tokenInfo == null
                || tokenInfo.getAud() == null
                || !googleClientId.equals(tokenInfo.getAud())
                || !Boolean.TRUE.equals(tokenInfo.getEmailVerified())
                || tokenInfo.getEmail() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Érvénytelen Google token!"));
        }

        Worker worker = workerRepository.findByEmail(tokenInfo.getEmail())
                .orElse(null);
        if (worker == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Google fiók nincs regisztrálva"));
        }
        if (!Boolean.TRUE.equals(worker.getActive())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Ez a pénztáros inaktív!"));
        }

        // Operatív szerepkör logika (V57)
        List<String> roleCodes = workerRoleService.getRoleCodesForWorker(worker.getId());
        String activeRole = null;
        List<String> permissions = List.of();
        boolean roleSelectionRequired = false;

        if (roleCodes.size() == 1) {
            activeRole = roleCodes.get(0);
            permissions = workerRoleService.getPermissionCodesForRole(activeRole);
        } else if (roleCodes.size() > 1) {
            roleSelectionRequired = true;
        }

        String token = jwtTokenProvider.generateToken(worker, activeRole, permissions);
        String tokenId = jwtTokenProvider.getTokenIdFromToken(token);

        WorkerSession session = WorkerSession.builder()
                .company(worker.getCompany())
                .worker(worker)
                .branch(worker.getBranch())
                .loginAt(LocalDateTime.now())
                .ipAddress(httpRequest.getRemoteAddr())
                .userAgent(httpRequest.getHeader("User-Agent"))
                .tokenId(tokenId)
                .build();

        sessionRepository.save(session);
        worker.setLastLoginAt(LocalDateTime.now());
        workerRepository.save(worker);

        long expiresInMs = 86400000L;
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(expiresInMs / 1000);

        return ResponseEntity.ok(LoginResponseDto.builder()
                .token(token)
                .worker(WorkerDto.from(worker))
                .expiresIn(expiresInMs)
                .expiresAt(expiresAt.toString())
                .roles(roleCodes)
                .activeRole(activeRole)
                .permissions(permissions)
                .roleSelectionRequired(roleSelectionRequired)
                .build());
    }

    private GoogleTokenInfo fetchTokenInfo(String idToken) {
        RestTemplate restTemplate = new RestTemplate();
        String url = "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken;
        try {
            return restTemplate.getForObject(url, GoogleTokenInfo.class);
        } catch (HttpClientErrorException ex) {
            return null;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class GoogleTokenInfo {
        private String aud;
        private String email;
        @JsonProperty("email_verified")
        private Boolean emailVerified;

        public String getAud() {
            return aud;
        }

        public void setAud(String aud) {
            this.aud = aud;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public Boolean getEmailVerified() {
            return emailVerified;
        }

        public void setEmailVerified(Boolean emailVerified) {
            this.emailVerified = emailVerified;
        }
    }
}
