package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DariusImportFileServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final LocalDate DATE = LocalDate.of(2025, 4, 22);
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2025-04-22T12:00:00Z"), ZoneOffset.UTC);

    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final DailyDenominationSnapshotRepository snapshotRepository =
            mock(DailyDenominationSnapshotRepository.class);
    private final TransactionRepository transactionRepository = mock(TransactionRepository.class);
    private final CompanyRepository companyRepository = mock(CompanyRepository.class);
    private final ShiftedCalendarDayRepository shiftedCalendarDayRepository =
            mock(ShiftedCalendarDayRepository.class);
    private final AuditLogService auditLogService = mock(AuditLogService.class);
    private final IntegrationTransportProperties properties = new IntegrationTransportProperties();

    private DariusImportFileService service;
    private Branch branch;

    @BeforeEach
    void setUp() {
        properties.getDarius().setPvCodes(Map.of("BEST", "108114"));
        branch = Branch.builder()
                .id(BRANCH_ID)
                .bankCode("276")
                .hasPos(true)
                .isActive(true)
                .build();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(Company.builder()
                .id(COMPANY_ID)
                .code("BEST")
                .build()));
        when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(List.of(branch));
        service = new DariusImportFileService(
                branchRepository,
                snapshotRepository,
                transactionRepository,
                companyRepository,
                new DariusImportPreflightValidator(shiftedCalendarDayRepository, CLOCK),
                new DariusImportFileSerializer(),
                auditLogService,
                properties);
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
        verify(auditLogService).log(
                eq("DARIUS_IMPORT_FILE_EXPORTED"),
                contains("raiffeisen_import_BEST_2025-04-22.imp"),
                eq(COMPANY_ID.toString()));
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
        verify(auditLogService, never()).log(eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), eq(COMPANY_ID.toString()));
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
        verify(auditLogService, never()).log(eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), eq(COMPANY_ID.toString()));
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
    void rejectsWhenNoBranchHasAnyReportableData() {
        when(snapshotRepository.findByBranchIdAndSnapshotDateAndClosingType(BRANCH_ID, DATE, 1))
                .thenReturn(List.of());
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        assertThatThrownBy(this::generate)
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nincs jelenthető adat");
        verify(auditLogService, never()).log(eq("DARIUS_IMPORT_FILE_EXPORTED"), contains(""), eq(COMPANY_ID.toString()));
    }

    @Test
    void loadsOnlyCurrentCompanyActiveBranches() {
        givenSnapshot();
        when(transactionRepository.groupByCurrencyTypeAndPaymentMethodForBranch(BRANCH_ID, DATE, DATE))
                .thenReturn(List.of());

        generate();

        verify(branchRepository).findByCompanyIdAndIsActiveTrue(COMPANY_ID);
        verify(branchRepository, never()).findByIsActiveTrue();
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

    private static String content(DariusImportFile result) {
        return new String(result.content(), StandardCharsets.UTF_8);
    }
}
