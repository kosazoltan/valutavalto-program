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
import java.sql.Timestamp;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * V338 regresszios Flyway-integracios teszt: a V337-ig felmigralo DB-be direkt
 * visszaallitja az elo diagnosztikaban talalt vault currency_stock anomaliat,
 * majd csak a V338 javithatja ki. A Szeged EUR negativ levezetett erteke
 * fizikailag lehetetlen, ezert a perzisztalt stock 0 marad; az altalanos
 * invarians tiltja, hogy barmely VAULT stock negativba menjen.
 */
@Testcontainers
class V338VaultStockReconciliationMigrationTest {

    private static final String MAIN_VAULT = "Fo Ertektar";
    private static final String SZEGED_VAULT = "Szeged";
    private static final String V338_NOTE = "V338 base_capital reconciliation — mozgás-alapú levezetett értékre igazítás, diag run 28643631686";

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    @DisplayName("V338 a Fo Ertektar HUF/EUR stockot levezetett ertekre igazítja audit-nyommal, negativ stock nelkul")
    void reconcilesVaultStockToDerivedValuesWithCorrectionMovementsAndIdempotency() throws Exception {
        migrateToVersion337();

        Map<StockKey, StockSnapshot> before;
        try (Connection connection = openConnection()) {
            seedPreV338VaultStockAnomaly(connection);
            before = readVaultStockSnapshots(connection);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertVaultStock(connection, MAIN_VAULT, "HUF", "100000000.00");
            assertVaultStock(connection, MAIN_VAULT, "EUR", "0.00");
            assertVaultStock(connection, SZEGED_VAULT, "EUR", "0.00");
            assertWeightedAvgCost(connection, MAIN_VAULT, "EUR", "390.1234");
            assertUnrelatedVaultStockRowsUnchanged(connection, before);
            assertNoNegativeVaultStock(connection);
            assertCorrectionMovements(connection);

            rerunV338SqlDirectly(connection);

            assertVaultStock(connection, MAIN_VAULT, "HUF", "100000000.00");
            assertVaultStock(connection, MAIN_VAULT, "EUR", "0.00");
            assertVaultStock(connection, SZEGED_VAULT, "EUR", "0.00");
            assertNoNegativeVaultStock(connection);
            assertCorrectionMovementCount(connection, 2);
        }
    }

