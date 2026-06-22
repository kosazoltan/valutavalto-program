package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ExchangeRate;
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
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-041: az {@link ExchangeRateRepository#findAllActiveRates} BRANCH-FIRST rendezését valós
 * PostgreSQL-en igazolja. A területi munkacsoport-árfolyam nézet
 * ({@code RateCreationService.getTerritoryWorkgroupRates}) ezen az ORDER BY-on keresztül választja
 * valutánként a REPREZENTATÍV pénztár branch-specifikus rátáját a globális fallback helyett
 * (a service oldalon {@code putIfAbsent} first-wins).
 *
 * <p>A branch-precedencia kizárólag az SQL ORDER BY záradékban él:
 * {@code CASE WHEN er.branch.id = :branchId THEN 0 ELSE 1 END}. A {@code RateCreationServiceTest}
 * a repót mockolja, így ezt a tényleges rendezést NEM fedi — ha valaki megfordítaná (globális előre),
 * az értéktáros read-only nézet némán a FALLBACK rátát mutatná. Ez az IT elkapja a regressziót.</p>
 *
 * <p>Docker szükséges — lokálisan tipikusan nem fut, CI-ben igen (lásd
 * {@code WorkerRepositoryPostgresLockIT}, {@code SeededPostgresAcceptanceIT}).</p>
 */
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
class ExchangeRateRepositoryFindAllActiveRatesPostgresIT {

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
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private ExchangeRateRepository exchangeRateRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("FK-041: findAllActiveRates a branch-specifikus rátát teszi a globális fallback ELÉ")
    void findAllActiveRates_ordersBranchSpecificBeforeGlobalFallback() {
        transactionTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            LocalDate today = LocalDate.now();
            String suffix = Long.toString(System.nanoTime());

            Company company = companyRepository.save(Company.builder()
                    .code(shortCode("C", suffix))
                    .name("FK041 Co " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix)).name("Type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code(shortCode("CO", suffix)).name("Hungary").createdAt(now).build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code(shortCode("BS", suffix)).name("Active").createdAt(now).build());

            Branch branch = branchRepository.save(Branch.builder()
                    .code(shortCode("BR", suffix))
                    .company(company)
                    .bankCode("FK041BANK")
                    .branchType(branchType)
                    .name("FK041 Branch")
                    .address("Acceptance Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(branchStatus)
                    .openingDate(today)
                    .createdAt(now)
                    .build());

            Currency eur = currencyRepository.findByCode("EUR").orElseGet(() ->
                    currencyRepository.saveAndFlush(Currency.builder()
                            .code("EUR").name("Euro").symbol("EUR").decimalPlaces(2)
                            .active(true).displayOrder(2).createdAt(now).build()));

            // Branch-specifikus EUR ráta (343) — ennek kell ELŐL lennie a branch-scope-olt lekérdezésben.
            exchangeRateRepository.save(ExchangeRate.builder()
                    .company(company).branch(branch).currency(eur)
                    .validDate(today).validTime(LocalTime.of(15, 12))
                    .baseBuyRate(new BigDecimal("343.0000")).baseSellRate(new BigDecimal("362.9900"))
                    .officialRate(new BigDecimal("352.6800")).active(true).createdAt(now).build());
            // Globális (branch IS NULL) fallback EUR ráta (340) — ennek HÁTUL kell lennie.
            exchangeRateRepository.save(ExchangeRate.builder()
                    .company(company).branch(null).currency(eur)
                    .validDate(today).validTime(LocalTime.of(15, 12))
                    .baseBuyRate(new BigDecimal("340.0000")).baseSellRate(new BigDecimal("366.0000"))
                    .officialRate(new BigDecimal("352.6800")).active(true).createdAt(now).build());
            exchangeRateRepository.flush();

            List<ExchangeRate> rates =
                    exchangeRateRepository.findAllActiveRates(company.getId(), branch.getId());

            assertThat(rates)
                    .as("a branch-specifikus ÉS a globális EUR ráta is visszajön")
                    .hasSize(2);
            assertThat(rates.get(0).getBranch())
                    .as("a branch-specifikus rátának ELŐL kell lennie (ORDER BY CASE branch-first)")
                    .isNotNull();
            assertThat(rates.get(0).getBaseBuyRate())
                    .as("az első találat a branch-specifikus ráta (343), nem a globális fallback (340)")
                    .isEqualByComparingTo("343.0000");
            assertThat(rates.get(1).getBranch())
                    .as("a globális fallback (branch IS NULL) a branch-specifikus mögött")
                    .isNull();
        });
    }

    private static String shortCode(String prefix, String value) {
        String digits = value.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return prefix + tail;
    }
}
