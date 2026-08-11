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
 * valos-DB viselkedese (Testcontainers + Flyway, a FK-076 precedens-minta szerint).
 *
 * <p>Amit bizonyit:
 * <ul>
 *   <li>FR-1: company-nkent pontosan 12 HUF sor — COIN {200,100,50,20,10,5} es
 *       BANKNOTE {500,1000,2000,5000,10000,20000}; HUF 1 es 2 NINCS (2008-ban bevonva).
 *       Osszesen 138 sor company-nkent (126 V376 + 12 HUF), 22 deviza, EUA tovabbra
 *       is tavol.</li>
 *   <li>NFR-5: a meglevo denomination tabla bit-azonos a migracio elott/utan —
 *       V379 kizarolag a denomination_allowed tablabar ir.</li>
 *   <li>Idempotencia: a seed-INSERT kezi ujrafuttatasa 0 sort illeszt be
 *       (WHERE NOT EXISTS gat), a COMMENT ON TABLE ujrafuttatasa artalmatlan.</li>
 *   <li>A tabla-komment mar NEM allitja a HUF kizarasat (V376 kommentje a V379
 *       COMMENT ON TABLE utasitasaval frissul — maga a V376 fajl erintetlen,
 *       checksum-immutable).</li>
 * </ul>
 *
 * <p>Arrange-struktura: a masodik companyt a V376 ELUTT szurjuk be, hogy mindket
 * seed (V376: 126 sor, V379: 12 HUF sor) az o katalogusat is feltoltse — igy a
 * "138 sor company-nkent" allitas tenyleg mindket tenantot meri (spec §4 edge
 * case: "ket company egyszerre").
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
     * A FK-080 HUF-seed migracio fajl-mintaja (addendum A-8: a terv peldamintaja
     * helyett ez a helyes — a tervezett nevvel ellenorizve:
     * V379__fk080_denomination_allowed_huf_seed.sql). A V-szam nem hardkódolt.
     */
    private static final Pattern V379_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk080_denomination_allowed.*\\.sql$");
    /**
     * Az FK-076 katalogus-migracio fajl-mintaja (az FK-076 teszt mintaja) — kizarolag
     * a V379 elotti kiindulo verzió meghatarozasahoz. Addendum A-1: ennek a mintanak
     * pontosan EGY fajlra kell illeszkednie; ha a V379 fajlneve utkozne, a szigoru
     * assert hangosan elbukik — a mintat nem lazitjuk, szukseg esetan az uj fajlnevet
     * kell atnevezni.
     */
    private static final Pattern V376_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__denomination_allowed.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    /**
     * A @Container statikus, igy a tesztek EGY Postgres-en osztoznak — a determinisztikus,
     * sorrendfuggetlen allapothoz minden teszt tiszta DB-rol indul (FK066/FK070-minta).
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
    // FR-1 + NFR-5 + idempotencia: 138 sor company-nkent, 12 HUF sor pontos
    // COIN/BANKNOTE halmaza, HUF 1/2 nelkul; denomination-tabla bit-azonos;
    // a seed kezi ujrafuttatasa nem duplikal
    // =====================================================================
    @Test
    @DisplayName("V379: 138 sor company-nkent, ebbol 12 HUF (6 COIN + 6 BANKNOTE), HUF 1/2 nelkul; denomination-tabla bit-azonos; idempotens")
    void v379SeedsExactlyTheHufCatalogPerCompany() throws Exception {
        // RED-bizonyitek: a V379 migracios fajlnak pontosan EGYnek kell lennie —
        // a migracio hianyaban ez az assert bukik eloszor.
        int v379Version = version(V379_FILE_PATTERN);

        // A masodik companyt a V376 ELUTT szurjuk be, hogy a V376 (126 sor) es a
        // V379 (12 HUF sor) seed is szamoljon vele.
        migrateToVersion(previousExistingVersionBefore(V376_FILE_PATTERN));
        insertSecondCompany();

        long companiesBefore;
        List<String> denominationSnapshotBefore;
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            companiesBefore = count(st, "SELECT count(*) FROM company");
            denominationSnapshotBefore = snapshotDenominationTable(connection);
        }
        assertThat(companiesBefore)
                .as("A seed-minta feltetelezi legalabb egy company-sor letet (EBC seed + a teszt masodik companyja)")
                .isGreaterThanOrEqualTo(2);

        // A teljes migracio-lanc futtatasa a V379-cel egyutt.
        migrateToLatest();

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            // A V379 tenylegesen lefutott (szerepel a Flyway schema_history-ban).
            try (PreparedStatement ps = connection.prepareStatement(
                    "SELECT count(*) FROM flyway_schema_history WHERE version = ?")) {
                ps.setString(1, String.valueOf(v379Version));
                try (ResultSet rs = ps.executeQuery()) {
                    assertThat(rs.next()).isTrue();
                    assertThat(rs.getLong(1)).as("A V379 migracio alkalmazva").isEqualTo(1);
                }
            }

            // FR-1: 138 sor company-nkent (126 V376 + 12 HUF).
            long allowedRows = count(st, "SELECT count(*) FROM denomination_allowed");
            assertThat(allowedRows).isEqualTo(ROWS_PER_COMPANY * companiesBefore);

            // Company-nkenti bontas: MINDEN company pontosan 138 sort kapott.
            List<String> perCompanyCounts = new ArrayList<>();
            try (ResultSet rs = st.executeQuery(
                    "SELECT company_id || '|' || count(*) FROM denomination_allowed "
                            + "GROUP BY company_id ORDER BY company_id")) {
                while (rs.next()) {
                    perCompanyCounts.add(rs.getString(1));
                }
            }
            assertThat(perCompanyCounts)
                    .as("Minden company pontosan 138 sort kap (nincs reszleges seed)")
                    .hasSize((int) companiesBefore)
                    .allSatisfy(row -> assertThat(row).endsWith("|" + ROWS_PER_COMPANY));

            long distinctCurrencies = count(st,
                    "SELECT count(DISTINCT currency_id) FROM denomination_allowed");
            assertThat(distinctCurrencies).isEqualTo(DISTINCT_CURRENCIES);

            // HUF: company-nkent pontosan 12 sor.
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

            // FR-1: a HUF COIN halmaz pontosan {5,10,20,50,100,200} — darabszam helyett
            // a teljes, nevertek szerint rendezett lista (face_value|tipus).
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
                    .as("HUF erme: kizarolag 200/100/50/20/10/5 (company-nkent)")
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
                    .as("HUF bankjegy: kizarolag 500/1000/2000/5000/10000/20000 (company-nkent)")
                    .containsExactlyElementsOf(expectedBanknotes);

            // HUF 1 es 2 forint szandekosan nincs (2008-ban bevonva).
            long hufOneOrTwo = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' AND da.face_value IN (1, 2)");
            assertThat(hufOneOrTwo).isZero();

            // EUA tovabbra is tavol.
            long eua = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'EUA'");
            assertThat(eua).isZero();

            // Az erme-keszlet: EUR 1/2 + HUF 200/100/50/20/10/5 = 8 sor company-nkent.
            long coins = count(st,
                    "SELECT count(*) FROM denomination_allowed "
                            + "WHERE denomination_type = 'COIN'");
            assertThat(coins)
                    .as("Csak EUR 1/2 es HUF 200..5 erme lehet (8 sor company-nkent)")
                    .isEqualTo(COIN_ROWS_PER_COMPANY * companiesBefore);

            // NFR-5: a meglevo denomination tabla bit-azonos a migracio elott/utan.
            assertThat(snapshotDenominationTable(connection))
                    .as("A denomination tabla tartalma nem modosulhatott (NFR-5)")
                    .isEqualTo(denominationSnapshotBefore);
        }

        // Idempotencia: a seed-INSERT kezi ujrafuttatasa nem duplikal.
        runSeedInsertRaw();
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            assertThat(count(st, "SELECT count(*) FROM denomination_allowed"))
                    .as("A seed kezi ujrafuttatasa utan a sorok szama valtozatlan")
                    .isEqualTo(ROWS_PER_COMPANY * companiesBefore);
        }
    }

    // =====================================================================
    // Tabla-komment: a V376 "HUF szandekosan nincs benne" allitasa a V379
    // COMMENT ON TABLE utasitasaval frissul; az utasitas ismetelheto
    // =====================================================================
    @Test
    @DisplayName("V379: a tabla-komment mar nem allitja a HUF kizarasat, a COMMENT ujrafuttatasa artalmatlan")
    void v379TableCommentNoLongerClaimsHufExclusion() throws Exception {
        // RED-bizonyitek: a V379 migracios fajlnak pontosan EGYnek kell lennie.
        version(V379_FILE_PATTERN);

        migrateToLatest();

        long companies;
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            companies = count(st, "SELECT count(*) FROM company");

            try (ResultSet rs = st.executeQuery(
                    "SELECT obj_description('denomination_allowed'::regclass)")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString(1))
                        .as("A V376 komment HUF-kizaro allitasa a V379-cel frissul")
                        .doesNotContain("szandekosan nincs");
            }
        }

        // A COMMENT ON TABLE utasitas kezi ujrafuttatasa artalmatlan.
        runTableCommentRaw();
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            assertThat(count(st, "SELECT count(*) FROM denomination_allowed"))
                    .as("A COMMENT ujrafuttatasa nem ir sort")
                    .isEqualTo(ROWS_PER_COMPANY * companies);
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
     * Kizarolag a seed-INSERT futtatasa nyersen — a WHERE NOT EXISTS gatnak 0 uj
     * sort kell adnia. Az INSERT a fajl egyetlen tablabba iro utasitasa.
     */
    private static void runSeedInsertRaw() throws Exception {
        String sql = Files.readString(resolveMigrationFile(), StandardCharsets.UTF_8);
        int start = sql.indexOf("INSERT INTO denomination_allowed");
        assertThat(start).as("A seed-INSERT megtalalhato a migracios fajlban").isNotNegative();
        int end = sql.indexOf(';', start);
        assertThat(end).as("A seed-INSERT lezaro pontosvesszoje").isGreaterThan(start);
        String seedInsert = sql.substring(start, end);
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            int inserted = st.executeUpdate(seedInsert);
            assertThat(inserted)
                    .as("A masodik futas a WHERE NOT EXISTS miatt 0 sort illeszt be")
                    .isZero();
        }
    }

    /**
     * A COMMENT ON TABLE utasitas nyers ujrafuttatasa (artalmatlansag bizonyitasa).
     * Kivonatas a fajl UTOLSO pontosvesszojeig (a COMMENT a fajl utolso utasitasa):
     * a sztringliteralon beluli irasjelek (proza) miatti elso-';'-vagas hibas
     * SQL-torna adna — ez kivetelkeppeni fix, az assert maga valtozatlan.
     */
    private static void runTableCommentRaw() throws Exception {
        String sql = Files.readString(resolveMigrationFile(), StandardCharsets.UTF_8);
        int start = sql.indexOf("COMMENT ON TABLE denomination_allowed");
        assertThat(start).as("A COMMENT utasitas megtalalhato a migracios fajlban").isNotNegative();
        int end = sql.lastIndexOf(';');
        assertThat(end).as("A COMMENT lezaro pontosvesszoje").isGreaterThan(start);
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
                            "A fk080_denomination_allowed migracios fajl nem talalhato"));
        }
    }

    // ============================ SQL HELPEREK ============================

    /** Masodik tenant a multi-company seed bizonyitasahoz (spec §4 edge case). */
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
     * A denomination tabla teljes sor-snapshotja determinisztikus sorrendben —
     * az NFR-5 bit-azonossag bizonyitasahoz (nem eleg a darabszam: egy DELETE+INSERT
     * ugyanazt a count-ot adna).
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
