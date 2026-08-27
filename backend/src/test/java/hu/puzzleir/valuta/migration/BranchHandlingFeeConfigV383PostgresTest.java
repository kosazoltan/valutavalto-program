package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
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
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FK-096: iroda-szintu kezelesi dij konfiguracio — V383 migracios teszt.
 *
 * <p>Bizonyitando allitasok:</p>
 * <ul>
 *   <li>RED-repro: V383 elott a {@code branch_handling_fee_config} tabla NEM letezik.</li>
 *   <li>FR-1: a tabla a megadott oszlopokkal all, es irodankent max 1 LIVE + 1 DRAFT
 *       aktiv sor lehet ( parcialis egyedi indexek: {@code uk_bhfc_branch_live},
 *       {@code uk_bhfc_branch_draft}).</li>
 *   <li>FR-2: a seed minden AKTIV irodanak LIVE sort ad, amely a korabbi cegszintu
 *       {@code system_parameter} erteket reprodukálja (D6 precedencia: ceg-scope sor
 *       eloszor, majd global, majd kod-default BRACKET). A cap VERBATIM (D5, nincs
 *       5 Ft kerekites). Nem kanonikus type-ertek nem buktatja a migraciot (B1).</li>
 *   <li>FR-3: a {@code handling_fee_bracket.status} oszlop DEFAULT 'LIVE' es minden
 *       meglevo sor 'LIVE'.</li>
 *   <li>NFR-2: a nyers SQL idempotens.</li>
 *   <li>D7: VAULT_COUNTERPARTY tipusu aktiv iroda is kap LIVE sort.</li>
 * </ul>
 */
