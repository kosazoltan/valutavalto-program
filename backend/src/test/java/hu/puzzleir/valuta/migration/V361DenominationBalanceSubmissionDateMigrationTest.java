package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
class V361DenominationBalanceSubmissionDateMigrationTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-3610-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("11111111-3610-0000-0000-000000000002");
    private static final UUID DATED_BALANCE_ID = UUID.fromString("11111111-3610-0000-0000-000000000003");
    private static final UUID NULL_BALANCE_ID = UUID.fromString("11111111-3610-0000-0000-000000000004");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void backfillsSubmissionDateAndCreatesNotNullIndexedColumn() throws Exception {
        migrateToVersion360();

        try (Connection connection = openConnection()) {
            execute(connection, """
                    INSERT INTO company (id, code, name, is_active, created_at)
                    VALUES (?, 'FK060', 'FK-060 Test Company', true, NOW())
                    """, COMPANY_ID);
            execute(connection, """
                    INSERT INTO branch (id, code, company_id, name)
                    VALUES (?, 'FK060-BRANCH', ?, 'FK-060 Test Branch')
                    """, BRANCH_ID, COMPANY_ID);
            long currencyId = queryForLong(connection, "SELECT id FROM currency WHERE code = 'HUF'");
            long denominationId = insertAndReturnId(connection, """
                    INSERT INTO denomination
                        (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                    VALUES (?, ?, ?, 1000, 'BANKNOTE', 0, true)
                    RETURNING id
                    """, COMPANY_ID, BRANCH_ID, currencyId);
            long secondDenominationId = insertAndReturnId(connection, """
                    INSERT INTO denomination
                        (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                    VALUES (?, ?, ?, 500, 'BANKNOTE', 0, true)
                    RETURNING id
                    """, COMPANY_ID, BRANCH_ID, currencyId);
            execute(connection, """
                    INSERT INTO denomination_balance
                        (id, cash_desk_id, denomination_id, quantity, total_value, updated_at, denomination_category)
                    VALUES (?, ?, ?, 1, 1000, TIMESTAMP '2026-07-20 18:00:00', 'EVENING')
                    """, DATED_BALANCE_ID, BRANCH_ID, denominationId);
            execute(connection, """
                    INSERT INTO denomination_balance
                        (id, cash_desk_id, denomination_id, quantity, total_value, updated_at, denomination_category)
                    VALUES (?, ?, ?, 2, 2000, NULL, 'EVENING')
                    """, NULL_BALANCE_ID, BRANCH_ID, secondDenominationId);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForString(connection, """
                    SELECT data_type || ':' || is_nullable
                      FROM information_schema.columns
                     WHERE table_schema = 'public'
                       AND table_name = 'denomination_balance'
                       AND column_name = 'submission_date'
                    """)).isEqualTo("date:NO");
            assertThat(queryForDate(connection,
                    "SELECT submission_date FROM denomination_balance WHERE id = ?", DATED_BALANCE_ID))
                    .isEqualTo(LocalDate.of(2026, 7, 20));
            assertThat(queryForDate(connection,
                    "SELECT submission_date FROM denomination_balance WHERE id = ?", NULL_BALANCE_ID))
                    .isEqualTo(queryForDate(connection, "SELECT CURRENT_DATE"));
            assertThat(queryForLong(connection, """
                    SELECT COUNT(*)
                      FROM pg_indexes
                     WHERE schemaname = 'public'
                       AND indexname = 'idx_denom_balance_submission'
                    """)).isEqualTo(1L);
        }
    }

    private static void migrateToVersion360() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("360"))
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

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static long insertAndReturnId(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static long queryForLong(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() ? resultSet.getString(1) : null;
            }
        }
    }

    private static LocalDate queryForDate(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getObject(1, LocalDate.class);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws Exception {
        for (int index = 0; index < parameters.length; index++) {
            statement.setObject(index + 1, parameters[index]);
        }
    }
}
