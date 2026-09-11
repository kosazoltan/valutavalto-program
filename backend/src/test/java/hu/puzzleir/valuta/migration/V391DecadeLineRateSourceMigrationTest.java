package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FKH-063 / V391 — rate provenance columns on {@code decade_report_line}.
 *
 * <p>Proves the three properties the migration must have: legacy rows keep {@code NULL}
 * provenance (no fabricated audit claim), the CHECK constraint accepts only the two legal
 * markers, and a second {@code migrate()} is a no-op (the guarded DO block must not fail on a
 * constraint that already exists — PostgreSQL has no
 * {@code ALTER TABLE ... ADD CONSTRAINT IF NOT EXISTS}).</p>
 */
@Testcontainers
class V391DecadeLineRateSourceMigrationTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID REPORT_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID LEGACY_LINE_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V391 adds nullable provenance columns, keeps legacy rows NULL, enforces the marker CHECK and is idempotent")
    void addsProvenanceColumnsWithCheckAndKeepsLegacyRowsNull() throws Exception {
        migrateToVersion("390");

        try (Connection connection = openConnection()) {
            seedCompany(connection);
            seedBranch(connection);
            seedDecadeReport(connection);
            // A line written BEFORE V391 — it has no provenance information at all.
            seedDecadeReportLine(connection, LEGACY_LINE_ID, "EUR");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            // 1. Legacy row keeps NULL provenance: "unknown" is the honest value, and a backfill
            //    stamping 'MNB' on it would fabricate a statutory claim.
            assertThat(queryForString(connection,
                    "SELECT opening_rate_source FROM decade_report_line WHERE id = ?", LEGACY_LINE_ID))
                    .isNull();
            assertThat(queryForString(connection,
                    "SELECT closing_rate_source FROM decade_report_line WHERE id = ?", LEGACY_LINE_ID))
                    .isNull();

            // 2. Both columns are nullable (a zero-stock line resolves no rate at all).
            assertThat(queryForString(connection, """
                    SELECT is_nullable FROM information_schema.columns
                     WHERE table_name = 'decade_report_line' AND column_name = 'opening_rate_source'
                    """)).isEqualTo("YES");
            assertThat(queryForString(connection, """
                    SELECT is_nullable FROM information_schema.columns
                     WHERE table_name = 'decade_report_line' AND column_name = 'closing_rate_source'
                    """)).isEqualTo("YES");

            // 3. Both legal markers are accepted.
            UUID mnbLine = UUID.randomUUID();
            insertLineWithSources(connection, mnbLine, "USD", "MNB", "MNB");
            UUID manualLine = UUID.randomUUID();
            insertLineWithSources(connection, manualLine, "BAM", "MANUAL_SETTLEMENT", "MANUAL_SETTLEMENT");
            assertThat(queryForString(connection,
                    "SELECT closing_rate_source FROM decade_report_line WHERE id = ?", manualLine))
                    .isEqualTo("MANUAL_SETTLEMENT");

            // 4. Any other source is rejected by the CHECK — RAIFFEISEN rows live in the shared
            //    rate cache and must never appear as a decade valuation source. (PostgreSQL
            //    reports whichever of the two constraints it evaluates first, so assert on the
            //    shared prefix.)
            assertThatThrownBy(() -> insertLineWithSources(
                    connection, UUID.randomUUID(), "RSD", "RAIFFEISEN", "RAIFFEISEN"))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("ck_decade_report_line_")
                    .hasMessageContaining("_rate_source");

            // ...and each column is guarded on its own.
            assertThatThrownBy(() -> insertLineWithSources(
                    connection, UUID.randomUUID(), "RSD", "RAIFFEISEN", "MNB"))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("ck_decade_report_line_opening_rate_source");
            assertThatThrownBy(() -> insertLineWithSources(
                    connection, UUID.randomUUID(), "RSD", "MNB", "RAIFFEISEN"))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("ck_decade_report_line_closing_rate_source");
        }

        // 5. Re-running the whole chain is a no-op (the DO-block guard, not ADD CONSTRAINT).
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForInteger(connection, """
                    SELECT count(*) FROM pg_constraint
                     WHERE conname IN ('ck_decade_report_line_opening_rate_source',
                                       'ck_decade_report_line_closing_rate_source')
                    """)).isEqualTo(2);
            assertThat(queryForString(connection,
                    "SELECT opening_rate_source FROM decade_report_line WHERE id = ?", LEGACY_LINE_ID))
                    .isNull();
        }
    }

    private static void migrateToVersion(String version) {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion(version))
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

    private static Connection openConnection() throws SQLException {
        return DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void seedCompany(Connection connection) throws SQLException {
        execute(connection, "INSERT INTO company (id, code, name) VALUES (?, ?, ?)",
                COMPANY_ID, "FKH063", "FKH-063 Test Co");
    }

    private static void seedBranch(Connection connection) throws SQLException {
        // Unique suffix: the migration chain itself seeds branches, and branch.code is UNIQUE
        // (uk_branch_code).
        execute(connection, "INSERT INTO branch (id, company_id, code, name) VALUES (?, ?, ?, ?)",
                BRANCH_ID, COMPANY_ID, "ZZFKH063", "FKH-063 Test Branch");
    }

    private static void seedDecadeReport(Connection connection) throws SQLException {
        execute(connection, """
                INSERT INTO decade_report (id, branch_id, year, decade)
                VALUES (?, ?, 2026, 25)
                """, REPORT_ID, BRANCH_ID);
    }

    private static void seedDecadeReportLine(Connection connection, UUID id, String currency) throws SQLException {
        execute(connection, """
                INSERT INTO decade_report_line (id, decade_report_id, currency_code)
                VALUES (?, ?, ?)
                """, id, REPORT_ID, currency);
    }

    private static void insertLineWithSources(Connection connection, UUID id, String currency,
                                              String openingSource, String closingSource) throws SQLException {
        execute(connection, """
                INSERT INTO decade_report_line
                    (id, decade_report_id, currency_code, opening_rate_source, closing_rate_source)
                VALUES (?, ?, ?, ?, ?)
                """, id, REPORT_ID, currency, openingSource, closingSource);
    }

    private static void execute(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static Integer queryForInteger(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("integer query returned a row").isTrue();
                return resultSet.getInt(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? resultSet.getString(1) : null;
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