@Testcontainers
class BranchHandlingFeeConfigV383PostgresTest {

    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");
    private static final Pattern V383_FILE_PATTERN =
            Pattern.compile("(?i)^V(\\d+)__fk096_branch_handling_fee_config.*\\.sql$");

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
    // RED-repro — a V383 ELOTTI allapot
    // =====================================================================
    @Test
    @DisplayName("RED-repro: V383 elott a branch_handling_fee_config tabla nem letezik")
    void redRepro_v383ElottNincsTabla() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            assertThat(tableExists(connection, "branch_handling_fee_config"))
                    .as("V383 elott a tabla meg nem allhat")
                    .isFalse();
        }
    }

    // =====================================================================
    // FR-1 — sema es egyedi kulcsok
    // =====================================================================
    @Test
    @DisplayName("V383/FR-1: a tabla pontosan a tervezett oszlopokkal all")
    void fr1_semaOszlopok() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(tableColumns(connection, "branch_handling_fee_config"))
                    .as("FR-1: a tabla oszlopkészlete")
                    .containsExactly(
                            "id", "company_id", "branch_id", "fee_mode", "per_mille_rate",
                            "per_mille_cap", "status", "is_active", "valid_from", "version",
                            "created_by", "created_at", "published_by", "published_at");
        }
    }

    @Test
    @DisplayName("V383/FR-1: irodankent max 1 LIVE + 1 DRAFT aktiv sor (parcialis egyedi indexek)")
    void fr1_egyLiveEsEgyDraftPerIroda() throws Exception {
        migrateToLatest();

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "C1");
            UUID branchId = seedBranch(connection, companyId, "B1", true, null);

            insertConfig(connection, companyId, branchId, "LIVE", "BRACKET");
            assertThatThrownBy(() -> insertConfig(connection, companyId, branchId, "LIVE", "BRACKET"))
                    .as("FR-1: a masodik aktiv LIVE sor unique-utkozik")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uk_bhfc_branch_live");

            assertThatCode(() -> insertConfig(connection, companyId, branchId, "DRAFT", "BRACKET"))
                    .as("FR-1: egy LIVE es egy DRAFT sor egyutt elfer")
                    .doesNotThrowAnyException();

            assertThatThrownBy(() -> insertConfig(connection, companyId, branchId, "DRAFT", "BRACKET"))
                    .as("FR-1: a masodik aktiv DRAFT sor unique-utkozik")
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uk_bhfc_branch_draft");
        }
    }

    // =====================================================================
    // FR-2 — seed: minden aktiv iroda LIVE sort kap a cegszintu parameter szerint
    // =====================================================================
    @Test
    @DisplayName("V383/FR-2: minden aktiv iroda PER_MILLE LIVE sort kap a globalis parameterbol;"
            + " inaktiv iroda nem kap sort")
    void fr2_mindenAktivIrodaKapLiveSort() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "PM");
            UUID b1 = seedBranch(connection, companyId, "PM1", true, null);
            UUID b2 = seedBranch(connection, companyId, "PM2", true, null);
            UUID b3 = seedBranch(connection, companyId, "PM3", true, null);
            UUID inactive = seedBranch(connection, companyId, "PM4", false, null);
            seedGlobalParameter(connection, "HANDLING_FEE_TYPE", "PER_MILLE");
            seedGlobalParameter(connection, "HANDLING_FEE_PER_MILLE", "3.5");
            seedGlobalParameter(connection, "HANDLING_FEE_PER_MILLE_MAX", "2003");

            migrateToLatest();

            for (UUID branchId : List.of(b1, b2, b3)) {
                assertLiveRow(connection, branchId, "PER_MILLE", "3.500");
            }
            assertThat(countLiveRows(connection, inactive))
                    .as("FR-2: inaktiv iroda NEM kap seed-sort")
                    .isZero();
        }
    }

    @Test
    @DisplayName("V383/FR-2/D5: a per_mille_cap VERBATIM 2003.00 — NEM 5 Ft-ra kerekített 2005")
    void fr2_capVerbatim() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "CV");
            UUID branchId = seedBranch(connection, companyId, "CV1", true, null);
            seedGlobalParameter(connection, "HANDLING_FEE_TYPE", "PER_MILLE");
            seedGlobalParameter(connection, "HANDLING_FEE_PER_MILLE", "3.5");
            seedGlobalParameter(connection, "HANDLING_FEE_PER_MILLE_MAX", "2003");

            migrateToLatest();

            assertThat(new java.math.BigDecimal(queryForString(connection,
                    "SELECT per_mille_cap FROM branch_handling_fee_config"
                            + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchId)))
                    .as("D5: a seed VERBATIM erteket ir, 5 Ft kerekites nelkul")
                    .isEqualByComparingTo("2003.00");
        }
    }

    @Test
    @DisplayName("V383/FR-2/D6: a ceg-scope HANDLING_FEE_TYPE override nyer a globalissal szemben")
    void fr2_cegSzintuOverrideNyer() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyA = seedCompany(connection, "CA");
            UUID branchA = seedBranch(connection, companyA, "CA1", true, null);
            UUID companyB = seedCompany(connection, "CB");
            UUID branchB = seedBranch(connection, companyB, "CB1", true, null);

            seedGlobalParameter(connection, "HANDLING_FEE_TYPE", "PER_MILLE");
            seedCompanyParameter(connection, companyA, "HANDLING_FEE_TYPE", "BRACKET");

            migrateToLatest();

            assertThat(queryForString(connection,
                    "SELECT fee_mode FROM branch_handling_fee_config"
                            + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchA))
                    .as("D6: az A ceget a ceg-scope BRACKET sor irja felul")
                    .isEqualTo("BRACKET");
            assertThat(queryForString(connection,
                    "SELECT fee_mode FROM branch_handling_fee_config"
                            + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchB))
                    .as("D6: a B ceg a global PER_MILLE-t orokolja")
                    .isEqualTo("PER_MILLE");
        }
    }

    @Test
    @DisplayName("V383/FR-2: HANDLING_FEE_* parameter nelkul a default BRACKET (HandlingFeeService:132 paritas)")
    void fr2_parameterNelkulBracketDefault() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "DF");
            UUID branchId = seedBranch(connection, companyId, "DF1", true, null);
            // V46 globalis HANDLING_FEE_* seed-sorait toroljuk: a "parameter nelkul"
            // agnak TENYLEGESEN parameter-mentes DB-rol kell indulnia.
            deleteHandlingFeeParameters(connection);

            migrateToLatest();

            assertLiveRow(connection, branchId, "BRACKET", null);
        }
    }

    @ParameterizedTest(name = "nem kanonikus type [{0}] → {1}, a migracio nem szakad meg")
    @CsvSource({
            "EZRELÉK, BRACKET",
            "Foo, BRACKET",
            "'BRACKET ', BRACKET",
            "per_mille, PER_MILLE",
            "'', BRACKET",
    })
    @DisplayName("V383/FR-2/B1: nem kanonikus HANDLING_FEE_TYPE ertek nem buktatja a migraciot")
    void fr2_nemKanonikusTypeBracketDefault(String rawType, String expectedMode) throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "NK");
            UUID branchId = seedBranch(connection, companyId, "NK1", true, null);
            seedGlobalParameter(connection, "HANDLING_FEE_TYPE", rawType);

            // B1 lenyeg: a CHECK (fee_mode IN ...) nem buktathatja meg az egesz V383-at —
            // a whitelist-map kanonizal, a mai runtime-fallback (BRACKET) szerint.
            assertThatCode(this::migrateToLatest)
                    .as("B1: a nem kanonikus parameter-ertek NEM szakithatja meg a migraciot")
                    .doesNotThrowAnyException();

            assertLiveRow(connection, branchId, expectedMode, null);
        }
    }

    // =====================================================================
    // FR-3 — handling_fee_bracket.status
    // =====================================================================
    @Test
    @DisplayName("V383/FR-3: handling_fee_bracket.status DEFAULT 'LIVE'; meglevo sorok LIVE-ok")
    void fr3_bracketStatusLive() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "FB");
            execute(connection,
                    "INSERT INTO handling_fee_bracket (company_id, bracket_order, upper_limit, fee_amount, active)"
                            + " VALUES (?, 1, 100000, 200, true)",
                    companyId);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            assertThat(queryForString(connection,
                    "SELECT status FROM handling_fee_bracket LIMIT 1"))
                    .as("FR-3: a meglevo sor LIVE statuszt kap")
                    .isEqualTo("LIVE");
            assertThat(queryForString(connection,
                    "SELECT column_default FROM information_schema.columns"
                            + " WHERE table_name = 'handling_fee_bracket' AND column_name = 'status'"))
                    .as("FR-3: az uj oszlop DEFAULT 'LIVE'")
                    .contains("LIVE");
        }
    }

    // =====================================================================
    // NFR-2 — idempotencia
    // =====================================================================
    @Test
    @DisplayName("V383/NFR-2: a nyers SQL ujrafuttatasa hiba nelkul lefut es nem valtoztat a seed-en")
    void nfr2_idempotens() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        long liveCountBefore;
        try (Connection connection = openConnection()) {
            UUID companyId = seedCompany(connection, "ID");
            seedBranch(connection, companyId, "ID1", true, null);
            seedGlobalParameter(connection, "HANDLING_FEE_TYPE", "PER_MILLE");
            seedGlobalParameter(connection, "HANDLING_FEE_PER_MILLE", "3.5");
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            liveCountBefore = queryForLong(connection,
                    "SELECT COUNT(*) FROM branch_handling_fee_config WHERE status = 'LIVE'");
        }

        String sql = Files.readString(resolveMigration(V383_FILE_PATTERN),
                java.nio.charset.StandardCharsets.UTF_8);
        try (Connection connection = openConnection();
             java.sql.Statement statement = connection.createStatement()) {
            statement.execute(sql);
            statement.execute(sql);
        }

        try (Connection connection = openConnection()) {
            assertThat(queryForLong(connection,
                    "SELECT COUNT(*) FROM branch_handling_fee_config WHERE status = 'LIVE'"))
                    .as("NFR-2: ujrafuttatas nem duplikal seed-sort")
                    .isEqualTo(liveCountBefore);
        }
    }

    // =====================================================================
    // D7 — VAULT_COUNTERPARTY iroda is kap sort
    // =====================================================================
    @Test
    @DisplayName("V383/D7: VAULT_COUNTERPARTY tipusu aktiv iroda is kap LIVE sort")
    void d7_counterpartyIsKapSort() throws Exception {
        migrateToVersion(previousExistingVersion(V383_FILE_PATTERN));

        UUID counterpartyTypeId;
        UUID companyId;
        try (Connection connection = openConnection()) {
            companyId = seedCompany(connection, "VP");
            execute(connection,
                    "INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)"
                            + " VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'VAULT_COUNTERPARTY',"
                            + " 'Vault counterparty', 'Partner', 100, true, NOW())"
                            + " ON CONFLICT (category, code) DO NOTHING");
            counterpartyTypeId = UUID.fromString(queryForString(connection,
                    "SELECT id FROM dictionary WHERE category = 'BRANCH_TYPE'"
                            + " AND code = 'VAULT_COUNTERPARTY'"));
            seedBranch(connection, companyId, "VP1", true, counterpartyTypeId);
        }

        migrateToLatest();

        try (Connection connection = openConnection()) {
            // A V277 seed 10 counterparty irodaja is kap sort (szandek, D7) — itt CSAK
            // a sajat teszt-cegunk ellenorzott counterparty-irodajat szamoljuk.
            assertThat(queryForLong(connection,
                    "SELECT COUNT(*) FROM branch_handling_fee_config bhfc"
                            + " JOIN branch b ON b.id = bhfc.branch_id"
                            + " WHERE b.branch_type_did = ? AND bhfc.company_id = ?"
                            + " AND bhfc.status = 'LIVE' AND bhfc.is_active",
                    counterpartyTypeId, companyId))
                    .as("D7: a counterparty iroda is kap seed-sort — nem marad fail-closed lyuk")
                    .isEqualTo(1);
        }
    }

    // ============================ ASSERT HELPEREK ============================

    private static void assertLiveRow(Connection connection, UUID branchId,
                                      String expectedMode, String expectedRate) throws Exception {
        assertThat(queryForLong(connection,
                "SELECT COUNT(*) FROM branch_handling_fee_config"
                        + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchId))
                .as("Pontosan 1 aktiv LIVE sor vart: %s", branchId)
                .isEqualTo(1);
        assertThat(queryForString(connection,
                "SELECT fee_mode FROM branch_handling_fee_config"
                        + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchId))
                .as("fee_mode")
                .isEqualTo(expectedMode);
        if (expectedRate != null) {
            assertThat(new java.math.BigDecimal(queryForString(connection,
                    "SELECT per_mille_rate FROM branch_handling_fee_config"
                            + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchId)))
                    .as("per_mille_rate")
                    .isEqualByComparingTo(expectedRate);
        }
    }

    private static long countLiveRows(Connection connection, UUID branchId) throws Exception {
        return queryForLong(connection,
                "SELECT COUNT(*) FROM branch_handling_fee_config"
                        + " WHERE branch_id = ? AND status = 'LIVE' AND is_active", branchId);
    }

    private static boolean tableExists(Connection connection, String tableName) throws Exception {
        return queryForLong(connection,
                "SELECT COUNT(*) FROM information_schema.tables"
                        + " WHERE table_schema = 'public' AND table_name = ?", tableName) > 0;
    }

    private static List<String> tableColumns(Connection connection, String tableName) throws Exception {
        List<String> columns = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT column_name FROM information_schema.columns"
                        + " WHERE table_schema = 'public' AND table_name = ?"
                        + " ORDER BY ordinal_position")) {
            statement.setString(1, tableName);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    columns.add(resultSet.getString(1));
                }
            }
        }
        return columns;
    }

    // ============================ FIXTURE HELPEREK ============================

    private static UUID seedCompany(Connection connection, String suffix) throws Exception {
        UUID companyId = UUID.randomUUID();
        execute(connection,
                "INSERT INTO company (id, code, name, is_active, created_at) VALUES (?, ?, ?, true, NOW())",
                companyId, "FK096" + suffix, "FK-096 migration test company " + suffix);
        return companyId;
    }

    private static UUID seedBranch(Connection connection, UUID companyId, String code,
                                   boolean active, UUID branchTypeDid) throws Exception {
        UUID branchId = UUID.randomUUID();
        execute(connection,
                "INSERT INTO branch (id, code, company_id, name, is_active, branch_type_did)"
                        + " VALUES (?, ?, ?, ?, ?, ?)",
                branchId, code, companyId, "FK-096 test branch " + code, active, branchTypeDid);
        return branchId;
    }

    private static void seedGlobalParameter(Connection connection, String key, String value)
            throws Exception {
        deleteParameter(connection, key);
        execute(connection,
                "INSERT INTO system_parameter (parameter_key, parameter_value, company_id)"
                        + " VALUES (?, ?, NULL)",
                key, value);
    }

    private static void seedCompanyParameter(Connection connection, UUID companyId,
                                             String key, String value) throws Exception {
        execute(connection,
                "DELETE FROM system_parameter WHERE parameter_key = ? AND company_id = ?",
                key, companyId);
        execute(connection,
                "INSERT INTO system_parameter (parameter_key, parameter_value, company_id)"
                        + " VALUES (?, ?, ?)",
                key, value, companyId);
    }

    /**
     * A V46 globalis HANDLING_FEE_* seed-sorainak eltakaritasa, hogy a teszt
     * altal beallitott ertekek legyenek az egyetlenek (D6 precedencia tisztan tesztelheto).
     */
    private static void deleteHandlingFeeParameters(Connection connection) throws Exception {
        execute(connection,
                "DELETE FROM system_parameter WHERE parameter_key IN"
                        + " ('HANDLING_FEE_TYPE','HANDLING_FEE_PER_MILLE','HANDLING_FEE_PER_MILLE_MAX')");
    }

    private static void deleteParameter(Connection connection, String key) throws Exception {
        execute(connection, "DELETE FROM system_parameter WHERE parameter_key = ?", key);
    }

    private static void insertConfig(Connection connection, UUID companyId, UUID branchId,
                                     String status, String feeMode) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "INSERT INTO branch_handling_fee_config"
                        + " (company_id, branch_id, fee_mode, status, is_active, valid_from)"
                        + " VALUES (?, ?, ?, ?, true, CURRENT_DATE)")) {
            statement.setObject(1, companyId);
            statement.setObject(2, branchId);
            statement.setString(3, feeMode);
            statement.setString(4, status);
            statement.executeUpdate();
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
     * eltorik, ha a szamozasban lyuk van.
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

    private void migrateToLatest() {
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

    private static void bind(PreparedStatement statement, Object... parameters) throws SQLException {
        for (int i = 0; i < parameters.length; i++) {
            statement.setObject(i + 1, parameters[i]);
        }
    }
}
