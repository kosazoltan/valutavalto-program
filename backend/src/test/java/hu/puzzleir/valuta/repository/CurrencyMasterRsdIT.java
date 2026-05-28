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
 * V274 (FK-006 follow-up) — RSD (Szerb dinár) hiány javítás migráció szanity-teszt.
 *
 * <p>Tünet (Kasza Helga visszajelzés, v2.27.35 telepítés után): az RSD MIND A
 * HÁROM törzs-vezérelt felületről hiányzik (Készlet-snapshot, Országos készlet
 * kártyák, Aktuális árfolyamok), pedig a V271 spec kérte az aktív halmazba
 * (display_order=16).</p>
 *
 * <p>Gyökér ok: a V271 az aktív halmazt UPDATE-tel állítja be — ami csak a
 * LÉTEZŐ sorokon hat. Ha az RSD valamilyen okból (admin-művelet, korábbi
 * env-eltérés) inaktívra állt vagy hiányzott, V271 nem hozta vissza aktívra.</p>
 *
 * <p><b>Tesztkörnyezet-megjegyzés:</b> a backend integration-test profil H2
 * in-memory DB-vel és letiltott Flyway-jel fut (lásd
 * {@code application-test.properties}: {@code spring.flyway.enabled=false},
 * {@code ddl-auto=create-drop}). A V271 / V274 migrációk Postgres-specifikus
 * {@code ON CONFLICT} szintaxist használnak, amit H2 nem támogat — ezért
 * SpringBootTest-alapú adat-szintű ellenőrzés nem kivitelezhető. Ehelyett a
 * migrációfájl JELENLÉTÉT és KULCS-TARTALMÁT ellenőrizzük; a valós DB-szintű
 * érvényesülést Flyway alkalmazza prod-deploy-kor.</p>
 */
class CurrencyMasterRsdIT {

    private static final Path V274 = Path.of(
            "src/main/resources/db/migration/V274__fix_rsd_currency_active.sql");

    @Test
    @DisplayName("V274 migráció jelen van a Flyway útvonalon")
    void migrationFileExists() {
        assertThat(Files.exists(V274))
                .as("V274 migrációs fájlnak léteznie kell: " + V274)
                .isTrue();
    }

    @Test
    @DisplayName("V274 RSD-t aktívvá teszi display_order=16-tal (idempotens upsert)")
    void migrationContainsRsdActiveUpsert() throws IOException {
        String sql = Files.readString(V274, StandardCharsets.UTF_8);

        assertThat(sql)
                .as("Az upsertnek az RSD-re kell vonatkoznia")
                .contains("'RSD'");

        assertThat(sql)
                .as("Idempotens INSERT ... ON CONFLICT mintát követ (mint a V271/V272)")
                .containsIgnoringCase("INSERT INTO currency")
                .containsIgnoringCase("ON CONFLICT (code) DO UPDATE");

        assertThat(sql)
                .as("Az RSD-t aktívvá teszi (is_active = true)")
                .containsPattern(Pattern.compile("is_active\\s*=\\s*true", Pattern.CASE_INSENSITIVE));

        assertThat(sql)
                .as("Az RSD display_order = 16 (V271 sorrend: ...RON, RSD, RUB...)")
                .containsPattern(Pattern.compile("display_order\\s*=\\s*16", Pattern.CASE_INSENSITIVE));
    }
}
