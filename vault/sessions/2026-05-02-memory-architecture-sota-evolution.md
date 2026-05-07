---
date: 2026-05-02
title: Vault evolution — 2026 SOTA memory architecture adoption
type: meta-improvement (vault szerkezet)
trigger: user-direktíva "olvasd el az alábbi szöveget [3 SOTA trend], készíts memóriát, ellenőrizd a jelenlegi memória korszerűségét"
duration: ~30 perc
related-prs: nincs (vault-only, nem érinti a repo-t)
---

# Vault evolution — 2026-05-02

## TL;DR

User megosztott egy 2026-os state-of-the-art memória-architektúra leírást (3 trend: Zep temporális gráf, Letta multi-tier, Mem0 procedurális). Megkérte:
1. Készítsek memóriát a vault-ba
2. Ellenőrizzem a jelenlegi vault-rendszer korszerűségét
3. Internetes kutatással pontos kódrészletekkel fejlesszem

Eredmény: **2 új reference + 2 új procedural memory + README-frissítés** a vault-ban. A jelenlegi rendszer **3-ból 1 SOTA képességet hiányolt** (procedurális memória strukturáltsága), most ezt implementáltuk.

## Mi történt

### Kutatás (WebSearch + WebFetch)
A 3 trend pontos kódrészleteit gyűjtöttem be:
1. **Zep / Graphiti**: Python `graphiti.add_episode()` + bi-temporal `valid_at` / `invalid_at`
2. **Letta**: `client.agents.create(memory_blocks=[...])` core/recall/archival pattern
3. **Mem0**: `m.add(messages, agent_id, memory_type="procedural_memory")`

### Új vault fájlok
| Path | Tartalom |
|---|---|
| `references/2026-memory-architecture-sota.md` | 3 trend pontos kódrészlettel |
| `references/vault-evolution-gap-analysis.md` | Jelenlegi vault vs SOTA, prioritizált javaslatok |
| `procedures/push-merge-cycle.md` | Strukturált workflow (trigger + steps + verify + failure recovery) |
| `procedures/research-first-fix.md` | Strukturált workflow a hibajavításra |
| `README.md` | Frissítve az új struktúrával + memóriatípus mapping |

### Architektúrális döntés
A vault marad **fájlrendszeres** (Obsidian-kompatibilis, kis-közepes projekt-méret), NEM állunk át Neo4j / vector DB rendszerre. De az új `procedures/` mappa **strukturált YAML frontmatter-rel** strukturálttá teszi a workflow-kat.

## Megállapítások

### Mit kapott a vault (P0 fejlesztések)
- ✅ **Procedurális memória**: új `procedures/` mappa a workflow-knak
- ✅ **SOTA reference**: a 3 trend dokumentálva pontos kódrészletekkel
- ✅ **Gap-analízis**: explicit lista mire van még hely a jövőben

### Mit halasztunk (P1+)
- ⏳ **Bi-temporal validity** (`valid_until` / `superseded_by` minden frontmatter-be) — későbbi session
- ⏳ **Multi-tier explicit** (külön `archival/` mappa régi session-eknek) — későbbi session
- ⏳ **Knowledge graph** — projekt méret még nem indokolja (~20 fájl)

### Stale tény-példa (illusztráció a temporal gap-re)
A `CLAUDE.md` "Aktuális release-állapot" szekció **2026-04-29-i v2.3.7** állapotot tartalmazott a P0-ban. Időközben már **v2.5.2** a current installer (2026-05-01-i atomic sprint), de a CLAUDE.md hivatkozása nem frissült. **Ez pontosan az a probléma, amit a Zep `invalid_at` automatikusan kezelne.** Manuálisan a CLAUDE.md frissítés (most, ebben a session-ben mellékesen, már megtörtént a 2026-05-02-i memóriafrissítés keretében — a v2.5.3 sprint mergelése után).

## Verify

- [x] 2 új reference fájl a vault-ban (összesen 13 KB)
- [x] 2 új procedural workflow a `procedures/` mappában (~7 KB)
- [x] README.md frissítve az új struktúrával + memóriatípus mapping
- [x] Sources hivatkozott külső URL-ekkel (Zep arXiv, Letta docs, Mem0 blog, ReasoningBank)

## Hivatkozások

- [SOTA reference](../references/2026-memory-architecture-sota.md)
- [Gap-analízis](../references/vault-evolution-gap-analysis.md)
- [Push-merge workflow](../procedures/push-merge-cycle.md)
- [Research-first workflow](../procedures/research-first-fix.md)
