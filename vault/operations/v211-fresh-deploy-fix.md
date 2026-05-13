---
title: V211 fresh-deploy fix runbook
date: 2026-05-13
tags: [operations, flyway, migration, hetzner]
status: active
---

# V211 fresh-deploy fix runbook (PR #574)

## Háttér

A `V211__cashier_custom_rate_tracking.sql` migration eredetileg HIBÁS oszlopneveket
használt:

```sql
INSERT INTO system_parameter (key, value, category, description)
VALUES ('CASHIER_CUSTOM_RATE_MIN_AMOUNT', '400000', ...)
ON CONFLICT (key) DO NOTHING;
```

A `system_parameter` tábla valódi oszlopnevei `parameter_key` / `parameter_value`
(a V135 óta). 2026-05-13 11:04 UTC ddb28551 deploy crash-elt:

```
ERROR: column "key" of relation "system_parameter" does not exist
```

## Korábbi (részleges) javítás

PR #562 cd1f9ee4 nem editálta V211-et (F15 lint blokkolta), helyette:
- `V213__fix_V211_cashier_custom_rate_params.sql` (új migration, helyes
  oszlopnevekkel + ON CONFLICT DO NOTHING)
- Production-on V211 manuálisan `flyway repair`-elve (V211 marked success=t,
  checksum=1782720344, de a fájl on-disk MARADT a hibás SQL-lel)

## Probléma: fresh-deploy time bomb

Friss DB-deploy (Scaleway bootstrap, dev-recreate, új Hetzner kiépítés) esetén
V211 SQL futna újra → `column "key" does not exist` → backend crash. Production
csak azért működik, mert ott V211 már success-szel meg van pipálva.

## Javítás (PR #574)

1. **V211 SQL fájl javítása** helyes oszlopnevekre:
   - `key` → `parameter_key`, `value` → `parameter_value`
   - Hozzáadott teljes oszloplista (id, parameter_type, is_active, updated_at,
     updated_by) — V213-mal egyezően
   - `ON CONFLICT (parameter_key) DO NOTHING` (idempotens — V213 utáni re-run safe)

2. **F15 lint exception**: `backend/src/main/resources/db/migration/.flyway-lint-allowed-modifications`
   whitelist mechanizmus a V211 dokumentált editálásához.

## Production deploy procedure (KÖTELEZŐ a következő merge-re)

A V211 fájl tartalma megváltozott → új checksum. Production-on viszont V211 már
`success=t` régi checksummal. Flyway alapból ezt validate hibaként blokkolja.

**Hetzner deploy ELŐTT** (egyszer):

```bash
# 1. SSH Hetzner-re
ssh -i ~/.ssh/hetzner_ed25519 root@95.216.191.162

# 2. Backend systemd unit env-be FLYWAY_REPAIR_ON_MIGRATE=true beállítás
sudo systemctl edit valuta-backend.service
# Hozzáadás a [Service] szekcióhoz:
#   Environment="FLYWAY_REPAIR_ON_MIGRATE=true"
sudo systemctl daemon-reload

# 3. Deploy elindítása (vagy automata GitHub deploy)
```

**Deploy után** (egyszer, ellenőrzés):

```bash
# 1. Flyway schema history checksum frissítve V211-re
sudo -u postgres psql valuta -c "SELECT version, checksum, success FROM flyway_schema_history WHERE version='211';"
# Várt: success=t, checksum=új-érték (nem 1782720344)

# 2. FLYWAY_REPAIR_ON_MIGRATE env var kikapcsolás (biztonság)
sudo systemctl edit valuta-backend.service
# Töröljük az Environment="FLYWAY_REPAIR_ON_MIGRATE=true" sort
sudo systemctl daemon-reload
sudo systemctl restart valuta-backend.service

# 3. Egészségellenőrzés
curl -s https://excvaluta.com/api/v1/auth/bootstrap-status
```

## Fresh-deploy garancia teszt

Új Scaleway instance vagy dev VM-en a backend V1-től V222-ig minden migration-t
futtat → V211 most már helyesen indul:

```bash
docker compose up postgres  # vagy fresh PG
cd backend && ./mvnw spring-boot:run
# Várt: minden migration success, bootstrap-status: completed=true
```

## Megjegyzés

A `.flyway-lint-allowed-modifications` mechanizmus **KIVÉTELES**. Új ilyen
módosításhoz mindig kell:
1. Vault runbook (mint ez)
2. PR description-ben hivatkozás a runbook-ra
3. Production-repair eljárás dokumentálva

A default továbbra is: **új V<n+1>__ migration**, NEM régi fájl editálás.
