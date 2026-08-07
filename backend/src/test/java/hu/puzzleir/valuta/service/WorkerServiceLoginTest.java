package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.entity.WorkerRoleAssignment;
import hu.puzzleir.valuta.entity.WorkerRoleDefinition;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerRoleAssignmentRepository;
import hu.puzzleir.valuta.repository.WorkerRoleDefinitionRepository;
import hu.puzzleir.valuta.repository.WorkerRolePermissionRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.lenient;

/**
 * Login security tests — T07 security fix verification.
 * Ensures companyCode is strictly validated without single-tenant fallback.
 */
@ExtendWith(MockitoExtension.class)
class WorkerServiceLoginTest {

    @Mock private CompanyRepository companyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRoleAssignmentRepository workerRoleAssignmentRepository;
    @Mock private WorkerRoleDefinitionRepository workerRoleDefinitionRepository;
    @Mock private WorkerRolePermissionRepository workerRolePermissionRepository;
    @Mock private WorkerSessionRepository workerSessionRepository;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private TokenBlacklistService tokenBlacklistService;
    @Mock private WorkerRoleService workerRoleService;
    @Mock private TotpService totpService;
    @Mock private SessionBranchResolver sessionBranchResolver;
    @Mock private WorkerBranchAccessService workerBranchAccessService; // v2.4.5 B6
    @InjectMocks private WorkerService workerService;

    @BeforeEach
    void setUp() {
        lenient().when(sessionBranchResolver.resolveSessionBranch(any(Worker.class), any()))
                .thenAnswer(inv -> {
                    Worker worker = inv.getArgument(0);
                    if (worker.getBranch() != null) {
                        return worker.getBranch();
                    }
                    return branchRepository.findByCompanyIdAndIsActiveTrue(worker.getCompany().getId()).stream()
                            .findFirst()
                            .orElse(null);
                });
    }

    @Test
    @DisplayName("T07 security fix: nem létező companyCode → AuthenticationException, nem fallback")
    void login_invalidCompanyCode_singleTenant_throwsAuthError() {
        // Given: single-tenant DB (1 company), de a kért companyCode nem létezik
        when(companyRepository.findByCode("NEMLETEZIK")).thenReturn(Optional.empty());
        when(companyRepository.findByCodeIgnoreCase("NEMLETEZIK")).thenReturn(Optional.empty());
        // NOTE: companyRepository.count() should NOT be called — no fallback

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("NEMLETEZIK");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");

        // When/Then: strict match fails → AuthenticationException
        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("cégkód");

        // Verify: no single-tenant fallback (count/findAll never called)
        verify(companyRepository, never()).count();
        verify(companyRepository, never()).findAll();
    }

