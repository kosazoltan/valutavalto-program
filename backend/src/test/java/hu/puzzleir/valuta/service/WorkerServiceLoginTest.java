package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
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
}
