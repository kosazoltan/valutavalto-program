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
 * FK-070 Fázis 2: a V368 cash_balance-korrekció célzott integrációs tesztje —
 * VALÓS Flyway-runnerrel, a V361/FK066 migrációs-teszt precedens mintájára.
 *
 * <p>Menet tesztenként: {@code clean} → {@code target(N-1)} Flyway-migráció (a teljes
 * valós séma + seed-adatok: az EBC cég és a BR035 fiók a V69/V83/V110/V145 seedekből
 * MÁR LÉTEZIK — a teszt nem szúr be duplikátumot, hanem a meglévő sorokat állítja be)
 * → nyers SQL állapot-beállítás → {@code migrate()} a FK-070 verzióig (a korrekciót a
 * valódi Flyway-út futtatja; a lánc vége SZÁNDÉKOSAN nem fut le — a V369/V370 (FKH-028)
 * ugyanazokat a BR020/BR035 cash_balance sorokat módosítja, saját dedikált tesztje a
 * {@code Fkh028CashBalanceMigrationsPostgresTest}) → assert.</p>
 *
 * <p>A RAISE NOTICE üzeneteket a Flyway nem adja vissza a hívónak, ezért a NOTICE-
 * assertek közvetlen (raw Statement) futtatásból származnak — ugyanazon a valós,
 * migrált sémán: a T1-ben a korrekciót a raw futás végzi (NOTICE-bizonyíték: 1-1 sor),
 * és utána a Flyway-út is lefut (guard: 0 sor); a T2-ben fordítva, a korrekciót a
 * Flyway-út végzi, és a raw újrafuttatás az NFR-1 kézi újra-alkalmazást modellezi.</p>
 *
 * <p>Megjegyzés (Codex-review): "másik cég azonos BR035 kódú fiókja" teszt-eset
 * SZÁNDÉKOSAN nincs — a {@code branch.code} GLOBÁLISAN egyedi ({@code uk_branch_code},
 * V0_1 + Branch entitás {@code unique=true}, l. V277 kommentár), így ez a forgatókönyv
 * sémailag előállíthatatlan; a migráció company-szűrője e mellett defense-in-depth.
 * Ugyanezen egyediség miatt a "hiányzó BR035" eset a seedelt fiók átkódolásával áll elő
 * (DELETE a worker/cash_balance FK-k miatt nem járható).</p>
 */
@Testcontainers
class CashBalanceCorrectionFk070MigrationPostgresTest {

