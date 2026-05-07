package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.GoogleLoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.SelectRoleRequestDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.RefreshToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.AdminBootstrapService;
import hu.puzzleir.valuta.service.GoogleLoginService;
import hu.puzzleir.valuta.service.PasswordResetService;
import hu.puzzleir.valuta.service.RefreshCookieService;
import hu.puzzleir.valuta.service.RefreshTokenService;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import hu.puzzleir.valuta.service.WorkerFirstTimeSetupService;
import hu.puzzleir.valuta.service.WorkerRoleService;
import hu.puzzleir.valuta.service.WorkerService;
import hu.puzzleir.valuta.util.ClientIpResolver;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static hu.puzzleir.valuta.test.WorkerTestFixtures.worker;

class AuthRefreshCookieIssueFailureTest {

    private final WorkerService workerService = mock(WorkerService.class);
    private final JwtTokenProvider jwtTokenProvider = mock(JwtTokenProvider.class);
    private final WorkerRepository workerRepository = mock(WorkerRepository.class);
    private final WorkerRoleService workerRoleService = mock(WorkerRoleService.class);
    private final TokenBlacklistService tokenBlacklistService = mock(TokenBlacklistService.class);
    private final AdminBootstrapService adminBootstrapService = mock(AdminBootstrapService.class);
    private final WorkerFirstTimeSetupService workerFirstTimeSetupService = mock(WorkerFirstTimeSetupService.class);
    private final PasswordResetService passwordResetService = mock(PasswordResetService.class);
    private final RefreshTokenService refreshTokenService = mock(RefreshTokenService.class);
    private final RefreshCookieService refreshCookieService = new RefreshCookieService(refreshTokenService);
    private final ClientIpResolver clientIpResolver = mock(ClientIpResolver.class);
    private final GoogleLoginService googleLoginService = mock(GoogleLoginService.class);

