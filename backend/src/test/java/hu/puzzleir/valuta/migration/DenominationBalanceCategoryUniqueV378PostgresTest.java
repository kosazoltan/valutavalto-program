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
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * FKH-033 (PR #1588 BLOCK-verdikt utokezelese): a {@code denomination_balance} tabla
 * V75-os egyedi kulcsa {@code (cash_desk_id, denomination_id)} volt, holott a V105 ota a
 * sor KATEGORIAVAL is tagelodik ({@code EVENING} / {@code HANDLING_FEE} / ...).
 *
 * <p>Kovetkezmeny elesben: ugyanarra a (penztar, cimlet) parra a MASODIK kategoria
 * mentese unique-utkozest dob ({@code DataIntegrityViolationException} / HTTP 500), es a
 * torvenyileg kotelezo napi zaras varazsloja osszeomlik. Jelenleg csak a kikapcsolt
 * {@code FEATURE_HANDLING_FEE_DENOMINATION} flag fedi el a hibat.</p>
 *
 * <p>Bizonyitando allitasok:</p>
 * <ul>
 *   <li>RED-repro: a V378 ELOTTI semaban a masodik kategoria beszurasa MEGHIUSUL.</li>
 *   <li>FR-1: a V378 utan a regi kulcs mar nincs meg, helyette
 *       {@code (cash_desk_id, denomination_id, denomination_category)} all.</li>
 *   <li>FR-2: a V378 utan ugyanaz a beszuras SIKERES — a ket kategoria egyutt el.</li>
 *   <li>FR-3: az uj kulcs tovabbra is vedi az AZONOS kategoriaju duplikatumot.</li>
 *   <li>NFR-1: legacy adat nem veszik el es nem valtozik (backfill-mentes atallas).</li>
 *   <li>NFR-2: a migracio ujrafuttathato (IF EXISTS / IF NOT EXISTS).</li>
 * </ul>
 */
@Testcontainers
class DenominationBalanceCategoryUniqueV378PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V378_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh033_denomination_balance.*\\.sql$");

    private static final String OLD_CONSTRAINT = "uk_denom_balance_desk_denom";
    private static final String NEW_CONSTRAINT = "uk_denom_balance_desk_denom_category";

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
    // RED-repro — a V378 ELOTTI allapot
    // =====================================================================
    @Test
    @DisplayName("RED-repro: a V378 elotti semaban az ELSO HANDLING_FEE cimlet-mentes "
            + "unique-utkozest dob (ez omlasztotta ossze a zarasi varazslot)")
    void v378ElottiSemabanAMasodikKategoriaUtkozik() throws Exception {
        migrateToVersion(previousExistingVersion(V378_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            Fixture fixture = seedDenomination(connection);
            insertBalance(connection, fixture, "EVENING", 10, new BigDecimal("100000.00"));

            assertThatThrownBy(() ->
                    insertBalance(connection, fixture, "HANDLING_FEE", 3, new BigDecimal("30000.00")))
                    .as("A V75-os (cash_desk_id, denomination_id) kulcs a MASODIK kategoriat is duplikatumnak veszi")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining(OLD_CONSTRAINT);
        }
    }

    // =====================================================================
    // FR-1 / FR-2 / FR-3 — a V378 utani allapot
    // =====================================================================
    @Test
    @DisplayName("V378/FR-1: a kategoria-mentes kulcs eltunik, a kategoria-tudatos kulcs all")
    void v378LecsereliAzEgyediKulcsot() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintColumns(connection, OLD_CONSTRAINT))
                    .as("FR-1: a regi, kategoria-mentes kulcs megszunt")
                    .isEmpty();
            assertThat(uniqueConstraintColumns(connection, NEW_CONSTRAINT))
                    .as("FR-1: az uj kulcs a kategoriat is tartalmazza, ebben a sorrendben")
                    .containsExactly("cash_desk_id", "denomination_id", "denomination_category");
        }
    }

    @Test
    @DisplayName("V378/FR-2: ugyanarra a (penztar, cimlet) parra EVENING es HANDLING_FEE "
            + "sor egyutt letezhet — a zarasi varazslo nem all meg")
    void v378UtanAKetKategoriaEgyuttEl() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            Fixture fixture = seedDenomination(connection);
            insertBalance(connection, fixture, "EVENING", 10, new BigDecimal("100000.00"));

            assertThatCode(() ->
                    insertBalance(connection, fixture, "HANDLING_FEE", 3, new BigDecimal("30000.00")))
                    .as("FR-2: a masodik kategoria mentese mar nem utkozik")
                    .doesNotThrowAnyException();

            assertThat(totalValue(connection, fixture, "EVENING"))
                    .as("FR-2: az esti sor valtozatlan")
                    .isEqualByComparingTo("100000.00");
            assertThat(totalValue(connection, fixture, "HANDLING_FEE"))
                    .as("FR-2: a kezelesi dij sor kulon sorkent all")
                    .isEqualByComparingTo("30000.00");
        }
    }

    @Test
    @DisplayName("V378/FR-3: az AZONOS kategoriaju duplikatumot az uj kulcs tovabbra is tiltja")
    void v378TovabbraIsTiltjaAzAzonosKategoriajuDuplikatumot() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            Fixture fixture = seedDenomination(connection);
            insertBalance(connection, fixture, "EVENING", 10, new BigDecimal("100000.00"));

            assertThatThrownBy(() ->
                    insertBalance(connection, fixture, "EVENING", 4, new BigDecimal("40000.00")))
                    .as("FR-3: a kategorian BELULI upsert-kulcs vedelme megmarad")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining(NEW_CONSTRAINT);
        }
    }

    // =====================================================================
    // NFR-1 — legacy adat serthetetlen
    // =====================================================================
    @Test
    @DisplayName("V378/NFR-1: a V378 elott letrehozott sor valtozatlanul atmegy (nincs backfill/torles)")
    void v378NemNyulALegacyAdathoz() throws Exception {
        migrateToVersion(previousExistingVersion(V378_FILE_PATTERN));

        UUID balanceId;
        Fixture fixture;
        try (Connection connection = openConnection()) {
            fixture = seedDenomination(connection);
            balanceId = insertBalance(connection, fixture, "EVENING", 7, new BigDecimal("70000.00"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(rowCount(connection))
                    .as("NFR-1: a migracio nem torol sort")
                    .isEqualTo(1);
            assertThat(totalValue(connection, fixture, "EVENING"))
                    .as("NFR-1: az osszeg valtozatlan")
                    .isEqualByComparingTo("70000.00");
            assertThat(quantityById(connection, balanceId))
                    .as("NFR-1: a darabszam valtozatlan")
                    .isEqualTo(7);
        }
    }

    // =====================================================================
    // NFR-2 — idempotencia
    // =====================================================================
    @Test
    @DisplayName("V378/NFR-2: a nyers SQL ujrafuttatasa hiba nelkul lefut es nem valtoztat a semen")
    void v378Idempotens() throws Exception {
        migrateToLatest();

        String sql = Files.readString(resolveMigration(V378_FILE_PATTERN),
                java.nio.charset.StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute(sql);
            statement.execute(sql);
        }

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintColumns(connection, NEW_CONSTRAINT))
                    .as("NFR-2: ujrafuttatas utan is pontosan egy, helyes kulcs all")
                    .containsExactly("cash_desk_id", "denomination_id", "denomination_category");
            assertThat(uniqueConstraintColumns(connection, OLD_CONSTRAINT)).isEmpty();
        }
    }

    // =====================================================================
    // PROD-PARITAS — a kulcs NEVE kornyezetenkent elter
    // =====================================================================

    /**
     * Eles Gate A meres (2026-08-10): a prod adatbazisban a kategoria-mentes kulcs neve
     * NEM {@code uk_denom_balance_desk_denom} (ahogy a V75 letrehozza), hanem a Hibernate
     * altal generalt {@code uk4g8glqo7rah6ebhlltscwyvdx}. Egy nevre szolo
     * {@code DROP CONSTRAINT IF EXISTS} ezert elesben NEMA NO-OP lenne: minden teszt zold
     * maradna, mikozben a hiba a prodban valtozatlanul all.
     *
     * <p>Ez a teszt pontosan azt a helyzetet allitja elo: atnevezi a kulcsot a prodban mert
     * nevre, majd lefuttatja a migraciot. A DROP-nak a SZERKEZET (oszloppar) alapjan kell
     * megtalalnia, nem nev szerint.</p>
     */
    @Test
    @DisplayName("V378/PROD-PARITAS: a kategoria-mentes kulcsot AKKOR is eltavolitja, ha a neve "
            + "Hibernate-generalt (uk4g8glqo7rah6ebhlltscwyvdx), nem a V75-os nev")
    void v378EltavolitjaAzElteroNevuKulcsotIs() throws Exception {
        migrateToVersion(previousExistingVersion(V378_FILE_PATTERN));

        String prodStyleName = "uk4g8glqo7rah6ebhlltscwyvdx";
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute("ALTER TABLE denomination_balance RENAME CONSTRAINT "
                    + OLD_CONSTRAINT + " TO " + prodStyleName);
        }

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintColumns(connection, prodStyleName))
                    .as("Elofeltetel: a prod-szeru nevu, kategoria-mentes kulcs all")
                    .containsExactly("cash_desk_id", "denomination_id");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(uniqueConstraintColumns(connection, prodStyleName))
                    .as("A nev-agnosztikus DROP a Hibernate-nevu kulcsot is eltavolitja — "
                            + "enelkul a javitas elesben hatastalan lenne")
                    .isEmpty();
            assertThat(uniqueConstraintColumns(connection, NEW_CONSTRAINT))
                    .as("es a kategoria-tudatos kulcs a helyere kerul")
                    .containsExactly("cash_desk_id", "denomination_id", "denomination_category");

            // A viselkedes is bizonyitando, nem csak a katalogus: a ket kategoria elfer.
            Fixture fixture = seedDenomination(connection);
            insertBalance(connection, fixture, "EVENING", 10, new BigDecimal("100000.00"));
            assertThatCode(() ->
                    insertBalance(connection, fixture, "HANDLING_FEE", 3, new BigDecimal("30000.00")))
                    .doesNotThrowAnyException();
        }
    }

    // ============================ ARRANGE ============================

    private record Fixture(UUID companyId, UUID branchId, long denominationId) {
    }

    private static Fixture seedDenomination(Connection connection) throws Exception {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        String suffix = companyId.toString().substring(0, 8);

        execute(connection,
                "INSERT INTO company (id, code, name, is_active, created_at) VALUES (?, ?, ?, true, NOW())",
                companyId, "F" + suffix, "FKH-033 migration test company");
        execute(connection,
                "INSERT INTO branch (id, code, company_id, name) VALUES (?, ?, ?, ?)",
                branchId, "B" + suffix, companyId, "FKH-033 migration test branch");

        long currencyId = queryForLong(connection, "SELECT id FROM currency WHERE code = 'HUF'");
        long denominationId;
        try (PreparedStatement statement = connection.prepareStatement("""
                INSERT INTO denomination
                    (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                VALUES (?, ?, ?, 10000, 'BANKNOTE', 0, true)
                RETURNING id
                """)) {
            bind(statement, companyId, branchId, currencyId);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                denominationId = resultSet.getLong(1);
            }
        }
        return new Fixture(companyId, branchId, denominationId);
    }

    private static UUID insertBalance(Connection connection, Fixture fixture, String category,
                                      int quantity, BigDecimal totalValue) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement statement = connection.prepareStatement("""
                INSERT INTO denomination_balance
                    (id, cash_desk_id, denomination_id, quantity, total_value, updated_at,
                     denomination_category, submission_date)
                VALUES (?, ?, ?, ?, ?, NOW(), ?, ?)
                """)) {
            statement.setObject(1, id);
            statement.setObject(2, fixture.branchId());
            statement.setLong(3, fixture.denominationId());
            statement.setInt(4, quantity);
            statement.setBigDecimal(5, totalValue);
            statement.setString(6, category);
            statement.setObject(7, LocalDate.of(2026, 8, 10));
            statement.executeUpdate();
        }
        return id;
    }

    // ============================ ASSERT HELPEREK ============================

    /** Az adott nevu UNIQUE kulcs oszlopai, kulcs-sorrendben; ures lista, ha a kulcs nincs. */
    private static List<String> uniqueConstraintColumns(Connection connection, String constraintName)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT a.attname
                  FROM pg_constraint con
                  JOIN pg_class rel ON rel.oid = con.conrelid
                  JOIN unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord) ON TRUE
                  JOIN pg_attribute a ON a.attrelid = rel.oid AND a.attnum = k.attnum
                 WHERE rel.relname = 'denomination_balance'
                   AND con.conname = ?
                   AND con.contype = 'u'
                 ORDER BY k.ord
                """)) {
            statement.setString(1, constraintName);
            try (ResultSet resultSet = statement.executeQuery()) {
                List<String> columns = new java.util.ArrayList<>();
                while (resultSet.next()) {
                    columns.add(resultSet.getString(1));
                }
                return columns;
            }
        }
    }

    private static BigDecimal totalValue(Connection connection, Fixture fixture, String category)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT total_value FROM denomination_balance
                 WHERE cash_desk_id = ? AND denomination_id = ? AND denomination_category = ?
                """)) {
            statement.setObject(1, fixture.branchId());
            statement.setLong(2, fixture.denominationId());
            statement.setString(3, category);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Sor vart: %s", category).isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
    }

    private static int quantityById(Connection connection, UUID balanceId) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT quantity FROM denomination_balance WHERE id = ?")) {
            statement.setObject(1, balanceId);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getInt(1);
            }
        }
    }

    private static long rowCount(Connection connection) throws Exception {
        return queryForLong(connection, "SELECT COUNT(*) FROM denomination_balance");
    }

    // ============================ FLYWAY HELPEREK ============================

    private static Path resolveMigration(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches).as("Pontosan 1 migracio vart a mintara: %s", pattern).hasSize(1);
            return matches.get(0);
        }
    }

    private static int version(Pattern pattern) throws IOException {
        Matcher matcher = pattern.matcher(resolveMigration(pattern).getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    /**
     * A megadott migracio ELOTTI, TENYLEGESEN LETEZO verzio — a naiv {@code version - 1}
     * eltorik, ha a szamozasban lyuk van (masik nyitott PR foglalta a kozbeni szamot).
     */
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
                            "Nincs a(z) V" + target + " elotti migracio a konyvtarban"));
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

    // ============================ SQL HELPEREK ============================

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters)
            throws Exception {
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
                assertThat(resultSet.next()).as("Egy sor vart: %s", sql).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