    private static final BigDecimal EUR_BAD = new BigDecimal("14334.45");
    private static final BigDecimal EUR_FIXED = new BigDecimal("14334.00");
    private static final BigDecimal USD_BAD = new BigDecimal("5797.57");
    private static final BigDecimal USD_FIXED = new BigDecimal("5797.00");

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    /** A FK-070 migráció fájl-mintája — a V-szám nem hardkódolt (átszámozás-biztos). */
    private static final Pattern FK070_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__.*fk070.*cash_balance.*\\.sql$");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    /**
     * A @Container statikus (V361-minta), így a tesztek EGY Postgres-en osztoznak —
     * a determinisztikus, sorrendfüggetlen állapothoz minden teszt tiszta DB-ről indul
     * (FK066-minta).
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
    // FR-1/FR-2 + scope-védelem: pontosan a két hibás sor korrigálódik,
    // NOTICE-bizonyítékkal (1-1 sor), majd a Flyway-út is hibátlanul lefut
    // =====================================================================
    @Test
    @DisplayName("FR-1/FR-2: az EBC/BR035 EUR és USD hibás sora korrigálódik (NOTICE: 1-1 sor); más valuta és más fiók érintetlen; a Flyway-út is lefut")
    void korrigaljaAKetHibasSortEsMastNemErint() throws Exception {
        migrateToVersion(fk070Version() - 1);

        UUID controlBranchId;
        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "EUR", EUR_BAD);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "USD", USD_BAD);
            // Nem érintett valuta ugyanazon a fiókon:
            upsertBalance(connection, br035.companyId(), br035.branchId(), "GBP", new BigDecimal("500.00"));
            // Nem érintett kontroll-fiók ugyanazzal a hibás értékkel (branch-scope bizonyíték):
            controlBranchId = insertControlBranch(connection, br035.companyId());
            upsertBalance(connection, br035.companyId(), controlBranchId, "EUR", EUR_BAD);
        }

        // Raw futtatás a NOTICE-bizonyítékért (a Flyway az SQLWarning-okat nem adja vissza).
        List<String> notices = runMigrationRawCollectingNotices();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("Az EBC/BR035 EUR sor a korrekció után egész érték")
                    .isEqualByComparingTo(EUR_FIXED);
            assertThat(balance(connection, "BR035", "USD"))
                    .as("Az EBC/BR035 USD sor a korrekció után egész érték")
                    .isEqualByComparingTo(USD_FIXED);
            assertThat(balance(connection, "BR035", "GBP"))
                    .as("A nem érintett GBP sor változatlan")
                    .isEqualByComparingTo("500.00");
            assertThat(balanceByBranchId(connection, controlBranchId, "EUR"))
                    .as("Másik fiók azonos hibás EUR értéke változatlan (branch-scope)")
                    .isEqualByComparingTo(EUR_BAD);
        }

        assertThat(notices)
                .as("A RAISE NOTICE pontosan 1-1 korrigált sort jelez EUR-ra és USD-re")
                .anySatisfy(n -> assertThat(n).contains("EUR 14334.45 -> 14334.00, 1 sor korrigalva"))
                .anySatisfy(n -> assertThat(n).contains("USD 5797.57 -> 5797.00, 1 sor korrigalva"));

        // A valódi Flyway-út is lefut a korrigált állapoton (guard: 0 sor), és sikeres.
        migrateThroughFk070();
        try (Connection connection = openConnection()) {
            assertThat(fk070MigrationSucceeded(connection))
                    .as("A FK-070 migráció a flyway_schema_history-ban sikeres")
                    .isTrue();
            assertThat(balance(connection, "BR035", "EUR")).isEqualByComparingTo(EUR_FIXED);
            assertThat(balance(connection, "BR035", "USD")).isEqualByComparingTo(USD_FIXED);
        }
    }

    // =====================================================================
    // NFR-1: a korrekciót a VALÓDI Flyway-út végzi; kézi újra-alkalmazás
    // (raw második futás) semmit nem változtat, és 0 sort jelez
    // =====================================================================
    @Test
    @DisplayName("NFR-1: a Flyway-út korrigál; a kézi második futtatás 0 sort érint, az állapot (értékek + updated_at) azonos marad")
    void masodikFutasSemmitNemValtoztat() throws Exception {
        migrateToVersion(fk070Version() - 1);

        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "EUR", EUR_BAD);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "USD", USD_BAD);
        }

        // Első futás: maga a Flyway-runner alkalmazza a migrációt (valódi út).
        migrateThroughFk070();

        List<String> before;
        try (Connection connection = openConnection()) {
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("A Flyway-úton futó migráció korrigálja az EUR sort")
                    .isEqualByComparingTo(EUR_FIXED);
            assertThat(balance(connection, "BR035", "USD"))
                    .as("A Flyway-úton futó migráció korrigálja az USD sort")
                    .isEqualByComparingTo(USD_FIXED);
            before = snapshotAllBalances(connection);
        }

        // Kézi újra-alkalmazás (NFR-1 forgatókönyv): 0 sor, semmi nem változik.
        List<String> secondRunNotices = runMigrationRawCollectingNotices();

        try (Connection connection = openConnection()) {
            assertThat(snapshotAllBalances(connection))
                    .as("A második futás után minden cash_balance sor (érték és updated_at) változatlan")
                    .isEqualTo(before);
        }
        assertThat(secondRunNotices)
                .as("A második futás mindkét valutára 0 érintett sort jelez")
                .anySatisfy(n -> assertThat(n).contains("EUR korrekcio NEM futott le (0"))
                .anySatisfy(n -> assertThat(n).contains("USD korrekcio NEM futott le (0"));
    }

    // =====================================================================
    // FR-3: őrfeltétel — megváltozott egyenleghez nem nyúl; a két valuta
    // guard-ja független
    // =====================================================================
    @Test
    @DisplayName("FR-3: ha az egyenleg nem a vart hibás érték, a Flyway-úton futó korrekció nem nyúl hozzá; a másik valuta őrfeltétele független")
    void orfeltetelVediAMegvaltozottEgyenleget() throws Exception {
        migrateToVersion(fk070Version() - 1);

        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);
            // EUR: NEM a vart hibás érték (időközben változott) -> nem nyúlhat hozzá
            upsertBalance(connection, br035.companyId(), br035.branchId(), "EUR", new BigDecimal("15334.45"));
            // USD: a vart hibás érték -> korrigálandó
            upsertBalance(connection, br035.companyId(), br035.branchId(), "USD", USD_BAD);
        }

        migrateThroughFk070();

        try (Connection connection = openConnection()) {
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("A megváltozott EUR egyenleghez a migráció nem nyúl")
                    .isEqualByComparingTo("15334.45");
            assertThat(balance(connection, "BR035", "USD"))
                    .as("Az USD őrfeltétele független az EUR-tól: korrigálódik")
                    .isEqualByComparingTo(USD_FIXED);
        }

        // NOTICE-bizonyíték az elmaradt EUR-korrekcióra (raw újrafutás ugyanazon a sémán;
        // az USD ekkor már korrigált, így arra is 0 sort jelez).
        List<String> notices = runMigrationRawCollectingNotices();
        assertThat(notices)
                .as("Az elmaradt EUR-korrekciót a NOTICE explicit jelzi (nem csendes)")
                .anySatisfy(n -> assertThat(n).contains("EUR korrekcio NEM futott le (0"));
        try (Connection connection = openConnection()) {
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("Az EUR a raw újrafutás után is érintetlen")
                    .isEqualByComparingTo("15334.45");
        }
    }

    // =====================================================================
    // Lookup-szűrés: INAKTÍV BR035 fiókhoz a migráció nem nyúl (is_active=TRUE
    // a feloldásban — a történelmi deaktivált duplikátum, l. V244, elleni védelem)
    // =====================================================================
    @Test
    @DisplayName("Lookup-szűrés: inaktív (is_active=FALSE) BR035 fiók hibás egyenlegéhez a Flyway-úton futó migráció nem nyúl, és NOTICE jelzi a no-opot")
    void inaktivBr035EsetenNoOp() throws Exception {
        migrateToVersion(fk070Version() - 1);

        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);
            execute(connection, "UPDATE branch SET is_active = FALSE WHERE id = ?", br035.branchId());
            upsertBalance(connection, br035.companyId(), br035.branchId(), "EUR", EUR_BAD);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "USD", USD_BAD);
        }

        migrateThroughFk070();

        try (Connection connection = openConnection()) {
            assertThat(fk070MigrationSucceeded(connection))
                    .as("A migráció inaktív BR035 mellett is sikeresen (no-opként) lefut")
                    .isTrue();
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("Az inaktív BR035 EUR egyenlege változatlan (a lookup is_active=TRUE-ra szűr)")
                    .isEqualByComparingTo(EUR_BAD);
            assertThat(balance(connection, "BR035", "USD"))
                    .as("Az inaktív BR035 USD egyenlege változatlan")
                    .isEqualByComparingTo(USD_BAD);
        }

        List<String> notices = runMigrationRawCollectingNotices();
        assertThat(notices)
                .as("A NOTICE jelzi, hogy aktív BR035 nem található")
                .anySatisfy(n -> assertThat(n).contains("BR035 branch (EBC ceg) nem talalhato"));
    }

    // =====================================================================
    // Lookup-szűrés: nem-EBC company.code esetén a migráció nem nyúl az
    // egyenlegekhez (Codex-adta teszteset, változtatás nélkül beillesztve).
    //
    // Codex-figyelmeztetés: a "más cég" állapotot a seedelt cég code mezőjének
    // átírásával állítjuk elő — a jelzett V369+ eset az FKH-028-cal be is következett,
    // ezért a teszt már nem latest-ig, hanem a FK-070 verzióig migrál
    // (migrateThroughFk070), így a későbbi migrációk mellékhatásaitól független.
    // =====================================================================
    @Test
    @DisplayName("Lookup-szűrés: ha a BR035 mögötti cég code-ja nem 'EBC', a Flyway-úton futó migráció nem nyúl az egyenlegekhez, és NOTICE jelzi a no-opot")
    void nemEbcCompanyCodeEsetenNoOp() throws Exception {
        migrateToVersion(fk070Version() - 1);

        List<String> before;
        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);

            // Séma-konform negatív eset: a seedelt cég FK-k érintése nélkül más code-ot kap,
            // így a V368 lookup (branch.code='BR035' AND company.code='EBC' AND is_active=TRUE)
            // már nem talál célfiókot.
            execute(connection, "UPDATE company SET code = 'FK070NOEBC' WHERE id = ?", br035.companyId());

            upsertBalance(connection, br035.companyId(), br035.branchId(), "EUR", EUR_BAD);
            upsertBalance(connection, br035.companyId(), br035.branchId(), "USD", USD_BAD);

            before = snapshotAllBalances(connection);
        }

        migrateThroughFk070();

        try (Connection connection = openConnection()) {
            assertThat(fk070MigrationSucceeded(connection))
                    .as("A migráció EBC-től eltérő company.code mellett is sikeresen (no-opként) lefut")
                    .isTrue();
            assertThat(snapshotAllBalances(connection))
                    .as("A company.code != 'EBC' miatt semmilyen cash_balance sor nem változott")
                    .isEqualTo(before);
            assertThat(balance(connection, "BR035", "EUR"))
                    .as("Az EBC-től eltérő company.code miatt a BR035 EUR egyenlege változatlan")
                    .isEqualByComparingTo(EUR_BAD);
            assertThat(balance(connection, "BR035", "USD"))
                    .as("Az EBC-től eltérő company.code miatt a BR035 USD egyenlege változatlan")
                    .isEqualByComparingTo(USD_BAD);
        }

        List<String> notices = runMigrationRawCollectingNotices();
        assertThat(notices)
                .as("A NOTICE jelzi, hogy nincs EBC-hez tartozó aktív BR035")
                .anySatisfy(n -> assertThat(n).contains("BR035 branch (EBC ceg) nem talalhato"));
    }

    // =====================================================================
    // Hiányzó BR035: no-op, nem hibázik — a fiók átkódolásával előállítva
    // (a branch.code globálisan egyedi; DELETE az FK-k miatt nem járható)
    // =====================================================================
    @Test
    @DisplayName("Hiányzó BR035 fiók esetén a Flyway-úton futó migráció hibátlan no-op, és semmilyen cash_balance sort nem érint")
    void hianyzoBr035EsetenNoOp() throws Exception {
        migrateToVersion(fk070Version() - 1);

        List<String> before;
        try (Connection connection = openConnection()) {
            Br035 br035 = resolveSeededBr035(connection);
            execute(connection, "UPDATE branch SET code = 'FK070RNMD' WHERE id = ?", br035.branchId());
            before = snapshotAllBalances(connection);
        }

        migrateThroughFk070();

        try (Connection connection = openConnection()) {
            assertThat(fk070MigrationSucceeded(connection))
                    .as("A migráció hiányzó BR035 mellett is sikeresen (no-opként) lefut")
                    .isTrue();
            assertThat(snapshotAllBalances(connection))
                    .as("Semmilyen cash_balance sor nem változott")
                    .isEqualTo(before);
        }

        List<String> notices = runMigrationRawCollectingNotices();
        assertThat(notices)
                .as("A NOTICE jelzi, hogy aktív BR035 nem található")
                .anySatisfy(n -> assertThat(n).contains("BR035 branch (EBC ceg) nem talalhato"));
    }

    // ============================ FLYWAY HELPEREK ============================

    /** A FK-070 migráció fájlja — mintára keres, nem hardkódolt V-számra (FK066-minta). */
    private static Path resolveFk070Migration() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> FK070_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("Pontosan 1 db V*__fk070*cash_balance*.sql migráció várt")
                    .hasSize(1);
            return matches.get(0);
        }
    }

    private static int fk070Version() throws IOException {
        Matcher matcher = FK070_FILE_PATTERN.matcher(resolveFk070Migration().getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        return Integer.parseInt(matcher.group(1));
    }

    private static void migrateToVersion(int version) {
        Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .target(MigrationVersion.fromVersion(String.valueOf(version)))
                .load()
                .migrate();
    }

    /**
     * A Flyway-út futtatása a FK-070 migrációig (bezárólag) — NEM latest-ig: a V369/V370
     * (FKH-028) szándékosan módosítja a BR020/BR035 cash_balance sorokat, így a latest-ig
     * futás a FK-070-specifikus assertek alól kihúzná a talajt (a lenti Codex-figyelmeztetés
     * által előre jelzett eset). A V369/V370 lefedése: Fkh028CashBalanceMigrationsPostgresTest.
     */
    private static void migrateThroughFk070() throws IOException {
        migrateToVersion(fk070Version());
    }

    private static boolean fk070MigrationSucceeded(Connection connection) throws Exception {
        return "true".equals(queryForString(connection,
                "SELECT success::text FROM flyway_schema_history WHERE version = ?",
                String.valueOf(fk070Version())));
    }

    /**
     * A migráció kézi (raw) futtatása EGY utasításként — a DO $$ blokk miatt nem
     * darabolható — a RAISE NOTICE üzenetek (SQLWarning-lánc) kigyűjtésével.
     */
    private static List<String> runMigrationRawCollectingNotices() throws Exception {
        String sql = Files.readString(resolveFk070Migration(), StandardCharsets.UTF_8);
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

    private record Br035(UUID branchId, UUID companyId) {
    }

    /** A migrációk (V69/V83/V110/V145) által seedelt EBC/BR035 feloldása. */
    private static Br035 resolveSeededBr035(Connection connection) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT b.id, b.company_id
                  FROM branch b
                  JOIN company co ON co.id = b.company_id
                 WHERE b.code = 'BR035' AND co.code = 'EBC'
                """)) {
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next())
                        .as("A migrált sémában léteznie kell a seedelt EBC/BR035 fióknak")
                        .isTrue();
                return new Br035(
                        resultSet.getObject(1, UUID.class),
                        resultSet.getObject(2, UUID.class));
            }
        }
    }

    private static UUID insertControlBranch(Connection connection, UUID companyId) throws Exception {
        UUID id = UUID.randomUUID();
        execute(connection, """
                INSERT INTO branch (id, code, company_id, name)
                VALUES (?, 'FK070CTRL', ?, 'FK-070 kontroll fiok')
                """, id, companyId);
        return id;
    }

    /** cash_balance upsert — a seed-migrációk után létezhet már sor a (branch, currency) párra. */
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

    private static BigDecimal balance(Connection connection, String branchCode, String currencyCode)
            throws Exception {
        return queryForBigDecimal(connection, """
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN branch b   ON b.id = cb.branch_id
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE b.code = ? AND c.code = ?
                """, branchCode, currencyCode);
    }

    private static BigDecimal balanceByBranchId(Connection connection, UUID branchId, String currencyCode)
            throws Exception {
        return queryForBigDecimal(connection, """
                SELECT cb.current_balance
                  FROM cash_balance cb
                  JOIN currency c ON c.id = cb.currency_id
                 WHERE cb.branch_id = ? AND c.code = ?
                """, branchId, currencyCode);
    }

    /** Minden cash_balance sor (érték + updated_at) determinisztikus sorrendben. */
    private static List<String> snapshotAllBalances(Connection connection) throws Exception {
        List<String> rows = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement("""
                SELECT id || '|' || current_balance || '|' || COALESCE(updated_at::text, '-')
                  FROM cash_balance ORDER BY id
                """)) {
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    rows.add(resultSet.getString(1));
                }
            }
        }
        return rows;
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

    private static BigDecimal queryForBigDecimal(Connection connection, String sql, Object... parameters)
            throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, parameters);
            try (ResultSet resultSet = statement.executeQuery()) {
                assertThat(resultSet.next()).as("Egy sor várt: %s", sql).isTrue();
                return resultSet.getBigDecimal(1);
            }
        }
    }

    private static void bind(PreparedStatement statement, Object... parameters) throws Exception {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
