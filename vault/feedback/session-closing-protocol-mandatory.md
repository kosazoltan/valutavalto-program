---
title: Session-zárási és visszaellenőrzési protokoll (KÖTELEZŐ)
date: 2026-05-04
author: Kósa Zoltán
priority: critical
applyTo: all-ai-agents
status: active
hatalyba_lepes: 2026-05-04
---

# Session-zárási és visszaellenőrzési protokoll — KÖTELEZŐ

> **2026-05-04 user-direktíva (Kósa Zoltán):**
>
> "Az utasítás kötelező érvényű utasítás, kötelező végrehajtani, halucináció,
> mellébeszélés, lustaság, halogatás, tévedés és butaság nélkül pontos, tiszta
> munka az elvárt. Kizárólag adatok alapján végezheted a munkádat, nincs
> becslés, nincs tippelés."

## A protokoll hatálya

Minden mesterséges intelligencia ügynök (Claude, OpenAI Codex, Cursor, Gemini,
Antigravity, GitHub Copilot CLI) **MINDEN egyes session záráskor KÖTELEZŐEN**
le kell futtatnia ezt a 9-lépéses protokollt.

A session nem tekinthető befejezettnek addig, amíg az ellenőrzési, javítási és
visszaolvasási körök tényszerűen le nem futottak, vagy egy objektív, dokumentált
blokkoló ok miatt nem futtathatók.

## A teljes protokoll szöveg

A teljes, gépileg betöltődő always-on rule-t lásd:
[`.cursor/rules/mandatory-session-closing-protocol.mdc`](D:\repo\valutavalto-program\.cursor\rules\mandatory-session-closing-protocol.mdc)

A CLAUDE.md projekt-szintű utasításokba is be van vezetve:
[`CLAUDE.md` "Session-zárási protokoll" szekció](D:\repo\valutavalto-program\CLAUDE.md)

## 9 kötelező lépés (összefoglaló)

1. **Workspace** — `git status`, `git diff`, módosított fájlok visszaolvasása.
2. **Helyi minőségkapuk** — lint, typecheck, format, test, build (mindenre, amit a repo támogat).
3. **Hibák + warningok javítása zöldig** — root cause alapú, NEM próba-szerencse.
4. **Merge előtti szinkron** — `git pull origin main`, konfliktus-feloldás, újra teszt.
5. **Push előtti végső helyi check** — minden zöld, force push tilos (kivéve user-direktíva).
6. **Push/deploy után KÜLSŐ ellenőrzések visszaolvasása**:
   - GitHub Actions CI (minden check)
   - Copilot review + komment + javaslat
   - Codex review + komment
   - Sourcery/Sorcery review + komment + quality gate
   - Hetzner/deploy szolgáltató teljes log + health check
7. **Külső hibák alapján javítási ciklus** — root cause → minimális fix → újra push → újra visszaolvas.
8. **Deploy utáni runtime ellenőrzések** — health URL, runtime log, 4xx/5xx, migration, env var.
9. **Záró jelentés tényekkel** — milyen parancsok futottak, milyen eredménnyel, ha blokkoló: pontos név + hibaüzenet + következő lépés.

## Tiltott lezárási minták

- ❌ "Valószínűleg jó" jellegű állítás
- ❌ CI/deploy állapot visszaolvasása nélküli "kész"
- ❌ Warning figyelmen kívül hagyása
- ❌ Review komment feldolgozatlanul hagyása
- ❌ Push/merge után lezárás eredmény-visszaolvasás nélkül
- ❌ Hibák felderítésének felhasználóra hagyása

## Elvárt végállapot

A session **kizárólag akkor zárható le sikeresen**, ha:

- a munkaterület diffje értett és szándékos
- minden helyi ellenőrzés sikeres
- minden warning javítva vagy bizonyítottan elfogadhatóként dokumentálva
- a merge állapot tiszta
- a push sikeres (ha kellett)
- a CI minden releváns checkje zöld
- Copilot/Codex/Sourcery hibajelentése visszaolvasva és kezelve
- deploy esetén a deploy sikeres, a célrendszer elérhető, a logok tiszták
- a záró válasz tényszerűen felsorolja az elvégzett ellenőrzéseket és eredményeit

## Konkrét parancsok ebben a repositoryban

```bash
# Backend
cd backend && ./mvnw -B test --no-transfer-progress

# Frontend-react
cd frontend-react && npm run typecheck && npm run lint:i18n-gate && npm test

# Penztar-client
cd penztar-client && npm run typecheck && npm run check:ipc && npm test

# Production smoke
curl -s https://excvaluta.com/api/v1/auth/bootstrap-status
curl -s "https://excvaluta.com/api/v1/public/branches?companyCode=EBC"

# AI review (zaj-szűrt)
gh api "repos/kosazoltan/valutavalto-program/pulls/$PR/reviews" --jq '...'
gh api "repos/kosazoltan/valutavalto-program/pulls/$PR/comments" --jq '...'
gh pr checks $PR
gh run list --branch main --limit 5
```

## Megsértés következménye

A protokoll figyelmen kívül hagyása **policy-violation** — a user-direktíva
explicit szövege szerint "halucináció, mellébeszélés, lustaság, halogatás,
tévedés és butaság" tiltott. Az AI ügynök TILOS hogy "kész"-nek jelölje a
session-t, ha bármelyik kötelező ellenőrzés nem futott le vagy nem zöld.

## Kapcsolódó vault dokumentumok

- [`ai-review-mandate-zero-tolerance.md`](ai-review-mandate-zero-tolerance.md) — minden P0/P1/P2 kötelező javítás
- [`hallucinacio-megszuntetese.md`](hallucinacio-megszuntetese.md) — research-first, Context7, iparági standardok
- [`lint-ci-codex-sourcery-every-pr-mandatory.md`](lint-ci-codex-sourcery-every-pr-mandatory.md) — minden PR-en kötelező CI+Codex+Sourcery+Copilot
- [`no-hallucination-lateral-thinking.md`](no-hallucination-lateral-thinking.md) — TILOS találgatás, csak fact-based döntés
