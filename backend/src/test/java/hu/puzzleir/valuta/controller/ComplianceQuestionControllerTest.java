package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateQuestionAnswerDto;
import hu.puzzleir.valuta.dto.compliance.CustomerQuestionAnswerDto;
import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.ComplianceQuestionService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
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

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class ComplianceQuestionControllerTest {

    private static final UUID QUESTION_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID ANSWER_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final String ANSWER_ENDPOINT = "POST /api/v1/compliance-questions/"
            + QUESTION_ID + "/answers";

    private MockMvc mockMvc;

    @Mock
    private ComplianceQuestionService service;

    @Mock
    private IdempotencyGuard idempotencyGuard;

    @InjectMocks
    private ComplianceQuestionController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("create: érvényes kérés 201-et és id-t ad")
    void create_returns201() throws Exception {
        when(service.create(any())).thenReturn(questionDto());

        mockMvc.perform(post("/api/v1/compliance-questions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"questionText\":\"Ismeri az ügyfelet?\","
                                + "\"questionType\":\"YES_NO\",\"displayOrder\":1}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(QUESTION_ID.toString()));
    }

    @Test
    @DisplayName("create: üres questionText bean validation 400")
    void create_blankText_badRequest() throws Exception {
        mockMvc.perform(post("/api/v1/compliance-questions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"questionText\":\"   \",\"questionType\":\"YES_NO\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("listActive: pénztár-sync aktív listára delegál")
    void listActive_delegates() throws Exception {
        when(service.listActiveForCurrentCompany()).thenReturn(List.of(questionDto()));

        mockMvc.perform(get("/api/v1/compliance-questions/active"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(QUESTION_ID.toString()));

        verify(service).listActiveForCurrentCompany();
    }

    @Test
    @DisplayName("submitAnswer: sikeres idempotens válasz complete-eli a guardot")
    void submitAnswer_created_completesIdempotency() throws Exception {
        CustomerQuestionAnswerDto answer = answerDto("YES");
        when(idempotencyGuard.tryAcquire(eq("test-key-1"), eq(ANSWER_ENDPOINT),
                any(CreateQuestionAnswerDto.class), eq(CustomerQuestionAnswerDto.class)))
                .thenReturn(new IdempotencyGuard.Acquired<>(null, null, CustomerQuestionAnswerDto.class));
        when(service.submitAnswer(eq(QUESTION_ID), any(CreateQuestionAnswerDto.class))).thenReturn(answer);

        mockMvc.perform(post("/api/v1/compliance-questions/{id}/answers", QUESTION_ID)
                        .header("Idempotency-Key", "test-key-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"customerId\":42,\"answerText\":\"yes\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(ANSWER_ID.toString()));

        verify(idempotencyGuard).complete(any(), eq(answer));
    }

    @Test
    @DisplayName("submitAnswer: cached idempotent replay nem hív service-t")
    void submitAnswer_cachedIdempotentReplay_skipsService() throws Exception {
        CustomerQuestionAnswerDto cached = answerDto("NO");
        when(idempotencyGuard.tryAcquire(eq("test-key-1"), eq(ANSWER_ENDPOINT),
                any(CreateQuestionAnswerDto.class), eq(CustomerQuestionAnswerDto.class)))
                .thenReturn(new IdempotencyGuard.Acquired<>(null, cached, CustomerQuestionAnswerDto.class));

        mockMvc.perform(post("/api/v1/compliance-questions/{id}/answers", QUESTION_ID)
                        .header("Idempotency-Key", "test-key-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"customerId\":42,\"answerText\":\"no\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.answerText").value("NO"));

        verify(service, never()).submitAnswer(any(), any());
    }

    @Test
    @DisplayName("submitAnswer: service hiba fail-eli az idempotency recordot")
    void submitAnswer_serviceThrows_failsIdempotency() throws Exception {
        IdempotencyGuard.Acquired<CustomerQuestionAnswerDto> acquired =
                new IdempotencyGuard.Acquired<>(null, null, CustomerQuestionAnswerDto.class);
        when(idempotencyGuard.tryAcquire(eq("test-key-1"), eq(ANSWER_ENDPOINT),
                any(CreateQuestionAnswerDto.class), eq(CustomerQuestionAnswerDto.class)))
                .thenReturn(acquired);
        when(service.submitAnswer(eq(QUESTION_ID), any(CreateQuestionAnswerDto.class)))
                .thenThrow(new ValidationException("hibás válasz"));

        mockMvc.perform(post("/api/v1/compliance-questions/{id}/answers", QUESTION_ID)
                        .header("Idempotency-Key", "test-key-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"customerId\":42,\"answerText\":\"talán\"}"))
                .andExpect(status().isBadRequest());

        verify(idempotencyGuard).fail(acquired);
    }

    @Test
    @DisplayName("setActive: hiányzó boolean mező 400 VALIDATION_FAILED")
    void setActive_missingBoolean_badRequest() throws Exception {
        mockMvc.perform(put("/api/v1/compliance-questions/{id}/active", QUESTION_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    private static ComplianceQuestionDto questionDto() {
        return ComplianceQuestionDto.builder()
                .id(QUESTION_ID)
                .questionText("Ismeri az ügyfelet?")
                .questionType(ComplianceQuestionType.YES_NO)
                .displayOrder(1)
                .active(true)
                .createdByWorkerCode("W-001")
                .build();
    }

    private static CustomerQuestionAnswerDto answerDto(String answerText) {
        return CustomerQuestionAnswerDto.builder()
                .id(ANSWER_ID)
                .questionId(QUESTION_ID)
                .customerId(42L)
                .answerText(answerText)
                .answeredByWorkerCode("W-001")
                .build();
    }
}
