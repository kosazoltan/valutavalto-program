package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.GoogleLoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.service.AdminBootstrapService;
import hu.puzzleir.valuta.service.GoogleLoginService;
import hu.puzzleir.valuta.service.PasswordResetService;
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
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AuthRefreshCookieIssueTest {

    private final WorkerService workerService = mock(WorkerService.class);
    private final JwtTokenProvider jwtTokenProvider = mock(JwtTokenProvider.class);
    private final WorkerRepository workerRepository = mock(WorkerRepository.class);
    private final WorkerRoleService workerRoleService = mock(WorkerRoleService.class);
    private final TokenBlacklistService tokenBlacklistService = mock(TokenBlacklistService.class);
    private final AdminBootstrapService adminBootstrapService = mock(AdminBootstrapService.class);
    private final WorkerFirstTimeSetupService workerFirstTimeSetupService = mock(WorkerFirstTimeSetupService.class);
    private final PasswordResetService passwordResetService = mock(PasswordResetService.class);
    private final RefreshTokenService refreshTokenService = mock(RefreshTokenService.class);
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
                clientIpResolver);
        LoginRequestDto requestDto = new LoginRequestDto();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(clientIpResolver.resolveClientIp(request)).thenReturn("127.0.0.1");
        when(workerService.login(requestDto, "127.0.0.1", null)).thenReturn(loginResponse());
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request)).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.login(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    @Test
    void googleLoginFailsWhenRefreshCookieCannotBeIssued() {
        GoogleAuthController controller = new GoogleAuthController(
                googleLoginService,
                refreshTokenService,
                workerRepository);
        GoogleLoginRequestDto requestDto = new GoogleLoginRequestDto();
        requestDto.setIdToken("id-token");
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(googleLoginService.loginWithGoogle("id-token", request)).thenReturn(loginResponse());
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request)).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.googleLogin(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
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
        when(refreshTokenService.issue(worker, request))
                .thenReturn(new RefreshTokenService.IssuedToken("selector.verifier", "hash", Instant.now()));

        org.springframework.http.ResponseEntity<hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto> result =
                controller.firstTimeWorkerSetup(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(setupResponse);
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=selector.verifier");
    }

    @Test
    void firstTimeWorkerSetupReturnsCommittedSuccessWhenRefreshCookieCannotBeIssued() {
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
                clientIpResolver);
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto requestDto =
                new hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto setupResponse =
                hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto.builder()
                        .success(true)
                        .message("Jelszo sikeresen beallitva.")
                        .workerId(42L)
                        .token("access-token")
                        .build();
        when(workerFirstTimeSetupService.setupWorkerPassword(requestDto)).thenReturn(setupResponse);
        when(workerRepository.findById(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(worker, request)).thenThrow(new IllegalStateException("database unavailable"));

        org.springframework.http.ResponseEntity<hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto> result =
                controller.firstTimeWorkerSetup(requestDto, request, response);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(result.getBody()).isSameAs(setupResponse);
        assertThat(result.getBody().getMessage()).contains("tartós bejelentkezési cookie nem jött létre");
        assertThat(response.getHeader("Set-Cookie")).isNull();
    }

    private LoginResponseDto loginResponse() {
        return LoginResponseDto.builder()
                .token("access-token")
                .worker(WorkerDto.builder().id(42L).build())
                .build();
    }

    private Worker worker() {
        Worker worker = new Worker();
        worker.setId(42L);
        return worker;
    }
}
