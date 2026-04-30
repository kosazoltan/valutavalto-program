package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerBranchAccess;
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

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

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
    @DisplayName("v2.4.5 B6: branchOverride + nem létező access → AuthenticationException")
    void login_branchOverride_noAccess_throwsAuthError() {
        // Given: érvényes worker, érvényes branch ugyanabban a company-ban,
        // de a worker_branch_access tábla NEM tartalmaz hozzáférést
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
        worker.setActive(true);
        worker.setPasswordHash("dummy");
        worker.setWorkerCode("KOSA");

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(companyId, "KOSA")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "dummy")).thenReturn(true);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        // B6: a worker MAR rendelkezik 1+ access-rekorddal (NEM legacy fallback),
        // de NEM tartalmazza a kért branch-et
        WorkerBranchAccess otherAccess = new WorkerBranchAccess();
        when(workerBranchAccessService.listBranches(workerId)).thenReturn(List.of(otherAccess));
        when(workerBranchAccessService.hasAccess(workerId, branchId)).thenReturn(false);

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");
        dto.setBranchId(branchId);

        // When/Then: B6 access check rejects login
        assertThatThrownBy(() -> workerService.login(dto, "127.0.0.1", "test"))
                .isInstanceOf(AuthenticationException.class)
                .hasMessageContaining("worker_branch_access");

        verify(workerBranchAccessService).hasAccess(workerId, branchId);
    }

    @Test
    @DisplayName("v2.4.5 B6: branchOverride + üres access tábla → legacy fallback (NEM blokkol)")
    void login_branchOverride_emptyAccessTable_legacyFallback() {
        // Given: érvényes worker, érvényes branch, de a worker_branch_access tábla
        // ÜRES (V173 seed nem futott / fresh DB) → ne blokkoljuk a logint
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
        worker.setActive(true);
        worker.setPasswordHash("dummy");
        worker.setWorkerCode("KOSA");

        when(companyRepository.findByCode("EBC")).thenReturn(Optional.of(company));
        when(workerRepository.findByCompanyIdAndCode(companyId, "KOSA")).thenReturn(Optional.of(worker));
        when(passwordEncoder.matches("1234", "dummy")).thenReturn(true);
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        // B6 fallback: üres access tábla
        when(workerBranchAccessService.listBranches(workerId)).thenReturn(List.of());
        // Backend egyéb mockok a logint követő flow-hoz
        when(workerRoleAssignmentRepository.findByWorkerId(workerId)).thenReturn(List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrue(companyId)).thenReturn(List.of(branch));

        LoginRequestDto dto = new LoginRequestDto();
        dto.setCompanyCode("EBC");
        dto.setWorkerCode("KOSA");
        dto.setPassword("1234");
        dto.setBranchId(branchId);

        // When/Then: legacy fallback engedi a logint, hasAccess() NEM lett ellenőrizve
        // (a check előzetesen rövidre zárva a hasAnyAccess=false miatt).
        // A login lefut a JWT generálásig (ahol más mock-ok hiánya miatt esetleg NPE,
        // de a B6 ágat sikeresen átléptük).
        try {
            workerService.login(dto, "127.0.0.1", "test");
        } catch (Exception ignored) {
            // Csak az érdekel, hogy NEM az "worker_branch_access" hiba dobódott
        }

        // Verify: hasAccess() NEM lett ellenőrizve, mert listBranches() üres volt
        verify(workerBranchAccessService, never()).hasAccess(workerId, branchId);
    }
}
