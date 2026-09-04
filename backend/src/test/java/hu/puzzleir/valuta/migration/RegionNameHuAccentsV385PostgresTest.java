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
import java.util.stream.Stream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-104 FR-1 (G1–G5) — the V385 REGION name_hu accent migration on real
 * PostgreSQL. Harness copied verbatim from
 * {@link TransactionLevyRateHistoryV384PostgresTest} (Flyway clean +
 * migrateToVersion + raw JDBC).
 *
 * <p>RED until V385 exists: {@code resolveMigration} fails with
 * "Pontosan 1 migráció várt" because no file matches the pattern.</p>
 */
@Testcontainers
class RegionNameHuAccentsV385PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V385_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk104_region_name_hu_accents.*\\.sql$");

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
    // G1 — RED-repro: the V145 baseline is what the old-value predicate targets
    // =====================================================================
    @Test
    @DisplayName("G1/RED-repro: before V385 the REGION name_hu values are the unaccented V145 seed")
    void g1_redRepro_baselineBeforeV385() throws Exception {
        migrateToVersion(previousExistingVersion(V385_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            assertThat(snapshot(connection, "REGION"))
                    .as("G1: the V145 baseline rows the old-value predicate targets")
                    .contains(
                            "BEKESCSABA|Bekescsaba|Bekescsaba",
                            "SZEKSZARD|Szekszard|Szekszard");
        }
    }

    // =====================================================================
    // G2 — accents applied; code/name byte-identical to before
    // =====================================================================
    @Test
    @DisplayName("G2: migrateToLatest accents the 6 REGION name_hu values; code/name untouched")
    void g2_accentsAppliedAndCodeNameUntouched() throws Exception {
        migrateToVersion(previousExistingVersion(V385_FILE_PATTERN));
        final List<String> before;
        try (Connection connection = openConnection()) {
            before = snapshot(connection, "REGION");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            List<String> after = snapshot(connection, "REGION");
            assertThat(after)
                    .as("G2: the 6 accented name_hu values")
                    .contains(
                            "BEKESCSABA|Bekescsaba|Békéscsaba",
                            "NYIREGYHAZA|Nyiregyhaza|Nyíregyháza",
                            "KECSKEMET|Kecskemet|Kecskemét",
                            "KAPOSVAR|Kaposvar|Kaposvár",
                            "PECS|Pecs|Pécs",
                            "SZEKSZARD|Szekszard|Szekszárd");
            // code|name prefix of every row must equal its before value.
            for (String line : after) {
                String prefix = line.substring(0, line.lastIndexOf('|'));
                String code = line.substring(0, line.indexOf('|'));
                assertThat(before.stream().filter(b -> b.startsWith(code + "|")).findFirst())
                        .as("G2: row %s present before migration", code)
                        .isPresent();
                String beforeLine = before.stream()
                        .filter(b -> b.startsWith(code + "|")).findFirst().orElseThrow();
                assertThat(beforeLine.substring(0, beforeLine.lastIndexOf('|')))
                        .as("G2: code|name prefix unchanged for %s", code)
                        .isEqualTo(prefix);
            }
        }
    }

    // =====================================================================
    // G3 — untouched rows stay byte-identical (incl. NATIONALITY)
    // =====================================================================
    @Test
    @DisplayName("G3: IRODA/DEBRECEN/SZEGED and the whole NATIONALITY category are untouched")
    void g3_untouchedRowsByteIdentical() throws Exception {
        migrateToVersion(previousExistingVersion(V385_FILE_PATTERN));
        final List<String> nationalityBefore;
        try (Connection connection = openConnection()) {
            nationalityBefore = snapshot(connection, "NATIONALITY");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(snapshot(connection, "REGION"))
                    .as("G3: rows not listed in V385 stay as seeded by V145")
                    .contains(
                            "IRODA|Central Office|Iroda",
                            "DEBRECEN|Debrecen|Debrecen",
                            "SZEGED|Szeged|Szeged");
            assertThat(snapshot(connection, "NATIONALITY"))
                    .as("G3: NATIONALITY byte-identical before/after V385")
                    .isEqualTo(nationalityBefore);
        }
    }

    // =====================================================================
    // G4 — hand-fixed row skipped (old-value predicate)
    // =====================================================================
    @Test
    @DisplayName("G4: a hand-fixed name_hu (third value) is NOT overwritten by V385")
    void g4_handFixedRowSkipped() throws Exception {
        migrateToVersion(previousExistingVersion(V385_FILE_PATTERN));
        try (Connection connection = openConnection()) {
            execute(connection,
                    "UPDATE dictionary SET name_hu = ? WHERE category='REGION' AND code='PECS'",
                    "Pécs (kézi)");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForString(connection,
                    "SELECT name_hu FROM dictionary WHERE category='REGION' AND code='PECS'"))
                    .as("G4: the hand-fixed value survives (predicate mismatch)")
                    .isEqualTo("Pécs (kézi)");
        }
    }

    // =====================================================================
    // G5 — idempotency over the whole dictionary table
    // =====================================================================
    @Test
    @DisplayName("G5: re-executing the V385 file leaves the whole dictionary byte-identical")
    void g5_idempotent() throws Exception {
        migrateToLatest();

        final List<String> all;
        try (Connection connection = openConnection()) {
            all = snapshotAll(connection);
        }

        String sql = Files.readString(resolveMigration(V385_FILE_PATTERN), StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }

        try (Connection connection = openConnection()) {
            assertThat(snapshotAll(connection))
                    .as("G5: re-running V385 changes nothing")
                    .isEqualTo(all);
        }
    }

    // ============================ SNAPSHOT HELPEREK ============================

    /** "code|name|name_hu" rows for one category, ORDER BY code. */
    private static List<String> snapshot(Connection connection, String category) throws Exception {
        List<String> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT code || '|' || name || '|' || name_hu FROM dictionary"
                        + " WHERE category = ? ORDER BY code")) {
            statement.setString(1, category);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(resultSet.getString(1));
                }
            }
        }
        return rows;
    }

    /** "category|code|name|name_hu" rows for the whole table, ORDER BY category, code. */
    private static List<String> snapshotAll(Connection connection) throws Exception {
        List<String> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT category || '|' || code || '|' || name || '|' || name_hu FROM dictionary"
                        + " ORDER BY category, code")) {
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(resultSet.getString(1));
                }
            }
        }
        return rows;
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

    /** A cél-verzió ELŐTTI, ténylegesen létező legmagasabb verzió (gap-safe). */
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
