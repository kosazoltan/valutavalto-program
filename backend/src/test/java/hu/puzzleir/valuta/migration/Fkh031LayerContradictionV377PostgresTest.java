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
 * FKH-031/A: a V377 (AT-000010 reteg-ellentmondas rendezese, B valtozat) migracio
 * integracios tesztje valos Flyway-runnerrel, a Fkh028/V375 precedens mintajara.
 *
 * <p>Bizonyitando allitasok:</p>
 * <ul>
 *   <li>FR-1/FR-3 — happy path: AA035100003 REVERSED-&gt;COMPLETED, AA035100004
 *       COMPLETED-&gt;CANCELLED, igy az elment 1000 USD PONTOSAN EGYSZER latszik a
 *       forgalmi (status='COMPLETED' AND financial_effective) szuresben.</li>
 *   <li>FR-2/NFR-1 — a cash_balance sor VALTOZATLAN.</li>
 *   <li>NFR-3 — fail-closed: eltero kiindulo statusznal NEM ir.</li>
 *   <li>NFR-3 — fail-closed: ha az AT-000010 transfer visszavont, NEM ir.</li>
 *   <li>NFR-2 — idempotencia: a nyers SQL tobbszori futasa utan is pontosan egy
 *       COMPLETED kimeno sor van.</li>
 *   <li>FR-4 — a beavatkozas oka mindket soron a notes mezobol visszakovethető.</li>
 * </ul>
 */
