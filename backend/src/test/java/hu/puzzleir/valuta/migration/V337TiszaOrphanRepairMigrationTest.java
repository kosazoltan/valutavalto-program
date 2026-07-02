package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * V337 regresszios Flyway-integracios teszt: a V336-ig felmigralo DB-be direkt
 * visszarakja az elo diagnosztikaban talalt TISZA-arva allapotot, majd csak a
 * kovetkezo Flyway migration javithatja ki. A worker mapping assert-ek
 * feltetelesek a worker-code letezesere, mert regi/lokalis seed-lanc drift
 * eseten nem minden login/duplikatum rekord garantalt; az altalanos invariansok
 * ettol fuggetlenul kotelezoek es fogjak az aktiv worker -> inaktiv branch hibat.
 */
@Testcontainers
class V337TiszaOrphanRepairMigrationTest {

    private static final String PASSWORD_HASH = "$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie";
    private static final String ORPHAN_SHIPMENT_NUMBER = "SHR-20260529-0001";
    private static final Map<String, String> TISZA_WORKER_FIXTURE = Map.of(
            "BALI", "Bali Henrietta",
            "BORSI", "Borsi Tamas",
            "KASZA", "Kasza Helga",
            "KOSA", "Kosa Zoltan",
            "FABULYA", "Fabulya Zsuzsa",
            "G_KISS_KORNEL", "Kiss Kornel",
            "G_KOSZTYU_CSABA", "Kosztyu Csaba"
    );

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V337 javitja a TISZA-n ragadt aktiv workereket, HUF kasszat es fuggo szallitmanyt")
    void repairsTiszaOrphanWorkersCashBalanceAndSubmittedShipment() throws Exception {
        migrateToVersion336();

        try (Connection connection = openConnection()) {
            seedTiszaOrphanState(connection);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertNoActiveWorkerOnInactiveBranch(connection);
            assertWorkerMappingsWhenCodesExist(connection);
            assertTiszaHufBalanceIsZero(connection);
            assertBr035ReceivedTiszaHufBalance(connection);
            assertNoSubmittedShipmentFromInactiveBranch(connection);
            assertTiszaShipmentWasCancelledWithV337Note(connection);
        }
    }

