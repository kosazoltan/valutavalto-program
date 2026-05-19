# Valutaváltó ERP — Claude Code kontextus

## SESSION-START KÖTELEZŐ OLVASMÁNY (sorrendben)

Minden új session-kezdéskor az alábbi fájlokat **kötelező** beolvasni ebben a sorrendben:

1. **`vault/feedback/_active_mandates.md`** — aktív mandate-szabályok indexe (rövid táblázat)
2. **`vault/feedback/claude-code-korrekcios-mandate-2026-05-17.md`** — üzleti / szabályozási dimenziók (Pmt., pénzügyi adatintegritás, multi-tenant, sztornó, code-signing, önminősítés)
3. **`vault/feedback/ai-agent-push-ci-doctrine-2026-05-17.md`** — Push/CI/Deploy/Merge 10-fázisú doctrine
4. **`CLAUDE.md`** (jelen fájl) — fejlesztői workflow
5. **`~/.claude/projects/<project-hash>/memory/MEMORY.md`** — auto-memory index (a `<project-hash>` gép-/user-specifikus; jelen gépen `D--repo-valutavalto-program`)
6. **`vault/sessions/`** — legfrissebb session-jegyzet (előző tanulság)

A `_active_mandates.md` index → konkrét mandate-fájl irány a navigáció. **Ne indulj el a feladaton, amíg ezt a 6 fájlt át nem olvastad.**

**WHEN IN DOUBT:** a repo-tény (kód, Flyway-migráció, AI_CONSTITUTION.md) **erősebb** mint az AI emlékezet.

---

> ## ⚠️ NULLADIK PRIORITAS — NEM-INFORMATIKUS VÉGFELHASZNÁLÓ ALAPELV (2026-05-05)
>
> **A KOLLÉGÁK NEM informatikusok ÉS NEM programozók.** Ez a teljes deliverable-pipeline alapelv, **MINDEN** más szabály felett.
>
> **TILOS** a kollégának küldeni: parancssort (`ipconfig`, `netsh`, `Stop-Process`), manuális mappa-törlést (`Win+R %APPDATA%`), `.env`/`hosts` fájl-szerkesztést, antivírus-konfigurálást, registry-módosítást.
>
> **A TELEPÍTŐ AUTOMATIKUSAN elvégzi**: DNS cache flush, userData migration, régi-mappa-törlés, registry-cleanup, tűzfal-szabályok, parancsikon-létrehozás, Setup Wizard auto-indítás, diagnosztika beépítve.
>
> **A felhasználó csak**: dupla-klikk telepítőre + UAC "Igen" + esetleg admin-jelszó (8+ karakter).
>
> **Server-oldali fix** (pl. Cloudflare DNS) is **én végzem el** (API token-nel), nem a felhasználó.
>
> **NEM programoztatjuk a tesztelőket.** Diagnosztikai `.txt` automatikusan generálódik (`Penztar-Diagnosztika.zip` dupla-klikk → asztalra ment), a felhasználó csak elküldi.
>
> **Csak 100%-ban működő, tökéletes terméket adunk ki.** Hallucináció / lustaság / butaság / halogatás / "feltételezem" / "valószínűleg jó" **TILOS**.
>
> **Forrás**: Kósa Zoltán user-direktíva 2026-05-05 (Borsi-Helga-Tomi-Heni debug-ciklus után, ELFOGADHATATLAN volt a parancssoros instrukciózás).
>
> **Vault**: `D:\repo\valutavalto-program\vault\feedback\auto-installer-everything-mandatory.md`

> ## AI_CONSTITUTION.md (ELSO PRIORITAS)
>
> **Minden AI-ugynok** (Claude, OpenAI Codex, Sourcery, Gemini) **KOTELEZOEN olvassa be az `AI_CONSTITUTION.md`-t** a repo gyokerben, mielott barmit csinal. Az ott leirt **10 nem-alkukepes szabaly + 7 tiltas + 7 reteg architekturara + erettsegi modell (L2)** feluliria a jelen `CLAUDE.md` minden reszet, ha konfliktus van.
>
> **Aktualis erettsegi szint**: **L2** (TDD + audit log + CI gate-ek + AI review automation).
>
> **Hatalyba lepes**: 2026-04-24 — a *Uj AI mukodesi alapelvek: implementacios kezikonyv* (Kosa Zoltan user-direktiva) alapjan.

> ## SESSION-ZÁRÁSI PROTOKOLL (KÖTELEZŐ — 2026-05-04 user-direktíva)
>
> **MINDEN session, kódmódosítás, deploy, merge, push, CI, Copilot, Codex, Sourcery/Sorcery ellenőrzés és hibajavítás lezárása ELŐTT** kötelezően végre kell hajtani a 9-lépéses session-zárási protokollt:
>
> 1. Workspace állapot (git status + diff)
> 2. Helyi minőségkapuk (lint + typecheck + test + build)
> 3. Hibák+warningok javítása zöldig (root cause alapú, NEM próba-szerencse)
> 4. Merge előtti szinkron + konfliktus-feloldás + újra teszt
> 5. Push előtti végső helyi check (force push tilos user-direktíva nélkül)
> 6. Push/deploy után **KÜLSŐ** ellenőrzések visszaolvasása: GitHub Actions CI, Copilot, Codex, Sourcery, Hetzner deploy log
> 7. Külső hibák alapján javítási ciklus (root cause → minimális fix → újra push → újra visszaolvas)
> 8. Deploy utáni runtime ellenőrzések (health URL, runtime log, 4xx/5xx, migration, env var)
> 9. Záró jelentés tényekkel — milyen parancsok futottak, milyen eredménnyel, ha blokkoló: pontos név + hibaüzenet + következő lépés
>
> **Tiltott:** "valószínűleg jó", CI-visszaolvasás nélküli "kész", warning figyelmen kívül hagyása, review komment feldolgozatlanul hagyása, eredmény-visszaolvasás nélküli lezárás.
>
> **Teljes szöveg:**
> - `.cursor/rules/mandatory-session-closing-protocol.mdc` (always-on, multi-AI)
> - `D:\repo\valutavalto-program\vault\feedback\session-closing-protocol-mandatory.md` (vault feedback)

> ## FOLYAMATOS TESZTELÉSI PROTOKOLL (KÖTELEZŐ — 2026-05-04 user-direktíva)
>
> **MINDEN fejlesztés, kódmódosítás, hibajavítás, refaktor, új funkció, tesztírás, build, runtime ellenőrzés és programfunkcionalitás-validálás során** kötelezően alkalmazni kell a 4-lépéses folyamatos tesztelési protokollt:
>
> 1. **Tesztkörnyezet azonosítása** a módosítás előtt — meglévő framework + konvenció keresése
> 2. **Célzott tesztek írása + futtatása** kódmódosítás közben:
>    - Új funkció → pozitív + negatív esetek
>    - Hibajavítás → regressziós teszt amely a hibát javítás előtt elkapná
>    - Refaktor → külső viselkedés változatlan
>    - UI / workflow → kritikus user-path Playwright/runtime
> 3. **Tesztcsomag folyamatos bővítése** — új modul/endpoint/parancs/állapot/adatformátum/hibakezelés → új teszt; **több réteg** (unit + integration + e2e + runtime smoke) ahol releváns
> 4. **Tesztek újrafuttatása** minden lényeges módosítás után — szűk → közepes → teljes suite
>
> **Tiltott:**
> - ❌ Teszt skip / kikommentelés / törlés azért, hogy zöld legyen
> - ❌ Assertion gyengítés úgy, hogy ne védje a lényegi viselkedést
> - ❌ "Működik" állítás teszt vagy runtime ellenőrzés nélkül
> - ❌ Új funkció teszt nélkül (ha objektíven tesztelhető)
> - ❌ Hibás teszt javítása helyett a kód maradhat hibás (a teszt jogos hibát jelez → kódot kell javítani)
>
> **Záró követelmény:** tényszerű jelentés a futtatott tesztparancsokról + eredményekről + lefedett funkcionalitásról.
>
> **Teljes szöveg:**
> - `.cursor/rules/mandatory-continuous-testing-protocol.mdc` (always-on, multi-AI)
> - `D:\repo\valutavalto-program\vault\feedback\continuous-testing-protocol-mandatory.md` (vault feedback)

