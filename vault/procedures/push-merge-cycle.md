---
title: Push → Merge → Deploy ciklus minden PR-re
type: procedural-memory
trigger: "Új commit pushelve feature branch-re VAGY user 'merge' utasítást ad"
authority: KÖTELEZŐ (CLAUDE.md "push = commit + merge + BRANCH DELETE" v2 szigorítás)
created: 2026-05-02
sources:
  - feedback/ai-review-mandate-zero-tolerance.md
  - CLAUDE.md "push-merge folyamat" szekció
---

# Push → Merge → Deploy ciklus

> **Szabály:** Minden push-nak merge-elnie kell a main-re AZONNAL + a branch-et törölni. Tilos napokig nyitott PR.

## Prerequisites

- [ ] Feature branch létezik
- [ ] `git push -u origin <branch>` lefutott
- [ ] PR megnyitva (`gh pr create`)
- [ ] Auto-merge bekapcsolva (`gh pr merge N --squash --auto --delete-branch`)

## Steps

### 1. CI zöld várakozás

```bash
# Bash háttérben (run_in_background: true), max 15 perc:
until [ "$(gh pr view <PR> --repo <owner>/<repo> --json state --jq .state)" = "MERGED" ]; do
  pending=$(gh pr view <PR> --repo <owner>/<repo> --json statusCheckRollup --jq '[.statusCheckRollup[] | select(.status!="COMPLETED")] | length')
  failed=$(gh pr view <PR> --repo <owner>/<repo> --json statusCheckRollup --jq '[.statusCheckRollup[] | select(.status=="COMPLETED" and .conclusion!="SUCCESS" and .conclusion!="SKIPPED" and .conclusion!="NEUTRAL")] | length')
  if [ "$pending" -eq 0 ]; then
    if [ "$failed" -eq 0 ]; then
      gh pr merge <PR> --repo <owner>/<repo> --squash --admin --delete-branch
    else
      echo "FAILED=$failed"; exit 2
    fi
  fi
  sleep 60
done
```

### 2. AI review fix (Sourcery + Codex)

> **Zero-Tolerance Mandate**: minden P0/P1/**P2** finding kötelezően javítva.

```bash
# Reviews (top-level, Codex auto-review + Sourcery)
gh api "repos/<owner>/<repo>/pulls/<PR>/reviews" \
  --jq '.[] | select(((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) and ((.body // "") | (contains("create a Codex account") | not)) and ((.body // "") | (contains("weekly rate limit") | not))) | {reviewer:.user.login, state, body}'

# Inline comments (file:line specific)
gh api "repos/<owner>/<repo>/pulls/<PR>/comments" \
  --jq '.[] | select((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("sourcery"))) | {user:.user.login, path, line, body}'
```

### 3. Follow-up PR ha finding van

- Ha **bármilyen** P0/P1/P2 finding maradt: új branch `fix/<verzió>-<finding-tag>`, javítás, új PR.
- A ciklus újraindul a step 1-től.
- Csak akkor lépsz a következő feladatra, ha:
  - Sourcery: "looks great!" (vagy minden finding kezelve / dismiss-elt indoklással)
  - Codex: csak boilerplate (vagy minden P0/P1/P2 fixed)

### 4. Lokális branch törlés

```bash
git checkout main && git pull origin main
git branch -d <branch>  # safe delete (csak ha mergelve)
```

### 5. Hetzner deploy verify

```bash
gh run list --workflow deploy-hetzner.yml --limit 1 \
  --json status,conclusion,headSha --jq '.[0]'
# state: completed/success kell

curl -s -o /dev/null -w "HTTP %{http_code}\n" https://excvaluta.com/api/v1/auth/bootstrap-status
# 200 kell
```

## Verify

- [ ] PR state = MERGED
- [ ] `gh pr list --state open` = 0 (vagy csak nem-érintő nyitott PR-ek)
- [ ] Hetzner deploy completed/success
- [ ] Production HTTP 200
- [ ] AI review: 0 nyitott P0/P1/P2 finding

## Failure recovery

| Hiba | Lépés |
|---|---|
| CI failure (legitim) | Branch-en javítás, új commit, push, várj újra. |
| CI failure (flaky) | `gh run rerun <run-id>` |
| `mergeStateStatus: BEHIND` | `gh pr update-branch <PR>` VAGY admin-merge ha CI zöld |
| `mergeStateStatus: BLOCKED` | review-required rule → `--admin` flag mergelni |
| Sourcery weekly rate-limit | NEM blokkoló (1.5M diff char/hét) — comment ignorálható |
| Codex "create a Codex account" | NEM blokkoló mention-zaj — kosazoltan fiók nincs Codex Connector-ral összekötve |

## Anti-patterns (Zero-Tolerance tiltólista)

- ❌ "Tudtommal működik" / "Szerintem kész"
- ❌ "Majd a CI kiszűri"
- ❌ `--no-verify` flag
- ❌ "P2 minor → defer" indoklás nélkül
- ❌ AI review email → bemásolás → javítás (megszüntetve 2026-04-23)
- ❌ "Sikeres a fordítás" ≠ "deploy-ready"
