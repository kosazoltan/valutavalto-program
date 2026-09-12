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
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-067 (spec doc: FKH-063) V392 — client_created_at column + TTL_NONBLOCKING_CUTOFF seed.
 *
 * FR-3 is a DATABASE-level guarantee: on a fresh install the seeded parameter must NOT switch the
 * non-blocking behaviour on. The seed therefore carries an EMPTY value, which
 * SystemParameterService.findEffectiveValue filters to Optional.empty() -> blocking branch.
 */
@Testcontainers
class TtlNonBlockingCutoffV392MigrationPostgresTest {

    private static final Path MIGRATION_DIR = Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh067_ttl_nonblocking_cutoff\\.sql$");

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

    @Test
    @DisplayName("V392: client_created_at oszlop + TTL_NONBLOCKING_CUTOFF sor BIZTONSAGOS (ures) alapertelmezessel")
    void migrationAddsColumnAndSafeDefaultParameter() throws Exception {
        migrateToVersion(previousExistingVersion(FILE_PATTERN));

        try (Connection c = openConnection(); Statement st = c.createStatement()) {
            // Elloallapot: sem az oszlop, sem a parameter-sor nem letezik.
            assertThat(columnExists(st, "transaction", "client_created_at")).isFalse();
            assertThat(globalParameterValue(st, "TTL_NONBLOCKING_CUTOFF")).isNull();
        }

        migrateToLatest();

        try (Connection c = openConnection(); Statement st = c.createStatement()) {
            assertThat(columnExists(st, "transaction", "client_created_at")).isTrue();
            assertThat(columnIsNullable(st, "transaction", "client_created_at")).isTrue();

            // FR-3: a sor letezik, de URES ertekkel -> a findEffectiveValue blank-szurese miatt
            // a szolgaltatas a blokkolo agon marad, amig valaki tudatosan be nem allitja.
            String seeded = globalParameterValue(st, "TTL_NONBLOCKING_CUTOFF");
            assertThat(seeded).isNotNull();
            assertThat(seeded).isEmpty();
            assertThat(parameterType(st, "TTL_NONBLOCKING_CUTOFF")).isEqualTo("DATETIME");
            assertThat(globalParameterIsActive(st, "TTL_NONBLOCKING_CUTOFF")).isTrue();
        }
    }

    @Test
    @DisplayName("V392: idempotens — a mar beallitott cutoff erteket az ujrafuttatas NEM irja felul")
    void rerunDoesNotOverwriteAConfiguredCutoff() throws Exception {
        migrateToLatest();

        String migrationSql = Files.readString(resolveMigrationFile());
        try (Connection c = openConnection(); Statement st = c.createStatement()) {
            // Az uzemelteto tudatosan beallitja a cutoffot.
            st.executeUpdate("UPDATE system_parameter SET parameter_value = '2026-09-12T06:00:00Z' "
                    + "WHERE parameter_key = 'TTL_NONBLOCKING_CUTOFF' AND company_id IS NULL");

            // Redeploy-szimulacio: a migracios SQL ujrafuttatasa.
            st.execute(migrationSql);

            assertThat(globalParameterValue(st, "TTL_NONBLOCKING_CUTOFF")).isEqualTo("2026-09-12T06:00:00Z");
            assertThat(globalParameterRowCount(st, "TTL_NONBLOCKING_CUTOFF")).isEqualTo(1);
        }
    }

    private static boolean columnExists(Statement st, String table, String column) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT 1 FROM information_schema.columns WHERE table_name = '" + table
                        + "' AND column_name = '" + column + "'")) {
            return rs.next();
        }
    }

    private static boolean columnIsNullable(Statement st, String table, String column) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT is_nullable FROM information_schema.columns WHERE table_name = '" + table
                        + "' AND column_name = '" + column + "'")) {
            return rs.next() && "YES".equals(rs.getString(1));
        }
    }

    private static String globalParameterValue(Statement st, String key) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT parameter_value FROM system_parameter WHERE parameter_key = '" + key
                        + "' AND company_id IS NULL")) {
            return rs.next() ? rs.getString(1) : null;
        }
    }

    private static String parameterType(Statement st, String key) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT parameter_type FROM system_parameter WHERE parameter_key = '" + key
                        + "' AND company_id IS NULL")) {
            return rs.next() ? rs.getString(1) : null;
        }
    }

    private static boolean globalParameterIsActive(Statement st, String key) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT is_active FROM system_parameter WHERE parameter_key = '" + key
                        + "' AND company_id IS NULL")) {
            return rs.next() && rs.getBoolean(1);
        }
    }

    private static int globalParameterRowCount(Statement st, String key) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT count(*) FROM system_parameter WHERE parameter_key = '" + key
                        + "' AND company_id IS NULL")) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    private static Path resolveMigrationFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).hasSize(1);
            return matches.get(0);
        }
    }

    /** A cel ELOTTI LETEZO legmagasabb verzio (gap-safe; soha nem "target - 1"). */
    private static int previousExistingVersion(Pattern target) throws IOException {
        int t = version(target);
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < t)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError("Nincs migracio a V" + t + " elott"));
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Matcher m = pattern.matcher(resolveMigrationFile().getFileName().toString());
        assertThat(m.matches()).isTrue();
        return Integer.parseInt(m.group(1));
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
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }
}
