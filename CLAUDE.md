# Valutaváltó ERP — Claude Code kontextus

> ## AI_CONSTITUTION.md (ELSO PRIORITAS)
>
> **Minden AI-ugynok** (Claude, OpenAI Codex, Sourcery, Gemini) **KOTELEZOEN olvassa be az `AI_CONSTITUTION.md`-t** a repo gyokerben, mielott barmit csinal. Az ott leirt **10 nem-alkukepes szabaly + 7 tiltas + 7 reteg architekturara + erettsegi modell (L2)** feluliria a jelen `CLAUDE.md` minden reszet, ha konfliktus van.
>
> **Aktualis erettsegi szint**: **L2** (TDD + audit log + CI gate-ek + AI review automation).
>
> **Hatalyba lepes**: 2026-04-24 — a *Uj AI mukodesi alapelvek: implementacios kezikonyv* (Kosa Zoltan user-direktiva) alapjan.

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

## KÖTELEZŐ ÉRVÉNYŰ: Session memory workflow
**Minden session elején** olvasd be:
1. `.remember/remember.md` — rövid handoff az előző session-től
2. `docs/knowledge/memory/*.yaml` — részletes session-enkénti memory (legfrissebbet)
3. `docs/knowledge/memory/*.qmd` — ugyanaz Quarto formátumban
4. `C:\Users\Kósa Zoltán\.claude\projects\D--repo-valutavalto-program\memory\MEMORY.md` — globális memory index (Claude runtime)
5. `docs/LESSONS_LEARNED.md` — korábbi hibák, amiket NE ismételj

**Minden session végén** (új session előtt) mentsd:
1. YAML → `docs/knowledge/memory/YYYY-MM-DD-session-name.yaml`
2. QMD → `docs/knowledge/memory/YYYY-MM-DD-session-name.qmd`
3. Cognee (MCP) → amint elérhető (TODO)
4. Obsidian vault → amint telepítve (TODO)
5. `.remember/remember.md` — rövid handoff (remember skill)
6. CLAUDE.md "Nyitott következő feladatok" → frissítés

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
**EZENTÚL (MEGSZÜNTETVE a bemásolgatás):** minden PR push után az **agent MAGA** futtatja:
```bash
gh api "/repos/kosazoltan/valutavalto-program/pulls/$PR/reviews" --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) | {reviewer:.user.login,state,body}'
gh api "/repos/kosazoltan/valutavalto-program/pulls/$PR/comments" --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) | {user:.user.login,path,line,body}'
```

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

