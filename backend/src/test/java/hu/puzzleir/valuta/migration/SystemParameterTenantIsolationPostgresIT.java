package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
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

@Testcontainers
class SystemParameterTenantIsolationPostgresIT {

    private static final String RECIPIENTS_KEY = "INCOME_PROOF_DOC_RECIPIENTS";
    private static final String GLOBAL_KEY = "GLOBAL_KEY";
    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("system_parameter company_id izolacio es parcial unique indexek valos PostgreSQL-en elnek")
    void systemParameterRowsAreTenantIsolatedAndPartialUniqueIndexesAreEnforced() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            seedCompany(connection, COMPANY_A, "BEST", "Best Change");
            seedCompany(connection, COMPANY_B, "PANNON", "Pannon Valto");
            insertSystemParameter(connection, RECIPIENTS_KEY, "a@x.hu", "COMPLIANCE", COMPANY_A);
            insertSystemParameter(connection, GLOBAL_KEY, "g", "SYSTEM", null);

            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id = ?
                    """, RECIPIENTS_KEY, COMPANY_B))
                    .isZero();
            assertThat(queryForString(connection, """
                    SELECT parameter_value
                      FROM system_parameter
                     WHERE parameter_key = ?
                       AND company_id = ?
                    """, RECIPIENTS_KEY, COMPANY_A))
                    .isEqualTo("a@x.hu");

            assertUniqueViolation(() -> insertSystemParameter(connection, RECIPIENTS_KEY,
                    "duplicate@x.hu", "COMPLIANCE", COMPANY_A));
            assertUniqueViolation(() -> insertSystemParameter(connection, GLOBAL_KEY,
                    "duplicate-global", "SYSTEM", null));

            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM system_parameter
                     WHERE (company_id IS NULL OR company_id = ?)
                       AND parameter_key = ?
                       AND parameter_value = 'a@x.hu'
                    """, COMPANY_B, RECIPIENTS_KEY))
                    .isZero();
        }
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

    private static void assertUniqueViolation(SqlAction action) {
        assertThatThrownBy(action::run)
                .isInstanceOfSatisfying(SQLException.class,
                        ex -> assertThat(ex.getSQLState()).isEqualTo("23505"));
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

    @FunctionalInterface
    private interface SqlAction {
        void run() throws SQLException;
    }
}
