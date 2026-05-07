package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.DataImportProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DataImportJob;
import hu.puzzleir.valuta.entity.DataImportStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DataImportJobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DataImportServiceTest {

    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Mock
    private DataImportJobRepository dataImportJobRepository;

    @Mock
    private BranchRepository branchRepository;

    private DataImportService service;
    private DataImportProperties dataImportProperties;

    @BeforeEach
    void setUp() {
        dataImportProperties = new DataImportProperties();
        dataImportProperties.setSimulatedSuccessEnabled(false);
        service = new DataImportService(dataImportJobRepository, branchRepository, dataImportProperties);

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(dataImportJobRepository.save(any(DataImportJob.class))).thenAnswer(inv -> {
            DataImportJob job = inv.getArgument(0);
            if (job.getId() == null) {
                job.setId(UUID.randomUUID());
            }
            return job;
        });
    }

    @Test
    void importInventoryFailsClosedWhenNoDriverConfigured() {
        DataImportJob result = service.importInventory(BRANCH_ID);

        assertThat(result.getStatus()).isEqualTo(DataImportStatus.FAILED);
        assertThat(result.getImportedRecords()).isZero();
        assertThat(result.getErrorLog()).contains("Data import driver nincs konfigurálva");
        assertThat(result.getErrorLog()).contains("data-import.simulated-success-enabled=false");
        assertThat(result.getCompletedAt()).isNotNull();
    }

    @Test
    void simulatedImportCanBeExplicitlyEnabledForIsolatedTests() {
        dataImportProperties.setSimulatedSuccessEnabled(true);

        DataImportJob result = service.importInventory(BRANCH_ID);

        assertThat(result.getStatus()).isEqualTo(DataImportStatus.COMPLETED);
        assertThat(result.getImportedRecords()).isZero();
        assertThat(result.getErrorLog()).isNull();
        assertThat(result.getCompletedAt()).isNotNull();
    }
}