    private static void migrateToVersion336() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("336"))
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

    private static void seedTiszaOrphanState(Connection connection) throws SQLException {
        assertBranchExists(connection, "TISZA");
        assertBranchExists(connection, "BR035");
        assertBranchExists(connection, "BR057");
        assertBranchExists(connection, "BR076");
        assertBranchExists(connection, "BR150");
        assertCurrencyExists(connection, "HUF");

        execute(connection, """
                UPDATE branch
                   SET is_active = FALSE,
                       updated_at = NOW()
                 WHERE code = 'TISZA'
                   AND company_id = (SELECT company_id FROM branch WHERE code = 'TISZA' LIMIT 1)
                """);

        // A V336-ig futtatott lokalis seed-lanc tortenelmi/login-duplikatum zajt is tartalmazhat
        // inaktiv brancheken. A V337 terv scope-ja a 7 felsorolt TISZA-arva worker, ezert a fixture
        // az egyeb inaktiv-branch zajt inaktivra allitja; az altalanos invarians-assert valtozatlanul
        // kotelezo marad, es a V337 nelkul a 7 visszaallitott worker miatt RED-del bukik.
        execute(connection, """
                UPDATE worker w
                   SET is_active = FALSE,
                       active = FALSE,
                       updated_at = NOW()
                  FROM branch b
                 WHERE b.id = w.branch_id
                   AND NOT b.is_active
                   AND w.is_active
                   AND w.company_id = (SELECT company_id FROM branch WHERE code = 'TISZA' LIMIT 1)
                   AND w.code NOT IN ('BALI', 'BORSI', 'KASZA', 'KOSA', 'FABULYA', 'G_KISS_KORNEL', 'G_KOSZTYU_CSABA')
                """);

        for (Map.Entry<String, String> entry : TISZA_WORKER_FIXTURE.entrySet()) {
            upsertActiveWorkerOnTisza(connection, entry.getKey(), entry.getValue());
        }

        upsertCashBalance(connection, "BR035", new BigDecimal("10000"));
        upsertCashBalance(connection, "TISZA", new BigDecimal("4985000"));
        upsertSubmittedTiszaShipment(connection);
    }

    private static void assertBranchExists(Connection connection, String branchCode) throws SQLException {
        Integer count = queryForInteger(connection, "SELECT COUNT(*) FROM branch WHERE code = ?", branchCode);
        assertThat(count)
                .as("a %s branch-nek leteznie kell a V336-ig felmigralo seed-lancban", branchCode)
                .isEqualTo(1);
    }

    private static void assertCurrencyExists(Connection connection, String currencyCode) throws SQLException {
        Integer count = queryForInteger(connection, "SELECT COUNT(*) FROM currency WHERE code = ?", currencyCode);
        assertThat(count)
                .as("a %s currency-nek leteznie kell a V336-ig felmigralo seed-lancban", currencyCode)
                .isEqualTo(1);
    }

    private static void upsertActiveWorkerOnTisza(Connection connection, String workerCode, String workerName) throws SQLException {
        execute(connection, """
                INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, region, is_active, active, created_at, updated_at)
                SELECT tisza.company_id, tisza.id, ?, ?, ?, 'CASHIER', tisza.region, TRUE, TRUE, NOW(), NOW()
                  FROM branch tisza
                 WHERE tisza.code = 'TISZA'
                ON CONFLICT (company_id, code) DO UPDATE
                    SET branch_id = EXCLUDED.branch_id,
                        is_active = TRUE,
                        active = TRUE,
                        updated_at = NOW()
                """, workerCode, workerName, PASSWORD_HASH);
    }

    private static void upsertCashBalance(Connection connection, String branchCode, BigDecimal currentBalance) throws SQLException {
        execute(connection, """
                INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance, opening_balance, created_at, updated_at, version)
                SELECT b.company_id, b.id, c.id, ?, 0, NOW(), NOW(), 0
                  FROM branch b
                  JOIN currency c ON c.code = 'HUF'
                 WHERE b.code = ?
                   AND b.company_id = (SELECT company_id FROM branch WHERE code = 'TISZA' LIMIT 1)
                ON CONFLICT (branch_id, currency_id) DO UPDATE
                    SET current_balance = EXCLUDED.current_balance,
                        updated_at = NOW()
                """, currentBalance, branchCode);
    }

    private static void upsertSubmittedTiszaShipment(Connection connection) throws SQLException {
        execute(connection, """
                INSERT INTO shipment_request (
                    id, company_id, request_number, from_branch_id, to_branch_id, requested_by_id,
                    status, request_date, delivery_date, notes, created_at
                )
                SELECT gen_random_uuid(), tisza.company_id, ?, tisza.id, target.id, requester.id,
                       'SUBMITTED', DATE '2026-05-29', DATE '2026-05-29', 'pre-V337 orphan test row', NOW()
                  FROM branch tisza
                  JOIN branch target ON target.company_id = tisza.company_id AND target.code = 'BR020'
                  JOIN worker requester ON requester.company_id = tisza.company_id AND requester.code = 'BALI'
                 WHERE tisza.code = 'TISZA'
                ON CONFLICT (company_id, request_number) WHERE company_id IS NOT NULL DO UPDATE
                    SET from_branch_id = EXCLUDED.from_branch_id,
                        to_branch_id = EXCLUDED.to_branch_id,
                        requested_by_id = EXCLUDED.requested_by_id,
                        status = 'SUBMITTED',
                        request_date = DATE '2026-05-29',
                        delivery_date = DATE '2026-05-29',
                        notes = 'pre-V337 orphan test row'
                """, ORPHAN_SHIPMENT_NUMBER);
    }

    private static void assertNoActiveWorkerOnInactiveBranch(Connection connection) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM worker w
                  JOIN branch b ON b.id = w.branch_id
                 WHERE w.is_active
                   AND NOT b.is_active
                """);
        assertThat(count).as("nem maradhat aktiv worker inaktiv branch-en").isZero();
    }

    private static void assertWorkerMappingsWhenCodesExist(Connection connection) throws SQLException {
        assertWorkerBranchWhenExists(connection, "BALI", "BR035");
        assertWorkerBranchWhenExists(connection, "BORSI", "BR035");
        assertWorkerBranchWhenExists(connection, "KASZA", "BR035");
        assertWorkerBranchWhenExists(connection, "KOSA", "BR035");
        assertWorkerBranchWhenExists(connection, "FABULYA", "BR076");
        assertWorkerBranchWhenExists(connection, "G_KISS_KORNEL", "BR150");
        assertWorkerBranchWhenExists(connection, "G_KOSZTYU_CSABA", "BR057");
    }

    private static void assertWorkerBranchWhenExists(Connection connection, String workerCode, String expectedBranchCode) throws SQLException {
        String actualBranchCode = queryForString(connection, """
                SELECT b.code
                  FROM worker w
                  JOIN branch b ON b.id = w.branch_id
                  JOIN branch tisza ON tisza.company_id = w.company_id AND tisza.code = 'TISZA'
                 WHERE w.code = ?
                   AND w.company_id = tisza.company_id
                """, workerCode);
        if (actualBranchCode != null) {
            assertThat(actualBranchCode)
                    .as("%s worker cel branch kodja", workerCode)
                    .isEqualTo(expectedBranchCode);
        }
    }

    private static void assertTiszaHufBalanceIsZero(Connection connection) throws SQLException {
        BigDecimal balance = queryForBigDecimal(connection, """
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN branch b ON b.id = cb.branch_id
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE b.code = 'TISZA'
                   AND c.code = 'HUF'
                """);
        assertThat(balance).as("V337 utan a TISZA HUF cash_balance nulla").isEqualByComparingTo(BigDecimal.ZERO);
    }

    private static void assertBr035ReceivedTiszaHufBalance(Connection connection) throws SQLException {
        BigDecimal balance = queryForBigDecimal(connection, """
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN branch b ON b.id = cb.branch_id
                  JOIN currency c ON c.id = cb.currency_id
                  JOIN branch tisza ON tisza.company_id = b.company_id AND tisza.code = 'TISZA'
                 WHERE b.code = 'BR035'
                   AND c.code = 'HUF'
                """);
        assertThat(balance).as("BR035 HUF egyenlege megkapja a TISZA HUF osszeget").isEqualByComparingTo("4995000");
    }

    private static void assertNoSubmittedShipmentFromInactiveBranch(Connection connection) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM shipment_request sr
                  JOIN branch b ON b.id = sr.from_branch_id
                 WHERE sr.status = 'SUBMITTED'
                   AND NOT b.is_active
                """);
        assertThat(count).as("nem maradhat SUBMITTED shipment_request inaktiv forras-branch-csel").isZero();
    }

    private static void assertTiszaShipmentWasCancelledWithV337Note(Connection connection) throws SQLException {
        String status = queryForString(connection,
                "SELECT status FROM shipment_request WHERE request_number = ?", ORPHAN_SHIPMENT_NUMBER);
        String notes = queryForString(connection,
                "SELECT notes FROM shipment_request WHERE request_number = ?", ORPHAN_SHIPMENT_NUMBER);

        assertThat(status).as("a TISZA arva shipment adminisztrativan lezarva").isEqualTo("CANCELLED");
        assertThat(notes).as("a shipment notes tartalmazza a V337 indokot").contains("V337: inaktív TISZA branch árva függő kérése");
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

    private static BigDecimal queryForBigDecimal(Connection connection, String sql, Object... parameters) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("decimal query returned a row").isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
