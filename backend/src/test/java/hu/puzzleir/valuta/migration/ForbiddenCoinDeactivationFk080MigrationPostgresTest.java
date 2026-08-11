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
 * FK-080 (FR-6 + NFR-4, V380): a tiltott COIN denomination-sorok inaktivalasanak
 * valos-DB bizonyitasa (Testcontainers + Flyway, az FK-076 teszt infrastrukturajat
 * masolva).
 *
 * <p>Amit bizonyit:
 * <ul>
 *   <li>FR-6: csak azokat az AKTIV COIN sorokat inaktivalja, amelyek
 *       (company, currency, face_value) harmasara NINCS az adott company AKTIV COIN
 *       denomination_allowed katalogusaban sor (CHF 5, CZK 10 → inaktiv);
 *       az engedelyezettek (EUR 2, HUF 100) es a nem-COIN sorok (EUR 500 BANKNOTE)
 *       erintetlenek.</li>
 *   <li>Mindket active-oszlopot (active ES is_active) explicit false-ra allitja
 *       (ticket C3 — nem fugg a trg_sync_active_columns trigger tukrozeseitol).</li>
 *   <li>A mar eleve inaktiv sor nem valtozik.</li>
 *   <li>Nincs DELETE: a denomination sorok darabszama valtozatlan.</li>
 *   <li>NFR-4: a denomination_balance tabla bit-azonos a V380 elott/utan, es a
 *       deactivated sorhoz tartozo egyenleg-sor FK-n keresztul tovabbra is olvashato.</li>
 *   <li>Cross-tenant (spec §6.b): a predikatum company-szintu — company B sajat,
 *       ENGEDELYEZETT CHF 5 COIN sora NEM inaktivalodik, mig company A ugyanilyen
 *       (engedelyezetlen) sora igen. Egy company-agnosztikus NOT EXISTS ellen
 *       ez a teszt elbukna (B katalogus-sora A sorat is megvedene).</li>
 *   <li>Idempotencia: az UPDATE masodik nyers futtatasa 0 sort modosit.</li>
 * </ul>
 *
 * <p>Arrange-struktura: a ket fixture companyt a V376 ELUTT szurjuk be, hogy a
 * V376/V379 seed az o katalogusukat is feltoltse (ezert marad aktiv a V380 utan
 * az EUR 2 COIN es — a V379-nek koszonhetoen — a HUF 100 COIN). A fixture
 * denomination-sorok ezutan, a V380 futasa ELOTT kerulnek be, a V380-t pedig a
 * teljes lanc (migrateToLatest) futtatja.
 */
