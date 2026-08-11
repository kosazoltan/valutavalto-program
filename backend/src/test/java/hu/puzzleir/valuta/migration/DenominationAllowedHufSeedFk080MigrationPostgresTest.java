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
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-080 (FR-1 + NFR-4/NFR-5): a denomination_allowed HUF-seed migracio (V379)
 * valós-DB viselkedése (Testcontainers + Flyway, a FK-076 precedens-minta szerint).
 *
 * <p>Amit bizonyít:
 * <ul>
 *   <li>FR-1: company-nként pontosan 12 HUF sor — COIN {200,100,50,20,10,5} és
 *       BANKNOTE {500,1000,2000,5000,10000,20000}; HUF 1 és 2 NINCS (2008-ban bevonva).
 *       Összesen 138 sor company-nként (126 V376 + 12 HUF), 22 deviza, EUA továbbra
 *       is távol.</li>
 *   <li>NFR-5: a meglévő denomination tábla bit-azonos a migráció előtt/után —
 *       V379 kizárólag a denomination_allowed táblába ír.</li>
 *   <li>Idempotencia: a seed-INSERT kézi újrafuttatása 0 sort illeszt be
 *       (WHERE NOT EXISTS gát), a COMMENT ON TABLE újrafuttatása ártalmatlan.</li>
 *   <li>A tábla-komment már NEM állítja a HUF kizárását (V376 kommentje a V379
 *       COMMENT ON TABLE utasításával frissül — a V376 fájl itself érintetlen,
 *       checksum-immutable).</li>
 * </ul>
 */
@Testcontainers
class DenominationAllowedHufSeedFk080MigrationPostgresTest {

