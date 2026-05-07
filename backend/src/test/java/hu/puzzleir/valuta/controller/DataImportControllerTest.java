package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DataImportJob;
import hu.puzzleir.valuta.entity.DataImportSourceType;
import hu.puzzleir.valuta.entity.DataImportStatus;
import hu.puzzleir.valuta.entity.DataImportType;
import hu.puzzleir.valuta.service.DataImportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class DataImportControllerTest {

    private static final UUID BRANCH_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");

    private MockMvc mockMvc;

    @Mock
    private DataImportService dataImportService;

    @InjectMocks
    private DataImportController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("FAILED import job nem 200-at ad vissza")
    void importInventory_returns503WhenJobFailed() throws Exception {
        when(dataImportService.importInventory(BRANCH_ID))
                .thenReturn(job(DataImportStatus.FAILED, "Data import driver nincs konfiguralva"));

        mockMvc.perform(post("/api/v1/data-import/inventory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"branchId\":\"" + BRANCH_ID + "\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value("FAILED"))
                .andExpect(jsonPath("$.errorLog").value("Data import driver nincs konfiguralva"));
    }

    @Test
    @DisplayName("COMPLETED import job tovabbra is 200")
    void importInventory_returns200WhenJobCompleted() throws Exception {
        when(dataImportService.importInventory(BRANCH_ID))
                .thenReturn(job(DataImportStatus.COMPLETED, null));

        mockMvc.perform(post("/api/v1/data-import/inventory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"branchId\":\"" + BRANCH_ID + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));
    }

    private DataImportJob job(DataImportStatus status, String errorLog) {
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");

        return DataImportJob.builder()
                .id(UUID.randomUUID())
                .branch(branch)
                .importType(DataImportType.INVENTORY)
                .status(status)
                .sourceType(DataImportSourceType.API)
                .totalRecords(0)
                .importedRecords(0)
                .failedRecords(status == DataImportStatus.FAILED ? 1 : 0)
                .errorLog(errorLog)
                .completedAt(LocalDateTime.now())
                .build();
    }
}
