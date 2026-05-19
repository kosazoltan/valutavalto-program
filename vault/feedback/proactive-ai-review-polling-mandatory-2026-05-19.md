---
title: "Proaktív CI + AI review polling — KÖTELEZŐ P0"
status: active
priority: P0
hatály: 2026-05-19 21:25+ CEST
forrás: Kósa Zoltán user-direktíva (2026-05-19 21:25 CEST, autonomous mode session)
related:
  - vault/feedback/two-rounds-before-merge-mandatory-2026-05-19.md (C.22)
  - vault/feedback/two-rounds-self-subagent-review-mandatory-2026-05-19.md (C.23)
  - CLAUDE.md C.4 "Auto-pull AI reviews, NEM email-másolás" (2026-05-16)
---

# Proaktív CI + AI review polling — KÖTELEZŐ P0

## A szabály

> "Időzítsd, saját funkcióként, a teljes CI workflow automatikus beolvasását, a
> GitHubról, a Copilot-ot codexet, Sourcery-t, mindent, mert így mindig megállsz,
> amikor várakozol, de elfelejted beolvasni őket."

## Probléma diagnózisa

A korábbi minta (rossz):
1. Push to PR → ScheduleWakeup CI completion-re
2. Passzív várakozás amíg a `gh pr checks` zöldül
3. Az AI review-k (Codex 60-120s, Copilot 60-180s, Sourcery 60-240s) **közben** beérkeznek emailben
4. Én **NEM** ellenőrzöm — a user kénytelen email-t forward-olni
5. User forward után reaktív válasz

A correct minta (új):
1. Push to PR → **2 párhuzamos** background poll:
   - **CI poll** (cron 30s, max 900s)
   - **AI review poll** (cron 60s, max 600s)
2. Mindkét csatorna beérkezésekor proaktív feldolgozás

## Időzítési cadence

**Push utáni cadence (minden PR-re):**

| T+ | Akció |
|---|---|
| 0s | Push success — set up 2 background poll |
| 60s | First AI review check — Codex általában már bent (`gh api .../pulls/{N}/reviews` + `/comments`) |
| 120s | Second AI review check — Copilot általában már bent |
| 180s | Third AI review check — Sourcery (ha nincs weekly rate-limit) |
| 300s | Fourth check — final escalation, ha kritikus review hiányzik |
| ≤900s | CI completion threshold |

## Implementáció (background poll script)

A `gh api` poll-ja egy `until` loop-ban:

```bash
# A) CI poll
until [ "$(gh pr checks <PR> --json state -q '[.[] | select(.state == "PENDING" or .state == "IN_PROGRESS" or .state == "QUEUED")] | length')" = "0" ]; do
  sleep 30
done

# B) AI review poll (PÁRHUZAMOS):
COUNT=0
until [ $(gh api "repos/.../pulls/<PR>/reviews" --jq '[.[] | select(((.user.login | ascii_downcase | contains("codex")) or (.user.login | ascii_downcase | contains("copilot"))) and ((.body // "") | (contains("create a Codex account") | not)))] | length') -ge 2 ] || [ $COUNT -ge 20 ]; do
  sleep 30
  COUNT=$((COUNT+1))
done
```

A 2 poll **párhuzamosan** indítható `run_in_background: true` Bash hívással.

## Mit POLLOLNI

**Minden push után 60s-en belül:**

1. **CI status** — `gh pr checks <PR> --json state,name`
2. **Codex review** — `gh api repos/.../pulls/<PR>/reviews --jq '.[] | select(.user.login | contains("codex"))'`
3. **Copilot review** — same, `contains("copilot")`
4. **Sourcery review** — same, `contains("sourcery")` — weekly rate-limit ignore
5. **CodeQL** — `gh api repos/.../pulls/<PR>/reviews --jq '.[] | select(.user.login | contains("github-advanced-security"))'`
6. **Inline comments** — `gh api repos/.../pulls/<PR>/comments`

## Tilos

- ❌ Passzív várakozás amíg a user forward-olja az emailt
- ❌ "Csak CI-re várok, AI review-t majd később megnézem" — proaktívan kell már T+60s-től
- ❌ "Várom a notifikációt" — a notifikáció CSAK CI completion-re fire-ol, az AI review-ra NEM külön

## Engedélyezett

- ✅ Mind a 2 poll (CI + AI) párhuzamosan `run_in_background: true`
- ✅ Sourcery weekly rate-limit ignore (CLAUDE.md mandate)
- ✅ Codex setup-prompt zaj filter (`contains("create a Codex account") | not`)
- ✅ Ha mind a 6 forrás T+300s-ig nem ad finding-et → admin-merge eljárás

## Forrás

- CLAUDE.md C.4 — "Auto-pull AI reviews, NEM email-másolás" (2026-05-16)
- C.12 — AI review query metodológia (6 endpoint kötelező)
- Jelen mandate kibővíti: NEM csak query-zünk amikor a user kéri, hanem **proaktívan időzítve** minden push után.

## Új CI mandate-szám

C.24 — Proaktív CI + AI review polling minden push után (T+60s/120s/180s/300s cadence).
