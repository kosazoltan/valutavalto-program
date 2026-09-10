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
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FKH-061 (A4, Defect B): closing_wizard.wizard_status must accept EXPIRED.
 *
 * <p>Production evidence: a CHECK constraint named {@code closing_wizard_wizard_status_check}
 * allows only IN_PROGRESS/COMPLETED/FAILED/CANCELLED, so the scheduled
 * {@code autoExpireStaleWizards} write of EXPIRED aborts every 30 minutes with SQLSTATE 23514
 * inside a poisoned transaction (25P02 afterwards). V75 created the column with NO check
 * constraint — the production constraint is out-of-Flyway drift — so V389 must repair BOTH
 * shapes: DROP CONSTRAINT IF EXISTS + ADD CONSTRAINT over all five enum values.</p>
 *
 * <p>RED repro: at V388 with the prod-shaped 4-value constraint applied as a fixture,
 * UPDATE ... SET wizard_status='EXPIRED' is rejected. After migrating to latest (V389) the same
 * update succeeds, 'BOGUS' is still rejected, and re-running the V389 SQL is idempotent.</p>
 *
 * <p>Service-level coverage of autoExpireStaleWizards (count + CLOSING_WIZARD_AUTO_EXPIRED audit)
 * already exists in ClosingWizardStaleSessionFk065Test — not duplicated here.</p>
 */
@Testcontainers
class ClosingWizardExpiredStatusV389PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__.*wizard_status.*\\.sql$");

    /** The prod-shaped drifted constraint: only 4 of the 5 WizardStatus values. */
    private static final String PROD_DRIFT_CONSTRAINT =
            "ALTER TABLE closing_wizard ADD CONSTRAINT closing_wizard_wizard_status_check "
            + "CHECK (wizard_status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED'))";

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
    @DisplayName("RED repro: at V388 with the prod-shaped constraint, EXPIRED is rejected")
    void prodShapedConstraintRejectsExpired() throws Exception {
        migrateToVersion(previousExistingVersion(FILE_PATTERN));
        try (Connection connection = open()) {
            try (Statement st = connection.createStatement()) {
                st.execute(PROD_DRIFT_CONSTRAINT);
            }
            seedWizard(connection);

            assertThatThrownBy(() -> updateStatus(connection, "EXPIRED"))
                    .isInstanceOf(SQLException.class)
                    .satisfies(e -> assertThat(((SQLException) e).getSQLState())
                            .isEqualTo("23514")); // check_violation
            // The four legacy values keep working — only EXPIRED was locked out.
            assertThatCode(() -> updateStatus(connection, "COMPLETED")).doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("migrate to latest: EXPIRED accepted, BOGUS still rejected")
    void latestAcceptsExpiredRejectsBogus() throws Exception {
        migrateToLatest();
        try (Connection connection = open()) {
            seedWizard(connection);

            assertThatCode(() -> updateStatus(connection, "EXPIRED")).doesNotThrowAnyException();
            assertThatThrownBy(() -> updateStatus(connection, "BOGUS"))
                    .isInstanceOf(SQLException.class)
                    .satisfies(e -> assertThat(((SQLException) e).getSQLState())
                            .isEqualTo("23514"));
        }
    }

    @Test
    @DisplayName("re-running the V389 SQL is idempotent on both shapes")
    void sqlIdempotent() throws Exception {
        migrateToLatest();
        Path file = matchingFile();
        String sql = Files.readString(file);
        try (Connection connection = open()) {
            // Shape 1 (fresh Flyway DB, constraint already added by V389): re-run is a no-op pair.
            assertThatCode(() -> {
                try (Statement st = connection.createStatement()) {
                    st.execute(sql);
                }
            }).doesNotThrowAnyException();
            // Shape 2 (prod drift): re-add the 4-value prod constraint, then re-run V389 SQL.
            try (Statement st = connection.createStatement()) {
                st.execute("ALTER TABLE closing_wizard DROP CONSTRAINT IF EXISTS closing_wizard_wizard_status_check");
                st.execute(PROD_DRIFT_CONSTRAINT);
                st.execute(sql);
            }
            seedWizard(connection);
            assertThatCode(() -> updateStatus(connection, "EXPIRED")).doesNotThrowAnyException();
        }
    }

    @Test
    @DisplayName("V389 filename matches pattern and version > V388")
    void filenameAndVersion() throws Exception {
        assertThat(version(FILE_PATTERN)).isGreaterThan(388);
    }

    // ============ helpers ============

    /** Minimal FK-valid chain: company → branch → worker → closing_wizard. */
    private static void seedWizard(Connection connection) throws SQLException {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        try (Statement st = connection.createStatement()) {
            st.execute("INSERT INTO company (id, code, name) VALUES ('" + companyId + "', 'FKH061C', 'FKH-061 test company')");
            st.execute("INSERT INTO branch (id, code, company_id, name) VALUES ('"
                    + branchId + "', 'FKH061B', '" + companyId + "', 'FKH-061 test branch')");
            st.execute("INSERT INTO worker (id, company_id, code, name, password_hash, role, branch_id) "
                    + "VALUES (990001, '" + companyId + "', 'FKH061', 'FKH-061 test worker', 'x', 'CASHIER', '"
                    + branchId + "')");
            st.execute("INSERT INTO closing_wizard (branch_id, closing_date, closing_type, "
                    + "started_by_worker_id, started_at) VALUES ('" + branchId
                    + "', '2026-09-01', 'DAILY', 990001, CURRENT_TIMESTAMP)");
        }
    }

    private static void updateStatus(Connection connection, String status) throws SQLException {
        try (Statement st = connection.createStatement()) {
            st.executeUpdate("UPDATE closing_wizard SET wizard_status = '" + status + "'");
        }
    }

    private static Path matchingFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).hasSize(1);
            return matches.get(0);
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Path file = matchingFile();
        Matcher matcher = pattern.matcher(file.getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    private static int previousExistingVersion(Pattern pattern) throws IOException {
        int target = version(pattern);
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError("no migration before V" + target));
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

    private static void migrateToLatest() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load()
                .migrate();
    }

    private static Connection open() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }
}