    @Test
    void passwordLoginFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        LoginRequestDto requestDto = new LoginRequestDto();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(clientIpResolver.resolveClientIp(request)).thenReturn("127.0.0.1");
        when(workerService.login(requestDto, "127.0.0.1", null)).thenReturn(loginResponse());
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request, null)).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.login(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    @Test
    void passwordLoginDoesNotIssueRefreshCookieBeforeRoleSelection() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        LoginRequestDto requestDto = new LoginRequestDto();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        LoginResponseDto roleSelectionResponse = LoginResponseDto.builder()
                .token("temp-token")
                .worker(WorkerDto.builder().id(42L).build())
                .roleSelectionRequired(true)
                .roles(List.of("penztar", "ertektar"))
                .activeRole(null)
                .build();
        when(clientIpResolver.resolveClientIp(request)).thenReturn("127.0.0.1");
        when(workerService.login(requestDto, "127.0.0.1", null)).thenReturn(roleSelectionResponse);

        var result = controller.login(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(roleSelectionResponse);
        assertThat(response.getHeader("Set-Cookie"))
                .contains("refreshToken=")
                .contains("Max-Age=0");
        verify(workerRepository, never()).findById(42L);
        verify(refreshTokenService, never()).issue(any(), any(), any());
    }

    @Test
    void selectRoleIssuesRefreshCookieForFinalSession() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("temp-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("temp-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("temp-token")).thenReturn(42L);
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRADE_EXECUTE"));
        when(jwtTokenProvider.generateToken(worker, "penztar", List.of("TRADE_EXECUTE"))).thenReturn("final-token");
        when(refreshTokenService.issue(worker, request, "penztar"))
                .thenReturn(new RefreshTokenService.IssuedToken("selector.verifier", "hash", Instant.now()));

        var result = controller.selectRole(new SelectRoleRequestDto("temp-token", "penztar"), request, response);

        assertThat(result.getBody()).isNotNull();
        assertThat(result.getBody().getToken()).isEqualTo("final-token");
        assertThat(result.getBody().getActiveRole()).isEqualTo("penztar");
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=selector.verifier");
    }

    @Test
    void selectRoleFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("temp-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("temp-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("temp-token")).thenReturn(42L);
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRADE_EXECUTE"));
        when(jwtTokenProvider.generateToken(worker, "penztar", List.of("TRADE_EXECUTE"))).thenReturn("final-token");
        when(refreshTokenService.issue(worker, request, "penztar")).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.selectRole(new SelectRoleRequestDto("temp-token", "penztar"), request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
        verify(tokenBlacklistService, never()).blacklistToken(any(), any(), any(), any());
    }

    @Test
    void googleLoginFailsWhenRefreshCookieCannotBeIssued() {
        GoogleAuthController controller = new GoogleAuthController(
                googleLoginService,
                refreshCookieService,
                workerRepository);
        GoogleLoginRequestDto requestDto = new GoogleLoginRequestDto();
        requestDto.setIdToken("id-token");
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(googleLoginService.loginWithGoogle("id-token", request)).thenReturn(loginResponse());
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request, null)).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.googleLogin(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    @Test
    void googleLoginDoesNotIssueRefreshCookieBeforeRoleSelection() {
        GoogleAuthController controller = new GoogleAuthController(
                googleLoginService,
                refreshCookieService,
                workerRepository);
        GoogleLoginRequestDto requestDto = new GoogleLoginRequestDto();
        requestDto.setIdToken("id-token");
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        LoginResponseDto roleSelectionResponse = LoginResponseDto.builder()
                .token("temp-token")
                .worker(WorkerDto.builder().id(42L).build())
                .roleSelectionRequired(true)
                .roles(List.of("penztar", "ertektar"))
                .activeRole(null)
                .build();
        when(googleLoginService.loginWithGoogle("id-token", request)).thenReturn(roleSelectionResponse);

        var result = controller.googleLogin(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(roleSelectionResponse);
        assertThat(response.getHeader("Set-Cookie"))
                .contains("refreshToken=")
                .contains("Max-Age=0");
        verify(workerRepository, never()).findById(42L);
        verify(refreshTokenService, never()).issue(any(), any(), any());
    }

    @Test
    void refreshCookiePreservesStoredActiveRole() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new jakarta.servlet.http.Cookie("refreshToken", "selector.verifier"));
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        RefreshToken oldRefresh = RefreshToken.builder()
                .workerId(42L)
                .activeRole(" ertektar ")
                .build();
        when(refreshTokenService.findActiveBySelectorAndVerifier("selector.verifier"))
                .thenReturn(Optional.of(oldRefresh));
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_READ"));
        when(jwtTokenProvider.generateToken(worker, "ertektar", List.of("VAULT_READ"))).thenReturn("refreshed-token");
        when(refreshTokenService.rotate(oldRefresh, worker, request, "ertektar"))
                .thenReturn(new RefreshTokenService.IssuedToken("new.selector", "hash", Instant.now()));

        var result = controller.refreshCookie(request, response);

        assertThat(result.getBody()).containsEntry("token", "refreshed-token");
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=new.selector");
    }

    @Test
    void firstTimeWorkerSetupIssuesRefreshCookieForAutoLogin() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto requestDto =
                new hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto setupResponse =
                hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto.builder()
                        .success(true)
                        .workerId(42L)
                        .token("access-token")
                        .build();
        when(workerFirstTimeSetupService.setupWorkerPassword(requestDto)).thenReturn(setupResponse);
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request, null))
                .thenReturn(new RefreshTokenService.IssuedToken("selector.verifier", "hash", Instant.now()));

        org.springframework.http.ResponseEntity<hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto> result =
                controller.firstTimeWorkerSetup(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(setupResponse);
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=selector.verifier");
    }

    @Test
    void firstTimeWorkerSetupFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto requestDto =
                new hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto();
        when(workerFirstTimeSetupService.setupWorkerPassword(requestDto))
                .thenReturn(hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto.builder()
                        .success(true)
                        .workerId(42L)
                        .token("access-token")
                        .build());
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request, null)).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.firstTimeWorkerSetup(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    private LoginResponseDto loginResponse() {
        return LoginResponseDto.builder()
                .token("access-token")
                .worker(WorkerDto.builder().id(42L).build())
                .build();
    }

}
