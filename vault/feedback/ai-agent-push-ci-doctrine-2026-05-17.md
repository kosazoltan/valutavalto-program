# Kötelező AI ügynök utasítás — Push, CI, hibajelentés-beolvasás, automatikus javítás, Deploy, Merge

**Készítette:** Kósa Zoltán kérésére
**Készült:** 2026-05-17
**Hatály:** Minden AI ügynök (Claude Code, Codex, Copilot, junior agentek) ami kódot módosít, pushol, CI-t futtat, review-jelzéseket olvas, hibákat javít, deployt indít vagy merge-elési döntést készít.

---

## Rövid cél

Az ügynök feladata nem az, hogy "megírja a kódot és reménykedjen", hanem hogy a teljes **Push → CI → review feedback → auto-fix → re-run → deploy gate → merge gate** ciklust végigvigye, amíg a változás bizonyíthatóan zöld, auditálható és biztonságos.

## Nem alku tárgya (10 alapszabály)

1. **Red CI mellett nincs merge.**
2. **Required status check megkerülése tilos.**
3. **Secret, token, jelszó, API kulcs soha nem kerülhet commitba, logba, PR bodyba, artifactba vagy snapshotba.**
4. **Az ügynök minden GitHub, Codex, Sourcery, Copilot, code scanning, test és deploy hibajelzést köteles beolvasni** (lásd jelen repo `feedback_auto_pull_reviews_no_email_copy.md` mandate).
5. **Az ügynök nem hagyhat figyelmen kívül failing checket azért, mert "nem az ő hibájának tűnik".**
6. **Az ügynök nem javíthat nagy refaktorral kis hibát.**
7. **Az ügynök minden javítás után köteles újra futtatni a releváns lokális ellenőrzéseket és megvárni a távoli CI-t.**
8. **Az ügynök nem merge-elhet emberi jóváhagyás nélkül**, kivéve ha a repo policy kifejezetten engedélyezi az auto-merge-et.
9. **Deploy csak deploy gate után indulhat.**
10. **Ha bármelyik eszköz ellentmond egymásnak, a szigorúbb jelzést kell követni, és a konfliktust reportolni kell.**

---

## Források és eszközök

### GitHub Actions
- `gh run list --branch <branch> --limit 10 --json status,conclusion,name,headSha`
- `gh run view <run-id> --log-failed`
- `gh api repos/<owner>/<repo>/commits/<sha>/check-runs`
- `gh api repos/<owner>/<repo>/check-runs/<id>/annotations`

### Sourcery
- PR review: summary + review guide + overall review + inline comments + "Prompt for AI Agents" blokk
- `@sourcery-ai review` / `@sourcery-ai summary` / `@sourcery-ai guide` paranccsal re-review kérhető
- Tilos: `@sourcery-ai resolve` / `@sourcery-ai dismiss` indoklás nélkül

### GitHub Copilot
- PR review "Comment" típusú, NEM blokkoló önmagában
- Validálni kell minden suggestion-t — Copilot nem garantáltan talál meg minden problémát

### Codex
- `@codex review` PR kommenttel
- `@codex fix ...` javító task (ha jogosultság engedi)
- CI-failure auto-fix workflow külön PR-rel (lásd minta lent)

### CodeQL (github-advanced-security[bot])
- Inline comments `/pulls/$PR/comments`-en
- E-mailben gyakran NEM küld notification-t → csak `gh api` polling

---

## A teljes kötelező workflow (10 fázis)

### Fázis 0 — Preflight

```bash
git status --short
git branch --show-current
git remote -v
git fetch --all --prune
git log --oneline -5
```

Rögzítendő: repo, branch, base, task scope, expected changed files, forbidden areas, test commands, deploy target, secret handling rule, merge policy. Munkafa nem-tiszta → STOP, ne írj felül ismeretlen módosítást.

### Fázis 1 — Lokális minőségi kapu push előtt

Push előtt minimum:
- format check
- lint
- typecheck
- unit tests
- integration tests (ha gyorsak)
- security/secret scan
- build
- schema/openapi validation (ha releváns)
- docker build (ha deployt érint)
- migration dry-run (ha DB-t érint)

Példa: `npm run lint && npm run typecheck && npm test && npm run build`; `mvn test`; `docker build .`.

Bármi piros → NINCS push.

### Fázis 2 — Commit és push

