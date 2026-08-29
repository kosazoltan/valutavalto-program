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
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FK-099 E-sorozat (E8–E16) — a V384 ráta-history migráció valós PostgreSQL-en.
 * Harness: {@link BranchHandlingFeeConfigV383PostgresTest} minta
 * (Flyway clean + migrateToVersion + raw JDBC).
 */
@Testcontainers
class TransactionLevyRateHistoryV384PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V384_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk099_transaction_levy_rate_history.*\\.sql$");

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

    // =====================================================================
    // E8 — RED-repro: V384 ELOTT nincs tabla
    // =====================================================================
    @Test
    @DisplayName("E8/RED-repro: V384 előtt a transaction_levy_rate_history tábla nem létezik")
    void e8_redRepro_tableAbsentBeforeV384() throws Exception {
        migrateToVersion(previousExistingVersion(V384_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            assertThat(tableExists(connection, "transaction_levy_rate_history"))
                    .as("V384 előtt a tábla még nem állhat")
                    .isFalse();
        }
    }

    // =====================================================================
    // E9 — séma
    // =====================================================================
    @Test
    @DisplayName("E9: migrateToLatest után a tábla a deklarált oszlopokkal áll")
    void e9_tableExistsWithDeclaredColumns() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(tableColumns(connection, "transaction_levy_rate_history"))
                    .as("E9: a tábla oszlopkészlete")
                    .containsExactly(
                            "id", "company_id", "effective_from", "base_rate_percent",
                            "base_rate_cap_huf", "supplement_rate_percent",
                            "supplement_rate_cap_huf", "conversion_single_side_flag",
                            "created_by", "created_at");
        }
    }

    // =====================================================================
    // E10 — C12 seed: cégenként egy sor, fix értékekkel
    // =====================================================================
    @Test
    @DisplayName("E10/C12: a seed minden cégnek pontosan egy sort ad (2013-01-01 / 0.450 / 20000.00)")
    void e10_seedOneRowPerCompany() throws Exception {
        migrateToVersion(previousExistingVersion(V384_FILE_PATTERN));
        try (Connection connection = openConnection()) {
            seedCompany(connection, "S1");
            seedCompany(connection, "S2");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            long companyCount = queryForLong(connection, "SELECT COUNT(*) FROM company");
            long rateCount = queryForLong(connection,
                    "SELECT COUNT(*) FROM transaction_levy_rate_history");
            assertThat(rateCount)
                    .as("C12: cégenként pontosan egy seed-sor")
                    .isEqualTo(companyCount);

            List<String> rows = new ArrayList<>();
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT to_char(effective_from, 'YYYY-MM-DD') || '|' || base_rate_percent"
                            + " || '|' || base_rate_cap_huf || '|' || supplement_rate_percent"
                            + " || '|' || supplement_rate_cap_huf || '|' || conversion_single_side_flag"
                            + " FROM transaction_levy_rate_history")) {
                try (ResultSet resultSet = statement.executeQuery()) {
                    while (resultSet.next()) {
                        rows.add(resultSet.getString(1));
                    }
                }
            }
            assertThat(rows).isNotEmpty();
            assertThat(rows).allSatisfy(value ->
                    assertThat(value).isEqualTo("2013-01-01|0.450|20000.00|0.450|20000.00|true"));
        }
    }

    // =====================================================================
    // E11/E12 — append-only trigger
    // =====================================================================
    @Test
    @DisplayName("E11: UPDATE az append-only táblán kivételt dob")
    void e11_updateRaises() throws Exception {
        migrateToLatest();
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "U1");
            seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 1, 1));

            assertThatThrownBy(() -> execute(connection,
                    "UPDATE transaction_levy_rate_history SET base_rate_percent = 0.5"))
                    .as("E11: UPDATE tiltott (immutable trigger)")
                    .isInstanceOf(SQLException.class);
        }
    }

    @Test
    @DisplayName("E12: DELETE FROM az append-only táblán kivételt dob")
    void e12_deleteRaises() throws Exception {
        migrateToLatest();
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "D1");
            seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 1, 1));

            assertThatThrownBy(() -> execute(connection,
                    "DELETE FROM transaction_levy_rate_history"))
                    .as("E12: DELETE tiltott (immutable trigger)")
                    .isInstanceOf(SQLException.class);
        }
    }

    // =====================================================================
    // E13/E14 — egyedi kulcs és monotonitás DB-szinten
    // =====================================================================
    @Test
    @DisplayName("E13: duplikált (company_id, effective_from) uk_tlrh_company_effective ütközés")
    void e13_duplicateEffectiveFromViolatesUnique() throws Exception {
        migrateToLatest();
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "Q1");
            seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 1, 1));

            assertThatThrownBy(() ->
                    seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 1, 1)))
                    .as("E13: az egyedi kulcs a duplikátumot elutasítja")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uk_tlrh_company_effective");
        }
    }

    @Test
    @DisplayName("E14: új, későbbi effective_from ugyanarra a cégre sikeres (az E13 jó fele)")
    void e14_laterEffectiveFromInserts() throws Exception {
        migrateToLatest();
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "L1");
            seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 1, 1));

            assertThatCode(() ->
                    seedRateRow(connection, companyId, java.time.LocalDate.of(2027, 6, 1)))
                    .as("E14: későbbi hatálybalépés beszúrható")
                    .doesNotThrowAnyException();
        }
    }

    // =====================================================================
    // E15 — idempotencia
    // =====================================================================
    @Test
    @DisplayName("E15: a migrációs SQL újrafuttatása 0 új seed-sort szúr be")
    void e15_seedIdempotent() throws Exception {
        migrateToVersion(previousExistingVersion(V384_FILE_PATTERN));
        try (Connection connection = openConnection()) {
            seedCompany(connection, "I1");
        }
        migrateToLatest();

        long countBefore;
        try (Connection connection = openConnection()) {
            countBefore = queryForLong(connection,
                    "SELECT COUNT(*) FROM transaction_levy_rate_history");
        }

        String sql = Files.readString(resolveMigration(V384_FILE_PATTERN), StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }

        try (Connection connection = openConnection()) {
            assertThat(queryForLong(connection,
                    "SELECT COUNT(*) FROM transaction_levy_rate_history"))
                    .as("E15: a seed újrafuttatása nem duplikál")
                    .isEqualTo(countBefore);
        }
    }

    // =====================================================================
    // E16 — D17 mapping: kihagyott flag → DB default TRUE
    // =====================================================================
    @Test
    @DisplayName("E16/D17: conversion_single_side_flag kihagyása → a DB default true-t ad vissza")
    void e16_omittedFlagDefaultsTrue() throws Exception {
        migrateToLatest();
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "F1");
            execute(connection,
                    "INSERT INTO transaction_levy_rate_history"
                            + " (company_id, effective_from, base_rate_percent, base_rate_cap_huf,"
                            + " supplement_rate_percent, supplement_rate_cap_huf, created_by)"
                            + " VALUES (?, ?, 0.450, 20000.00, 0.450, 20000.00, 'E16')",
                    companyId, java.sql.Date.valueOf(java.time.LocalDate.of(2027, 2, 1)));

            assertThat(queryForString(connection,
                    "SELECT conversion_single_side_flag::text FROM transaction_levy_rate_history"
                            + " WHERE company_id = ?", companyId))
                    .as("E16: a BOOLEAN NOT NULL DEFAULT TRUE oszlop default értéke true")
                    .isEqualTo("true");
        }
    }

    // ============================ FIXTURE HELPEREK ============================

    private static UUID seedCompany(Connection connection, String suffix) throws Exception {
        UUID companyId = UUID.randomUUID();
        execute(connection,
                "INSERT INTO company (id, code, name, is_active, created_at) VALUES (?, ?, ?, true, NOW())",
                companyId, "FK099" + suffix, "FK-099 migration test company " + suffix);
        return companyId;
    }

    private static void seedRateRow(Connection connection, UUID companyId,
                                    java.time.LocalDate effectiveFrom) throws SQLException {
        execute(connection,
                "INSERT INTO transaction_levy_rate_history"
                        + " (company_id, effective_from, base_rate_percent, base_rate_cap_huf,"
                        + " supplement_rate_percent, supplement_rate_cap_huf, conversion_single_side_flag,"
                        + " created_by)"
                        + " VALUES (?, ?, 0.500, 25000.00, 0.500, 25000.00, TRUE, 'TEST')",
                companyId, java.sql.Date.valueOf(effectiveFrom));
    }

    // ============================ STRUKTÚRA HELPEREK ============================

    private static boolean tableExists(Connection connection, String tableName) throws Exception {
        return queryForLong(connection,
                "SELECT COUNT(*) FROM information_schema.tables"
                        + " WHERE table_schema = 'public' AND table_name = ?", tableName) > 0;
    }

    private static List<String> tableColumns(Connection connection, String tableName) throws Exception {
        List<String> columns = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT column_name FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ?"
                        + " ORDER BY ordinal_position")) {
            statement.setString(1, tableName);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    columns.add(resultSet.getString(1));
                }
            }
        }
        return columns;
    }

    // ============================ FLYWAY HELPEREK ============================

    private static Path resolveMigration(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).as("Pontosan 1 migráció várt a mintára: %s", pattern).hasSize(1);
            return matches.get(0);
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Matcher matcher = pattern.matcher(resolveMigration(pattern).getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    /** A cél-verzió ELŐTTI, ténylegesen létező legmagasabb verzió (V383 minta). */
    private static int previousExistingVersion(Pattern pattern) throws IOException {
        int target = version(pattern);
        Pattern anyMigration = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> anyMigration.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError(
                            "Nincs a(z) V" + target + " előtti migráció a könyvtárban"));
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

    private void migrateToLatest() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load()
                .migrate();
    }

    // ============================ SQL HELPEREK ============================

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters)
            throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static long queryForLong(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getString(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
