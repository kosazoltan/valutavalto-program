---
name: Lint CI Codex Sourcery Copilot — kotelezo MINDEN PR-en automatikusan
description: User-direktiva 2026-05-03 21:50 + 21:53 CEST. Minden PR utan a lint CI + Codex + Sourcery + Copilot review-k AUTOMATIKUS lekerdezese + javitasa, lustasag/hazugsag/mellebeszeles nelkul. NEM kerdezni meg a usert, NEM defer-elni P3-ra hivatkozva, NEM "majd kesobb"-ra tenni.
type: feedback
priority: P0 — felulirja a defaultokat
created: 2026-05-03
trigger: "minden PR meg-nyitas / push / merge utan automatikusan"
---

# Lint CI Codex Sourcery Copilot — minden PR-en kotelezo, automatikus

> **User direktiva 2026-05-03 21:50 CEST (Kosa Zoltan):**
>
> "mentsd el a teljes workflot!!! lint CI codex sourcery kötelező minden pr
> esetén!!!! Automatikusan minden esetben lustaság, hazugság, mellébeszélés
> nélkül kötelező, megcsinálnod."
>
> **Kovetes 21:53 CEST:** "a copilot jelzéseit is kötelező" — a Copilot
> reviewer is FELL-VEEND a kotelezo listara, nem "best-effort" hanem
> EGYENERTEKU Codex/Sourcery-vel.

## A szabaly

**Minden PR letrehozasa, push-olasa es merge-elese utan KOTELEZO** a kovetkezo
ciklus AUTOMATIKUSAN, ember-megerositess nelkul:

### 1. CI ellenorzes (kotelezo)

```bash
gh pr checks <PR_NUM> --json name,bucket
```

- **Backend Build + Test** (mvn test) — KOTELEZO ZOLD
- **frontend-react Lint + TypeCheck** + i18n-gate — KOTELEZO ZOLD
- **penztar-client Test + Lint + TypeCheck + IPC Contract** — KOTELEZO ZOLD
- **CodeQL** (Analyze actions/java-kotlin/javascript-typescript) — KOTELEZO ZOLD
- **Trivy Backend SCA** — KOTELEZO ZOLD
- **GitLeaks Secret Scan** — KOTELEZO ZOLD
- **UTF-8 Guardrail** — KOTELEZO ZOLD
- **Auth Reload Smoke (Playwright)** — KOTELEZO ZOLD ha frontend-react valtozott

### 2. Codex review feldolgozas (kotelezo)

```bash
gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/reviews" \
  --jq '.[] | select(((.user.login | ascii_downcase | contains("codex"))) and ((.body // "") | (contains("create a Codex account") | not)) and ((.body // "") | (contains("weekly rate limit") | not)))'

gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")))'
```

**MINDEN P0/P1/P2 talalat KOTELEZOEN javitani — uj follow-up commit-ban + push.**
P3 (style/nice-to-have) megemlitendo, lehet defer, de DOKUMENTALT indoklassal a vault-ban.

### 3. Sourcery review feldolgozas (kotelezo)

```bash
gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/reviews" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery")))'

gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("sourcery")))'
```

**MINDEN talalat KOTELEZOEN javitani**, kiveve:
- Sourcery weekly rate-limit (1.5M diff char) — NEM blokkolo
- Bizonyithatoan hamis pozitiv — vault-jegyzetbe doksizni miert

### 4. Copilot review (KOTELEZO — egyenerteku Codex/Sourcery-vel)

A `copilot-pull-request-reviewer[bot]` review-k tobbsegszor "## Pull request overview" + inline javaslatok formajaban erkeznek. **2026-05-03 21:53 user direktiva: a Copilot is KOTELEZO**, NEM "best-effort":

```bash
gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/reviews" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("copilot")))'

gh api "repos/kosazoltan/valutavalto-program/pulls/<PR>/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("copilot")))'
```

**MINDEN P0/P1/P2 talalat KOTELEZOEN javitani**, ugyanugy mint Codex/Sourcery-nel.
P3 (style/nice-to-have) is ahol biztonsagos + low-risk — javitani; ahol nagyobb refaktor, dokumentalt defer.

## TILOS

- ❌ "P3 minor → defer" indoklas nelkul
- ❌ "Majd kesobb a kovetkezo sprint-ben" — NEM ha P0/P1/P2
- ❌ "A user nem szol, nem foglalkozom vele" — automatikusan, megerositess nelkul
- ❌ "Csak az enyem (PR-em) tartozik ram" — minden nyitott PR-en feltetelezni hogy menetkesz
- ❌ "Sourcery weekly limit miatt nem tudom" — a P0/P1/P2 az Codex/Copilot reviewbol jon, nem skip-pelheto
- ❌ Csak az ALL_DONE monitor utan elnezni a PR-t — proaktivan kell ellenorizni az AI-bot review-jat
- ❌ Hazudni hogy "minden zold" anelkul, hogy `gh pr checks` ellenorizve lett

## Kotelezo workflow ciklus

```
1. PR letrehozas (gh pr create)
2. Var CI-re (Monitor jq script)
3. CI green → 4. lepes
   CI fail → fixelni + commit + push, GO TO 2.
4. Lekerdezni Codex + Sourcery + Copilot reviews + comments (gh api)
5. P0/P1/P2 jelzetek → javitani + commit + push
   GO TO 2 (CI ujra)
6. Reviews 'looks great!' VAGY mind P0/P1/P2 fix → admin merge
7. Production deploy verify (curl /api/v1/auth/bootstrap-status -> 200)
```

A `gh pr merge --squash --admin --delete-branch` utan UJABB CI ciklus indul (deploy + e2e). Azt is monitorozni KOTELEZO.

## Verify

A workflow betartasa az alabbi parancsokon ellenorzheto:

```bash
# Hany Codex review-finding maradt nyitva a legutobbi 5 PR-en?
for pr in $(gh pr list --state merged --limit 5 --json number --jq '.[].number'); do
  codex_count=$(gh api "repos/kosazoltan/valutavalto-program/pulls/$pr/comments" --jq '.[] | select((.user.login | ascii_downcase | contains("codex"))) | .body' 2>/dev/null | wc -l)
  echo "PR #$pr: $codex_count Codex inline comment"
done

# CI hibak utolso 30 run-bol (kihagyva a known false-positive AI Auto-Fix)
gh run list -L 30 --json status,conclusion,workflowName \
  --jq '.[] | select(.conclusion=="failure" and (.workflowName != "AI Review Auto-Fix")) | .workflowName'
```

## Hivatkozasok

- [feedback/ai-review-mandate-zero-tolerance.md](./ai-review-mandate-zero-tolerance.md) — eredeti zero-tolerance mandate (2026-04-29)
- CLAUDE.md "KÖTELEZŐ ÉRVÉNYŰ: AI Review Zero-Tolerance Mandate (v2.3.18+, 2026-04-29 user-direktíva)" — projekt-szintu kotelezettseg
- CLAUDE.md "Kötelező AI code review workflow (Sourcery + Codex)" — manualis fallback szakasz
