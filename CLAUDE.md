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

## KÖTELEZŐ ÉRVÉNYŰ: Session memory workflow (Obsidian-alapú, 2026-04-27 óta)

**EGYETLEN aktív memóriarendszer:** `D:\valutavalto-vault\` (Obsidian vault, dedikált a valutaváltó-projekt számára).

A korábbi rendszerek **deprecated** (2026-04-27 user-direktíva — "memória mizéria megszüntetése"):
- ❌ `.memory/` (SQLite + Node.js MCP) — **TÖRÖLVE** (Bence/Eszter/Tamás belső koncepció refek)
- ❌ Cognee MCP (TODO maradt) — **VISSZAVONVA**
- ❌ Több párhuzamos memóriarendszer

**Minden session elején** olvasd be (ebben a sorrendben):
1. `D:\valutavalto-vault\README.md` — vault használati protokoll
2. `D:\valutavalto-vault\sessions\` — legfrissebb session-jegyzet (YYYY-MM-DD)
3. `D:\valutavalto-vault\feedback\` — kötelező user-direktívák (skim mindent)
4. `.remember/remember.md` — csak quick-state handoff (4-5 sor)
5. `docs/LESSONS_LEARNED.md` — korábbi hibák, amiket NE ismételj

**Minden session végén** mentsd a vault-ba:
1. `D:\valutavalto-vault\sessions\YYYY-MM-DD-rovid-leiras.md` — új session-jegyzet
2. `D:\valutavalto-vault\feedback\<topic>.md` — ha új user-direktíva érkezett
3. `D:\valutavalto-vault\references\<topic>.md` — ha új projekt-tudás érkezett külső forrásból
4. `.remember/remember.md` — quick-state update (Main HEAD, open PR/issue, production health)
5. CLAUDE.md "Nyitott következő feladatok" → frissítés ha változott

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
> **Vault:** `D:\valutavalto-vault\feedback\ai-review-mandate-zero-tolerance.md`

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
> **Vault:** `D:\valutavalto-vault\feedback\hallucinacio-megszuntetese.md`
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

## Aktuális release-állapot (a következő agent számára folytatási horgony)
- **Verzió:** **v2.3.7** (2026-04-29 SB4 sprint óta — minor bump, mert Spring Boot 4 + Tomcat 11 major framework upgrade).
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
- **Aktuális memória helye:** `D:\valutavalto-vault\sessions\2026-04-29-*.md` (Obsidian vault: multi-track-execution + track-4-spring-boot-4-sprint). A `docs/knowledge/memory/*.yaml` történelmi formátum, új session-jegyzetek a vault-ba kerülnek.
- **Asztali shortcutok** (`C:\Users\Kósa Zoltán\OneDrive\Desktop\`): `Valuta Pénztár — Fejlesztői mód (INDÍTÁS).lnk`, `Valuta Pénztár — Fejlesztői mód (LEÁLLÍTÁS).lnk`, `Valuta Pénztár — Éles kliens (telepített).lnk`.
- **AI review automation:** `.github/workflows/ai-review-auto-fix.yml` minden PR merge után triggerel. Sourcery weekly rate-limit (1.5M diff char) — nem blokkoló. A Bence-féle `.github/workflows/auto-review.yml` 2026-04-27 óta törölve.
- **Production URL SSOT (BEFEJEZVE):** `config/production-urls.json` + `backend/.../config/ProductionUrls.java` + `scripts/_production-urls.ps1` + Electron `penztar-client/electron/main.ts` `loadProductionUrls()` + `electron-builder.json` extraResources. Lazy-load minden komponensben.
- **Jackson 3 future migration**: a `spring-boot-jackson2` stop-gap modul + `JacksonConfig.java` programmatic ObjectMapper csak átmeneti megoldás. Egy nagyobb refaktor PR-ben (külön sprint) a 39 fájl `com.fasterxml.jackson.*` → `tools.jackson.*` import-migráció OpenRewrite recipe-pal, ObjectMapper API breaking changes javítás. Akkor: a `spring.jackson.use-jackson2-defaults=true` + a `JacksonConfig.java` törölhető.
- **Nyitott következő feladatok (2026-04-29 állapot):**
  - **P0 (éles pénztár frissítés):** user reinstall az éles gépen **v2.3.7**-tel. Telepítő kész: `~/Downloads/Penztar-Setup-2.3.7-20260429.exe` (280 MB) + `Penztar-Eltavolito-2.3.7-20260429.exe`. Lépések: 1) Eltávolító admin joggal, 2) Setup admin joggal, 3) SetupWizard 5 lépés (Iroda → Program típus → Szerver **Kapcsolat tesztelése** kötelező → Admin jelszó → Telepítés), 4) bootstrap admin login, 5) új VÉTEL teszt → bizonylat formátum: `V<3-jegyű-numerikus-kód>000001`.
  - **P1:** happy path teszt dev módban (Fejlesztői mód INDÍTÁS shortcut) — SetupWizard 4. lépésnél **Kapcsolat tesztelése gombot** kell nyomni (connectionTest.state=ok kötelező a Továbbhoz).
  - **P2:** CodeQL Actions hardening (9 medium: workflow-permissions + unpinned-tag).
  - **P2:** Installer acceptance test friss Windows VM-en az `installer/tests/installer-validation-suite.ps1` szkripttel.
  - **P2 (long-term):** teljes Jackson 3 migráció — 39 fájl `com.fasterxml.jackson.*` → `tools.jackson.*` import-csere (OpenRewrite recipe). Akkor a stop-gap modul + JacksonConfig.java törölhető.

**LEZÁRVA 2026-04-29-i sessionben:** ✅ Spring Boot 3.5.13 → 4.0.6 (PR #263, sprint), ✅ Tomcat 10.1.54 → 11.0.21 (PR #264), ✅ JacksonConfig builder + modulesToInstall (PR #265+#266), ✅ springdoc 3.0.3 (#263 unified, #196 dependabot zárta automatikusan), ✅ eslint 9.39 → 10.2.1 + Node engines >=20.19.0 (PR #256), ✅ react 18 → 19.2.5 (PR #257, mind a 4 csomag, peer-dep skew elhárítva), ✅ V166 silent reactivation + V167 BASE TABLE defensive migrationok (PR #255, #258), ✅ MIGRATION_NOTES.md dokumentálás (V3_5+V33+V3_7+V109+V166+V167), ✅ playwright.live testMatch full-menu spec (PR #255).

**LEZÁRVA (korábbi sessionekben):** ✅ Issue #110 cash_balance (2026-04-27), ✅ V155 migration (2026-04-24), ✅ CB-016 NavClosingService VAT_RATE → tax_code mapping (V143 + SystemParameter), ✅ Production URL SSOT teljes 3-réteg refaktor (PR #173 + #174), ✅ Cognee MCP / Obsidian vault sync (`D:\valutavalto-vault\` aktív 2026-04-27 óta).