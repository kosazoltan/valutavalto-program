package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DataImportJob;
import hu.puzzleir.valuta.entity.DataImportStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DataImportJobRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DataImportServiceTest {

    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Mock
    private DataImportJobRepository dataImportJobRepository;

    @Mock
    private BranchRepository branchRepository;

    private DataImportService service;

    @BeforeEach
    void setUp() {
        service = new DataImportService(dataImportJobRepository, branchRepository);
        ReflectionTestUtils.setField(service, "simulatedSuccessEnabled", false);

        // IDOR-guard (audit 2026-06-15): findBranch most existsByIdAndCompanyId-t hív → auth-kontextus kell.
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(1L, UUID.randomUUID(), UUID.randomUUID(), "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(branchRepository.existsByIdAndCompanyId(eq(BRANCH_ID), any())).thenReturn(true);
        when(dataImportJobRepository.save(any(DataImportJob.class))).thenAnswer(inv -> {
            DataImportJob job = inv.getArgument(0);
            if (job.getId() == null) {
                job.setId(UUID.randomUUID());
            }
            return job;
        });
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void importInventoryFailsClosedWhenNoDriverConfigured() {
        DataImportJob result = service.importInventory(BRANCH_ID);

        assertThat(result.getStatus()).isEqualTo(DataImportStatus.FAILED);
        assertThat(result.getImportedRecords()).isZero();
        assertThat(result.getErrorLog()).contains("Data import driver nincs konfigurálva");
        assertThat(result.getCompletedAt()).isNotNull();
    }

    @Test
    void simulatedImportCanBeExplicitlyEnabledForIsolatedTests() {
        ReflectionTestUtils.setField(service, "simulatedSuccessEnabled", true);

        DataImportJob result = service.importInventory(BRANCH_ID);

        assertThat(result.getStatus()).isEqualTo(DataImportStatus.COMPLETED);
        assertThat(result.getImportedRecords()).isZero();
        assertThat(result.getErrorLog()).isNull();
        assertThat(result.getCompletedAt()).isNotNull();
    }
}
