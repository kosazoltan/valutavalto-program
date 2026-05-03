package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.entity.WorkerSession;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * V178/V179 Google OAuth audit (2026-05-03) regressziovedelem a {@link GoogleLoginService}-re.
 *
 * <p>Bizonyitja:
 * <ul>
 *   <li>NEM whitelisted email -> AuthenticationException</li>
 *   <li>tobb candidate (config error) -> ConflictException</li>
 *   <li>inaktiv worker -> AuthenticationException</li>
 *   <li>elso login: sub binding mentodik (bind enabled)</li>
 *   <li>elso login bind disabled -> AuthenticationException</li>
 *   <li>sub mismatch -> AuthenticationException + audit log</li>
 *   <li>happy path: LoginResponseDto + validAppModes (canonical role-bol)</li>
 *   <li>token invalid -> AuthenticationException</li>
 * </ul>
 */
class GoogleLoginServiceTest {

    private GoogleIdTokenService googleIdTokenService;
    private WorkerRepository workerRepository;
    private WorkerSessionRepository sessionRepository;
    private WorkerRoleService workerRoleService;
    private JwtTokenProvider jwtTokenProvider;
    private BranchRepository branchRepository;
    private GoogleLoginService service;

    @BeforeEach
    void setUp() {
        googleIdTokenService = Mockito.mock(GoogleIdTokenService.class);
        workerRepository = Mockito.mock(WorkerRepository.class);
        sessionRepository = Mockito.mock(WorkerSessionRepository.class);
        workerRoleService = Mockito.mock(WorkerRoleService.class);
        jwtTokenProvider = Mockito.mock(JwtTokenProvider.class);
        branchRepository = Mockito.mock(BranchRepository.class);

        service = new GoogleLoginService(
                googleIdTokenService, workerRepository, sessionRepository,
                workerRoleService, jwtTokenProvider, branchRepository);
        ReflectionTestUtils.setField(service, "bindSubOnFirstLogin", true);
    }

    private GoogleIdTokenService.VerifiedGoogleIdentity identity(String sub, String email) {
        return new GoogleIdTokenService.VerifiedGoogleIdentity(
                sub, email, true, null,
                "test-client-id", "https://accounts.google.com");
    }

    private Worker worker(String code, String email, boolean active, String googleSub) {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("TISZA").company(company).build();
        return Worker.builder()
                .id(42L)
                .code(code)
                .name("Test Worker")
                .company(company)
                .branch(branch)
                .role(WorkerRole.CASHIER)
                .active(active)
                .email(email)
                .googleLoginEnabled(true)
                .googleSubject(googleSub)
                .build();
    }

    @Test
    @DisplayName("invalid token -> AuthenticationException")
    void invalidToken_throws() throws Exception {
        when(googleIdTokenService.verify("bad"))
                .thenThrow(new GoogleIdTokenService.GoogleTokenInvalidException("BLANK_TOKEN", "..."));

        assertThatThrownBy(() -> service.loginWithGoogle("bad", new MockHttpServletRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("sikertelen");
    }

    @Test
    @DisplayName("no whitelisted candidate -> AuthenticationException")
    void notWhitelisted_throws() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of());

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("nincs engedélyezve");
    }

