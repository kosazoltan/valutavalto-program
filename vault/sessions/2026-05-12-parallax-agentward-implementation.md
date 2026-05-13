---
title: Parallax AgentWard implementacio
date: 2026-05-12
type: implementation-session
status: completed
---

# Parallax AgentWard implementacio

## Bemenet

A user adott egy Parallax-ugynokhalozati utasitascsomagot: kognitiv es
vegrehajtasi reteg szeparacio, ketlepcsos verifikacio, MCP/skill routing,
AgentWard runtime biztonsag, default-sensitive titokkezeles, OAuth blocklist,
OWASP agentic top 10 es permanent intelligence archive.

## Implementalt repo-szintu elemek

- `scripts/agentward-guard.mjs`: determinisztikus guard a kotelezo agent
  procedura fajlokra, self-check bekotesre, Google OAuth blocklistre es
  secret-like repo mintakra.
- `scripts/agent-decision-log.mjs`: hash-lanccal append-only dontesi naplo.
- `vault/agent-archive/README.md`: archivum hasznalati szabalyok.
- `vault/procedures/parallax-agentward-protocol.md`: operativ memoria es
  eljarasrend.
- `AGENTS.md`: Parallax/AgentWard repo-adaptacio.
- `package.json`: `agent:guard`, `agent:archive` es self-check kapu bekotes.
- `scripts/pre-push-quality-gate.ps1`: AgentWard guard push elotti futtatasa.
- `.gitignore`: Google OAuth client secret JSON fajlnev mintak tiltasa.
- `scripts/repo-memory.mjs`: a `vault/agent-archive` bekerult a memoriaforrasok
  koze.

## Tudatos korlat

Nem allitjuk, hogy eBPF, fizikai gateway izolacio vagy kulso OIDC gateway
infrastruktura repo-szinten teljesen megvalosult. Ezek kulso futtatasi es
platformszintu kovetelmenyek. A repo-ban a kikonyszeritheto reszek lettek
beepitve.

## Elso archiv bejegyzes

`vault/agent-archive/decision-log.jsonl` genesis hash:

```text
3410fccf2bcd1b6fbd2b6566d98eb512b8f7fc4ff95da1d501362444be00f3c9
```

## Verifikacio

- `node --check scripts/agentward-guard.mjs`
- `node --check scripts/agent-decision-log.mjs`
- `node --check scripts/repo-memory.mjs`
- `npm run agent:guard`
- `npm run self-check:before-lint`
- `npm run lint`
- `npm run memory:sync`

Eredmeny: minden futas sikeres. A lint 0 errorral futott le; a repo korabbi
217 `i18next/no-literal-string` warningja tovabbra is ismert, nem ennek a
valtoztatasnak a hibaja.
