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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class V352IncomeProofRecipientsBackfillMigrationTest {

    private static final String RECIPIENTS_KEY = "INCOME_PROOF_DOC_RECIPIENTS";
    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_2_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID ORPHAN_COMPANY_ID = UUID.fromString("99999999-9999-9999-9999-999999999999");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V352 a legacy jovedelmi igazolas cimzett kulcsokat company_id-ra backfilleli idempotensen")
    void backfillsLegacyIncomeProofRecipientsKeysToCompanyScopedRowsIdempotently() throws Exception {
        migrateToVersion351();

        try (Connection connection = openConnection()) {
            seedCompany(connection, COMPANY_ID, "BEST", "Best Change");
            insertSystemParameter(connection, RECIPIENTS_KEY + "." + COMPANY_ID,
                    "a@x.hu,b@x.hu", "COMPLIANCE", null);
            insertSystemParameter(connection, RECIPIENTS_KEY + "." + ORPHAN_COMPANY_ID,
                    "orphan@x.hu", "COMPLIANCE", null);
            insertSystemParameter(connection, "WU_PROVIDER_MODE", "STUB", "WESTERN_UNION", null);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id = ?
                    """, RECIPIENTS_KEY, COMPANY_ID))
                    .isEqualTo("a@x.hu,b@x.hu");
            assertThat(queryForString(connection, """
                    SELECT company_id::text
                      FROM system_parameter
                     WHERE parameter_key = ?
                    """, RECIPIENTS_KEY + "." + ORPHAN_COMPANY_ID))
                    .isNull();
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id IS NULL
                    """, RECIPIENTS_KEY + "." + ORPHAN_COMPANY_ID))
                    .isEqualTo("orphan@x.hu");
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = 'WU_PROVIDER_MODE'
                       AND company_id IS NULL
                    """)).isEqualTo("STUB");

            seedCompany(connection, COMPANY_2_ID, "PANNON", "Pannon Valtó");
            insertSystemParameter(connection, RECIPIENTS_KEY, "scoped@x.hu", "COMPLIANCE", COMPANY_2_ID);
            insertSystemParameter(connection, RECIPIENTS_KEY + "." + COMPANY_2_ID,
                    "legacy-should-remain@x.hu", "COMPLIANCE", null);
            int beforeRerunCount = queryForInteger(connection, "SELECT COUNT(*) FROM system_parameter");

            rerunV352SqlDirectly(connection);

            assertThat(queryForInteger(connection, "SELECT COUNT(*) FROM system_parameter"))
                    .isEqualTo(beforeRerunCount);
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id = ?
                    """, RECIPIENTS_KEY, COMPANY_2_ID))
                    .isEqualTo("scoped@x.hu");
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id IS NULL
                    """, RECIPIENTS_KEY + "." + COMPANY_2_ID))
                    .isEqualTo("legacy-should-remain@x.hu");
        }
    }

    private static void migrateToVersion351() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("351"))
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
        execute(connection, """
                INSERT INTO company (id, code, name)
                VALUES (?, ?, ?)
                """, id, code, name);
    }

    private static void insertSystemParameter(Connection connection, String key, String value,
                                              String category, UUID companyId) throws SQLException {
        execute(connection, """
                INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type,
                                              category, company_id, is_active)
                VALUES (gen_random_uuid(), ?, ?, 'STRING', ?, ?, true)
                """, key, value, category, companyId);
    }

    private static void rerunV352SqlDirectly(Connection connection) throws SQLException, IOException {
        try (var stream = V352IncomeProofRecipientsBackfillMigrationTest.class
                .getClassLoader()
                .getResourceAsStream("db/migration/V352__income_proof_recipients_company_backfill.sql")) {
            assertThat(stream).as("V352 migration SQL elerheto legyen a classpath-on").isNotNull();
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