## Aktuális release-állapot (a következő agent számára folytatási horgony)
- **Verzió:** **v2.2.4** (2026-04-24 hotfix). Minden modul egységesen 2.2.4-n. GitHub Release: https://github.com/kosazoltan/valutavalto-program/releases/tag/v2.2.4 (2 assets uploaded).
- **Main HEAD:** `6fd63cb8` (release: v2.2.3 — version bump + CHANGELOG, 13 PR aggregate, PR #177).
- **Mai 9 merge (2026-04-24):** PR #172, #173, #174, #175, #176, #177, #178, #179 (AI constitution), #180 (shipment fix), #181 (v2.2.4 release).
- **Telepítő fájlok v2.2.3** (gitignore-osak, `installer/build/`-ban + másolva `%USERPROFILE%\Downloads\`-ba):
  - `Penztar-Setup-2.2.3-20260424.exe` — **273.59 MB**, SHA-256 `C52663EFA7A3EE5BB0B9ECDFD46D7F63B10F8D966C7B2A334972EBBD67148145`
  - `Penztar-Eltavolito-2.2.3-20260424.exe` — **58.47 KB**, SHA-256 `9B492A38443C87BF6D095224B1E312A0CA1DD1D090A5527A0B6ED2C420A06B02`
  - GitHub Release artifact-ok feltöltve 2026-04-24 12:32 UTC.
- **Újra-buildelés:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 [-SkipDownloads]`. A `$Version` PARAMETER most auto-load a monorepo root `package.json`-ból (PR #103 + #104 `build-common.ps1` helperrel).
- **NSIS encoding szabály:** `.nsi` csak Windows-1252 ASCII. Ékezetek → sima ASCII. Em-dash → `-`.
- **Memory fájlok a v2.2.3 release-hez:** `docs/knowledge/memory/2026-04-24-cash-balance-issue110-v155-closure.yaml` + `.qmd`. `.remember/remember.md` frissítve v2.2.3-mal.
- **Asztali shortcutok** (`C:\Users\Kósa Zoltán\OneDrive\Desktop\`): `Valuta Pénztár — Fejlesztői mód (INDÍTÁS).lnk`, `Valuta Pénztár — Fejlesztői mód (LEÁLLÍTÁS).lnk`, `Valuta Pénztár — Éles kliens (telepített).lnk`.
- **AI review automation:** `.github/workflows/ai-review-auto-fix.yml` minden PR merge után triggerel. A kötelező gyűjtő-script minta: `for pr in 97 98 100 101 102 103 104; do gh api "/repos/kosazoltan/valutavalto-program/pulls/$pr/reviews"; done`. PR #104 ezzel 7 hibát javított.
- **Production URL SSOT (v2.2.3-ban BEFEJEZVE):** `config/production-urls.json` + `backend/.../config/ProductionUrls.java`. PR #173 (2026-04-24): teljes 3-réteg propagáció: backend `List.of(...)` -> `ProductionUrls.BASE_URL`, `scripts/_production-urls.ps1` helper, Electron `main.ts` `loadProductionUrls()` + `electron-builder.json` extraResources.
- **Nyitott következő feladatok (2026-04-22 ota, friss session utan):**
  - **P0 (éles pénztár frissítés):** user v2.1.7 reinstall az éles gépen — 1) `Penztar-Eltavolito-2.2.3-20260424.exe` admin joggal, 2) `Penztar-Setup-2.2.3-20260424.exe` admin joggal, 3) SetupWizard 5 lépés (Iroda → Program típus → Szerver (**Kapcsolat tesztelése** gomb kötelező!) → Admin jelszó → Telepítés), 4) belépés a bootstrap admin credentials-szel (ld. setup wizard SetupWizard 4. lepes + 1Password/secure vault), 5) új VÉTEL teszt → bizonylat formátum: `V<3-jegyű-numerikus-kód>000001` (pl. `BR035` branch-en `V035000001`, `BR017` branch-en `V017000001`). A prefix a `branch.code` numerikus része `% 1000`-rel (3 jegyűre paddelt) — ld. `ReceiptSequenceService.extractBranchCode()`. Non-numerikus branch code → `hashCode() % 1000` fallback. 2026-04-22 teszten a `V035000004` a `BR035` **session-branch**-en (NEM BR017-en) született, a 4-edik VÉTEL a branch-en (sequence counter). A receipt prefix a **session-branch**-ből származik (ahol a session nyílt), nem a worker.branch-ből.
  - **P0 ~~(cash_balance deployment gap)~~:** LEZÁRVA 2026-04-24 PR #164 - auto-init napnyitáskor `DailySessionService.updateCashBalancesForOpening()`-ben.
  - **P0 ~~(V155 migration Hetzner production-on)~~:** LEZÁRVA 2026-04-24 - V155..V160 mind applied a Hetzner production-on, health 200, PR #164 deploy SUCCESS igazolta.
  - **P1:** happy path teszt dev módban (Fejlesztői mód INDÍTÁS shortcut) — a SetupWizard 4. lépésnél **Kapcsolat tesztelése gombot** kell nyomni (connectionTest.state=ok kötelező a Továbbhoz).
  - **P1:** Production URL SSOT teljes refaktor — Java konstans osztály (`ProductionUrls.java`) + `config/production-urls.json` meglelve, **deferred**: minden @Value default, PS1 launcher hardcoded és Electron `main.ts` fallback a config-ból lazy-load-olni.
  - **P2:** CB-016 (NavClosingService hardcoded VAT_RATE=0.27 → tax_code mapping).
  - **P2:** Cognee MCP integráció (amint elérhető) — auto-save session memóriába.
  - **P2:** Obsidian vault sync (amint telepítve) — auto-save session memóriába.
  - **P2:** Spring Boot 3.5.14 upgrade (2026-04-23 milestone; amint release-eli Tomcat 10.1.54+ bundle-lel, törlendő az explicit `<tomcat.version>` override a `backend/pom.xml`-ből).
  - **P2:** Installer acceptance test friss Windows VM-en az `installer/tests/installer-validation-suite.ps1` szkripttel.


## Session zarasa (2026-04-22 07:20)

Main HEAD: `38594cb94b97` (PR #108 merge utan). Mai session: 20+ PR merge-elve.
Fobb terkepek:
- B2 Cashier KPI dashboard (#73) + B1 Audit trail (#74)
- Multi-tenant security 13/15 fix (#75, #76, #83)
- AI review automation: GitHub Actions + Claude Code Action (#88, #90, #108)
- 6 hullam AI reviewer feedback javitasa (#81-87, #107)
- Credentials redact P1 (#107) - plaintext jelszo torolve a session memory-bol

Tesztek: Backend 972/972, Frontend 505/505, Penztar 97/97, Security 14/14.

**Folytatas egy uj session-ben:**
```bash
cd D:/repo/valutavalto-program
git pull origin main
cat .remember/remember.md
cat docs/knowledge/memory/2026-04-22-session-b-wave-ai-automation.yaml
```

Kovetkezo feladatok: lasd "Nyitott következő feladatok" fent.