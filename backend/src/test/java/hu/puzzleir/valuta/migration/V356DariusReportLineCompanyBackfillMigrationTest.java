package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class V356DariusReportLineCompanyBackfillMigrationTest {

    private static final UUID COMPANY_1_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_2_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID BRANCH_1_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID BRANCH_2_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final UUID REPORT_1_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");
    private static final UUID REPORT_2_ID = UUID.fromString("66666666-6666-6666-6666-666666666666");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V356 a Darius riport sorokat a szülő cégére backfilleli és idempotensen szigorítja")
    void backfillsReportLineCompanyFromParentAndAddsTenantIndexIdempotently() throws Exception {
        migrateToVersion355();

        try (Connection connection = openConnection()) {
            seedCompany(connection, COMPANY_1_ID, "BEST", "Best Change");
            seedCompany(connection, COMPANY_2_ID, "PANNON", "Pannon Váltó");
            seedBranch(connection, BRANCH_1_ID, COMPANY_1_ID, "B001", "Best iroda");
            seedBranch(connection, BRANCH_2_ID, COMPANY_2_ID, "P001", "Pannon iroda");
            seedReport(connection, REPORT_1_ID, COMPANY_1_ID, LocalDate.of(2026, 7, 10));
            seedReport(connection, REPORT_2_ID, COMPANY_2_ID, LocalDate.of(2026, 7, 11));
            seedLine(connection, REPORT_1_ID, BRANCH_1_ID, "EUR");
            seedLine(connection, REPORT_1_ID, BRANCH_1_ID, "USD");
            seedLine(connection, REPORT_2_ID, BRANCH_2_ID, "EUR");
            seedLine(connection, REPORT_2_ID, BRANCH_2_ID, "CHF");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForInteger(connection,
                    "SELECT COUNT(*) FROM darius_report_line WHERE company_id = ?", COMPANY_1_ID))
                    .isEqualTo(2);
            assertThat(queryForInteger(connection,
                    "SELECT COUNT(*) FROM darius_report_line WHERE company_id = ?", COMPANY_2_ID))
                    .isEqualTo(2);
            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM darius_report_line l
                      JOIN darius_daily_report r ON r.id = l.report_id
                     WHERE l.company_id <> r.company_id
                    """))
                    .isZero();
            assertThat(queryForString(connection, """
                    SELECT is_nullable
                      FROM information_schema.columns
                     WHERE table_schema = 'public'
                       AND table_name = 'darius_report_line'
                       AND column_name = 'company_id'
                    """))
                    .isEqualTo("NO");
            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM pg_indexes
                     WHERE schemaname = 'public'
                       AND tablename = 'darius_report_line'
                       AND indexname = 'ix_darius_line_company_report'
                    """))
                    .isEqualTo(1);

            int beforeRerunCount = queryForInteger(connection, "SELECT COUNT(*) FROM darius_report_line");
            rerunV356SqlDirectly(connection);

            assertThat(queryForInteger(connection, "SELECT COUNT(*) FROM darius_report_line"))
                    .isEqualTo(beforeRerunCount);
            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM darius_report_line l
                      JOIN darius_daily_report r ON r.id = l.report_id
                     WHERE l.company_id <> r.company_id
                    """))
                    .isZero();
        }
    }

    private static void migrateToVersion355() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("355"))
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

    private static void seedCompany(Connection connection, UUID id, String code, String name) throws SQLException {
        execute(connection, "INSERT INTO company (id, code, name) VALUES (?, ?, ?)", id, code, name);
    }

    private static void seedBranch(Connection connection, UUID id, UUID companyId, String code, String name)
            throws SQLException {
        execute(connection, "INSERT INTO branch (id, company_id, code, name) VALUES (?, ?, ?, ?)",
                id, companyId, code, name);
    }

    private static void seedReport(Connection connection, UUID id, UUID companyId, LocalDate date)
            throws SQLException {
        execute(connection, """
                INSERT INTO darius_daily_report (id, company_id, report_date)
                VALUES (?, ?, ?)
                """, id, companyId, date);
    }

    private static void seedLine(Connection connection, UUID reportId, UUID branchId, String currencyCode)
            throws SQLException {
        execute(connection, """
                INSERT INTO darius_report_line (report_id, branch_id, branch_code, currency_code)
                VALUES (?, ?, 'TEST', ?)
                """, reportId, branchId, currencyCode);
    }

    private static void rerunV356SqlDirectly(Connection connection) throws SQLException, IOException {
        try (var stream = V356DariusReportLineCompanyBackfillMigrationTest.class
                .getClassLoader()
                .getResourceAsStream("db/migration/V356__darius_report_line_company_id.sql")) {
            assertThat(stream).as("V356 migration SQL elérhető legyen a classpath-on").isNotNull();
            String sql = new String(stream.readAllBytes(), StandardCharsets.UTF_8);
            try (Statement statement = connection.createStatement()) {
                statement.execute(sql);
            }
        }
    }

    private static void execute(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static Integer queryForInteger(Connection connection, String sql, Object... parameters)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("integer query returned a row").isTrue();
                return resultSet.getInt(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters)
            throws SQLException {
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