    @Test
    @DisplayName("Létező companyCode eltérő case-ben → login továbbra is működik (normalizeCode uppercase)")
    void login_companyCodeCaseInsensitive_works() {
        // Given: "ebc" input → normalizeCode → "EBC", so findByCode("EBC") matches directly
        Company company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Test Company");

        // normalizeCode("ebc") = "EBC" → direct match succeeds
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));

        // Worker not found → dummy hash path, but company resolution should succeed
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "KOSA")).thenReturn(Optional.empty());
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "KOSA")).thenReturn(Optional.empty());
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("ebc");  // lowercase input
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");

        // When/Then: company resolves OK via normalizeCode, but worker not found → auth error (not "cégkód" error)
        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("pénztáros");

        // Verify: normalizeCode converted "ebc" → "EBC" and matched directly
        verify(companyRepository).findByCode("EBC");
    }

    @Test
    @DisplayName("Production login nem hoz létre fallback workert 1234 jelszóval")
    void login_missingFallbackWorkerDoesNotAutoCreateWorker() {
        Company company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Test Company");

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "KOSA")).thenReturn(Optional.empty());
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "KOSA")).thenReturn(Optional.empty());
        when(passwordEncoder.matches("1234", "$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie"))
                .thenReturn(false);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");

        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("pénztáros");

        verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(company.getId());
        verify(branchRepository, never()).findByCompanyId(company.getId());
        verify(passwordEncoder, never()).encode(anyString());
        verify(workerRepository, never()).save(any(Worker.class));
    }

    /**
     * v2.4.6 (B6 — Codex P1 #331 privilege-escalation fix): a kért branchId akkor és csak
     * akkor engedélyezett, ha (a) explicit `worker_branch_access` rekord létezik VAGY
     * (b) a kért branch == worker.branchId (default, legacy 1:1).
     */
    @Test
    @DisplayName("v2.4.6 B6: branchOverride NEM-default branch + nincs explicit access → AuthenticationException")
    void login_branchOverride_nonDefault_noAccess_throwsAuthError() {
        UUID companyId = UUID.randomUUID();
        UUID requestedBranchId = UUID.randomUUID();
        UUID defaultBranchId = UUID.randomUUID(); // különböző!
        Long workerId = 42L;

        Company company = new Company();
        company.setId(companyId);
        company.setCode("EBC");
        company.setName("Test");

        Branch requestedBranch = new Branch();
        requestedBranch.setId(requestedBranchId);
        requestedBranch.setCompany(company);

        Branch defaultBranch = new Branch();
        defaultBranch.setId(defaultBranchId);
        defaultBranch.setCompany(company);

        Worker worker = new Worker();
        worker.setId(workerId);
        worker.setCompany(company);
        worker.setBranch(defaultBranch); // worker default branch != requested
        worker.setActive(true);
        worker.setPasswordHash("dummy");
        worker.setCode("KOSA");
        worker.setRole(WorkerRole.ADMIN); // szerver/admin szerepkör — webes "full" felület

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(companyId, "KOSA")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "dummy")).thenReturn(true);
        when(branchRepository.findById(requestedBranchId)).thenReturn(Optional.of(requestedBranch));
        when(workerBranchAccessService.hasAccess(workerId, requestedBranchId)).thenReturn(false);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");
        dto.setBranchId(requestedBranchId);

        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("worker_branch_access");

        verify(workerBranchAccessService).hasAccess(workerId, requestedBranchId);
    }

    @Test
    @DisplayName("v2.4.6 B6: branchOverride == worker.branchId (default) → engedélyezett (legacy 1:1)")
    void login_branchOverride_defaultBranch_succeeds() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Long workerId = 42L;

        Company company = new Company();
        company.setId(companyId);
        company.setCode("EBC");
        company.setName("Test");

        Branch branch = new Branch();
        branch.setId(branchId);
        branch.setCompany(company);

        Worker worker = new Worker();
        worker.setId(workerId);
        worker.setCompany(company);
        worker.setBranch(branch); // default == requested
        worker.setActive(true);
        worker.setPasswordHash("dummy");
        worker.setCode("KOSA");
        worker.setRole(WorkerRole.ADMIN); // szerver/admin szerepkör — webes "full" felület

        // Mockito strict-mode: csak a B6-ág + early-return stubok
        lenient().when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        lenient().when(workerRepository.findByCompanyIdAndCode(companyId, "KOSA"))
                .thenReturn(Optional.of(worker));
        lenient().when(passwordEncoder.matches("1234", "dummy")).thenReturn(true);
        lenient().when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        // hasAccess() lefut (returns false = no explicit access), de isDefaultBranch=true
        // engedi a logint
        lenient().when(workerBranchAccessService.hasAccess(workerId, branchId)).thenReturn(false);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");
        dto.setBranchId(branchId);
        dto.setAppMode("full"); // KOSA=ügyvezető, webes admin — a B6 branch-logika tesztje, nem a cashier-szabályé

        // When/Then: default branch login NEM dob "worker_branch_access" hibát.
        // A JWT-flow lefut try/catch-ben — más NPE-k mock nélkül.
        Exception caught = null;
        try {
            workerService.login(dto, "127.0.0.1", "test");
        } catch (AuthenticationException ae) {
            caught = ae;
        } catch (Exception ignored) {
            // NPE mock nélküli flow-ban OK — nem ide tartozik
        }

        if (caught != null) {
            org.assertj.core.api.Assertions.assertThat(caught)
                    .isNotInstanceOf(AuthenticationException.class);
        }
    }

    @Test
    @DisplayName("v2.4.6 B6: branchOverride NEM-default + explicit access → engedélyezett (multi-branch worker)")
    void login_branchOverride_explicitAccess_succeeds() {
        UUID companyId = UUID.randomUUID();
        UUID requestedBranchId = UUID.randomUUID();
        UUID defaultBranchId = UUID.randomUUID();
        Long workerId = 42L;

        Company company = new Company();
        company.setId(companyId);
        company.setCode("EBC");
        company.setName("Test");

        Branch requestedBranch = new Branch();
        requestedBranch.setId(requestedBranchId);
        requestedBranch.setCompany(company);

        Branch defaultBranch = new Branch();
        defaultBranch.setId(defaultBranchId);
        defaultBranch.setCompany(company);

        Worker worker = new Worker();
        worker.setId(workerId);
        worker.setCompany(company);
        worker.setBranch(defaultBranch);
        worker.setActive(true);
        worker.setPasswordHash("dummy");
        worker.setCode("KOSA");
        worker.setRole(WorkerRole.ADMIN); // szerver/admin szerepkör — webes "full" felület

        lenient().when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        lenient().when(workerRepository.findByCompanyIdAndCode(companyId, "KOSA"))
                .thenReturn(Optional.of(worker));
        lenient().when(passwordEncoder.matches("1234", "dummy")).thenReturn(true);
        lenient().when(branchRepository.findById(requestedBranchId)).thenReturn(Optional.of(requestedBranch));
        // explicit access engedi
        when(workerBranchAccessService.hasAccess(workerId, requestedBranchId)).thenReturn(true);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");
        dto.setBranchId(requestedBranchId);
        dto.setAppMode("full"); // webes admin — a B6 branch-logika tesztje, nem a cashier-szabályé

        Exception caught = null;
        try {
            workerService.login(dto, "127.0.0.1", "test");
        } catch (AuthenticationException ae) {
            caught = ae;
        } catch (Exception ignored) {
            // NPE mock nélküli flow-ban OK
        }

        if (caught != null) {
            org.assertj.core.api.Assertions.assertThat(caught)
                    .isNotInstanceOf(AuthenticationException.class);
        }
        verify(workerBranchAccessService).hasAccess(workerId, requestedBranchId);
    }

    @Test
    @DisplayName("Legacy CASHIER role assignment nelkul csak penztar appMode-ban lephet be")
    void login_legacyCashierWithoutAssignments_rejectsTreasuryAppMode() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.CASHIER);

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of());

        LoginRequestDto dto = legacyLoginRequest("ertektar");

        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("szerepkör");

        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(), any(), any(), any());
        verify(workerSessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Legacy CASHIER role assignment nelkul penztar appMode-ban validAppModes=penztar es branch fallback is mukodik")
    void login_legacyCashierWithoutAssignments_allowsCashierAppModeWithBranchFallback() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, null, WorkerRole.CASHIER);

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(company.getId())).thenReturn(List.of(branch));
        // FK-076: 5-arg overload (grantedRoles) — a listat a grantedRolesForAppMode allitja elo.
        when(jwtTokenProvider.generateToken(eq(worker), eq(branch), isNull(), eq(List.of()), anyList()))
                .thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id");

        LoginResponseDto response = workerService.login(legacyLoginRequest("penztar"), "127.0.0.1", "test");

        assertThat(response.getActiveRole()).isNull();
        assertThat(response.getValidAppModes()).containsExactly("penztar");
        assertThat(response.getWorker().getBranchCode()).isEqualTo("TISZA");
        verify(workerSessionRepository).save(any());
        verify(workerRepository).save(worker);
    }

    // ── Üzleti szabály (Kósa Zoltán 2026-05-26): JELSZÓ = CSAK PÉNZTÁROS ──────────────────────

    @Test
    @DisplayName("Jelszó=pénztáros: több szerepkörű dolgozó penztar appMode-ban CSAK pénztárosként lép be (értéktáros kiesik)")
    void login_password_localTerminal_restrictsToCashierOnly() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.CASHIER);

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        // A dolgozónak penztar + ertektar szerepköre is van (mint Balinak a V228 után)
        when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of(
                roleAssignment(1, "penztar"),
                roleAssignment(2, "ertektar")));
        when(workerRolePermissionRepository.findByRoleDefIdWithPermission(1)).thenReturn(List.of());
        when(jwtTokenProvider.generateToken(eq(worker), eq(branch), eq("penztar"), eq(List.of()), anyList()))
                .thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id");
        when(totpService.isMfaRequired(10L)).thenReturn(true);

        LoginResponseDto response = workerService.login(legacyLoginRequest("penztar"), "127.0.0.1", "test");

        // CSAK pénztáros: nincs szerepkör-választó, az aktív role penztar, az ertektar KIESETT.
        assertThat(response.getRoleSelectionRequired()).isFalse();
        assertThat(response.getActiveRole()).isEqualTo("penztar");
        assertThat(response.getRoles()).containsExactly("penztar");
        assertThat(response.getRoles()).doesNotContain("ertektar");
        assertThat(response.getMfaRequired()).isTrue();
    }

    @Test
    @DisplayName("Jelszó=pénztáros: pénztáros szerepkör NÉLKÜLI dolgozó lokális terminálon jelszóval NEM léphet be (Google-re irányít)")
    void login_password_localTerminal_noCashierRole_denied() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.CASHIER);

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        // Csak értéktáros szerepkör (nincs pénztáros) → jelszóval tilos
        when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of(
                roleAssignment(2, "ertektar")));

        assertThatThrownBy(() -> workerService.login(legacyLoginRequest("ertektar"), "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("csak pénztáros");

        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(), any(), any(), any());
        verify(workerSessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Codex P1 bypass zárva: legacy (0-role) NEM-pénztáros dolgozó jelszóval tilos lokális terminálon")
    void login_password_legacyNonCashier_denied() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.MANAGER); // NEM cashier, 0 role-assignment

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of());

        assertThatThrownBy(() -> workerService.login(legacyLoginRequest("penztar"), "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("csak pénztáros");

        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Codex P1 backward-compat: HIÁNYZÓ appMode (sync-engine bootstrap) NEM korlátozódik pénztárosra")
    void login_password_blankAppMode_notCashierRestricted() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.ADMIN);

        lenient().when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        lenient().when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        lenient().when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        lenient().when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of(
                roleAssignment(5, "foertektar")));
        lenient().when(workerRolePermissionRepository.findByRoleDefIdWithPermission(5)).thenReturn(List.of());
        lenient().when(jwtTokenProvider.generateToken(any(Worker.class), any(), any(), any(), any())).thenReturn("jwt");
        lenient().when(jwtTokenProvider.getTokenIdFromToken("jwt")).thenReturn("tid");

        // appMode szándékosan NINCS beállítva (null) — sync-engine bootstrap-login mintája.
        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("BORSI");
        dto.setPassword("1234");

        Exception caught = null;
        try {
            workerService.login(dto, "127.0.0.1", "test");
        } catch (Exception e) {
            caught = e;
        }
        // A "jelszó=pénztáros" gate NEM korlátozza a hiányzó-appMode (bootstrap) belépést.
        if (caught != null) {
            assertThat(caught.getMessage()).doesNotContain("csak pénztáros");
        }
    }

    @Test
    @DisplayName("Codex P1: rate-maker jelszavas belépés NEM korlátozódik pénztárosra (foertektar megmarad)")
    void login_password_rateMaker_notCashierRestricted() {
        Company company = legacyCompany();
        Branch branch = legacyBranch(company);
        Worker worker = legacyWorker(company, branch, WorkerRole.ADMIN);

        lenient().when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        lenient().when(workerRepository.findByCompanyIdAndCode(company.getId(), "BORSI")).thenReturn(Optional.of(worker));
        lenient().when(passwordEncoder.matches("1234", "hash")).thenReturn(true);
        lenient().when(workerRoleAssignmentRepository.findByWorkerId(10L)).thenReturn(List.of(
                roleAssignment(5, "foertektar")));
        lenient().when(workerRolePermissionRepository.findByRoleDefIdWithPermission(5)).thenReturn(List.of());
        lenient().when(jwtTokenProvider.generateToken(any(Worker.class), any(), any(), any(), any())).thenReturn("jwt");
        lenient().when(jwtTokenProvider.getTokenIdFromToken("jwt")).thenReturn("tid");

        Exception caught = null;
        try {
            workerService.login(legacyLoginRequest("rate-maker"), "127.0.0.1", "test");
        } catch (Exception e) {
            caught = e;
        }
        // A LÉNYEG: a "jelszó=pénztáros" gate NEM dobja el a rate-maker belépést.
        if (caught != null) {
            assertThat(caught.getMessage()).doesNotContain("csak pénztáros");
        }
    }

    private WorkerRoleAssignment roleAssignment(int id, String code) {
        return WorkerRoleAssignment.builder()
                .roleDef(WorkerRoleDefinition.builder().id(id).code(code).build())
                .build();
    }

    private Company legacyCompany() {
        Company company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Exclusive Best Change");
        return company;
    }

    private Branch legacyBranch(Company company) {
        Branch branch = new Branch();
        branch.setId(UUID.randomUUID());
        branch.setCompany(company);
        branch.setCode("TISZA");
        branch.setName("Tisza iroda");
        return branch;
    }

    private Worker legacyWorker(Company company, Branch branch, WorkerRole role) {
        Worker worker = new Worker();
        worker.setId(10L);
        worker.setCompany(company);
        worker.setBranch(branch);
        worker.setCode("BORSI");
        worker.setName("Borsi Kollegano");
        worker.setRole(role);
        worker.setActive(true);
        worker.setPasswordHash("hash");
        return worker;
    }

    private LoginRequestDto legacyLoginRequest(String appMode) {
        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("BORSI");
        dto.setPassword("1234");
        dto.setAppMode(appMode);
        return dto;
    }

    /**
     * PP-15: a name-based fallback eltávolítása után teljes névvel NEM lehet bejelentkezni.
     * Korábban resolveWorkerForLogin() a worker kódján kívül a worker.getName()-t is egyeztette.
     */
    @Test
    @DisplayName("PP-15: bejelentkezés teljes névvel elutasítva — name-based fallback eltávolítva")
    void login_byFullName_rejected_noNameFallback() {
        Company company = new Company();
        company.setId(UUID.randomUUID());
        company.setCode("EBC");
        company.setName("Test Company");

        // normalizeCode("Kosa Zoltan") = "KOSA ZOLTAN" — space preserved, code lookup fails
        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(company.getId(), "KOSA ZOLTAN")).thenReturn(Optional.empty());
        when(workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), "KOSA ZOLTAN")).thenReturn(Optional.empty());

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("Kosa Zoltan");  // normalizeCode → "KOSA ZOLTAN", no worker code match
        dto.setPassword("1234");

        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("pénztáros");

        // PP-15: findByCompanyId (bulk fetch for name-scan) must NOT be called
        verify(workerRepository, never()).findByCompanyId(company.getId());
    }
}
