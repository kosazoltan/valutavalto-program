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
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-066 FR-4 — a pénznemenkénti zárás-tolerancia seed-migráció valós-DB viselkedése
 * (V361-minta: Testcontainers + Flyway; CI-ben fut, lokálisan Docker kell).
 *
 * <p>SZERZŐDÉS (GREEN-fázis seed-döntés, user-jóváhagyással 2026-07-27: 3 soros seed —
 * a korábbi „csak HUF” pin dokumentált spec-változásként bővült):
 * <ul>
 *   <li>Friss DB-n a migráció GLOBÁLIS (company_id IS NULL) sorokat seedel:
 *       CLOSING_TOLERANCE_HUF='5', CLOSING_TOLERANCE_EUR='1', CLOSING_TOLERANCE_USD='1'
 *       (parameter_type=NUMBER, category=CLOSING); más CLOSING_TOLERANCE_% sor nem
 *       keletkezik.</li>
 *   <li>A seed-SQL újrafuttatása idempotens: nem duplikál, értéket nem változtat.</li>
 *   <li>Meglévő (üzemeltető által testre szabott) globális sort a migráció NEM ír
 *       felül (SEED-DÖNTÉS: nincs update-if-different ág).</li>
 * </ul>
 *
 * <p>FK-073 (dokumentált spec-változás, NEM teszt-gyengítés): a V373 migráció az
 * egyszeri üzleti döntés alapján TUDATOSAN felülírja a fenti „nincs update-ág”
 * szerződést — a végállapot mindhárom globális sorra érték=0, is_active=true.
 * Az alábbi tesztek ezért a V373 utáni végállapotot (0/0/0) asszertálják.
 */
