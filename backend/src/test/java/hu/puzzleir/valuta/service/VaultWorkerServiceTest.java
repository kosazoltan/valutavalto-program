package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.VaultWorkerCreateRequestDto;
import hu.puzzleir.valuta.dto.auth.VaultWorkerOptionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-ÉRTÉKTÁR (V285): VaultWorkerService unit tesztek — a szűkített értéktári dolgozó-felvétel.
 */
class VaultWorkerServiceTest {

    private WorkerRepository workerRepository;
    private BranchRepository branchRepository;
    private CompanyRepository companyRepository;
    private WorkerRoleService workerRoleService;
    private PasswordEncoder passwordEncoder;
    private VaultWorkerService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    private Company company;
    private Branch branch;

    @BeforeEach
    void setUp() {
        workerRepository = Mockito.mock(WorkerRepository.class);
        branchRepository = Mockito.mock(BranchRepository.class);
        companyRepository = Mockito.mock(CompanyRepository.class);
        workerRoleService = Mockito.mock(WorkerRoleService.class);
        passwordEncoder = Mockito.mock(PasswordEncoder.class);
        service = new VaultWorkerService(workerRepository, branchRepository, companyRepository,
                workerRoleService, passwordEncoder);

        company = Company.builder().id(COMPANY_ID).code("EBC").build();
        branch = Branch.builder().id(BRANCH_ID).code("BR020").name("Szeged Értéktár").company(company).build();

        securityUtilsMock = Mockito.mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        securityUtilsMock.when(SecurityUtils::getCurrentWorkerId).thenReturn(1000L);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    @Test
    @DisplayName("createVaultWorker happy path: bcrypt jelszó + saját branch + ertektar role")
    void createVaultWorker_happyPath() {
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.existsByCompanyIdAndCode(eq(COMPANY_ID), any())).thenReturn(false);
        when(passwordEncoder.encode("Titok123")).thenReturn("$2a$12$hash");
        when(workerRepository.saveAndFlush(any(Worker.class))).thenAnswer(inv -> {
            Worker w = inv.getArgument(0);
            w.setId(55L);
            return w;
        });

        VaultWorkerOptionDto result = service.createVaultWorker(
                new VaultWorkerCreateRequestDto("Bali Henriett", "Titok123", "Titok123"));

        assertThat(result.getId()).isEqualTo(55L);
        assertThat(result.getName()).isEqualTo("Bali Henriett");

        org.mockito.ArgumentCaptor<Worker> captor = org.mockito.ArgumentCaptor.forClass(Worker.class);
        verify(workerRepository).saveAndFlush(captor.capture());
        Worker saved = captor.getValue();
        assertThat(saved.getPasswordHash()).isEqualTo("$2a$12$hash");
        assertThat(saved.getBranch().getId()).isEqualTo(BRANCH_ID);
        assertThat(saved.getCompany().getId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getSharedAccount()).isFalse();
        assertThat(saved.getGoogleLoginEnabled()).isFalse();
        assertThat(saved.getActive()).isTrue();
        assertThat(saved.getCode()).startsWith("VW");
        // ertektar canonical role hozzárendelve
        verify(workerRoleService).assignRole(55L, "ertektar");
    }

    @Test
    @DisplayName("createVaultWorker: eltérő jelszó-megerősítés -> ValidationException")
    void createVaultWorker_passwordMismatch_throws() {
        assertThatThrownBy(() -> service.createVaultWorker(
                new VaultWorkerCreateRequestDto("Bali Henriett", "Titok123", "Masik456")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem egyezik");
        verify(workerRepository, never()).saveAndFlush(any());
        verify(workerRoleService, never()).assignRole(any(), any());
    }

    @Test
    @DisplayName("createVaultWorker: nincs branch a kontextusban -> ValidationException")
    void createVaultWorker_noBranch_throws() {
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);
        assertThatThrownBy(() -> service.createVaultWorker(
                new VaultWorkerCreateRequestDto("Bali Henriett", "Titok123", "Titok123")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("értéktár");
        verify(workerRepository, never()).saveAndFlush(any());
    }
}
