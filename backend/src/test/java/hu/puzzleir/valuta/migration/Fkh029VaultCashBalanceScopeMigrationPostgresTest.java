package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLWarning;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-029 FR-1: a V371 migráció (értéktári {@code cash_balance} hatókör-teljesítés)
 * integrációs tesztje valós Flyway-runnerrel — a V368/V369 migrációs-teszt precedens
 * mintájára (CI-ben fut; lokálisan Docker hiányában a Testcontainers-baseline része).
 *
 * <p>Amit bizonyít:
 * <ul>
 *   <li>MINDEN aktív {@code is_vault=TRUE} branch MINDEN aktív valutára kap sort, 0-val</li>
 *   <li>a meglévő sor értéke ÉS {@code updated_at}-ja érintetlen (BR020 V369-utáni állapot)</li>
 *   <li>inaktív vault-branch NEM kap sort (a V334 predikátum tükörképe)</li>
 *   <li>multi-tenant: a {@code company_id} a branch cégéből jön (cross-tenant szivárgás nincs)</li>
 *   <li>idempotencia: kézi újrafuttatás 0 sort ír (NOTICE-bizonyítékkal)</li>
 * </ul>
 */
@Testcontainers
class Fkh029VaultCashBalanceScopeMigrationPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V371_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh029_vault_cash_balance.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @BeforeEach
    void cleanDatabase() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .cleanDisabled(false)
                .load()
                .clean();
    }

    @Test
    @DisplayName("V371: minden aktív értéktári branch minden aktív valutára kap cash_balance sort 0-val; a meglévő sor értéke és updated_at-ja érintetlen; újrafuttatás 0 sort pótol")
    void v371PotoljaMindenAktivErtektarSorait() throws Exception {
        migrateToVersion(version(V371_FILE_PATTERN) - 1);

        UUID br020Id;
        UUID br020CompanyId;
        Timestamp seededUpdatedAt;
        List<UUID> activeVaultBranchIds;

        try (Connection connection = openConnection()) {
            SeededBranch br020 = resolveSeededBranch(connection, "BR020");
            br020Id = br020.branchId();
            br020CompanyId = br020.companyId();

            // A V369 már lefutott (a V371 előtti állapot): BR020-nak vannak sorai.
            // Egy sort NEM-nulla értékre állítunk — ehhez a V371 nem nyúlhat.
            upsertBalance(connection, br020CompanyId, br020Id, "EUR", new BigDecimal("777.77"));
            seededUpdatedAt = updatedAt(connection, br020Id, "EUR");

            activeVaultBranchIds = activeVaultBranchIds(connection);
            assertThat(activeVaultBranchIds)
                    .as("A migrált sémában kell lennie legalább egy aktív értéktári branchnek")
                    .isNotEmpty();
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            long activeCurrencies = queryForLong(connection,
                    "SELECT count(*) FROM currency WHERE is_active = TRUE");

            // 1. MINDEN aktív vault-branch minden aktív valutára kap sort.
            for (UUID branchId : activeVaultBranchIds) {
                long rows = queryForLong(connection, """
                        SELECT count(*) FROM cash_balance cb
                          JOIN currency c ON c.id = cb.currency_id
                         WHERE cb.branch_id = ? AND c.is_active = TRUE
                        """, branchId);
                assertThat(rows)
                        .as("A(z) %s értéktári branchnek minden aktív valutára van cash_balance sora",
                                branchId)
                        .isEqualTo(activeCurrencies);

                // 2. multi-tenant: a company_id a branch cégéből jön.
                long mismatched = queryForLong(connection, """
                        SELECT count(*) FROM cash_balance cb
                          JOIN branch b ON b.id = cb.branch_id
                         WHERE cb.branch_id = ? AND cb.company_id <> b.company_id
                        """, branchId);
                assertThat(mismatched)
                        .as("Egyetlen pótolt sor company_id-ja sem térhet el a branch cégétől (cross-tenant)")
                        .isZero();
            }

            // 3. A seedelt, NEM-nulla EUR sor értéke ÉS updated_at-ja érintetlen.
            assertThat(balance(connection, br020Id, "EUR"))
                    .as("A meglévő EUR sor értéke érintetlen (a migráció csak pótol)")
                    .isEqualByComparingTo("777.77");
            assertThat(updatedAt(connection, br020Id, "EUR"))
                    .as("A meglévő sor updated_at-ja sem módosul (NOT EXISTS szűrés)")
                    .isEqualTo(seededUpdatedAt);

            // 4. A pótolt sorok mind 0 nyitóértékűek — csak a seedelt EUR nem 0.
            long nonZeroOnVaults = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN branch b ON b.id = cb.branch_id
                     WHERE b.is_vault = TRUE AND b.is_active = TRUE AND cb.current_balance <> 0
                    """);
            assertThat(nonZeroOnVaults)
                    .as("Minden pótolt értéktári sor 0 értékű (kizárólag a seedelt EUR nem)")
                    .isEqualTo(1);

            long nonZeroOpening = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN branch b ON b.id = cb.branch_id
                     WHERE b.is_vault = TRUE AND b.is_active = TRUE AND cb.opening_balance <> 0
                    """);
            assertThat(nonZeroOpening)
                    .as("A pótolt sorok opening_balance-a is 0")
                    .isZero();

            // 5. INAKTÍV vault-branch NEM kap sort (a V334 predikátum tükörképe).
            long inactiveVaultRows = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN branch b ON b.id = cb.branch_id
                     WHERE b.is_vault = TRUE AND b.is_active = FALSE
                    """);
            assertThat(inactiveVaultRows)
                    .as("Inaktív értéktári branch nem kap pótolt sort (hatókör = V334 tükörképe)")
                    .isZero();
        }

        // 6. Idempotencia: kézi újrafuttatás 0 sort pótol, NOTICE-bizonyítékkal.
        List<String> notices = runRawCollectingNotices(V371_FILE_PATTERN);
        assertThat(notices)
                .as("A második futás 0 pótolt sort jelent (idempotens)")
                .anySatisfy(n -> assertThat(n).contains("osszesen 0 hianyzo cash_balance sor potolva"));
    }

    @Test
    @DisplayName("V371: a nem-vault (pénztári) branch-ek cash_balance sorai változatlanok — a migráció nem szór szét sorokat")
    void v371NemErintiANemVaultBranchEket() throws Exception {
        migrateToVersion(version(V371_FILE_PATTERN) - 1);

        long nonVaultRowsBefore;
        try (Connection connection = openConnection()) {
            nonVaultRowsBefore = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN branch b ON b.id = cb.branch_id
                     WHERE b.is_vault IS DISTINCT FROM TRUE
                    """);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            long nonVaultRowsAfter = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN branch b ON b.id = cb.branch_id
                     WHERE b.is_vault IS DISTINCT FROM TRUE
                    """);
            assertThat(nonVaultRowsAfter)
                    .as("A nem-vault branch-ek sorszáma változatlan (a V371 kizárólag vault-branchre ír)")
                    .isEqualTo(nonVaultRowsBefore);
        }
    }

    // ============================ FLYWAY HELPEREK ============================

    private static Path resolveMigration(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).as("Pontosan 1 migráció várt a mintára: %s", pattern).hasSize(1);
            return matches.get(0);
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Matcher matcher = pattern.matcher(resolveMigration(pattern).getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    private static void migrateToVersion(int version) {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion(String.valueOf(version)))
                .load()
                .migrate();
    }

    private static void migrateToLatest() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load()
                .migrate();
    }

    private static List<String> runRawCollectingNotices(Pattern pattern) throws Exception {
        String sql = Files.readString(resolveMigration(pattern), StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(sql);
            List<String> notices = new ArrayList<>();
            SQLWarning warning = statement.getWarnings();
            while (warning != null) {
                notices.add(warning.getMessage());
                warning = warning.getNextWarning();
            }
            return notices;
        }
    }

    // ============================ SQL HELPEREK ============================

    private record SeededBranch(UUID branchId, UUID companyId) {
    }

    private static SeededBranch resolveSeededBranch(Connection connection, String code) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT b.id, b.company_id
                  FROM branch b
                  JOIN company co ON co.id = b.company_id
                 WHERE b.code = ? AND co.code = 'EBC'
                """)) {
            statement.setString(1, code);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next())
                        .as("A migrált sémában léteznie kell a seedelt EBC/%s fióknak", code)
                        .isTrue();
                return new SeededBranch(
                        resultSet.getObject(1, UUID.class),
                        resultSet.getObject(2, UUID.class));
            }
        }
    }

    private static List<UUID> activeVaultBranchIds(Connection connection) throws Exception {
        List<UUID> ids = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT id FROM branch WHERE is_vault = TRUE AND is_active = TRUE ORDER BY code
                """);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                ids.add(resultSet.getObject(1, UUID.class));
            }
        }
        return ids;
    }

    private static void upsertBalance(Connection connection, UUID companyId, UUID branchId,
                                      String currencyCode, BigDecimal amount) throws Exception {
        long currencyId = queryForLong(connection,
                "SELECT id FROM currency WHERE code = ?", currencyCode);
        execute(connection, """
                INSERT INTO cash_balance
                    (company_id, branch_id, currency_id, current_balance, opening_balance,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 0, NOW(), NOW(), 0)
                ON CONFLICT (branch_id, currency_id) DO UPDATE
                    SET current_balance = EXCLUDED.current_balance,
                        updated_at = NOW()
                """, companyId, branchId, currencyId, amount);
    }

    private static BigDecimal balance(Connection connection, UUID branchId, String currencyCode)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE cb.branch_id = ? AND c.code = ?
                """)) {
            statement.setObject(1, branchId);
            statement.setString(2, currencyCode);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("cash_balance sor várt: %s", currencyCode).isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
    }

    private static Timestamp updatedAt(Connection connection, UUID branchId, String currencyCode)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT cb.updated_at
                  FROM cash_balance cb
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE cb.branch_id = ? AND c.code = ?
                """)) {
            statement.setObject(1, branchId);
            statement.setString(2, currencyCode);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("cash_balance sor várt: %s", currencyCode).isTrue();
                return resultSet.getTimestamp(1);
            }
        }
    }

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static long queryForLong(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws Exception {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