@Testcontainers
class ClosingToleranceSeedFk066MigrationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern SEED_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__.*closing_tolerance.*\\.sql$");

    /**
     * A @Container statikus (V361-minta), így a tesztek EGY Postgres-en osztoznak —
     * a determinisztikus, sorrendfüggetlen állapothoz minden teszt tiszta DB-ről indul.
     */
    @org.junit.jupiter.api.BeforeEach
    void cleanDatabase() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .cleanDisabled(false)
                .load()
                .clean();
    }

    /** A seed-migráció fájlja + verziószáma (nem hardkódolt — mintára keres). */
    private static Path resolveSeedMigration() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> SEED_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("FK-066 FR-4: pontosan egy V<n>__*closing_tolerance*.sql seed-migráció kell")
                    .hasSize(1);
            return matches.get(0);
        }
    }

    private static int seedVersionOf(Path seedFile) {
        Matcher m = SEED_FILE_PATTERN.matcher(seedFile.getFileName().toString());
        assertThat(m.matches()).isTrue();
        return Integer.parseInt(m.group(1));
    }

    @Test
    @DisplayName("FK-066 FR-4 + FK-073: friss DB-n a globális sorok végállapota HUF='0'/EUR='0'/USD='0' (V364 seed + V373 felülírás), és csak azok")
    void freshDatabaseSeedsGlobalRows() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            for (String[] expected : new String[][]{
                    {"CLOSING_TOLERANCE_HUF", "0"},
                    {"CLOSING_TOLERANCE_EUR", "0"},
                    {"CLOSING_TOLERANCE_USD", "0"}}) {
                assertThat(queryForString(connection, """
                        SELECT parameter_value || '|' || parameter_type || '|' || category
                               || '|' || is_active::text
                          FROM system_parameter
                         WHERE parameter_key = '%s' AND company_id IS NULL
                        """.formatted(expected[0])))
                        .as(expected[0])
                        .isEqualTo(expected[1] + "|NUMBER|CLOSING|true");
            }
            assertThat(queryForLong(connection, """
                    SELECT COUNT(*) FROM system_parameter
                     WHERE parameter_key LIKE 'CLOSING_TOLERANCE\\_%' ESCAPE '\\'
                    """))
                    .as("Pontosan a 3 seedelt sor — más pénznemre kód-szintű fallback él")
                    .isEqualTo(3L);
        }
    }

    @Test
    @DisplayName("FK-066 FR-4: a seed-SQL kétszeri újrafuttatása idempotens — nem duplikál, értéket nem módosít")
    void rerunningSeedSqlDoesNotDuplicate() throws Exception {
        migrateToLatest();
        String seedSql = Files.readString(resolveSeedMigration(), StandardCharsets.UTF_8);

        try (Connection connection = openConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(seedSql);
            statement.execute(seedSql);

            assertThat(queryForLong(connection, """
                    SELECT COUNT(*) FROM system_parameter
                     WHERE parameter_key LIKE 'CLOSING_TOLERANCE\\_%' ESCAPE '\\'
                    """)).isEqualTo(3L);
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF' AND company_id IS NULL
                    """)).isEqualTo("0");
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_EUR' AND company_id IS NULL
                    """)).isEqualTo("0");
        }
    }

    @Test
    @DisplayName("FK-066 Codex M2: meglévő CÉGES HUF-override nem nyomja el a globális seedeket — mind a 3 globál létrejön, a céges sor érintetlen")
    void companyOverrideDoesNotSuppressGlobalSeeds() throws Exception {
        int seedVersion = seedVersionOf(resolveSeedMigration());
        migrateToVersion(seedVersion - 1);

        UUID companyId = UUID.fromString("11111111-3640-0000-0000-000000000001");
        try (Connection connection = openConnection()) {
            execute(connection, """
                    INSERT INTO company (id, code, name, is_active, created_at)
                    VALUES (?, 'FK066', 'FK-066 Test Company', true, NOW())
                    """, companyId);
            execute(connection, """
                    INSERT INTO system_parameter
                        (id, parameter_key, parameter_value, parameter_type, category, description, is_active, company_id)
                    VALUES (gen_random_uuid(), 'CLOSING_TOLERANCE_HUF', '2', 'NUMBER', 'CLOSING',
                            'FK-066 teszt: céges override a seed előtt', true, ?)
                    """, companyId);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            // A globális seedek a céges override-tól FÜGGETLENÜL létrejönnek;
            // FK-073: a V373 utáni végállapot 0/0/0 (a céges override-ot nem érinti):
            for (String[] expected : new String[][]{
                    {"CLOSING_TOLERANCE_HUF", "0"},
                    {"CLOSING_TOLERANCE_EUR", "0"},
                    {"CLOSING_TOLERANCE_USD", "0"}}) {
                assertThat(queryForString(connection, """
                        SELECT parameter_value FROM system_parameter
                         WHERE parameter_key = '%s' AND company_id IS NULL
                        """.formatted(expected[0])))
                        .as("globális seed: " + expected[0])
                        .isEqualTo(expected[1]);
            }
            // A céges override érintetlen (nem íródik felül, nem duplikálódik):
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF' AND company_id = '%s'
                    """.formatted(companyId)))
                    .isEqualTo("2");
            assertThat(queryForLong(connection, """
                    SELECT COUNT(*) FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF'
                    """))
                    .as("pontosan 2 HUF-sor: 1 globál + 1 céges")
                    .isEqualTo(2L);
        }
    }

    @Test
    @DisplayName("FK-073: a V373 az egyszeri üzleti döntés alapján a testre szabott globális értéket ('3') is 0-ra írja (a V364 'nincs update-ág' szerződésének tudatos felülírása)")
    void existingCustomValueIsPreserved() throws Exception {
        int seedVersion = seedVersionOf(resolveSeedMigration());
        migrateToVersion(seedVersion - 1);

        try (Connection connection = openConnection()) {
            execute(connection, """
                    INSERT INTO system_parameter
                        (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
                    VALUES (gen_random_uuid(), 'CLOSING_TOLERANCE_HUF', '3', 'NUMBER', 'CLOSING',
                            'FK-066 teszt: üzemeltető által testre szabott tolerancia', true)
                    """);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF' AND company_id IS NULL
                    """))
                    .as("FK-073 (dokumentált spec-változás): a V373 TUDATOSAN felülírja a V364 "
                            + "'nincs update-ág' szerződését — a '3' egyszeri üzleti döntéssel '0'-ra változik")
                    .isEqualTo("0");
            assertThat(queryForLong(connection, """
                    SELECT COUNT(*) FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF'
                    """)).isEqualTo(1L);
            // A hiányzó EUR/USD sorokat a migráció ettől függetlenül seedeli (V373 után 0 értékkel):
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_EUR' AND company_id IS NULL
                    """)).isEqualTo("0");
            assertThat(queryForString(connection, """
                    SELECT parameter_value FROM system_parameter
                     WHERE parameter_key = 'CLOSING_TOLERANCE_USD' AND company_id IS NULL
                    """)).isEqualTo("0");
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
            for (int index = 0; index < parameters.length; index++) {
                statement.setObject(index + 1, parameters[index]);
            }
            statement.executeUpdate();
        }
    }

    private static long queryForLong(Connection connection, String sql) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            assertThat(resultSet.next()).isTrue();
            return resultSet.getLong(1);
        }
    }

    private static String queryForString(Connection connection, String sql) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            return resultSet.next() ? resultSet.getString(1) : null;
        }
    }
}
