---
title: Memóriahasználati és tudáskarbantartási protokoll (KÖTELEZŐ)
date: 2026-05-04
author: Kósa Zoltán
priority: critical
applyTo: all-ai-agents
status: active
hatalyba_lepes: 2026-05-04
---

# Memóriahasználati és tudáskarbantartási protokoll — KÖTELEZŐ

> **2026-05-04 user-direktíva (Kósa Zoltán):**
>
> "Ez az utasítás kötelező érvényű minden mesterséges intelligencia ügynök számára.
> A repoban végzett minden munkamenetben kötelező a rendelkezésre álló
> memóriaforrások beolvasása, tényalapú használata, folyamatos frissítése, a
> session végén pedig kötelező memória mentése. A memória nem találgatások
> tárolója: csak ellenőrzött tapasztalatot, reprodukálható megoldást, valós hibák
> okát, tényleges projektkonvenciót és használható összefüggést rögzíthet
> releváns tudásként."

## A protokoll hatálya

Minden mesterséges intelligencia ügynök (Claude, OpenAI Codex, Cursor, Gemini,
Antigravity, GitHub Copilot CLI), amely ebben a repositoryban dolgozik —
függetlenül attól, hogy kódot módosít, hibát javít, dokumentációt készít,
adatot dolgoz fel, lokális automatizmust futtat, tesztet ír, CI/deploy folyamatot
vizsgál, vagy csak elemzést végez.

## A teljes protokoll szöveg

A teljes, gépileg betöltődő always-on rule-t lásd:
[`.cursor/rules/mandatory-memory-protocol.mdc`](D:\repo\valutavalto-program\.cursor\rules\mandatory-memory-protocol.mdc)

A CLAUDE.md projekt-szintű utasításokba is be van vezetve:
[`CLAUDE.md` "MEMÓRIAHASZNÁLATI PROTOKOLL" szekció](D:\repo\valutavalto-program\CLAUDE.md)

## Kötelező memóriaforrások (ebben a repoban aktív)

- **CLAUDE.md** (auto-load)
- **AI_CONSTITUTION.md** (10 nem-alkukepes szabály + 7 tiltás)
- **AGENTS.md / CODEX.md / VSCODE.md / ANTIGRAVITY.md** (multi-AI)
- **`.cursor/rules/*.mdc`** (always-on Cursor rule-ok)
- **Repo-local Obsidian vault** `D:\repo\valutavalto-program\vault\` (sessions, feedback, procedures, references)
- **`.remember/remember.md`** (quick-state handoff)
- **`docs/LESSONS_LEARNED.md`**
- **`docs/knowledge/memory/*.yaml`** (historikus, csak olvasni)

**DEPRECATED** (NE használd): `~/.claude/projects/.../memory/`, `.memory/` SQLite,
Cognee MCP, OpenClaw refek.

## Kötelező 3 fő ciklus

### 1. Session-eleji memóriaolvasás
- Releváns memóriaforrások azonosítása + beolvasása
- Aktív alkalmazás (NEM csak hivatkozás)
- Repo aktuális állapot győz, ha memória ellentmond

### 2. Munka közbeni memóriafrissítés
- Bizonyított root cause / hibajavítás / sikeres parancs / projektkonvenció / felhasználói preferencia / elkerülendő minta / külső szolgáltatás viselkedése / biztonsági tanulság / deploy tapasztalat / összefüggés
- TILOS: tipp, feltételezés, debug zaj, titok/token/jelszó/credential, szükségtelen személyes adat

### 3. Session-zárási memóriamentés
- Repo-local vault `sessions/YYYY-MM-DD-rovid-leiras.md` (új session-jegyzet)
- Repo-local vault `feedback/<topic>.md` (új user-direktíva)
- Repo-local vault `procedures/<workflow-name>.md` (workflow)
- Repo-local vault `references/<topic>.md` (új projekt-tudás külső forrásból)
- `.remember/remember.md` (quick-state)
- CLAUDE.md "Aktuális release-állapot" (ha változott)

## Dream funkció (kötelező, tényalapú)

Csendes memória-elemzési és összefüggéskereső folyamat. **NEM fantáziálás.**
- Csak tényekből indul ki
- NEM talál ki új projektállapotot, parancseredményt, felhasználói szándékot
- NEM helyettesíti a tesztet, buildet, lintet, runtime ellenőrzést
- Eredmény kategóriák: `Tanulság`, `Összefüggés`, `Kockázat`, `Javasolt gyakorlat`, `Elavult memória jelölés`
- Kötelező formátum: dátum + kiinduló memóriaforrások + tények + összefüggés + következmény + bizonytalanság + következő ellenőrizhető lépés

## Tiltott memória-minták

- ❌ Hallucináció / találgatás / bizonytalan következtetés
- ❌ Egyszeri véletlen siker rögzítése aktív tudásként
- ❌ Titok / token / jelszó / credential mentése
- ❌ Felesleges személyes adat
- ❌ Forrás nélküli állítás
- ❌ Elavult/hibás memória aktív hagyása
- ❌ Két ellentmondó memória párhuzamos hagyása

## Záró jelentéstétel

Minden session végén tényszerűen jelenteni:
- Milyen memóriaforrásokat olvasott be / frissített
- Milyen új tény/tanulság került mentésre
- Volt-e elavult/hibás memória, amelyet javított vagy jelölt
- Futott-e Dream elemzés, milyen eredménnyel
- Ha nem történt memóriaművelet: az objektív blokkoló ok

## Memória-rétegek (beolvasztva: mandatory-memory-after-each-workflow.md, 2026-06-15)

- rövid távú (állapot/blokkolók/aktív direktívák) · középtávú (handoff, friss workflow-eredmény) ·
  operatív (reprodukálható parancsok, recovery) · hosszú távú (stabil tények, legacy parity, üzleti szabály).
- False-success guard: NE jelents REST/sync sikert, ha csak fájl-bundle készült.

## Kapcsolódó vault dokumentumok

- [`session-closing-protocol-mandatory.md`](session-closing-protocol-mandatory.md) — 9-lépéses session zárás
- [`continuous-testing-protocol-mandatory.md`](continuous-testing-protocol-mandatory.md) — folyamatos tesztelés
- [`ai-agent-push-ci-doctrine-2026-05-17.md`](ai-agent-push-ci-doctrine-2026-05-17.md) — push→CI→AI-review→merge hurok (merge/deploy előtt)
- [`no-hallucination-lateral-thinking.md`](no-hallucination-lateral-thinking.md) — research-first (Context7), iparági standardok, fact-based, NEM találgatás
