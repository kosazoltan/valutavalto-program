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
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-080 (FR-6, V380): a tiltott COIN denomination-sorok inaktivalasanak valos-DB
 * bizonyitasa (Testcontainers + Flyway, az FK-076 teszt infrastruktorat masolva).
 *
 * <p>Amit bizonyit:
 * <ul>
 *   <li>Csak azokat az AKTIV COIN sorokat inaktivalja, amelyek (company, currency,
 *       face_value) harmasa NEM szerepel az adott company aktiv COIN katalogusaban
 *       (CHF 5, CZK 10 → inaktiv; EUR 2, HUF 100, EUR 500 BANKNOTE → erintetlen).</li>
 *   <li>Mindket active-oszlopot (active ES is_active) explicit false-ra allitja
 *       (ticket C3 — nem fugg a trg_sync_active_columns trigger tukrozeseitol).</li>
 *   <li>Nincs DELETE: a denomination sorok darabszama valtozatlan.</li>
 *   <li>NFR-4: a denomination_balance tabla bit-azonos a migracio elott/utan, es a
 *       deactivated sorhoz tartozo egyenleg-sor FK-n keresztul tovabbra is olvashato.</li>
 *   <li>Cross-tenant (spec §6.b): a predikatum company-szintu — company B sajat,
 *       ENGEDELYEZETT CHF 5 COIN sora NEM inaktivalodik, mig company A ugyanilyen
 *       (engedelyezetlen) sora igen. Egy company-agnosztikus NOT EXISTS ellen
 *       ez a teszt elbukna.</li>
 *   <li>Idempotencia: az UPDATE masodik nyers futtatasa 0 sort modosit.</li>
 * </ul>
 *
 * <p>Arrange-struktura: a fixture companykat meg a V376 ELOTT szurjuk be, hogy a
 * V376/V379 katalogus-seed az o soraikat is feltoltse — ezert marad az EUR 2 COIN
 * es a HUF 100 COIN engedelyezett (es aktiv) a V380 utan. A fixture branch-eket es
 * denomination-sorokat CSAK ezutan (a V380 elotti utolso verzion) szurjuk be, igy a
 * V320/V328 regi katalogus-backfill (amely a seed-branch-ekre futott le) nem keveredik
 * a fixture-alleitasokba.
 */
