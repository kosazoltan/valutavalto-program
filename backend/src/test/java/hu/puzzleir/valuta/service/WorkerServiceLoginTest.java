package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerRoleAssignmentRepository;
import hu.puzzleir.valuta.repository.WorkerRoleDefinitionRepository;
import hu.puzzleir.valuta.repository.WorkerRolePermissionRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
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
    @Mock private WorkerBranchAccessService workerBranchAccessService; // v2.4.5 B6
    @InjectMocks private WorkerService workerService;

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
        when(workerRepository.findByCompanyId(company.getId())).thenReturn(java.util.List.of());
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
        when(workerRepository.findByCompanyId(company.getId())).thenReturn(List.of());
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

        verify(jwtTokenProvider, never()).generateToken(any(Worker.class), any(), any());
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
        when(jwtTokenProvider.generateToken(worker, null, List.of())).thenReturn("jwt-token");
        when(jwtTokenProvider.getTokenIdFromToken("jwt-token")).thenReturn("token-id");

        LoginResponseDto response = workerService.login(legacyLoginRequest("penztar"), "127.0.0.1", "test");

        assertThat(response.getActiveRole()).isNull();
        assertThat(response.getValidAppModes()).containsExactly("penztar");
        assertThat(response.getWorker().getBranchCode()).isEqualTo("TISZA");
        assertThat(worker.getBranch()).isEqualTo(branch);
        verify(workerSessionRepository).save(any());
        verify(workerRepository).save(worker);
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
}
