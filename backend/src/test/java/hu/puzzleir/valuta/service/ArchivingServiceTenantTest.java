package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ArchiveTask;
import hu.puzzleir.valuta.entity.ArchiveTaskStatus;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ArchiveTaskRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * F3.1 multi-tenant izoláció verifikáció az ArchivingService-en.
 *
 * Korábbi IDOR-finding: getAllTasks() findAll()-t hívott company szűrés nélkül,
 * executeTask() nem ellenőrizte a companyId-t → cross-tenant hozzáférés volt lehetséges.
 */
@ExtendWith(MockitoExtension.class)
class ArchivingServiceTenantTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID TASK_B_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    @Mock private ArchiveTaskRepository archiveTaskRepository;
    @Mock private MonthlyArchiveService monthlyArchiveService;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;

    @InjectMocks private ArchivingService archivingService;

    @Test
    @DisplayName("getAllTasks — csak a bejelentkezett cég feladatait adja vissza")
    void getAllTasks_filtersToCurrentCompany() {
        ArchiveTask taskA = new ArchiveTask();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(archiveTaskRepository.findByCompanyId(COMPANY_A)).thenReturn(List.of(taskA));

            List<ArchiveTask> result = archivingService.getAllTasks();

            assertThat(result).containsExactly(taskA);
            verify(archiveTaskRepository).findByCompanyId(COMPANY_A);
            verify(archiveTaskRepository, never()).findAll();
        }
    }

    @Test
    @DisplayName("createTask — company beállítása a security context alapján, kliens ID null-ozva")
    void createTask_setsCompanyFromContext_nullsClientId() {
        Company companyA = new Company();
        companyA.setId(COMPANY_A);

        ArchiveTask input = new ArchiveTask();
        input.setTaskType("ARCHIVE");
        input.setEntityType("TRANSACTION");
        // Kliens által küldött ID — ezt null-ozni kell (task hijacking prevention)
        input.setId(UUID.randomUUID());

        ArchiveTask saved = new ArchiveTask();
        saved.setStatus(ArchiveTaskStatus.PENDING);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(companyRepository.findById(COMPANY_A)).thenReturn(Optional.of(companyA));
            when(archiveTaskRepository.save(any())).thenReturn(saved);

            archivingService.createTask(input);

            assertThat(input.getId()).isNull();
            verify(companyRepository).findById(COMPANY_A);
            verify(archiveTaskRepository).save(input);
        }
    }

    @Test
    @DisplayName("executeTask — cross-tenant task-ID-re ResourceNotFoundException")
    void executeTask_otherCompanyTask_throws() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(archiveTaskRepository.findByIdAndCompanyId(TASK_B_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> archivingService.executeTask(TASK_B_ID))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(archiveTaskRepository).findByIdAndCompanyId(TASK_B_ID, COMPANY_A);
        }
    }

    @Test
    @DisplayName("executeTask — más cég branch-ével criteria injection blokkolva")
    void executeTask_crossTenantBranchId_throws() {
        UUID otherBranchId = UUID.fromString("44444444-4444-4444-4444-444444444444");
        ArchiveTask task = new ArchiveTask();
        task.setTaskType("ARCHIVE");
        task.setEntityType("TRANSACTION");
        task.setCriteria("branchId=" + otherBranchId + ";yearMonth=2026-01");
        task.setStatus(ArchiveTaskStatus.PENDING);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(archiveTaskRepository.findByIdAndCompanyId(TASK_B_ID, COMPANY_A))
                    .thenReturn(Optional.of(task));
            when(archiveTaskRepository.save(any())).thenAnswer(i -> i.getArgument(0));
            when(branchRepository.existsByIdAndCompanyId(otherBranchId, COMPANY_A)).thenReturn(false);

            ArchiveTask result = archivingService.executeTask(TASK_B_ID);

            assertThat(result.getStatus()).isEqualTo(ArchiveTaskStatus.FAILED);
            verify(branchRepository).existsByIdAndCompanyId(otherBranchId, COMPANY_A);
        }
    }

    @Test
    @DisplayName("executeTask — saját cég task-ja végrehajtható (COMPLETED állapot)")
    void executeTask_ownCompanyTask_succeeds() {
        ArchiveTask task = new ArchiveTask();
        task.setTaskType("ARCHIVE");
        task.setEntityType("OTHER");
        task.setStatus(ArchiveTaskStatus.PENDING);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
            when(archiveTaskRepository.findByIdAndCompanyId(TASK_B_ID, COMPANY_A))
                    .thenReturn(Optional.of(task));
            when(archiveTaskRepository.save(any())).thenAnswer(i -> i.getArgument(0));

            ArchiveTask result = archivingService.executeTask(TASK_B_ID);

            assertThat(result.getStatus()).isEqualTo(ArchiveTaskStatus.COMPLETED);
        }
    }
}