@Testcontainers
class ForbiddenCoinDeactivationFk080MigrationPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    /** A FK-080 tiltott-erme migracio fajl-mintaja (addendum A-8). */
    private static final Pattern V380_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk080_tiltott_erme.*\\.sql$");
    /** A FK-076 katalogus-migracio mintaja (a company-beszuras idozitesehez). */
    private static final Pattern V376_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__denomination_allowed.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    private UUID companyA;
    private UUID branchA;
    private UUID companyB;
    private UUID branchB;
    private long chf5CoinIdA;
    private long czk10CoinIdA;
    private long eur2CoinIdA;
    private long huf100CoinIdA;
    private long eur500BanknoteIdA;
    private long chf5InactiveIdA;
    private long chf5CoinIdB;

    /**
     * A @Container statikus, igy a tesztek EGY Postgres-en osztoznak — minden teszt
     * tiszta DB-rol indul (FK-076 minta).
     */
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
    @DisplayName("V380: tiltott COIN sorok inaktivalva, engedelyezettek es BANKNOTE-k erintetlenek; nincs DELETE; balance bit-azonos; cross-tenant")
    void v380DeactivatesOnlyForbiddenActiveCoinRows() throws Exception {
        arrangeFixtures();

        long denominationCountBefore;
        List<String> balanceSnapshotBefore;
        List<String> denominationSnapshotBefore;
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            denominationCountBefore = count(st, "SELECT count(*) FROM denomination");
            balanceSnapshotBefore = snapshotDenominationBalanceTable(connection);
            denominationSnapshotBefore = snapshotDenominationTable(connection);
        }
        assertThat(balanceSnapshotBefore).as("A fixture balance-sora bekerult").isNotEmpty();
        assertThat(denominationCountBefore)
                .as("A fixture denomination-sorai bekerultek")
                .isGreaterThanOrEqualTo(7);

        migrateToLatest();

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            // Tiltott COIN sorok inaktivalva — MINDKET active-oszlop explicit false.
            assertActiveFlags(st, chf5CoinIdA, false);
            assertActiveFlags(st, czk10CoinIdA, false);

            // Engedelyezett COIN es BANKNOTE sorok valtozatlanul aktvak.
            assertActiveFlags(st, eur2CoinIdA, true);
            assertActiveFlags(st, huf100CoinIdA, true);
            assertActiveFlags(st, eur500BanknoteIdA, true);

            // A mar eleve inaktiv sor nem modosult (a WHERE active=true ki sem valasztja).
            assertActiveFlags(st, chf5InactiveIdA, false);

            // Cross-tenant (spec §6.b): company B sajat ENGEDELYEZETT CHF 5 COIN sora
            // AKTIV marad — company A ugyanilyen sora viszont inaktiv lett. Egy
            // company-agnosztikus NOT EXISTS itt elbukna.
            assertActiveFlags(st, chf5CoinIdB, true);

            // Nincs DELETE: a denomination darabszam valtozatlan.
            assertThat(count(st, "SELECT count(*) FROM denomination"))
                    .as("Nincs DELETE — a sorok darabszama valtozatlan")
                    .isEqualTo(denominationCountBefore);

            // NFR-4: a denomination_balance bit-azonos, az egyenleg-sor FK-n olvashato.
            assertThat(snapshotDenominationBalanceTable(connection))
                    .as("A denomination_balance tartalma nem modosulhatott (NFR-4)")
                    .isEqualTo(balanceSnapshotBefore);
            assertThat(count(st,
                    "SELECT count(*) FROM denomination_balance db "
                            + "JOIN denomination d ON d.id = db.denomination_id "
                            + "WHERE db.quantity = 7"))
                    .as("A quantity=7 egyenleg-sor az inaktivalas utan is olvashato az FK-n keresztul")
                    .isEqualTo(1);
        }

        // Idempotencia: az UPDATE nyers ujrafuttatasa 0 sort modosit, snapshot stabil.
        int secondRunAffected = runV380UpdateRaw();
        assertThat(secondRunAffected)
                .as("A masodik futas 0 sort modosit (active=true mar nem all fenn)")
                .isZero();
        try (Connection connection = openConnection()) {
            assertThat(snapshotDenominationTable(connection))
                    .as("Az idempotens masodik futas utan a denomination tabla valtozatlan")
                    .isEqualTo(denominationSnapshotBefore);
        }
    }

    // ============================ FIXTURE ============================

    /**
     * Company A + branch A: CHF 5 COIN aktiv (tiltott), CZK 10 COIN aktiv (tiltott),
     * EUR 2 COIN aktiv (engedelyezett), HUF 100 COIN aktiv (engedelyezett — V379),
     * EUR 500 BANKNOTE aktiv (nem COIN, erintetlen), CHF 5 COIN mar inaktiv.
     * Company B + branch B: CHF 5 COIN aktiv, es company B-hez ENGEDELYEZETT
     * katalogus-sor kerul → az o sora nem inaktivalodik (cross-tenant bizonyitek).
     * Plusz egy denomination_balance sor (quantity=7) company A CHF 5 COIN sorara.
     *
     * <p>A companykat a V376 ELOTT szurjuk be (a seed szamoljon veluk); a V320/V328
     * regi backfill sorait a V380 futasa elott toroljuk (lasd osztaly-Javadoc).
     */
    private void arrangeFixtures() throws Exception {
        // A companykat meg a V376 ELOTT szurjuk be, hogy a katalogus-seed (V376 + V379)
        // az o soraikat is feltoltse: ezert marad az EUR 2 COIN es a HUF 100 COIN
        // engedelyezett company A-nal (a V380 ezeket nem inaktivalhatja).
        migrateToVersion(highestExistingBelow(V376_FILE_PATTERN));

        companyA = insertCompany("FK-080 Tenant A", "FK080A");
        companyB = insertCompany("FK-080 Tenant B", "FK080B");

        // Migracio a V380 elotti utolso verzioig (V376/V377/V378/V379 lefut,
        // V380 meg nem). A V320/V328 backfill a seed-branch-eken mar lefutott,
        // a most beszurt companyknak akkor meg nem volt branch-e.
        migrateToVersion(previousExistingVersion());

        branchA = insertBranch(companyA, "FK080-BR-A");
        branchB = insertBranch(companyB, "FK080-BR-B");

        long chf = currencyId("CHF");
        long czk = currencyId("CZK");
        long eur = currencyId("EUR");
        long huf = currencyId("HUF");

        chf5CoinIdA = insertDenominationRow(companyA, branchA, chf, 5, "COIN", true);
        czk10CoinIdA = insertDenominationRow(companyA, branchA, czk, 10, "COIN", true);
        eur2CoinIdA = insertDenominationRow(companyA, branchA, eur, 2, "COIN", true);
        huf100CoinIdA = insertDenominationRow(companyA, branchA, huf, 100, "COIN", true);
        eur500BanknoteIdA = insertDenominationRow(companyA, branchA, eur, 500, "BANKNOTE", true);
        chf5InactiveIdA = insertDenominationRow(companyA, branchA, chf, 5, "COIN", false);

        chf5CoinIdB = insertDenominationRow(companyB, branchB, chf, 5, "COIN", true);
        // CSAK company B kap engedelyezett CHF 5 COIN katalogus-sort (a V376 seedben
        // CHF-hez csak bankjegy-sorok vannak — a (company,currency,face_value) kulcs
        // nem utkozik, mert CHF 5 COIN-sor nincs a seedben).
        insertAllowedRow(companyB, chf, 5, "COIN");

        insertBalanceRow(branchA, chf5CoinIdA, 7);
    }

    // ============================ FLYWAY HELPEREK ============================

    /**
     * A V380 elotti LEGMAGASABB letezo verzió (gap-safe — NEM `version - 1`;
     * a nyitott PR-ek miatt a szamozas nem feltetlenul folytonos).
     */
    private static int previousExistingVersion() throws IOException {
        int target = version(V380_FILE_PATTERN);
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError(
                            "Nincs migracio a V" + target + " elott"));
        }
    }

    /**
     * A megadott fajl-mintaju migracio ELOTTI LEGMAGASABB letezo verzió
     * (gap-safe — NEM `version - 1`).
     */
    private static int highestExistingBelow(Pattern targetPattern) throws IOException {
        int target = version(targetPattern);
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError(
                            "Nincs migracio a V" + target + " elott"));
        }
    }

    private static void migrateToLatest() {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load()
                .migrate();
    }

    private static void migrateToVersion(int version) {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion(String.valueOf(version)))
                .load()
                .migrate();
    }

    /** Addendum A-8: pontosan 1 fajl feleljen meg — soha nem tobb, soha nem nulla. */
    private static int version(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("Pontosan 1 db FK-080 tiltott-erme migracios fajl varva")
                    .hasSize(1);
            Matcher matcher = pattern.matcher(matches.get(0).getFileName().toString());
            assertThat(matcher.matches()).isTrue();
            return Integer.parseInt(matcher.group(1));
        }
    }

    /**
     * A V380 UPDATE-je nyers ujrafuttatasa (a DO-blokk UPDATE utasitasa az elso
     * pontosvesszoig — a GET DIAGNOSTICS/RAISE NOTICE reszek nelkul). A masodik
     * futasnak 0 sort kell modositania (idempotencia).
     */
    private static int runV380UpdateRaw() throws Exception {
        String sql = Files.readString(resolveMigrationFile(), StandardCharsets.UTF_8);
        int start = sql.indexOf("UPDATE denomination d");
        assertThat(start).as("Az UPDATE megtalalhato a migracios fajlban").isNotNegative();
        int end = sql.indexOf(';', start);
        assertThat(end).as("Az UPDATE lezaro pontosvesszoje").isGreaterThan(start);
        String updateStatement = sql.substring(start, end);
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            return st.executeUpdate(updateStatement);
        }
    }

    private static Path resolveMigrationFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .filter(p -> V380_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .findFirst()
                    .orElseThrow(() -> new AssertionError(
                            "A FK-080 tiltott-erme migracios fajl nem talalhato"));
        }
    }

    // ============================ SQL HELPEREK ============================

    private static UUID insertCompany(String name, String code) throws Exception {
        UUID id = UUID.randomUUID();
        // CodeQL java/concatenated-sql-query: PreparedStatement, nem string-konkatenacio.
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO company (id, name, code, is_active, created_at) "
                             + "VALUES (?, ?, ?, true, NOW())")) {
            ps.setObject(1, id);
            ps.setString(2, name);
            ps.setString(3, code);
            ps.executeUpdate();
        }
        return id;
    }

    private static UUID insertBranch(UUID companyId, String code) throws Exception {
        UUID id = UUID.randomUUID();
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO branch (id, company_id, code, name, is_active, created_at) "
                             + "VALUES (?, ?, ?, ?, true, NOW())")) {
            ps.setObject(1, id);
            ps.setObject(2, companyId);
            ps.setString(3, code);
            ps.setString(4, code + " Name");
            ps.executeUpdate();
        }
        return id;
    }

    private static long currencyId(String code) throws Exception {
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "SELECT id FROM currency WHERE code = ?")) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                assertThat(rs.next()).as("A(z) " + code + " deviza letezik a seedben").isTrue();
                return rs.getLong(1);
            }
        }
    }

    /**
     * Denomination-sor beszurasa. MINDKET active-oszlopot explicit allitjuk (a V109
     * utan mindketto letezik), hogy a fixture ne fuggon a trigger tukrozeseitol.
     */
    private static long insertDenominationRow(UUID companyId, UUID branchId, long currencyId,
                                              int faceValue, String type, boolean active) throws Exception {
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO denomination (company_id, branch_id, currency_id, face_value, "
                             + "denomination_type, quantity, min_quantity, active, is_active, created_at) "
                             + "VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?, NOW())",
                     Statement.RETURN_GENERATED_KEYS)) {
            ps.setObject(1, companyId);
            ps.setObject(2, branchId);
            ps.setLong(3, currencyId);
            ps.setBigDecimal(4, BigDecimal.valueOf(faceValue));
            ps.setString(5, type);
            ps.setBoolean(6, active);
            ps.setBoolean(7, active);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                assertThat(keys.next()).isTrue();
                return keys.getLong(1);
            }
        }
    }

    private static void insertAllowedRow(UUID companyId, long currencyId,
                                         int faceValue, String type) throws Exception {
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO denomination_allowed (company_id, currency_id, face_value, "
                             + "denomination_type, is_active, created_at, updated_at) "
                             + "VALUES (?, ?, ?, ?, true, NOW(), NOW())")) {
            ps.setObject(1, companyId);
            ps.setLong(2, currencyId);
            ps.setBigDecimal(3, BigDecimal.valueOf(faceValue));
            ps.setString(4, type);
            ps.executeUpdate();
        }
    }

    private static void insertBalanceRow(UUID branchId, long denominationId, int quantity) throws Exception {
        UUID id = UUID.randomUUID();
        // CHF 5 erme x 7 db = 35.00 ertek.
        BigDecimal totalValue = BigDecimal.valueOf(5L * quantity).setScale(2);
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO denomination_balance (id, cash_desk_id, denomination_id, "
                             + "quantity, total_value, denomination_category, submission_date) "
                             + "VALUES (?, ?, ?, ?, ?, 'EVENING', CURRENT_DATE)")) {
            ps.setObject(1, id);
            ps.setObject(2, branchId);
            ps.setLong(3, denominationId);
            ps.setInt(4, quantity);
            ps.setBigDecimal(5, totalValue);
            ps.executeUpdate();
        }
    }

    private static void assertActiveFlags(Statement st, long denominationId,
                                          boolean expectedActive) throws Exception {
        try (PreparedStatement ps = st.getConnection().prepareStatement(
                "SELECT active, is_active FROM denomination WHERE id = ?")) {
            ps.setLong(1, denominationId);
            try (ResultSet rs = ps.executeQuery()) {
                assertThat(rs.next()).as("denomination id=" + denominationId + " letezik").isTrue();
                assertThat(rs.getBoolean(1))
                        .as("denomination id=" + denominationId + " active oszlop")
                        .isEqualTo(expectedActive);
                assertThat(rs.getBoolean(2))
                        .as("denomination id=" + denominationId + " is_active oszlop")
                        .isEqualTo(expectedActive);
            }
        }
    }

    /**
     * A denomination_balance teljes sor-snapshotja determinisztikus sorrendben —
     * az NFR-4 bit-azonossag bizonyitasahoz (nem eleg a darabszam).
     */
    private static List<String> snapshotDenominationBalanceTable(Connection connection) throws Exception {
        List<String> rows = new ArrayList<>();
        try (Statement st = connection.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT id || '|' || cash_desk_id || '|' || denomination_id"
                             + " || '|' || quantity || '|' || total_value"
                             + " || '|' || denomination_category || '|' || submission_date"
                             + " FROM denomination_balance ORDER BY id")) {
            while (rs.next()) {
                rows.add(rs.getString(1));
            }
        }
        return rows;
    }

    /**
     * A denomination tabla teljes sor-snapshotja determinisztikus sorrendben — az
     * idempotencia-ellenorzeshez (a masodik UPDATE utan is bit-azonos).
     */
    private static List<String> snapshotDenominationTable(Connection connection) throws Exception {
        List<String> rows = new ArrayList<>();
        try (Statement st = connection.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT id || '|' || company_id || '|' || branch_id || '|' || currency_id"
                             + " || '|' || face_value || '|' || denomination_type || '|' || quantity"
                             + " || '|' || COALESCE(min_quantity::text, '-')"
                             + " || '|' || COALESCE(max_quantity::text, '-')"
                             + " || '|' || active || '|' || is_active || '|' || created_at"
                             + " || '|' || COALESCE(updated_at::text, '-')"
                             + " FROM denomination ORDER BY id")) {
            while (rs.next()) {
                rows.add(rs.getString(1));
            }
        }
        return rows;
    }

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
    }

    private static long count(Statement st, String sql) throws Exception {
        try (ResultSet rs = st.executeQuery(sql)) {
            assertThat(rs.next()).isTrue();
            return rs.getLong(1);
        }
    }
}
