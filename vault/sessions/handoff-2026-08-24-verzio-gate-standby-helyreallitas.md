# Handoff — 2026-08-24 — verzió-gate kiadás + standby-helyreállítás

## Mi volt a feladat

A `handoff-2026-08-24-fkh039-fk093-v2.28.86-verzio-gate.md` félbehagyott munkájának
befejezése: v2.28.87 kiadása, mert a v2.28.86 tag kétszer kapott buildet, és az
auto-update semverre ül — a második build tartalma sosem jutott ki a pénztárgépekre.

## Mergelve (5 PR)

| PR | Mit | main SHA |
|---|---|---|
| #1652 | verzió-gate: GitHub Release baseline + 4 review-P1 | `d86fab06` |
| #1653 | standby health: abszolút 240 s határidő | `47c1823f` |
| #1655 | `GH_TOKEN` a Pénztár installer lépésnek | `13e9ea50` |
| #1654 | standby `.env` merge-only kulcsszinkron | `8d6e1a89` |
| #1656 | script-injekció + `notes` hosszkorlát | CI-ben |

## A nap fő eredménye: a hot-standby életre kelt

A 240 s-os ablak nem csak „elfért" — **ez tárta fel a valódi hibát**. A korábbi 80 s
mindig előbb járt le, mint a crash-ciklus, ezért időzítési gondnak látszott:

```
Caused by: java.lang.IllegalStateException:
FATAL: app.supervisor.password-hash nincs konfigurálva vagy nem BCrypt hash!
systemd: valuta-backend.service: Main process exited, status=1/FAILURE
```

A Scaleway standby backend **összeomlott induláskor**. Failover esetén nem elavult
kód futott volna, hanem semmi. Ok: a deploy csak a JAR-t másolta, a konfigurációt soha.

Javítás után (run **32774120617**, minden job zöld):

```
env-szinkron: potolt kulcsok (ertek nelkul):
  + JWT_EXPIRATION          + ERRORLOG_HMAC_SECRET
  + CORS_ALLOWED_ORIGINS    + SPRINGDOC_API_DOCS_ENABLED
  + SPRINGDOC_SWAGGER_UI_ENABLED
  + GOOGLE_LOGIN_BIND_SUB_ON_FIRST_LOGIN

standby health attempt 5 (32s/240s): HTTP 200
standby pg_is_in_recovery (t=jo): t
=== Standby warm backend UP (41s, 5 probalkozas) ===
```

Merge-only: meglévő értéket soha nem ír felül, topológia-függő kulcsokat
(`DATABASE_URL`, `SPRING_FLYWAY_ENABLED`, `NEON_*`) blocklist zár ki, eltérő
osztott titok esetén fail-closed leáll.

## Amit a review-k fogtak meg (és amit én mértem)

A #1654 első változatára 11 találat jött, **hat valódi**, köztük három P1:

1. a szinkron a `pg_is_in_recovery()` gárda **elé** került → failover után egy
   aktív primary konfigját írta volna át;
2. az üres `APP_SUPERVISOR_PASSWORD_HASH=` sort „szinkronizáltnak" vette →
   a backend továbbra is crashelt volna, pont amit javítani hivatott;
3. kiszámítható `/tmp/m.sh` root jogon (TOCTOU) → `mktemp` + `trap` takarítás.

A verzió-kapunak saját P1-jei voltak (#1652): a legsúlyosabb, hogy a
`commit-version-bump` job a publish **után** futtatta újra a kaput → a kiadott
verzió sosem került volna vissza a mainbe. Mind mutációval igazolva.

## Script-injekció (#1656)

A release 2. kísérletében minden build sikeres volt, de a `Publish` elszállt:
a **saját release-jegyzetem backtickje** törte el a PowerShell parsert. A gyökérok
mélyebb: a workflow nyersen interpolálta a felhasználói bemenetet a scriptbe —
a GitHub által dokumentált injekciós minta, signing-secretekhez férő runneren.

Felmérés (`classify-injection.py`), **tényleges kockázat** szerint osztályozva:

| kategória | db | teendő |
|---|---|---|
| boolean/choice (GitHub korlátozza) | 3 | nem kockázat |
| release-workflow, szabad szövegű | 3 | **javítva** |
| hotfix `confirm` | 8 | **nyitott feladat** |

## Nyitott feladatok

1. **8 hotfix-workflow `confirm` inputja** ugyanazt a nyers interpolációs mintát
   használja (`hotfix-flyway-repair-v194`, `scaleway-*`, `neon-*`). Mindegyik fix
   stringgel hasonlít és külön jóváhagyáshoz kötött, de a minta azonos.
2. **`ssh-keyscan` + `accept-new` TOFU** minden deploy-útvonalon. Nem verifikáció.
   Egyetlen lépésben átírni inkonzisztens állapotot szülne — külön feladat.
3. **v2.28.87 release** — a 3. kísérlet a #1656 merge után indítható.

## Külső akadály

`actions/checkout@v7` **hétszer** ragadt be 5–15 percre egy nap alatt, miközben
githubstatus.com végig „All Systems Operational" volt. Minden esetben `gh run rerun
--failed` oldotta meg; ~1,5 órát vitt el. A `penztar-client scanner.test.ts`
flaky-nak bizonyult (lokálisan 17/17 PASS 1.9 s).

## Bizonyítékok

- `.hermes/tickets/2026-08-24-verzio-gate-kiadas-folytatas.md`
- `.hermes/evidence/2026-08-24/standby-config-drift.md`
- skill frissítve: `valutavalto-secure-release` (4 új pitfall)