    @Test
    @DisplayName("multiple candidates (config error) -> ConflictException")
    void multipleCandidates_throws() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of(
                        worker("W1", "user@gmail.com", true, null),
                        worker("W2", "user@gmail.com", true, null)));

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("inactive worker -> AuthenticationException")
    void inactiveWorker_throws() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of(worker("W1", "user@gmail.com", false, "g-sub-1")));

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("inaktív");
    }

    @Test
    @DisplayName("first login + bind enabled -> google_subject mentodik")
    void firstLoginBindEnabled_savesSubject() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        Worker w = worker("W1", "user@gmail.com", true, null);
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com")).thenReturn(List.of(w));
        // Codex P1 PR #361 follow-up: a sub-binding most ellenorzi, hogy az identity.subject()
        // mar nincs masik worker-hez kotve. Empty Optional == elerheto.
        when(workerRepository.findByGoogleSubject("g-sub-1")).thenReturn(java.util.Optional.empty());
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("penztar"));
        when(workerRoleService.getPermissionCodesForRole("penztar")).thenReturn(List.of("TRANSACTION_BUY"));
        when(jwtTokenProvider.generateToken(any(), any(), any())).thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id-1");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        assertThat(response).isNotNull();
        assertThat(response.getToken()).isEqualTo("jwt-token");
        assertThat(w.getGoogleSubject()).isEqualTo("g-sub-1");
        assertThat(w.getGoogleLinkedAt()).isNotNull();
        assertThat(w.getGoogleLastLoginAt()).isNotNull();
    }

    @Test
    @DisplayName("Codex P1 PR #361: first-time bind + masik worker mar lefoglalta a subject-et -> AuthenticationException")
    void firstLoginBind_subjectAlreadyBoundToOtherWorker_throws() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-collision", "user@gmail.com"));
        Worker currentWorker = worker("W1", "user@gmail.com", true, null);
        Worker otherWorker = worker("W2", "other@gmail.com", true, "g-sub-collision");
        otherWorker.setId(99L);  // KRITIKUS: kulonbozo id, hogy a service otherWorker.getId() != currentWorker.getId() check elindiljon
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of(currentWorker));
        when(workerRepository.findByGoogleSubject("g-sub-collision"))
                .thenReturn(java.util.Optional.of(otherWorker));

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .as("subject already bound to other worker -> kontrollalt 401, NEM 500 DataIntegrityViolation")
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("masik dolgozohoz");
        verify(workerRepository, never()).save(any());
    }

    @Test
    @DisplayName("first login + bind DISABLED -> AuthenticationException")
    void firstLoginBindDisabled_throws() throws Exception {
        ReflectionTestUtils.setField(service, "bindSubOnFirstLogin", false);
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of(worker("W1", "user@gmail.com", true, null)));

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("hozzakotve");
        verify(workerRepository, never()).save(any());
    }

    @Test
    @DisplayName("sub mismatch -> AuthenticationException")
    void subMismatch_throws() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-NEW", "user@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com"))
                .thenReturn(List.of(worker("W1", "user@gmail.com", true, "g-sub-OLD")));

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest()))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("nem egyezik");
        verify(workerRepository, never()).save(any());
    }

    @Test
    @DisplayName("happy path returning sub -> LoginResponseDto + validAppModes")
    void happyPath_returningSub_buildsLoginResponseDto() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "user@gmail.com"));
        Worker w = worker("W1", "user@gmail.com", true, "g-sub-1");
        when(workerRepository.findGoogleLoginCandidatesByEmail("user@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L))
                .thenReturn(List.of("penztar", "ertektar"));
        when(jwtTokenProvider.generateToken(any(), any(), any())).thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id-1");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        assertThat(response.getToken()).isEqualTo("jwt-token");
        assertThat(response.getRoles()).containsExactlyInAnyOrder("penztar", "ertektar");
        // 2 role -> roleSelectionRequired = true
        assertThat(response.getRoleSelectionRequired()).isTrue();
        // validAppModes = ["penztar","ertektar"] (mindketto canonical role)
        assertThat(response.getValidAppModes()).containsExactlyInAnyOrder("penztar", "ertektar");
        assertThat(response.getPasswordChangeRequired()).isFalse();

        ArgumentCaptor<WorkerSession> sessionCaptor = ArgumentCaptor.forClass(WorkerSession.class);
        verify(sessionRepository).save(sessionCaptor.capture());
        assertThat(sessionCaptor.getValue().getTokenId()).isEqualTo("token-id-1");
    }

    @Test
    @DisplayName("happy path foertektar canonical role -> validAppModes tartalmazza 'full'-t")
    void happyPath_foertektarRole_setsFullAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "helga@gmail.com"));
        Worker w = worker("HELGA", "helga@gmail.com", true, "g-sub-1");
        when(workerRepository.findGoogleLoginCandidatesByEmail("helga@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("foertektar"));
        when(workerRoleService.getPermissionCodesForRole("foertektar"))
                .thenReturn(List.of("VAULT_RECEIVE", "RATE_CREATE"));
        when(jwtTokenProvider.generateToken(any(), any(), any())).thenReturn("jwt-helga");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-helga")).thenReturn("token-id-helga");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        // foertektar in SERVER_CANONICAL_ROLES -> "full" appMode
        assertThat(response.getValidAppModes()).containsExactly("full");
        assertThat(response.getActiveRole()).isEqualTo("foertektar");
        assertThat(response.getPermissions()).containsExactly("VAULT_RECEIVE", "RATE_CREATE");
    }

    @Test
    @DisplayName("V181: teruleti_vezeto canonical role -> 'kamera' appMode (NEM 'full')")
    void happyPath_teruletiVezetoRole_setsKameraAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-tv", "tv@gmail.com"));
        Worker w = worker("TV1", "tv@gmail.com", true, "g-sub-tv");
        when(workerRepository.findGoogleLoginCandidatesByEmail("tv@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("teruleti_vezeto"));
        when(workerRoleService.getPermissionCodesForRole("teruleti_vezeto"))
                .thenReturn(List.of("CAMERA_VIEW", "CAMERA_DOWNLOAD"));
        when(jwtTokenProvider.generateToken(any(), any(), any())).thenReturn("jwt-tv");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-tv")).thenReturn("token-id-tv");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        // V181: teruleti_vezeto a KAMERA_CANONICAL_ROLES-ban van -> "kamera" appMode
        // EZUTAN NEM "full" — NEM ferhetnek hozza a szerver-admin felulethez.
        assertThat(response.getValidAppModes())
                .as("teruleti_vezeto -> 'kamera' appMode V181 ota (NEM 'full')")
                .containsExactly("kamera");
        assertThat(response.getValidAppModes()).doesNotContain("full");
        assertThat(response.getActiveRole()).isEqualTo("teruleti_vezeto");
    }

    @Test
    @DisplayName("V181: biztonsagi_vezeto canonical role -> 'kamera' appMode")
    void happyPath_biztonsagiVezetoRole_setsKameraAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-sec", "sec@gmail.com"));
        Worker w = worker("SEC1", "sec@gmail.com", true, "g-sub-sec");
        when(workerRepository.findGoogleLoginCandidatesByEmail("sec@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("biztonsagi_vezeto"));
        when(workerRoleService.getPermissionCodesForRole("biztonsagi_vezeto"))
                .thenReturn(List.of("CAMERA_VIEW", "CAMERA_SETUP"));
        when(jwtTokenProvider.generateToken(any(), any(), any())).thenReturn("jwt-sec");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-sec")).thenReturn("token-id-sec");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        assertThat(response.getValidAppModes())
                .as("biztonsagi_vezeto -> 'kamera' appMode V181 ota (NEM 'full')")
                .containsExactly("kamera");
        assertThat(response.getValidAppModes()).doesNotContain("full");
    }
}