    private static void migrateToVersion337() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion("337"))
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

    private static void seedPreV338VaultStockAnomaly(Connection connection) throws SQLException {
        assertVaultTerritoryExists(connection, MAIN_VAULT);
        assertVaultTerritoryExists(connection, SZEGED_VAULT);
        assertCurrencyExists(connection, "HUF");
        assertCurrencyExists(connection, "EUR");

        upsertVaultStock(connection, MAIN_VAULT, "HUF", "99582500.00", "1.0000");
        upsertVaultStock(connection, MAIN_VAULT, "EUR", "950.00", "390.1234");
        upsertVaultStock(connection, SZEGED_VAULT, "EUR", "0.00", "401.5678");
        deleteV338CorrectionMovements(connection);
    }

    private static void upsertVaultStock(
            Connection connection,
            String territoryName,
            String currencyCode,
            String quantity,
            String weightedAvgCost
    ) throws SQLException {
        execute(connection, """
                INSERT INTO currency_stock (
                    company_id, entity_type, entity_id, currency_code,
                    quantity, weighted_avg_cost, last_updated
                )
                SELECT vt.company_id, 'VAULT', vt.id::TEXT, ?, ?, ?, TIMESTAMP '2026-07-03 08:00:00'
                  FROM vault_territory vt
                  JOIN company c ON c.id = vt.company_id AND c.code = 'EBC'
                 WHERE vt.name = ?
                ON CONFLICT (company_id, entity_type, entity_id, currency_code) DO UPDATE
                    SET quantity = EXCLUDED.quantity,
                        weighted_avg_cost = EXCLUDED.weighted_avg_cost,
                        last_updated = EXCLUDED.last_updated
                """, currencyCode, new BigDecimal(quantity), new BigDecimal(weightedAvgCost), territoryName);
    }

    private static void deleteV338CorrectionMovements(Connection connection) throws SQLException {
        execute(connection, "DELETE FROM inventory_movement WHERE notes = ?", V338_NOTE);
    }

    private static void assertVaultTerritoryExists(Connection connection, String territoryName) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM vault_territory vt
                  JOIN company c ON c.id = vt.company_id AND c.code = 'EBC'
                 WHERE vt.name = ?
                """, territoryName);
        assertThat(count)
                .as("a %s vault_territory-nek leteznie kell a V337-ig felmigralo seed-lancban", territoryName)
                .isEqualTo(1);
    }

    private static void assertCurrencyExists(Connection connection, String currencyCode) throws SQLException {
        Integer count = queryForInteger(connection, "SELECT COUNT(*) FROM currency WHERE code = ?", currencyCode);
        assertThat(count)
                .as("a %s currency-nek leteznie kell a V337-ig felmigralo seed-lancban", currencyCode)
                .isEqualTo(1);
    }

    private static Map<StockKey, StockSnapshot> readVaultStockSnapshots(Connection connection) throws SQLException {
        Map<StockKey, StockSnapshot> snapshots = new LinkedHashMap<>();
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT cs.company_id::TEXT, cs.entity_id, cs.currency_code,
                       cs.quantity, cs.weighted_avg_cost, cs.last_updated
                  FROM currency_stock cs
                 WHERE cs.entity_type = 'VAULT'
                 ORDER BY cs.company_id::TEXT, cs.entity_id, cs.currency_code
                """)) {
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    StockKey key = new StockKey(
                            resultSet.getString("company_id"),
                            resultSet.getString("entity_id"),
                            resultSet.getString("currency_code"));
                    snapshots.put(key, new StockSnapshot(
                            resultSet.getBigDecimal("quantity"),
                            resultSet.getBigDecimal("weighted_avg_cost"),
                            resultSet.getTimestamp("last_updated")));
                }
            }
        }
        return snapshots;
    }

    private static void assertVaultStock(
            Connection connection,
            String territoryName,
            String currencyCode,
            String expectedQuantity
    ) throws SQLException {
        BigDecimal quantity = queryForBigDecimal(connection, """
                SELECT cs.quantity
                  FROM currency_stock cs
                  JOIN vault_territory vt ON vt.company_id = cs.company_id AND vt.id::TEXT = cs.entity_id
                  JOIN company c ON c.id = vt.company_id AND c.code = 'EBC'
                 WHERE cs.entity_type = 'VAULT'
                   AND vt.name = ?
                   AND cs.currency_code = ?
                """, territoryName, currencyCode);
        assertThat(quantity)
                .as("%s %s VAULT stock", territoryName, currencyCode)
                .isEqualByComparingTo(expectedQuantity);
    }

    private static void assertWeightedAvgCost(
            Connection connection,
            String territoryName,
            String currencyCode,
            String expectedWac
    ) throws SQLException {
        BigDecimal weightedAvgCost = queryForBigDecimal(connection, """
                SELECT cs.weighted_avg_cost
                  FROM currency_stock cs
                  JOIN vault_territory vt ON vt.company_id = cs.company_id AND vt.id::TEXT = cs.entity_id
                  JOIN company c ON c.id = vt.company_id AND c.code = 'EBC'
                 WHERE cs.entity_type = 'VAULT'
                   AND vt.name = ?
                   AND cs.currency_code = ?
                """, territoryName, currencyCode);
        assertThat(weightedAvgCost)
                .as("%s %s WAC valtozatlan", territoryName, currencyCode)
                .isEqualByComparingTo(expectedWac);
    }

    private static void assertUnrelatedVaultStockRowsUnchanged(
            Connection connection,
            Map<StockKey, StockSnapshot> before
    ) throws SQLException {
        String mainVaultEntityId = queryForString(connection, """
                SELECT vt.id::TEXT
                  FROM vault_territory vt
                  JOIN company c ON c.id = vt.company_id AND c.code = 'EBC'
                 WHERE vt.name = ?
                """, MAIN_VAULT);
        Map<StockKey, StockSnapshot> after = readVaultStockSnapshots(connection);
        assertThat(after.keySet()).as("a V338 nem hoz letre es nem torol VAULT currency_stock sort").isEqualTo(before.keySet());

        for (Map.Entry<StockKey, StockSnapshot> entry : before.entrySet()) {
            StockKey key = entry.getKey();
            if (Objects.equals(key.entityId(), mainVaultEntityId)
                    && ("HUF".equals(key.currencyCode()) || "EUR".equals(key.currencyCode()))) {
                continue;
            }
            StockSnapshot afterSnapshot = after.get(key);
            assertThat(afterSnapshot)
                    .as("nem celzott VAULT stock sor valtozatlan: %s", key)
                    .isEqualTo(entry.getValue());
        }
    }

    private static void assertNoNegativeVaultStock(Connection connection) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM currency_stock
                 WHERE entity_type = 'VAULT'
                   AND quantity < 0
                """);
        assertThat(count).as("VAULT currency_stock soha nem lehet negativ").isZero();
    }

    private static void assertCorrectionMovements(Connection connection) throws SQLException {
        assertCorrectionMovementCount(connection, 2);

        BigDecimal hufAmount = queryForBigDecimal(connection, """
                SELECT amount
                  FROM inventory_movement im
                  JOIN currency c ON c.id = im.currency_id
                 WHERE im.notes = ?
                   AND im.movement_type = 'CORRECTION'
                   AND im.status = 'RECEIVED'
                   AND c.code = 'HUF'
                """, V338_NOTE);
        assertThat(hufAmount).as("HUF korrekcios movement delta abszolut erteke").isEqualByComparingTo("417500.0000");

        BigDecimal eurAmount = queryForBigDecimal(connection, """
                SELECT amount
                  FROM inventory_movement im
                  JOIN currency c ON c.id = im.currency_id
                 WHERE im.notes = ?
                   AND im.movement_type = 'CORRECTION'
                   AND im.status = 'RECEIVED'
                   AND c.code = 'EUR'
                """, V338_NOTE);
        assertThat(eurAmount).as("EUR korrekcios movement delta abszolut erteke").isEqualByComparingTo("950.0000");

        Integer completeRows = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM inventory_movement
                 WHERE notes = ?
                   AND movement_type = 'CORRECTION'
                   AND status = 'RECEIVED'
                   AND initiated_by_id IS NOT NULL
                   AND approved_by_id IS NOT NULL
                   AND received_by_id IS NOT NULL
                   AND reference_number IS NOT NULL
                   AND movement_date IS NOT NULL
                   AND movement_time IS NOT NULL
                   AND huf_value IS NOT NULL
                """, V338_NOTE);
        assertThat(completeRows).as("a V338 korrekcios movement sorok minden kotelezo audit mezot kitoltenek").isEqualTo(2);
    }

    private static void assertCorrectionMovementCount(Connection connection, int expectedCount) throws SQLException {
        Integer count = queryForInteger(connection, """
                SELECT COUNT(*)
                  FROM inventory_movement
                 WHERE notes = ?
                   AND movement_type = 'CORRECTION'
                   AND status = 'RECEIVED'
                """, V338_NOTE);
        assertThat(count).as("V338 CORRECTION inventory_movement sorok szama").isEqualTo(expectedCount);
    }

    private static void rerunV338SqlDirectly(Connection connection) throws SQLException, IOException {
        try (var stream = V338VaultStockReconciliationMigrationTest.class
                .getClassLoader()
                .getResourceAsStream("db/migration/V338__vault_stock_base_capital_reconciliation.sql")) {
            assertThat(stream).as("V338 migration SQL elerheto legyen a classpath-on").isNotNull();
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

    private record StockKey(String companyId, String entityId, String currencyCode) {
    }

    private record StockSnapshot(BigDecimal quantity, BigDecimal weightedAvgCost, Timestamp lastUpdated) {
    }
}
