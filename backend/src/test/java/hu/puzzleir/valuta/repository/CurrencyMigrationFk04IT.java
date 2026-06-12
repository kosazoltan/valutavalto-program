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
 * FK04 (FR-5, FR-6) — V317 kanonikus display_order + V318 UNIQUE constraint sanity-teszt.
 *
 * <p>Tünet: a V298 az EUA-t display_order=17-tel seedelte, ami a V271-es RUB=17-tel
 * duplikál. Továbbá a V3-as inaktív maradványok (BGN=12, DKK=17, HRK=18) is ütköznek
 * a V271 aktív értékeivel (MXN=12, RUB=17, THB=18).</p>
 *
 * <p><b>Tesztkörnyezet-megjegyzés (a CurrencyMasterRsdIT mintája szerint):</b> a backend
 * integration-test profil H2 in-memory DB-vel és letiltott Flyway-jel fut
 * ({@code application-test.properties}: {@code spring.flyway.enabled=false}).
 * A V317/V318 Postgres-specifikus szintaxist használ (window function FROM-mal,
 * DO $$ blokk), ezért a migrációfájl JELENLÉTÉT és KULCS-TARTALMÁT ellenőrizzük;
 * a valós DB-szintű érvényesülést a Flyway alkalmazza prod-deploy-kor.</p>
 */
class CurrencyMigrationFk04IT {

    private static final Path V317 = Path.of(
            "src/main/resources/db/migration/V317__fk04_canonical_currency_display_order.sql");
    private static final Path V318 = Path.of(
            "src/main/resources/db/migration/V318__fk04_unique_currency_display_order.sql");

    @Test
    @DisplayName("V317 + V318 migráció jelen van a Flyway útvonalon")
    void migrationFilesExist() {
        assertThat(Files.exists(V317)).as("V317 migrációs fájlnak léteznie kell: " + V317).isTrue();
        assertThat(Files.exists(V318)).as("V318 migrációs fájlnak léteznie kell: " + V318).isTrue();
    }

    @Test
    @DisplayName("FR-5: V317 kanonikus sorrend — RUB=14, EUA=15, TRY=16 (duplikáció megszűnik)")
    void v317ContainsCanonicalOrder() throws IOException {
        String sql = Files.readString(V317, StandardCharsets.UTF_8);

        assertThat(sql)
                .as("EUA a RUB(14) és TRY(16) közé kerül (display_order=15)")
                .contains("('RUB', 14)")
                .contains("('EUA', 15)")
                .contains("('TRY', 16)");

        assertThat(sql)
                .as("A bázisdeviza HUF=0 marad, a kanonikus lista EUR=1-gyel indul, NZD=22-vel zárul")
                .contains("('HUF', 0)")
                .contains("('EUR', 1)")
                .contains("('NZD', 22)");

        assertThat(sql)
                .as("A nem-kanonikus (inaktív maradvány) valuták a 100+ tartományba kerülnek, " +
                    "hogy a V318 UNIQUE constraint felvehetö legyen")
                .containsPattern(Pattern.compile("100\\s*\\+\\s*sub\\.seq"));
    }

    @Test
    @DisplayName("FR-6: V318 UNIQUE constraint a display_order-re (globális tábla — TBD-2)")
    void v318ContainsUniqueConstraint() throws IOException {
        String sql = Files.readString(V318, StandardCharsets.UTF_8);

        assertThat(sql)
                .as("UNIQUE constraint a display_order oszlopra (a currency tábla globális, " +
                    "nincs company_id — ezért NEM (company_id, display_order) páros)")
                .contains("uq_currency_display_order")
                .containsPattern(Pattern.compile("UNIQUE\\s*\\(display_order\\)", Pattern.CASE_INSENSITIVE));

        assertThat(sql)
                .as("Idempotens (pg_constraint létezés-ellenőrzés)")
                .contains("pg_constraint");
    }
}
