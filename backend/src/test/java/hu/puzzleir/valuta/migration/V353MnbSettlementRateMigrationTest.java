package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.math.BigDecimal;
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
class V353MnbSettlementRateMigrationTest {

    private static final UUID COMPANY_1_ID = UUID.fromString("11111111-3530-0000-0000-000000000001");
    private static final UUID COMPANY_2_ID = UUID.fromString("22222222-3530-0000-0000-000000000002");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V353 letrehozza az MNB elszamolasi arfolyam tablak schemajat es idempotens kezdosorait")
    void createsMnbSettlementRateTablesAndSeedsActiveCurrenciesIdempotently() throws Exception {
        migrateToVersion352();

        try (Connection connection = openConnection()) {
            seedCompany(connection, COMPANY_1_ID, "FK028A1", "FK-028 Test Company 1");
            seedCompany(connection, COMPANY_2_ID, "FK028A2", "FK-028 Test Company 2");
            seedCurrency(connection, "XAA", "FK-028 Active Currency", true, 901);
            seedCurrency(connection, "XBB", "FK-028 Inactive Currency", false, 902);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(tableExists(connection, "mnb_settlement_rate")).isTrue();
            assertThat(tableExists(connection, "mnb_settlement_rate_history")).isTrue();

            assertColumn(connection, "mnb_settlement_rate", "company_id", "uuid", false, null);
            assertColumn(connection, "mnb_settlement_rate", "currency_code", "character varying", false, 3);
            assertColumn(connection, "mnb_settlement_rate", "official_rate", "numeric", false, null);
            assertColumn(connection, "mnb_settlement_rate", "updated_by", "character varying", true, 50);
            assertColumn(connection, "mnb_settlement_rate_history", "recorded_by", "character varying", true, 50);

            assertIndexExists(connection, "ux_mnb_settlement_rate_company_currency");
            assertIndexExists(connection, "ix_msr_history_company_recorded");
            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM pg_constraint
                     WHERE conrelid IN ('mnb_settlement_rate'::regclass,
                                        'mnb_settlement_rate_history'::regclass)
                       AND contype = 'f'
                    """)).as("FK constraint szandekosan nincs a company/currency tablak fele").isZero();

            assertThat(queryForBigDecimal(connection, """
                    SELECT official_rate
                      FROM mnb_settlement_rate
                     WHERE company_id = ?
                       AND currency_code = 'XAA'
                    """, COMPANY_1_ID)).isEqualByComparingTo("0.0000");
            assertThat(queryForBigDecimal(connection, """
                    SELECT official_rate
                      FROM mnb_settlement_rate
                     WHERE company_id = ?
                       AND currency_code = 'HUF'
                    """, COMPANY_1_ID)).isEqualByComparingTo("1.0000");
            assertThat(queryForBigDecimal(connection, """
                    SELECT official_rate
                      FROM mnb_settlement_rate
                     WHERE company_id = ?
                       AND currency_code = 'XAA'
                    """, COMPANY_2_ID)).isEqualByComparingTo("0.0000");
            assertThat(queryForInteger(connection, """
                    SELECT COUNT(*)
                      FROM mnb_settlement_rate
                     WHERE company_id IN (?, ?)
                       AND currency_code = 'XBB'
                    """, COMPANY_1_ID, COMPANY_2_ID)).isZero();
            assertThat(queryForInteger(connection, "SELECT COUNT(*) FROM mnb_settlement_rate_history")).isZero();

            int rateRowsBeforeRerun = queryForInteger(connection, "SELECT COUNT(*) FROM mnb_settlement_rate");
            rerunV353SqlDirectly(connection);
            assertThat(queryForInteger(connection, "SELECT COUNT(*) FROM mnb_settlement_rate"))
                    .isEqualTo(rateRowsBeforeRerun);
        }
    }

    private static void migrateToVersion352() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("352"))
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
                INSERT INTO company (id, code, name, is_active, created_at)
                VALUES (?, ?, ?, true, NOW())
                """, id, code, name);
    }

    private static void seedCurrency(Connection connection, String code, String name, boolean active,
                                     int displayOrder) throws SQLException {
        execute(connection, """
                INSERT INTO currency (code, name, symbol, decimal_places, active, is_active, display_order, created_at)
                VALUES (?, ?, ?, 2, ?, ?, ?, NOW())
                """, code, name, code, active, active, displayOrder);
    }

    private static void assertColumn(Connection connection, String tableName, String columnName,
                                     String dataType, boolean nullable, Integer characterMaximumLength)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT data_type, is_nullable, character_maximum_length
                  FROM information_schema.columns
                 WHERE table_schema = 'public'
                   AND table_name = ?
                   AND column_name = ?
                """)) {
            statement.setString(1, tableName);
            statement.setString(2, columnName);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("%s.%s column exists", tableName, columnName).isTrue();
                assertThat(resultSet.getString("data_type")).isEqualTo(dataType);
                assertThat(resultSet.getString("is_nullable")).isEqualTo(nullable ? "YES" : "NO");
                if (characterMaximumLength != null) {
                    assertThat(resultSet.getInt("character_maximum_length")).isEqualTo(characterMaximumLength);
                }
            }
        }
    }

    private static boolean tableExists(Connection connection, String tableName) throws SQLException {
        return queryForString(connection, "SELECT to_regclass(?)::text", "public." + tableName) != null;
    }

    private static void assertIndexExists(Connection connection, String indexName) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM pg_indexes
                 WHERE schemaname = 'public'
                   AND indexname = ?
                """, indexName);
        assertThat(count).as("%s index letezzen", indexName).isEqualTo(1);
    }

    private static void rerunV353SqlDirectly(Connection connection) throws SQLException, IOException {
        try (var stream = V353MnbSettlementRateMigrationTest.class
                .getClassLoader()
                .getResourceAsStream("db/migration/V353__create_mnb_settlement_rate.sql")) {
            assertThat(stream).as("V353 migration SQL elerheto legyen a classpath-on").isNotNull();
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

    private static BigDecimal queryForBigDecimal(Connection connection, String sql, Object... parameters)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("decimal query returned a row").isTrue();
                return resultSet.getBigDecimal(1);
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
