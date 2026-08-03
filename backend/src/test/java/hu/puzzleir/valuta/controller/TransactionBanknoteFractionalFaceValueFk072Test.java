package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.repository.TransactionBanknoteRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;
import java.util.UUID;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-072 biztonsági fix-kör (Codex BLOCKING): a Bankjegy-bontás backend végpontja
 * (POST /api/v1/transactions/{id}/banknotes) a frontend-védelem (FR-6) megkerülésével,
 * direkt API-hívással ma elfogad 1 alatti (tört) névértéket — a DTO {@code @DecimalMin("0.01")}
 * átengedi. Az elvárt viselkedés: a tört névérték bean-validációs hibával elutasítva,
 * magyar üzenettel, perzisztálás nélkül.
 *
 * Sima mock() (nem MockitoExtension): GREEN után a tört-esetben a bean-validáció már a
 * controller-metódus ELŐTT elutasít, így a repo-stubok nem futnak — strict stubbing alatt
 * ez UnnecessaryStubbing lenne (ld. memory: red-teszt-mockito-strict-stubs-csapda).
 */
class TransactionBanknoteFractionalFaceValueFk072Test {

    private static final long TRANSACTION_ID = 42L;
    private static final UUID COMPANY_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");

    private TransactionBanknoteRepository banknoteRepository;
    private TransactionRepository transactionRepository;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        banknoteRepository = mock(TransactionBanknoteRepository.class);
        transactionRepository = mock(TransactionRepository.class);
        mockMvc = MockMvcBuilders
                .standaloneSetup(new TransactionBanknoteController(banknoteRepository, transactionRepository))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        when(transactionRepository.findByIdAndCompanyId(eq(TRANSACTION_ID), any()))
                .thenReturn(Optional.of(mock(Transaction.class)));
        when(banknoteRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("BLOCKING: 1 alatti névérték (0.5) direkt API-hívásból → magyar validációs hiba, nincs mentés")
    void fractionalFaceValue_rejectedBeforePersist() throws Exception {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            mockMvc.perform(post("/api/v1/transactions/{transactionId}/banknotes", TRANSACTION_ID)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"currencyCode\":\"JPY\",\"faceValue\":0.5,\"quantity\":1,\"direction\":\"IN\"}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.fieldErrors.faceValue", containsString("1-nél kisebb")));

            verify(banknoteRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Regresszió: egész névérték (500 × 2) változatlanul rögzíthető")
    void wholeFaceValue_stillAccepted() throws Exception {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            mockMvc.perform(post("/api/v1/transactions/{transactionId}/banknotes", TRANSACTION_ID)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"currencyCode\":\"JPY\",\"faceValue\":500,\"quantity\":2,\"direction\":\"IN\"}"))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.totalValue").value(1000));

            verify(banknoteRepository).save(any());
        }
    }
}
