# B.8 — Production-first vs. TDD reconciliation mandate

**Hatály:** always, P1
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.8 szakasz

## Az ütközés

A "production-first" elv (CLAUDE.md C.13) tiltja a divergens lokál seed-et: minden adat csak Flyway-migrációval kerülhet a sémába. A TDD elv viszont tesztkörnyezet-fixture-öket igényel.

Ezek ütközhetnek, ha egy teszt új tábla / oszlop / adatszet kell.

## Feloldás (4 szabály)

1. **Teszt-fixture-ök NEM seed-adatok.** A `@TestConfiguration`-ban definiált fixture csak a test-runner JVM-jében létezik, soha NEM kerül `flyway/migration/`-be.
2. **Reproduction-teszt psql-INSERT-tel** csak a fejlesztő lokál Postgres-én, utána ROLLBACK / DROP kötelező. Soha NEM a Hetzner / Scaleway DB-re.
3. **Flyway migráció a séma forrása.** Ha új tábla / oszlop kell tesztkörnyezetnek IS, az migration. A migration code-review P0 lehet, mert production séma változás.
4. **Lokál Postgres CSAK Hetzner-replikából feltöltve** (anonimizált dump), soha NEM kézi seed.

## Implementációs hivatkozás

```java
// JÓ — TestConfiguration fixture
@TestConfiguration
public class TransactionTestConfig {
    @Bean
    public Transaction sampleTransaction() {
        return Transaction.builder()
            .amount(BigDecimal.valueOf(100))
            .currency("EUR")
            .build();
    }
}

// ROSSZ — migration-szintű seed
// V232__seed_test_transactions.sql  ← TILOS, ez prod-séma változás
INSERT INTO transaction (...) VALUES (...);
```

## Hetzner-replika dump (kézi process)

```bash
# Fejlesztő gépen, NEM CI-ben
ssh deploy@hetzner "pg_dump --schema-only valutavalto" > schema.sql
ssh deploy@hetzner "pg_dump --data-only --table=branch --table=worker valutavalto" | \
  sed 's/\\(real-name-pattern\\)/anon-\\1/g' > anon-data.sql

# Lokál Postgres-be
psql valutavalto_local < schema.sql
psql valutavalto_local < anon-data.sql
```

Soha NEM commitolt a `anon-data.sql` (gitignore).
