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
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

@Testcontainers
class ClosingControlAlertLevelDropMigrationPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__.*alert_level.*\\.sql$");

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
    @DisplayName("RED-repro: previousExistingVersion still has alert_level")
    void previousVersionHasAlertLevel() throws Exception {
        migrateToVersion(previousExistingVersion(FILE_PATTERN));
        try (Connection connection = open()) {
            assertThat(columnExists(connection, "closing_control", "alert_level")).isTrue();
        }
    }

    @Test
    @DisplayName("migrate to latest: alert_level column and idx_closing_control_alert gone")
    void latestDropsColumnAndIndex() throws Exception {
        migrateToLatest();
        try (Connection connection = open()) {
            assertThat(columnExists(connection, "closing_control", "alert_level")).isFalse();
            assertThat(indexExists(connection, "idx_closing_control_alert")).isFalse();
        }
    }

    @Test
    @DisplayName("re-running V388 SQL is idempotent")
    void sqlIdempotent() throws Exception {
        migrateToLatest();
        Path file = matchingFile();
        String sql = Files.readString(file);
        try (Connection connection = open()) {
            assertThatCode(() -> connection.createStatement().execute(sql)).doesNotThrowAnyException();
            assertThat(columnExists(connection, "closing_control", "alert_level")).isFalse();
        }
    }

    @Test
    @DisplayName("V388 filename matches Pattern and version > V387")
    void filenameAndVersion() throws Exception {
        assertThat(version(FILE_PATTERN)).isGreaterThan(387);
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

    private static int version(Pattern pattern) throws IOException {
        Path file = matchingFile();
        Matcher matcher = pattern.matcher(file.getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    private static int previousExistingVersion(Pattern pattern) throws IOException {
        int target = version(pattern);
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

    private static boolean columnExists(Connection connection, String table, String column) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT 1 FROM information_schema.columns WHERE table_name = ? AND column_name = ?")) {
            statement.setString(1, table);
            statement.setString(2, column);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static boolean indexExists(Connection connection, String indexName) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT 1 FROM pg_indexes WHERE indexname = ?")) {
            statement.setString(1, indexName);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next();
            }
        }
    }
}
