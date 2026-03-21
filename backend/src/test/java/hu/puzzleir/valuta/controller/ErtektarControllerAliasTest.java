package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class ErtektarControllerAliasTest {

    @Mock private VaultCollectionService vaultCollectionService;
    @Mock private VaultDistributionService vaultDistributionService;
    @Mock private VaultBankTransactionService vaultBankTransactionService;
    @Mock private VaultTransferService vaultTransferService;
    @Mock private MaterialReceiptService materialReceiptService;
    @Mock private StockCorrectionService stockCorrectionService;
    @Mock private ConsolidatedReportService consolidatedReportService;
    @Mock private BranchMonitoringService branchMonitoringService;

    @InjectMocks
    private ErtektarController controller;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void branchesStatus_aliasEndpointRespondsOk() throws Exception {
        BranchStatusResponse response = BranchStatusResponse.builder().isOnline(true).build();
        when(branchMonitoringService.getBranchDashboard()).thenReturn(Map.of(UUID.randomUUID(), response));

        mockMvc.perform(get("/api/v1/ertektar/branches/status"))
                .andExpect(status().isOk());
    }
}