> ## MEMÓRIAHASZNÁLATI ÉS TUDÁSKARBANTARTÁSI PROTOKOLL (KÖTELEZŐ — 2026-05-04 user-direktíva)
>
> **MINDEN session, munkamenet-indítás, munkamenet-zárás, fejlesztés, hibajavítás, memóriaolvasás, memóriamentés, QMD, YAML, Cognee, vectoros memória vagy Obsidian memória használata során** kötelezően alkalmazni kell.
>
> **A memória NEM találgatások tárolója** — csak ellenőrzött tapasztalat, reprodukálható megoldás, valós hibák oka, tényleges projektkonvenció és használható összefüggés.
>
> **3 fő ciklus:**
>
> 1. **Session-eleji memóriaolvasás** — releváns memóriaforrások (CLAUDE.md, vault, `.remember/`, `.cursor/rules/`, AI_CONSTITUTION.md, AGENTS.md, CODEX.md) beolvasása + aktív alkalmazása
> 2. **Munka közbeni memóriafrissítés** — bizonyított root cause / hibajavítás / parancs / projektkonvenció / felhasználói preferencia / elkerülendő minta / külső szolgáltatás viselkedése / biztonsági tanulság / deploy tapasztalat azonnal jegyzetelendő
> 3. **Session-zárási memóriamentés** — vault `sessions/YYYY-MM-DD-*.md` (új jegyzet) + `feedback/<topic>.md` (új user-direktíva) + `references/<topic>.md` (új projekt-tudás) + `.remember/remember.md` (quick-state)
>
> **Memóriaforrás-típusok:** QMD (strukturált tudástár, Quarto Markdown), YAML (gépileg olvasható, `verified`/`assumption`/`deprecated`/`blocked`/`needs-review` mezőkkel), Cognee (gráf, deprecated ebben a repoban), Vectoros (embedding/szemantikus), **repo-local Obsidian vault `D:\repo\valutavalto-program\vault\` (aktív)**.
>
> **Dream funkció (kötelező, tényalapú):** csendes memória-elemzés a memóriaforrások között — kapcsolatok keresése, ismétlődő hibák felismerése, javasolt gyakorlatok. NEM fantáziálás, NEM helyettesít tesztet/buildet/lintet/runtime ellenőrzést.
>
> **Tiltott:**
> - ❌ Hallucináció / találgatás / bizonytalan következtetés rögzítése
> - ❌ Titok / token / jelszó / credential / felesleges személyes adat mentése
> - ❌ Forrás nélküli állítás aktív tudásként
> - ❌ Elavult / hibás memória aktív hagyása (vagy 2 ellentmondó memória párhuzamosan)
> - ❌ Repo aktuális tényének felülírása régi memóriával (a repo tény az erősebb)
>
> **Záró követelmény:** tényszerű jelentés a beolvasott + frissített memóriaforrásokról + új tanulságokról + javított elavult bejegyzésekről + Dream eredményekről.
>
> **Teljes szöveg:**
> - `.cursor/rules/mandatory-memory-protocol.mdc` (always-on, multi-AI)
> - `D:\repo\valutavalto-program\vault\feedback\memory-protocol-mandatory.md` (vault feedback)

## Projekt áttekintés
Magyar valutaváltó / pénzváltó ERP rendszer. Multi-tenant (több iroda), offline-képes.

## Tech stack
- **Backend:** Java 21, Spring Boot 3.2, Spring Security, Spring Data JPA, PostgreSQL, Flyway migrációk
- **Frontend (admin):** React 19, TypeScript, Tailwind CSS 3, Zustand — `frontend-react/`
- **Desktop kliens (pénztáros):** Electron 33, React, SQLite offline sync — `penztar-client/`
- **Build:** Maven (backend), npm + Vite (frontend + desktop)

## Könyvtárstruktúra
```
backend/                  # Spring Boot backend
  src/main/java/hu/puzzleir/valuta/
    config/               # Security, WebSocket, CORS, rate limiting
    controller/           # REST kontrollerek (~113 db)
    dto/                  # Request/response DTO-k
    entity/               # JPA entity-k (~165 db)
    mapper/               # MapStruct mapperek
    repository/           # Spring Data JPA repók
    security/             # JWT, SecurityUtils
    service/              # Üzleti logika (~122 db)
    util/                 # Segédosztályok
  src/main/resources/
    db/migration/         # Flyway migrációk (V1–V71)
    application.properties
frontend-react/           # Admin webes felület (React 19 + TS)
  src/pages/              # ~51 oldal
  src/services/api.ts     # Axios API hívások
  src/utils/              # Segédek (pl. rounding.ts — 5 Ft kerekítés)
penztar-client/           # Pénztáros Electron kliens
  src/pages/              # Buy, Sell, Conversion, stb.
  src/stores/             # Zustand store-ok
  electron/sync-engine.ts # Offline sync
database/                 # Extra migrációk, seed-ek
scripts/                  # Utility szkriptek
```

## KÖTELEZŐ ÉRVÉNYŰ: Lint CI + Codex + Sourcery + Copilot — minden PR-en automatikusan (2026-05-03 user-direktíva)

> **User direktíva 2026-05-03 21:50 + 21:53 CEST:**
> "lint CI codex sourcery kötelező minden pr esetén!!!! Automatikusan minden esetben
> lustaság, hazugság, mellébeszélés nélkül kötelező, megcsinálnod."
> "a copilot jelzéseit is kötelező"

**Minden PR létrehozás/push/merge után KÖTELEZŐ a teljes ciklus AUTOMATIKUSAN, ember-megerősítés nélkül:**

1. **CI ellenőrzés** — `gh pr checks <PR>` — minden required check ZÖLD vagy fix-elés
2. **Codex review lekérés** — `gh api .../pulls/<PR>/reviews` + `/comments` (filter chatgpt-codex-connector)
3. **Sourcery review lekérés** — ugyanaz, sourcery-ai user
4. **Copilot review lekérés** — ugyanaz, copilot-pull-request-reviewer (2026-05-03 user-direktíva: NEM "best-effort", **EGYENÉRTÉKŰ** Codex/Sourcery-vel)
5. **MINDEN P0/P1/P2 jelzett hibát KÖTELEZŐ azonnal javítani** — új follow-up commit + push + új CI ciklus
6. **Csak akkor admin-merge** ha (a) CI zöld + (b) MINDEN P0/P1/P2 fixelve VAGY dokumentált defer indoklással a vault-ban

**TILOS:**
- ❌ "P3 minor → defer" indoklás nélkül
- ❌ "Majd a következő sprintben" P0/P1/P2-re
- ❌ "Csak az enyém PR" — mind nyitott PR ráma vonatkozik
- ❌ "Sourcery weekly limit miatt nem tudom" — a P0/P1/P2 a Codex/Copilot review-ból is jön
- ❌ Hazudni "minden zöld"-et `gh pr checks` validáció nélkül
- ❌ Csak az ALL_DONE monitor után átfutni a PR-t — proaktívan kell ellenőrizni az AI-bot review-ját

**Részletes workflow:** [vault/feedback/lint-ci-codex-sourcery-every-pr-mandatory.md](D:\repo\valutavalto-program\vault\feedback\lint-ci-codex-sourcery-every-pr-mandatory.md)

## KÖTELEZŐ ÉRVÉNYŰ: Production-first fejlesztés
> **A fejlesztés közvetlenül a produktumhoz (Hetzner HA: https://excvaluta.com) illeszkedik.**
> TILOS divergens lokális stack-et használni seed-adattal, amit a produktum nem tartalmaz.

### Szabályok
1. **Frontend + Electron** az `excvaluta.com`-ra mutat (production API URL). Lokális backend CSAK Maven teszt-futtatáshoz (mvn test), nem integrációs fejlesztéshez.
2. **Lokális DB seed** TILOS, ami nincs a produktum DB-n. Ha új seed kell: **Flyway migráció** -> commit -> push -> Hetzner deploy (auto) -> NEKI ott is futni kell.
3. **Adatbázis migráció** esetén: `backend/src/main/resources/db/migration/V{N}__{name}.sql` — a CI/CD deploy pipeline futtatja produktum-on is.
4. **Manuális INSERT `psql`-lel** a lokális DB-be **csak reprodukciós tesztre**, utána **azonnal rollback vagy DROP**. TILOS elfelejtve hagyni.
5. **Ha produktum DB-ben valami hiányzik** (pl. licence, árfolyam), **Flyway migration** a fix útja — ne kézi `psql INSERT`.

### "Local-only" szabályok
- `docker-compose up postgres` csak mvn test + fejlesztői debug-hoz
- `npm run dev` + backend lokálisan CSAK unit-szintű frontend debug-hoz
- **Integrációs teszt** = Hetzner produktum + `VITE_API_URL=https://excvaluta.com/api/v1` env

### Session kezdőlépés (KÖTELEZŐ)
Minden új session elején:
```bash
curl -s https://excvaluta.com/api/v1/auth/bootstrap-status   # >= 200
curl -s https://excvaluta.com/api/v1/public/branches?companyCode=EBC   # non-empty
```
Ha **DOWN**: először helyreállítani (Hetzner + Scaleway HA failover), utána kezdeni a fejlesztést.

## KÖTELEZŐ ÉRVÉNYŰ: Session memory workflow (Obsidian-alapú, 2026-04-27 óta)

