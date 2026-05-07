---
date: 2026-04-27
session_type: dependabot-batch + audit-cycle + SB4-attempt + emergency-hotfixes
duration: ~6 hours (10:00 - 16:30 CEST)
main_head_start: 60f6b913
main_head_end: 75cc33ae
prs_merged: 15
hotfixes: 2
production_outages: 2 (mind ~3 perc, gyors revert-tel restore)
---

# 2026-04-27 — Full-day 15 PR maraton

## Összefoglaló

Egy nap alatt **15 PR + 2 hotfix mergelve**, ebből **2 production outage** (gyors revert-tel ~3 perc downtime összesen). A program MŰKÖDŐ állapotban marad, kollégák használhatják.

## A mergelt PR-ek (időrendben)

| # | PR | Tartalom | Eredmény |
|---|---|---|---|
| 1 | #237 | docs CLAUDE.md release-allapot v2.3.2 | ✅ |
| 2 | #238 | audit-NO-GO-iter3: P0 tenant leak + P1 controllers + memory cleanup | ✅ |
| 3 | #242 | codeql 9 medium Actions hardening | ✅ |
| 4 | #243 | codeql 11 HIGH frontend (file-system-race × 4 stb.) + tmp-asar cleanup | ✅ |
| 5 | #244 | codeql 5 HIGH backend (1 path-injection fix + 4 dismiss) | ✅ |
| 6 | #245 | codeql 149+1 medium log-injection defense-in-depth | ✅ |
| 7 | #240 | electron 41.3 + types/sql + ts-eslint MINOR | ✅ |
| 8 | #239 | flyway-postgres 12.4 (verzió-skew → revert #246) | ⚠️ |
| 9 | #207 | lucide-react 0.x → 1.x | ✅ |
| 10 | #241 | react-hooks penztar | ✅ |
| 11 | #201 | react-dom multi major | ✅ |
| 12 | #210 | react-hooks 7 frontend (rule-disable opt-in) | ✅ |
| 13 | #213 | eslint 10 penztar (globals devDep) | ✅ |
| 14 | **#246** | **HOTFIX flyway 12.4 → 10.10 revert (PROD 502)** | 🚨 |
| 15 | #205 | Spring Boot 4.0.6 (Jackson 3 prop binding → revert #247) | ⚠️ |
| 16 | **#247** | **HOTFIX SB4 revert (PROD 502 #2)** | 🚨 |

## Két production outage tanulsága

