package hu.puzzleir.valuta.migration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-099 E-sorozat (E1–E7) — a V384 ráta-history migráció SZERKEZETI szerződése.
 * Docker nélkül fut (a valós DB-viselkedést a
 * {@link TransactionLevyRateHistoryV384PostgresTest} Testcontainers-teszt fedi).
 *
 * <p>Szerződés: pontosan egy {@code V384__fk099_transaction_levy_rate_history.sql};
 * kilenc oszlop; UNIQUE (company_id, effective_from); index (company_id,
 * effective_from DESC); immutable BEFORE UPDATE OR DELETE trigger; NINCS
 * {@code DELETE FROM} utasítás; insert-if-missing seed (2013-01-01, 0.450,
 * 20000.00); a {@code transaction} tábla érintetlen.</p>
 */
class TransactionLevyRateHistoryV384MigrationSqlTest {

    /** Surefire working dir = backend modulgyökér. */
    private static final Path MIGRATION_DIR =
            Path.of("src", "main", "resources", "db", "migration");

    private static final Pattern V384_FILE_PATTERN =
            Pattern.compile("^V(\\d+)__fk099_transaction_levy_rate_history.*\\.sql$");

    private static Path resolveMigration() throws IOException {
        try (Stream<Path> files = Files.list(MIGRATION_DIR)) {
            List<Path> matches = files
                    .filter(p -> V384_FILE_PATTERN.matcher(p.getFileName().toString()).matches())
                    .toList();
            assertThat(matches)
                    .as("E1: pontosan egy V<n>__fk099_transaction_levy_rate_history.sql migráció "
                            + "kell a db/migration alatt (RED-fázisban még hiányzik)")
                    .hasSize(1);
            return matches.get(0);
        }
    }

    private static String readSql() throws IOException {
        return Files.readString(resolveMigration(), StandardCharsets.UTF_8);
    }

    /** SQL-kommentek levágása, hogy a komment-szöveg ne zavarja a DELETE FROM ellenőrzést. */
    private static String stripComments(String sql) {
        return sql.replaceAll("--[^\n]*", "");
    }

    @Test
    @DisplayName("E1: pontosan egy migrációs fájl létezik, verziója 384")
    void e1_exactlyOneFileWithVersion384() throws IOException {
        Matcher matcher = V384_FILE_PATTERN
                .matcher(resolveMigration().getFileName().toString());
        assertThat(matcher.matches()).isTrue();
        assertThat(matcher.group(1)).isEqualTo("384");
    }

    @Test
    @DisplayName("E2: mind a kilenc oszlop deklarált, a flag BOOLEAN NOT NULL DEFAULT TRUE")
    void e2_allNineColumnsDeclared() throws IOException {
        String sql = readSql();

        assertThat(sql)
                .contains("id")
                .contains("company_id")
                .contains("effective_from")
                .contains("base_rate_percent")
                .contains("base_rate_cap_huf")
                .contains("supplement_rate_percent")
                .contains("supplement_rate_cap_huf")
                .contains("conversion_single_side_flag")
                .contains("created_by")
                .contains("created_at");
        assertThat(sql)
                .as("D17/DDL: conversion_single_side_flag BOOLEAN NOT NULL DEFAULT TRUE")
                .containsPattern(Pattern.compile(
                        "(?is)conversion_single_side_flag\\s+BOOLEAN\\s+NOT\\s+NULL\\s+DEFAULT\\s+TRUE"));
    }

    @Test
    @DisplayName("E3: UNIQUE (company_id, effective_from) és index (company_id, effective_from DESC)")
    void e3_uniqueAndIndex() throws IOException {
        String sql = readSql();

        assertThat(sql)
                .as("append-only egyedi kulcs cégenkénti hatálybalépésre")
                .containsPattern(Pattern.compile(
                        "(?is)UNIQUE\\s*\\(\\s*company_id\\s*,\\s*effective_from\\s*\\)"));
        assertThat(sql)
                .as("NFR-5: index (company_id, effective_from DESC)")
                .containsPattern(Pattern.compile(
                        "(?is)CREATE\\s+INDEX.*ON\\s+transaction_levy_rate_history"
                                + "\\s*\\(\\s*company_id\\s*,\\s*effective_from\\s+DESC\\s*\\)"));
    }

    @Test
    @DisplayName("E4: immutable BEFORE UPDATE OR DELETE … FOR EACH ROW trigger")
    void e4_immutableTrigger() throws IOException {
        String sql = readSql();

        assertThat(sql)
                .containsPattern(Pattern.compile(
                        "(?is)BEFORE\\s+UPDATE\\s+OR\\s+DELETE\\s+ON\\s+transaction_levy_rate_history"));
        assertThat(sql)
                .as("sor-szintű trigger (V238 minta)")
                .contains("FOR EACH ROW");
        assertThat(sql)
                .containsPattern(Pattern.compile("(?is)CREATE\\s+TRIGGER\\s+\\w+immutable\\w*"));
    }

    @Test
    @DisplayName("E5: NINCS DELETE FROM utasítás (a trigger OR DELETE kulcsszava megengedett)")
    void e5_noDeleteFromStatement() throws IOException {
        String sql = stripComments(readSql());

        assertThat(Pattern.compile("(?is)DELETE\\s+FROM").matcher(sql).results().count())
                .as("E5: az append-only migráció semmilyen DELETE FROM-ot nem tartalmazhat")
                .isZero();
    }

    @Test
    @DisplayName("E6: a seed insert-if-missing (WHERE NOT EXISTS), értékei 2013-01-01 / 0.450 / 20000.00")
    void e6_seedIsInsertIfMissing() throws IOException {
        String sql = readSql();

        assertThat(sql).contains("INSERT INTO transaction_levy_rate_history");
        assertThat(sql)
                .as("insert-if-missing (V383 minta)")
                .containsPattern(Pattern.compile("(?is)WHERE\\s+NOT\\s+EXISTS"));
        assertThat(sql)
                .contains("DATE '2013-01-01'")
                .contains("0.450")
                .contains("20000.00");
    }

    @Test
    @DisplayName("E7: a transaction tábla érintetlen — nincs ALTER TABLE transaction")
    void e7_transactionTableUntouched() throws IOException {
        String sql = stripComments(readSql());

        assertThat(Pattern.compile("(?is)ALTER\\s+TABLE\\s+transaction\\b").matcher(sql).find())
                .as("E7: a `transaction` táblához egyetlen ALTER sem nyúlhat")
                .isFalse();
    }
}
