package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ertektar.BankTransactionResponseDto;
import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.service.*;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
    @Mock private IdempotencyGuard idempotencyGuard;

    @InjectMocks
    private ErtektarController controller;

    private static final String BANK_TX_BODY =
            "{\"transactionType\":\"BUY\",\"currencyCode\":\"EUR\",\"amount\":1000,\"exchangeRate\":390}";

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

    @Test
    void createBankTransaction_replayCachedKey_returnsCachedWithoutServiceCall() throws Exception {
        // Audit P2 #10: azonos Idempotency-Key újrajátszásnál a guard cache-elt választ ad →
        // a service NEM hívódik újra → NINCS dupla VaultBankTransaction + dupla készletmozgás.
        BankTransactionResponseDto cached = BankTransactionResponseDto.builder()
                .id(7L).transactionType("BUY").currencyCode("EUR").build();
        when(idempotencyGuard.tryAcquire(eq("KEY-1"), anyString(), any(), eq(BankTransactionResponseDto.class)))
                .thenReturn(new IdempotencyGuard.Acquired<>(null, cached, BankTransactionResponseDto.class));

        mockMvc.perform(post("/api/v1/ertektar/bank-transactions")
                        .header("Idempotency-Key", "KEY-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(BANK_TX_BODY))
                .andExpect(status().isOk());

        verify(vaultBankTransactionService, never()).createBankTransaction(any());
    }

    @Test
    void createBankTransaction_freshKey_callsServiceAndCompletes() throws Exception {
        IdempotencyRecord rec = new IdempotencyRecord();
        when(idempotencyGuard.tryAcquire(any(), anyString(), any(), eq(BankTransactionResponseDto.class)))
                .thenReturn(new IdempotencyGuard.Acquired<>(rec, null, BankTransactionResponseDto.class));
        when(vaultBankTransactionService.createBankTransaction(any()))
                .thenReturn(BankTransactionResponseDto.builder().id(8L).build());

        mockMvc.perform(post("/api/v1/ertektar/bank-transactions")
                        .header("Idempotency-Key", "KEY-2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(BANK_TX_BODY))
                .andExpect(status().isOk());

        verify(vaultBankTransactionService).createBankTransaction(any());
        verify(idempotencyGuard).complete(any(), any());
    }
}
