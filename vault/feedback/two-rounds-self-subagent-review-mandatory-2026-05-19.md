---
title: "Kétkörös SAJÁT subagent self-review merge előtt — kötelező P0 mandate"
status: active
priority: P0
hatály: 2026-05-19 15:45+ CEST
forrás: Kósa Zoltán user-direktíva (2026-05-19 15:45 CEST, PR #700 V240 review-flow közben)
related:
  - vault/feedback/two-rounds-before-merge-mandatory-2026-05-19.md (P0 #697 — CI + AI gate)
  - CLAUDE.md C.10 (Zero-Tolerance AI review)
---

# Kétkörös SAJÁT subagent self-review merge előtt — KÖTELEZŐ P0

> ⚠️ **HATÁLY-PONTOSÍTÁS (2026-06-15):** **NEM always-on**. Az adverzariális
> subagent-review **merge/deploy/magas-kockázat** előtt kötelező — normál feladatra
> a célzott self-review elég (`AGENTS.md` §4; `_active_mandates.md` deprecálta a
> „kötelezett kétkörös self-review normál feladatnál" formát). A merge-előtti mag marad.

## A szabály

> "Neked kell kétszer ellenőrizned a saját ai közeiddel egy másik ügynökkel
> az elkészült kódot, és csak utána mergeld, ne csak a AI botokra hagyatkozz,
> hanem saját magadat is kötelező kétsoron ellenőrizned egy ügynököddel
> az általad írt kódot."

## A 2 saját kör (a meglévő CI + AI gate KIEGÉSZÍTÉSE, NEM helyettesítése)

### 1. Saját Round 1 — subagent code review
- `Agent` tool meghívása `general-purpose` (vagy domain-specifikus) subagent-tel
- A subagent fókusza: **kódminőség + reproduktálható logika + edge case**
- A subagent feladata: report ONLY genuine problems (NEM stylistic)
- Párhuzamosíthatóak több ügynökök (különböző fókusszal)

### 2. Saját Round 2 — verify Round 1 concerns + új ügynökkel
- A Round 1 által flagged-elt aggályokat **verifikálni** kell (pl. column-létezés, FK-konzisztencia)
- ÚJABB subagent independent eye-vel (fresh context)
- ÚJ issue-kat is keres, nem csak verify

### KIEGÉSZÍTI (NEM helyettesíti) a CI + AI gate-et

A teljes merge-protokoll:
1. **CI gate** (`gh pr checks` → mind zöld)
2. **GitHub AI gate** (Codex/Sourcery/Copilot/CodeQL → all P0/P1/P2 fixed)
3. **SAJÁT subagent Round 1** (general-purpose agent code review)
4. **SAJÁT subagent Round 2** (verify Round 1 + új fresh agent)
5. **CSAK akkor admin-merge** ha mind a 4 zöld

## Mikor érvényes

Minden merge előtt, kivéve:
- Pure docs commit (csak .md fájl)
- HOTFIX kritikus production outage-re (külön user-direktíva kell)

## Trigger példa

**PR #700 (V240 BR026 + bank_code follow-up):**
- GitHub AI gate: Codex P2 + 3× Copilot P2 → mind javítva (round 1+2)
- SAJÁT Round 1: 2 párhuzamos general-purpose ügynök (SQL/Flyway fókusz + multi-tenant/safety fókusz) → mindkettő SAFE TO MERGE
- SAJÁT Round 2: új general-purpose ügynök verifikálta a Round 1 4 aggályát (`branch.updated_at` V0_1:57 column-létezés, V145 re-run risk, V239 production state, IS DISTINCT FROM NULL semantics) → mind feloldva

## Indok

A 2026-05-19 PR #699 / #700 cikluson kiderült: a GitHub AI botok (Codex, Copilot)
**nem mindig veszik észre** a teljes hatókört. Példa: a V239 `bank_code='BR009'`
template-clone hibát Copilot felvette (8 értéktár), de a **CODEX külön P2-ben**
észrevette, hogy **új-install path-on** BR026 is hibás. Egy önálló subagent
review-val a teljes bug-ot kell behatárolni.

## Tilos

- ❌ "AI botok elég" — saját subagent kötelező
- ❌ "Csak 1 saját kör" — kétkör kötelező
- ❌ Subagent verdikt verifikálás nélkül — a Round 2 specifikusan VERIFY-fókuszú
