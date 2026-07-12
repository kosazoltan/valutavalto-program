package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideType;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FS-11 S1: repository-tesztek a cégszintű compliance tranzakció-kereső tenant- és szűrő-kontraktusára.
 */
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class ComplianceTransactionSearchRepositoryTest {

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;

    @Test
    @DisplayName("FS-11 S1: üres szűrő csak a saját cég financialEffective sorait adja vissza")
    void emptyFilterReturnsOnlyOwnCompanyFinancialEffectiveRows() {
        LocalDateTime now = LocalDateTime.now();
        Tenant own = seedTenant("FS11A", now);
        Tenant foreign = seedTenant("FS11B", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(transaction(own, "FS11-A-001", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"));
        transactionRepository.save(transaction(own, "FS11-A-002", TransactionType.SELL, day, LocalTime.of(11, 0), eur, "2000.00"));
        transactionRepository.save(transaction(foreign, "FS11-B-001", TransactionType.BUY, day, LocalTime.of(12, 0), eur, "3000.00"));
        transactionRepository.flush();

        Page<Transaction> result = search(own, null, null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("FS11-A-002", "FS11-A-001");
        assertThat(result.getTotalElements()).isEqualTo(2);
    }

    @Test
    @DisplayName("FS-11 S1: financialEffective=false CONVERSION parent sor üres szűrővel sem jön vissza")
    void financialEffectiveFalseRowsAreExcluded() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11FE", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(transaction(tenant, "FS11-FE-OK", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"));
        transactionRepository.save(withFinancialEffective(transaction(tenant, "FS11-FE-NO", TransactionType.CONVERSION, day, LocalTime.of(11, 0), eur, "9999.00"), false));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-FE-OK");
    }

    @Test
    @DisplayName("FS-11 S1: dátum-intervallum mindkét határa inkluzív")
    void dateRangeIsInclusive() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11D", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);

        transactionRepository.save(transaction(tenant, "FS11-D-BEFORE", TransactionType.BUY, LocalDate.of(2026, 7, 4), LocalTime.NOON, eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-D-START", TransactionType.BUY, LocalDate.of(2026, 7, 5), LocalTime.NOON, eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-D-END", TransactionType.BUY, LocalDate.of(2026, 7, 10), LocalTime.NOON, eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-D-AFTER", TransactionType.BUY, LocalDate.of(2026, 7, 11), LocalTime.NOON, eur, "1000.00"));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, LocalDate.of(2026, 7, 5), LocalDate.of(2026, 7, 10), null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("FS11-D-END", "FS11-D-START");
    }

    @Test
    @DisplayName("FS-11 S1: típus és HUF min/max határ inkluzívan szűr")
    void typeAndHufAmountBoundsAreInclusive() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11H", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(transaction(tenant, "FS11-H-LOW", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "999.99"));
        transactionRepository.save(transaction(tenant, "FS11-H-MIN", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-H-MAX", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "2000.00"));
        transactionRepository.save(transaction(tenant, "FS11-H-TYPE", TransactionType.SELL, day, LocalTime.of(12, 0), eur, "1500.00"));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, null, null, TransactionType.BUY,
                new BigDecimal("1000.00"), new BigDecimal("2000.00"), true, List.of(-1L), null,
                false, false, false, false, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("FS11-H-MAX", "FS11-H-MIN");
    }

    @Test
    @DisplayName("FS-11 S1: currencyIds fő-valutára szűr, az üres-lista sentinel pedig mindent enged")
    void currencyFilterAndSentinelWork() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11C", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        Currency usd = findOrCreateCurrency("USD", "USA dollár", "$", 2, 2, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(transaction(tenant, "FS11-C-EUR", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-C-USD", TransactionType.BUY, day, LocalTime.of(11, 0), usd, "2000.00"));
        transactionRepository.flush();

        Page<Transaction> eurOnly = search(tenant, null, null, null, null, null, null,
                false, List.of(eur.getId()), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));
        Page<Transaction> sentinel = search(tenant, null, null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(eurOnly.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-C-EUR");
        assertThat(sentinel.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-C-USD", "FS11-C-EUR");
    }

    @Test
    @DisplayName("FS-11 S1: boolean szűrők csak a ténylegesen illeszkedő sorokat engedik át")
    void booleanFiltersWorkIndividually() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11BOL", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomRate(transaction(tenant, "FS11-BOOL-CUSTOM", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "1000.00")));
        transactionRepository.save(withPep(transaction(tenant, "FS11-BOOL-PEP", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"), true));
        transactionRepository.save(withOwnBehalf(transaction(tenant, "FS11-BOOL-BEHALF", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "1000.00"), false));
        transactionRepository.save(withOwnBehalf(transaction(tenant, "FS11-BOOL-OWN", TransactionType.BUY, day, LocalTime.of(12, 0), eur, "1000.00"), true));
        transactionRepository.save(withOwnBehalf(transaction(tenant, "FS11-BOOL-NULL", TransactionType.BUY, day, LocalTime.of(13, 0), eur, "1000.00"), null));
        transactionRepository.save(withDiscountCode(transaction(tenant, "FS11-BOOL-DISCOUNT", TransactionType.BUY, day, LocalTime.of(14, 0), eur, "1000.00"), 4));
        transactionRepository.save(withOverride(transaction(tenant, "FS11-BOOL-OVERRIDE", TransactionType.BUY, day, LocalTime.of(15, 0), eur, "1000.00"), HandlingFeeOverrideType.HALF));
        transactionRepository.save(withNoDiscount(transaction(tenant, "FS11-BOOL-NONE", TransactionType.BUY, day, LocalTime.of(16, 0), eur, "1000.00")));
        transactionRepository.flush();

        assertThat(search(tenant, null, null, null, null, null, null, true, List.of(-1L), null,
                true, false, false, false, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20))
                .getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-BOOL-CUSTOM");
        assertThat(search(tenant, null, null, null, null, null, null, true, List.of(-1L), null,
                false, false, false, true, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20))
                .getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-BOOL-PEP");
        assertThat(search(tenant, null, null, null, null, null, null, true, List.of(-1L), null,
                false, false, true, false, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20))
                .getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-BOOL-BEHALF");
        assertThat(search(tenant, null, null, null, null, null, null, true, List.of(-1L), null,
                false, true, false, false, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20))
                .getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("FS11-BOOL-OVERRIDE", "FS11-BOOL-DISCOUNT");
    }

    @Test
    @DisplayName("FS-11 S1: ügyfélnév és okmányszám LIKE case-insensitive töredékre szűr")
    void customerLikeFiltersAreCaseInsensitive() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11LIKE", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomer(transaction(tenant, "FS11-LIKE-YES", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"), "Kovács Béla", "AB123456"));
        transactionRepository.save(withCustomer(transaction(tenant, "FS11-LIKE-NO", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "1000.00"), "Nagy Anna", "ZX999999"));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                "kov", null, null, "123", false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-LIKE-YES");
    }

    @Test
    @DisplayName("FS-11 S1: jogi személy checkbox és cégnév LIKE szűr")
    void legalEntityFiltersWork() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11LEG", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withLegalEntity(transaction(tenant, "FS11-LEG-YES", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"), true, "Exclusive Alfa Kft."));
        transactionRepository.save(withLegalEntity(transaction(tenant, "FS11-LEG-NO", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "1000.00"), false, "Magánszemély"));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, true, "alfa", null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-LEG-YES");
    }

    @Test
    @DisplayName("FS-11 S1: kombinált szűrőn csak a minden feltételnek megfelelő sor jön vissza")
    void combinedFiltersRequireAllConditions() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11COMB", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withPep(transaction(tenant, "FS11-COMB-YES", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "5000.00"), true));
        transactionRepository.save(withPep(transaction(tenant, "FS11-COMB-NOTYPE", TransactionType.SELL, day, LocalTime.of(11, 0), eur, "5000.00"), true));
        transactionRepository.save(withPep(transaction(tenant, "FS11-COMB-NOAMT", TransactionType.BUY, day, LocalTime.of(12, 0), eur, "999.99"), true));
        transactionRepository.save(withPep(transaction(tenant, "FS11-COMB-NOPEP", TransactionType.BUY, day, LocalTime.of(13, 0), eur, "5000.00"), false));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, null, null, null, TransactionType.BUY,
                new BigDecimal("1000.00"), null, true, List.of(-1L), null,
                false, false, false, true, null, null, null, null, false, null, null, null, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber).containsExactly("FS11-COMB-YES");
    }

    @Test
    @DisplayName("FS-11 S1: branchId szűrő és lapozott totalElements helyes")
    void branchFilterAndPagingWork() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS11BR", now);
        Branch otherBranch = createBranch(tenant, "FS11BR2", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(transaction(tenant, "FS11-BR-1", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "1000.00"));
        transactionRepository.save(transaction(tenant, "FS11-BR-2", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "2000.00"));
        transactionRepository.save(withBranch(transaction(tenant, "FS11-BR-OTHER", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "3000.00"), otherBranch));
        transactionRepository.flush();

        Page<Transaction> result = search(tenant, tenant.branch().getId(), null, null, null, null, null,
                true, List.of(-1L), null, false, false, false, false,
                null, null, null, null, false, null, null, null, null, PageRequest.of(0, 2));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("FS11-BR-2", "FS11-BR-1");
        assertThat(result.getTotalElements()).isEqualTo(2);
    }

    private Page<Transaction> search(
            Tenant tenant,
            java.util.UUID branchId,
            LocalDate startDate,
            LocalDate endDate,
            TransactionType type,
            BigDecimal minHufAmount,
            BigDecimal maxHufAmount,
            boolean currencyIdsEmpty,
            List<Long> currencyIds,
            PaymentMethod paymentMethod,
            boolean customRateOnly,
            boolean kkDiscountOnly,
            boolean onBehalfOfOtherOnly,
            boolean pepOnly,
            String customerName,
            LocalDate customerBirthDate,
            String customerNationality,
            String customerDocumentNumber,
            boolean legalEntityOnly,
            String legalEntityName,
            String legalEntityTaxNumber,
            String legalDeedNumber,
            String legalEntitySeat,
            org.springframework.data.domain.Pageable pageable) {
        return transactionRepository.searchComplianceTransactions(
                tenant.company().getId(), branchId, startDate, endDate, type, minHufAmount, maxHufAmount,
                currencyIdsEmpty, currencyIds, paymentMethod, customRateOnly, kkDiscountOnly,
                onBehalfOfOtherOnly, pepOnly, customerName, customerBirthDate, customerNationality,
                customerDocumentNumber, legalEntityOnly, legalEntityName, legalEntityTaxNumber,
                legalDeedNumber, legalEntitySeat, null, null, null,
                true, List.of("-"), pageable);
    }

    private Tenant seedTenant(String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("FS-11 S1 Company " + suffix)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("FS-11 S1 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(shortCode("CO", suffix))
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(shortCode("BS", suffix))
                .name("Active")
                .createdAt(now)
                .build());
        Branch branch = branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(company)
                .bankCode("FS11BANK")
                .branchType(branchType)
                .name("FS-11 S1 Branch " + suffix)
                .address("Compliance utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDictionary)
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix))
                .name("FS-11 S1 Pénztáros")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, branch, worker);
    }

    private Branch createBranch(Tenant tenant, String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        return branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(tenant.company())
                .bankCode("FS11BANK")
                .branchType(tenant.branch().getBranchType())
                .name("FS-11 S1 Other Branch " + suffix)
                .address("Compliance utca 2")
                .city("Budapest")
                .zipCode("1000")
                .country(tenant.branch().getCountry())
                .branchStatus(tenant.branch().getBranchStatus())
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
    }

    private Currency findOrCreateCurrency(
            String code,
            String name,
            String symbol,
            int decimalPlaces,
            int displayOrder,
            LocalDateTime now) {
        return currencyRepository.findByCode(code)
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code(code)
                        .name(name)
                        .symbol(symbol)
                        .decimalPlaces(decimalPlaces)
                        .active(true)
                        .displayOrder(displayOrder)
                        .createdAt(now)
                        .build()));
    }

    private Transaction transaction(
            Tenant tenant,
            String receiptNumber,
            TransactionType type,
            LocalDate businessDate,
            LocalTime time,
            Currency currency,
            String hufAmount) {
        return Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(businessDate)
                .transactionTime(time)
                .currency(currency)
                .currencyAmount(new BigDecimal("10.00"))
                .exchangeRate(new BigDecimal("400.0000"))
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .discountTypeCode(0)
                .customerId("FS11-CUST")
                .customerName("FS-11 S1 Ügyfél")
                .customerDocumentNumber("AB123456")
                .financialEffective(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static Transaction withFinancialEffective(Transaction transaction, boolean financialEffective) {
        transaction.setFinancialEffective(financialEffective);
        return transaction;
    }

    private static Transaction withCustomRate(Transaction transaction) {
        transaction.setCashierCustomRate(true);
        return transaction;
    }

    private static Transaction withPep(Transaction transaction, Boolean pep) {
        transaction.setCustomerIsPep(pep);
        return transaction;
    }

    private static Transaction withOwnBehalf(Transaction transaction, Boolean ownBehalf) {
        transaction.setCustomerOnOwnBehalf(ownBehalf);
        return transaction;
    }

    private static Transaction withDiscountCode(Transaction transaction, Integer discountTypeCode) {
        transaction.setDiscountTypeCode(discountTypeCode);
        return transaction;
    }

    private static Transaction withOverride(Transaction transaction, HandlingFeeOverrideType overrideType) {
        transaction.setHandlingFeeOverrideType(overrideType);
        return transaction;
    }

    private static Transaction withNoDiscount(Transaction transaction) {
        transaction.setDiscountTypeCode(0);
        transaction.setHandlingFeeOverrideType(null);
        return transaction;
    }

    private static Transaction withCustomer(Transaction transaction, String name, String documentNumber) {
        transaction.setCustomerName(name);
        transaction.setCustomerDocumentNumber(documentNumber);
        return transaction;
    }

    private static Transaction withLegalEntity(Transaction transaction, Boolean legalEntityCustomer, String legalEntityName) {
        transaction.setIsLegalEntityCustomer(legalEntityCustomer);
        transaction.setLegalEntityName(legalEntityName);
        return transaction;
    }

    private static Transaction withBranch(Transaction transaction, Branch branch) {
        transaction.setBranch(branch);
        return transaction;
    }

    private static String shortCode(String prefix, String value) {
        String digits = value.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return prefix + tail;
    }

    private record Tenant(Company company, Branch branch, Worker worker) {
    }
}
