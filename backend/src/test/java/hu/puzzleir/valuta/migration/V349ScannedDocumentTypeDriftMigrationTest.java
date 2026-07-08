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

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class V349ScannedDocumentTypeDriftMigrationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V349 a scanned_document customer_id/transaction_id UUID driftet BIGINT-re javitja idempotensen")
    void repairsScannedDocumentCustomerAndTransactionTypeDriftWithIdempotency() throws Exception {
        migrateToVersion348();

        try (Connection connection = openConnection()) {
            assertThat(columnType(connection, "customer_id")).isEqualTo("uuid");
            assertThat(columnType(connection, "transaction_id")).isEqualTo("uuid");
            assertThat(queryForInteger(connection, "SELECT COUNT(*) FROM scanned_document")).isZero();
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(columnType(connection, "customer_id")).isEqualTo("bigint");
            assertThat(columnType(connection, "transaction_id")).isEqualTo("bigint");
            assertIndexExists(connection, "idx_scanned_document_customer");
            assertIndexExists(connection, "idx_scanned_document_transaction");

            execute(connection, """
                    INSERT INTO scanned_document (customer_id, transaction_id, document_type, file_name)
                    VALUES (12345, 67890, 'ID_CARD', 'teszt.jpg')
                    """);

            rerunV349SqlDirectly(connection);

            assertThat(columnType(connection, "customer_id")).isEqualTo("bigint");
            assertThat(columnType(connection, "transaction_id")).isEqualTo("bigint");
            assertThat(queryForLong(connection, "SELECT customer_id FROM scanned_document")).isEqualTo(12345L);
            assertThat(queryForLong(connection, "SELECT transaction_id FROM scanned_document")).isEqualTo(67890L);
        }
    }

    private static void migrateToVersion348() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("348"))
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

    private static void assertIndexExists(Connection connection, String indexName) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM pg_indexes
                 WHERE tablename = 'scanned_document'
                   AND indexname = ?
                """, indexName);
        assertThat(count).as("%s index letezzen", indexName).isEqualTo(1);
    }

    private static String columnType(Connection connection, String column) throws SQLException {
        return queryForString(connection, """
                SELECT format_type(a.atttypid, a.atttypmod)
                  FROM pg_attribute a
                 WHERE a.attrelid = 'scanned_document'::regclass
                   AND a.attname = ?
                   AND NOT a.attisdropped
                """, column);
    }

    private static void rerunV349SqlDirectly(Connection connection) throws SQLException, IOException {
        try (var stream = V349ScannedDocumentTypeDriftMigrationTest.class
                .getClassLoader()
                .getResourceAsStream("db/migration/V349__scanned_document_type_drift_repair.sql")) {
            assertThat(stream).as("V349 migration SQL elerheto legyen a classpath-on").isNotNull();
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

    private static Long queryForLong(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("long query returned a row").isTrue();
                return resultSet.getLong(1);
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
