# Dependabot major-verzió defer-napló — 2026-06-01

> **Cél:** a major Dependabot PR-ek döntésének tényalapú rögzítése (C.10/AI-review-mandate:
> „minden findinget javítani VAGY dokumentált defer-indoklás a vaultban"). Token-ökonómia:
> egy helyen, nem PR-enként szétszórva.

## Kontextus

5 nyitott major Dependabot PR került áttekintésre (rebase után mind MERGEABLE). Döntés:
**3 mergelve, 2 dokumentált defer** (gyökérok-bizonyítással, NEM vak elutasítás).

## ✅ Mergelve (alacsony kockázat, CI zöld)

| PR | Bump | Indok |
|---|---|---|
| #835 | `actions/setup-dotnet` 4→5 | CI-only action; nincs futásidejű hatás; CI zöld. |
| #837 | `actions/setup-node` 5→6 | CI-only action; Node 24 már használt; CI zöld. |
| #839 | `react-router-dom` 6→7 | A projekt a v6-os data-API-t használja, amit a v7 visszafelé kompatibilisen visz tovább; rebase után **teljes CI zöld** (Lint+TypeCheck+Playwright). |

## ⏸️ Dokumentált defer (gyökérok bizonyítva, nincs CVE-driver)

### #836 — logstash-logback-encoder 8.0 → 9.0

**Gyökérok (réteg = ökoszisztéma-inkompatibilitás, NEM build-flag):**
- A 9.0 **Jackson 3-ra migrál** (`tools.jackson` package — upstream release `logstash-logback-encoder-9.0`, PR #1095) és Java 17+ minimumot kér.
- A backend **szándékosan Jackson-2 stop-gap-en** van (Spring Boot 4 — lásd `CLAUDE.md` tech-stack: „Jackson 2 stop-gap").
- A két saját PII-redactor provider — `RedactingMessageJsonProvider`, `RedactingStackTraceJsonProvider`
  (`backend/.../logging/`) — `com.fasterxml.jackson.core.JsonGenerator`-t (Jackson **2**) importál és
  `writeTo(JsonGenerator, ILoggingEvent)`-et override-ol. A v9 szülő-szignatúra `tools.jackson.core.JsonGenerator`
  → **`method does not override or implement a method from a supertype`** → Backend Build FAIL (CI-bizonyíték:
  run 26727955832).

**Miért defer és nem most-fix:** a v9 a logging-rétegre Jackson 3-at kényszerítene, miközben a teljes app
(REST-szerializáció) Jackson 2-n van. Két Jackson-major egy classpath-on + a providerek Jackson-3 API-ra
(`writeStringField`, `getFieldName`) portolása = kockázat egy **kozmetikus** logging-bumpért. Nincs CVE a 8.0-n.

**Trigger az újranyitásra:** a teljes alkalmazás Jackson-3 migrációja (amikor a Spring Boot leveszi a Jackson-2 stop-gapet).

### #840 — tailwindcss 3.4.18 → 4.3.0

**Gyökérok (réteg = breaking ground-up rewrite, a bump nem elég):**
- A tailwind 4 alapjaiból átírt: **CSS-first config**, a PostCSS-integráció külön `@tailwindcss/postcss`
  csomagba költözött, utility-átnevezések, `@tailwind` direktívák → `@import "tailwindcss"`.
- A PR **csak verziót bumpol** (`package.json` + lock), NEM migrál. A projekt v3-stílusú marad:
  - `frontend-react/postcss.config.js` → `{ tailwindcss: {}, autoprefixer: {} }` — **v4-ben hibát dob**
    (a `tailwindcss` már nem PostCSS-plugin),
  - `frontend-react/src/index.css` → `@tailwind` direktívák (v3),
  - `frontend-react/tailwind.config.js` → JS-config (v3).
  → a bump **eltörné az admin-UI stílusát**.
- A `frontend-react Lint + TypeCheck` CI-check azért zöld, mert **nem futtat Vite-buildet** (nincs dedikált
  frontend prod-build PR-check; csak a `deploy-hetzner.yml` buildel, deploykor). A törést csak a Playwright-smoke
  fogná meg.

**Miért defer:** nincs CVE a 3.4.x-en; a v4-migráció **dedikált, vizuálisan verifikált** feladat (postcss.config +
index.css + tailwind.config átírás + a ~51 oldal stílus-regresszió-ellenőrzése), nem dependency-batch tétel.
A nem-informatikus végfelhasználó alapelv (C.1) miatt törött admin-UI kiadása tilos.

**Trigger az újranyitásra:** tervezett UI-migrációs milestone, vizuális regresszió-teszttel.

## Megjegyzés a korábban skippelt PR-ekről
- **#848 / #849** — lockfile-konfliktus miatt korábban skippelve (külön rebase-batch szükséges).

## Bizonyíték-állapot (2026-06-01)
- main: v2.27.75, production HEALTHY 200, version-sync OK.
- 3 superseded branch törölve (fk-04-e2, fk-005-debug, audit-vv-elvi — main már tartalmazza a fixeket).
- voice-assistant phase5-8 branchek: **SKIP** (user-direktíva, megtartva).
