package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.dto.darius.DariusImportReadinessDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.DariusBankBranch;
import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestLine;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.DariusBankBranchRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestLineRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestRepository;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.MockedStatic;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

class DariusImportFileServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final UUID FIXING_REQUEST_ID = UUID.fromString("30000000-0000-0000-0000-000000000003");
    private static final UUID BANK_BRANCH_ID = UUID.fromString("40000000-0000-0000-0000-000000000004");
    private static final LocalDate DATE = LocalDate.of(2025, 4, 22);
    private static final Clock CLOCK = Clock.fixed(
            Instant.parse("2025-04-22T12:00:00Z"), DariusImportPreflightValidator.BUSINESS_ZONE);

    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final DailyDenominationSnapshotRepository snapshotRepository =
            mock(DailyDenominationSnapshotRepository.class);
    private final TransactionRepository transactionRepository = mock(TransactionRepository.class);
    private final CompanyRepository companyRepository = mock(CompanyRepository.class);
    private final ShiftedCalendarDayRepository shiftedCalendarDayRepository =
            mock(ShiftedCalendarDayRepository.class);
    private final DariusFixingRequestRepository fixingRequestRepository =
            mock(DariusFixingRequestRepository.class);
    private final DariusFixingRequestLineRepository fixingLineRepository =
            mock(DariusFixingRequestLineRepository.class);
    private final DariusBankBranchRepository bankBranchRepository = mock(DariusBankBranchRepository.class);
    private final AuditLogService auditLogService = mock(AuditLogService.class);
    private final IntegrationTransportProperties properties = new IntegrationTransportProperties();

    private DariusImportFileService service;
    private Branch branch;

    @BeforeEach
    void setUp() {
        properties.getDarius().setPvCodes(Map.of("BEST", "108114"));
        branch = Branch.builder()
                .id(BRANCH_ID)
                .name("Teszt iroda")
                .bankCode("276")
                .hasPos(true)
                .isActive(true)
                .build();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(Company.builder()
                .id(COMPANY_ID)
                .code("BEST")
                .build()));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(branch));
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), eq(List.of(
                        DariusFixingRequestStatus.DRAFT,
                        DariusFixingRequestStatus.APPROVED,
                        DariusFixingRequestStatus.INCLUDED))))
                .thenReturn(List.of());
        service = newService(new DariusImportFileSerializer(), auditLogService);
    }

    private DariusImportFileService newService(
            DariusImportFileSerializer fileSerializer,
            AuditLogService fileAuditLogService) {
        return new DariusImportFileService(
                branchRepository,
                snapshotRepository,
                transactionRepository,
                companyRepository,
                new DariusImportPreflightValidator(shiftedCalendarDayRepository, CLOCK),
                fileSerializer,
                fileAuditLogService,
                properties,
                fixingRequestRepository,
                fixingLineRepository,
                bankBranchRepository,
                CLOCK);
    }

    @Test
    void generatesFileInWritableTransactionWithCardSellMirrorAndAudit() throws NoSuchMethodException {
        Transactional transaction = DariusImportFileService.class
                .getMethod("generateImportFile", LocalDate.class, int.class)
                .getAnnotation(Transactional.class);
        assertThat(transaction).isNotNull();
        assertThat(transaction.readOnly()).isFalse();

        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(row("EUR", "SELL", PaymentMethod.CARD, "50", "20000", "100")));

        DariusImportFile result = generate();
        String content = new String(result.content(), StandardCharsets.UTF_8);

        assertThat(result.fileName()).isEqualTo("raiffeisen_import_BEST_2025-04-22.imp");
        assertThat(content).contains("JELENTES PENZTARALLOMANY\r\n");
        assertThat(content).contains("JELENTES UGYFELFORGALOM V3\r\n");
        assertThat(content).contains("EUR\t0\t0\t50\t0\t0\t0\t0\r\n");
        assertThat(content).contains("HUF\t0\t0\t0\t20000\t100\t0\t0\r\n");
        assertThat(content).doesNotContain("JELENTES UZLETKOTES");
        verify(auditLogService).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"),
                contains("raiffeisen_import_BEST_2025-04-22.imp"),
                eq("raiffeisen_import_BEST_2025-04-22.imp"),
                eq(COMPANY_ID));
    }

    @Test
    void mapsCardBuyToFxBoughtAndHufSold() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(row("EUR", "BUY", PaymentMethod.CARD, "25.50", "10000", "40")));

        String content = content(generate());

        assertThat(content).contains("EUR\t0\t0\t0\t25.5\t0\t0\t0\r\n");
        assertThat(content).contains("HUF\t0\t0\t10000\t0\t0\t40\t0\r\n");
    }

    @Test
    void treatsNullPaymentMethodAsCash() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(row("EUR", "BUY", null, "100", "39000", "10")));

        String content = content(generate());

        assertThat(content).contains("EUR\t0\t100\t0\t0\t0\t0\t0\r\n");
        assertThat(content).contains("HUF\t0\t0\t0\t0\t0\t0\t10\r\n");
    }

    @Test
    void rejectsTurnoverWithoutSnapshotAndDoesNotAudit() {
        when(snapshotRepository.findByBranchIdAndSnapshotDateAndClosingType(BRANCH_ID, DATE, 1))
                .thenReturn(List.of());
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(row("EUR", "BUY", PaymentMethod.CASH, "100", "39000", "0")));

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("[276]")
                .hasMessageContaining("nincs címlet-snapshot");
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void rejectsMissingPvCodeAndDoesNotAudit() {
        properties.getDarius().setPvCodes(Map.of());
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("[GLOBAL]")
                .hasMessageContaining("PV_AZONOSITO");
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void emitsOnlyStockBlockWhenThereIsNoTurnover() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        String content = content(generate());

        assertThat(content).contains("JELENTES PENZTARALLOMANY");
        assertThat(content).doesNotContain("JELENTES UGYFELFORGALOM V3");
    }

    @Test
    void rejectsWhenActiveBranchHasNoSnapshotEvenWithoutTurnover() {
        when(snapshotRepository.findByBranchIdAndSnapshotDateAndClosingType(BRANCH_ID, DATE, 1))
                .thenReturn(List.of());
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("[276]")
                .hasMessageContaining("nincs címlet-snapshot");
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void rejectsWholeExportWhenAnyActiveBranchIsIncompleteAndListsEveryError() {
        Branch second = Branch.builder()
                .id(UUID.fromString("30000000-0000-0000-0000-000000000003"))
                .bankCode("312")
                .hasPos(false)
                .isActive(true)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(branch, second));
        givenSnapshot();
        when(snapshotRepository.findByBranchIdAndSnapshotDateAndClosingType(second.getId(), DATE, 1))
                .thenReturn(List.of());
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(second.getId(), DATE, DATE))
                .thenReturn(List.of());

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("[312]")
                .hasMessageContaining("nincs címlet-snapshot");
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void loadsOnlyCurrentCompanyActiveBranches() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        generate();

        verify(branchRepository).findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID);
        verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(COMPANY_ID);
        verify(branchRepository, never()).findByIsActiveTrue();
    }

    @Test
    void reportsReadinessWithoutGeneratingFileOrWritingSuccessAudit() {
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(branch));

        DariusImportReadinessDto readiness;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            readiness = service.importReadiness();
        }

        assertThat(readiness.companyCode()).isEqualTo("BEST");
        assertThat(readiness.pvCodeConfigured()).isTrue();
        assertThat(readiness.activeBranchCount()).isEqualTo(1);
        assertThat(readiness.branchesWithInvalidBankCode()).isEmpty();
        assertThat(readiness.activeBankBranchCount()).isZero();
        assertThat(readiness.fixingConfigured()).isFalse();
        assertThat(readiness.ready()).isTrue();
        verify(branchRepository).findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID);
        verify(bankBranchRepository)
                .findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(COMPANY_ID);
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void readinessFailsClosedForMissingPvCodeAndInvalidBankCodes() {
        properties.getDarius().setPvCodes(Map.of());
        Branch missingBankCode = Branch.builder()
                .id(UUID.fromString("30000000-0000-0000-0000-000000000003"))
                .name("Hiányzó bankkód")
                .bankCode(null)
                .isActive(true)
                .build();
        Branch nonNumericBankCode = Branch.builder()
                .id(UUID.fromString("40000000-0000-0000-0000-000000000004"))
                .name("Nem numerikus bankkód")
                .bankCode("INVALID")
                .isActive(true)
                .build();
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(List.of(missingBankCode, nonNumericBankCode));

        DariusImportReadinessDto readiness;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            readiness = service.importReadiness();
        }

        assertThat(readiness.companyCode()).isEqualTo("BEST");
        assertThat(readiness.pvCodeConfigured()).isFalse();
        assertThat(readiness.activeBranchCount()).isEqualTo(2);
        assertThat(readiness.branchesWithInvalidBankCode())
                .containsExactly("Hiányzó bankkód (null)", "Nem numerikus bankkód (INVALID)");
        assertThat(readiness.activeBankBranchCount()).isZero();
        assertThat(readiness.fixingConfigured()).isFalse();
        assertThat(readiness.ready()).isFalse();
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void includesApprovedFixingRequestAndMarksItIncluded() {
        givenSnapshot();
        DariusFixingRequest request = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.APPROVED);
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(request));
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch(BANK_BRANCH_ID, "7001", true)));
        when(fixingLineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(
                COMPANY_ID, FIXING_REQUEST_ID)).thenReturn(List.of(
                        fixingLine(FIXING_REQUEST_ID, "USD", "0", "20000"),
                        fixingLine(FIXING_REQUEST_ID, "EUR", "50000", "0")));

        DariusImportFile result = generate();
        String content = content(result);
        String hash = sha256(result.content());

        assertThat(content).contains("JELENTES UZLETKOTES")
                .contains("BANKFIOK_AZONOSITO\t7001")
                .contains("EUR\t50000\t0")
                .contains("USD\t0\t20000");
        assertThat(request.getStatus()).isEqualTo(DariusFixingRequestStatus.INCLUDED);
        assertThat(request.getIncludedAt()).isEqualTo(LocalDateTime.of(2025, 4, 22, 14, 0));
        assertThat(request.getIncludedFileSha256()).isEqualTo(hash);
        verify(fixingRequestRepository).save(request);
        verify(fixingLineRepository)
                .findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(COMPANY_ID, FIXING_REQUEST_ID);
        verifyNoMoreInteractions(fixingLineRepository);
        verify(auditLogService).logForCompany(
                eq("DARIUS_FIXING_REQUEST_INCLUDED"),
                contains("sha256=" + hash),
                eq(FIXING_REQUEST_ID.toString()),
                eq(COMPANY_ID));
    }

    @Test
    void keepsIncludedRequestsInFileOnRepeatedGeneration() {
        givenSnapshot();
        DariusFixingRequest request = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.INCLUDED);
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(request));
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch(BANK_BRANCH_ID, "7001", true)));
        when(fixingLineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(
                COMPANY_ID, FIXING_REQUEST_ID)).thenReturn(List.of(
                        fixingLine(FIXING_REQUEST_ID, "EUR", "50000", "0")));

        DariusImportFile first = generate();
        DariusImportFile second = generate();

        assertThat(first.content()).containsExactly(second.content());
        assertThat(content(first)).contains("JELENTES UZLETKOTES");
        assertThat(request.getStatus()).isEqualTo(DariusFixingRequestStatus.INCLUDED);
        verify(fixingRequestRepository, never()).save(any());
        verify(auditLogService, never()).logForCompany(
                eq("DARIUS_FIXING_REQUEST_INCLUDED"), contains(""), anyString(), eq(COMPANY_ID));
    }

    @Test
    void failsClosedWhenDraftFixingRequestExistsForDate() {
        givenSnapshot();
        DariusFixingRequest request = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.DRAFT);
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(request));
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch(BANK_BRANCH_ID, "7001", true)));

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jóváhagyatlan")
                .hasMessageContaining("7001");
        assertThat(request.getStatus()).isEqualTo(DariusFixingRequestStatus.DRAFT);
        verify(fixingRequestRepository, never()).save(any());
        verifyNoInteractions(fixingLineRepository);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void failsClosedWhenApprovedRequestBankBranchIsInactiveOrCodeBlank() {
        givenSnapshot();
        DariusFixingRequest request = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.APPROVED);
        DariusBankBranch bankBranch = bankBranch(BANK_BRANCH_ID, "7001", false);
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(request));
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch));

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("inaktív");

        bankBranch.setIsActive(true);
        bankBranch.setBankBranchCode(" ");
        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kód nélküli");
        assertThat(request.getStatus()).isEqualTo(DariusFixingRequestStatus.APPROVED);
        verify(fixingRequestRepository, never()).save(any());
        verifyNoInteractions(fixingLineRepository);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void exportQueryExcludesCancelledRequests() {
        givenSnapshot();

        DariusImportFile result = generate();

        assertThat(content(result)).doesNotContain("JELENTES UZLETKOTES");
        verify(fixingRequestRepository)
                .findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                        COMPANY_ID,
                        DATE,
                        List.of(
                                DariusFixingRequestStatus.DRAFT,
                                DariusFixingRequestStatus.APPROVED,
                                DariusFixingRequestStatus.INCLUDED));
        verifyNoInteractions(bankBranchRepository);
        verifyNoInteractions(fixingLineRepository);
        verify(fixingRequestRepository, never()).save(any());
    }

    @Test
    void serializerFailureLeavesApprovedRequestUntouchedAndUnaudited() {
        givenSnapshot();
        DariusFixingRequest request = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.APPROVED);
        givenValidFixing(request, bankBranch(BANK_BRANCH_ID, "7001", true));
        DariusImportFileSerializer failingSerializer = mock(DariusImportFileSerializer.class);
        when(failingSerializer.serialize(any())).thenThrow(new IllegalStateException("serialize failed"));
        service = newService(failingSerializer, auditLogService);

        assertThatThrownBy(this::generate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("serialize failed");
        assertThat(request.getStatus()).isEqualTo(DariusFixingRequestStatus.APPROVED);
        assertThat(request.getIncludedFileSha256()).isNull();
        verify(fixingRequestRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    void auditFailureLeavesAllApprovedRequestsUntouchedWithoutPartialIncludedState() {
        givenSnapshot();
        UUID secondRequestId = UUID.fromString("50000000-0000-0000-0000-000000000005");
        UUID secondBankBranchId = UUID.fromString("60000000-0000-0000-0000-000000000006");
        DariusFixingRequest first = fixingRequest(
                FIXING_REQUEST_ID, BANK_BRANCH_ID, DariusFixingRequestStatus.APPROVED);
        DariusFixingRequest second = fixingRequest(
                secondRequestId, secondBankBranchId, DariusFixingRequestStatus.APPROVED);
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(first, second));
        when(bankBranchRepository.findByIdAndCompanyId(BANK_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch(BANK_BRANCH_ID, "7001", true)));
        when(bankBranchRepository.findByIdAndCompanyId(secondBankBranchId, COMPANY_ID))
                .thenReturn(Optional.of(bankBranch(secondBankBranchId, "7002", true)));
        when(fixingLineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(
                eq(COMPANY_ID), any())).thenAnswer(invocation -> List.of(
                        fixingLine(invocation.getArgument(1), "EUR", "1", "0")));
        doThrow(new IllegalStateException("audit failed"))
                .when(auditLogService).logForCompany(
                        eq("DARIUS_FIXING_REQUEST_INCLUDED"),
                        contains(secondRequestId.toString()),
                        eq(secondRequestId.toString()),
                        eq(COMPANY_ID));

        assertThatThrownBy(this::generate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("audit failed");
        assertThat(first.getStatus()).isEqualTo(DariusFixingRequestStatus.APPROVED);
        assertThat(second.getStatus()).isEqualTo(DariusFixingRequestStatus.APPROVED);
        assertThat(first.getIncludedFileSha256()).isNull();
        assertThat(second.getIncludedFileSha256()).isNull();
        verify(fixingRequestRepository, never()).save(any());
    }

    @Test
    void normalizesEnumBuyAndStringSellRowsWithoutRounding() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of(
                        row("EUR", TransactionType.BUY, PaymentMethod.CASH, "100", "39000", "10"),
                        row("EUR", "SELL", PaymentMethod.CASH, "50", "20500", "20")));

        String content = content(generate());

        assertThat(content).contains("EUR\t50\t100\t0\t0\t0\t0\t0\r\n");
        assertThat(content).contains("HUF\t0\t0\t0\t0\t0\t0\t30\r\n");
    }

    @Test
    void normalizesSupportedNumericProjectionValuesThroughGeneratedImport() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of(
                        projectionRow("EUR", "BUY", new BigDecimal("10.00"), null, 1L),
                        projectionRow("USD", "SELL", Integer.valueOf(3), 4.5d, null),
                        projectionRow("GBP", "BUY", 2.0d, BigInteger.valueOf(40_000), 2),
                        projectionRow("CHF", "SELL", BigInteger.valueOf(9_007_199_254_740_993L), 0.0f, 1.0f)));

        String content = content(generate());
        String crlf = Character.toString(13) + Character.toString(10);

        assertThat(content).contains("CHF\t9007199254740993\t0\t0\t0\t0\t0\t0" + crlf);
        assertThat(content).contains("EUR\t0\t10\t0\t0\t0\t0\t0" + crlf);
        assertThat(content).contains("GBP\t0\t2\t0\t0\t0\t0\t0" + crlf);
        assertThat(content).contains("USD\t3\t0\t0\t0\t0\t0\t0" + crlf);
        assertThat(content).contains("HUF\t0\t0\t0\t0\t0\t0\t4\r\n");
    }

    @Test
    void preservesHumanDecimalSemanticsForFiniteFloatProjectionAmount() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(projectionRow("EUR", "BUY", 0.1f, 39_000L, 0)));

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("csak egész lehet: 0.1")
                .hasMessageNotContaining("0.10000000149011612");
        verifyNoInteractions(auditLogService);
    }

    @Test
    void rejectsUnsupportedProjectionAmountWithoutClassCastException() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(projectionRow("EUR", "BUY", "100", 39_000L, 0)));

        assertThatThrownBy(this::generate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("java.lang.String");
        verifyNoInteractions(auditLogService);
    }

    @Test
    void rejectsNonFiniteProjectionAmount() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(
                        projectionRow("EUR", "BUY", Double.POSITIVE_INFINITY, 39_000L, 0)));

        assertThatThrownBy(this::generate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("nem véges");
        verifyNoInteractions(auditLogService);
    }

    @ParameterizedTest
    @MethodSource("additionalNonFiniteProjectionAmounts")
    void rejectsAdditionalNonFiniteProjectionAmounts(Object nonFiniteAmount) {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.<Object[]>of(
                        projectionRow("EUR", "BUY", nonFiniteAmount, 39_000L, 0)));

        assertThatThrownBy(this::generate)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("nem véges");
        verifyNoInteractions(auditLogService);
    }

    private static Stream<Object> additionalNonFiniteProjectionAmounts() {
        return Stream.of(Float.POSITIVE_INFINITY, Float.NaN, Double.NaN);
    }

    private DariusImportFile generate() {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            return service.generateImportFile(DATE, 0);
        }
    }

    private void givenSnapshot() {
        when(snapshotRepository.findByBranchIdAndSnapshotDateAndClosingType(BRANCH_ID, DATE, 1))
                .thenReturn(List.of(DailyDenominationSnapshot.builder()
                        .branchId(BRANCH_ID)
                        .snapshotDate(DATE)
                        .currencyCode("EUR")
                        .denominationType("BANKNOTE")
                        .faceValue(new BigDecimal("100"))
                        .quantity(3)
                        .closingType(1)
                        .createdAt(LocalDateTime.of(2025, 4, 22, 10, 58))
                        .build()));
    }

    private void givenValidFixing(DariusFixingRequest request, DariusBankBranch bankBranch) {
        when(fixingRequestRepository.findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                eq(COMPANY_ID), eq(DATE), any())).thenReturn(List.of(request));
        when(bankBranchRepository.findByIdAndCompanyId(request.getBankBranchId(), COMPANY_ID))
                .thenReturn(Optional.of(bankBranch));
        when(fixingLineRepository.findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(
                COMPANY_ID, request.getId())).thenReturn(List.of(
                        fixingLine(request.getId(), "EUR", "1", "0")));
    }

    private static DariusFixingRequest fixingRequest(
            UUID id,
            UUID bankBranchId,
            DariusFixingRequestStatus status) {
        return DariusFixingRequest.builder()
                .id(id)
                .companyId(COMPANY_ID)
                .bankBranchId(bankBranchId)
                .requestDate(DATE)
                .status(status)
                .build();
    }

    private static DariusBankBranch bankBranch(UUID id, String code, boolean active) {
        return DariusBankBranch.builder()
                .id(id)
                .companyId(COMPANY_ID)
                .bankBranchCode(code)
                .name("Teszt bankfiók")
                .isActive(active)
                .build();
    }

    private static DariusFixingRequestLine fixingLine(
            UUID requestId,
            String currencyCode,
            String deliveredAmount,
            String collectedAmount) {
        return DariusFixingRequestLine.builder()
                .companyId(COMPANY_ID)
                .requestId(requestId)
                .currencyCode(currencyCode)
                .deliveredAmount(new BigDecimal(deliveredAmount))
                .collectedAmount(new BigDecimal(collectedAmount))
                .build();
    }

    private static String sha256(byte[] content) {
        try {
            return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content));
        } catch (NoSuchAlgorithmException exception) {
            throw new AssertionError(exception);
        }
    }

    private static Object[] row(
            String currency,
            Object type,
            PaymentMethod paymentMethod,
            String currencyAmount,
            String hufAmount,
            String fee) {
        return new Object[]{
                currency,
                type,
                paymentMethod,
                new BigDecimal(currencyAmount),
                new BigDecimal(hufAmount),
                new BigDecimal(fee)
        };
    }

    private static Object[] projectionRow(
            String currency,
            Object type,
            Object currencyAmount,
            Object hufAmount,
            Object fee) {
        return new Object[]{currency, type, PaymentMethod.CASH, currencyAmount, hufAmount, fee};
    }

    private static String content(DariusImportFile result) {
        return new String(result.content(), StandardCharsets.UTF_8);
    }
}
