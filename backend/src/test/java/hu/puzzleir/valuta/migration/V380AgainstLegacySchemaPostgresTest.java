package hu.puzzleir.valuta.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * V380 regresszio: a migracio a CSONKA ELES SEMAN is lefut.
 *
 * <p><b>Miert letezik ez a teszt.</b> 2026-08-12-en az FK-080 release eles deployja
 * elbukott es a rendszer 502-t adott: a `denomination` tablan az eles Hetzner DB-n
 * CSAK `is_active` oszlop van, a V380 viszont statikusan `active`-ra hivatkozott
 * (`ERROR: column d.active does not exist`, SQLSTATE 42703). A Flyway-hiba a Spring
 * context indulasat akasztotta meg, a backend nem indult el.
 *
 * <p><b>Miert nem fogta meg a meglevo teszt.</b> A `ForbiddenCoinDeactivationFk080MigrationPostgresTest`
 * a teljes migracio-lancot FRISS seman futtatja, ahol a V3 DDL `active`-ja ES a V3_7/V109
 * guard `is_active`-ja is letezik. A csonka eles sema egyetlen tesztben sem volt
 * reprodukalva — ez a lefedettseg valodi hianya volt.
 *
 * <p>Ez a teszt a V380 elott eldobja az `active` oszlopot (es a rea epulo triggert),
 * majd futtatja a V380-at. A javitas elotti statikus SQL-lel 42703-mal bukik.
 *
 * <p>Runbook: `vault/operations/v380-eles-oszlop-agnosztikus-hotfix-2026-08-12.md`.
 */
@Testcontainers
class V380AgainstLegacySchemaPostgresTest {

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

    @Test
    @DisplayName("V380: lefut olyan semaval is, ahol a denomination tablan CSAK is_active van (eles Hetzner allapot)")
    void v380SucceedsWhenOnlyIsActiveColumnExists() throws Exception {
        // Arrange: migracio a V379-ig (a V380 ELOTT allunk meg).
        migrateToVersion(379);

        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            // Az eles sema reprodukalasa: a szinkron-trigger es az `active` oszlop eldobasa.
            st.execute("DROP TRIGGER IF EXISTS trg_sync_active_columns ON denomination");
            st.execute("ALTER TABLE denomination DROP COLUMN IF EXISTS active");

            assertThat(columnExists(st, "denomination", "active"))
                    .as("Az arrange utan a csonka eles semat utanozzuk: nincs `active` oszlop")
                    .isFalse();
            assertThat(columnExists(st, "denomination", "is_active"))
                    .as("`is_active` viszont van — pontosan ez az eles allapot")
                    .isTrue();
        }

        // Act: a V380 lefuttatasa a csonka seman. A javitas elott ez 42703-mal dobott.
        migrateToLatest();

        // Assert: a migracio sikeres (a Flyway history-ban success), a sema hasznalhato.
        try (Connection connection = openConnection(); Statement st = connection.createStatement()) {
            try (ResultSet rs = st.executeQuery(
                    "SELECT success FROM flyway_schema_history WHERE version = '380'")) {
                assertThat(rs.next()).as("A V380 bekerult a flyway_schema_history-ba").isTrue();
                assertThat(rs.getBoolean("success"))
                        .as("A V380 SIKERESEN futott le a csonka eles seman")
                        .isTrue();
            }

            // A tiltott COIN sorokra a meglevo aktiv-oszlop false lett (nem maradt aktiv szemet).
            try (ResultSet rs = st.executeQuery(
                    "SELECT count(*) FROM denomination d "
                            + "WHERE d.is_active = true AND d.denomination_type = 'COIN' "
                            + "AND NOT EXISTS (SELECT 1 FROM denomination_allowed da "
                            + "WHERE da.company_id = d.company_id AND da.currency_id = d.currency_id "
                            + "AND da.face_value = d.face_value AND da.denomination_type = 'COIN' "
                            + "AND da.is_active = true)")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getLong(1))
                        .as("A csonka seman is minden tiltott COIN sor inaktivalva lett")
                        .isZero();
            }
        }
    }

    private static boolean columnExists(Statement st, String table, String column) throws Exception {
        try (ResultSet rs = st.executeQuery(
                "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                        + "WHERE table_schema = 'public' AND table_name = '" + table + "' "
                        + "AND column_name = '" + column + "')")) {
            rs.next();
            return rs.getBoolean(1);
        }
    }

    private static Connection openConnection() throws Exception {
        return DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
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
}
