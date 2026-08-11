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
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FK-076 (FR-1 + NFR-5): a denomination_allowed törzsadat-migráció (V376) valós-DB
 * viselkedése (Testcontainers + Flyway, a V361/V371/FK070 precedens-minta szerint).
 *
 * <p>Amit bizonyít:
 * <ul>
 *   <li>FR-1: pontosan 138 sor company-nként — 126 a V376-bol (124 banknote 21 devizara
 *       + EUR 1/2 erme) es 12 a V379 HUF-seedbol (FK-080); EUA nelkul; minden face_value egész szám. Két company esetén a seed
 *       mindkettőnek 126-126 sort ad (spec §4 edge case: „két company egyszerre").</li>
 *   <li>NFR-5: a meglévő denomination tábla tartalma bit-azonos a migráció előtt/után
 *       (se DELETE, se UPDATE nem érintheti) — teljes sor-snapshot, nem csak darabszám.</li>
 *   <li>Idempotencia: a seed-INSERT kézi újrafuttatása nem duplikál (WHERE NOT EXISTS gát).</li>
 *   <li>A CHECK megszorítások DB-szinten elutasítják a tört/negatív face_value-t és az
 *       érvénytelen denomination_type-ot.</li>
 * </ul>
 *
 * <p>Friss DB-n a Flyway-lánc (V69/V83/V110, ON CONFLICT (code) DO NOTHING) pontosan
 * EGY company-sort seedel (EBC); a második tenantot ez a teszt szúrja be a multi-company
 * szorzás bizonyításához.
 */
@Testcontainers
class DenominationAllowedFk076MigrationPostgresTest {

    // FK-080 delta: a V379 minden companynek +12 HUF sort ad (6 erme + 6 bankjegy),
    // ezert a migrateToLatest() utani vart ertekek 126->138, 2->8, 21->22 lettek.
    private static final long ROWS_PER_COMPANY = 138L;      // 126 (V376) + 12 HUF (V379)
    private static final long COIN_ROWS_PER_COMPANY = 8L;   // EUR 1/2 + HUF 200/100/50/20/10/5
    private static final long DISTINCT_CURRENCIES = 22L;    // 21 (V376) + HUF
    private static final long HUF_ROWS_PER_COMPANY = 12L;

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    /** A FK-076 migráció fájl-mintája — a V-szám nem hardkódolt (átszámozás-biztos). */
    private static final Pattern V376_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__denomination_allowed.*\\.sql$");
    /**
     * A FK-080 HUF-seed (V379) fájl-mintája — szintén átszámozás-biztos.
     * Azért kell, mert az NFR-5 bit-azonosság mérése PONTOSAN eddig migrálhat:
     * a rá következő V380 szándékosan módosítja a `denomination` táblát.
     */
    private static final Pattern HUF_SEED_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk080_denomination_allowed_huf_seed\\.sql$");

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
    // FR-1 + NFR-5 + idempotencia: 126 sor company-nként (két companyvel),
    // 21 devizakód, HUF/EUA nélkül; denomination-tábla bit-azonos; a seed
    // kézi újrafuttatása nem duplikál
    // =====================================================================
    @Test
    @DisplayName("V376+V379: 138 sor company-nként (2 company = 276 sor), 22 devizakód, HUF-fal (12 sor), EUA nélkül; denomination-tábla bit-azonos; idempotens")
    void v376SeedsExactlyTheAllowedCatalogPerCompany() throws Exception {
        migrateToVersion(previousExistingVersion());

        // Spec §4 edge case: második company — a seednek company-nként 126 sort kell adnia.
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

        // Migracio a V379-ig — NEM migrateToLatest().
        //
        // FK-080 (WU-8c): a lanc vegen ott van a V380 is, ami SZANDEKOSAN modositja a
        // `denomination` tablat (a tiltott COIN sorokat inaktivalja). Az itteni NFR-5
        // allitas viszont azt bizonyitja, hogy a KATALOGUS-SEED (V376 + a V379 HUF-seed)
        // nem nyul a `denomination` tablahoz. A migrateToLatest() a ket kulonbozo
        // szandekot egy meresbe olvasztotta, es a V380 sajat, helyes viselkedesetol
        // bukott el (merve: 304 tiltott COIN sor inaktivalva, koztuk a HUF 1/2).
        //
        // Ezert a mereshez a V379-ig migralunk: a V379 additiv a denomination_allowed-ra
        // (+12 HUF sor company-nkent) es a `denomination` tablat nem erinti — igy minden
        // itteni allitas ervenyes marad. A V380 hatasat a dedikalt
        // ForbiddenCoinDeactivationFk080MigrationPostgresTest bizonyitja.
        migrateToVersion(hufSeedVersion());

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            // FR-1: 126 sor company-nként.
            long allowedRows = count(st, "SELECT count(*) FROM denomination_allowed");
            assertThat(allowedRows).isEqualTo(ROWS_PER_COMPANY * companiesBefore);

            // Company-nkénti bontás: MINDEN company pontosan 126 sort kapott.
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

            // FK-080: a HUF MAR BENNE VAN (V379) — company-nkent pontosan 12 sor.
            // Az EUA tovabbra is kizarva.
            long hufRows = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF'");
            assertThat(hufRows)
                    .as("FK-080: a HUF a katalogus resze (12 sor company-nkent)")
                    .isEqualTo(HUF_ROWS_PER_COMPANY * companiesBefore);

            // A bevont HUF 1 es 2 forint SOHA nem kerulhet be (FK-080 FR-1).
            long hufOneOrTwo = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'HUF' AND da.face_value IN (1, 2)");
            assertThat(hufOneOrTwo)
                    .as("HUF 1 es 2 forint (2008-ban bevonva) nem engedelyezett")
                    .isZero();

            long eua = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE c.code = 'EUA'");
            assertThat(eua).isZero();

            // NFR-5 (tört címlet tilos): minden face_value egész; az egyetlen érme-kivétel
            // az EUR 1 és EUR 2 (2 sor company-nként).
            long fractional = count(st,
                    "SELECT count(*) FROM denomination_allowed "
                            + "WHERE face_value <> TRUNC(face_value, 0)");
            assertThat(fractional).isZero();

            long coins = count(st,
                    "SELECT count(*) FROM denomination_allowed "
                            + "WHERE denomination_type = 'COIN'");
            assertThat(coins)
                    .as("Csak EUR 1/2 és HUF 200..5 érme lehet (8 sor company-nként)")
                    .isEqualTo(COIN_ROWS_PER_COMPANY * companiesBefore);

            // FK-080: erme kizarolag EUR (1/2) es HUF (200..5) lehet — minden mas
            // deviza minden nevertekben BANKNOTE.
            long coinOutsideEurAndHuf = count(st,
                    "SELECT count(*) FROM denomination_allowed da "
                            + "JOIN currency c ON c.id = da.currency_id "
                            + "WHERE da.denomination_type = 'COIN' AND c.code NOT IN ('EUR','HUF')");
            assertThat(coinOutsideEurAndHuf)
                    .as("EUR-on es HUF-on kivul erme (egesz erteku is) tilos")
                    .isZero();

            // NFR-5: a meglévő denomination tábla bit-azonos a migráció előtt/után.
            assertThat(snapshotDenominationTable(connection))
                    .as("A denomination tábla tartalma nem módosulhatott (NFR-5)")
                    .isEqualTo(denominationSnapshotBefore);
        }

        // Idempotencia: a seed-INSERT kézi újrafuttatása (NFR-1 forgatókönyv: kézi
        // újra-alkalmazás) nem duplikál — a WHERE NOT EXISTS gát tartja az állapotot.
        runSeedInsertRaw();
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            assertThat(count(st, "SELECT count(*) FROM denomination_allowed"))
                    .as("A seed kézi újrafuttatása után a sorok száma változatlan")
                    .isEqualTo(ROWS_PER_COMPANY * companiesBefore);
        }
    }

    // =====================================================================
    // CHECK megszorítások: tört és negatív face_value, érvénytelen típus
    // DB-szinten elutasítva (FK-072 védelmi vonalának kettősítése)
    // =====================================================================
    @Test
    @DisplayName("V376: a CHECK megszorítások érvényesülnek (tört, negatív face_value és rossz típus elutasítva)")
    void v376CheckConstraintsRejectInvalidRows() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            String sampleRow = "SELECT company_id, currency_id FROM denomination_allowed LIMIT 1";

            assertThatThrownBy(() -> st.executeUpdate(
                    "INSERT INTO denomination_allowed (company_id, currency_id, face_value, denomination_type) "
                            + "SELECT company_id, currency_id, 0.50, 'COIN' FROM (" + sampleRow + ") t"))
                    .as("Tört face_value DB-szinten elutasítva (chk_denomination_allowed_whole)")
                    .isInstanceOf(SQLException.class);

            assertThatThrownBy(() -> st.executeUpdate(
                    "INSERT INTO denomination_allowed (company_id, currency_id, face_value, denomination_type) "
                            + "SELECT company_id, currency_id, -5, 'BANKNOTE' FROM (" + sampleRow + ") t"))
                    .as("Negatív face_value DB-szinten elutasítva (chk_denomination_allowed_positive)")
                    .isInstanceOf(SQLException.class);

            assertThatThrownBy(() -> st.executeUpdate(
                    "INSERT INTO denomination_allowed (company_id, currency_id, face_value, denomination_type) "
                            + "SELECT company_id, currency_id, 10, 'GOLD' FROM (" + sampleRow + ") t"))
                    .as("Érvénytelen denomination_type DB-szinten elutasítva (chk_denomination_allowed_type)")
                    .isInstanceOf(SQLException.class);
        }
    }

    // ============================ FLYWAY HELPEREK ============================

    /**
     * A V376 előtti LÉTEZŐ legmagasabb verzió (gap-safe — NEM `version - 1`: a
     * nyitott PR-ek miatt a számozás nem feltétlenül folytonos, és az aritmetikai
     * alak CI-ben FlywayException-höz vezet, ha a szomszédos fájl nincs a checkoutban).
     */
    private static int previousExistingVersion() throws IOException {
        int target = version(V376_FILE_PATTERN);
        Pattern any = Pattern.compile("(?i)^V(\\d+)__.*\\.sql$");
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .map(p -> any.matcher(p.getFileName().toString()))
                    .filter(Matcher::matches)
                    .map(m -> Integer.parseInt(m.group(1)))
                    .filter(v -> v < target)
                    .max(Integer::compareTo)
                    .orElseThrow(() -> new AssertionError(
                            "Nincs migráció a V" + target + " előtt"));
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
                    .as("Pontosan 1 db denomination_allowed migráció várt")
                    .hasSize(1);
            Matcher matcher = pattern.matcher(matches.get(0).getFileName().toString());
            assertThat(matcher.matches()).isTrue();
            return Integer.parseInt(matcher.group(1));
        }
    }

    /**
     * A FK-080 HUF-seed (V379) verziószáma — az NFR-5 mérés felső határa.
     *
     * <p>A rá következő V380 szándékosan módosítja a `denomination` táblát, ezért a
     * bit-azonosság mérése nem futhat a teljes láncon (lásd a mérési pont kommentjét).
     */
    private static int hufSeedVersion() throws IOException {
        return version(HUF_SEED_FILE_PATTERN);
    }

    /**
     * Kizárólag a seed-INSERT futtatása nyersen (a CREATE TABLE/INDEX/COMMENT részek
     * nélkül — azok a Flyway-úton már létrejöttek). Az INSERT a fájl egyetlen olyan
     * utasítása, amely a táblába ír; az első pontosvesszőig tart.
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

    private static Path resolveMigrationFile() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            return files
                    .filter(p -> V376_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .findFirst()
                    .orElseThrow(() -> new AssertionError(
                            "A denomination_allowed migrációs fájl nem található"));
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
            ps.setString(2, "FK-076 Test Tenant");
            ps.setString(3, "FK076T");
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
