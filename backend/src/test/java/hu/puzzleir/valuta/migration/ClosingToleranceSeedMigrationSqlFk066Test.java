package hu.puzzleir.valuta.migration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-066 FR-4 — a pénznemenkénti zárás-tolerancia seed-migráció SZERKEZETI szerződése
 * (Docker nélkül futtatható; a valós DB-viselkedést a
 * {@link ClosingToleranceSeedFk066MigrationTest} Testcontainers-teszt fedi CI-ben).
 *
 * <p>SZERZŐDÉS (FK-066 Fázis 1 korrekció + GREEN-fázis seed-döntés, user-jóváhagyással
 * 2026-07-27: 3 soros seed — a korábbi „csak HUF” pin dokumentált spec-változásként
 * bővült HUF+EUR+USD-re):
 * <ul>
 *   <li>Létezik seed-migráció {@code V<n>__*closing_tolerance*.sql} néven a
 *       {@code db/migration} alatt (a verziószám a merge pillanatában szabad szám,
 *       nem hardkódolt — a teszt mintára keres).</li>
 *   <li>A seed GLOBÁLIS sorokat szúr be insert-if-missing mintával ({@code WHERE NOT
 *       EXISTS}, V307-minta INSERT-ága): {@code CLOSING_TOLERANCE_HUF='5'},
 *       {@code CLOSING_TOLERANCE_EUR='1'}, {@code CLOSING_TOLERANCE_USD='1'}.</li>
 *   <li>SEED-DÖNTÉS: a V307-mintától eltérően NINCS update-if-different ág —
 *       üzemeltető által testre szabott meglévő értéket redeploy nem írhat felül.
 *       Ezért a fájl nem tartalmazhat {@code UPDATE system_parameter} utasítást.</li>
 *   <li>Más pénznemre nincs seed: azokra a kód-szintű fallback (nem-HUF: 0) érvényes,
 *       explicit sort az üzemeltető vihet fel.</li>
 * </ul>
 */
class ClosingToleranceSeedMigrationSqlFk066Test {

    /** Surefire working dir = backend modulgyökér. */
    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");

    private static final Pattern SEED_FILE_PATTERN =
            Pattern.compile("(?i)^V\\d+__.*closing_tolerance.*\\.sql$");

    private static Path resolveSeedMigration() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> SEED_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("FK-066 FR-4: pontosan egy V<n>__*closing_tolerance*.sql seed-migráció "
                            + "kell a db/migration alatt (RED-fázisban még hiányzik)")
                    .hasSize(1);
            return matches.get(0);
        }
    }

    @Test
    @DisplayName("FK-066 FR-4: a seed-migráció létezik, HUF=5/EUR=1/USD=1 sort seedel, mindhármat insert-if-missing mintával")
    void seedMigrationExistsWithInsertIfMissing() throws IOException {
        String sql = Files.readString(resolveSeedMigration(), StandardCharsets.UTF_8);

        assertThat(sql).contains("CLOSING_TOLERANCE_HUF").contains("'5'");
        assertThat(sql).contains("CLOSING_TOLERANCE_EUR");
        assertThat(sql).contains("CLOSING_TOLERANCE_USD");
        assertThat(sql).contains("'1'");
        long insertCount = Pattern.compile("(?is)INSERT\\s+INTO\\s+system_parameter")
                .matcher(sql).results().count();
        long notExistsCount = Pattern.compile("(?is)WHERE\\s+NOT\\s+EXISTS")
                .matcher(sql).results().count();
        assertThat(insertCount).as("3 seed-sor = 3 INSERT").isEqualTo(3);
        assertThat(notExistsCount)
                .as("insert-if-missing: MINDEN INSERT-hez WHERE NOT EXISTS (V307-minta INSERT-ága)")
                .isEqualTo(3);
    }

    @Test
    @DisplayName("FK-066 Codex M2: mindhárom NOT EXISTS-őr a GLOBÁLIS sorra szűkít (company_id IS NULL, V348-minta)")
    void notExistsGuardsTargetGlobalScope() throws IOException {
        // Enélkül egy meglévő CÉGES override elnyomná a globális seedet (M2 finding).
        String sql = Files.readString(resolveSeedMigration(), StandardCharsets.UTF_8);

        long scopedGuardCount = Pattern.compile(
                        "(?is)parameter_key\\s*=\\s*'CLOSING_TOLERANCE_\\w+'\\s+AND\\s+company_id\\s+IS\\s+NULL")
                .matcher(sql).results().count();
        assertThat(scopedGuardCount)
                .as("mindhárom seed-sor őrfeltétele: parameter_key = '…' AND company_id IS NULL")
                .isEqualTo(3);
    }

    @Test
    @DisplayName("FK-066 SEED-DÖNTÉS: nincs UPDATE-ág — meglévő testre szabott értéket a redeploy nem írhat felül")
    void seedMigrationHasNoUpdateBranch() throws IOException {
        String sql = Files.readString(resolveSeedMigration(), StandardCharsets.UTF_8);

        assertThat(sql)
                .as("A V307-mintától szándékosan eltérünk: update-if-different ág TILOS")
                .doesNotContainPattern(Pattern.compile("(?is)UPDATE\\s+system_parameter"));
    }

    @Test
    @DisplayName("FK-066: pontosan a HUF/EUR/USD tolerancia seedelt — más CLOSING_TOLERANCE_ kulcs nem szerepel a seedben")
    void seedsExactlyHufEurUsdRows() throws IOException {
        // GREEN-fázis seed-döntés (user-jóváhagyással): HUF=5, EUR=1, USD=1. Más
        // pénznem toleranciája kód-szintű fallback (0), nem seed — explicit sort
        // az üzemeltető visz fel, ha kell.
        String sql = Files.readString(resolveSeedMigration(), StandardCharsets.UTF_8);

        assertThat(sql.replace("CLOSING_TOLERANCE_HUF", "")
                .replace("CLOSING_TOLERANCE_EUR", "")
                .replace("CLOSING_TOLERANCE_USD", ""))
                .as("A seed kizárólag a HUF/EUR/USD tolerancia-kulcsokat szúrhatja be")
                .doesNotContain("CLOSING_TOLERANCE_");
    }
}
