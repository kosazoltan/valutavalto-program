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
import hu.puzzleir.valuta.service.SessionBranchResolver;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.ArgumentMatchers.eq;
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
    private final hu.puzzleir.valuta.service.WorkerSetupTokenService workerSetupTokenService = mock(hu.puzzleir.valuta.service.WorkerSetupTokenService.class);
    private final hu.puzzleir.valuta.repository.CompanyRepository companyRepository = mock(hu.puzzleir.valuta.repository.CompanyRepository.class);
    private final PasswordResetService passwordResetService = mock(PasswordResetService.class);
    private final RefreshTokenService refreshTokenService = mock(RefreshTokenService.class);
    private final RefreshCookieService refreshCookieService = new RefreshCookieService(refreshTokenService);
    private final SessionBranchResolver sessionBranchResolver = mock(SessionBranchResolver.class);
    private final ClientIpResolver clientIpResolver = mock(ClientIpResolver.class);
    private final GoogleLoginService googleLoginService = mock(GoogleLoginService.class);

    private AuthController controller() {
        return new AuthController(
                workerService,
                jwtTokenProvider,
                workerRepository,
                workerRoleService,
                tokenBlacklistService,
                adminBootstrapService,
                workerFirstTimeSetupService,
                workerSetupTokenService,
                companyRepository,
                passwordResetService,
                refreshTokenService,
                refreshCookieService,
                sessionBranchResolver,
                clientIpResolver);
    }

    @Test
    void passwordLoginFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = controller();
        LoginRequestDto requestDto = new LoginRequestDto();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(clientIpResolver.resolveClientIp(request)).thenReturn("127.0.0.1");
        when(workerService.login(requestDto, "127.0.0.1", null)).thenReturn(loginResponse());
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(eq(worker), eq(request), isNull(), any())).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.login(requestDto, request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
    }

    @Test
    void passwordLoginDoesNotIssueRefreshCookieBeforeRoleSelection() {
        AuthController controller = controller();
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
        verify(refreshTokenService, never()).issue(any(), any(), any(), any());
    }

    @Test
    void passwordLoginRejectsSingleRoleThatDoesNotBelongToRequestedAppModeBeforeCookie() {
        AuthController controller = controller();
        LoginRequestDto requestDto = new LoginRequestDto();
        requestDto.setAppMode("penztar");
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        LoginResponseDto wrongAppModeResponse = LoginResponseDto.builder()
                .token("access-token")
                .worker(WorkerDto.builder().id(42L).build())
                .roleSelectionRequired(false)
                .roles(List.of("audit_only_test"))
                .activeRole("audit_only_test")
                .build();
        when(clientIpResolver.resolveClientIp(request)).thenReturn("127.0.0.1");
        when(workerService.login(requestDto, "127.0.0.1", null)).thenReturn(wrongAppModeResponse);

        assertThatThrownBy(() -> controller.login(requestDto, request, response))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("nem használható");

        verify(workerRepository, never()).findById(42L);
        verify(refreshTokenService, never()).issue(any(), any(), any(), any());
    }

    @Test
    void selectRoleIssuesRefreshCookieForFinalSession() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("temp-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("temp-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("temp-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRADE_EXECUTE"));
        when(sessionBranchResolver.resolveSessionBranch(worker, "penztar")).thenReturn(worker.getBranch());
        when(jwtTokenProvider.generateToken(eq(worker), eq(worker.getBranch()), eq("penztar"), eq(List.of("TRADE_EXECUTE")), anyList()))
                .thenReturn("final-token");
        when(refreshTokenService.issue(eq(worker), eq(request), eq("penztar"), any()))
                .thenReturn(new RefreshTokenService.IssuedToken("selector.verifier", "hash", Instant.now()));

        var result = controller.selectRole(new SelectRoleRequestDto("temp-token", "penztar"), request, response);

        assertThat(result.getBody()).isNotNull();
        assertThat(result.getBody().getToken()).isEqualTo("final-token");
        assertThat(result.getBody().getActiveRole()).isEqualTo("penztar");
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=selector.verifier");
    }

    @Test
    void selectRoleRejectsRoleThatDoesNotBelongToRequestedAppMode() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("temp-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("temp-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("temp-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "audit_only_test"));

        assertThatThrownBy(() -> controller.selectRole(
                new SelectRoleRequestDto("temp-token", "audit_only_test", "penztar"),
                request,
                response))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("nem használható");

        verify(workerRoleService, never()).getPermissionCodesForRole("audit_only_test");
        verify(refreshTokenService, never()).issue(any(), any(), any(), any());
    }

    @Test
    void selectRoleFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("temp-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("temp-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("temp-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRADE_EXECUTE"));
        when(sessionBranchResolver.resolveSessionBranch(worker, "penztar")).thenReturn(worker.getBranch());
        when(jwtTokenProvider.generateToken(eq(worker), eq(worker.getBranch()), eq("penztar"), eq(List.of("TRADE_EXECUTE")), anyList()))
                .thenReturn("final-token");
        when(refreshTokenService.issue(eq(worker), eq(request), eq("penztar"), any())).thenThrow(new IllegalStateException("database unavailable"));

        assertThatThrownBy(() -> controller.selectRole(new SelectRoleRequestDto("temp-token", "penztar"), request, response))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    BusinessException businessException = (BusinessException) ex;
                    assertThat(businessException.getErrorCode()).isEqualTo("LOGIN_SESSION_ISSUE_FAILED");
                    assertThat(businessException.getHttpStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
                });
        verify(tokenBlacklistService, never()).blacklistToken(any(), any(), any(), any());
    }

    @Test
    void refreshTokenRejectsRevokedActiveRoleFromJwt() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer access-token");
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("access-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("access-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("access-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(jwtTokenProvider.getActiveRoleFromToken("access-token")).thenReturn("ertektar");
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));
        LocalDateTime tokenExpiresAt = LocalDateTime.of(2026, 5, 7, 15, 30);
        when(jwtTokenProvider.getExpirationDateTimeFromToken("access-token")).thenReturn(tokenExpiresAt);

        var result = controller.refreshToken(request);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(tokenBlacklistService).blacklistToken(
                eq("old-token-id"),
                eq(42L),
                eq(TokenBlacklistService.REASON_ROLE_REVOKED),
                eq(tokenExpiresAt));
        verify(workerRoleService, never()).getPermissionCodesForRole("ertektar");
        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
    }

    @Test
    void refreshTokenBlacklistFallbackUsesConfiguredJwtExpirationWhenTokenExpiryIsMissing() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer access-token");
        Worker worker = worker();
        LocalDateTime configuredExpiresAt = LocalDateTime.of(2026, 5, 7, 16, 30);
        when(jwtTokenProvider.validateToken("access-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("access-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("access-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(jwtTokenProvider.getExpirationDateTimeFromToken("access-token")).thenReturn(null);
        when(jwtTokenProvider.getConfiguredExpirationDateTimeFromNow()).thenReturn(configuredExpiresAt);
        when(jwtTokenProvider.getActiveRoleFromToken("access-token")).thenReturn("ertektar");
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));

        var result = controller.refreshToken(request);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(tokenBlacklistService).blacklistToken(
                eq("old-token-id"),
                eq(42L),
                eq(TokenBlacklistService.REASON_ROLE_REVOKED),
                eq(configuredExpiresAt));
    }

    @Test
    void refreshTokenRecomputesPermissionsFromCurrentRole() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer access-token");
        Worker worker = worker();
        when(jwtTokenProvider.validateToken("access-token")).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken("access-token")).thenReturn("old-token-id");
        when(tokenBlacklistService.isBlacklisted("old-token-id")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken("access-token")).thenReturn(42L);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(jwtTokenProvider.getActiveRoleFromToken("access-token")).thenReturn("penztar");
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRADE_EXECUTE"));
        when(sessionBranchResolver.resolveSessionBranch(worker, "penztar")).thenReturn(worker.getBranch());
        when(jwtTokenProvider.generateToken(eq(worker), eq(worker.getBranch()), eq("penztar"), eq(List.of("TRADE_EXECUTE")), anyList()))
                .thenReturn("refreshed-token");
        LocalDateTime tokenExpiresAt = LocalDateTime.of(2026, 5, 7, 15, 30);
        when(jwtTokenProvider.getExpirationDateTimeFromToken("access-token")).thenReturn(tokenExpiresAt);

        var result = controller.refreshToken(request);

        assertThat(result.getBody()).containsEntry("token", "refreshed-token");
        verify(jwtTokenProvider, never()).getPermissionsFromToken("access-token");
        verify(tokenBlacklistService).blacklistToken(
                eq("old-token-id"),
                eq(42L),
                eq(TokenBlacklistService.REASON_REFRESH),
                eq(tokenExpiresAt));
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
        when(googleLoginService.loginWithGoogle("id-token", request, null, false)).thenReturn(loginResponse());
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(eq(worker), eq(request), isNull(), any())).thenThrow(new IllegalStateException("database unavailable"));

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
        when(googleLoginService.loginWithGoogle("id-token", request, null, false)).thenReturn(roleSelectionResponse);

        var result = controller.googleLogin(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(roleSelectionResponse);
        assertThat(response.getHeader("Set-Cookie"))
                .contains("refreshToken=")
                .contains("Max-Age=0");
        verify(workerRepository, never()).findById(42L);
        verify(refreshTokenService, never()).issue(any(), any(), any(), any());
    }

    @Test
    void googleLoginRejectsSingleRoleThatDoesNotBelongToRequestedAppModeBeforeCookie() {
        GoogleAuthController controller = new GoogleAuthController(
                googleLoginService,
                refreshCookieService,
                workerRepository);
        GoogleLoginRequestDto requestDto = new GoogleLoginRequestDto();
        requestDto.setIdToken("id-token");
        requestDto.setAppMode("penztar");
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        // audit_only_test = NEM selectable penztar modban
        LoginResponseDto wrongAppModeResponse = LoginResponseDto.builder()
                .token("access-token")
                .worker(WorkerDto.builder().id(42L).build())
                .roleSelectionRequired(false)
                .roles(List.of("audit_only_test"))
                .activeRole("audit_only_test")
                .build();
        when(googleLoginService.loginWithGoogle("id-token", request, "penztar", false)).thenReturn(wrongAppModeResponse);

        assertThatThrownBy(() -> controller.googleLogin(requestDto, request, response))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("nem használható");

        verify(workerRepository, never()).findById(42L);
        verify(refreshTokenService, never()).issue(any(), any(), any(), any());
    }

    @Test
    void refreshCookiePreservesStoredActiveRole() {
        AuthController controller = controller();
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
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_READ"));
        when(sessionBranchResolver.resolveSessionBranch(worker, "ertektar")).thenReturn(worker.getBranch());
        when(jwtTokenProvider.generateToken(eq(worker), eq(worker.getBranch()), eq("ertektar"), eq(List.of("VAULT_READ")), anyList()))
                .thenReturn("refreshed-token");
        when(refreshTokenService.rotate(oldRefresh, worker, request, "ertektar"))
                .thenReturn(new RefreshTokenService.IssuedToken("new.selector", "hash", Instant.now()));

        var result = controller.refreshCookie(request, response);

        assertThat(result.getBody()).containsEntry("token", "refreshed-token");
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=new.selector");
    }

    @Test
    void refreshCookieRejectsRevokedStoredActiveRole() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new jakarta.servlet.http.Cookie("refreshToken", "selector.verifier"));
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        RefreshToken oldRefresh = RefreshToken.builder()
                .workerId(42L)
                .activeRole("ertektar")
                .build();
        when(refreshTokenService.findActiveBySelectorAndVerifier("selector.verifier"))
                .thenReturn(Optional.of(oldRefresh));
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));

        var result = controller.refreshCookie(request, response);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getHeader("Set-Cookie"))
                .contains("refreshToken=")
                .contains("Max-Age=0");
        verify(refreshTokenService).revoke(oldRefresh);
        verify(workerRoleService, never()).getPermissionCodesForRole("ertektar");
        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
        verify(refreshTokenService, never()).rotate(any(), any(), any(), any());
    }

    @Test
    void refreshCookieRejectsAmbiguousLegacySessionWithoutActiveRole() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new jakarta.servlet.http.Cookie("refreshToken", "selector.verifier"));
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        RefreshToken oldRefresh = RefreshToken.builder()
                .workerId(42L)
                .activeRole(null)
                .build();
        when(refreshTokenService.findActiveBySelectorAndVerifier("selector.verifier"))
                .thenReturn(Optional.of(oldRefresh));
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar", "ertektar"));

        var result = controller.refreshCookie(request, response);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getHeader("Set-Cookie"))
                .contains("refreshToken=")
                .contains("Max-Age=0");
        verify(refreshTokenService).revoke(oldRefresh);
        verify(jwtTokenProvider, never()).generateToken(any(), any(), any());
        verify(refreshTokenService, never()).rotate(any(), any(), any(), any());
    }

    @Test
    void firstTimeWorkerSetupIssuesRefreshCookieForAutoLogin() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto requestDto =
                new hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto setupResponse =
                hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto.builder()
                        .success(true)
                        .workerId(42L)
                        .activeRole("penztar")
                        .token("access-token")
                        .build();
        when(workerFirstTimeSetupService.setupWorkerPassword(requestDto)).thenReturn(setupResponse);
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(eq(worker), eq(request), eq("penztar"), any()))
                .thenReturn(new RefreshTokenService.IssuedToken("selector.verifier", "hash", Instant.now()));

        org.springframework.http.ResponseEntity<hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto> result =
                controller.firstTimeWorkerSetup(requestDto, request, response);

        assertThat(result.getBody()).isSameAs(setupResponse);
        assertThat(response.getHeader("Set-Cookie")).contains("refreshToken=selector.verifier");
    }

    @Test
    void firstTimeWorkerSetupFailsWhenRefreshCookieCannotBeIssued() {
        AuthController controller = controller();
        MockHttpServletRequest request = new MockHttpServletRequest();
        MockHttpServletResponse response = new MockHttpServletResponse();
        Worker worker = worker();
        hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto requestDto =
                new hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto();
        when(workerFirstTimeSetupService.setupWorkerPassword(requestDto))
                .thenReturn(hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto.builder()
                        .success(true)
                        .workerId(42L)
                        .activeRole("penztar")
                        .token("access-token")
                        .build());
        when(workerRepository.findByIdWithCompanyAndBranch(42L)).thenReturn(Optional.of(worker));
        when(refreshTokenService.issue(eq(worker), eq(request), eq("penztar"), any())).thenThrow(new IllegalStateException("database unavailable"));

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
