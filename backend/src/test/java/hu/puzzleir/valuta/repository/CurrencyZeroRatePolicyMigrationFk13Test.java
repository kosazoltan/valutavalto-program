package hu.puzzleir.valuta.repository;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK13 (FR-11) — V393 migráció sanity-teszt: két nullable boolean oszlop a {@code currency} táblán +
 * a {@code currency_audit_log.action} CHECK bővítése {@code ZERO_RATE_POLICY}-vel.
 *
 * <p>A {@link CurrencyMigrationFk04IT} mintáját követi (fájl-jelenlét + kulcs-tartalom), mert a backend
 * tesztprofil H2 + kikapcsolt Flyway ({@code application-test.properties}), és a V393 Postgres-specifikus
 * ({@code DO $$}, {@code pg_constraint}). <b>Névkonvenció:</b> {@code *Test} utótag, hogy a surefire
 * (default include-minták) ténylegesen futtassa — a {@code *IT} utótagú társait a {@code mvn test} nem futtatja.</p>
 *
 * <p>Megjegyzés a RED-körhöz: a migráció a jóváhagyott scaffolding része, ezért ez a teszt már a RED
 * fázisban zöld — a szerződést rögzíti, nem a hiányzó üzleti logikát.</p>
 */
class CurrencyZeroRatePolicyMigrationFk13Test {

    private static final Path V393 = Path.of(
            "src/main/resources/db/migration/V393__fk13_currency_zero_rate_policy.sql");

    @Test
    @DisplayName("V393 migráció jelen van a Flyway útvonalon")
    void migrationFileExists() {
        assertThat(Files.exists(V393)).as("V393 migrációs fájlnak léteznie kell: " + V393).isTrue();
    }

    @Test
    @DisplayName("FR-11: két NULLABLE boolean oszlop, idempotens ADD COLUMN IF NOT EXISTS (nincs NOT NULL)")
    void v393AddsTwoNullableBooleanColumns() throws IOException {
        String sql = Files.readString(V393, StandardCharsets.UTF_8);

        assertThat(sql).containsPattern(Pattern.compile(
                "ALTER\\s+TABLE\\s+currency\\s+ADD\\s+COLUMN\\s+IF\\s+NOT\\s+EXISTS\\s+buy_zero_allowed\\s+BOOLEAN",
                Pattern.CASE_INSENSITIVE));
        assertThat(sql).containsPattern(Pattern.compile(
                "ALTER\\s+TABLE\\s+currency\\s+ADD\\s+COLUMN\\s+IF\\s+NOT\\s+EXISTS\\s+sell_zero_allowed\\s+BOOLEAN",
                Pattern.CASE_INSENSITIVE));
        assertThat(sql)
                .as("nullable oszlop: a 'nem beállított = tiltott' szemantika + flyway-content-audit ADD-NOT-NULL szabály")
                .doesNotContainPattern(Pattern.compile("zero_allowed\\s+BOOLEAN\\s+NOT\\s+NULL", Pattern.CASE_INSENSITIVE));
    }

    @Test
    @DisplayName("FR-11: currency_audit_log.action CHECK bővül ZERO_RATE_POLICY-vel, a régi 4 action megmarad, pg_constraint-alapú feloldással")
    void v393ExtendsAuditActionCheck() throws IOException {
        String sql = Files.readString(V393, StandardCharsets.UTF_8);

        assertThat(sql).contains("currency_audit_log");
        assertThat(sql).contains("'ZERO_RATE_POLICY'");
        assertThat(sql)
                .as("a meglévő V238 action-készlet nem szűkülhet")
                .contains("'CREATE'").contains("'ACTIVATE'").contains("'DEACTIVATE'").contains("'UPDATE'");
        assertThat(sql)
                .as("a V238 névtelen CHECK-jét a pg_constraint alapján kell feloldani (a generált név a repóból nem ismert)")
                .contains("pg_constraint");
        assertThat(sql)
                .as("VARCHAR(20) korlát: az action-név legfeljebb 20 karakter")
                .satisfies(s -> assertThat("ZERO_RATE_POLICY".length()).isLessThanOrEqualTo(20));
    }
}