- Egy commit egy logikai javítás.
- Commit prefix: `feat/fix/docs/test/chore/security/ci/ops/hotfix`.
- Generált / bináris ne kerüljön be (kivéve repo policy engedi).

Push után:
```bash
gh pr status
gh pr view --json number,url,headRefName,baseRefName,mergeStateStatus,reviewDecision,statusCheckRollup
gh pr checks --watch
```

### Fázis 3 — GitHub CI hibák beolvasása

Minden failing runra:
```bash
gh run view <run-id> --log-failed
gh api repos/<owner>/<repo>/commits/<sha>/check-runs
```

Normalizált issue schema:
```json
{
  "source": "github_actions",
  "workflow": "CI",
  "job": "test",
  "step": "pytest",
  "file": "path/to/file.py",
  "line": 123,
  "severity": "blocking",
  "message": "AssertionError...",
  "raw_log_excerpt": "...",
  "repro_command": "python -m pytest ...",
  "status": "open"
}
```

### Fázis 4 — Codex jelzések

1. Codex review commentek.
2. Codex action output / artifact.
3. Codex által nyitott fix PR.

NE fogadd el vakon — validáld lokális teszttel és CI-vel.

```bash
gh pr view <pr> --json reviews,comments
gh api repos/<owner>/<repo>/pulls/<pr>/reviews
gh api repos/<owner>/<repo>/issues/<pr>/comments
```

Codex javaslat csak akkor alkalmazható, ha:
- a diff kicsi és célzott,
- nincs secret változás,
- nincs nem kért refaktor,
- minden teszt lefut,
- a módosítás érthető.

### Fázis 5 — Sourcery jelzések

Beolvasandó:
- PR Summary
- Review Guide
- Overall Review
- Inline comments
- "Prompt for AI Agents" collapsed blokk

Sourcery re-review új push után. Tilos `@sourcery-ai resolve` / `@sourcery-ai dismiss` indoklás nélkül.

### Fázis 6 — Copilot jelzések

Háromfelé kategorizálás:
- `must_fix`: bug / security / test failure / edge case
- `nice_to_have`: olvashatóság, kis egyszerűsítés
- `reject_with_reason`: téves / scope-on kívüli / kockázatos

Copilot javaslatot **tilos automatikusan elfogadni**, ha:
- megváltoztatja az üzleti logikát,
- töröl tesztet,
- lazít validációt,
- hardcode-ol értéket,
- secretet érint,
- csak a tesztet igazítja a hibás működéshez.

### Fázis 7 — Hibák deduplikálása + priorizálása

Közös schema:
```json
{
  "id": "ci-001",
  "source": "github_actions | codex | sourcery | copilot | code_scanning | human",
  "severity": "critical | high | medium | low | info",
  "blocking": true,
  "category": "build | test | lint | typecheck | security | deploy | review | docs | flaky | unknown",
  "file": "string|null",
  "line": "number|null",
  "message": "string",
  "repro_command": "string|null",
  "suggested_fix": "string|null",
  "dedupe_key": "string",
  "status": "open | fixed | rejected_false_positive | deferred | blocked",
  "resolution_note": "string|null"
}
```

Prioritás:
1. Secret leak / credential kitettség
2. Build / install / setup hiba
3. Typecheck / compile hiba
4. Failing unit / integration teszt
5. Security / code scanning finding
6. Deploy blocker
7. Required review blocker
8. Sourcery / Codex / Copilot valódi bug
9. Lint / format
10. Documentation / nice-to-have

### Fázis 8 — Automatikus javítási ciklus

```text
collect reports → normalize → dedupe → rank →
fix smallest blocking set → local checks → commit → push →
wait for CI → re-collect → repeat
```

Limits:
- `max_fix_cycles = 5`
- `max_same_error_repeats = 2`

Ugyanaz a hiba kétszer visszatér → STOP, BLOCKED report.

**Tiltott automatikus javítás:**
- Adatvesztés migráció
- Public API breaking change
- Biztonsági policy lazítás
- Required check kikapcsolása mint "javítás"
- Teszt törlése / skip
- Üzleti döntést igénylő változás

### Fázis 9 — Deploy gate

Deploy előtt kötelező:
- minden required check green
- build artifact létrehozva
- security / secret scan green
- migration dry-run green (ha releváns)
- env vars validated
- rollback plan documented
- deploy target explicit

Production deploy: csak ha policy engedi + approval + rollback + smoke test.

