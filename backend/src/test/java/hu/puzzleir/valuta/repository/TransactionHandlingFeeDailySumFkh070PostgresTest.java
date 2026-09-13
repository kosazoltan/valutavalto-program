package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-070: the new live daily handling-fee SUM finder on real PostgreSQL.
 *
 * <p>Filter contract (ticket TBD-2): company + branch + transactionDate + status COMPLETED
 * + financialEffective = true + type in buy/sell family. Rows excluded: non-effective
 * (conversion parent), PENDING, REVERSED, other day, other branch, other tenant.</p>
 *
 * <p>Pinning test (plan WU-1): do not edit after commit.</p>
 */
@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class TransactionHandlingFeeDailySumFkh070PostgresTest {

    private static final LocalDate D = LocalDate.of(2026, 9, 10);

    private static final Collection<TransactionType> BUY_AND_SELL = List.of(
            TransactionType.BUY,
            TransactionType.WESTERN_UNION_RECEIVE,
            TransactionType.MONEYGRAM_RECEIVE,
            TransactionType.SELL,
            TransactionType.WESTERN_UNION_SEND,
            TransactionType.MONEYGRAM_SEND);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("FKH-070 FR-1/FR-4: only live COMPLETED effective buy/sell fees of the"
            + " tenant+branch+day are summed")
    void sumsOnlyLiveEffectiveCompletedBuySellFees() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        // 295 (BUY, effective) + 100 (SELL, effective) = 395.
        // Excluded: 500 (effective=false), 700 (PENDING), 800 (REVERSED),
        //           900 (D+1), 1000 (branch B2), 1100 (company A2).
        assertThat(transactionRepository.sumHandlingFeeForBranchAndDate(
                seed.companyA().getId(), seed.branchB().getId(), D, BUY_AND_SELL))
                .isEqualByComparingTo("395");

        // Tenant isolation: the same branch under company A2 sees nothing.
        assertThat(transactionRepository.sumHandlingFeeForBranchAndDate(
                seed.companyA2().getId(), seed.branchB().getId(), D, BUY_AND_SELL))
                .isEqualByComparingTo("0");

        // The next business day sees only its own row.
        assertThat(transactionRepository.sumHandlingFeeForBranchAndDate(
                seed.companyA().getId(), seed.branchB().getId(), D.plusDays(1), BUY_AND_SELL))
                .isEqualByComparingTo("900");

        // An empty day yields 0 (COALESCE), never null.
        assertThat(transactionRepository.sumHandlingFeeForBranchAndDate(
                seed.companyA().getId(), seed.branchB().getId(), D.plusDays(5), BUY_AND_SELL))
                .isEqualByComparingTo("0");
    }

    // ============================ SEED ============================

    private Seed seed() {
        LocalDateTime now = D.atTime(8, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FKH070-BT-" + suffix)
                .name("FKH-070 branch type")
                .createdAt(now)
                .updatedAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("FKH070-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .updatedAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FKH070-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .updatedAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .displayOrder(1)
                        .createdAt(now)
                        .updatedAt(now)
                        .build()));

        Company companyA = companyRepository.save(Company.builder()
                .code("FKH070A-" + suffix)
                .name("FKH-070 Company A")
                .createdAt(now)
                .updatedAt(now)
                .build());
        Company companyA2 = companyRepository.save(Company.builder()
                .code("FKH070Z-" + suffix)
                .name("FKH-070 Company A2")
                .createdAt(now)
                .updatedAt(now)
                .build());
        Branch branchB = seedBranch(companyA, "B" + suffix, branchType, country, branchStatus, now);
        Branch branchB2 = seedBranch(companyA, "B2" + suffix, branchType, country, branchStatus, now);
        Branch branchA2B = seedBranch(companyA2, "Z" + suffix, branchType, country, branchStatus, now);
        Worker workerA = seedWorker(companyA, branchB, "A" + suffix, now);
        Worker workerA2 = seedWorker(companyA2, branchA2B, "Z" + suffix, now);

        // Included: 295 + 100.
        saveTransaction(companyA, branchB, workerA, huf, D, TransactionType.BUY,
                TransactionStatus.COMPLETED, "295", true, "F70T1-" + suffix);
        saveTransaction(companyA, branchB, workerA, huf, D, TransactionType.SELL,
                TransactionStatus.COMPLETED, "100", true, "F70T2-" + suffix);
        // Excluded: conversion-parent style non-effective row.
        saveTransaction(companyA, branchB, workerA, huf, D, TransactionType.BUY,
                TransactionStatus.COMPLETED, "500", false, "F70T3-" + suffix);
        // Excluded: PENDING.
        saveTransaction(companyA, branchB, workerA, huf, D, TransactionType.BUY,
                TransactionStatus.PENDING, "700", true, "F70T4-" + suffix);
        // Excluded: REVERSED.
        saveTransaction(companyA, branchB, workerA, huf, D, TransactionType.BUY,
                TransactionStatus.REVERSED, "800", true, "F70T5-" + suffix);
        // Excluded from D: next-day row (own assertion above).
        saveTransaction(companyA, branchB, workerA, huf, D.plusDays(1), TransactionType.BUY,
                TransactionStatus.COMPLETED, "900", true, "F70T6-" + suffix);
        // Excluded: other branch of the same company.
        saveTransaction(companyA, branchB2, workerA, huf, D, TransactionType.BUY,
                TransactionStatus.COMPLETED, "1000", true, "F70T7-" + suffix);
        // Excluded: other tenant.
        saveTransaction(companyA2, branchA2B, workerA2, huf, D, TransactionType.BUY,
                TransactionStatus.COMPLETED, "1100", true, "F70T8-" + suffix);

        transactionRepository.flush();
        return new Seed(companyA, branchB, companyA2);
    }

    private Branch seedBranch(
            Company company,
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code("FKH070-" + suffix)
                .company(company)
                .bankCode("FKH070BANK")
                .branchType(branchType)
                .name("FKH-070 Branch " + suffix)
                .address("Test Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .openingDate(D)
                .createdAt(now)
                .updatedAt(now)
                .build());
    }

    private Worker seedWorker(Company company, Branch branch, String suffix, LocalDateTime now) {
        return workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code("FKH070-W-" + suffix)
                .name("FKH-070 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .updatedAt(now)
                .build());
    }

    private void saveTransaction(
            Company company,
            Branch branch,
            Worker worker,
            Currency currency,
            LocalDate date,
            TransactionType type,
            TransactionStatus status,
            String handlingFee,
            boolean financialEffective,
            String receiptNumber) {
        transactionRepository.save(Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(status)
                .transactionDate(date)
                .transactionTime(LocalTime.NOON)
                .currency(currency)
                .currencyAmount(BigDecimal.ONE)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(BigDecimal.ZERO)
                .handlingFee(new BigDecimal(handlingFee))
                .customerId("FKH070")
                .financialEffective(financialEffective)
                .createdAt(date.atTime(12, 0))
                .build());
    }

    private record Seed(Company companyA, Branch branchB, Company companyA2) {}
}
