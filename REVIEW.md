# PUSH / MERGE / DEPLOY self-review kötelező checklist

> **Forrás:** Opus 4.7 GitHub minőségbiztosítási utasításrendszer (2026-04-23 user-direktíva)
> **Hely:** `.claude/projects/D--repo-valutavalto-program/memory/OPUS_GITHUB_QUALITY_MANDATE.md` (globális) + ezen fájl (projekt)
> **Kötelező:** minden `git push`, `gh pr merge`, backend/frontend deploy ELŐTT kötelezően végigfutni.

## ☑ Lokális kapuk (pre-push)

- [ ] `lint` — frontend `npm run lint` + backend `./mvnw -q checkstyle:check` (ha van) → **0 error**
- [ ] `typecheck` — frontend `npx tsc --noEmit` → **exit=0**
- [ ] `test` — releváns suite zöld:
  - [ ] backend: `cd backend && ./mvnw test` (érintett módulok)
  - [ ] frontend: `cd frontend-react && npm test -- --run` (érintett komponensek)
  - [ ] penztar-client: `cd penztar-client && npm test -- --run` (érintett Electron IPC-k)
- [ ] `build` — backend `./mvnw -DskipTests package` + frontend `npm run build` → **exit=0**

**Ha bármelyik bukik:** TILOS `git push`. Javítás → újrafutatás → csak zöld állapotban push.

## ☑ Git-higiénia

- [ ] **feature branch** (`fix/...`, `feat/...`, `chore/...`, `docs/...`) — NEM közvetlenül `main`-re
- [ ] `git push --force` tiltott a védett main-en
- [ ] Branch protection/ruleset változtatás csak külön PR-ben, CODEOWNERS jóváhagyással
- [ ] `.github/workflows/` módosítás NEM keveredik üzleti kóddal egy PR-ben

## ☑ Biztonsági tiltólista (új kód)

- [ ] nincs hard-coded secret (.env, api key, jelszó, JWT titok)
- [ ] nincs SQL string-konkatenáció user inputból (csak `@Param` / PreparedStatement / Criteria)
- [ ] nincs `eval`, `Function`, `unsafe deserialization`
- [ ] nincs `shell=True`, shell string-konkat input-ból (Python), `Runtime.exec(String)` (Java)
- [ ] nincs path traversal (`../`, user-path a filesystem API-ban validáció nélkül)
- [ ] nincs néma `catch(Exception e){}` (Java) / `except: pass` (Python) — legalább log
- [ ] nincs hamis mock adat production válaszként
- [ ] új dependency: hivatalos registry, verzió rögzítve, Dependabot dependency-review ZÖLD

## ☑ Fail loud, never fake

- [ ] Hiány (külső API, DB, service, file, secret) esetén **explicit error + log**
- [ ] Fallback CSAK jól látható `degraded` jelzéssel (UI banner / HTTP header)
- [ ] TILOS úgy tenni, mintha élő adat lenne, ha mock/cache/fallback van

## ☑ Kötelező GitHub-jelzés lekérdezés (PUSH UTÁN, MERGE ELŐTT)

```bash
OWNER="kosazoltan"
REPO="valutavalto-program"
PR="<szam>"

# 1. PR head SHA + review decision
gh pr view "$PR" --repo "$OWNER/$REPO" --json number,title,headRefOid,reviewDecision,mergeStateStatus,isDraft

# 2. Required checks állapot
gh pr checks "$PR" --repo "$OWNER/$REPO" --required --json name,workflow,state,bucket,description,link

# 3. Minden check-run + annotation
HEAD_SHA="$(gh pr view "$PR" --repo "$OWNER/$REPO" --json headRefOid -q .headRefOid)"
gh api "/repos/$OWNER/$REPO/commits/$HEAD_SHA/check-runs?per_page=100" \
  --jq '.check_runs[] | {name,status,conclusion,app:.app.name,title:.output.title,annotations_count:.output.annotations_count}'

# 4. Codex review
gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.body // "" | ascii_downcase | contains("codex"))) | {reviewer:.user.login,state,submitted_at,body}'

# 5. Sourcery review
gh api "/repos/$OWNER/$REPO/pulls/$PR/reviews?per_page=100" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery")) or (.body // "" | ascii_downcase | contains("sourcery"))) | {reviewer:.user.login,state,submitted_at,body}'

# 6. Inline review comments (Codex + Sourcery)
gh api "/repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) | {user:.user.login,path,line,body}'

# 7. Dependabot high/critical open
gh api "/repos/$OWNER/$REPO/dependabot/alerts?state=open&severity=high,critical&per_page=100" \
  --jq '.[] | {number,state,severity:.security_vulnerability.severity,package:.dependency.package.name,fixed_version:.security_vulnerability.first_patched_version.identifier}'

# 8. CodeQL/code scanning (PR-hez kötött)
gh api "/repos/$OWNER/$REPO/code-scanning/alerts?state=open&severity=critical,high&pr=$PR&per_page=100" \
  --jq '.[] | {number,tool:.tool.name,rule_id:.rule.id,severity:.rule.security_severity_level,path:.most_recent_instance.location.path,line:.most_recent_instance.location.start_line}'

# 9. Secret scanning + push protection
gh api "/repos/$OWNER/$REPO" --jq '{secret_scanning:.security_and_analysis.secret_scanning.status,push_protection:.security_and_analysis.secret_scanning_push_protection.status}'
```

