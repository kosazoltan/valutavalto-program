package hu.puzzleir.valuta.migration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.SQLWarning;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

/**
 * FK-070 Fázis 2: a V368 cash_balance-korrekció célzott integrációs tesztje.
 *
 * <p>A migráció a BR035 (EBC) fiók EUR/USD egyenlegét korrigálja egész értékre,
 * KIZÁRÓLAG ha az ismert hibás érték (EUR 14334.45 / USD 5797.57) áll benne.
 * A teszt a migráció előtti/utáni állapotot hasonlítja össze a két érintett sorra,
 * és igazolja a nem érintett fiók/valuta változatlanságát (FR-1/FR-2), a lookup
 * {@code is_active=TRUE} szűrését, az őrfeltétel-védelmet (FR-3), az idempotenciát
 * (NFR-1) és a RAISE NOTICE jelzéseket (FR-6). A migrációs fájlt NÉV-MINTA alapján
 * keresi (fk070 + cash_balance), így a V-szám esetleges átszámozása nem töri a tesztet.</p>
 *
 * <p>Megjegyzés (Codex-review): "másik cég azonos BR035 kódú fiókja" teszt-eset
 * SZÁNDÉKOSAN nincs — a {@code branch.code} GLOBÁLISAN egyedi ({@code uk_branch_code},
 * V0_1 + Branch entitás {@code unique=true}, l. V277 kommentár), így ez a forgatókönyv
 * sémailag előállíthatatlan; a migráció company-szűrője e mellett defense-in-depth.</p>
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
class CashBalanceCorrectionFk070MigrationPostgresTest {

    private static final LocalDateTime NOW = LocalDate.of(2026, 7, 30).atTime(9, 0);
    private static final BigDecimal EUR_BAD = new BigDecimal("14334.45");
    private static final BigDecimal EUR_FIXED = new BigDecimal("14334.00");
    private static final BigDecimal USD_BAD = new BigDecimal("5797.57");
    private static final BigDecimal USD_FIXED = new BigDecimal("5797.00");

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
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void cleanState() {
        // A migráció fixen az EBC/BR035 kódokra keres, ezért tesztenként tiszta
        // company/branch/cash_balance állapot kell (a currency törzs megmaradhat).
        jdbcTemplate.update("DELETE FROM cash_balance");
        jdbcTemplate.update("DELETE FROM branch");
        jdbcTemplate.update("DELETE FROM company");
    }

    // =====================================================================
    // FR-1/FR-2 + scope-védelem: pontosan a két hibás sor korrigálódik
    // =====================================================================
    @Test
    @DisplayName("FR-1/FR-2: az EBC/BR035 EUR és USD hibás sora korrigálódik; más valuta és más fiók érintetlen")
    void korrigaljaAKetHibasSortEsMastNemErint() {
        transactionTemplate.executeWithoutResult(status -> {
            Company ebc = seedCompany("EBC");
            Branch br035 = seedBranch(ebc, "BR035", true);
            Branch br099 = seedBranch(ebc, "BR099", true);

            Currency eur = currency("EUR");
            Currency usd = currency("USD");
            Currency gbp = currency("GBP");

            seedBalance(ebc, br035, eur, EUR_BAD);
            seedBalance(ebc, br035, usd, USD_BAD);
            // Nem érintett valuta ugyanazon a fiókon:
            seedBalance(ebc, br035, gbp, new BigDecimal("500.00"));
            // Nem érintett fiók ugyanazzal a hibás értékkel (branch-scope bizonyíték):
            seedBalance(ebc, br099, eur, EUR_BAD);
        });

        List<String> notices = runMigration();

        assertThat(balance("EBC", "BR035", "EUR"))
                .as("Az EBC/BR035 EUR sor a korrekció után egész érték")
                .isEqualByComparingTo(EUR_FIXED);
        assertThat(balance("EBC", "BR035", "USD"))
                .as("Az EBC/BR035 USD sor a korrekció után egész érték")
                .isEqualByComparingTo(USD_FIXED);
        assertThat(balance("EBC", "BR035", "GBP"))
                .as("A nem érintett GBP sor változatlan")
                .isEqualByComparingTo("500.00");
        assertThat(balance("EBC", "BR099", "EUR"))
                .as("Másik fiók azonos hibás EUR értéke változatlan (branch-scope)")
                .isEqualByComparingTo(EUR_BAD);

        assertThat(notices)
                .as("A RAISE NOTICE pontosan 1-1 korrigált sort jelez EUR-ra és USD-re")
                .anySatisfy(n -> assertThat(n).contains("EUR 14334.45 -> 14334.00, 1 sor korrigalva"))
                .anySatisfy(n -> assertThat(n).contains("USD 5797.57 -> 5797.00, 1 sor korrigalva"));
    }

    // =====================================================================
    // NFR-1: idempotencia — második futás semmit nem változtat
    // =====================================================================
    @Test
    @DisplayName("NFR-1: a második futás 0 sort érint, az állapot (értékek + updated_at) bitre azonos marad")
    void masodikFutasSemmitNemValtoztat() {
        transactionTemplate.executeWithoutResult(status -> {
            Company ebc = seedCompany("EBC");
            Branch br035 = seedBranch(ebc, "BR035", true);
            seedBalance(ebc, br035, currency("EUR"), EUR_BAD);
            seedBalance(ebc, br035, currency("USD"), USD_BAD);
        });

        runMigration();
        List<Map<String, Object>> before = snapshotAllBalances();

        List<String> secondRunNotices = runMigration();
        List<Map<String, Object>> after = snapshotAllBalances();

        assertThat(after)
                .as("A második futás után minden cash_balance sor (érték és updated_at) változatlan")
                .isEqualTo(before);
        assertThat(secondRunNotices)
                .as("A második futás mindkét valutára 0 érintett sort jelez")
                .anySatisfy(n -> assertThat(n).contains("EUR korrekcio NEM futott le (0"))
                .anySatisfy(n -> assertThat(n).contains("USD korrekcio NEM futott le (0"));
    }

    // =====================================================================
    // FR-3: őrfeltétel — megváltozott egyenleghez nem nyúl, és jelzi
    // =====================================================================
    @Test
    @DisplayName("FR-3: ha az egyenleg nem a vart hibás érték, a korrekció nem fut le és RAISE NOTICE jelzi; a másik valuta őrfeltétele független")
    void orfeltetelVediAMegvaltozottEgyenleget() {
        transactionTemplate.executeWithoutResult(status -> {
            Company ebc = seedCompany("EBC");
            Branch br035 = seedBranch(ebc, "BR035", true);
            // EUR: NEM a vart hibás érték (időközben változott) -> nem nyúlhat hozzá
            seedBalance(ebc, br035, currency("EUR"), new BigDecimal("15334.45"));
            // USD: a vart hibás érték -> korrigálandó
            seedBalance(ebc, br035, currency("USD"), USD_BAD);
        });

        List<String> notices = runMigration();

        assertThat(balance("EBC", "BR035", "EUR"))
                .as("A megváltozott EUR egyenleghez a migráció nem nyúl")
                .isEqualByComparingTo("15334.45");
        assertThat(balance("EBC", "BR035", "USD"))
                .as("Az USD őrfeltétele független az EUR-tól: korrigálódik")
                .isEqualByComparingTo(USD_FIXED);
        assertThat(notices)
                .as("Az elmaradt EUR-korrekciót a NOTICE explicit jelzi (nem csendes)")
                .anySatisfy(n -> assertThat(n).contains("EUR korrekcio NEM futott le (0"));
    }

    // =====================================================================
    // Lookup-szűrés: INAKTÍV BR035 fiókhoz a migráció nem nyúl (is_active=TRUE
    // a feloldásban — a történelmi deaktivált duplikátum, l. V244, elleni védelem)
    // =====================================================================
    @Test
    @DisplayName("Lookup-szűrés: inaktív (is_active=FALSE) BR035 fiók hibás egyenlegéhez a migráció nem nyúl, és NOTICE jelzi a no-opot")
    void inaktivBr035EsetenNoOp() {
        transactionTemplate.executeWithoutResult(status -> {
            Company ebc = seedCompany("EBC");
            Branch inactiveBr035 = seedBranch(ebc, "BR035", false);
            seedBalance(ebc, inactiveBr035, currency("EUR"), EUR_BAD);
            seedBalance(ebc, inactiveBr035, currency("USD"), USD_BAD);
        });

        List<String> notices = runMigration();

        assertThat(balance("EBC", "BR035", "EUR"))
                .as("Az inaktív BR035 EUR egyenlege változatlan (a lookup is_active=TRUE-ra szűr)")
                .isEqualByComparingTo(EUR_BAD);
        assertThat(balance("EBC", "BR035", "USD"))
                .as("Az inaktív BR035 USD egyenlege változatlan")
                .isEqualByComparingTo(USD_BAD);
        assertThat(notices)
                .as("A NOTICE jelzi, hogy aktív BR035 nem található")
                .anySatisfy(n -> assertThat(n).contains("BR035 branch (EBC ceg) nem talalhato"));
    }

    // =====================================================================
    // Üres / idegen adatbázis: hiányzó BR035 mellett no-op, nem hibázik
    // =====================================================================
    @Test
    @DisplayName("Hiányzó EBC/BR035 fiók (pl. friss teszt-DB) esetén a migráció hibátlan no-op")
    void hianyzoBranchEsetenNoOp() {
        List<String> notices = runMigration();

        assertThat(notices)
                .as("A hiányzó fiókot a NOTICE jelzi, a migráció nem hibázik le")
                .anySatisfy(n -> assertThat(n).contains("BR035 branch (EBC ceg) nem talalhato"));
        assertThat(jdbcTemplate.queryForObject("SELECT count(*) FROM cash_balance", Integer.class))
                .isZero();
    }

    // ============================ HELPEREK ============================

    /** A FK-070 migrációs fájl név-minta alapú felkutatása (V-szám független). */
    private String loadMigrationSql() {
        try {
            Resource[] all = new PathMatchingResourcePatternResolver()
                    .getResources("classpath*:db/migration/V*.sql");
            List<Resource> hits = Arrays.stream(all)
                    .filter(r -> {
                        String name = r.getFilename();
                        return name != null
                                && name.toLowerCase().contains("fk070")
                                && name.toLowerCase().contains("cash_balance");
                    })
                    .toList();
            if (hits.size() != 1) {
                fail("FK-070: pontosan 1 db db/migration/V*__fk070*cash_balance*.sql fájl várt, talált: "
                        + hits.size());
            }
            return hits.get(0).getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /**
     * A migráció futtatása EGYETLEN utasításként (a DO $$ blokkot a script-splitter
     * pontosvesszőnél széttörné), a RAISE NOTICE üzenetek kigyűjtésével — a NOTICE a
     * Postgres JDBC-ben SQLWarning-láncként érkezik.
     */
    private List<String> runMigration() {
        String sql = loadMigrationSql();
        return jdbcTemplate.execute((ConnectionCallback<List<String>>) con -> {
            try (Statement st = con.createStatement()) {
                st.execute(sql);
                List<String> notices = new ArrayList<>();
                SQLWarning warning = st.getWarnings();
                while (warning != null) {
                    notices.add(warning.getMessage());
                    warning = warning.getNextWarning();
                }
                return notices;
            }
        });
    }

    private BigDecimal balance(String companyCode, String branchCode, String currencyCode) {
        return jdbcTemplate.queryForObject("""
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN branch b   ON b.id  = cb.branch_id
                  JOIN company co ON co.id = b.company_id
                  JOIN currency c ON c.id  = cb.currency_id
                 WHERE co.code = ? AND b.code = ? AND c.code = ?
                """, BigDecimal.class, companyCode, branchCode, currencyCode);
    }

    private List<Map<String, Object>> snapshotAllBalances() {
        return jdbcTemplate.queryForList(
                "SELECT id, current_balance, updated_at FROM cash_balance ORDER BY id");
    }

    private Company seedCompany(String code) {
        return companyRepository.save(Company.builder()
                .code(code)
                .name("FK-070 teszt ceg " + code)
                .createdAt(NOW)
                .build());
    }

    private Branch seedBranch(Company company, String code, boolean active) {
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code("FK070-BT-" + suffix).name("FK-070 branch type").createdAt(NOW).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code("FK070-CO-" + suffix).name("Hungary").createdAt(NOW).build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code("FK070-BS-" + suffix).name("Active").createdAt(NOW).build());
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("FK070")
                .branchType(branchType)
                .name("FK-070 Branch " + code + " " + suffix)
                .address("Teszt utca 1")
                .city("Szeged")
                .zipCode("6720")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(active)
                .openingDate(NOW.toLocalDate())
                .createdAt(NOW)
                .build());
    }

    private Currency currency(String code) {
        return currencyRepository.findByCode(code)
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code(code)
                        .name("FK-070 " + code)
                        .symbol(code)
                        .decimalPlaces(2)
                        .active(true)
                        .createdAt(NOW)
                        .build()));
    }

    private void seedBalance(Company company, Branch branch, Currency currency, BigDecimal amount) {
        cashBalanceRepository.save(CashBalance.builder()
                .company(company)
                .branch(branch)
                .currency(currency)
                .currentBalance(amount)
                .createdAt(NOW)
                .build());
    }
}
