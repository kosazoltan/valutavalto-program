package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideType;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-11 S1: service-tesztek a companyId SecurityContextből olvasására, normalizálásra és DTO mappingre.
 */
@ExtendWith(MockitoExtension.class)
class ComplianceTransactionSearchServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private ComplianceTransactionSearchService service;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
        Authentication auth = new TestingAuthenticationToken("fs11", null);
        auth.setAuthenticated(true);
        var details = mock(hu.puzzleir.valuta.security.WorkerAuthenticationDetails.class);
        when(details.getCompanyId()).thenReturn(COMPANY_ID);
        ((TestingAuthenticationToken) auth).setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FS-11 S1: search a SecurityContext companyId-jével hívja a repository-t")
    void searchUsesCompanyIdFromSecurityContext() {
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of()));

        service.search(new ComplianceTransactionSearchCriteria(), PageRequest.of(0, 10));

        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), isNull(), isNull(), isNull(), isNull(), isNull(), isNull(),
                eq(true), eq(List.of(-1L)), isNull(), eq(false), eq(false), eq(false), eq(false), isNull(), isNull(), isNull(),
                isNull(), eq(false), isNull(), isNull(), isNull(), isNull(), isNull(), any());
    }

    @Test
    @DisplayName("FS-11 S1: currencyIds üres esetben sentinel, megadva pedig változatlan lista")
    void currencyIdsEmptyUsesSentinelOtherwiseOriginalList() {
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of()));

        service.search(new ComplianceTransactionSearchCriteria(), PageRequest.of(0, 10));
        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        criteria.setCurrencyIds(List.of(1L, 2L));
        service.search(criteria, PageRequest.of(0, 10));

        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                eq(true), eq(List.of(-1L)), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any());
        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                eq(false), eq(List.of(1L, 2L)), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("FS-11 S1: string szűrők trimelődnek, üres string null-ként megy tovább")
    void stringFiltersAreTrimmedAndBlankBecomesNull() {
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of()));
        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        criteria.setCustomerName("  kovács  ");
        criteria.setCustomerNationality("   ");
        criteria.setCustomerDocumentNumber("");

        service.search(criteria, PageRequest.of(0, 10));

        ArgumentCaptor<String> customerName = ArgumentCaptor.forClass(String.class);
        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), customerName.capture(), any(), isNull(),
                isNull(), anyBoolean(), any(), any(), any(), any(), isNull(), any());
        assertThat(customerName.getValue()).isEqualTo("kovács");
    }

    @Test
    @DisplayName("FS-11 S1: beneficialOwnerName szűrő trimelődik, üres string null-ként megy tovább")
    void beneficialOwnerNameFilterIsTrimmedAndBlankBecomesNull() {
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of()));
        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        criteria.setBeneficialOwnerName("  Kovács Tulaj Béla  ");

        service.search(criteria, PageRequest.of(0, 10));

        ArgumentCaptor<String> beneficialOwnerName = ArgumentCaptor.forClass(String.class);
        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), isNull(), any(), isNull(),
                isNull(), anyBoolean(), isNull(), isNull(), isNull(), isNull(), beneficialOwnerName.capture(), any());
        assertThat(beneficialOwnerName.getValue()).isEqualTo("Kovács Tulaj Béla");

        ComplianceTransactionSearchCriteria blank = new ComplianceTransactionSearchCriteria();
        blank.setBeneficialOwnerName("   ");
        service.search(blank, PageRequest.of(0, 10));

        verify(transactionRepository).searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), isNull(), any(), isNull(),
                isNull(), anyBoolean(), isNull(), isNull(), isNull(), isNull(), isNull(), any());
    }

    @Test
    @DisplayName("FS-11 S1: RowDto mapping mezőhelyes, null-safe és a KK kedvezmény származtatott")
    void rowMappingIsFieldAccurateNullSafeAndDerivesKkDiscount() {
        Transaction discountCode = transaction("FS11-MAP-DISC");
        discountCode.setDiscountTypeCode(4);
        Transaction override = transaction("FS11-MAP-OVR");
        override.setHandlingFeeOverrideType(HandlingFeeOverrideType.HALF);
        Transaction noDiscount = transaction("FS11-MAP-NONE");
        noDiscount.setCurrency(null);
        noDiscount.setWorker(null);
        noDiscount.setOriginalTransaction(null);
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of(discountCode, override, noDiscount)));

        Page<ComplianceTransactionRowDto> result = service.search(new ComplianceTransactionSearchCriteria(), PageRequest.of(0, 10));

        assertThat(result.getContent()).extracting(ComplianceTransactionRowDto::getKkDiscount)
                .containsExactly(true, true, false);
        ComplianceTransactionRowDto first = result.getContent().get(0);
        assertThat(first.getReceiptNumber()).isEqualTo("FS11-MAP-DISC");
        assertThat(first.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(first.getBranchName()).isEqualTo("Belvárosi iroda");
        assertThat(first.getBranchCode()).isEqualTo("BR001");
        assertThat(first.getCurrencyId()).isEqualTo(978L);
        assertThat(first.getCurrencyCode()).isEqualTo("EUR");
        assertThat(first.getWorkerCode()).isEqualTo("P001");
        assertThat(first.getWorkerName()).isEqualTo("Teszt Pénztáros");
        assertThat(first.getOriginalReceiptNumber()).isEqualTo("FS11-ORIG");
        ComplianceTransactionRowDto nullSafe = result.getContent().get(2);
        assertThat(nullSafe.getCurrencyId()).isNull();
        assertThat(nullSafe.getWorkerCode()).isNull();
        assertThat(nullSafe.getOriginalReceiptNumber()).isNull();
    }

    @Test
    @DisplayName("FS-11 S1: searchForExport 10000 sor felett fail-closed, limit alatt teljes listát ad")
    void searchForExportEnforcesMaxRows() {
        when(transactionRepository.searchComplianceTransactions(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(),
                anyBoolean(), any(), any(), anyBoolean(), anyBoolean(), anyBoolean(), anyBoolean(), any(), any(), any(),
                any(), anyBoolean(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of(transaction("FS11-EXPORT-OK")), PageRequest.of(0, 10_000), 10_000))
                .thenReturn(new PageImpl<>(List.of(transaction("FS11-EXPORT-TOO-LARGE")), PageRequest.of(0, 10_000), 10_001));

        assertThat(service.searchForExport(new ComplianceTransactionSearchCriteria()))
                .extracting(ComplianceTransactionRowDto::getReceiptNumber)
                .containsExactly("FS11-EXPORT-OK");
        assertThatThrownBy(() -> service.searchForExport(new ComplianceTransactionSearchCriteria()))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode")
                .isEqualTo("COMPLIANCE_EXPORT_TOO_LARGE");
    }

    private static Transaction transaction(String receiptNumber) {
        Company company = Company.builder().id(COMPANY_ID).code("C1").name("Company").build();
        Branch branch = Branch.builder().id(BRANCH_ID).code("BR001").name("Belvárosi iroda").company(company).build();
        Currency currency = Currency.builder().id(978L).code("EUR").name("Euró").build();
        Worker worker = Worker.builder().id(1L).code("P001").name("Teszt Pénztáros").company(company).branch(branch).build();
        Transaction original = Transaction.builder().receiptNumber("FS11-ORIG").build();
        return Transaction.builder()
                .id(123L)
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.of(2026, 7, 8))
                .transactionTime(LocalTime.of(10, 30))
                .currency(currency)
                .currencyAmount(new BigDecimal("12.34"))
                .exchangeRate(new BigDecimal("400.1234"))
                .hufAmount(new BigDecimal("4937.52"))
                .paymentMethod(PaymentMethod.CARD)
                .cashierCustomRate(true)
                .customerIsPep(true)
                .customerOnOwnBehalf(false)
                .amlSuspicious(true)
                .customerId("CUST-1")
                .customerName("Kovács Béla")
                .customerBirthDate(LocalDate.of(1980, 1, 2))
                .customerNationality("Magyar")
                .customerDocumentNumber("AB123456")
                .isLegalEntityCustomer(true)
                .legalEntityName("Alfa Kft.")
                .legalEntityTaxNumber("12345678-2-42")
                .originalTransaction(original)
                .discountTypeCode(0)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
