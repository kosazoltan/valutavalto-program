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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-062: V390 closes orphaned (superseded) open worker_session rows.
 *
 * <p>Production evidence (2026-09-11): 1533 of 1772 worker_session rows had
 * {@code logout_at IS NULL}; 1523 of those were superseded — the same worker had a later
 * login — because the pre-FKH-061 logout path closed at most one row and threw HTTP 500 when
 * several were open. V390 sets {@code logout_at} to the next login of the same worker, which is
 * the latest instant at which the session was provably over.</p>
 *
 * <p>Three mandatory shapes are covered: the happy path, the fail-closed path (rows whose state
 * does not match are left untouched — already closed rows, rows with no later login, and rows
 * of a DIFFERENT worker), and idempotency by re-executing the raw SQL file twice after Flyway
 * already applied it.</p>
 */
@Testcontainers
class WorkerSessionOrphanLogoutBackfillV390PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh062_worker_session_orphan_logout_backfill\\.sql$");

    private static final UUID COMPANY_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID BRANCH_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final long WORKER_A = 960001L;
    private static final long WORKER_B = 960002L;

    private static final LocalDateTime T1 = LocalDateTime.parse("2026-03-13T17:29:56");
    private static final LocalDateTime T2 = LocalDateTime.parse("2026-04-02T08:00:00");
    private static final LocalDateTime T3 = LocalDateTime.parse("2026-05-19T17:42:19");
    private static final LocalDateTime MANUAL_LOGOUT = LocalDateTime.parse("2026-03-13T18:05:00");

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
    @DisplayName("V390 closes every superseded open row at the next login of the same worker")
    void closesSupersededRowsAtNextLogin() throws Exception {
        migrateToVersion(previousExistingVersion());
        try (Connection connection = open()) {
            seedTenant(connection);
            insertSession(connection, 1L, WORKER_A, T1, null);
            insertSession(connection, 2L, WORKER_A, T2, null);
            insertSession(connection, 3L, WORKER_A, T3, null);
            // RED: before V390 all three rows are open.
            assertThat(openCount(connection)).isEqualTo(3);
        }

        migrateToLatest();

        try (Connection connection = open()) {
            assertThat(logoutAt(connection, 1L)).isEqualTo(T2);
            assertThat(logoutAt(connection, 2L)).isEqualTo(T3);
            // The worker's most recent row may be a live session -> untouched.
            assertThat(logoutAt(connection, 3L)).isNull();
            assertThat(openCount(connection)).isEqualTo(1);
            assertThat(invalidDurationCount(connection)).isZero();
        }
    }

    @Test
    @DisplayName("fail-closed: manually closed rows, last rows and other workers stay untouched")
    void leavesNonMatchingStateUntouched() throws Exception {
        migrateToVersion(previousExistingVersion());
        try (Connection connection = open()) {
            seedTenant(connection);
            // Already closed by hand (an operator fix) -> the value must survive verbatim.
            insertSession(connection, 10L, WORKER_A, T1, MANUAL_LOGOUT);
            insertSession(connection, 11L, WORKER_A, T2, null);
            // Worker B logged in LATER than worker A's open row, but that is another worker:
            // a cross-worker close would fabricate an end for a session still running.
            insertSession(connection, 20L, WORKER_B, T3, null);
        }

        migrateToLatest();

        try (Connection connection = open()) {
            assertThat(logoutAt(connection, 10L))
                    .as("manual logout preserved, not overwritten with T2")
                    .isEqualTo(MANUAL_LOGOUT);
            assertThat(logoutAt(connection, 11L))
                    .as("worker A's last row has no later login of its own worker")
                    .isNull();
            assertThat(logoutAt(connection, 20L))
                    .as("worker B's only row stays open")
                    .isNull();
            assertThat(openCount(connection)).isEqualTo(2);
        }
    }

    @Test
    @DisplayName("re-running the V390 SQL twice changes nothing (idempotent)")
    void rawSqlIsIdempotent() throws Exception {
        migrateToVersion(previousExistingVersion());
        try (Connection connection = open()) {
            seedTenant(connection);
            insertSession(connection, 1L, WORKER_A, T1, null);
            insertSession(connection, 2L, WORKER_A, T2, null);
            insertSession(connection, 3L, WORKER_A, T3, null);
        }

        migrateToLatest();

        String sql = Files.readString(matchingFile());
        try (Connection connection = open(); Statement st = connection.createStatement()) {
            st.execute(sql);
            st.execute(sql);
            // Still T2 and T3 — not shifted to T3/NULL, and row 3 never gets a fabricated end.
            assertThat(logoutAt(connection, 1L)).isEqualTo(T2);
            assertThat(logoutAt(connection, 2L)).isEqualTo(T3);
            assertThat(logoutAt(connection, 3L)).isNull();
            assertThat(openCount(connection)).isEqualTo(1);
        }
    }

    @Test
    @DisplayName("V390 filename matches the expected pattern and its version is above V389")
    void filenameAndVersion() throws Exception {
        assertThat(version()).isGreaterThan(389);
    }

    // ============ helpers ============

    /** Minimal FK-valid chain: company -> branch -> two workers. Values are bound, never concatenated. */
    private static void seedTenant(Connection connection) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO company (id, code, name) VALUES (?, ?, ?)")) {
            ps.setObject(1, COMPANY_ID);
            ps.setString(2, "FKH062C");
            ps.setString(3, "FKH-062 test company");
            ps.executeUpdate();
        }
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO branch (id, code, company_id, name) VALUES (?, ?, ?, ?)")) {
            ps.setObject(1, BRANCH_ID);
            ps.setString(2, "FKH062B");
            ps.setObject(3, COMPANY_ID);
            ps.setString(4, "FKH-062 test branch");
            ps.executeUpdate();
        }
        insertWorker(connection, WORKER_A, "FKH062A");
        insertWorker(connection, WORKER_B, "FKH062BB");
    }

    private static void insertWorker(Connection connection, long id, String code) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO worker (id, company_id, code, name, password_hash, role, branch_id) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?)")) {
            ps.setLong(1, id);
            ps.setObject(2, COMPANY_ID);
            ps.setString(3, code);
            ps.setString(4, "FKH-062 test worker " + code);
            ps.setString(5, "x");
            ps.setString(6, "CASHIER");
            ps.setObject(7, BRANCH_ID);
            ps.executeUpdate();
        }
    }

    private static void insertSession(Connection connection, long id, long workerId,
                                      LocalDateTime loginAt, LocalDateTime logoutAt)
            throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO worker_session (id, company_id, worker_id, branch_id, login_at, logout_at) "
                        + "VALUES (?, ?, ?, ?, ?, ?)")) {
            ps.setLong(1, id);
            ps.setObject(2, COMPANY_ID);
            ps.setLong(3, workerId);
            ps.setObject(4, BRANCH_ID);
            ps.setTimestamp(5, Timestamp.valueOf(loginAt));
            ps.setTimestamp(6, logoutAt == null ? null : Timestamp.valueOf(logoutAt));
            ps.executeUpdate();
        }
    }

    private static LocalDateTime logoutAt(Connection connection, long id) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT logout_at FROM worker_session WHERE id = ?")) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                assertThat(rs.next()).as("worker_session row %s exists", id).isTrue();
                Timestamp value = rs.getTimestamp(1);
                return value == null ? null : value.toLocalDateTime();
            }
        }
    }

    private static long openCount(Connection connection) throws SQLException {
        return scalar(connection, "SELECT count(*) FROM worker_session WHERE logout_at IS NULL");
    }

    private static long invalidDurationCount(Connection connection) throws SQLException {
        return scalar(connection,
                "SELECT count(*) FROM worker_session WHERE logout_at IS NOT NULL AND logout_at <= login_at");
    }

    private static long scalar(Connection connection, String sql) throws SQLException {
        try (Statement st = connection.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            assertThat(rs.next()).isTrue();
            return rs.getLong(1);
        }
    }

    private static Path matchingFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).hasSize(1);
            return matches.get(0);
        }
    }

    private static int version() throws IOException {
        Matcher matcher = FILE_PATTERN.matcher(matchingFile().getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    private static int previousExistingVersion() throws IOException {
        int target = version();
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError("no migration before V" + target));
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

    private static Connection open() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }
}
