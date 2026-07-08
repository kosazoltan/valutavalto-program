package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateQuestionAnswerDto;
import hu.puzzleir.valuta.dto.compliance.CustomerQuestionAnswerDto;
import hu.puzzleir.valuta.dto.compliance.UpdateComplianceQuestionDto;
import hu.puzzleir.valuta.entity.ComplianceQuestion;
import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import hu.puzzleir.valuta.entity.CustomerQuestionAnswer;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ComplianceQuestionRepository;
import hu.puzzleir.valuta.repository.CustomerQuestionAnswerRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ComplianceQuestionServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID QUESTION_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID ANSWER_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final Long CUSTOMER_ID = 42L;
    private static final Long TRANSACTION_ID = 77L;

    @Mock
    private ComplianceQuestionRepository questionRepository;

    @Mock
    private CustomerQuestionAnswerRepository answerRepository;

    @Mock
    private CustomerRepository customerRepository;

    private ComplianceQuestionService service;

    @BeforeEach
    void setUp() {
        service = new ComplianceQuestionService(questionRepository, answerRepository, customerRepository);
    }

    @Test
    @DisplayName("create: sikeres mentés SecurityContext companyId-val, alapértelmezett sorrenddel")
    void create_success() {
        when(questionRepository.save(any(ComplianceQuestion.class))).thenAnswer(invocation -> {
            ComplianceQuestion question = invocation.getArgument(0);
            question.setId(QUESTION_ID);
            return question;
        });

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            ComplianceQuestionDto result = service.create(CreateComplianceQuestionDto.builder()
                    .questionText("  Ismeri az ügyfelet?  ")
                    .questionType(ComplianceQuestionType.YES_NO)
                    .displayOrder(null)
                    .build());

            assertThat(result.getId()).isEqualTo(QUESTION_ID);
        }

        ArgumentCaptor<ComplianceQuestion> captor = ArgumentCaptor.forClass(ComplianceQuestion.class);
        verify(questionRepository).save(captor.capture());
        ComplianceQuestion saved = captor.getValue();
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getActive()).isTrue();
        assertThat(saved.getDisplayOrder()).isZero();
        assertThat(saved.getCreatedByWorkerCode()).isEqualTo("W-001");
        assertThat(saved.getQuestionText()).isEqualTo("Ismeri az ügyfelet?");
    }

    @Test
    @DisplayName("create: üres kérdésszöveg elutasítva, mentés nélkül")
    void create_blankText_rejected() {
        assertThatThrownBy(() -> service.create(CreateComplianceQuestionDto.builder()
                .questionText("   ")
                .questionType(ComplianceQuestionType.FREE_TEXT)
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(questionRepository, never()).save(any());
    }

    @Test
    @DisplayName("update: cég-scope-olt kérdés módosítása")
    void update_success() {
        ComplianceQuestion question = question(ComplianceQuestionType.YES_NO, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(questionRepository.save(any(ComplianceQuestion.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            ComplianceQuestionDto result = service.update(QUESTION_ID, UpdateComplianceQuestionDto.builder()
                    .questionText("  Új kérdés  ")
                    .questionType(ComplianceQuestionType.FREE_TEXT)
                    .displayOrder(12)
                    .build());

            assertThat(result.getQuestionText()).isEqualTo("Új kérdés");
            assertThat(result.getQuestionType()).isEqualTo(ComplianceQuestionType.FREE_TEXT);
            assertThat(result.getDisplayOrder()).isEqualTo(12);
        }

        verify(questionRepository).save(question);
    }

    @Test
    @DisplayName("update: idegen cég / nem létező id azonos 404")
    void update_notFoundInCompany_throws404() {
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.update(QUESTION_ID, UpdateComplianceQuestionDto.builder()
                    .questionText("Új")
                    .build()))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("setActive: soft-disable flag billentése")
    void setActive_togglesFlag() {
        ComplianceQuestion question = question(ComplianceQuestionType.YES_NO, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(questionRepository.save(any(ComplianceQuestion.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            ComplianceQuestionDto result = service.setActive(QUESTION_ID, false);

            assertThat(result.getActive()).isFalse();
        }

        verify(questionRepository).save(question);
        assertThat(question.getActive()).isFalse();
    }

    @Test
    @DisplayName("listActive: az aktuális cég aktív kérdéseire delegál")
    void listActiveForCurrentCompany_delegates() {
        when(questionRepository.findByCompanyIdAndActiveTrueOrderByDisplayOrderAscCreatedAtAsc(COMPANY_ID))
                .thenReturn(List.of(question(ComplianceQuestionType.YES_NO, true)));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThat(service.listActiveForCurrentCompany()).hasSize(1);
        }

        verify(questionRepository).findByCompanyIdAndActiveTrueOrderByDisplayOrderAscCreatedAtAsc(COMPANY_ID);
    }

    @Test
    @DisplayName("submitAnswer: YES_NO válasz normalizált, fail-closed validáció után ment")
    void submitAnswer_success_yesNo() {
        ComplianceQuestion question = question(ComplianceQuestionType.YES_NO, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID)).thenReturn(Optional.empty());
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> {
            CustomerQuestionAnswer answer = invocation.getArgument(0);
            answer.setId(ANSWER_ID);
            return answer;
        });

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            CustomerQuestionAnswerDto result = service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .answerText("yes")
                    .build());

            assertThat(result.getId()).isEqualTo(ANSWER_ID);
        }

        ArgumentCaptor<CustomerQuestionAnswer> captor = ArgumentCaptor.forClass(CustomerQuestionAnswer.class);
        verify(answerRepository).save(captor.capture());
        CustomerQuestionAnswer saved = captor.getValue();
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getQuestionId()).isEqualTo(QUESTION_ID);
        assertThat(saved.getAnswerText()).isEqualTo("YES");
        assertThat(saved.getAnsweredByWorkerCode()).isEqualTo("W-001");
        assertThat(saved.getAnsweredAt()).isNotNull();
    }

    @Test
    @DisplayName("submitAnswer: YES_NO hibás szöveg elutasítva, mentés nélkül")
    void submitAnswer_yesNo_invalidText_rejected() {
        ComplianceQuestion question = question(ComplianceQuestionType.YES_NO, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .answerText("talán")
                    .build()))
                    .isInstanceOf(ValidationException.class);
        }

        verify(answerRepository, never()).save(any());
    }

    @Test
    @DisplayName("submitAnswer: FREE_TEXT válasz trimelve mentődik")
    void submitAnswer_freeText_trimmed() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID)).thenReturn(Optional.empty());
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .answerText("  válasz  ")
                    .build());
        }

        ArgumentCaptor<CustomerQuestionAnswer> captor = ArgumentCaptor.forClass(CustomerQuestionAnswer.class);
        verify(answerRepository).save(captor.capture());
        assertThat(captor.getValue().getAnswerText()).isEqualTo("válasz");
    }

    @Test
    @DisplayName("submitAnswer: ismeretlen ügyfél 404, mentés nélkül")
    void submitAnswer_unknownCustomer_throws404() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(false);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .answerText("válasz")
                    .build()))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(answerRepository, never()).save(any());
    }

    @Test
    @DisplayName("submitAnswer: meglévő transaction-höz kötött válasz felülíródik")
    void submitAnswer_upsert_overwritesExisting() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        CustomerQuestionAnswer existing = answer("régi", TRANSACTION_ID);
        existing.setId(ANSWER_ID);
        LocalDateTime oldAnsweredAt = LocalDateTime.now().minusDays(1);
        existing.setAnsweredAt(oldAnsweredAt);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionId(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID, TRANSACTION_ID)).thenReturn(Optional.of(existing));
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-002");

            CustomerQuestionAnswerDto result = service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .transactionId(TRANSACTION_ID)
                    .answerText("új")
                    .build());

            assertThat(result.getId()).isEqualTo(ANSWER_ID);
        }

        verify(answerRepository).save(existing);
        assertThat(existing.getAnswerText()).isEqualTo("új");
        assertThat(existing.getAnsweredByWorkerCode()).isEqualTo("W-002");
        assertThat(existing.getAnsweredAt()).isAfter(oldAnsweredAt);
    }

    @Test
    @DisplayName("submitAnswer: null transactionId esetén IS NULL query-t használ")
    void submitAnswer_nullTransaction_usesIsNullQuery() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID)).thenReturn(Optional.empty());
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .transactionId(null)
                    .answerText("válasz")
                    .build());
        }

        verify(answerRepository).findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID);
        verify(answerRepository, never()).findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionId(
                any(), any(), any(), any());
    }

    @Test
    @DisplayName("getAnswersForQuestion: ismeretlen kérdés 404, answer repo hívás nélkül")
    void getAnswersForQuestion_unknownQuestion_throws404() {
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.getAnswersForQuestion(QUESTION_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(answerRepository, never()).findByCompanyIdAndQuestionIdOrderByAnsweredAtDesc(any(), any());
    }

    @Test
    @DisplayName("getAnswersForCustomer: companyId-szűrt query-re delegál")
    void getAnswersForCustomer_delegates() {
        when(answerRepository.findByCompanyIdAndCustomerIdOrderByAnsweredAtDesc(COMPANY_ID, CUSTOMER_ID))
                .thenReturn(List.of(answer("válasz", null)));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThat(service.getAnswersForCustomer(CUSTOMER_ID)).hasSize(1);
        }

        verify(answerRepository).findByCompanyIdAndCustomerIdOrderByAnsweredAtDesc(COMPANY_ID, CUSTOMER_ID);
    }

    @Test
    @DisplayName("submitAnswer: insert-race — a flush DIVE-ja változatlanul propagál (a controller-retry kapja el)")
    void submitAnswer_insertRace_propagatesDataIntegrityViolation() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID)).thenReturn(Optional.empty());
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> invocation.getArgument(0));
        DataIntegrityViolationException dive =
                new DataIntegrityViolationException("ux_cqa_company_question_customer_notx");
        doThrow(dive).when(answerRepository).flush();

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .answerText("válasz")
                    .build()))
                    .isSameAs(dive);
        }
    }

    @Test
    @DisplayName("submitAnswer: meglévő sor UPDATE-ága nem flush-ol (ott nincs insert-race)")
    void submitAnswer_existingAnswer_noExplicitFlush() {
        ComplianceQuestion question = question(ComplianceQuestionType.FREE_TEXT, true);
        CustomerQuestionAnswer existing = answer("régi", TRANSACTION_ID);
        when(questionRepository.findByIdAndCompanyId(QUESTION_ID, COMPANY_ID)).thenReturn(Optional.of(question));
        when(customerRepository.existsByIdAndCompanyId(CUSTOMER_ID, COMPANY_ID)).thenReturn(true);
        when(answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionId(
                COMPANY_ID, QUESTION_ID, CUSTOMER_ID, TRANSACTION_ID)).thenReturn(Optional.of(existing));
        when(answerRepository.save(any(CustomerQuestionAnswer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-002");

            service.submitAnswer(QUESTION_ID, CreateQuestionAnswerDto.builder()
                    .customerId(CUSTOMER_ID)
                    .transactionId(TRANSACTION_ID)
                    .answerText("új")
                    .build());
        }

        verify(answerRepository, never()).flush();
    }

    private static ComplianceQuestion question(ComplianceQuestionType type, boolean active) {
        return ComplianceQuestion.builder()
                .id(QUESTION_ID)
                .companyId(COMPANY_ID)
                .questionText("Kérdés")
                .questionType(type)
                .displayOrder(1)
                .active(active)
                .createdByWorkerCode("W-000")
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static CustomerQuestionAnswer answer(String answerText, Long transactionId) {
        return CustomerQuestionAnswer.builder()
                .id(ANSWER_ID)
                .companyId(COMPANY_ID)
                .questionId(QUESTION_ID)
                .customerId(CUSTOMER_ID)
                .transactionId(transactionId)
                .answerText(answerText)
                .answeredByWorkerCode("W-000")
                .answeredAt(LocalDateTime.now())
                .build();
    }
}