**Egybe:** `powershell -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR_NUM>`

## ☑ Blokkoló feltételek (NINCS merge)

| Forrás | Blokkoló állapot |
|---|---|
| Required check | `bucket=fail` / `cancel` / 10+ perc `pending` |
| Check-run annotation | `annotation_level=failure` |
| Review decision | `CHANGES_REQUESTED` |
| Codex | P0/P1 finding unresolved |
| Sourcery | Security / testing / complexity finding unresolved |
| Dependabot | `state=open` + `severity=high,critical` |
| CodeQL | new open high/critical alert (PR-hez kötve) |
| Secret scanning | új valódi secret / bypass |
| Conversation | unresolved thread a PR-en |

## ☑ Deploy előtti extra kapuk

- [ ] Build artifact létezik
- [ ] SBOM generálva (ha release)
- [ ] `gh attestation verify ./dist/app --repo "$OWNER/$REPO"` (ha release)
- [ ] Container scan high/critical nélkül (ha image deploy)
- [ ] Production environment required reviewer jóváhagyta (ha prod deploy)

## ☑ 5-szempontú kód-tartalom review (diff elfogadása ELŐTT)

> Hozzáadva 2026-05-27 (architect-mode metodika fold). A fenti lokális/git/biztonsági/GitHub
> kapuk a folyamatot fedik; ez a szakasz a **diff tartalmi** átvizsgálása. Csak az ott még NEM
> szereplő pontokat sorolja (nincs duplikáció).

1. **Szándék** — a változás megoldja az EREDETI problémát (nem mást)? Minden peremeset kezelve
   (null/undefined, hálózati hiba, üres lista, 0/negatív összeg, hiányzó jog)? Nincs hallgatólagos
   „do nothing" ág — minden if/else explicit?
2. **Architektúra** — illeszkedik a meglévő kódbázis mintáihoz (mapper/service/repo réteg,
   multi-tenant scope, OSIV=false LazyInit-kezelés)? **Nincs túlbonyolítás** (felesleges absztrakció,
   új réteg, korai általánosítás)? A változás a lehető legkevesebb fájlt érinti?
3. **Biztonság** — *(a tiltólistán felül)* **a beimportált könyvtár/szimbólum VALÓBAN létezik**
   (hallucináció-ellenőrzés: a package a `package.json`/`pom.xml`-ben van, az import feloldódik a
   build-ben)? Minden input a rendszerhatáron validált?
4. **Karbantarthatóság** — nincs benne felesleges **placeholder elnevezés** (`foo`, `tmp`, `data2`,
   `TODO`-stub), kommentelt holt kód, vagy a fájl konvenciójától eltérő **kevert stílus**?
5. **Teljesítmény** — a DB-lekérdezések hatékonyak (nincs N+1, van index a szűrt oszlopon, a lapozott
   query nem tölt be mindent memóriába)? Nincs felesleges ciklus-beli I/O?

**Bizonytalanság-kezelés:** ha egy ponton nem vagy biztos (pl. „létezik-e ez a metódus/oszlop"),
**ellenőrizd a forrást** (grep/Read/build) — TILOS feltételezésre építve elfogadni a diffet.

## ☑ Záró self-review formátum (minden kódos GitHub-feladat végén)

```markdown
## Állapot
Nem kész / Kész / Blocked

## Változtatott fájlok
- `path`: miért változott

## Lokális ellenőrzések
- lint: pass/fail/pending, parancs
- typecheck: pass/fail/pending, parancs
- test: pass/fail/pending, parancs
- build: pass/fail/pending, parancs

## GitHub ellenőrzések
- required checks: pass/fail/pending
- check-run failure annotációk: nincs / lista
- CodeQL/code scanning: nincs open high/critical / lista
- Dependabot: nincs open high/critical / lista
- secret scanning/push protection: nincs új jelzés / lista
- Codex review: futott, nincs P0/P1 / lista
- Sourcery review: futott, nincs blocking finding / lista
- unresolved conversations: 0 / lista

## Döntés
Merge-ready csak akkor, ha minden fenti pont pass.
Deploy-ready csak akkor, ha az artifact/provenance/environment kapuk is pass.
```

## ☑ Zéró-tolerancia tiltólista

- ❌ "Tudtommal működik" / "Szerintem kész" / "Remélem jó" — NINCS
- ❌ "Majd a CI kiszűri" — NEM (előbb lokálisan)
- ❌ `--no-verify` flag `git commit` / `git push` esetén — TILOS
- ❌ AI review jelzés emailben jön + agent bemásolgatja — **MEGSZÜNTETVE**; az agent MAGA kérdezi le minden push után
- ❌ "Sikeres a fordítás" ≠ "deploy-ready" — nem elég

## Memory referenciák
- `C:\Users\Kósa Zoltán\.claude\projects\D--repo-valutavalto-program\memory\OPUS_GITHUB_QUALITY_MANDATE.md` (user-global)
- `.claude/projects/D--repo-valutavalto-program/memory/MEMORY.md` (index, első sor)