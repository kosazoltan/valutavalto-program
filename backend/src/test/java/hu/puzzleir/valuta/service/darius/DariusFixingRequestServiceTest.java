package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusBankBranchCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestCreateDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestDto;
import hu.puzzleir.valuta.dto.darius.DariusFixingRequestLineDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DariusBankBranch;
import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestLine;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DariusBankBranchRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestLineRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class DariusFixingRequestServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BANK_BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final UUID REQUEST_ID = UUID.fromString("30000000-0000-0000-0000-000000000003");
    private static final LocalDate REQUEST_DATE = LocalDate.of(2026, 7, 14);
    private static final String WORKER_CODE = "FOERT01";

    private final DariusBankBranchRepository bankBranchRepository = mock(DariusBankBranchRepository.class);
    private final DariusFixingRequestRepository requestRepository = mock(DariusFixingRequestRepository.class);
    private final DariusFixingRequestLineRepository lineRepository = mock(DariusFixingRequestLineRepository.class);
    private final CurrencyRepository currencyRepository = mock(CurrencyRepository.class);
    private final AuditLogService auditLogService = mock(AuditLogService.class);

    private DariusFixingRequestService service;
    private DariusBankBranch bankBranch;

    @BeforeEach
    void setUp() {
        reset(bankBranchRepository, requestRepository, lineRepository, currencyRepository, auditLogService);
        service = new DariusFixingRequestService(
                bankBranchRepository,
                requestRepository,
                lineRepository,
                currencyRepository,
                auditLogService);
        bankBranch = DariusBankBranch.builder()
                .id(BANK_BRANCH_ID)
                .companyId(COMPANY_ID)
                .bankBranchCode("RB-BP-01")
                .name("Raiffeisen Budapest")
                .isActive(true)
                .build();
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch));
        when(currencyRepository.findByCodeAndActiveTrue("EUR"))
                .thenReturn(Optional.of(Currency.builder().code("EUR").active(true).build()));
        when(currencyRepository.findByCodeAndActiveTrue("USD"))
                .thenReturn(Optional.of(Currency.builder().code("USD").active(true).build()));
        when(requestRepository.saveAndFlush(any(DariusFixingRequest.class))).thenAnswer(invocation -> {
            DariusFixingRequest request = invocation.getArgument(0);
            request.setId(REQUEST_ID);
            return request;
        });
        when(lineRepository.saveAllAndFlush(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void createsDraftWithValidLinesAndAudits() {
        DariusFixingRequestDto result = secured(() -> service.create(validCreateDto()));

        assertThat(result.status()).isEqualTo(DariusFixingRequestStatus.DRAFT.name());
        assertThat(result.bankBranchId()).isEqualTo(BANK_BRANCH_ID);
        ArgumentCaptor<DariusFixingRequest> requestCaptor = ArgumentCaptor.forClass(DariusFixingRequest.class);
        verify(requestRepository).saveAndFlush(requestCaptor.capture());
        assertThat(requestCaptor.getValue().getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(requestCaptor.getValue().getCreatedBy()).isEqualTo(WORKER_CODE);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Iterable<DariusFixingRequestLine>> linesCaptor = ArgumentCaptor.forClass(Iterable.class);
        verify(lineRepository).saveAllAndFlush(linesCaptor.capture());
        assertThat(linesCaptor.getValue())
                .allSatisfy(line -> {
                    assertThat(line.getCompanyId()).isEqualTo(COMPANY_ID);
                    assertThat(line.getRequestId()).isEqualTo(REQUEST_ID);
                });
        verify(auditLogService).logForCompany(
                eq("DARIUS_FIXING_REQUEST_CREATED"), any(String.class), eq(REQUEST_ID.toString()), eq(COMPANY_ID));
    }

    @Test
    void rejectsCreateWhenBankBranchMissingInactiveOrForeignWithoutLineInteraction() {
        UUID foreignId = UUID.randomUUID();
        when(bankBranchRepository.findByIdAndCompanyId(foreignId, COMPANY_ID)).thenReturn(Optional.empty());
        DariusFixingRequestCreateDto foreign = new DariusFixingRequestCreateDto(
                foreignId, REQUEST_DATE, null, validLines());

        assertThatThrownBy(() -> secured(() -> service.create(foreign)))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(lineRepository);
        verify(requestRepository, never()).saveAndFlush(any());
        verifyNoInteractions(auditLogService);

        bankBranch.setIsActive(false);
        assertThatThrownBy(() -> secured(() -> service.create(validCreateDto())))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("inaktív");
        verify(requestRepository, never()).saveAndFlush(any());
    }

    @Test
    void rejectsCreateOnEmptyAndAggregatedInvalidLines() {
        DariusFixingRequestCreateDto empty = new DariusFixingRequestCreateDto(
                BANK_BRANCH_ID, REQUEST_DATE, null, List.of());
        assertThatThrownBy(() -> secured(() -> service.create(empty)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("legalább egy");

        List<DariusFixingRequestLineDto> invalidLines = List.of(
                new DariusFixingRequestLineDto("EUR", new BigDecimal("-1"), new BigDecimal("0")),
                new DariusFixingRequestLineDto("EUR", new BigDecimal("100.50"), BigDecimal.ZERO),
                new DariusFixingRequestLineDto("ZZZ", BigDecimal.ZERO, BigDecimal.ZERO),
                new DariusFixingRequestLineDto("bad", null, new BigDecimal("1.25")));
        DariusFixingRequestCreateDto invalid = new DariusFixingRequestCreateDto(
                BANK_BRANCH_ID, REQUEST_DATE, null, invalidLines);

        assertThatThrownBy(() -> secured(() -> service.create(invalid)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("duplikált valutakód")
                .hasMessageContaining("nem lehet negatív")
                .hasMessageContaining("csak egész")
                .hasMessageContaining("legalább az egyik összeg pozitív")
                .hasMessageContaining("nem aktív vagy nem létezik")
                .hasMessageContaining("[A-Z]{3}")
                .hasMessageContaining("hiányzik");
        verify(requestRepository, never()).saveAndFlush(any());
        verify(lineRepository, never()).saveAllAndFlush(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    void acceptsSixteenIntegerDigitsButRejectsSeventeenBeforePersistence() {
        DariusFixingRequestCreateDto boundary = new DariusFixingRequestCreateDto(
                BANK_BRANCH_ID,
                REQUEST_DATE,
                null,
                List.of(new DariusFixingRequestLineDto(
                        "EUR", new BigDecimal("9999999999999999"), BigDecimal.ZERO)));

        DariusFixingRequestDto result = secured(() -> service.create(boundary));

        assertThat(result.lines()).singleElement()
                .extracting(DariusFixingRequestLineDto::deliveredAmount)
                .isEqualTo(new BigDecimal("9999999999999999"));

        reset(requestRepository, lineRepository, auditLogService);
        DariusFixingRequestCreateDto overflow = new DariusFixingRequestCreateDto(
                BANK_BRANCH_ID,
                REQUEST_DATE,
                null,
                List.of(new DariusFixingRequestLineDto(
                        "EUR", new BigDecimal("10000000000000000"), BigDecimal.ZERO)));

        assertThatThrownBy(() -> secured(() -> service.create(overflow)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("legfeljebb 16 számjegyű");
        verify(requestRepository, never()).saveAndFlush(any());
        verify(lineRepository, never()).saveAllAndFlush(any());
    }

    @Test
    void aggregatesIndependentBranchDuplicateAndLineValidationFailures() {
        bankBranch.setIsActive(false);
        bankBranch.setBankBranchCode(" ");
        when(requestRepository.existsByCompanyIdAndRequestDateAndBankBranchIdAndStatusNot(
                COMPANY_ID, REQUEST_DATE, BANK_BRANCH_ID, DariusFixingRequestStatus.CANCELLED))
                .thenReturn(true);
        DariusFixingRequestCreateDto invalid = new DariusFixingRequestCreateDto(
                BANK_BRANCH_ID,
                REQUEST_DATE,
                null,
                List.of(new DariusFixingRequestLineDto("bad", new BigDecimal("-1"), BigDecimal.ZERO)));

        assertThatThrownBy(() -> secured(() -> service.create(invalid)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("inaktív")
                .hasMessageContaining("BANKFIOK_AZONOSITO")
                .hasMessageContaining("már létezik")
                .hasMessageContaining("[A-Z]{3}")
                .hasMessageContaining("nem lehet negatív")
                .hasMessageContaining("legalább az egyik összeg pozitív");
        verify(requestRepository, never()).saveAndFlush(any());
        verify(lineRepository, never()).saveAllAndFlush(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    void rejectsSecondLiveRequestForSameDayAndBranch() {
        when(requestRepository.existsByCompanyIdAndRequestDateAndBankBranchIdAndStatusNot(
                COMPANY_ID, REQUEST_DATE, BANK_BRANCH_ID, DariusFixingRequestStatus.CANCELLED))
                .thenReturn(true);

        assertThatThrownBy(() -> secured(() -> service.create(validCreateDto())))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már létezik");
        verify(requestRepository, never()).saveAndFlush(any());
        verifyNoInteractions(lineRepository);
    }

    @Test
    void approvesOnlyDraftAndAudits() {
        DariusFixingRequest draft = request(DariusFixingRequestStatus.DRAFT);
        stubRequestMapping(draft);

        DariusFixingRequestDto result = secured(() -> service.approve(REQUEST_ID));

        assertThat(result.status()).isEqualTo(DariusFixingRequestStatus.APPROVED.name());
        assertThat(draft.getApprovedBy()).isEqualTo(WORKER_CODE);
        assertThat(draft.getApprovedAt()).isNotNull();
        verify(auditLogService).logForCompany(
                eq("DARIUS_FIXING_REQUEST_APPROVED"), any(String.class), eq(REQUEST_ID.toString()), eq(COMPANY_ID));

        reset(auditLogService);
        draft.setStatus(DariusFixingRequestStatus.APPROVED);
        assertThatThrownBy(() -> secured(() -> service.approve(REQUEST_ID)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("DRAFT");
        verifyNoInteractions(auditLogService);
    }

    @Test
    void cancelsDraftAndApprovedButNeverIncluded() {
        DariusFixingRequest approved = request(DariusFixingRequestStatus.APPROVED);
        stubRequestMapping(approved);

        DariusFixingRequestDto result = secured(() -> service.cancel(REQUEST_ID));

        assertThat(result.status()).isEqualTo(DariusFixingRequestStatus.CANCELLED.name());
        assertThat(approved.getCancelledBy()).isEqualTo(WORKER_CODE);
        assertThat(approved.getCancelledAt()).isNotNull();
        verify(auditLogService).logForCompany(
                eq("DARIUS_FIXING_REQUEST_CANCELLED"), any(String.class), eq(REQUEST_ID.toString()), eq(COMPANY_ID));

        reset(auditLogService);
        approved.setStatus(DariusFixingRequestStatus.INCLUDED);
        assertThatThrownBy(() -> secured(() -> service.cancel(REQUEST_ID)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("INCLUDED");
        verifyNoInteractions(auditLogService);
    }

    @Test
    void updatesLinesOnlyWhileDraftWithTenantScopedDeleteAndStamp() {
        DariusFixingRequest draft = request(DariusFixingRequestStatus.DRAFT);
        when(requestRepository.findForUpdateByIdAndCompanyId(REQUEST_ID, COMPANY_ID)).thenReturn(Optional.of(draft));
        when(lineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(COMPANY_ID, REQUEST_ID))
                .thenReturn(List.of());

        DariusFixingRequestDto result = secured(() -> service.updateLines(REQUEST_ID, validCreateDto()));

        assertThat(result.lines()).hasSize(2);
        verify(lineRepository).deleteByCompanyIdAndRequestId(COMPANY_ID, REQUEST_ID);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<Iterable<DariusFixingRequestLine>> captor = ArgumentCaptor.forClass(Iterable.class);
        verify(lineRepository).saveAllAndFlush(captor.capture());
        assertThat(captor.getValue()).allSatisfy(line -> assertThat(line.getCompanyId()).isEqualTo(COMPANY_ID));
        verify(auditLogService).logForCompany(
                eq("DARIUS_FIXING_REQUEST_UPDATED"), any(String.class), eq(REQUEST_ID.toString()), eq(COMPANY_ID));

        draft.setStatus(DariusFixingRequestStatus.APPROVED);
        assertThatThrownBy(() -> secured(() -> service.updateLines(REQUEST_ID, validCreateDto())))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("DRAFT");
    }

    @Test
    void crossTenantLineAccessLeaksNothingForEveryRequestMutation() {
        when(requestRepository.findForUpdateByIdAndCompanyId(REQUEST_ID, COMPANY_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> secured(() -> service.updateLines(REQUEST_ID, validCreateDto())))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> secured(() -> service.approve(REQUEST_ID)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> secured(() -> service.cancel(REQUEST_ID)))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(requestRepository, times(3)).findForUpdateByIdAndCompanyId(REQUEST_ID, COMPANY_ID);
        verifyNoInteractions(lineRepository);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void bankBranchCreateValidatesConstraintsAndAudits() {
        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto(" RB 01", "Fiók"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("whitespace");
        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("RB\t01", "Fiók"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("whitespace");
        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("X".repeat(51), "Fiók"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("50");
        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("RB01", "X".repeat(201)))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("200");

        when(bankBranchRepository.existsByCompanyIdAndBankBranchCode(COMPANY_ID, "RB01"))
                .thenReturn(true);
        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("RB01", "Fiók"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már létezik");

        when(bankBranchRepository.existsByCompanyIdAndBankBranchCode(COMPANY_ID, "RB02"))
                .thenReturn(false);
        when(bankBranchRepository.saveAndFlush(any(DariusBankBranch.class))).thenAnswer(invocation -> {
            DariusBankBranch branch = invocation.getArgument(0);
            branch.setId(BANK_BRANCH_ID);
            return branch;
        });
        var created = secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("RB02", "Központi fiók")));
        assertThat(created.bankBranchCode()).isEqualTo("RB02");
        verify(auditLogService).logForCompany(
                eq("DARIUS_BANK_BRANCH_CREATED"), any(String.class), eq(BANK_BRANCH_ID.toString()), eq(COMPANY_ID));
    }

    @Test
    void mapsDatabaseUniquenessFailureToValidationInsteadOfServerError() {
        when(bankBranchRepository.saveAndFlush(any(DariusBankBranch.class)))
                .thenThrow(new DataIntegrityViolationException("ux_dbb_company_code"));

        assertThatThrownBy(() -> secured(() -> service.createBankBranch(
                new DariusBankBranchCreateDto("RB03", "Fiók"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már létezik");
        verifyNoInteractions(auditLogService);
    }

    @Test
    void listRequestsBatchLoadsBranchesAndLinesWithBoundedTenantScopedCalls() {
        DariusFixingRequest draft = request(DariusFixingRequestStatus.DRAFT);
        UUID secondRequestId = UUID.fromString("30000000-0000-0000-0000-000000000004");
        DariusFixingRequest approved = DariusFixingRequest.builder()
                .id(secondRequestId)
                .companyId(COMPANY_ID)
                .bankBranchId(BANK_BRANCH_ID)
                .requestDate(REQUEST_DATE)
                .status(DariusFixingRequestStatus.APPROVED)
                .createdBy(WORKER_CODE)
                .build();
        when(requestRepository.findByCompanyIdAndRequestDateOrderByCreatedAtAsc(COMPANY_ID, REQUEST_DATE))
                .thenReturn(List.of(draft, approved));
        when(bankBranchRepository.findByCompanyIdAndIdIn(COMPANY_ID, Set.of(BANK_BRANCH_ID)))
                .thenReturn(List.of(bankBranch));
        List<DariusFixingRequestLine> lines = new ArrayList<>(linesForRequest());
        lines.add(DariusFixingRequestLine.builder()
                .companyId(COMPANY_ID)
                .requestId(secondRequestId)
                .currencyCode("GBP")
                .deliveredAmount(BigDecimal.ONE)
                .collectedAmount(BigDecimal.ZERO)
                .build());
        when(lineRepository.findByCompanyIdAndRequestIdInOrderByRequestIdAscCurrencyCodeAsc(
                COMPANY_ID, Set.of(REQUEST_ID, secondRequestId)))
                .thenReturn(lines);

        List<DariusFixingRequestDto> result = secured(() -> service.listRequests(REQUEST_DATE));

        assertThat(result).hasSize(2);
        assertThat(result.get(0).lines()).hasSize(2);
        assertThat(result.get(1).lines()).singleElement()
                .extracting(DariusFixingRequestLineDto::currencyCode)
                .isEqualTo("GBP");
        verify(bankBranchRepository).findByCompanyIdAndIdIn(COMPANY_ID, Set.of(BANK_BRANCH_ID));
        verify(lineRepository).findByCompanyIdAndRequestIdInOrderByRequestIdAscCurrencyCodeAsc(
                COMPANY_ID, Set.of(REQUEST_ID, secondRequestId));
        verify(bankBranchRepository, never()).findByIdAndCompanyId(any(), any());
        verify(lineRepository, never()).findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(any(), any());
    }

    @Test
    void bankBranchListAndDeactivateRemainTenantScopedAndAudited() {
        when(bankBranchRepository.findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(COMPANY_ID))
                .thenReturn(List.of(bankBranch));
        when(bankBranchRepository.save(bankBranch)).thenReturn(bankBranch);

        assertThat(secured(() -> service.listBankBranches(false)))
                .singleElement()
                .extracting("bankBranchCode")
                .isEqualTo("RB-BP-01");
        var deactivated = secured(() -> service.deactivateBankBranch(BANK_BRANCH_ID));

        assertThat(deactivated.active()).isFalse();
        verify(bankBranchRepository).findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(COMPANY_ID);
        verify(bankBranchRepository).findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID);
        verify(auditLogService).logForCompany(
                eq("DARIUS_BANK_BRANCH_DEACTIVATED"),
                any(String.class),
                eq(BANK_BRANCH_ID.toString()),
                eq(COMPANY_ID));
    }

    @Test
    void includedIsTerminalForApproveUpdateAndCancel() {
        DariusFixingRequest included = request(DariusFixingRequestStatus.INCLUDED);
        when(requestRepository.findForUpdateByIdAndCompanyId(REQUEST_ID, COMPANY_ID)).thenReturn(Optional.of(included));

        assertThatThrownBy(() -> secured(() -> service.approve(REQUEST_ID)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("DRAFT");
        assertThatThrownBy(() -> secured(() -> service.updateLines(REQUEST_ID, validCreateDto())))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("DRAFT");
        assertThatThrownBy(() -> secured(() -> service.cancel(REQUEST_ID)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("INCLUDED");

        verifyNoInteractions(lineRepository);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void overlongAuthenticatedWorkerCodeIsSystemStateFailure() {
        assertThatThrownBy(() -> secured("W".repeat(101), () -> service.create(validCreateDto())))
                .isInstanceOf(IllegalStateException.class)
                .isNotInstanceOf(ValidationException.class)
                .hasMessageContaining("worker-kód");
        verify(requestRepository, never()).saveAndFlush(any());
    }

    @Test
    void rejectsBlankWorkerCodeFailClosed() {
        assertThatThrownBy(() -> secured("   ", () -> service.approve(REQUEST_ID)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("worker-kód");

        verify(requestRepository, never()).save(any());
    }

    @Test
    void rejectsNullWorkerCodeFailClosed() {
        assertThatThrownBy(() -> secured(null, () -> service.approve(REQUEST_ID)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("worker-kód");

        verify(requestRepository, never()).save(any());
    }

    private DariusFixingRequestCreateDto validCreateDto() {
        return new DariusFixingRequestCreateDto(BANK_BRANCH_ID, REQUEST_DATE, "Heti igény", validLines());
    }

    private List<DariusFixingRequestLineDto> validLines() {
        return List.of(
                new DariusFixingRequestLineDto("EUR", new BigDecimal("100"), BigDecimal.ZERO),
                new DariusFixingRequestLineDto("USD", BigDecimal.ZERO, new BigDecimal("50")));
    }

    private DariusFixingRequest request(DariusFixingRequestStatus status) {
        return DariusFixingRequest.builder()
                .id(REQUEST_ID)
                .companyId(COMPANY_ID)
                .bankBranchId(BANK_BRANCH_ID)
                .requestDate(REQUEST_DATE)
                .status(status)
                .note("Heti igény")
                .createdBy(WORKER_CODE)
                .build();
    }

    private List<DariusFixingRequestLine> linesForRequest() {
        return List.of(
                DariusFixingRequestLine.builder()
                        .companyId(COMPANY_ID)
                        .requestId(REQUEST_ID)
                        .currencyCode("EUR")
                        .deliveredAmount(new BigDecimal("100"))
                        .collectedAmount(BigDecimal.ZERO)
                        .build(),
                DariusFixingRequestLine.builder()
                        .companyId(COMPANY_ID)
                        .requestId(REQUEST_ID)
                        .currencyCode("USD")
                        .deliveredAmount(BigDecimal.ZERO)
                        .collectedAmount(new BigDecimal("50"))
                        .build());
    }

    private void stubRequestMapping(DariusFixingRequest request) {
        when(requestRepository.findForUpdateByIdAndCompanyId(REQUEST_ID, COMPANY_ID)).thenReturn(Optional.of(request));
        when(requestRepository.save(any(DariusFixingRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(lineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(COMPANY_ID, REQUEST_ID))
                .thenReturn(linesForRequest());
    }

    private <T> T secured(Supplier<T> action) {
        return secured(WORKER_CODE, action);
    }

    private <T> T secured(String workerCode, Supplier<T> action) {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn(workerCode);
            return action.get();
        }
    }
}
