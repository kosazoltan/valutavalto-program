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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-029 FR-5: a V372 migráció (holt CASHIER {@code currency_stock} sorok törlése)
 * integrációs tesztje valós Flyway-runnerrel.
 *
 * <p>A migráció hármas védelmét bizonyítjuk — ELŐ adat semmiképp ne törlődjön:
 * <ul>
 *   <li>holt sor (inaktív fiók + nulla cash_balance + 2026-04-01 előtti) → TÖRÖLVE</li>
 *   <li>AKTÍV fiók CASHIER sora → MEGMARAD</li>
 *   <li>nem-nulla {@code cash_balance}-ú pár → MEGMARAD</li>
 *   <li>friss ({@code last_updated} 2026-04-01 utáni) sor → MEGMARAD</li>
 *   <li>{@code entity_type='VAULT'} sorok → ÉRINTETLENEK</li>
 *   <li>idempotencia: második futás 0 sort töröl</li>
 * </ul>
 */
@Testcontainers
class Fkh029DeadCashierStockDeletionPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V372_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh029_holt_cashier.*\\.sql$");

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
    @DisplayName("V372: a holt CASHIER sor törlődik, de az aktív fiók / nem-nulla cash_balance / friss sor MEGMARAD, a VAULT réteg érintetlen")
    void v372TorliAHoltSorokat_deAzEloketMegtartja() throws Exception {
        migrateToVersion(version(V372_FILE_PATTERN) - 1);

        UUID inactiveBranchId;
        UUID activeBranchId;
        UUID companyId;
        long vaultRowsBefore;

        try (Connection connection = openConnection()) {
            SeededBranch active = resolveSeededBranch(connection, "BR035");
            activeBranchId = active.branchId();
            companyId = active.companyId();

            // Egy INAKTÍV fiók előállítása (a KORUT/TISZA prod-mintázat).
            inactiveBranchId = insertInactiveBranch(connection, companyId, "ZZTEST");

            // (a) HOLT sor: inaktív fiók, nincs cash_balance, régi időbélyeg → TÖRLENDŐ
            insertCashierStock(connection, companyId, inactiveBranchId, "EUR",
                    new BigDecimal("5200"), "2026-03-16 12:51:15");

            // (b) INAKTÍV fiók, de NEM-NULLA cash_balance → MEGMARAD
            insertCashierStock(connection, companyId, inactiveBranchId, "USD",
                    new BigDecimal("4100"), "2026-03-16 12:51:15");
            upsertBalance(connection, companyId, inactiveBranchId, "USD", new BigDecimal("123.45"));

            // (c) AKTÍV fiók CASHIER sora → MEGMARAD
            insertCashierStock(connection, companyId, activeBranchId, "EUR",
                    new BigDecimal("999"), "2026-03-16 12:51:15");

            // (d) INAKTÍV fiók, de FRISS időbélyeg (2026-04-01 után) → MEGMARAD
            insertCashierStock(connection, companyId, inactiveBranchId, "GBP",
                    new BigDecimal("77"), "2026-07-01 08:00:00");

            vaultRowsBefore = queryForLong(connection,
                    "SELECT count(*) FROM currency_stock WHERE entity_type = 'VAULT'");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            // (a) törölve
            assertThat(cashierStockExists(connection, inactiveBranchId, "EUR"))
                    .as("A holt sor (inaktív fiók, nulla cash_balance, régi seed) törlődik")
                    .isFalse();

            // (b) megmaradt — nem-nulla könyvelési egyenleg
            assertThat(cashierStockExists(connection, inactiveBranchId, "USD"))
                    .as("Nem-nulla cash_balance-ú pár sora MEGMARAD (könyvelési nyom)")
                    .isTrue();

            // (c) megmaradt — aktív fiók
            assertThat(cashierStockExists(connection, activeBranchId, "EUR"))
                    .as("AKTÍV fiók CASHIER sora MEGMARAD (élő adat védelme)")
                    .isTrue();

            // (d) megmaradt — friss időbélyeg
            assertThat(cashierStockExists(connection, inactiveBranchId, "GBP"))
                    .as("2026-04-01 utáni sor MEGMARAD (nem seed-generáció)")
                    .isTrue();

            // VAULT réteg érintetlen
            assertThat(queryForLong(connection,
                    "SELECT count(*) FROM currency_stock WHERE entity_type = 'VAULT'"))
                    .as("A VAULT réteg sorszáma változatlan — a migráció kizárólag CASHIER-t érint")
                    .isEqualTo(vaultRowsBefore);
        }

        // Idempotencia: második futás 0 sort töröl.
        List<String> notices = runRawCollectingNotices(V372_FILE_PATTERN);
        assertThat(notices)
                .as("A második futás 0 törölt sort jelent (idempotens)")
                .anySatisfy(n -> assertThat(n).contains("0 holt CASHIER currency_stock sor torolve"));
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

    /** Inaktív fiók a KORUT/TISZA prod-mintázatra (is_active=FALSE, nem vault). */
    private static UUID insertInactiveBranch(Connection connection, UUID companyId, String code)
            throws Exception {
        UUID id = UUID.randomUUID();
        execute(connection, """
                INSERT INTO branch (id, company_id, code, name, is_active, is_vault, created_at)
                VALUES (?, ?, ?, ?, FALSE, FALSE, NOW())
                """, id, companyId, code, "Teszt inaktív fiók " + code);
        return id;
    }

    private static void insertCashierStock(Connection connection, UUID companyId, UUID branchId,
                                          String currencyCode, BigDecimal quantity,
                                          String lastUpdated) throws Exception {
        execute(connection, """
                INSERT INTO currency_stock
                    (company_id, entity_type, entity_id, currency_code, quantity,
                     weighted_avg_cost, last_updated)
                VALUES (?, 'CASHIER', ?, ?, ?, 1, CAST(? AS TIMESTAMP))
                """, companyId, branchId.toString(), currencyCode, quantity, lastUpdated);
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
                    SET current_balance = EXCLUDED.current_balance
                """, companyId, branchId, currencyId, amount);
    }

    private static boolean cashierStockExists(Connection connection, UUID branchId, String currencyCode)
            throws Exception {
        return queryForLong(connection, """
                SELECT count(*) FROM currency_stock
                 WHERE entity_type = 'CASHIER' AND entity_id = ? AND currency_code = ?
                """, branchId.toString(), currencyCode) > 0;
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
