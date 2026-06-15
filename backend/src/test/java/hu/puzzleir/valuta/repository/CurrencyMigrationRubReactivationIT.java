package hu.puzzleir.valuta.repository;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RUB visszaállítás (2026-06-15) — V327 reaktiválás + V328 címlet-backfill + V329
 * currency_stock backfill sanity-teszt.
 *
 * <p>Háttér: a 2026-06-12-i V319 a RUB-ot {@code is_active=false}-ra állította (téves
 * user-infó). A RUB mégis forgalmazott — a V327 visszaaktiválja, a V328 pótolja a
 * címlet-katalógusát (a V320 csak aktív valutákra seedelt, így a RUB kimaradt), a V329
 * pedig a hiányzó értéktári {@code currency_stock} sorokat (a V323 szintén csak aktív
 * valutákra futott).</p>
 *
 * <p><b>Tesztkörnyezet-megjegyzés (a CurrencyMigrationFk04IT mintája szerint):</b> a
 * backend integration-test profil H2 in-memory DB-vel és letiltott Flyway-jel fut
 * ({@code application-test.properties}: {@code spring.flyway.enabled=false}). A migrációk
 * Postgres-specifikus szintaxist használnak ({@code DO $$} blokk, {@code GET DIAGNOSTICS}),
 * ezért a migrációfájlok JELENLÉTÉT és KULCS-TARTALMÁT ellenőrizzük; a valós DB-szintű
 * érvényesülést a Flyway alkalmazza prod-deploy-kor (Hetzner Gate A + Neon Gate B).</p>
 */
class CurrencyMigrationRubReactivationIT {

    private static final Path V327 = Path.of(
            "src/main/resources/db/migration/V327__reactivate_rub_currency.sql");
    private static final Path V328 = Path.of(
            "src/main/resources/db/migration/V328__rub_denomination_catalog_backfill.sql");
    private static final Path V329 = Path.of(
            "src/main/resources/db/migration/V329__rub_currency_stock_vault_rows.sql");

    @Test
    @DisplayName("V327/V328/V329 RUB-visszaállító migrációk jelen vannak a Flyway útvonalon")
    void migrationFilesExist() {
        assertThat(Files.exists(V327)).as("V327 (reaktiválás) létezzen: " + V327).isTrue();
        assertThat(Files.exists(V328)).as("V328 (címlet-backfill) létezzen: " + V328).isTrue();
        assertThat(Files.exists(V329)).as("V329 (currency_stock) létezzen: " + V329).isTrue();
    }

    @Test
    @DisplayName("V327: RUB is_active=true, idempotens (WHERE is_active=false guard)")
    void v327ReactivatesRubIdempotently() throws IOException {
        String sql = Files.readString(V327, StandardCharsets.UTF_8);
        assertThat(sql)
                .as("a RUB-ot aktiválja")
                .containsPattern("(?is)UPDATE\\s+currency\\s+SET\\s+is_active\\s*=\\s*true")
                .contains("code = 'RUB'");
        assertThat(sql)
                .as("idempotens: csak inaktív sort érint")
                .contains("is_active = false");
    }

    @Test
    @DisplayName("V328: RUB címlet-katalógus (bankjegy 5000–50, érme 10–0.10), idempotens NOT EXISTS")
    void v328BackfillsRubDenominations() throws IOException {
        String sql = Files.readString(V328, StandardCharsets.UTF_8);
        assertThat(sql)
                .as("a RUB valutára szűr, csak aktív állapotban")
                .contains("c.code = 'RUB'")
                .contains("c.is_active = true");
        assertThat(sql)
                .as("a kanonikus RUB bankjegy- és érme-címletek (Bank of Russia)")
                .contains("5000").contains("50").contains("0.10");
        assertThat(sql)
                .as("idempotens: (branch, currency, face_value) NOT EXISTS guard")
                .containsIgnoringCase("NOT EXISTS")
                .contains("denomination");
    }

    @Test
    @DisplayName("V329: RUB currency_stock VAULT sorok (qty=0, wac=0), idempotens NOT EXISTS")
    void v329BackfillsRubCurrencyStock() throws IOException {
        String sql = Files.readString(V329, StandardCharsets.UTF_8);
        assertThat(sql)
                .as("a RUB-ra szűr aktív vault_territory-kra")
                .contains("c.code = 'RUB'")
                .contains("vault_territory");
        assertThat(sql)
                .as("VAULT entity_type, currency_stock tábla")
                .contains("currency_stock")
                .contains("'VAULT'");
        assertThat(sql)
                .as("idempotens: NOT EXISTS guard")
                .containsIgnoringCase("NOT EXISTS");
    }
}
