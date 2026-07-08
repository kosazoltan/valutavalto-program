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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * FS-10 S1: compliance-kérdés service — center CRUD, pénztár-sync lista,
 * fail-closed válasz-rögzítés (upsert), compliance-visszaolvasás.
 * MINDEN lekérdezés companyId-szűrt (invariáns #1); a cég a SecurityContextből jön.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ComplianceQuestionService {

    private static final int MAX_QUESTION_LENGTH = 2000;
    private static final int MAX_ANSWER_LENGTH = 4000;

    private final ComplianceQuestionRepository questionRepository;
    private final CustomerQuestionAnswerRepository answerRepository;
    private final CustomerRepository customerRepository;

    @Transactional(rollbackFor = Exception.class)
    public ComplianceQuestionDto create(CreateComplianceQuestionDto dto) {
        String text = normalizeQuestionText(dto.getQuestionText());
        if (dto.getQuestionType() == null) {
            throw new ValidationException("A kérdés típusa kötelező");
        }
        ComplianceQuestion question = ComplianceQuestion.builder()
                .companyId(SecurityUtils.getCurrentCompanyId())
                .questionText(text)
                .questionType(dto.getQuestionType())
                .displayOrder(dto.getDisplayOrder() == null ? 0 : dto.getDisplayOrder())
                .active(true)
                .createdByWorkerCode(SecurityUtils.getCurrentWorkerCode())
                .build();
        question = questionRepository.save(question);
        log.info("Compliance-kérdés létrehozva: id={}, type={}", question.getId(), question.getQuestionType());
        return toDto(question);
    }

    @Transactional(rollbackFor = Exception.class)
    public ComplianceQuestionDto update(UUID id, UpdateComplianceQuestionDto dto) {
        ComplianceQuestion question = requireInCurrentCompany(id);
        if (dto.getQuestionText() != null) {
            question.setQuestionText(normalizeQuestionText(dto.getQuestionText()));
        }
        if (dto.getQuestionType() != null) {
            question.setQuestionType(dto.getQuestionType());
        }
        if (dto.getDisplayOrder() != null) {
            question.setDisplayOrder(dto.getDisplayOrder());
        }
        return toDto(questionRepository.save(question));
    }

    @Transactional(rollbackFor = Exception.class)
    public ComplianceQuestionDto setActive(UUID id, boolean active) {
        ComplianceQuestion question = requireInCurrentCompany(id);
        question.setActive(active);
        return toDto(questionRepository.save(question));
    }

    @Transactional(readOnly = true)
    public List<ComplianceQuestionDto> listForCurrentCompany() {
        return questionRepository
                .findByCompanyIdOrderByDisplayOrderAscCreatedAtAsc(SecurityUtils.getCurrentCompanyId())
                .stream().map(this::toDto).toList();
    }

    /** Pénztár-sync: az aktuális cég aktív kérdései, megjelenítési sorrendben. */
    @Transactional(readOnly = true)
    public List<ComplianceQuestionDto> listActiveForCurrentCompany() {
        return questionRepository
                .findByCompanyIdAndActiveTrueOrderByDisplayOrderAscCreatedAtAsc(SecurityUtils.getCurrentCompanyId())
                .stream().map(this::toDto).toList();
    }

    /**
     * Pénztári válasz-rögzítés — fail-closed: csak létező, AZONOS cégbeli és aktív
     * kérdésre, létező cégbeli ügyfélre; minden validáció a mentés ELŐTT.
     * Upsert a (company, question, customer, transaction) kulcson (D3 döntés).
     */
    @Transactional(rollbackFor = Exception.class)
    public CustomerQuestionAnswerDto submitAnswer(UUID questionId, CreateQuestionAnswerDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        ComplianceQuestion question = questionRepository.findByIdAndCompanyId(questionId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Compliance-kérdés nem található: " + questionId));
        if (!Boolean.TRUE.equals(question.getActive())) {
            throw new ValidationException("A kérdés inaktív, válasz nem rögzíthető");
        }
        if (dto.getCustomerId() == null) {
            throw new ValidationException("Ügyfél megadása kötelező");
        }
        if (!customerRepository.existsByIdAndCompanyId(dto.getCustomerId(), companyId)) {
            throw new ResourceNotFoundException("Ügyfél nem található: " + dto.getCustomerId());
        }
        String answerText = validateAnswerText(question.getQuestionType(), dto.getAnswerText());

        CustomerQuestionAnswer answer = (dto.getTransactionId() == null
                ? answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionIdIsNull(
                        companyId, questionId, dto.getCustomerId())
                : answerRepository.findByCompanyIdAndQuestionIdAndCustomerIdAndTransactionId(
                        companyId, questionId, dto.getCustomerId(), dto.getTransactionId()))
                .orElseGet(() -> CustomerQuestionAnswer.builder()
                        .companyId(companyId)
                        .questionId(questionId)
                        .customerId(dto.getCustomerId())
                        .transactionId(dto.getTransactionId())
                        .build());
        answer.setAnswerText(answerText);
        answer.setAnsweredByWorkerCode(SecurityUtils.getCurrentWorkerCode());
        answer.setAnsweredAt(LocalDateTime.now());
        answer = answerRepository.save(answer);
        log.info("Compliance-válasz rögzítve: questionId={}, answerId={}", questionId, answer.getId());
        return toDto(answer);
    }

    @Transactional(readOnly = true)
    public List<CustomerQuestionAnswerDto> getAnswersForQuestion(UUID questionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        questionRepository.findByIdAndCompanyId(questionId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Compliance-kérdés nem található: " + questionId));
        return answerRepository.findByCompanyIdAndQuestionIdOrderByAnsweredAtDesc(companyId, questionId)
                .stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public List<CustomerQuestionAnswerDto> getAnswersForCustomer(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return answerRepository.findByCompanyIdAndCustomerIdOrderByAnsweredAtDesc(companyId, customerId)
                .stream().map(this::toDto).toList();
    }

    /** Cég-scope-olt betöltés — cross-tenant/nem létező id-ra AZONOS 404 (nincs enumeráció). */
    private ComplianceQuestion requireInCurrentCompany(UUID id) {
        return questionRepository.findByIdAndCompanyId(id, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Compliance-kérdés nem található: " + id));
    }

    private static String normalizeQuestionText(String raw) {
        String text = raw == null ? "" : raw.trim();
        if (text.isEmpty()) {
            throw new ValidationException("A kérdés szövege nem lehet üres");
        }
        if (text.length() > MAX_QUESTION_LENGTH) {
            throw new ValidationException("A kérdés legfeljebb " + MAX_QUESTION_LENGTH + " karakter lehet");
        }
        return text;
    }

    /** YES_NO: csak YES/NO (case-insensitive), normalizálva tárolva; FREE_TEXT: trim + hossz-limit. */
    private static String validateAnswerText(ComplianceQuestionType type, String raw) {
        String text = raw == null ? "" : raw.trim();
        if (text.isEmpty()) {
            throw new ValidationException("A válasz szövege nem lehet üres");
        }
        if (text.length() > MAX_ANSWER_LENGTH) {
            throw new ValidationException("A válasz legfeljebb " + MAX_ANSWER_LENGTH + " karakter lehet");
        }
        if (type == ComplianceQuestionType.YES_NO) {
            String normalized = text.toUpperCase(Locale.ROOT);
            if (!"YES".equals(normalized) && !"NO".equals(normalized)) {
                throw new ValidationException("YES_NO kérdésre csak YES vagy NO válasz adható");
            }
            return normalized;
        }
        return text;
    }

    private ComplianceQuestionDto toDto(ComplianceQuestion q) {
        return ComplianceQuestionDto.builder()
                .id(q.getId())
                .questionText(q.getQuestionText())
                .questionType(q.getQuestionType())
                .displayOrder(q.getDisplayOrder())
                .active(q.getActive())
                .createdByWorkerCode(q.getCreatedByWorkerCode())
                .createdAt(q.getCreatedAt())
                .updatedAt(q.getUpdatedAt())
                .build();
    }

    private CustomerQuestionAnswerDto toDto(CustomerQuestionAnswer a) {
        return CustomerQuestionAnswerDto.builder()
                .id(a.getId())
                .questionId(a.getQuestionId())
                .customerId(a.getCustomerId())
                .transactionId(a.getTransactionId())
                .answerText(a.getAnswerText())
                .answeredByWorkerCode(a.getAnsweredByWorkerCode())
                .answeredAt(a.getAnsweredAt())
                .build();
    }
}
