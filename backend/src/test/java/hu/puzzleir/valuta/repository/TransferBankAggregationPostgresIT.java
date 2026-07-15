package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class TransferBankAggregationPostgresIT {

    private static final LocalDate BUSINESS_DATE = LocalDate.of(2026, 7, 14);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("BANK+ az aznapi COMPLETED ERB U tételeket valutánként összegzi")
    void sumBankInByDayAggregatesCompletedErbReceiverTransfersByCurrency() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("IN");
            saveTransfer(seed, seed.vault(), seed.partner(), "IN-1", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.eur(), "100.00");
            saveTransfer(seed, seed.vault(), seed.partner(), "IN-2", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.eur(), "250.00");

            assertThat(totals(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)))
                    .containsExactly(Map.entry("EUR", new BigDecimal("350.0000")));
        });
    }

    @Test
    @DisplayName("BANK− az aznapi COMPLETED TRB F tételt összegzi, BANK+ nem")
    void sumBankOutByDayAggregatesCompletedSenderTransferOnly() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("OUT");
            saveTransfer(seed, seed.vault(), seed.partner(), "OUT-1", Transfer.TransferType.TRB,
                    Transfer.TransferDirection.F, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.usd(), "75.00");

            assertThat(totals(transferRepository.sumBankOutByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)))
                    .containsExactly(Map.entry("USD", new BigDecimal("75.0000")));
            assertThat(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    @Test
    @DisplayName("Multi-line technikai RB-nél kizárólag a sorösszegek számítanak, a header nem")
    void multiLineTransferUsesLineCurrenciesAndNeverAddsHeaderAmount() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("ML");
            Transfer transfer = saveTransfer(seed, seed.vault(), seed.partner(), "ML-1",
                    Transfer.TransferType.ERB, Transfer.TransferDirection.U,
                    Transfer.TransferStatus.COMPLETED, false, BUSINESS_DATE, seed.eur(), "999.00");
            transfer.getLines().add(line(transfer, seed.eur(), "100.00", 1));
            transfer.getLines().add(line(transfer, seed.usd(), "50.00", 2));
            transferRepository.saveAndFlush(transfer);

            Map<String, BigDecimal> result = totals(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE));

            assertThat(result)
                    .containsEntry("EUR", new BigDecimal("100.00"))
                    .containsEntry("USD", new BigDecimal("50.00"))
                    .hasSize(2);
            assertThat(result.values()).noneMatch(value -> value.compareTo(new BigDecimal("999.00")) == 0);
        });
    }

    @Test
    @DisplayName("TransferLine nélküli FRB a header HUF összegével számít")
    void headerOnlyTransferFallsBackToHeaderCurrencyAndAmount() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("HDR");
            saveTransfer(seed, seed.vault(), seed.partner(), "HDR-1", Transfer.TransferType.FRB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.huf(), "500000.00");

            assertThat(totals(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)))
                    .containsExactly(Map.entry("HUF", new BigDecimal("500000.0000")));
        });
    }

    @Test
    @DisplayName("Sztornózott technikai RB nem számít bele")
    void cancelledTransferIsExcluded() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("CAN");
            saveTransfer(seed, seed.vault(), seed.partner(), "CAN-1", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, true,
                    BUSINESS_DATE, seed.eur(), "100.00");

            assertThat(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    @Test
    @DisplayName("Csak COMPLETED státuszú technikai RB számít bele")
    void pendingAndReceivedTransfersAreExcluded() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("STA");
            saveTransfer(seed, seed.vault(), seed.partner(), "STA-P", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.PENDING, false,
                    BUSINESS_DATE, seed.eur(), "100.00");
            saveTransfer(seed, seed.vault(), seed.partner(), "STA-R", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.RECEIVED, false,
                    BUSINESS_DATE, seed.eur(), "200.00");
            saveTransfer(seed, seed.vault(), seed.partner(), "STA-C", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.eur(), "300.00");

            assertThat(totals(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)))
                    .containsExactly(Map.entry("EUR", new BigDecimal("300.0000")));
        });
    }

    @Test
    @DisplayName("Más napi technikai RB nem számít bele")
    void transferFromAnotherDateIsExcluded() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("DAT");
            saveTransfer(seed, seed.vault(), seed.partner(), "DAT-OLD", Transfer.TransferType.ERB,
                    Transfer.TransferDirection.U, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE.minusDays(1), seed.eur(), "100.00");

            assertThat(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    @Test
    @DisplayName("A fromBranch cége szerinti tenant-szűrés idegen értéktári tételt kizár")
    void transferFromAnotherCompanyIsExcludedEvenWithRequestedCompany() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("TEN");
            Seed foreign = seed("FOR");
            saveTransfer(foreign, foreign.vault(), foreign.partner(), "TEN-FOREIGN",
                    Transfer.TransferType.ERB, Transfer.TransferDirection.U,
                    Transfer.TransferStatus.COMPLETED, false, BUSINESS_DATE, foreign.eur(), "900.00");

            assertThat(transferRepository.sumBankInByDay(
                    foreign.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    @Test
    @DisplayName("Ugyanazon cég másik értéktárának tétele nem számít bele")
    void transferFromAnotherVaultBranchIsExcluded() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("BR");
            Branch otherVault = saveBranch(seed.company(), seed.dictionaries(), "OTHER", true, 2);
            Worker otherWorker = saveWorker(seed.company(), otherVault, "OTHER");
            saveTransfer(seed.withWorker(otherWorker), otherVault, seed.partner(), "BR-OTHER",
                    Transfer.TransferType.ERB, Transfer.TransferDirection.U,
                    Transfer.TransferStatus.COMPLETED, false, BUSINESS_DATE, seed.eur(), "450.00");

            assertThat(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    @Test
    @DisplayName("UF irány BANK−-ban számít, BANK+-ban nem")
    void fullCycleDirectionCountsOnlyAsBankOut() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seed("UF");
            saveTransfer(seed, seed.vault(), seed.partner(), "UF-1", Transfer.TransferType.PRB,
                    Transfer.TransferDirection.UF, Transfer.TransferStatus.COMPLETED, false,
                    BUSINESS_DATE, seed.huf(), "1250.00");

            assertThat(totals(transferRepository.sumBankOutByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)))
                    .containsExactly(Map.entry("HUF", new BigDecimal("1250.0000")));
            assertThat(transferRepository.sumBankInByDay(
                    seed.vault().getId(), seed.company().getId(), BUSINESS_DATE)).isEmpty();
        });
    }

    private Seed seed(String prefix) {
        String suffix = uniqueSuffix(prefix);
        LocalDateTime now = LocalDateTime.now();
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix, 20))
                .name("FK-052 Company " + suffix)
                .createdAt(now)
                .build());
        Dictionaries dictionaries = saveDictionaries(suffix, now);
        Branch vault = saveBranch(company, dictionaries, "VAULT", true, 1);
        Branch partner = saveBranch(company, dictionaries, "BANK", false, null);
        Worker worker = saveWorker(company, vault, suffix);
        Currency eur = findOrCreateCurrency("EUR", "Euro", "EUR", 2, 2, now);
        Currency usd = findOrCreateCurrency("USD", "US Dollar", "USD", 2, 3, now);
        Currency huf = findOrCreateCurrency("HUF", "Forint", "Ft", 0, 1, now);
        return new Seed(company, vault, partner, worker, dictionaries, eur, usd, huf);
    }

    private Dictionaries saveDictionaries(String suffix, LocalDateTime now) {
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix, 20))
                .name("FK-052 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(shortCode("CO", suffix, 20))
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary status = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(shortCode("BS", suffix, 20))
                .name("Active")
                .createdAt(now)
                .build());
        return new Dictionaries(branchType, country, status);
    }

    private Branch saveBranch(
            Company company,
            Dictionaries dictionaries,
            String label,
            boolean vault,
            Integer territoryId) {
        String suffix = uniqueSuffix(label);
        return branchRepository.save(Branch.builder()
                .code(shortCode("B", suffix, 20))
                .company(company)
                .bankCode("FK052")
                .branchType(dictionaries.branchType())
                .name("FK-052 " + label)
                .address("Test street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(dictionaries.country())
                .branchStatus(dictionaries.status())
                .openingDate(BUSINESS_DATE.minusYears(1))
                .isVault(vault)
                .vaultTerritoryId(territoryId)
                .createdAt(LocalDateTime.now())
                .build());
    }

    private Worker saveWorker(Company company, Branch branch, String label) {
        String suffix = uniqueSuffix(label);
        return workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix, 10))
                .name("FK-052 Worker")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(LocalDateTime.now())
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

    private Transfer saveTransfer(
            Seed seed,
            Branch fromBranch,
            Branch toBranch,
            String number,
            Transfer.TransferType type,
            Transfer.TransferDirection direction,
            Transfer.TransferStatus status,
            boolean cancelled,
            LocalDate date,
            Currency currency,
            String amount) {
        return transferRepository.saveAndFlush(Transfer.builder()
                .transferNumber(uniqueSuffix(number))
                .companyId(fromBranch.getCompany().getId())
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(seed.worker())
                .transferType(type)
                .status(status)
                .transferDate(date)
                .transferTime(LocalTime.NOON)
                .currency(currency)
                .amount(new BigDecimal(amount))
                .direction(direction)
                .isCancelled(cancelled)
                .createdAt(LocalDateTime.now())
                .build());
    }

    private static TransferLine line(Transfer transfer, Currency currency, String amount, int lineNo) {
        return TransferLine.builder()
                .transfer(transfer)
                .currency(currency)
                .amount(new BigDecimal(amount))
                .lineNo(lineNo)
                .build();
    }

    private static Map<String, BigDecimal> totals(List<Object[]> rows) {
        Map<String, BigDecimal> result = new LinkedHashMap<>();
        for (Object[] row : rows) {
            String currencyCode = row[0] != null ? (String) row[0] : (String) row[1];
            result.merge(currencyCode, (BigDecimal) row[2], BigDecimal::add);
        }
        return result;
    }

    private static String uniqueSuffix(String prefix) {
        return prefix + Long.toUnsignedString(System.nanoTime(), 36);
    }

    private static String shortCode(String prefix, String value, int maxLength) {
        String code = (prefix + value).replaceAll("[^A-Za-z0-9]", "");
        return code.length() <= maxLength ? code : code.substring(code.length() - maxLength);
    }

    private record Dictionaries(Dictionary branchType, Dictionary country, Dictionary status) {
    }

    private record Seed(
            Company company,
            Branch vault,
            Branch partner,
            Worker worker,
            Dictionaries dictionaries,
            Currency eur,
            Currency usd,
            Currency huf) {
        private Seed withWorker(Worker replacement) {
            return new Seed(company, vault, partner, replacement, dictionaries, eur, usd, huf);
        }
    }
}