Deploy után:
- health check
- smoke test
- logs check
- error monitoring
- rollback readiness

### Fázis 10 — Merge gate

```bash
gh pr view <pr> --json mergeStateStatus,reviewDecision,statusCheckRollup
gh pr checks <pr>
```

Merge csak ha:
- minden required check success (vagy policy-szerint elfogadott neutral / skipped)
- nincs open critical / high issue
- nincs unresolved blocking review
- nincs secret scan finding
- branch up-to-date vagy merge queue kezeli
- PR body tartalmaz verification summary-t

Merge queue: workflow-nak `merge_group` eventre is futnia kell.

---

## PR body kötelező szerkezete

```text
## Scope
Mit változtat.

## Non-goals
Mihez nem nyúlt.

## Verification
Lokális parancsok és eredmények.

## CI status
GitHub Actions / Codex / Sourcery / Copilot összefoglaló.

## Auto-fix loop
Milyen hibákat olvasott be, mit javított.

## Deploy
Preview/production deploy státusz, smoke test, rollback.

## Safety invariants
Secret, broker, live trading, data migration, irreversible action.

## Open issues
Mi maradt, severity és owner.

## Merge recommendation
Approve / wait / request changes.
```

---

## Kötelező zárójelentés

Minden push/fix/deploy/merge kör végén:

```text
Branch:
PR:
Head SHA:
Base:
Changed files:
Local checks:
GitHub Actions:
Codex:
Sourcery:
Copilot:
Code scanning:
Deploy:
Open blockers:
Fix cycles used:
Cost / external API usage:
Secrets check:
Merge recommendation:
Next action:
```

---

## Agent tiltólista

Az ügynök SOHA nem teheti:
- required check kikapcsolása
- branch protection lazítása
- failing teszt skip valódi indok nélkül
- snapshot átírása hiba elfedésére
- type error `any`-val elkenése indok nélkül
- secret beégetése
- API kulcs echozása
- production deploy smoke test nélkül
- DB migráció dry-run nélkül
- merge unresolved high/critical mellett
- Sourcery/Copilot/Codex comment "resolve" javítás nélkül
- force push védett branchre
- másik agent / ember módosításának felülírása

---

## Junior-utasítás (másolható)

```text
Junior, Push/Deploy/Merge esetén kötelező a teljes CI feedback loop végigvitele.

1. Preflight: git status, branch, remote, base, scope. Ismeretlen módosítást nem írhatsz felül.

2. Push előtt: format/lint/typecheck/test/build/security scan lokálisan. Ha bármi piros, nincs push.

3. Push után:
   - gh pr checks --watch
   - gh run view --log-failed minden failing runra
   - Checks API annotations beolvasása
   - PR reviews/comments beolvasása

4. Kötelező források:
   - GitHub Actions logs/checks/annotations
   - Codex review/fix/artifact/output
   - Sourcery summary/guide/overall/inline + Prompt for AI Agents
   - Copilot review comments/suggestions
   - code scanning / security / secret / dependency alerts

5. Normalizált issue schema.

6. Deduplikálj + priorizálj: secrets > build > typecheck > tests > security > deploy > blocking review > lint > docs.

7. Automatikus javítás: legkisebb célzott diff, nincs refaktor scope-on kívül, nincs teszt-skip, nincs validation lazítás, nincs secret, fix után lokális check, commit, push, CI újraolvasás.

8. Max 5 fix ciklus. Ugyanaz a hiba kétszer → STOP + BLOCKED report.

9. Deploy: csak zöld required checks után. Production csak approval + rollback + smoke test mellett.

10. Merge: csak legfrissebb SHA zöld required checks, nincs open critical/high, nincs unresolved blocking review, nincs secret/security finding. PR body tartalmaz verification + CI + deploy + safety + open issues szakaszt. Emberi jóváhagyás nélkül NE merge-elj.

Minden kör végén zárójelentés.
```

---

## Végső elv

Az AI ügynök nem "kódgenerátor", hanem CI-felelős végrehajtó. A jó működés mércéje nem az, hogy készült-e commit, hanem az, hogy a teljes jelzésrendszerből beolvasott minden hibát, a valódiakat célzottan javította, a fals pozitívakat indoklással lezárta, minden checket újrafuttatott, és csak auditálható zöld állapotban engedte deploy vagy merge irányba a változást.