@Testcontainers
class ForbiddenCoinDeactivationFk080MigrationPostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    /**
     * A FK-080 tiltott-erme migracio fajl-mintaja (addendum A-8: a tervezett nevvel
     * ellenorizve — V380__fk080_tiltott_erme_sorok_inaktivalasa.sql). A V-szam nem
     * hardkódolt (atrszamoszas-biztos).
     */
    private static final Pattern V380_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk080_tiltott_erme.*\\.sql$");
    /**
     * Az FK-076 katalogus-migracio fajl-mintaja — a ketlepcsos arrange-hoz: a
     * fixture companykat a V376 seed ELUTT kell beszurni, hogy a katalogusuk
     * feltoltodjon (V376: 126 sor, V379: +12 HUF sor).
     */
    private static final Pattern V376_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__denomination_allowed.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

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
        // RED-bizonyitek: a V380 migracios fajlnak pontosan EGYnek kell lennie —
        // a migracio hianyaban ez az assert bukik eloszor.
        version(V380_FILE_PATTERN);

        // 1. lepcső: fixture companyk beszurasa a V376 ELATT (a seed szamoljon veluk).
        migrateToVersion(previousExistingVersionBefore(V376_FILE_PATTERN));
        UUID companyA = insertCompany("FK-080 Tenant A", "FK080A");
        UUID companyB = insertCompany("FK-080 Tenant B", "FK080B");

        // 2. lepcső: migracio a V380 elotti utolso verzióig — V376/V379 katalogus-seed
        // a ket uj company-ra is; a denomination tabla ekkor meg ures a fixture
        // branch-ek szamara.
        migrateToVersion(previousExistingVersionBefore(V380_FILE_PATTERN));

        UUID branchA = insertBranch(companyA, "FK080-BR-A");
        UUID branchB = insertBranch(companyB, "FK080-BR-B");

        long chf = currencyId("CHF");
        long czk = currencyId("CZK");
        long eur = currencyId("EUR");
        long huf = currencyId("HUF");

        // Company A: ket tiltott, ket engedelyezett COIN, egy BANKNOTE, egy eleve
        // inaktiv sor.
        long chf5CoinIdA = insertDenominationRow(companyA, branchA, chf, 5, "COIN", true);
        long czk10CoinIdA = insertDenominationRow(companyA, branchA, czk, 10, "COIN", true);
        long eur2CoinIdA = insertDenominationRow(companyA, branchA, eur, 2, "COIN", true);
        long huf100CoinIdA = insertDenominationRow(companyA, branchA, huf, 100, "COIN", true);
        long eur500BanknoteIdA = insertDenominationRow(companyA, branchA, eur, 500, "BANKNOTE", true);
        long chf5InactiveIdA = insertDenominationRow(companyA, branchA, chf, 5, "COIN", false);

        // Company B: ugyanaz a par, de B sajat katalogusa ENGEDELYEZI a CHF 5 COIN-t.
        long chf5CoinIdB = insertDenominationRow(companyB, branchB, chf, 5, "COIN", true);
        // CSAK company B kap engedelyezett CHF 5 COIN katalogus-sort (a V376 seedben
        // CHF-hez csak bankjegy-sorok vannak — a (company,currency,face_value) kulcs
        // nem utkozik, mert CHF 5 COIN-sor nincs a seedben).
        insertAllowedRow(companyB, chf, 5, "COIN");

        // NFR-4: egyenleg-sor (quantity=7) company A tiltott CHF 5 COIN soran.
        insertBalanceRow(branchA, chf5CoinIdA, 7);

        long denominationCountBefore;
        List<String> balanceSnapshotBefore;
        List<String> denominationSnapshotAfterFirstRun;
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            denominationCountBefore = count(st, "SELECT count(*) FROM denomination");
            balanceSnapshotBefore = snapshotDenominationBalanceTable(connection);
        }
        assertThat(balanceSnapshotBefore)
                .as("A fixture egyenleg-sora bekerult a denomination_balance tablabar")
                .isNotEmpty();
        assertThat(denominationCountBefore)
                .as("A fixture denomination-sorai bekerultek")
                .isGreaterThanOrEqualTo(7);

        // 3. lepcső: a teljes lanc — a V380 most fut.
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
            try (PreparedStatement ps = connection.prepareStatement(
                    "SELECT b.quantity FROM denomination_balance b "
                            + "JOIN denomination d ON d.id = b.denomination_id "
                            + "WHERE b.denomination_id = ?")) {
                ps.setLong(1, chf5CoinIdA);
                try (ResultSet rs = ps.executeQuery()) {
                    assertThat(rs.next())
                            .as("A quantity=7 egyenleg-sor az inaktivalas utan is olvashato az FK-n keresztul")
                            .isTrue();
                    assertThat(rs.getInt(1)).isEqualTo(7);
                }
            }

            denominationSnapshotAfterFirstRun = snapshotDenominationTable(connection);
        }

        // Idempotencia: az UPDATE nyers ujrafuttatasa 0 sort modosit, snapshot stabil.
        int secondRunAffected = runV380UpdateRaw();
        assertThat(secondRunAffected)
                .as("A masodik futas 0 sort modosit (active=true mar nem all fenn)")
                .isZero();
        try (Connection connection = openConnection()) {
            assertThat(snapshotDenominationTable(connection))
                    .as("Az idempotens masodik futas utan a denomination tabla valtozatlan")
                    .isEqualTo(denominationSnapshotAfterFirstRun);
        }
    }

    // ============================ FLYWAY HELPEREK ============================

    /**
     * Az adott mintaju migraciot ELOZO utolso LETEZO verzió (gap-safe — NEM
     * `version - 1`: a nyitott PR-ek miatt a szamozas nem feltetlenul folytonos,
     * es az aritmetikai alak CI-ben FlywayException-hoz vezet, ha a szomszedos
     * fajl nincs a checkoutban).
     */
    private static int previousExistingVersionBefore(Pattern targetPattern) throws IOException {
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
                    .as("Pontosan 1 db megfelelo FK-080 migracios fajl varva")
                    .hasSize(1);
            Matcher matcher = pattern.matcher(matches.get(0).getFileName().toString());
            assertThat(matcher.matches()).isTrue();
            return Integer.parseInt(matcher.group(1));
        }
    }

    /**
     * A V380 UPDATE-jenek nyers ujrafuttatasa (az UPDATE utasitas az elso
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

    // CodeQL java/concatenated-sql-query: minden paraméterezett INSERT PreparedStatement-tel.

    private static UUID insertCompany(String name, String code) throws Exception {
        UUID id = UUID.randomUUID();
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

    /** Engedelyezett katalogus-sor beszurasa egy adott companynek. */
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

    /** Egyenleg-sor a megadott denomination soron (cash_desk_id = branch UUID). */
    private static void insertBalanceRow(UUID branchId, long denominationId, int quantity)
            throws Exception {
        // CHF 5 erme x 7 db = 35.00 ertek.
        BigDecimal totalValue = BigDecimal.valueOf(5L * quantity).setScale(2);
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO denomination_balance (cash_desk_id, denomination_id, "
                             + "quantity, total_value, denomination_category, submission_date) "
                             + "VALUES (?, ?, ?, ?, 'EVENING', CURRENT_DATE)")) {
            ps.setObject(1, branchId);
            ps.setLong(2, denominationId);
            ps.setInt(3, quantity);
            ps.setBigDecimal(4, totalValue);
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
