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
import java.sql.SQLWarning;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-028 Fázis 4-5: a V369 (BR020 hiányzó cash_balance sorok pótlása) és a V370
 * (BR035 +1000 USD + duplikátum-annotáció) migrációk integrációs tesztje — valós
 * Flyway-runnerrel, a V368/FK-070 migrációs-teszt precedens mintájára (CI-ben fut,
 * lokálisan Docker-hiány miatt a Testcontainers-baseline része).
 */
@Testcontainers
class Fkh028CashBalanceMigrationsPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V369_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh028_br020.*\\.sql$");
    private static final Pattern V370_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh028_br035.*\\.sql$");
    /** FKH-028/B: a V370 tulkorrekciojat rendezo migracio (-2000 USD). */
    private static final Pattern V375_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh028b_br035.*\\.sql$");
    private static final String MARKER = "[FKH-028 V370]";

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
    // V369 — Fázis 4: minden aktív valutára létrejön a BR020 sor, 0-val;
    // a meglévő sor ÉRINTETLEN; a második (kézi) futás 0 sort pótol
    // =====================================================================
    @Test
    @DisplayName("V369: BR020 minden aktív valutára kap cash_balance sort 0-val; meglévő sor érintetlen; újrafuttatás 0 sort pótol")
    void v369PotoljaAHianyzoBr020Sorokat() throws Exception {
        migrateToVersion(version(V369_FILE_PATTERN) - 1);

        UUID branchId;
        UUID companyId;
        try (Connection connection = openConnection()) {
            SeededBranch br020 = resolveSeededBranch(connection, "BR020");
            branchId = br020.branchId();
            companyId = br020.companyId();
            // Meglévő sor: az EUR-nak már van egyenlege — ehhez a migráció NEM nyúlhat.
            upsertBalance(connection, companyId, branchId, "EUR", new BigDecimal("123.45"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            long activeCurrencies = queryForLong(connection,
                    "SELECT count(*) FROM currency WHERE is_active = TRUE");
            long br020Rows = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance cb
                      JOIN currency c ON c.id = cb.currency_id
                     WHERE cb.branch_id = ? AND c.is_active = TRUE
                    """, branchId);
            assertThat(br020Rows)
                    .as("BR020-nak minden aktív valutára van cash_balance sora")
                    .isEqualTo(activeCurrencies);

            assertThat(balance(connection, branchId, "EUR"))
                    .as("A már létező EUR sor értéke érintetlen (a migráció csak pótol)")
                    .isEqualByComparingTo("123.45");

            long nonZero = queryForLong(connection, """
                    SELECT count(*) FROM cash_balance
                     WHERE branch_id = ? AND current_balance <> 0
                    """, branchId);
            assertThat(nonZero)
                    .as("A pótolt sorok mind 0 nyitóértékűek (csak a seedelt EUR nem 0)")
                    .isEqualTo(1);
        }

        // Kézi újrafuttatás (NFR-idempotencia): 0 pótolt sor, NOTICE-bizonyítékkal.
        List<String> notices = runRawCollectingNotices(V369_FILE_PATTERN);
        assertThat(notices)
                .anySatisfy(n -> assertThat(n).contains("0 hianyzo cash_balance sor potolva"));
    }

    // =====================================================================
    // V370 — Fázis 5: +1000 USD, bizonylat-annotáció, marker-alapú idempotencia
    // =====================================================================
    @Test
    @DisplayName("V370: BR035 USD +1000; AT-000009/010 és AA035100002/003 jelölést kap; kézi újrafuttatás a marker miatt NEM ad újabb +1000-et")
    void v370KorrigalEsAnnotal_ismetlesVedett() throws Exception {
        migrateToVersion(version(V370_FILE_PATTERN) - 1);

        UUID branchId;
        UUID companyId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            companyId = br035.companyId();
            upsertBalance(connection, companyId, branchId, "USD", new BigDecimal("4797.00"));

            UUID toBranchId = resolveSeededBranch(connection, "BR020").branchId();
            long workerId = queryForLong(connection, "SELECT id FROM worker ORDER BY id LIMIT 1");
            long usdId = queryForLong(connection, "SELECT id FROM currency WHERE code = 'USD'");
            insertTransfer(connection, companyId, branchId, toBranchId, workerId, usdId, "AT-000009");
            insertTransfer(connection, companyId, branchId, toBranchId, workerId, usdId, "AT-000010");
            insertTransaction(connection, companyId, branchId, workerId, usdId, "AA035100002");
            insertTransaction(connection, companyId, branchId, workerId, usdId, "AA035100003");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            // FKH-028/B: a `migrateToLatest()` a V370 UTAN a V375-ot IS lefuttatja, ezert a
            // vart vegallapot a TELJES lanc eredmenye: 4797 +1000 (V370) = 5797, majd
            // -2000 (V375 tulkorrekcio-rendezes) = 3797. Ez egyben azt is bizonyitja, hogy a
            // V375 allapot-ellenorzese a V370 altal eloallitott 5797-re HELYESEN illeszkedik.
            assertThat(balance(connection, branchId, "USD"))
                    .as("BR035 USD a teljes V370+V375 lanc utan (4797 +1000 -2000)")
                    .isEqualByComparingTo("3797.00");

            assertThat(markedTransfers(connection, companyId))
                    .as("Mindkét duplikált átadólap jelölést kapott")
                    .isEqualTo(2);
            assertThat(markedTransactions(connection, branchId))
                    .as("Mindkét duplikált ellentranzakció jelölést kapott")
                    .isEqualTo(2);
        }

        // Kézi újrafuttatás: a marker-guard miatt NINCS újabb +1000, és a jelölés nem duplázódik.
        List<String> notices = runRawCollectingNotices(V370_FILE_PATTERN);
        assertThat(notices)
                .anySatisfy(n -> assertThat(n).contains("mar alkalmazva"));
        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("A második V370-futás NEM ad újabb +1000-et (marker-guard) — az érték a "
                            + "V375-tel zárult lánc végállapotán marad")
                    .isEqualByComparingTo("3797.00");
            String notes = queryForString(connection, """
                    SELECT notes FROM transfer WHERE company_id = ? AND transfer_number = 'AT-000009'
                    """, companyId);
            assertThat(countOccurrences(notes, MARKER))
                    .as("A jelölés nem duplázódik a notes-ban")
                    .isEqualTo(1);
        }
    }

    @Test
    @DisplayName("V370: ha a duplikált bizonylatok nem léteznek, a +1000 korrekció akkor is lefut, jelölés 0 sorra")
    void v370HianyzoBizonylatokEseten_korrekcioLefut() throws Exception {
        migrateToVersion(version(V370_FILE_PATTERN) - 1);

        UUID branchId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            upsertBalance(connection, br035.companyId(), branchId, "USD", new BigDecimal("100.00"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("A korrekció bizonylat-sorok nélkül is lefut")
                    .isEqualByComparingTo("1100.00");
        }
    }

    // =====================================================================
    // V375 — FKH-028/B: a V370 tulkorrekcio rendezese (-2000 USD),
    // TBD-4 allapot-ellenorzessel (fail-closed)
    // =====================================================================

    @Test
    @DisplayName("V375: a V370 utani 5797-es egyenleget a levezetett 3797-re korrigálja")
    void v375KorrigaljaATulkorrigaltEgyenleget() throws Exception {
        migrateToVersion(previousExistingVersion(V375_FILE_PATTERN));

        UUID branchId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            // A prodban mert, V370 utani allapot eloallitasa.
            upsertBalance(connection, br035.companyId(), branchId, "USD", new BigDecimal("5797.00"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("FR-B2: a BR035 USD-egyenleg a levezetett helyes ertekre all (5797 - 2000)")
                    .isEqualByComparingTo("3797.00");
        }
    }

    @Test
    @DisplayName("V375/TBD-4: eltérő kiinduló egyenleghez NEM nyúl (fail-closed állapot-ellenőrzés)")
    void v375NemNyulElteroKiindulasiAllapothoz() throws Exception {
        migrateToVersion(previousExistingVersion(V375_FILE_PATTERN));

        UUID branchId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            // Idokozben megvaltozott adat: NEM a vart 5797. Pontosan ez a szituacio okozta a
            // V370 tulkorrekciojat — a marker-alapu idempotencia ez ellen NEM vedett.
            upsertBalance(connection, br035.companyId(), branchId, "USD", new BigDecimal("4200.00"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("TBD-4: ismeretlen kiindulo allapotnal a migracio NEM ir (fail-closed)")
                    .isEqualByComparingTo("4200.00");
        }
    }

    @Test
    @DisplayName("V375: idempotens — a már korrigált 3797-es egyenleget nem csökkenti tovább")
    void v375Idempotens() throws Exception {
        migrateToVersion(previousExistingVersion(V375_FILE_PATTERN));

        UUID branchId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            upsertBalance(connection, br035.companyId(), branchId, "USD", new BigDecimal("5797.00"));
        }

        migrateToLatest();
        // Kezi ujrafuttatas a Flyway once-only szemantikajan TUL (NFR-4).
        runRawCollectingNotices(V375_FILE_PATTERN);
        runRawCollectingNotices(V375_FILE_PATTERN);

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("NFR-4: tobbszori futas utan is pontosan 3797 (nem 1797, nem -203)")
                    .isEqualByComparingTo("3797.00");
        }
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

    /**
     * A megadott migracio ELOTTI, TENYLEGESEN LETEZO verzio.
     *
     * <p>A naiv {@code version(...) - 1} eltorik, ha a szamozasban LYUK van: a V375 elott a
     * V374-et egy MASIK, meg nyitott PR (FK-076) foglalja, igy ezen az agon a V373 az elozo.
     * A Flyway ilyenkor {@code No migration with a target version 374 could be found} hibat
     * dob — lokalisan zold lehet (ha a masik ag fajlja ott van), CI-ben viszont bukik.
     * Ezert a konyvtar tenyleges tartalmabol keressuk meg a kozvetlen elozmenyt.</p>
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

    private static List<String> runRawCollectingNotices(Pattern pattern) throws Exception {
        String sql = Files.readString(resolveMigration(pattern), StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(sql);
            List<String> notices = new ArrayList<>();
            SQLWarning warning = statement.getWarnings();
            while (warning != null) {
                notices.add(warning.getMessage());
                warning = warning.getNextWarning();
            }
            return notices;
        }
    }

    // ============================ SQL HELPEREK ============================

    private record SeededBranch(UUID branchId, UUID companyId) {
    }

    private static SeededBranch resolveSeededBranch(Connection connection, String code) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT b.id, b.company_id
                  FROM branch b
                  JOIN company co ON co.id = b.company_id
                 WHERE b.code = ? AND co.code = 'EBC'
                """)) {
            statement.setString(1, code);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next())
                        .as("A migrált sémában léteznie kell a seedelt EBC/%s fióknak", code)
                        .isTrue();
                return new SeededBranch(
                        resultSet.getObject(1, UUID.class),
                        resultSet.getObject(2, UUID.class));
            }
        }
    }

    private static void upsertBalance(Connection connection, UUID companyId, UUID branchId,
                                      String currencyCode, BigDecimal amount) throws Exception {
        long currencyId = queryForLong(connection,
                "SELECT id FROM currency WHERE code = ?", currencyCode);
        execute(connection, """
                INSERT INTO cash_balance
                    (company_id, branch_id, currency_id, current_balance, opening_balance,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 0, NOW(), NOW(), 0)
                ON CONFLICT (branch_id, currency_id) DO UPDATE
                    SET current_balance = EXCLUDED.current_balance,
                        updated_at = NOW()
                """, companyId, branchId, currencyId, amount);
    }

    private static void insertTransfer(Connection connection, UUID companyId, UUID fromBranchId,
                                       UUID toBranchId, long workerId, long currencyId,
                                       String transferNumber) throws Exception {
        execute(connection, """
                INSERT INTO transfer
                    (transfer_number, company_id, from_branch_id, to_branch_id, from_worker_id,
                     transfer_type, status, transfer_date, transfer_time, currency_id, amount,
                     is_cancelled, created_at)
                VALUES (?, ?, ?, ?, ?, 'CURRENCY', 'RECEIVED', CURRENT_DATE, CURRENT_TIME, ?,
                        1000.0000, FALSE, NOW())
                """, transferNumber, companyId, fromBranchId, toBranchId, workerId, currencyId);
    }

    private static void insertTransaction(Connection connection, UUID companyId, UUID branchId,
                                          long workerId, long currencyId, String receiptNumber)
            throws Exception {
        execute(connection, """
                INSERT INTO transaction
                    (company_id, branch_id, worker_id, receipt_number, transaction_type, status,
                     transaction_date, transaction_time, currency_id, currency_amount,
                     exchange_rate, huf_amount, financial_effective, created_at)
                VALUES (?, ?, ?, ?, 'TRANSFER_OUT', 'COMPLETED', CURRENT_DATE, CURRENT_TIME, ?,
                        1000.00, 340.0000, 340000.00, TRUE, NOW())
                """, companyId, branchId, workerId, receiptNumber, currencyId);
    }

    private static long markedTransfers(Connection connection, UUID companyId) throws Exception {
        return queryForLong(connection, """
                SELECT count(*) FROM transfer
                 WHERE company_id = ? AND transfer_number IN ('AT-000009', 'AT-000010')
                   AND notes LIKE '%[FKH-028 V370]%'
                """, companyId);
    }

    private static long markedTransactions(Connection connection, UUID branchId) throws Exception {
        return queryForLong(connection, """
                SELECT count(*) FROM transaction
                 WHERE branch_id = ? AND receipt_number IN ('AA035100002', 'AA035100003')
                   AND notes LIKE '%[FKH-028 V370]%'
                """, branchId);
    }

    private static BigDecimal balance(Connection connection, UUID branchId, String currencyCode)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE cb.branch_id = ? AND c.code = ?
                """)) {
            statement.setObject(1, branchId);
            statement.setString(2, currencyCode);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("cash_balance sor várt: %s", currencyCode).isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
    }

    private static int countOccurrences(String text, String needle) {
        int count = 0;
        int index = 0;
        while (text != null && (index = text.indexOf(needle, index)) >= 0) {
            count++;
            index += needle.length();
        }
        return count;
    }

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static void execute(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            statement.executeUpdate();
        }
    }

    private static long queryForLong(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static String queryForString(Connection connection, String sql, Object... parameters) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getString(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws Exception {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
