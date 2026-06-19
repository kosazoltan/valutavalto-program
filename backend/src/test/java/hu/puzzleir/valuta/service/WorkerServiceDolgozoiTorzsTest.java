package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.entity.WorkerRoleAssignment;
import hu.puzzleir.valuta.entity.WorkerRoleDefinition;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerRoleAssignmentRepository;
import hu.puzzleir.valuta.repository.WorkerRoleDefinitionRepository;
import hu.puzzleir.valuta.repository.WorkerRolePermissionRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.MockedStatic;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-026 — a Dolgozói Törzs Adatbázis lista backend-bővítésének tesztjei.
 * Lefedi: region + roleCodes feltöltése (FR-1, FR-2), több hozzárendelés,
 * üres roleCodes, és az N+1 elkerülése (FR-3: findByCompanyIdAndWorkerIdIn pontosan egyszer).
 */
@ExtendWith(MockitoExtension.class)
class WorkerServiceDolgozoiTorzsTest {

    @Mock private CompanyRepository companyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRoleAssignmentRepository roleAssignmentRepository;
    @Mock private WorkerRoleDefinitionRepository workerRoleDefinitionRepository;
    @Mock private WorkerRolePermissionRepository workerRolePermissionRepository;
    @Mock private WorkerSessionRepository workerSessionRepository;
    @Mock private JwtTokenProvider jwtTokenProvider;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private TokenBlacklistService tokenBlacklistService;
    @Mock private WorkerRoleService workerRoleService;
    @Mock private TotpService totpService;
    @Mock private WorkerBranchAccessService workerBranchAccessService;
    @InjectMocks private WorkerService workerService;

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private Company company() {
        return Company.builder().id(COMPANY_ID).code("EBC").name("EBC Kft.").build();
    }

    private Branch branch() {
        return Branch.builder()
                .id(UUID.fromString("22222222-2222-2222-2222-222222222222"))
                .code("BR020").name("Szeged Értéktár").build();
    }

    private Worker worker(Long id, String code, String name, String region) {
        return Worker.builder()
                .id(id).code(code).name(name).region(region)
                .role(WorkerRole.CASHIER).active(true)
                .company(company()).branch(branch())
                .build();
    }

    private WorkerRoleAssignment assignment(Worker w, String roleCode) {
        return WorkerRoleAssignment.builder()
                .worker(w)
                .roleDef(WorkerRoleDefinition.builder().code(roleCode).nameHu(roleCode).build())
                .build();
    }

    @Test
    @DisplayName("FR-1/FR-2: findAllByCompany feltölti a region és roleCodes mezőket")
    void findAllByCompany_populatesRegionAndRoleCodes() {
        Worker w1 = worker(1L, "BR020-01", "Kiss Anna", "SZEGED");
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workerRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(w1));
            when(roleAssignmentRepository.findByCompanyIdAndWorkerIdIn(any(), any()))
                    .thenReturn(List.of(assignment(w1, "teruleti_vezeto"), assignment(w1, "ertektar")));

            List<WorkerDto> result = workerService.findAllByCompany();

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getRegion()).isEqualTo("SZEGED");
            assertThat(result.get(0).getRoleCodes())
                    .containsExactlyInAnyOrder("teruleti_vezeto", "ertektar");
        }
    }

    @Test
    @DisplayName("FR-2: több worker_role_assignment sor → minden role_code a roleCodes-ban")
    void findAllByCompany_multipleAssignments() {
        Worker w1 = worker(1L, "BR020-02", "Nagy Béla", "SZEGED");
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workerRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(w1));
            when(roleAssignmentRepository.findByCompanyIdAndWorkerIdIn(any(), any()))
                    .thenReturn(List.of(assignment(w1, "penztar"), assignment(w1, "ertektar")));

            List<WorkerDto> result = workerService.findAllByCompany();

            assertThat(result.get(0).getRoleCodes()).containsExactlyInAnyOrder("penztar", "ertektar");
        }
    }

    @Test
    @DisplayName("FR-2: worker_role_assignment nélküli dolgozó → üres roleCodes (nem null)")
    void findAllByCompany_emptyWhenNoAssignment() {
        Worker w1 = worker(1L, "KP-01", "Tóth Cecília", "PECS");
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workerRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(w1));
            when(roleAssignmentRepository.findByCompanyIdAndWorkerIdIn(any(), any())).thenReturn(List.of());

            List<WorkerDto> result = workerService.findAllByCompany();

            assertThat(result.get(0).getRoleCodes()).isNotNull().isEmpty();
        }
    }

    @Test
    @DisplayName("FR-3: a roleCodes feltöltés EGY batch-lekérdezéssel történik (findByCompanyIdAndWorkerIdIn 1x)")
    void findAllByCompany_noNPlusOne() {
        List<Worker> workers = List.of(
                worker(1L, "W1", "Egy", "SZEGED"),
                worker(2L, "W2", "Kettő", "SZEGED"),
                worker(3L, "W3", "Három", "PECS"));
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workerRepository.findByCompanyId(COMPANY_ID)).thenReturn(workers);
            when(roleAssignmentRepository.findByCompanyIdAndWorkerIdIn(any(), any())).thenReturn(List.of());

            workerService.findAllByCompany();

            // FR-3: függetlenül a worker-ek számától, pontosan EGY batch-hívás.
            verify(roleAssignmentRepository, times(1)).findByCompanyIdAndWorkerIdIn(eq(COMPANY_ID), any());
        }
    }

    @Test
    @DisplayName("FR-14: üres worker-lista → nincs felesleges batch-hívás, üres eredmény")
    void findAllByCompany_emptyWorkers_noBatchCall() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workerRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());

            List<WorkerDto> result = workerService.findAllByCompany();

            assertThat(result).isEmpty();
            verify(roleAssignmentRepository, times(0)).findByCompanyIdAndWorkerIdIn(any(), any());
        }
    }
}
