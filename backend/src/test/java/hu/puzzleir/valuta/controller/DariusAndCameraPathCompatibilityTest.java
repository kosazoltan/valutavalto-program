package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.service.CameraExportService;
import hu.puzzleir.valuta.service.CameraHashChainService;
import hu.puzzleir.valuta.service.DariusReportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDate;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class DariusAndCameraPathCompatibilityTest {

    @Mock
    private DariusReportService dariusReportService;
    @Mock
    private CameraExportService cameraExportService;
    @Mock
    private CameraHashChainService cameraHashChainService;

    @InjectMocks
    private DariusReportController dariusReportController;
    @InjectMocks
    private CameraExportController cameraExportController;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(dariusReportController, cameraExportController).build();
    }

    @Test
    void dariusGenerate_acceptsLegacyAndV1BasePath() throws Exception {
        when(dariusReportService.generateDailyReport(LocalDate.parse("2026-03-21")))
                .thenReturn(DariusDailyReportDto.builder().build());

        mockMvc.perform(post("/api/v1/darius/generate").param("date", "2026-03-21"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/darius/generate").param("date", "2026-03-21"))
                .andExpect(status().isOk());
    }

    @Test
    void cameraVerifyChain_acceptsLegacyAndV1BasePath() throws Exception {
        UUID branchId = UUID.randomUUID();
        when(cameraHashChainService.verifyChain(eq(branchId), any())).thenReturn(true);

        mockMvc.perform(post("/api/v1/camera/export/verify-chain")
                        .param("branchId", branchId.toString())
                        .param("cameraId", "CAM-1"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/camera/export/verify-chain")
                        .param("branchId", branchId.toString())
                        .param("cameraId", "CAM-1"))
                .andExpect(status().isOk());
    }
}