@Testcontainers
class Fkh031LayerContradictionV377PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V377_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fkh031_at000010.*\\.sql$");
    private static final String MARKER = "[FKH-031 V377]";

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
    // FR-1 / FR-3 / FR-2 — happy path
    // =====================================================================
    @Test
    @DisplayName("V377: a REVERSED kimeno sor COMPLETED lesz, a sztorno-sor CANCELLED, "
            + "a forgalomban pontosan egyszer latszik az 1000 USD, a cash_balance valtozatlan")
    void v377RendeziAReteg_ellentmondast() throws Exception {
        Fixture fixture = arrangeProdState("REVERSED", "COMPLETED", false, "COMPLETED");

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(status(connection, fixture.branchId(), "AA035100003"))
                    .as("FR-3: a tenylegesen megtortent kimeno mozgas COMPLETED")
                    .isEqualTo("COMPLETED");
            assertThat(status(connection, fixture.branchId(), "AA035100004"))
                    .as("FR-3: a valosagban meg nem tortent sztorno-sor ervenytelenitve")
                    .isEqualTo("CANCELLED");

            assertThat(effectiveOutgoingUsd(connection, fixture.branchId()))
                    .as("FR-1: a forgalmi szuresbe (COMPLETED + financial_effective) pontosan "
                            + "1000 USD kimeno mozgas kerul be — se 0, se 2000")
                    .isEqualByComparingTo("1000.00");

            assertThat(balance(connection, fixture.branchId(), "USD"))
                    .as("FR-2 / NFR-1: a cash_balance a V375 utani 3797-en marad, a V377 nem nyul hozza")
                    .isEqualByComparingTo("3797.00");

            // FR-4: a beavatkozas oka mindket soron visszakovetheto.
            assertThat(notes(connection, fixture.branchId(), "AA035100003"))
                    .contains(MARKER)
                    .contains("AT-000010");
            assertThat(notes(connection, fixture.branchId(), "AA035100004"))
                    .contains(MARKER)
                    .contains("ervenytelenitve");
        }
    }

    // =====================================================================
    // NFR-3 — fail-closed
    // =====================================================================
    @Test
    @DisplayName("V377/NFR-3: eltero kiindulo tranzakcio-statuszhoz NEM nyul (fail-closed)")
    void v377NemNyulElteroKiindulasiAllapothoz() throws Exception {
        // Idokozben mar kezzel rendeztek a kimeno sort, de a sztorno-sor is COMPLETED maradt:
        // ez NEM a vizsgalatban rogzitett allapot, es NEM is a kesz vegallapot.
        Fixture fixture = arrangeProdState("FAILED", "COMPLETED", false, "COMPLETED");

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(status(connection, fixture.branchId(), "AA035100003"))
                    .as("NFR-3: ismeretlen kiindulo allapotnal a migracio NEM ir")
                    .isEqualTo("FAILED");
            assertThat(status(connection, fixture.branchId(), "AA035100004"))
                    .as("NFR-3: a sztorno-sor sem valtozik")
                    .isEqualTo("COMPLETED");
            assertThat(notes(connection, fixture.branchId(), "AA035100003"))
                    .as("NFR-3: fail-closed eseten notes-annotacio sem keletkezik")
                    .doesNotContain(MARKER);
        }
    }

    @Test
    @DisplayName("V377/NFR-3: visszavont AT-000010 transfer eseten NEM ir "
            + "(ilyenkor a REVERSED tranzakcio-statusz HELYES)")
    void v377NemIrVisszavontTransferEseten() throws Exception {
        Fixture fixture = arrangeProdState("REVERSED", "COMPLETED", true, "CANCELLED");

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(status(connection, fixture.branchId(), "AA035100003"))
                    .as("Ha az atadolap visszavont, a REVERSED statusz helyes — nincs korrekcio")
                    .isEqualTo("REVERSED");
            assertThat(status(connection, fixture.branchId(), "AA035100004"))
                    .isEqualTo("COMPLETED");
        }
    }

    // =====================================================================
    // NFR-2 — idempotencia (a Flyway once-only szemantikajan TUL)
    // =====================================================================
    @Test
    @DisplayName("V377/NFR-2: a nyers SQL ujrafuttatasa nem duplazza a forgalmat es a notes-jelolest")
    void v377Idempotens() throws Exception {
        Fixture fixture = arrangeProdState("REVERSED", "COMPLETED", false, "COMPLETED");

        migrateToLatest();
        List<String> firstRerun = runRawCollectingNotices(V377_FILE_PATTERN);
        runRawCollectingNotices(V377_FILE_PATTERN);

        assertThat(firstRerun)
                .as("NFR-2: az ujrafuttatas felismeri a mar rendezett allapotot")
                .anySatisfy(notice -> assertThat(notice).contains("MAR alkalmazva"));

        try (Connection connection = openConnection()) {
            assertThat(effectiveOutgoingUsd(connection, fixture.branchId()))
                    .as("NFR-2: tobbszori futas utan is pontosan 1000 USD forgalom (nem 2000)")
                    .isEqualByComparingTo("1000.00");
            assertThat(countOccurrences(notes(connection, fixture.branchId(), "AA035100003"), MARKER))
                    .as("NFR-2: a notes-jeloles nem duplazodik")
                    .isEqualTo(1);
            assertThat(balance(connection, fixture.branchId(), "USD"))
                    .as("NFR-1: tobbszori futas utan sem valtozik a cash_balance")
                    .isEqualByComparingTo("3797.00");
        }
    }

    @Test
    @DisplayName("V377: ha az AA035100003/004 bizonylatpar nem letezik, a migracio kart nem tesz")
    void v377HianyzoBizonylatparEsetenNemHibazik() throws Exception {
        migrateToVersion(previousExistingVersion(V377_FILE_PATTERN));

        UUID branchId;
        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            branchId = br035.branchId();
            upsertBalance(connection, br035.companyId(), branchId, "USD", new BigDecimal("3797.00"));
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, branchId, "USD"))
                    .as("Bizonylatok nelkul a migracio lefut, de nem ir")
                    .isEqualByComparingTo("3797.00");
        }
    }

    /**
     * FAIL-CLOSED szerzodes a fel-allapotra.
     *
     * <p>A migracio 4. blokkja (kiindulo-allapot guard) a HIBAS KEZDOALLAPOTOT mar iras ELOTT
     * kiszuri — azt a {@code v377NemNyulElteroKiindulasiAllapothoz} teszt fedi. Az itt vizsgalt
     * ag ezzel szemben CSAK valodi versenyhelyzetben erheto el: ha a masodik UPDATE es a
     * SELECT kozott valaki mashonnan modositja a REVERSAL sort. Ez fixturaval nem allithato
     * elo determinisztikusan, ezert a viselkedes helyett a FORRAS-SZERZODEST allitjuk:
     * ezen az agon RAISE EXCEPTION-nek kell allnia, nem RAISE NOTICE-nak.</p>
     *
     * <p>Miert szamit: NOTICE eseten az elso UPDATE (AA035100003 -> COMPLETED) commitalodna a
     * masodik nelkul, es a 1000 USD DUPLAN latszana a BR035 forgalmaban — pontosan az a
     * penzugyi hiba, amit ez a migracio rendezni hivatott. EXCEPTION-nel a Flyway a teljes
     * migraciot visszagorgeti: inkabb ne fusson le, mint hogy felig fusson le.</p>
     */
    @Test
    @DisplayName("V377: a fel-allapot aga fail-closed (RAISE EXCEPTION, nem NOTICE)")
    void v377FelAllapotAgaFailClosed() throws Exception {
        String sql = Files.readString(resolveMigration(V377_FILE_PATTERN), StandardCharsets.UTF_8);

        int secondUpdate = sql.indexOf("AA035100004 ervenytelenitese");
        assertThat(secondUpdate)
                .as("A masodik UPDATE fel-allapot-aga megtalalhato a migracioban")
                .isGreaterThan(0);

        String branch = sql.substring(secondUpdate);
        assertThat(sql.substring(Math.max(0, secondUpdate - 200), secondUpdate))
                .as("A fel-allapot agat RAISE EXCEPTION vezeti be (RAISE NOTICE fel-allapotot commitalna)")
                .contains("RAISE EXCEPTION");
        assertThat(branch)
                .as("Az uzenet kimondja a visszagorgetest")
                .contains("VISSZAGORGETVE");
    }

    /**
     * A sikeres ag valtozatlanul NOTICE-szal zar (nem szabad, hogy a fail-closed valtoztatas
     * a normal futast is elszallassza) — ezt a {@code v377RendeziAReteg_ellentmondast} teszt
     * bizonyitja viselkedesi szinten; itt csak a forras-szerzodest rogzitjuk.
     */
    @Test
    @DisplayName("V377: a sikeres ag tovabbra is NOTICE-szal zar")
    void v377SikeresAgNoticeMarad() throws Exception {
        String sql = Files.readString(resolveMigration(V377_FILE_PATTERN), StandardCharsets.UTF_8);
        assertThat(sql)
                .as("A sikeres rendezes tajekoztato NOTICE-a megmaradt")
                .contains("reteg-ellentmondas rendezve");
    }

    // ============================ ARRANGE ============================

    private record Fixture(UUID companyId, UUID branchId) {
    }

    /**
     * Eloallitja a V377 ELOTTI, prodban mert allapotot: 4 BR035 USD-tranzakcio, az
     * AT-000009 (visszavont) es AT-000010 atadolap, valamint a V375 utani 3797-es egyenleg.
     */
    private static Fixture arrangeProdState(String outStatus,
                                            String reversalStatus,
                                            boolean transferCancelled,
                                            String transferStatus) throws Exception {
        migrateToVersion(previousExistingVersion(V377_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            SeededBranch br035 = resolveSeededBranch(connection, "BR035");
            UUID companyId = br035.companyId();
            UUID branchId = br035.branchId();
            UUID toBranchId = resolveSeededBranch(connection, "BR020").branchId();
            long workerId = queryForLong(connection, "SELECT id FROM worker ORDER BY id LIMIT 1");
            long usdId = queryForLong(connection, "SELECT id FROM currency WHERE code = 'USD'");

            // A V375 utani, helyes egyenleg — a V377-nek ehhez NEM szabad hozzanyulnia.
            upsertBalance(connection, companyId, branchId, "USD", new BigDecimal("3797.00"));

            insertTransfer(connection, companyId, branchId, toBranchId, workerId, usdId,
                    "AT-000009", "CANCELLED", true);
            insertTransfer(connection, companyId, branchId, toBranchId, workerId, usdId,
                    "AT-000010", transferStatus, transferCancelled);

            insertTransaction(connection, companyId, branchId, workerId, usdId,
                    "AA035100002", "TRANSFER_OUT", "COMPLETED", "AT-000009");
            long outId = insertTransaction(connection, companyId, branchId, workerId, usdId,
                    "AA035100003", "TRANSFER_OUT", outStatus, "AT-000010");
            insertReversal(connection, companyId, branchId, workerId, usdId,
                    "AA035100004", reversalStatus, outId);
            insertTransaction(connection, companyId, branchId, workerId, usdId,
                    "AV035100005", "TRANSFER_IN", "COMPLETED", "AT-000009-SZ");

            return new Fixture(companyId, branchId);
        }
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
                        .as("A migralt semaban letezik a seedelt EBC/%s fiok", code)
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
                                       String transferNumber, String status, boolean cancelled)
            throws Exception {
        execute(connection, """
                INSERT INTO transfer
                    (transfer_number, company_id, from_branch_id, to_branch_id, from_worker_id,
                     transfer_type, status, transfer_date, transfer_time, currency_id, amount,
                     is_cancelled, created_at)
                VALUES (?, ?, ?, ?, ?, 'CURRENCY', ?, CURRENT_DATE, CURRENT_TIME, ?,
                        1000.0000, ?, NOW())
                """, transferNumber, companyId, fromBranchId, toBranchId, workerId, status,
                currencyId, cancelled);
    }

    private static long insertTransaction(Connection connection, UUID companyId, UUID branchId,
                                          long workerId, long currencyId, String receiptNumber,
                                          String type, String status, String referenceNumber)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                INSERT INTO transaction
                    (company_id, branch_id, worker_id, receipt_number, transaction_type, status,
                     transaction_date, transaction_time, currency_id, currency_amount,
                     exchange_rate, huf_amount, financial_effective, reference_number, created_at)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_DATE, CURRENT_TIME, ?, 1000.00, 340.0000,
                        340000.00, TRUE, ?, NOW())
                RETURNING id
                """)) {
            bind(statement, companyId, branchId, workerId, receiptNumber, type, status,
                    currencyId, referenceNumber);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getLong(1);
            }
        }
    }

    private static void insertReversal(Connection connection, UUID companyId, UUID branchId,
                                       long workerId, long currencyId, String receiptNumber,
                                       String status, long originalTransactionId) throws Exception {
        execute(connection, """
                INSERT INTO transaction
                    (company_id, branch_id, worker_id, receipt_number, transaction_type, status,
                     transaction_date, transaction_time, currency_id, currency_amount,
                     exchange_rate, huf_amount, financial_effective, original_transaction_id,
                     created_at)
                VALUES (?, ?, ?, ?, 'REVERSAL', ?, CURRENT_DATE, CURRENT_TIME, ?, 1000.00,
                        340.0000, 340000.00, TRUE, ?, NOW())
                """, companyId, branchId, workerId, receiptNumber, status, currencyId,
                originalTransactionId);
    }

    private static String status(Connection connection, UUID branchId, String receiptNumber)
            throws Exception {
        return queryForString(connection, """
                SELECT status FROM transaction WHERE branch_id = ? AND receipt_number = ?
                """, branchId, receiptNumber);
    }

    private static String notes(Connection connection, UUID branchId, String receiptNumber)
            throws Exception {
        String notes = queryForString(connection, """
                SELECT COALESCE(notes, '') FROM transaction
                 WHERE branch_id = ? AND receipt_number = ?
                """, branchId, receiptNumber);
        return notes == null ? "" : notes;
    }

    /**
     * A forgalmi lekerdezesek szuresenek (status='COMPLETED' AND financial_effective=TRUE)
     * megfelelo, BR035-bol KIMENO USD-osszeg. A REVERSAL sorok CANCELLED allapotban kiesnek.
     */
    private static BigDecimal effectiveOutgoingUsd(Connection connection, UUID branchId)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT COALESCE(SUM(tr.currency_amount), 0)
                  FROM transaction tr
                  JOIN currency c ON c.id = tr.currency_id
                 WHERE tr.branch_id = ?
                   AND c.code = 'USD'
                   AND tr.transaction_type = 'TRANSFER_OUT'
                   AND tr.reference_number = 'AT-000010'
                   AND tr.status = 'COMPLETED'
                   AND tr.financial_effective = TRUE
                """)) {
            statement.setObject(1, branchId);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
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
                assertThat(resultSet.next()).as("cash_balance sor vart: %s", currencyCode).isTrue();
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

    private static String queryForString(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor vart: %s", sql).isTrue();
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