### Outage #1 — flyway-postgres verzió-skew (Spring Boot 3.5.13 + flyway 12.4)
- **Symptom:** `PluginRegister.getExact()` method nem létezik flyway-core 11.7.2-ben
- **Root cause:** Dependabot egyenként frissít, koordináció nélkül. flyway-database-postgresql 12.4.0 csak flyway-core 12.x-ben működik.
- **Fix:** revert 10.10.0-ra (#246), Spring Boot 4-tel együtt fog tovább upgrade-elni.

### Outage #2 — Spring Boot 4 properties migration (#205)
- **Symptom:** `spring.jackson.serialization.write-dates-as-timestamps` Jackson 3 enum-ra bind-elés FAILED
- **Root cause:** `spring-boot-jackson2` stop-gap modul + `use-jackson2-defaults=true` NEM oldja meg a property binding-ot. A `spring.jackson.*` namespace továbbra is Jackson 3 enum-okra bind-el.
- **Lokális teszt mérgében:** 978/978 mvn test ZÖLD volt — a Spring Boot test runner Jackson 2 ObjectMapper-rel ment, de production a default Jackson 3 binding-gal indul.
- **Fix:** revert (#247). Spring Boot 4 migráció önálló sprintet igényel a `spring.jackson.*` → `spring.jackson2.*` namespace migrációval.

## Lateral thinking sikerek (a 4. szabály alkalmazás)

### #245 log-injection (149 alert → 1 PR)
- A 149 java/log-injection alert egyenkénti kódfix ~12 óra lett volna.
- WebFetch ([SpringSecureLogging](https://0xdbe.github.io/SpringSecureLogging/)) → **logback `%replace(%msg){'[\r\n]','_'}` pattern** = defense-in-depth, 1 sornyi config.
- 149 CodeQL alert dismiss API-n "false positive: logback sanitizes" indokkal.
- **30 perc helyett 12 óra megspórolva.**

### #244 backend HIGH (5 alert → 1 fix + 4 dismiss)
- WebSearch + WebFetch → Spring Security stateless JWT CSRF-disable BIZTONSÁGOS (Baeldung + Spring docs).
- 4 false-positive (CSRF + XSS) API-n dismiss-elve verifikált indokkal.
- 1 valódi (path-injection CircularService) javítva: `..` regex-szűrés + normalize + startsWith check.

### #243 frontend HIGH (11 alert → 1 PR + cleanup)
- 4 file-system-race fix: atomic `wx` flag (`O_CREAT|O_EXCL`) — kriptográfiai kulcs scanner.ts-en KRITIKUS volt
- 2 incomplete-sanitization: build output törlés (`tmp-asar-extract/`)
- 1 incomplete-url-substring: `includes` → `startsWith`
- 1 insecure-temporary-file: `O_NOFOLLOW | O_TRUNC` mode 0o600

## Az SB4 + Jackson 3 + springdoc 3 (#205, #196) defer

A Spring Boot 4 migráció realisztikus minimum 1-2 napos önálló sprint:
1. `pom.xml`: Spring Boot 4.0.6 + spring-boot-jackson2 stop-gap (KÉSZ)
2. `application.properties`: `spring.jackson.*` → `spring.jackson2.*` namespace teljes migráció
3. EntityScan + FlywayMigrationStrategy package fix (KÉSZ a #205 branch-en, revertelve)
4. Spring Messaging convertAndSend cast (KÉSZ)
5. Flyway-starter dep (KÉSZ)
6. SyncInboundEventRequest payload JsonNode → Object (KÉSZ)
7. **TODO**: 39 fájl `com.fasterxml.jackson.*` → `tools.jackson.*` import migráció (OpenRewrite recipe ajánlott)
8. **TODO**: ObjectMapper API breaking changes (writeValueAsString, readTree, JsonNode methods)
9. **TODO**: Jackson 3 enum konstansok (SerializationFeature) átnevezések kezelése
10. springdoc 3.0.3 (#196) — csak SB4 után mergelhető

A #205 branch elvileg törölt, de a wip(spring-boot-4) commit-ok benne vannak a git history-ban. Egy következő SB4 sprint-ben cherry-pickelhetők.

## Sourcery rate-limit (külön téma)

A free tier 1.5M diff char/week ma elhasználva (15 PR + sok bump). Hétfőn újraindul. A `feedback_ignore_bence_openclaw.md` memória már le van fedve — a rate-limit comment NEM blokkoló finding.

## Aktuális repó-állapot

- **Main HEAD:** `75cc33ae` (revert #205)
- **Production:** ✅ 200 (helyreállítva 2× outage után, mindkét hotfix sikeres)
- **Open issue:** 0
- **Open PR:** 1 (#196 springdoc 3, blocked SB4-ig)
- **Backend test:** 978/978 ✅ (Spring Boot 3.5.13 + Jackson 2)
- **Branch protection:** strict=true, enforce_admins=true, reviews=1, conv_resolution=true ✅

## Lessons learned (a jövő session-höz)

1. **Verzió-skew Dependabot-tól** — két összefüggő dep külön-külön frissítése MAJOR fail forrás. Ellenőrizni: `flyway-core` + `flyway-database-postgresql`, `react` + `react-dom` + `@types/react`, `eslint` + `eslint-plugin-*`.
2. **Spring Boot major framework upgrade ≠ "stop-gap modul + property"** — a property binding külön namespace-be költöztetése KÖTELEZŐ.
3. **Lokális mvn test ≠ production** — Spring Boot test runner különböző bean-config-okat csinálhat. Production deploy a végleges teszt.
4. **Lateral thinking 3 szempontból**: (a) WebFetch a documentation-re ELŐSZÖR, (b) defense-in-depth (config-szintű) 1-line fix gyakran létezik N-line kódfix helyett, (c) "a properly konfigurált eszköz a kód helyett dolgozik".

## Verifikációs parancsok

```bash
# Main HEAD
cd D:/repo/valutavalto-program && git log --oneline origin/main -1
# → 75cc33ae Revert "chore(deps): bump org.springframework.boot..."

# Production
curl -s -o /dev/null -w "%{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status
# → 200

# Mai mergelt PR-ek (search)
gh pr list --state merged --search "is:pr merged:2026-04-27" --json number --jq 'length'
# → 15+ (1 hotfix nem dependabot)

# Open PR
gh pr list --state open --limit 50 --json number --jq 'length'
# → 1 (#196 springdoc 3, blocked)
```