    private static final long ROWS_PER_COMPANY = 138L;   // 126 (V376) + 12 HUF (V379)
    private static final long COIN_ROWS_PER_COMPANY = 8L; // EUR 1/2 + HUF 200/100/50/20/10/5
    private static final long DISTINCT_CURRENCIES = 22L;  // 21 (V376) + HUF
    private static final long HUF_ROWS_PER_COMPANY = 12L;

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    /**
     * A FK-080 HUF-seed migráció fájl-mintája — a V-szám nem hardkódolt
     * (átszámozás-biztos). A minta a tervezett névvel ellenőrizve:
     * V379__fk080_denomination_allowed_huf_seed.sql.
     */
    private static final Pattern V379_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk080_denomination_allowed.*\\.sql$");
    /** A FK-076 katalogus-migracio mintaja (a company-beszuras idozitesehez). */
    private static final Pattern V376_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__denomination_allowed.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    /**
     * A @Container statikus, így a tesztek EGY Postgres-en osztoznak — a determinisztikus,
     * sorrendfüggetlen állapothoz minden teszt tiszta DB-ről indul (FK066/FK070-minta).
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

    // =====================================================================
    // FR-1 + NFR-5 + idempotencia: 138 sor company-nként, 12 HUF sor pontos
    // COIN/BANKNOTE halmaza, HUF 1/2 nélkül; denomination-tábla bit-azonos;
    // a seed kézi újrafuttatása nem duplikál
    // =====================================================================
    @Test
    @DisplayName("V379: 138 sor company-nként, ebből 12 HUF (6 COIN + 6 BANKNOTE), HUF 1/2 nélkül; denomination-tábla bit-azonos; idempotens")
    void v379SeedsExactlyTheHufCatalogPerCompany() throws Exception {
        // A masodik companyt meg a V376 ELOTT szurjuk be, hogy a katalogus-seed
        // (V376 + V379) az o sorait is feltoltse — a company-nkenti 138 soros
        // szorzas csak igy bizonyithato (a V376 utan beszurt company katalogusa
        // ures maradna). Spec §4 edge case: ket company egyideju seederese.
        migrateToVersion(highestExistingBelow(V376_FILE_PATTERN));
        insertSecondCompany();

        long companiesBefore;
        List<String> denominationSnapshotBefore;
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            companiesBefore = count(st, "SELECT count(*) FROM company");
            denominationSnapshotBefore = snapshotDenominationTable(connection);
        }
        assertThat(companiesBefore)
                .as("A seed-minta feltételezi legalább egy company-sor létét (EBC seed + a teszt második companyja)")
                .isGreaterThanOrEqualTo(2);

        // CSAK a V379-ig migralunk: a denomination bit-azonossag bizonyitasa a V379
        // ablaka. A V380 (tiltott COIN sorok inaktivalasa) csak a V379 UTAN futtathato,
        // es a hatasat a ForbiddenCoinDeactivationFk080MigrationPostgresTest bizonyitja.
        migrateToVersion(version(V379_FILE_PATTERN));

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            // FR-1: 138 sor company-nként (126 V376 + 12 HUF).
            long allowedRows = count(st, "SELECT count(*) FROM denomination_allowed");
            assertThat(allowedRows).isEqualTo(ROWS_PER_COMPANY * companiesBefore);

            // Company-nkénti bontás: MINDEN company pontosan 138 sort kapott.
            List<String> perCompanyCounts = new ArrayList<>();
            try (ResultSet rs = st.executeQuery(
                    "SELECT company_id || '|' || count(*) FROM denomination_allowed "
                            + "GROUP BY company_id ORDER BY company_id")) {
                while (rs.next()) {
                    perCompanyCounts.add(rs.getString(1));
                }
            }
            assertThat(perCompanyCounts)
                    .as("Minden company pontosan 138 sort kap (nincs részleges seed)")
                    .hasSize((int) companiesBefore)
                    .allSatisfy(row -> assertThat(row).endsWith("|" + ROWS_PER_COMPANY));

            long distinctCurrencies = count(st,
                    "SELECT count(DISTINCT currency_id) FROM denomination_allowed");
            assertThat(distinctCurrencies).isEqualTo(DISTINCT_CURRENCIES);

            // HUF: company-nként pontosan 12 sor.
            List<String> hufPerCompany = new ArrayList<>();
            try (ResultSet rs = st.executeQuery(
                    "SELECT da.company_id || '|' || count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' GROUP BY da.company_id ORDER BY da.company_id")) {
                while (rs.next()) {
                    hufPerCompany.add(rs.getString(1));
                }
            }
            assertThat(hufPerCompany)
                    .as("Minden company pontosan 12 HUF sort kap")
                    .hasSize((int) companiesBefore)
                    .allSatisfy(row -> assertThat(row).endsWith("|" + HUF_ROWS_PER_COMPANY));

            // FR-1: a HUF COIN halmaz pontosan {200,100,50,20,10,5} — darabszám helyett
            // a teljes, névérték szerint rendezett lista (face_value|tipus).
            List<String> hufCoins = new ArrayList<>();
            try (ResultSet rs = st.executeQuery(
                    "SELECT TRUNC(da.face_value, 0)::bigint || '|' || da.denomination_type "
                            + "FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' AND da.denomination_type = 'COIN' "
                            + "ORDER BY da.face_value, da.company_id")) {
                while (rs.next()) {
                    hufCoins.add(rs.getString(1));
                }
            }
            List<String> expectedCoins = new ArrayList<>();
            for (String coin : List.of("5|COIN", "10|COIN", "20|COIN", "50|COIN", "100|COIN", "200|COIN")) {
                for (int i = 0; i < companiesBefore; i++) {
                    expectedCoins.add(coin);
                }
            }
            assertThat(hufCoins)
                    .as("HUF érme: kizárólag 200/100/50/20/10/5 (company-nként)")
                    .containsExactlyElementsOf(expectedCoins);

            // FR-1: a HUF BANKNOTE halmaz pontosan {500,1000,2000,5000,10000,20000}.
            List<String> hufBanknotes = new ArrayList<>();
            try (ResultSet rs = st.executeQuery(
                    "SELECT TRUNC(da.face_value, 0)::bigint || '|' || da.denomination_type "
                            + "FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' AND da.denomination_type = 'BANKNOTE' "
                            + "ORDER BY da.face_value, da.company_id")) {
                while (rs.next()) {
                    hufBanknotes.add(rs.getString(1));
                }
            }
            List<String> expectedBanknotes = new ArrayList<>();
            for (String banknote : List.of("500|BANKNOTE", "1000|BANKNOTE", "2000|BANKNOTE",
                    "5000|BANKNOTE", "10000|BANKNOTE", "20000|BANKNOTE")) {
                for (int i = 0; i < companiesBefore; i++) {
                    expectedBanknotes.add(banknote);
                }
            }
            assertThat(hufBanknotes)
                    .as("HUF bankjegy: kizárólag 500/1000/2000/5000/10000/20000 (company-nként)")
                    .containsExactlyElementsOf(expectedBanknotes);

            // HUF 1 és 2 forint szándékosan nincs (2008-ban bevonva).
            long hufOneOrTwo = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' AND da.face_value IN (1, 2)");
            assertThat(hufOneOrTwo).isZero();

            // EUA továbbra is távol.
            long eua = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'EUA'");
            assertThat(eua).isZero();

            // Az érme-készlet: EUR 1/2 + HUF 200/100/50/20/10/5 = 8 sor company-nként.
            long coins = count(st,
                    "SELECT count(*) FROM denomination_allowed "
                            + "WHERE denomination_type = 'COIN'");
            assertThat(coins)
                    .as("Csak EUR 1/2 és HUF 200..5 érme lehet (8 sor company-nként)")
                    .isEqualTo(COIN_ROWS_PER_COMPANY * companiesBefore);

            // NFR-5: a meglévő denomination tábla bit-azonos a migráció előtt/után.
            assertThat(snapshotDenominationTable(connection))
                    .as("A denomination tábla tartalma nem módosulhatott (NFR-5)")
                    .isEqualTo(denominationSnapshotBefore);
        }

        // Idempotencia: a seed-INSERT kézi újrafuttatása nem duplikál.
        runSeedInsertRaw();
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            assertThat(count(st, "SELECT count(*) FROM denomination_allowed"))
                    .as("A seed kézi újrafuttatása után a sorok száma változatlan")
                    .isEqualTo(ROWS_PER_COMPANY * companiesBefore);
        }
    }

    // =====================================================================
    // Tábla-komment: a V376 "HUF szandekosan nincs benne" állítása a V379
    // COMMENT ON TABLE utasításával frissül; az utasítás ismételhető
    // =====================================================================
    @Test
    @DisplayName("V379: a tábla-komment már nem állítja a HUF kizárását, a COMMENT újrafuttatása ártalmatlan")
    void v379TableCommentNoLongerClaimsHufExclusion() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection(); Statement st = connection.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT obj_description('denomination_allowed'::regclass)")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString(1))
                    .as("A V376 komment HUF-kizáró állítása a V379-cel frissül")
                    .doesNotContain("szandekosan nincs");
        }

        // A COMMENT ON TABLE utasítás kézi újrafuttatása ártalmatlan.
        runTableCommentRaw();
        try (Connection connection = openConnection(); Statement st = connection.createStatement();
             ResultSet rs = st.executeQuery("SELECT count(*) FROM denomination_allowed")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getLong(1))
                    .as("A COMMENT újrafuttatása nem ír sort")
                    .isEqualTo(ROWS_PER_COMPANY * count(st, "SELECT count(*) FROM company"));
        }
    }

    // ============================ FLYWAY HELPEREK ============================

    /**
     * A megadott fajl-mintaju migracio ELOTTI LEGMAGASABB letezo verzió (gap-safe —
     * NEM `version - 1`; a nyitott PR-ek miatt a szamozas nem feltetlenul folytonos,
     * es az aritmetikai alak CI-ben FlywayException-hoz vezetne).
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

    private static int version(Pattern pattern) throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> pattern.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("Pontosan 1 db fk080_denomination_allowed migráció várt")
                    .hasSize(1);
            Matcher matcher = pattern.matcher(matches.get(0).getFileName().toString());
            assertThat(matcher.matches()).isTrue();
            return Integer.parseInt(matcher.group(1));
        }
    }

    /**
     * Kizárólag a seed-INSERT futtatása nyersen — a WHERE NOT EXISTS gátnak 0 új
     * sort kell adnia. Az INSERT a fájl egyetlen táblába író utasítása.
     */
    private static void runSeedInsertRaw() throws Exception {
        String sql = Files.readString(resolveMigrationFile(), StandardCharsets.UTF_8);
        int start = sql.indexOf("INSERT INTO denomination_allowed");
        assertThat(start).as("A seed-INSERT megtalálható a migrációs fájlban").isNotNegative();
        int end = sql.indexOf(';', start);
        assertThat(end).as("A seed-INSERT lezáró pontosvesszője").isGreaterThan(start);
        String seedInsert = sql.substring(start, end);
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            int inserted = st.executeUpdate(seedInsert);
            assertThat(inserted)
                    .as("A második futás a WHERE NOT EXISTS miatt 0 sort illeszt be")
                    .isZero();
        }
    }

    /** A COMMENT ON TABLE utasítás nyers újrafuttatása (ártalmatlanság bizonyítása). */
    private static void runTableCommentRaw() throws Exception {
        String sql = Files.readString(resolveMigrationFile(), StandardCharsets.UTF_8);
        int start = sql.indexOf("COMMENT ON TABLE denomination_allowed");
        assertThat(start).as("A COMMENT utasítás megtalálható a migrációs fájlban").isNotNegative();
        int end = sql.indexOf(';', start);
        assertThat(end).as("A COMMENT lezáró pontosvesszője").isGreaterThan(start);
        String comment = sql.substring(start, end);
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            st.execute(comment);
        }
    }

    private static Path resolveMigrationFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .filter(p -> V379_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .findFirst()
                    .orElseThrow(() -> new AssertionError(
                            "A fk080_denomination_allowed migrációs fájl nem található"));
        }
    }

    // ============================ SQL HELPEREK ============================

    /** Második tenant a multi-company seed bizonyításához (spec §4 edge case). */
    private static void insertSecondCompany() throws Exception {
        // CodeQL java/concatenated-sql-query (HIGH): a UUID string-konkatenacio helyett
        // PreparedStatement — a teszt sem epithet SQL-t osszefuzessel (a szabaly a
        // teszt-forrasra is ervenyes, es ez az egyetlen helyes minta).
        try (Connection connection = openConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "INSERT INTO company (id, name, code, is_active, created_at) "
                             + "VALUES (?, ?, ?, true, NOW())")) {
            ps.setObject(1, UUID.randomUUID());
            ps.setString(2, "FK-080 HUF Seed Test Tenant");
            ps.setString(3, "FK080T");
            ps.executeUpdate();
        }
    }

    /**
     * A denomination tábla teljes sor-snapshotja determinisztikus sorrendben —
     * az NFR-5 bit-azonosság bizonyításához (nem elég a darabszám: egy DELETE+INSERT
     * ugyanazt a count-ot adná).
     */
    private static List<String> snapshotDenominationTable(Connection connection) throws Exception {
        List<String> rows = new ArrayList<>();
        try (Statement st = connection.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT id || '|' || company_id || '|' || branch_id || '|' || currency_id"
                             + " || '|' || face_value || '|' || denomination_type || '|' || quantity"
                             + " || '|' || COALESCE(min_quantity::text, '-')"
                             + " || '|' || COALESCE(max_quantity::text, '-')"
                             + " || '|' || active || '|' || created_at || '|' || COALESCE(updated_at::text, '-')"
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
