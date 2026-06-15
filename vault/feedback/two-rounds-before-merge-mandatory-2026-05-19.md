---
title: "Két ellenőrzési kör merge előtt — kötelező P0 mandate"
status: active
priority: P0
hatály: 2026-05-19+
forrás: Kósa Zoltán user-direktíva (2026-05-19 13:39 CEST, PR #697)
related: CLAUDE.md C.10 (Zero-Tolerance AI review)
---

# Két ellenőrzési kör merge előtt — KÖTELEZŐ P0

> ⚠️ **HATÁLY-PONTOSÍTÁS (2026-06-15):** Ez a szabály **NEM always-on**. A két kör
> **merge/deploy/release/magas-kockázat** előtt kötelező — normál, kis lokális
> feladatra a célzott ellenőrzés elég (`AGENTS.md` §4; `_active_mandates.md`
> „Hatályon kivul helyezett": kötelezett kétkörös self-review *normál* feladatnál).
> Az eredeti „minden feladatra P0" forma túlszabályozás → hatályon kívül; a
> merge-előtti magas-kockázatú mag érvényes marad.

## A szabály

> "Most ezt kötelező szabályként kezelem: merge előtt két külön saját
> ellenőrzési kört futtatok, és csak zöld CI + zöld AI gate után megy tovább."

## A 2 kör

### 1. CI gate (zöld)
- `gh pr checks <PR>` — minden required check `pass` (vagy `skipping` indokolt esetekben)
- **TILOS** `pending`-gel merge-et csinálni
- **TILOS** `failure`-rel admin-mergel kerülni a check-eket

### 2. AI gate (zöld)
- `gh api repos/.../pulls/{N}/reviews` + `/comments` — Codex + Copilot + Sourcery
- **MINDEN P0/P1/P2 finding fixelve VAGY dismiss-elve dokumentált indoklással**
- Sourcery weekly rate-limit hit → NEM blokkoló
- Codex/Copilot stale finding (előző commit-ról) → ellenőrizni hogy a kódban már nincs a probléma

## A "második kör"

Az első kör után (CI + AI gate zöld) a fix-eket pusholjuk, **majd újra végigfutjuk a két kapcsolatot a NEW commit-on**:

1. CI újra fut a fix-commit-ra → várni zöldig
2. AI review újra fut → ha új finding → újabb iteráció
3. Amikor a fix-commit-on is mind a kettő zöld → **csak akkor admin-merge**

## Tilos

- ❌ "P3 minor → defer" indoklás nélkül
- ❌ "stale finding" megjelölés a kód valódi auditja nélkül
- ❌ "majd a CI-ben kiderül" — minden lépés ELŐRE validálva
- ❌ Race-condition: pushing fix while CI still running on previous commit

## Mikor érvényes

Minden PR merge előtt, kivéve:
- HOTFIX kritikus production outage-re (külön user-direktíva kell)
- Pure docs commit (.md fájl módosítás)

## Kapcsolódó

- CLAUDE.md C.10 "Lint CI + Codex + Sourcery + Copilot minden PR-en"
- CLAUDE.md "AI Review Zero-Tolerance Mandate v2.3.18+"
- vault/feedback/ai-agent-push-ci-doctrine-2026-05-17.md
