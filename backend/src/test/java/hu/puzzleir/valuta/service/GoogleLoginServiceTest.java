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
import hu.puzzleir.valuta.util.ClientIpResolver;
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
    private ClientIpResolver clientIpResolver;
    private TotpService totpService;
    private WorkerService workerService;
    private org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private SessionBranchResolver sessionBranchResolver;
    private GoogleLoginService service;

    @BeforeEach
    void setUp() {
        googleIdTokenService = Mockito.mock(GoogleIdTokenService.class);
        workerRepository = Mockito.mock(WorkerRepository.class);
        sessionRepository = Mockito.mock(WorkerSessionRepository.class);
        workerRoleService = Mockito.mock(WorkerRoleService.class);
        jwtTokenProvider = Mockito.mock(JwtTokenProvider.class);
        branchRepository = Mockito.mock(BranchRepository.class);
        clientIpResolver = Mockito.mock(ClientIpResolver.class);
        totpService = Mockito.mock(TotpService.class);
        workerService = Mockito.mock(WorkerService.class);
        passwordEncoder = Mockito.mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        sessionBranchResolver = Mockito.mock(SessionBranchResolver.class);
        when(clientIpResolver.resolveClientIp(any())).thenReturn("127.0.0.1");
        when(sessionBranchResolver.resolveSessionBranch(any(), any())).thenAnswer(inv -> {
            Worker worker = inv.getArgument(0);
            return worker.getBranch();
        });

        service = new GoogleLoginService(
                googleIdTokenService, workerRepository, sessionRepository,
                workerRoleService, jwtTokenProvider, branchRepository, clientIpResolver,
                totpService, workerService, passwordEncoder, sessionBranchResolver);
        ReflectionTestUtils.setField(service, "bindSubOnFirstLogin", true);
    }

    private GoogleIdTokenService.VerifiedGoogleIdentity identity(String sub, String email) {
        return new GoogleIdTokenService.VerifiedGoogleIdentity(
                sub, email, true, null,
                "test-client-id", "https://accounts.google.com",
                "Test Worker", "https://example.test/avatar.png");
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
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-token");
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
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id-1");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));
        when(clientIpResolver.resolveClientIp(any())).thenReturn("198.51.100.25");

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
        assertThat(sessionCaptor.getValue().getIpAddress()).isEqualTo("198.51.100.25");
        verify(clientIpResolver).resolveClientIp(any());
    }

    @Test
    @DisplayName("Legacy Google login role assignment nelkul penztar appMode-ban worker.role fallbackot es branch fallbackot hasznal")
    void legacyWorkerRoleFallback_setsBranchBeforeJwt() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-legacy", "cashier@gmail.com"));
        Worker w = worker("BORSI", "cashier@gmail.com", true, "g-sub-legacy");
        w.setBranch(null);
        Branch fallbackBranch = Branch.builder()
                .id(UUID.randomUUID())
                .code("TISZA")
                .name("Tisza iroda")
                .company(w.getCompany())
                .build();
        when(workerRepository.findGoogleLoginCandidatesByEmail("cashier@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(w.getCompany().getId()))
                .thenReturn(List.of(fallbackBranch));
        when(sessionBranchResolver.resolveSessionBranch(w, null)).thenReturn(fallbackBranch);
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList())).thenAnswer(inv -> {
            Branch sessionBranch = inv.getArgument(1);
            assertThat(sessionBranch).isEqualTo(fallbackBranch);
            return "jwt-legacy";
        });
        when(jwtTokenProvider.getTokenIdFromToken("jwt-legacy")).thenReturn("token-id-legacy");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest(), "penztar");

        assertThat(response.getActiveRole()).isNull();
        assertThat(response.getValidAppModes()).containsExactly("penztar");
        assertThat(response.getWorker().getBranchCode()).isEqualTo("TISZA");
        verify(sessionBranchResolver).resolveSessionBranch(w, null);
    }

    @Test
    @DisplayName("Legacy Google CASHIER role assignment nelkul nem lephet be ertektar appMode-ba")
    void legacyWorkerRoleFallback_rejectsWrongAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-legacy", "cashier@gmail.com"));
        Worker w = worker("BORSI", "cashier@gmail.com", true, "g-sub-legacy");
        when(workerRepository.findGoogleLoginCandidatesByEmail("cashier@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of());

        assertThatThrownBy(() -> service.loginWithGoogle("ok", new MockHttpServletRequest(), "ertektar"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("szerepkör");

        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList());
        verify(sessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("happy path foertektar canonical role -> validAppModes tartalmazza 'full' es 'rate-maker' modot")
    void happyPath_foertektarRole_setsFullAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-1", "helga@gmail.com"));
        Worker w = worker("HELGA", "helga@gmail.com", true, "g-sub-1");
        when(workerRepository.findGoogleLoginCandidatesByEmail("helga@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("foertektar"));
        when(workerRoleService.getPermissionCodesForRole("foertektar"))
                .thenReturn(List.of("VAULT_RECEIVE", "RATE_CREATE"));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-helga");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-helga")).thenReturn("token-id-helga");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        // foertektar: pénztár-ellenőrzés (penztar) + SERVER_CANONICAL_ROLES (full) + RATE_MAKER (rate-maker).
        assertThat(response.getValidAppModes()).containsExactly("penztar", "full", "rate-maker");
        assertThat(response.getCentralModules())
                .contains("rate-maker", "rate-publication", "national-stock", "vault-stocktake")
                .doesNotContain("permission-matrix");
        assertThat(response.getActiveRole()).isEqualTo("foertektar");
        assertThat(response.getPermissions()).containsExactly("VAULT_RECEIVE", "RATE_CREATE");
    }

    @Test
    @DisplayName("V247: teruleti_vezeto canonical role -> 'kamera' + 'full' appMode")
    void happyPath_teruletiVezetoRole_setsKameraAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-tv", "tv@gmail.com"));
        Worker w = worker("TV1", "tv@gmail.com", true, "g-sub-tv");
        when(workerRepository.findGoogleLoginCandidatesByEmail("tv@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("teruleti_vezeto"));
        when(workerRoleService.getPermissionCodesForRole("teruleti_vezeto"))
                .thenReturn(List.of("CAMERA_VIEW", "CAMERA_DOWNLOAD"));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-tv");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-tv")).thenReturn("token-id-tv");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        // teruleti_vezeto: pénztár-ellenőrzés (penztar) + kamera + kozponti helyi munkaallomas (full).
        assertThat(response.getValidAppModes())
                .as("teruleti_vezeto -> penztar + kamera + full appMode")
                .containsExactly("penztar", "kamera", "full");
        assertThat(response.getActiveRole()).isEqualTo("teruleti_vezeto");
    }

    @Test
    @DisplayName("V247: biztonsagi_vezeto canonical role -> 'kamera' + 'full' appMode")
    void happyPath_biztonsagiVezetoRole_setsKameraAppMode() throws Exception {
        when(googleIdTokenService.verify("ok"))
                .thenReturn(identity("g-sub-sec", "sec@gmail.com"));
        Worker w = worker("SEC1", "sec@gmail.com", true, "g-sub-sec");
        when(workerRepository.findGoogleLoginCandidatesByEmail("sec@gmail.com")).thenReturn(List.of(w));
        when(workerRoleService.getRoleCodesForWorker(42L)).thenReturn(List.of("biztonsagi_vezeto"));
        when(workerRoleService.getPermissionCodesForRole("biztonsagi_vezeto"))
                .thenReturn(List.of("CAMERA_VIEW", "CAMERA_SETUP"));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-sec");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-sec")).thenReturn("token-id-sec");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest());

        assertThat(response.getValidAppModes())
                .as("biztonsagi_vezeto -> kamera + full appMode")
                .containsExactly("kamera", "full");
    }

    // ============ FK-ÉRTÉKTÁR (V285): kétlépcsős értéktári belépés ============

    private Worker sharedInstitutional(Company company, Branch branch, String sub, String email) {
        return Worker.builder()
                .id(1000L).code("G_SZEGED_ET").name("Szeged Ertektar")
                .company(company).branch(branch).role(WorkerRole.CASHIER)
                .active(true).email(email).googleLoginEnabled(true).googleSubject(sub)
                .sharedAccount(true)
                .build();
    }

    private Worker personalVaultWorker(Company company, Branch branch, Long id, String name) {
        return Worker.builder()
                .id(id).code("BALI").name(name)
                .company(company).branch(branch).role(WorkerRole.CASHIER)
                .active(true).googleLoginEnabled(false).sharedAccount(false)
                .passwordHash("$2a$12$dummyhashdummyhashdummyhashdummyhashdu")
                .build();
    }

    @Test
    @DisplayName("V285: intézményi (shared) fiók + capability-flag + van személyes worker -> dolgozóválasztó (nincs token)")
    void sharedAccount_withSelectableWorkers_returnsSelection() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Értéktár").company(company).build();
        Worker institutional = sharedInstitutional(company, branch, "g-sub-szeged", "szeged.ebc@gmail.com");
        Worker personal = personalVaultWorker(company, branch, 77L, "Bali Henriett");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRepository.findSelectableVaultWorkers(any(), any())).thenReturn(List.of(personal));
        when(workerRoleService.getRoleCodesForWorker(77L)).thenReturn(List.of("ertektar"));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest(), "ertektar", true);

        assertThat(response.getVaultWorkerSelectionRequired()).isTrue();
        assertThat(response.getToken()).isNull();
        assertThat(response.getVaultBranchName()).isEqualTo("Szeged Értéktár");
        assertThat(response.getVaultWorkers()).hasSize(1);
        assertThat(response.getVaultWorkers().get(0).getName()).isEqualTo("Bali Henriett");
        assertThat(response.getVaultWorkers().get(0).getId()).isEqualTo(77L);
        // NINCS session, amíg nincs jelszavas 2. fázis
        verify(sessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("V285: intézményi fiók DE nincs személyes worker -> fallback intézményi session (nincs kizárás)")
    void sharedAccount_noSelectableWorkers_fallsBackToSession() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Értéktár").company(company).build();
        Worker institutional = sharedInstitutional(company, branch, "g-sub-szeged", "szeged.ebc@gmail.com");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRepository.findSelectableVaultWorkers(any(), any())).thenReturn(List.of());
        when(workerRoleService.getRoleCodesForWorker(1000L)).thenReturn(List.of("ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_VIEW"));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-institutional");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-institutional")).thenReturn("tid-inst");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest(), "ertektar", true);

        assertThat(response.getVaultWorkerSelectionRequired()).isFalse();
        assertThat(response.getToken()).isEqualTo("jwt-institutional");
        verify(sessionRepository).save(any());
    }

    @Test
    @DisplayName("V285: régi kliens (capability-flag false) intézményi fióknál is sessiont kap (nem törik el)")
    void sharedAccount_oldClientNoCapability_getsSession() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Értéktár").company(company).build();
        Worker institutional = sharedInstitutional(company, branch, "g-sub-szeged", "szeged.ebc@gmail.com");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRoleService.getRoleCodesForWorker(1000L)).thenReturn(List.of("ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_VIEW"));
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-old");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-old")).thenReturn("tid-old");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        // appMode "ertektar", supportsVaultWorkerSelection = false (régi kliens 3-arg overload)
        LoginResponseDto response = service.loginWithGoogle("ok", new MockHttpServletRequest(), "ertektar");

        assertThat(response.getVaultWorkerSelectionRequired()).isFalse();
        assertThat(response.getToken()).isEqualTo("jwt-old");
        verify(workerRepository, never()).findSelectableVaultWorkers(any(), any());
    }

    @Test
    @DisplayName("V285: selectVaultWorker happy path -> személyes worker JWT")
    void selectVaultWorker_happyPath() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Értéktár").company(company).build();
        Worker institutional = sharedInstitutional(company, branch, "g-sub-szeged", "szeged.ebc@gmail.com");
        Worker personal = personalVaultWorker(company, branch, 77L, "Bali Henriett");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRepository.findByIdWithCompanyAndBranch(77L)).thenReturn(java.util.Optional.of(personal));
        when(workerRoleService.getRoleCodesForWorker(77L)).thenReturn(List.of("ertektar"));
        when(workerRoleService.getPermissionCodesForRole("ertektar")).thenReturn(List.of("VAULT_VIEW"));
        when(passwordEncoder.matches("sajat-jelszo", personal.getPasswordHash())).thenReturn(true);
        when(jwtTokenProvider.generateToken(any(Worker.class), any(Branch.class), any(), org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.anyList()))
                .thenReturn("jwt-personal");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-personal")).thenReturn("tid-personal");
        when(workerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionRepository.save(any(WorkerSession.class))).thenAnswer(inv -> inv.getArgument(0));

        LoginResponseDto response = service.selectVaultWorker("ok", 77L, "sajat-jelszo",
                new MockHttpServletRequest(), "ertektar");

        assertThat(response.getToken()).isEqualTo("jwt-personal");
        assertThat(response.getActiveRole()).isEqualTo("ertektar");
        assertThat(response.getWorker().getId()).isEqualTo(77L);
        verify(workerService).assertVaultLoginNotLocked("EBC:BALI");
        verify(workerService).clearVaultLoginAttempts("EBC:BALI");
        verify(workerService, never()).recordVaultFailedAttempt(any());
    }

    @Test
    @DisplayName("V285: selectVaultWorker hibás jelszó -> AuthenticationException + lockout-számláló nő")
    void selectVaultWorker_wrongPassword_recordsAttempt() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch branch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged Értéktár").company(company).build();
        Worker institutional = sharedInstitutional(company, branch, "g-sub-szeged", "szeged.ebc@gmail.com");
        Worker personal = personalVaultWorker(company, branch, 77L, "Bali Henriett");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRepository.findByIdWithCompanyAndBranch(77L)).thenReturn(java.util.Optional.of(personal));
        when(workerRoleService.getRoleCodesForWorker(77L)).thenReturn(List.of("ertektar"));
        when(passwordEncoder.matches("rossz", personal.getPasswordHash())).thenReturn(false);

        assertThatThrownBy(() -> service.selectVaultWorker("ok", 77L, "rossz",
                new MockHttpServletRequest(), "ertektar"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Érvénytelen");
        verify(workerService).recordVaultFailedAttempt("EBC:BALI");
        verify(workerService, never()).clearVaultLoginAttempts(any());
        verify(sessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("V285: selectVaultWorker más branch workere -> generikus hiba (cross-branch védelem)")
    void selectVaultWorker_crossBranch_throws() throws Exception {
        Company company = Company.builder().id(UUID.randomUUID()).code("EBC").build();
        Branch szegedBranch = Branch.builder().id(UUID.randomUUID()).code("BR020").name("Szeged").company(company).build();
        Branch debrecenBranch = Branch.builder().id(UUID.randomUUID()).code("BR050").name("Debrecen").company(company).build();
        Worker institutional = sharedInstitutional(company, szegedBranch, "g-sub-szeged", "szeged.ebc@gmail.com");
        // A személyes worker MÁS branch-en (Debrecen) van.
        Worker personalOtherBranch = personalVaultWorker(company, debrecenBranch, 88L, "Idegen Dolgozó");

        when(googleIdTokenService.verify("ok")).thenReturn(identity("g-sub-szeged", "szeged.ebc@gmail.com"));
        when(workerRepository.findGoogleLoginCandidatesByEmail("szeged.ebc@gmail.com")).thenReturn(List.of(institutional));
        when(workerRepository.findByIdWithCompanyAndBranch(88L)).thenReturn(java.util.Optional.of(personalOtherBranch));

        assertThatThrownBy(() -> service.selectVaultWorker("ok", 88L, "barmi",
                new MockHttpServletRequest(), "ertektar"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("Érvénytelen");
        verify(sessionRepository, never()).save(any());
    }
}