**EGYETLEN aktív memóriarendszer:** `D:\repo\valutavalto-program\vault\` (repo-local Obsidian-kompatibilis vault, dedikált a valutaváltó-projekt számára).

A korábbi rendszerek **deprecated** (2026-04-27 user-direktíva — "memória mizéria megszüntetése"):
- ❌ `.memory/` (SQLite + Node.js MCP) — **TÖRÖLVE** (Bence/Eszter/Tamás belső koncepció refek)
- ❌ Cognee MCP (TODO maradt) — **VISSZAVONVA**
- ❌ Több párhuzamos memóriarendszer

**Minden session elején** olvasd be (ebben a sorrendben):
1. `D:\repo\valutavalto-program\vault\README.md` — vault használati protokoll
2. `D:\repo\valutavalto-program\vault\sessions\` — legfrissebb session-jegyzet (YYYY-MM-DD)
3. `D:\repo\valutavalto-program\vault\feedback\` — kötelező user-direktívák (skim mindent)
4. `.remember/remember.md` — csak quick-state handoff (4-5 sor)
5. `docs/LESSONS_LEARNED.md` — korábbi hibák, amiket NE ismételj

**Minden session végén** mentsd a vault-ba:
1. `D:\repo\valutavalto-program\vault\sessions\YYYY-MM-DD-rovid-leiras.md` — új session-jegyzet
2. `D:\repo\valutavalto-program\vault\feedback\<topic>.md` — ha új user-direktíva érkezett
3. `D:\repo\valutavalto-program\vault\references\<topic>.md` — ha új projekt-tudás érkezett külső forrásból
4. `D:\repo\valutavalto-program\vault\procedures\<workflow-name>.md` — ha új vagy módosult workflow született
5. `.remember/remember.md` — quick-state update (Main HEAD, open PR/issue, production health)
6. CLAUDE.md "Nyitott következő feladatok" → frissítés ha változott

**Tilos:**
- ❌ Új fájl írása `~/.claude/projects/.../memory/`-ba — az csak redirect
- ❌ Bence/Eszter/Tamás (régi belső AI csapat-koncepció) — deprecated
- ❌ OpenClaw / openclaw refek — másik projekt, külön vault
- ❌ Új `.memory/` SQLite vagy hasonló párhuzamos rendszer

A `docs/knowledge/memory/*.yaml` történelmi formátum (2026-04-26 előtti session-ök) **maradnak** a git history-ban, de új YAML-okat NE hozz létre — az Obsidian vault `sessions/` lett a hely.

Ezek **kötelező érvényűek**, nem választható.

## KÖTELEZŐ ÉRVÉNYŰ: Komplex ökoszisztéma megnyitás
Amikor a user "nyissuk meg a valuta programot / indítsd az ökoszisztémát / teljes rendszer / program elindítása" utasítást ad, **MINDIG az összes komponenst együtt kell indítani**, TILOS csak egy részt:

1. **Lokális PostgreSQL** (localhost:5432) — ellenőrzés + V154 migration alkalmazva
2. **Backend** (Spring Boot, port 8080) — `backend/mvnw spring-boot:run`
3. **Frontend-react admin** (Vite, port 3000) — `frontend-react/npm run dev`
4. **Penztar-client Electron** — `penztar-client/npm run dev:main` (a renderer a frontend-react 3000-esét használja)

**Launcher:** `scripts/start-valuta-ecosystem.ps1` — egyetlen paranccsal az összes komponens elindul + health check + log path-ok listázva.

**Leállítás:** `scripts/stop-valuta-ecosystem.ps1` (vagy `Get-Process java,node,electron | Stop-Process -Force`)

**TILOS külön megnyitni!** A helyes állapot ellenőrzése csak komplex rendszer-szinten érvényes — pl. a frontend authentication hitelesítése a backend-hez, az Electron sync a backend-hez és a frontend-hez stb. Külön indítás csak debug célra megengedett, explicit user-megerősítéssel.

## Build és futtatás
```bash
# Backend
cd backend && ./mvnw spring-boot:run

# Frontend (admin)
cd frontend-react && npm install && npm run dev

# Pénztáros kliens
cd penztar-client && npm install && npm run dev
```

## Tesztek
```bash
# Backend tesztek (JUnit 5)
cd backend && ./mvnw test

# Frontend tesztek (Vitest)
cd frontend-react && npm test

# Pénztáros kliens tesztek
cd penztar-client && npm test
```

## Fontos konvenciók
- **Nyelv:** A kódbázis Java/TypeScript, de a domain (üzleti fogalmak) magyarul van: vétel (buy), eladás (sell), sztornó (storno), napzárás (daily closing), címletezés (denomination), árfolyam (exchange rate)
- **Multi-tenant:** Minden lekérdezés companyId-ra szűr — SOHA ne hagyd ki a company szűrést!
- **HUF kerekítés:** Magyar 5 Ft-os kerekítés kötelező minden HUF összegnél (`roundHuf` util)
- **AML:** Pénzmosás elleni ellenőrzés kötelező tranzakciók előtt
- **Árfolyam frissesség:** 24 órás TTL — lejárt rátával nem szabad tranzakciót engedni
- **Security:** `@PreAuthorize` annotáció minden controlleren, JWT auth, CORS nem lehet wildcard (`*`)

## Kotelezo regi hibak azonnali javitasa
- Ha egy audit vagy kódreview soran barmilyen korabbi hibat megtalalsz (scope-on kivul, mas modulban), azonnal javitani kell, nem dokumentalni kesobbre.
- Ez kiterjeszti a jelenlegi PR scope szabalyt — a user szerint minden ismert hiba surgos.
- Kivetel: ha a javitas tobb napos refactort igenyelne, akkor GitHub Issue-t nyitni + kommentalni a kodban.


## V2 AKTIV: Multi-modell GitHub mandate (2026-04-23 este)

- HATALY: Minden Anthropic + OpenAI + Gemini coding agent (NINCS mentesseg)
- IGAZSAGFORRAS: AGENTS.md (projekt gyoker, modellfuggetlen)
- KEMENY TILTASOK: AI_CONTRACT.md (300 LOC plafon, test manipulation tilos, Actions hardening)
- SKILLEK: .claude/skills/{github-quality-gate,ai-review-responder,deploy-verification,agents-md-generator}/
- GLOBAL MEMORY: ~/.claude/projects/D--repo-valutavalto-program/memory/MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md (53 KB)
- OBSIDIAN: docs/obsidian-vault/MANDATE_V2.md
- QMD+YAML: docs/knowledge/memory/2026-04-23-multi-model-mandate-v2.{qmd,yaml}

A v2 KIEGESZITI a kovetkezo [LEGACY v1] szekciot, NEM helyettesiti. A v1 szekcio 10 kapu + GitHub-jelzes lekerdezesi protokoll resz valtozatlan, viszont a v2 tovabbi 10 protokoll szekcioval bovult (PR state polling, GraphQL threads, rulesets, workflow logs, Actions hardening, SLSA attestation, stb).
## KÖTELEZŐ ÉRVÉNYŰ: Opus 4.7 GitHub minőségbiztosítási mandate (v3, 2026-04-23+)

> **User-direktíva:** `C:\Users\Kósa Zoltán\Downloads\opus-4-7-github-push-minosegbiztositas.md` (33 KB, 10 pontos munkaszerződés + GitHub-jelzés lekérdezési protokoll)
> **Globális memória:** `C:\Users\Kósa Zoltán\.claude\projects\D--repo-valutavalto-program\memory\OPUS_GITHUB_QUALITY_MANDATE.md` (automatikusan betöltött MEMORY.md index első sora)
> **Projekt checklist:** `REVIEW.md` (minden push elott kovetendo)

### Alapelv
Opus nem „programozó asszisztensként”, hanem **auditált GitHub-operátorként** dolgozik. **NINCS** „kész”, „ready”, „done”, „pusholható”, „merge-ready”, „deploy-ready” deklaráció gépileg ellenőrzött bizonyíték nélkül.

### Kapumátrix (10 kapu)

| Kapu | Kötelező bizonyíték | Ha nem zöld |
|---|---|---|
| Lokális lint | `lint` 0 error | Tilos pusholni |
| Typecheck | `tsc --noEmit`, `mypy`, `cargo check` | Tilos pusholni |
| Teszt | Unit/integration/e2e releváns suite zöld | Tilos pusholni |
| Build | Reprodukálható build sikeres | Tilos PR-t késznek jelölni |
| GitHub Checks | Required checks pass/pending/fail lekérdezve | Fail/pending esetén folytatni kell |
| Codex review | P0/P1 finding nincs / dismissed | Tilos merge-ready |
| Sourcery review | Security/testing/complexity findingek kezelve | Tilos merge-ready |
| Dependabot | Nyitott high/critical alert nincs | Tilos deploy |
| CodeQL | Új open high/critical nincs | Tilos merge/deploy |
| Secret scanning | Új secret alert / bypass nincs | Tilos merge/deploy |

### Kötelező munkafolyamat (mindig ebben a sorrendben)
1. **Explore** - releváns fájlok olvasása
2. **Plan** - mely fájlok változnak, miért, melyik teszt bizonyítja
3. **Code** - csak a terv szerinti fájlokon
4. **Local verify** - `lint → typecheck → test → build`
5. **Diff self-review** - minden fájl indoklása
6. **Push** feature branch-en
7. **GitHub jelzés lekérdezés** (`scripts/github-signal-check.ps1 <PR>`)
8. **AI review fix** (Codex / Sourcery P0/P1 azonnal)
9. **Required checks újra** - csak zöld állapotban merge
10. **Záró self-review formátum** (REVIEW.md végén leírt blokk)

### Biztonsági tiltólista (új kód)
- hard-coded secret / SQL string-konkat input-ból / `eval`/`Function` / `shell=True` / path traversal / néma catch / hamis mock prod-ban / nem ellenőrzött dependency

### Fail loud, never fake
- Hiány (külső API/DB/service/file/secret) esetén: **explicit error + log**
- Fallback CSAK `degraded` jelzéssel
- Tilos úgy tenni mintha élő adat lenne, ha mock/cache van

### AI review jelzések (KÖTELEZŐ módszer változás — user-direktíva)
**EDDIG:** email-ben érkezik review → user bemásolgatja → agent javítja.  
**EZENTÚL (MEGSZÜNTETVE a bemásolgatás):** minden PR push után az **agent MAGA** futtatja a queries-ket.

#### KRITIKUS megjegyzés a Codex dual-channel zavarról (2026-04-27 audit fix)
- A Codex GitHub App **AUTOMATIKUS** review-t ad PR-eken — ez a valódi findinges csatorna, a `/pulls/{N}/reviews` API-n jelenik meg `state: COMMENTED, body: "💡 Codex Review..."` formában.
- Az `@codex review` MENTION egy MÁSIK csatorna. Ha a kosazoltan ChatGPT fiók nincs összekötve a Codex Connector-ral (https://chatgpt.com/codex/cloud/settings/connectors), akkor minden mention-re `chatgpt-codex-connector[bot]` válasz: **"To use Codex here, create a Codex account and connect to github."** Ez **ZAJ**, nem hibás finding!
- A `.github/workflows/auto-review.yml` Bence workflow 2026-04-27 óta **NEM küld `@codex review` mention-t** — csak Sourcery-t (a Codex auto-review úgyis lefut).
- **Query helye:** kizárólag `/pulls/{N}/reviews` + `/pulls/{N}/comments`. NE `/issues/{N}/comments`-et — ott csak a mention-zaj van.

#### Kötelező AI review query (defensive zaj-szűréssel):
```bash
# Reviews (top-level review submissions) - Codex auto-review + Sourcery itt erkezik
gh api "/repos/kosazoltan/valutavalto-program/pulls/$PR/reviews" \
  --jq '.[] | select(((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) and ((.body // "") | (contains("create a Codex account") | not)) and ((.body // "") | (contains("weekly rate limit") | not))) | {reviewer:.user.login,state,body}'

# Inline comments (file:line specific findingek)
gh api "/repos/kosazoltan/valutavalto-program/pulls/$PR/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) | {user:.user.login,path,line,body}'
```

A `(contains("create a Codex account") | not)` es `(contains("weekly rate limit") | not)` szurok kizarjak:
- Codex setup-prompt zaj (ha valaha megis a reviews API-ra is felkerulne)
- Sourcery weekly rate-limit comment zaj

### Helper scriptek
- `scripts/pre-push-quality-gate.ps1` — lint + typecheck + test + build futtatas, exit=0 kell a push-hoz
- `scripts/github-signal-check.ps1 <PR_NUM>` — osszes GitHub jelzes egyben (required checks, Codex, Sourcery, Dependabot, CodeQL)

### Zéró-tolerancia tiltólista
- ❌ "Tudtommal működik" / "Szerintem kész"
- ❌ "Majd a CI kiszűri"
- ❌ `--no-verify` flag
- ❌ AI review email → bemásolás → javítás (**megszüntetve**)
- ❌ "Sikeres a fordítás" ≠ "deploy-ready"
## KÖTELEZŐ ÉRVÉNYŰ: push = commit + merge + BRANCH DELETE (v2 szigoritas)
**2026-04-23 óta kötelező** (user-direktíva, üzletmenet-kritikus, **v2 szigorítás** a branch-halmozódás miatt):

- **Minden push-nak merge-elnie kell a main-re AZONNAL + a branch-et tÖrÖlni** (remote + local).
- Nem maradhat nyitott PR, feature branch, vagy uncommitted fejlesztés hosszabb ideig.
- **Tilos**:
  - Nyitott PR napokig "CI várakozás" ürügyén
  - Uncommitted fejlesztések
  - Feledésbe merült branch-ek (2026-04-23 állapot: **91 lokális + 30 remote branch** halmozódott fel, SOHA többé!)
  - `--delete-branch=false` flag használata — **VISSZAVONVA**

### Push-merge folyamat (minden kód-módosításkor)
1. **Code change + commit** a feature branch-en
2. **Push** a feature branch-re (`git push`)
3. **CI zöld** (várj amíg minden check SUCCESS)
4. **AI review fix** (Sourcery/Codex feedback azonnal javítva, `gh api pulls/N/reviews + comments` lekérése kötelező)
5. **Merge to main** — `gh pr merge N --squash --auto --delete-branch` (a `--delete-branch` KÖTELEZŐ, NEM `=false`)
6. **Lokális branch törlés** (`git branch -d BRANCH`)
7. **Hetzner auto-deploy** (backend + frontend)

### Miért kötelező?
- **Uncommitted fejlesztés** hibái miatt a bug "nem javul": a fix a branch-en van, de a main-en NEM → production továbbra is buggy.
- **AI ügynökök munkája** (Sourcery, Codex) elvészhet, ha a PR napokig nyitva marad.
- **Hetzner production** csak a main branch-ről deploy-ol → ha a fix nincs main-en, production sem javul.
- **Branch-halmozódás** (91+30 a 2026-04-23 állapotban) nehezíti a navigációt, rejti az aktív fejlesztéseket, duplikált kódot tárol.

### Kivétel
- Explicit merge-blokkoló AI review feedback (CHANGES_REQUESTED DISMISS nélkül)
- Legitim CI failure (nem flaky)
- Dependabot PR-ek: batch merge hetente 1x, NEM egyenként.

### Auto-merge + cleanup CLI script (KÖTELEZŐ szintaxis)
```bash
# Minden uj PR auto-merge ezzel:
gh pr merge $PR_NUM --squash --auto --delete-branch

# Lokalis cleanup merge utan:
git checkout main && git pull origin main
git branch -d $BRANCH_NAME
```

### Periodikus cleanup (hetente 1x, KÖTELEZŐ)

**AI review fix v2.1** (2026-04-23 Sourcery + Codex feedback beepitve):
- Codex P1: origin/main KIZARVA a cleanup-bol (branch protection-off eseten is biztonsagos)
- Sourcery P2: shell variable-ok quoted formaban + fetch --all --prune a skript elejen

```bash
# 0. Fetch + prune (Sourcery P2 #138): mindig friss remote allapot a merge-base check-hez
git fetch --all --prune

# 1. Remote merged branch-ek torlese (KIVEVE origin/main!)
gh api "repos/OWNER/REPO/branches" --paginate -q '.[] | select(.protected==false) | .name'   | while IFS= read -r branch; do
      # Codex P1 #138: KOTELEZO main-t explicit KIZARNI a cleanup-bol
      # Branch protection-off eseten az ancestor check igaz lenne origin/main-re is
      # es a weekly cleanup letorolne a default branch-et (CI/deploy breaking!)
      if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
        continue
      fi
      if git merge-base --is-ancestor "origin/$branch" origin/main 2>/dev/null; then
        gh api -X DELETE "repos/OWNER/REPO/git/refs/heads/$branch"
        echo "Deleted remote: $branch"
      fi
    done

# 2. Lokalis merged branch torles (quoted variable - Sourcery P2):
git branch --merged main | grep -v -E "^\*| main$"   | while IFS= read -r branch; do
      branch=$(echo "$branch" | xargs)  # trim whitespace
      if [ -n "$branch" ] && [ "$branch" != "main" ]; then
        git branch -d "$branch"
      fi
    done

# 3. Lokalis stale remote references cleanup (ha valami remote-rol eltunt):
git remote prune origin
```

### Monitoring (heti)
Elvart: `gh pr list --state open` = 0 PR, aktiv remote branch szam:
```bash
# Sourcery P2 #138 fix: 'main$' regex - NEM szuri az origin/HEAD -> origin/main pointer-t
# ami az egyszeru 'main' match hibasan szurtte (off-by-one)
git branch -r | grep -v -E '(main$|HEAD)' | wc -l
```

Ha az ertek **> 5**: azonnal futtatni a cleanup scriptet.

## AUTOMATIZALT AI code review workflow (Sourcery + Codex)
**2026-04-21 ota automatikus**: a `.github/workflows/ai-review-auto-fix.yml` a Claude Code Action-t triggereli, amikor Sourcery vagy Codex review erkezik. Ez automatikusan javit + push-ol a feature branch-re. A manualis workflow az `agent` fallback.

Lasd: `docs/AI_REVIEW_AUTOMATION.md`

## Kötelező AI code review workflow (Sourcery + Codex) — manualis fallback
- **Minden PR MERGE UTAN automatikusan:**
  1. Lekerni a Sourcery-AI es ChatGPT-Codex review-kat: `gh api repos/OWNER/REPO/pulls/PR_NUM/reviews` es `/pulls/PR_NUM/comments` (filter: user.login matches `sourcery-ai|chatgpt-codex-connector`).
  2. **Automatikusan javitani a jelzett hibakat.** Priorizalas: P1 (bug_risk, kritikus) > P2 (suggestions) > style.
  3. Follow-up PR-t nyitni: `fix(ai-review): ...` prefix-szel.
  4. Helyi teszt-futtatas kotelezo a merge elott (backend mvn test + frontend vitest + tsc).
- **Helyes-pozitiv kizarasa:** Ha egy AI flag hamis riasztas (pl. balanced brackets), dokumentalni a PR-ben miert nem javitasra vonatkozo. Ne ignoralni, csak megjelolni.
- **Kovetkezo session handoff:** minden AI javitas a session handoff memory YAML-ban dokumentalando.

## KÖTELEZŐ ÉRVÉNYŰ: AI Review Zero-Tolerance Mandate (v2.3.18+, 2026-04-29 user-direktíva)

> **Hatálybalépés:** 2026-04-29 20:55 CEST (Kósa Zoltán direkt utasítása)
> **Vault:** `D:\repo\valutavalto-program\vault\feedback\ai-review-mandate-zero-tolerance.md`

**A szabály:**
> Addig nem léphetsz tovább, amíg a GitHub Codex + Sourcery AI Botok jelentéseit
> le nem kérted a GitHub-ról, és nem javítottad azokat a jelzett hibákat.
> Minden PR / Merge után KÖTELEZŐ:
> 1. **Várni** a Sourcery + Codex review-kra (~1-2 perc admin-merge után)
> 2. **Lekérdezni** a finding-eket (`gh api .../pulls/{N}/reviews + comments`)
> 3. **Javítani MINDEN** P0/P1/P2 jelzett hibát (NEM csak P0/P1!)
> 4. **Új follow-up PR** nyitása + cikluson újra végigmenni
> 5. **CSAK akkor léphet a következő feladatra**, ha:
>    - Sourcery: "looks great!" (vagy minden finding kezelve / dismissed indoklással)
>    - Codex: csak boilerplate (vagy minden P0/P1 fixed)

**Tilos:**
- ❌ "P2 minor → defer" megjelölés indoklás nélkül
- ❌ Új feladat indítása amíg Sourcery/Codex finding nyitva
- ❌ Saját döntéssel "kihagyni" review-k figyelmen kívül hagyását

**Engedélyezett (dismiss + dokumentált):**
- ✅ P2 finding **dismiss** indoklással a vault-jegyzetben (>1000 LOC refaktor → külön sprint, GitHub issue-ban követni)
- ✅ Sourcery finding amit a Codex felülír (P1 elsőbbség P2 felett)

**Indok:** A 2026-04-29-i Codex P1 #280 megmutatta: a `console.log` heartbeat
silently elsüllyedne production-ban (Electron renderer→main forward filter
level >= 2). A mandate NEM-követése = production-fagyás-detection elvész.

**Konklúzió:** A code review tooling másodlagos szem-pár, NEM választható.

## KÖTELEZŐ ÉRVÉNYŰ: Hallucinációs Kör Megszüntetése — Iparági Standard (2026-04-29 user-direktíva)

> **Hatálybalépés:** 2026-04-29 21:25 CEST (Kósa Zoltán direkt utasítása)
> **Vault:** `D:\repo\valutavalto-program\vault\feedback\hallucinacio-megszuntetese.md`
> **Trigger:** 9 sorozatos Sourcery P2 follow-up PR (v2.3.13 → v2.3.22) ugyanazon a fájlon.

**Context7 API kulcs (2026-04-29 user-import):**
- **Tárolás:** `.env.context7` (repo gyökér, **gitignore-olt** — NEM commit-olható)
- **Setup útmutató:** `.claude/CONTEXT7_SETUP.md`
- **Használat:** `claude code` indításkor `$env:CONTEXT7_API_KEY` betöltve a `.env.context7`-ből

**A szabály:**
> Ezentúl minden programozási feladat előtt KÖTELEZŐ:
> 1. **Context7 MCP** (`mcp__892e2348-f110-4f49-afe2-e16ee93cb2f4__resolve-library-id` + `query-docs`) használata a hivatalos library doc + best-practice patterns olvasásához
> 2. **Iparági standardokra hivatkozni** (NEM saját ad-hoc megoldás): Zod, Valibot, Joi (validation); electron-log, Pino, Winston (logger); Zustand, TanStack Query (state)
> 3. **Brainstorming ELŐTT a kódolás** (komplex feature esetén `superpowers:brainstorming` skill)
> 4. **TDD ELŐTT az implementáció** (`superpowers:test-driven-development`)

**TILOS:**
- ❌ Próbálkozás-alapú kódolás ("majd kiderül a Sourcery review-n")
- ❌ Saját ad-hoc validáció iparági lib helyett (pl. `STRICT_INTEGER_PATTERN` regex Zod helyett)
- ❌ Apró iterációs PR-ek folyamatos generálása ugyanazon a fájlon
- ❌ Találgatás (próba-hiba módszer kódolás közben)

**Példa — heartbeat config (rossz vs jó):**

❌ Rossz (9 PR iteráció): manual `parseInt` + range check + `STRICT_INTEGER_PATTERN` + `logger.warn` + komment-align...

✅ Jó (1 PR, Zod-dal):
```typescript
import { z } from 'zod'

export const heartbeatConfig = z.object({
  intervalMs: z.coerce.number().int().min(10_000).max(600_000).default(60_000)
}).parse({ intervalMs: import.meta.env.VITE_HEARTBEAT_INTERVAL_MS })
```

Egyszer írt, type-safe, validált, iparági standard (Zod 3.22.4 már a `package.json`-ben).

**Új workflow:**
```
Új feladat → 1. Context7 query (iparági standard library)
            → 2. Brainstorming (ha komplex)
            → 3. TDD (test-first)
            → 4. Implementáció iparági lib-bel
            → 5. Egyszeri Sourcery/Codex review (várhatóan tiszta)
            → 6. Merge
```

## Kötelező security gate minden agentnek
- **Always-on szabály:** Kötelező alkalmazni `.cursor/rules/mandatory-security-gate.mdc`.
- **Kötelező skill:** Minden programozási feladatnál kötelező a `.cursor/skills/security-deploy-gate/SKILL.md`.
- **Kötelező baseline:** `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md` (multi-stack: Java, Electron, React, Python, Node.js).
- **Deploy előtti gate:** Kötelező futtatás: `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`.
- **Blokkolás:** `FAILED` vagy `BLOCKED` gate státusz esetén deploy tiltott.
- **Bizonyíték-kötelezettség:** Eredményeket `security-reports/latest/` útvonalról kell jelenteni.

## Adatbázis
- PostgreSQL (szerver), SQLite (offline kliens)
- Flyway migrációk: `backend/src/main/resources/db/migration/`
- Kapcsolat: `application.properties` → `spring.datasource.*`

## KÖTELEZŐ ÉRVÉNYŰ: V234 Belső log+audit modul (2026-05-18 user-direktíva)

> **Hatálybalépés:** 2026-05-18 (Kósa Zoltán direkt utasítása: "a saját programunkon belül, a saját kódjainkon és a saját exe-fájlainkon belül futó logolást szeretnék")
> **Vault session-jegyzet:** [vault/sessions/2026-05-18-internal-log-audit-module-build.md](vault/sessions/2026-05-18-internal-log-audit-module-build.md)
> **Hibakod-katalógus:** [packages/shared-logging/error-codes.yaml](packages/shared-logging/error-codes.yaml)

**A szabály:**

> MINDEN backend `LOG.error()` / frontend `vvLogger.error()` / Electron `vvLogger.error()` hívásban
> **KÖTELEZŐ** `error_code` paraméter (formátum: `VV-<KATEGORIA>-<3-jegyű>` — pl. `VV-AML-001`).
>
> Ha új hibatípust találsz a kódban → ELŐSZÖR add hozzá a hibakódot az
> `packages/shared-logging/error-codes.yaml`-hez `ai_fix_hint`-tel + `user_impact`-tel,
> CSAK UTÁNA írj `vvLogger.error("UJ-KOD", ...)` hívást.

**Architektúra:**
- **Logging:** `VVLogger` (backend) / `vvLogger` (frontend + 3 Electron kliens) — strukturált JSON output (Logstash encoder), MDC trace_id automatikus
- **Audit:** `AuditEventService.appendEvent()` — hash-chain SHA-256 (tamper-evidence), V234 audit_log tabla immutable trigger-rel
- **PII redactor:** Logback `%redact(%msg)` custom converter + frontend `redact()` recursive object scrubber — 7 pattern: OpenAI key, JWT, Bearer, email, IBAN, kártyaszám, magyar szig.szám
- **Diagnostics API:** `/api/v1/diagnostics/audit/{recent-errors,trace,entity,error-codes,hash-chain-verify,log}` — ADMIN/SUPPORT/MANAGER role
- **Admin UI:** `/admin/audit-diagnostics` route (frontend-react)

**Session-start kötelező olvasmány az AI-nak:**
- `packages/shared-logging/error-codes.yaml` (30 jelenlegi hibakód + AI fix hint)
- `vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md` (tervezet)

**Tilos:**
- ❌ `logger.error('hiba történt')` error_code nélkül (jelenlegi `logger.ts` legacy — fokozatosan migrálandó)
- ❌ Új error_code-ot kitalálni az error-codes.yaml-be való felvétel nélkül
- ❌ PII (jelszó, JWT, kártyaszám, magyar szig.szám) sima logba — a Logback redactor mindent moz, DE strukturált `attrs.*`-ban se logoljunk PII-t (defense-in-depth)
- ❌ audit_log UPDATE/DELETE — az immutable trigger doblja az exception-t (compliance: Pmt./NAV)

---

## Aktuális release-állapot (a következő agent számára folytatási horgony)
- **Verzió:** **v2.5.61** (2026-05-19 — Árfolyamkészítő HyperFormula cell engine + 6 valuta törlés + Currency Manager UI V238 audit-log [#697]).
- **v2.5.61 PR (admin-merged main-be 2026-05-19 12:05 CEST):**
  - **PR #697** (5 commit, merge commit `0660ff46c`): a Kósa Zoltán user-direktíva alapján az Árfolyamkészítő (arfolyam-keszito-client) Főlapját bővítjük 2 feature-rel + Currency Manager UI + audit-log:
    - **HyperFormula cell-engine (HIBA v2.5.61 #1):** A D oszlop kivételével minden cella formula-képes (`=A1*1.02`, `=A1+B1` típusú Excel-szerű képletek). HyperFormula v3.2.0 library (GPL v3, internal-use justification a `frontend-react/NOTICE.md`-ben). 6 user-editable oszlop képletes: A=settlement, B=otp, C=helper, E=weakMultiBuy, F=weakMultiSell, I=wholesale. Reaktív recompute (dependency-graph). FormulaMap state + localStorage persistencia.
    - **6 valuta törlés (HIBA v2.5.61 #2):** DKK, NOK, SEK, HRK, BGN, RCH eltávolítva a DEFAULT_CURRENCIES-ből (28 → 22 valuta). V237 Flyway: `UPDATE currency SET is_active=false WHERE code IN(...)` (NEM DELETE — Pmt./NAV 8-év megőrzés).
    - **Currency Manager UI (HIBA v2.5.61 #3):** Új admin modal a Rate-Maker Főlapról ("Valutakezelő" gomb, csak főértéktáros / ügyvezető / admin szerepkörnek). POST `/api/v1/currencies` (új valuta) + PATCH `/api/v1/currencies/{id}/active` (aktivál/deaktivál + indoklás). SOHA NEM DELETE — `is_active` flag váltás. V238 Flyway: `currency_audit_log` immutable tábla (UPDATE+DELETE trigger-tiltva, JSONB old/new snapshot, worker_id + ip_address + note). AdminCurrencyService + CurrencyAuditLogRepository + CurrencyManagerModal komponens.
    - **AI review fix-batch:** Codex P1 sync formula eval (a save/dispatch path placeholder 0 helyett `hf.calculateFormula` szinkron eval) + 5 Copilot P2 (PURE comment + saveLocally formulas deps + HF enrichedRows for cross-base + DetailedCellError → warn+toast keep-last + V237 GET DIAGNOSTICS ROW_COUNT) + CodeQL log-injection sanitize (`sanitizeForLog` helper az AdminCurrencyService.java-ban) + NOTICE.md GPL v3 internal-use justification.
- **v2.5.61 új P0 mandate:** **két ellenőrzési kör merge előtt** (vault/feedback/two-rounds-before-merge-mandatory-2026-05-19.md). CI gate + AI gate, mind zöld + 0 új P0/P1/P2 finding. PR #697 ezt **3 körön** végigvitte (P1 fix → CodeQL alert → CodeQL fix → minden zöld → merge).
- **Telepítő fájlok v2.5.61 (LEGFRISSEBB, 2026-05-19 UNSIGNED build)** — `installer/build/` + `kozponti-client/release/` + `arfolyam-keszito-client/release/` + másolva `%USERPROFILE%\Downloads\`-ba:
  - `Penztar-Setup-2.5.61-20260519.exe` — **282.66 MB** (296,391,264 byte), SHA-256 `18CF54A4F03D7762922731AE3FE31A850B5E4534DC5F63F27E67278CBC29AB1C`
  - `Kozponti-Iranyitokozpont-Setup-2.5.61.exe` — **101.05 MB** (105,953,515 byte), SHA-256 `ABA896563B70CC062C4EF5F80B3300FC98E6A3ADE4582256B9C2C3F2BDB5C533`
  - `Arfolyamkeszito-Setup-2.5.61.exe` — **101.04 MB** (105,953,283 byte), SHA-256 `8E8545DBAFF25FBAF8BC474902CF58E0EA823AEA3B1B786419B072D762CF803D`
  - `Penztar-Eltavolito-2.5.61-20260519.exe` — **59.43 KB** (60,858 byte), SHA-256 `D5BF7315BCEF2AC21BB32C1F7E3BF31E45B5D3A18766BBD728937709354C9B6C`
  - **UNSIGNED build** — DigiCert EV CS cert kiadásig SmartScreen "További információ" → "Futtatás mindenképp" szükséges.
- **Korábbi verzió:** v2.5.60 (2026-05-19 — Fabulya Zsuzsanna 18+1 user-bug B-kategória atomikus fix-batch [#695]).
- **v2.5.60 PR (admin-merged main-be 2026-05-19 12:52 CEST):**
  - **PR #695** (37 fájl, +2066 / -120 LOC, 7 commit, merge commit `28d7c70d`): a Fabulya Zsuzsanna kollégánő által 2026-05-19-én jelentett B-kategória **8 hibájának atomikus javítása** + 2 Codex P1 + 12 Copilot P2 finding fix:
    - **HIBA #10** (BUY HUF készlet): `CashierTransactionPage.tsx` client-side prevalidation BUY módban is fut (mode==='buy' || 'sell' guard) + a fee és kerekítés levonva a backend-egyenértékű totalHufPayable-ből.
    - **HIBA #12** (SIMPLIFIED okmány): `CustomerPanel.tsx` `{showFull && ...}` guard a okmány típus + szám mezőkre — csak FULL módban (300k+) mutatja, SIMPLIFIED-nél (100-300k) eltűnik.
    - **HIBA #13** (Ügyfél nem rögzíthető — "Belső szerverhiba"): **V236 Flyway migration** — `customer.nationality` és `transaction.customer_nationality` VARCHAR(3) → VARCHAR(100), mert a frontend "Magyar" / "EU-állampolgárság" / "Egyéb" humanreadable szöveget küld, ami a V3-as VARCHAR(3)-ba nem fért bele → HTTP 500 `value too long`. Customer + Transaction entity `length=100`.
    - **HIBA #14** (bizonylet hiányos szül.hely/idő/anyja neve): teljes Electron data-flow refaktor — `penztar-client/electron/sqlite.ts` schema bővítve 16 customer-snapshot oszloppal, új `savePendingTransactionV2` objektum-paraméteres API + `save-pending-transaction-v2` IPC channel + `sync-engine.ts` POST body bővítés.
    - **HIBA #15** (PEP minőség): új `PepKind` enum (6 érték: CSALADTAG/KOZELI_MUNKATARS/KORMANYFO/PARLAMENTI/NAV_VEZETO/EGYEB) + **V235 Flyway migration** `customer_pep_kind VARCHAR(50)` + CHECK constraint + ReceiptGeneratorService `buildPepStatusText()` kategória-specifikus szöveg + CustomerPanel 7-utas dropdown.
    - **HIBA #17** (más nevében actor azonosítás): V235 7 új actor mező (`customer_actor_birth_place/birth_date/mother_name/nationality/document_type/document_number/address`) + ActorPanel inline UI a CustomerPanel-ben + validáció (`!onOwnBehalf` → mind a 6 mező + actorName kötelező) + `EscPosReceiptService` rendereli az actor adatokat a bizonylatra.
    - **HIBA #18** (bizonylet "saját nevében" hibás): `customer_on_own_behalf` flag plumbing az Electron pathon — a sync-engine actor-guard csak `customer_on_own_behalf === 0` esetén küldi át.
    - **HIBA #19** (Konverzió Pmt. — új user-direktíva): `ConversionRequestDto` + `TransactionConversionService.executeConversion` bővítve 14 új customer-snapshot mezővel + `ConversionPage.tsx` CustomerPanel integráció `hufAmount >= 100k` esetén + Electron offline plumbing teljes szinten: `pending_conversions` schema 18 új oszlop + `savePendingConversionV2` + `save-pending-conversion-v2` IPC + `syncConversion` POST body + ConversionPage Electron path payload (17 mező + actor identity).
    - **Codex P1 #1** (PEP enforcement): `validatePmtComplianceFields()` 300k+ tranzakcióknál + új `PMT_STRICT_ENFORCEMENT` SystemParameter feature-flag (default `false` v2.5.59 kompat, v2.5.61+ default `true` → `ValidationException`).
    - **Codex P1 #2** (Conversion Electron Pmt. plumbing): 5-layer fix (sqlite + savePendingConversionV2 + IPC + saveAndSync + sync-engine + ConversionPage Electron path).
    - **Copilot P2 (12 finding):** @Pattern regex empty string fix (3 DTO), BUY HUF check handling fee subtract, sync-engine actor guard, CustomerPanel actorName guard, 4-way version sync (kozponti + arfolyam + 5 lockfile packages[""] entry), ReceiptPdfService actor render (EscPosReceiptService extend), CashierTransactionPage actor stale data.
    - **CI fix**: `PepSourceOfFundsTest` NPE — defensive null-check a `systemParameterService`-re a `validatePmtComplianceFields`-ben (mockolt teszt-kontextus).
- **Korábbi verzió:** v2.5.59 (2026-05-19 — overnight PR marathon 4 PR: Hangsegéd unified mode UI + 422 friendly errors + flaky test [#689] + SetupWizard integration test rate-limit defensive [#690] + Copilot DTO enum follow-up [#691] + Codex P1 cause-chain bug iter2 [#692]).
- **Korábbi verzió:** v2.5.58 (2026-05-18, 3 PR: V234 DailyClosingService logger phase 2 [#685] + SetupWizard értéktáros Google OAuth [#686] + Rate-Maker EXE central server connection [#687]).
- **v2.5.59 PR-ek (admin-merged main-be 2026-05-19 overnight session):**
  - **PR #689** Hangsegéd unified mode + size reduction + 422 friendly errors + flaky test fix: a Kósa Zoltán direktíva alapján a 3 mode-gomb (Telepítés/Tesztelés/Hibajelzés) helyett egyetlen "Beszélgetés indítása" gomb, panel w-72 → w-56, VoiceTokenError + VOICE_ERROR_MESSAGES map. Plus issueStore race-condition fix.
  - **PR #690** SetupWizard integration test rate-limit defensive: HTTP 429 elfogadás 400 mellett (production bot-protection).
  - **PR #691** Copilot #689 follow-up: DTO `String mode` + `@Pattern` → `VoiceAssistantMode` direkt típus, VOICE_MODE_LABEL map, 3 új 422-mapping unit teszt.
  - **PR #692** Codex P1 cause-chain bug fix + iter2: a `VoiceAssistantMode.fromWireName()` IllegalArgumentException → Jackson `ValueInstantiationException` (NEM InvalidFormatException) — hármas cause-chain detekció a GlobalExceptionHandler-ben. `@JsonValue` reflection + `Locale.ROOT` az enum-wire-name lista képzéséhez. 9 új RTL teszt + 3 új handler-bizonyíték teszt + 7 új enum-kontrakt teszt. Backend 1400/1400 PASS, frontend voice 72/72 PASS.
- **v2.5.58 PR-ek (admin-merged main-be 2026-05-18):**
  - **PR #685** (V234 audit phase 2): DailyClosingService 10× `log.error()` → `VV_LOG.error()` migráció (VV-BIZ-006..010 hibakódok), HashMap null-guard pattern terminal_id-re (Codex P2 NPE fix), 30 → 41 error code error-codes.yaml-ben (VV-VOICE-004/005, VV-TECH-003/004, VV-AML-004, VV-SYNC-004, VV-BIZ-006..010).
  - **PR #686** (SetupWizard értéktár Google OAuth): Step 4 ServerStep új props (appMode, googleAuthSetupReady, googleSetupWorker), 3-way conditional render (pénztáros dropdown / Google OAuth info card / Back-to-Step-1 hint). Bug fix: értéktár alkalmazottak Google email-ükkel léphetnek be NEM pénztáros-dropdown via.
  - **PR #687** (Rate-Maker thin client architecture, Kósa Zoltán directive): Árfolyamkészítő EXE NEM standalone hanem `central server` thin client. `serverSnapshotRef` pattern diff-based publishing-hez (csak változott sorok push-olva, threshold 0.0001), in-flight edit preservation (dirty flag → mount-sync overwrite-elkerülés), `exchangeRateMasterApi.create()` endpoint, V234 8 review finding fix egy commitban (1c5e0849e: Sourcery offline fallback, Sourcery localStorage vs network 2-try, Copilot all-row anti-pattern).
- **Hangsegéd (Voice Assistant) feature rollout (2026-05-18 session):**
  - **15 PR mergelve a main-be:** Phase 1 [#654], Phase 2 [#659], Phase 3 [#660], Phase 4 [#661], Phase 5 [#672], Phase 6 [#673], Phase 7 [#674], Phase 8 [#675], Phase 9 [#676], Phase 9.5a [#668], Phase 9.5b [#677], Phase 10 [#667], + #669 (lint scope), #670 (code-signing docs Sectigo→DigiCert pivot), #671 (vault PII redact).
  - **Hetzner backend env:** `OPENAI_API_KEY` + `VOICE_OPENAI_ENABLED=true` beállítva a `set-voice-assistant-env.yml` workflow-val. Backend restartolt, bootstrap-status 200.
  - **Frontend build-flag:** `VITE_VOICE_ASSISTANT_ENABLED=true` beépítve a v2.5.57 buildek-be. A lebegő Hangsegéd Panel jobb-alsó sarokban jelenik meg.
  - **OpenAI Realtime API:** `gpt-realtime-2` (~$0.06-0.08/min audio, shimmer voice, gpt-realtime-whisper transcription).
  - **Költségvédelem:** per-worker rate-limit 10 ephemeral-token-keres / ora (configurálható env-flag).
  - **Adatvédelem:** issueStore IndexedDB lokálisan, master OPENAI_API_KEY csak backend-en, ~60s ephemeral client_secret WebRTC-hez.
- **Telepítő fájlok v2.5.60 (LEGFRISSEBB, 2026-05-19 UNSIGNED build, B-kategória fix-batch)** — `installer/build/` + `kozponti-client/release/` + `arfolyam-keszito-client/release/` + másolva `%USERPROFILE%\Downloads\`-ba:
  - `Penztar-Setup-2.5.60-20260519.exe` — **282.49 MB** (296,209,523 byte), SHA-256 `73FB0C895CA32039E18CF54A5C99A56BD9824B422AD3FCB6B899D795ADCB9E41`
  - `Kozponti-Iranyitokozpont-Setup-2.5.60.exe` — **100.94 MB** (105,838,732 byte), SHA-256 `BABDA2014630BA23E48FFC0407F4F0553C981F8661F57A6F59FFC0C4F8A9D5A8`
  - `Arfolyamkeszito-Setup-2.5.60.exe` — **100.94 MB** (105,838,352 byte), SHA-256 `CBBFB876C3078C8489234BAA00046C1FA16E70B9521D59475BB87234A9335D31`
  - `Penztar-Eltavolito-2.5.60-20260519.exe` — **59.43 KB** (60,859 byte), SHA-256 `F4D64FDFF13CFD8AFA13868D5199C7E146A931C4D420A9A0031036198896950F`
  - **UNSIGNED build** — DigiCert EV CS cert kiadásig (vár Q&A validation 2026-05-19 13:00+) a SmartScreen "További információ" → "Futtatás mindenképp" lépés szükséges.
- **Telepítő fájlok v2.5.59 (előző UNSIGNED build, 2026-05-19 overnight)** — `installer/build/` + `kozponti-client/release/` + `arfolyam-keszito-client/release/` + másolva `%USERPROFILE%\Downloads\`-ba:
  - `Penztar-Setup-2.5.59-20260519.exe` — **282.51 MB** (296,232,003 byte), SHA-256 `F43F22C5CB6142A784690FF6E722D18CF52BEA4E7C9224E54BE68E8EF0CB59F6`
  - `Kozponti-Iranyitokozpont-Setup-2.5.59.exe` — **100.93 MB** (105,836,915 byte), SHA-256 `D4BD4294D273F2D16E2B83A606BE24AC7B970742F522D9AFA504E733D08797AE`
  - `Arfolyamkeszito-Setup-2.5.59.exe` — **100.93 MB** (105,836,844 byte), SHA-256 `9448829F1EF3DF73F925B9E0A76CAAAD3C885F3C5CB95B92FFE3A5505AA53C65`
  - `Penztar-Eltavolito-2.5.59-20260519.exe` — **59.43 KB** (60,856 byte), SHA-256 `2975720118FD92D3975A68464DE8851A9FA485D206D9D326AFC78095D147903C`
  - **UNSIGNED build** — DigiCert EV CS cert kiadásig (kedd 2026-05-19 13:00 CEST verifikációs call) a SmartScreen "További információ" → "Futtatás mindenképp" lépés szükséges. A v2.5.60+ SIGNED release a cert kiadás után.
- **Telepítő fájlok v2.5.58 (előző UNSIGNED build, 2026-05-18)** — 3 PR feature/fix-set:
  - `Penztar-Setup-2.5.58-20260518.exe` — 282.57 MB, SHA-256 `1B4F8A6ECD447FFC93C8D6C675D88724F5ED4981EB71699821545D164A468998`
  - `Kozponti-Iranyitokozpont-Setup-2.5.58.exe` — 100.93 MB, SHA-256 `163B79F1CD0045141E3AFF7A9F3ECD28EFC7C942DE843F1AD0C20792B8BECD28`
  - `Arfolyamkeszito-Setup-2.5.58.exe` — 100.93 MB, SHA-256 `F0BE00BE1061064F1CC608A6828B9647D1D6DD6E9BCBEC9B4BDF5FF3361B09B0`
  - `Penztar-Eltavolito-2.5.58-20260518.exe` — 59.43 KB, SHA-256 `F4DA648B0D1A8B3BE6C333E1B1546D2547E5ED9FFBB9A1AF012F81E2EFF28270`
- **Telepítő fájlok v2.5.57 (előző UNSIGNED build, 2026-05-18)** — Hangsegéd MVP rollout:
  - `Penztar-Setup-2.5.57-20260518.exe` — 280.94 MB, SHA-256 `E55E2D390688FE2B1F3CB947253D89B7D59203E63B3E7E72F24EA93198F13600`
  - `Kozponti-Iranyitokozpont-Setup-2.5.57.exe` — 100.93 MB, SHA-256 `7C1CBB4546A061EDD14B3A2544CF69D797DD8319B354E1721D412B883C658CC0`
  - `Arfolyamkeszito-Setup-2.5.57.exe` — 100.93 MB, SHA-256 `BB86BA566754BB2C60846A99B2DDBC70632AEB79FE968D6317BA030BE43603D0`
  - `Penztar-Eltavolito-2.5.57-20260518.exe` — 60.86 KB, SHA-256 `AB97665C134EF1DBB67CB1DE59582191E3678B2441BC4A572AB7154E961ED597`
- **Verzió:** v2.5.53 [előző] (2026-05-15 — 10 felhasználói bug + production hotfix-ek + BALI/W-S011/Google OAuth lezárva, mind admin-merged a main-be).
- **Backend stack (2026-04-29 SB4 sprint óta):** **Spring Boot 4.0.6** + **Tomcat 11.0.21** (Servlet 6.1) + **Jackson 2 stop-gap** (`spring-boot-jackson2` modul + `JacksonConfig.java` programmatic `@Primary @Bean ObjectMapper` `Jackson2ObjectMapperBuilder.json().modulesToInstall(...)` mintával) + **springdoc 3.0.3** + **flyway-database-postgresql 12.4.0** (flyway-core 12.x SB4 BOM-ból). 1009/1009 mvn test PASS, Hetzner production deploy SUCCESS (3× verifikálva).
- **Main HEAD:** `1217cf08` (PR #266: modulesToInstall extend mode, 2026-04-29).
- **Production:** Hetzner deploy SUCCESS minden mergelt PR után, bootstrap-status 200, V155..V167 applied.
- **2026-04-29 marathon (13 PR mergelve, 0 outage, rekord-session):**
  - **A+B+C ciklus (#254-262, 9 PR):** CLAUDE.md cleanup, V166 silent reactivation fix, V167 BASE TABLE defensive, eslint 10 + Node engines >=20.19.0, react 18→19.2.5 (mind a 4 csomag), MIGRATION_NOTES.md doc, V3_7 sync claim correction, V109 multi-step responsibilities, MIGRATION_NOTES.md final polish (best practices section). 7 ciklusos AI review fix-loop CONVERGED.
  - **SB4 sprint (#263-266, 4 PR):** Spring Boot 3.5.13→4.0.6 (#263), Tomcat 10.1.54 override eltávolítva → BOM default 11.0.21 (#264), JacksonConfig builder + MIGRATION_NOTES.md domain-claim fix (#265), modulesToInstall extend mode (#266). 04-27-i Jackson 3 enum bind outage gyökér-oka **megszüntetve** (3 problematic property kivéve + programmatic ObjectMapper).
- **2026-04-27 marathon (15 PR + 2 hotfix):** PR #237 (docs), #238 (audit-NO-GO-iter3), #242 (CodeQL 9 medium Actions hardening), #243 (CodeQL 11 HIGH frontend file-system-race), #244 (CodeQL 5 HIGH backend path-injection), #245 (149 java/log-injection logback `%replace`), #240 (electron 41.3 + types/sql + ts-eslint MINOR), #239→#246 (flyway-postgres 12.4 → revert 10.10.0, production outage #1), #207 (lucide-react 1.x), #241 (react-hooks penztar), #210 (react-hooks 7 frontend), #208 (typescript-eslint 8.59), #205→#247 (Spring Boot 4.0.6 → revert, production outage #2).
- **2026-04-28 (audit-iter5 + release):** PR #251 (audit-iter5 Codex P1×2), PR #252 (release v2.3.6), PR #253 (V165 guard).
- **Telepítő fájlok v2.3.7 (LEGFRISSEBB, 2026-04-29 SB4 + Tomcat 11 stack)** — `installer/build/` + másolva `%USERPROFILE%\Downloads\`-ba:
  - `Penztar-Setup-2.3.7-20260429.exe` — **280.1 MB** (293,705,333 byte), SHA-256 `230a4c540b2b78b8a9d201face5aa701a2691e02a9263ad9028c237f74dcecbf`
  - `Penztar-Eltavolito-2.3.7-20260429.exe` — **59.05 KB** (60,468 byte) — verzió-független NSIS uninstaller (megegyezik a 2.3.6-tal)
  - **Backend stack a installerben:** Spring Boot 4.0.6 + Tomcat 11.0.21 + Jackson 2 stop-gap + springdoc 3 + flyway 12.4 + JacksonConfig.java
  - **Build parancs:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 -SkipDownloads` (logok: `C:\Temp\installer-build-2026-04-29.log`)
- **Korábbi telepítők** (régi stack, ne használd v2.3.7 helyett):
  - v2.3.6: `Penztar-Setup-2.3.6-20260428.exe` 276 MB (SB 3.5.13 + Tomcat 10.1)
  - v2.3.2: `Penztar-Setup-2.3.2-20260425.exe` 441 MB (SB 3.5 + bundled JBR)
  - GitHub Release: https://github.com/kosazoltan/valutavalto-program/releases/tag/v2.3.2
- **Újra-buildelés:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 [-SkipDownloads]`. A `$Version` PARAMETER auto-load a monorepo root `package.json`-ból (PR #103 + #104 `build-common.ps1` helperrel).
- **NSIS encoding szabály:** `.nsi` csak Windows-1252 ASCII. Ékezetek → sima ASCII. Em-dash → `-`.
- **Aktuális memória helye:** `D:\repo\valutavalto-program\vault\sessions\2026-04-29-*.md` (Obsidian vault: multi-track-execution + track-4-spring-boot-4-sprint). A `docs/knowledge/memory/*.yaml` történelmi formátum, új session-jegyzetek a vault-ba kerülnek.
- **Asztali shortcutok** (`C:\Users\Kósa Zoltán\OneDrive\Desktop\`): `Valuta Pénztár — Fejlesztői mód (INDÍTÁS).lnk`, `Valuta Pénztár — Fejlesztői mód (LEÁLLÍTÁS).lnk`, `Valuta Pénztár — Éles kliens (telepített).lnk`.
- **AI review automation:** `.github/workflows/ai-review-auto-fix.yml` minden PR merge után triggerel. Sourcery weekly rate-limit (1.5M diff char) — nem blokkoló. A Bence-féle `.github/workflows/auto-review.yml` 2026-04-27 óta törölve.
- **Production URL SSOT (BEFEJEZVE):** `config/production-urls.json` + `backend/.../config/ProductionUrls.java` + `scripts/_production-urls.ps1` + Electron `penztar-client/electron/main.ts` `loadProductionUrls()` + `electron-builder.json` extraResources. Lazy-load minden komponensben.
- **Jackson 3 future migration**: a `spring-boot-jackson2` stop-gap modul + `JacksonConfig.java` programmatic ObjectMapper csak átmeneti megoldás. Egy nagyobb refaktor PR-ben (külön sprint) a 39 fájl `com.fasterxml.jackson.*` → `tools.jackson.*` import-migráció OpenRewrite recipe-pal, ObjectMapper API breaking changes javítás. Akkor: a `spring.jackson.use-jackson2-defaults=true` + a `JacksonConfig.java` törölhető.
- **Nyitott következő feladatok (2026-05-15 állapot):**
  - **P0.1 (éles pénztár frissítés v2.5.53 — NON-SIGNED):** user reinstall a pénztáros gépeken. Telepítő: `C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.53-20260515.exe` (281 MB, **unsigned** — SmartScreen "További információ" → "Futtatás mindenképp"). SHA-256: `7e358a265d630ec875a22bfaa57b033aec4d136a18a96316529856a5b0ae868f`. Eltávolító: `Penztar-Eltavolito-2.5.53-20260515.exe` (60 KB, SHA-256 `f9143d49c97a5cca1e6eae55030cec56cc37b85fbc96ebb3003d017e6918d253`).
  - **P0.2 (központi munkaállomás első telepítése v2.5.53 — NON-SIGNED):** **ÚJ** kliens! `Kozponti-Iranyitokozpont-Setup-2.5.53.exe` (101 MB, SHA-256 `3284e2d2cd34ed537dc8babc4ef6f892ca795c3e452585cb32a96997c9e42b0e`) — főértéktáros gépén kerül telepítésre először. appMode=`full`, route=`/central-workstation`, heading "Központi irányítóközpont".
  - **P0.3 (RFM kliens első telepítése v2.5.53 — NON-SIGNED):** **ÚJ** kliens! `Arfolyamkeszito-Setup-2.5.53.exe` (101 MB, SHA-256 `91dd1c6ba0f38179f156bace36e98c0339fbb8a755001127dd37848363d5a1e4`) — főértéktárosi gépen kerül telepítésre. appMode=`rate-maker`, route=`/rates/creation`.
  - **P1.1 (Drill 1 live):** Vasárnap 2026-05-17 04:00 CEST scheduled routine (trig_01WpU5Vts7DnXE2d4XSnnW5Q) readiness check-et csinál + checklist. Vagy manuálisan: `gh workflow run scaleway-failover-drill.yml -f drill_level=1 -f dry_run=false`.
  - **P1.2 (happy path teszt v2.5.53):** Fejlesztői mód INDÍTÁS shortcut → SetupWizard 4. lépés Kapcsolat tesztelése gomb (`connectionTest.state=ok`) → új VÉTEL → bizonylat `V<3-jegyű>000001`. Plus: 100k+ tranzakció → ellenőrizni hogy a bizonylaton szül.hely/szül.idő/anyja neve megjelenik; 300k+ → PEP/saját-név kérdés panel megjelenik.
  - **P1.3 (DigiCert EV CS validation):** vár phone callback (+36 70 380 0202) + cégkivonat/aláírási minta + video verif call. 3-5 nap. Részletek: `vault/sessions/2026-05-15-digicert-hsm-approval.md`.
  - **P1.4 (cert kiadás utáni signed v2.5.54 release):** `az keyvault certificate pending merge --vault-name kv-valuta-codesign --name valuta-codesign-cert --file <cer>` + `gh workflow run windows-signed-release.yml -f version=2.5.54 -f publish_release=true`.
  - **P2.3 (Drill 2 + Drill 3):** Drill 1 sikeres után, alacsony forgalmú időszakban. DNS swap 5 percre + adatvesztés mérés.
  - **P2.4 (Cloudflare Load Balancer):** Auto-DNS failover (~14 USD/hó). CF Load Balancer beállítás Hetzner-Scaleway origin pool-lal.
  - **P2.5 (UptimeRobot monitoring):** 5 percenként health-check + email/SMS riasztás 5xx esetén.
  - **P3.1 (Jackson 3 migráció — long-term):** 39 fájl `com.fasterxml.jackson.*` → `tools.jackson.*` import csere OpenRewrite-tal. A `spring-boot-jackson2` stop-gap + `JacksonConfig.java` törölhető utána.

**LEZÁRVA 2026-05-14-i sessionben:** ✅ PR #564 P2.1 cashier custom-rate kvóta backend enforcement (Codex P1 #562) + PR #565 P2.2 foreignStatus String→Enum (Copilot finding) + PR #579 per-session quota decrement, ✅ PR #581 rate-maker főlap MVP (28 valuta, A-I oszlopok, kereszt-árfolyam) + PR #584 CustomerPanel UX (100k HUF hint), ✅ PR #586 AML local-first degradált mód + PR #587 per-item devizastátusz + V226 + PR #588 GOOGLE_DESKTOP_CLIENT_ID multi-érték, ✅ v2.5.51 4-way version bump (#589 + cca7ba6da), ✅ PR #582-#583 local-first shared core + outbox retry fix, ✅ 8-PR autonomous mode Azure Key Vault Premium HSM signing infra (#591-#600: workflow YAML, sign hook, EXZ integráció, jlink --compress 2 fix, longpaths checkout fix).

**LEZÁRVA 2026-05-15-i hosszú sessionben (14 PR, 10 felhasználói bug + 4 infra hotfix):**

🐛 **User-jelentett 10 bug fix:**
- HIBA #1 (transfer dropdown üres) → PR #606
- HIBA #2 (BranchPage admin értéktár/TH/főpénztár) → PR #611 (DictionaryController + form bővítés)
- HIBA #3 (negatív készlet vételhez) → PR #605
- HIBA #4 (foreignStatus K/B) → kód már a main-en, csak verify v2.5.53+ telepítés után
- HIBA #5 (100-300k bizonylat hiányzó szül.hely/idő) → PR #612+#613+#614
- HIBA #6 (SIMPLIFIED ID-nél okmány) → PR #605
- HIBA #7 (300k+ bizonylat hiányos) → PR #612+#613+#614
- HIBA #8 (PEP/saját-név kérdés tranzakció közben) → PR #614 (300k+ panel)
- HIBA #9 (ügyfél nem rögzíthető) → PR #607 (idempotens upsert + valódi error toast)
- HIBA #10 KIEMELT (kezelési költség nem rögzíthető — 2 napos hamis "kész") → PR #605 V227 + PR #610 hotfix sync_active_columns()

🚨 **Production OUTAGE + recovery + infrastruktúra:**
- V228 (BALI worker reaktiválás + 7 role mind BALI-ra mind W-S011-re) → PR #608
- Google OAuth userData/.env betöltés mindhárom Electron kliensben (penztar + kozponti + arfolyam) → PR #608
- V227 production deploy fail: sync_active_columns() function nem létezett → PR #610 defensive CREATE OR REPLACE + Flyway repair step a deploy workflow-ba
- Backend HTTP 502 outage → recovered HTTP 200

🔐 **Code Signing track (track 4):** Sectigo OV CS cancel + store credit $659.97 (NEM Azure-kompat — Microsoft Q&A: KV HSM nincs key attestation) → DigiCert EV CS Azure-native order ($559.99, store credit fedezi, $99.98 maradó), ✅ DigiCert HSM Approval form SUBMITTED 09:55 CEST (Azure Key Vault Premium HSM elfogadva — "audited cloud (e.g., Azure or AWS)"), ✅ vault sessions #601 + #602 + auto-memory project_codesigning_pivot_digicert_ev_2026_05_15.md + QMD/YAML memory (PR #603), ✅ **3 unsigned installer build v2.5.51** (Penztar-Setup 281 MB + Kozponti 101 MB + Arfolyamkeszito 101 MB + Eltavolito 60 KB, mind Downloads/-ban SHA-256-tal), ✅ installer-validation-suite-v2.5.51.ps1 acceptance test script + non-invazív smoke-test 4 fájlra (file version metadata + size OK), ✅ CLAUDE.md "Nyitott feladatok" frissítés (P2.1+P2.2 lezárt status, P1.3+P1.4 új DigiCert validation track).

**LEZÁRVA 2026-05-13-i sessionben:** ✅ v2.5.48 → v2.5.49 release (PR #562, V211 production crash fix + bizonylat admin UI + transfer P1 + Playwright redirect), ✅ Scaleway DEV1-S → DEV1-M resize (2 GB → 4 GB), ✅ Scaleway v2.5.49 JAR rebuild + Google OAuth env vars, ✅ 3 telepítő build (Penztar + Kozponti + Arfolyamkeszito mind 2.5.49), ✅ Scaleway failover runbook 8 fejezet + GitHub Actions workflow (Drill 1/2/3 szintekkel), ✅ Cloudflare DNS:Edit token + 5 GitHub Secret setup, ✅ Redis Scaleway-en telepítve (warm), ✅ 4 memóriarendszer rendrehozás (QMD 5 valutavalto kollekció + YAML + Cognee + Vector), ✅ Windows QMD shim + HOME=USERPROFILE fix patch-package-szerű auto-apply-jel.

**LEZÁRVA 2026-05-01-i sessionben:** ✅ v2.5.0 outage rollback + atomi v2.5.1 re-do (5 PR #338-#343 mind production-on), ✅ v2.5.2 installer build, ✅ Stale remote branch cleanup (3 db törölve, 0 maradt), ✅ CodeQL Actions hardening (PR #242 már 04-27-én lezárta — listáról törölve), ✅ Utolsó nyitott CodeQL alert dismissed (#188 java/log-injection PublicBranchController:98 → false positive, logback %replace pattern globálisan stripeli a CRLF-et).

**LEZÁRVA 2026-04-29-i sessionben:** ✅ Spring Boot 3.5.13 → 4.0.6 (PR #263, sprint), ✅ Tomcat 10.1.54 → 11.0.21 (PR #264), ✅ JacksonConfig builder + modulesToInstall (PR #265+#266), ✅ springdoc 3.0.3 (#263 unified, #196 dependabot zárta automatikusan), ✅ eslint 9.39 → 10.2.1 + Node engines >=20.19.0 (PR #256), ✅ react 18 → 19.2.5 (PR #257, mind a 4 csomag, peer-dep skew elhárítva), ✅ V166 silent reactivation + V167 BASE TABLE defensive migrationok (PR #255, #258), ✅ MIGRATION_NOTES.md dokumentálás (V3_5+V33+V3_7+V109+V166+V167), ✅ playwright.live testMatch full-menu spec (PR #255).

**LEZÁRVA (korábbi sessionekben):** ✅ Issue #110 cash_balance (2026-04-27), ✅ V155 migration (2026-04-24), ✅ CB-016 NavClosingService VAT_RATE → tax_code mapping (V143 + SystemParameter), ✅ Production URL SSOT teljes 3-réteg refaktor (PR #173 + #174), ✅ Cognee MCP / Obsidian vault sync (`D:\repo\valutavalto-program\vault\` aktív 2026-04-27 óta).
