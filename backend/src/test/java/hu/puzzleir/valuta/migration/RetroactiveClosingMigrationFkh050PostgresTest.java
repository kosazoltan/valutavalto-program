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
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FKH-050: retroactive closing — V386 (daily_session audit columns) +
 * V387 (date-aware denomination_balance unique key) migration test.
 *
 * <p>Claims under proof:</p>
 * <ul>
 *   <li>RED-repro: before V386 daily_session has no retroactive audit columns;
 *       before V387 the denomination_balance 4-column date-aware key is absent.</li>
 *   <li>V386: three columns with the planned types/defaults; existing rows get
 *       is_retroactive_closing=false; the worker FK is enforced.</li>
 *   <li>V387: uk_denom_balance_desk_denom_category_date exists, the old 3-column
 *       key is gone; same (desk, denom, category) on two dates succeeds, twice on
 *       the same date raises naming the new constraint.</li>
 *   <li>Both migrations are re-runnable (idempotent raw SQL).</li>
 * </ul>
 */
@Testcontainers
class RetroactiveClosingMigrationFkh050PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V386_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh050_daily_session_retroactive_audit.*\\.sql$");
    private static final Pattern V387_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh050_denomination_balance_date_key.*\\.sql$");

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

    // =====================================================================
    // RED-repro — the state BEFORE the migrations
    // =====================================================================

    @Test
    @DisplayName("RED-repro: before V386 daily_session has no is_retroactive_closing column")
    void redRepro_beforeV386NoAuditColumn() throws Exception {
        migrateToVersion(previousExistingVersion(V386_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            assertThat(columnExists(connection, "daily_session", "is_retroactive_closing"))
                    .as("before V386 the audit column must not exist")
                    .isFalse();
        }
    }

    @Test
    @DisplayName("RED-repro: before V387 the 4-column date-aware key does not exist")
    void redRepro_beforeV387NoDateKey() throws Exception {
        migrateToVersion(previousExistingVersion(V387_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintOn(connection, "denomination_balance",
                    new String[]{"cash_desk_id", "denomination_category", "denomination_id",
                            "submission_date"}))
                    .as("before V387 the 4-column key must not exist")
                    .isFalse();
        }
    }

    // =====================================================================
    // V386 — daily_session retroactive audit columns
    // =====================================================================

    @Test
    @DisplayName("V386: three audit columns exist with the planned types and defaults")
    void v386_auditColumnsExist() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(columnType(connection, "daily_session", "is_retroactive_closing"))
                    .isEqualTo("boolean");
            assertThat(columnDefault(connection, "daily_session", "is_retroactive_closing"))
                    .contains("false");
            assertThat(columnNullable(connection, "daily_session", "is_retroactive_closing"))
                    .as("is_retroactive_closing NOT NULL")
                    .isFalse();
            assertThat(columnType(connection, "daily_session", "retroactive_closed_by_worker_id"))
                    .isEqualTo("bigint");
            assertThat(columnNullable(connection, "daily_session", "retroactive_closed_by_worker_id"))
                    .as("retroactive_closed_by_worker_id nullable")
                    .isTrue();
            assertThat(columnType(connection, "daily_session", "retroactive_closed_at"))
                    .contains("timestamp");
        }
    }

    @Test
    @DisplayName("V386: existing rows get is_retroactive_closing=false")
    void v386_existingRowsDefaultFalse() throws Exception {
        migrateToVersion(previousExistingVersion(V386_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "RC1");
            UUID branchId = seedBranch(connection, companyId, "RCB1");
            insertDailySession(connection, companyId, branchId, java.time.LocalDate.now().minusDays(2));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForLong(connection,
                    "SELECT COUNT(*) FROM daily_session WHERE is_retroactive_closing = false"))
                    .as("every pre-existing row is NOT retroactive")
                    .isEqualTo(1);
            assertThat(queryForLong(connection,
                    "SELECT COUNT(*) FROM daily_session WHERE retroactive_closed_at IS NOT NULL"))
                    .isZero();
        }
    }

    @Test
    @DisplayName("V386: retroactive_closed_by_worker_id is a real FK to worker(id)")
    void v386_workerFkEnforced() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "FK1");
            UUID branchId = seedBranch(connection, companyId, "FKB1");
            long workerId = insertWorker(connection, companyId, branchId, "FKW1");
            insertDailySession(connection, companyId, branchId, java.time.LocalDate.now().minusDays(1));

            assertThatCode(() -> execute(connection,
                    "UPDATE daily_session SET retroactive_closed_by_worker_id = ?", workerId))
                    .as("a real worker id is accepted")
                    .doesNotThrowAnyException();

            assertThatThrownBy(() -> execute(connection,
                    "UPDATE daily_session SET retroactive_closed_by_worker_id = 99999999"))
                    .as("a bogus worker id violates the FK")
                    .isInstanceOf(SQLException.class);
        }
    }

    // =====================================================================
    // V387 — date-aware denomination unique key
    // =====================================================================

    @Test
    @DisplayName("V387: the 4-column date-aware key exists and the old 3-column key is gone")
    void v387_dateKeyReplacesOldKey() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintNamed(connection, "denomination_balance",
                    "uk_denom_balance_desk_denom_category_date"))
                    .as("the new 4-column constraint exists")
                    .isTrue();
            assertThat(uniqueConstraintOn(connection, "denomination_balance",
                    new String[]{"cash_desk_id", "denomination_id", "denomination_category"}))
                    .as("the old 3-column key is gone")
                    .isFalse();
        }
    }

    @Test
    @DisplayName("V387: same (desk, denom, category) on two dates succeeds;"
            + " twice on the same date raises naming the new constraint")
    void v387_twoDatesAllowedSameDateRejected() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "DK1");
            UUID branchId = seedBranch(connection, companyId, "DKB1");
            long currencyId = insertCurrency(connection, "FUX");
            long denominationId =
                    insertDenomination(connection, companyId, branchId, currencyId);
            java.time.LocalDate d1 = java.time.LocalDate.now().minusDays(3);
            java.time.LocalDate d2 = java.time.LocalDate.now().minusDays(2);

            insertDenominationBalance(connection, branchId, denominationId, d1);
            assertThatCode(() ->
                    insertDenominationBalance(connection, branchId, denominationId, d2))
                    .as("same key on a DIFFERENT submission_date succeeds")
                    .doesNotThrowAnyException();

            assertThatThrownBy(() ->
                    insertDenominationBalance(connection, branchId, denominationId, d1))
                    .as("same key on the SAME submission_date violates the new constraint")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uk_denom_balance_desk_denom_category_date");
        }
    }

    // =====================================================================
    // idempotency — both migrations re-runnable
    // =====================================================================

    @Test
    @DisplayName("V386/V387: raw SQL re-execution is idempotent")
    void migrationsAreIdempotent() throws Exception {
        migrateToLatest();

        String v386 = Files.readString(resolveMigration(V386_FILE_PATTERN),
                java.nio.charset.StandardCharsets.UTF_8);
        String v387 = Files.readString(resolveMigration(V387_FILE_PATTERN),
                java.nio.charset.StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute(v386);
            statement.execute(v386);
            statement.execute(v387);
            statement.execute(v387);
        }

        try (Connection connection = openConnection()) {
            assertThat(columnExists(connection, "daily_session", "is_retroactive_closing"))
                    .isTrue();
            assertThat(uniqueConstraintNamed(connection, "denomination_balance",
                    "uk_denom_balance_desk_denom_category_date"))
                    .isTrue();
        }
    }

    // ============================ ASSERT / SCHEMA HELPERS ============================

    private static boolean columnExists(Connection connection, String table, String column)
            throws Exception {
        return queryForLong(connection,
                "SELECT COUNT(*) FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ? AND column_name = ?",
                table, column) > 0;
    }

    private static String columnType(Connection connection, String table, String column)
            throws Exception {
        return queryForString(connection,
                "SELECT data_type FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ? AND column_name = ?",
                table, column);
    }

    private static String columnDefault(Connection connection, String table, String column)
            throws Exception {
        return queryForString(connection,
                "SELECT column_default FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ? AND column_name = ?",
                table, column);
    }

    private static boolean columnNullable(Connection connection, String table, String column)
            throws Exception {
        return "YES".equals(queryForString(connection,
                "SELECT is_nullable FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ? AND column_name = ?",
                table, column));
    }

    /** Does a UNIQUE constraint exist on exactly these columns (order-insensitive)? */
    private static boolean uniqueConstraintOn(Connection connection, String table, String[] columns)
            throws Exception {
        java.util.Arrays.sort(columns);
        StringBuilder arrayLiteral = new StringBuilder("ARRAY[");
        for (int i = 0; i < columns.length; i++) {
            if (i > 0) {
                arrayLiteral.append(',');
            }
            arrayLiteral.append('\'').append(columns[i]).append('\'');
        }
        arrayLiteral.append("]::text[]");
        return queryForLong(connection,
                "SELECT COUNT(*) FROM pg_constraint con"
                        + " JOIN pg_class rel ON rel.oid = con.conrelid"
                        + " WHERE rel.relname = ? AND con.contype = 'u'"
                        + " AND (SELECT array_agg(a.attname::text ORDER BY a.attname::text)"
                        + "        FROM unnest(con.conkey) AS k(attnum)"
                        + "        JOIN pg_attribute a ON a.attrelid = con.conrelid"
                        + "         AND a.attnum = k.attnum) = " + arrayLiteral,
                table) > 0;
    }

    private static boolean uniqueConstraintNamed(Connection connection, String table, String name)
            throws Exception {
        return queryForLong(connection,
                "SELECT COUNT(*) FROM pg_constraint con"
                        + " JOIN pg_class rel ON rel.oid = con.conrelid"
                        + " WHERE rel.relname = ? AND con.conname = ? AND con.contype = 'u'",
                table, name) > 0;
    }

    // ============================ FIXTURE HELPERS ============================

    private static UUID seedCompany(Connection connection, String suffix) throws Exception {
        UUID companyId = UUID.randomUUID();
        execute(connection,
                "INSERT INTO company (id, code, name, is_active, created_at)"
                        + " VALUES (?, ?, ?, true, NOW())",
                companyId, "FKH050" + suffix, "FKH-050 migration test company " + suffix);
        return companyId;
    }

    private static UUID seedBranch(Connection connection, UUID companyId, String code)
            throws Exception {
        UUID branchId = UUID.randomUUID();
        execute(connection,
                "INSERT INTO branch (id, code, company_id, name, is_active)"
                        + " VALUES (?, ?, ?, ?, true)",
                branchId, code, companyId, "FKH-050 test branch " + code);
        return branchId;
    }

    private static long insertWorker(Connection connection, UUID companyId, UUID branchId,
                                     String code) throws Exception {
        execute(connection,
                "INSERT INTO worker (company_id, code, name, password_hash, role, branch_id)"
                        + " VALUES (?, ?, ?, 'x', 'CASHIER', ?)",
                companyId, code, "FKH-050 test worker", branchId);
        return queryForLong(connection, "SELECT id FROM worker WHERE code = ?", code);
    }

    private static void insertDailySession(Connection connection, UUID companyId, UUID branchId,
                                           java.time.LocalDate date) throws Exception {
        execute(connection,
                "INSERT INTO daily_session (company_id, branch_id, session_date, status)"
                        + " VALUES (?, ?, ?, 'OPEN')",
                companyId, branchId, date);
    }

    private static long insertCurrency(Connection connection, String code) throws Exception {
        execute(connection,
                "INSERT INTO currency (code, name) VALUES (?, ?)",
                code, "FKH-050 test currency");
        return queryForLong(connection, "SELECT id FROM currency WHERE code = ?", code);
    }

    private static long insertDenomination(Connection connection, UUID companyId, UUID branchId,
                                           long currencyId) throws Exception {
        execute(connection,
                "INSERT INTO denomination (company_id, branch_id, currency_id, face_value,"
                        + " denomination_type) VALUES (?, ?, ?, 1000, 'BANKNOTE')",
                companyId, branchId, currencyId);
        return queryForLong(connection,
                "SELECT id FROM denomination WHERE company_id = ? AND currency_id = ?",
                companyId, currencyId);
    }

    private static void insertDenominationBalance(Connection connection, UUID branchId,
                                                  long denominationId, java.time.LocalDate date)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO denomination_balance"
                        + " (cash_desk_id, denomination_id, quantity, total_value,"
                        + "  denomination_category, submission_date)"
                        + " VALUES (?, ?, 1, 1000, 'EVENING', ?)")) {
            statement.setObject(1, branchId);
            statement.setLong(2, denominationId);
            statement.setDate(3, java.sql.Date.valueOf(date));
            statement.executeUpdate();
        }
    }

    // ============================ FLYWAY HELPERS ============================

    private static Path resolveMigration(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            java.util.List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("exactly one migration expected for pattern: %s", pattern)
                    .hasSize(1);
            return matches.get(0);
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Matcher matcher = pattern.matcher(resolveMigration(pattern).getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    /**
     * The really existing migration version BEFORE the given one — the naive
     * {@code version - 1} breaks when the numbering has gaps.
     */
    private static int previousExistingVersion(Pattern pattern) throws IOException {
        int target = version(pattern);
        Pattern anyMigration = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> anyMigration.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError(
                            "no migration exists before V" + target));
        }
    }

    private static void migrateToVersion(int version) {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion(String.valueOf(version)))
                .load()
                .migrate();
    }

    private void migrateToLatest() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load()
                .migrate();
    }

    // ============================ SQL HELPERS ============================

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static long queryForLong(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("one row expected: %s", sql).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("one row expected: %s", sql).isTrue();
                return resultSet.getString(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
