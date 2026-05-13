---
title: Parallax AgentWard repo-protokoll
type: operational-procedure
trigger: "AI agent munka, lint, push, merge, deploy, titokkezeles, OAuth/OIDC"
authority: KOTELEZO user direktiva
created: 2026-05-12
status: active
sources:
  - user directive 2026-05-12: PARALLAX-UGYNOKHALOZATI RENDSZERUTASITAS
  - scripts/agentward-guard.mjs
  - scripts/agent-decision-log.mjs
---

# Parallax AgentWard repo-protokoll

## Cel

A user altal adott Parallax/AgentWard utasitascsomag repo-kompatibilis
beepitese. Ez a dokumentum nem irja felul a futtatokornyezet rendszerutasitasait,
hanem a valutavalto repo munkafolyamatait erositi: determinisztikus scriptek,
validacios kapuk, memoria es auditnaplo.

## Repo-szintu lekepzes

- Cognitive layer: intent ertelmezes, terv, memoriaolvasas, skill/procedure
  valasztas.
- Execution layer: minden ismetelheto ellenorzes scriptbe kerul, nem ad hoc
  shell-talalgatasba.
- Local verifier: `scripts/agentward-guard.mjs`, `check-four-area-alignment.mjs`,
  typecheck, lint, teszt.
- Global verifier: AGENTS.md, vault memoria, CI digest, GitHub/Sourcery/Codex
  jelzesek, dontesi archivum.

## Kotelezo futasi kapuk

- Lint elott: `npm run self-check:before-lint`
- Push elott: `npm run self-check:before-push`
- Merge elott: `npm run self-check:before-merge`
- Deploy elott: `npm run self-check:before-deploy`
- Kezi Parallax/AgentWard guard: `npm run agent:guard`
- Dontesi archivum: `npm run agent:archive -- --summary "..."`

## Titokkezeles

- Minden env ertek alapbol sensitive. Repo-ba csak placeholder vagy pelda kerulhet.
- Google OAuth client secret JSON fajl nem commitolhato.
- Hosszu eletu token vagy refresh token nem kerulhet repo-fajlba.
- Titokrotacio utan kotelezo redeploy es uj verifikacio.
- Blokkolt OAuth client ID:
  `110671459871-30f1spbu0hptbs60cb4vsmv79i7bbvqj.apps.googleusercontent.com`

## AgentWard ot retege

1. Foundation scan: package script es kotelezo file jelenlet.
2. Input sanitization: blocklist es secret-like scan.
3. Cognition protection: memoria/procedure file-ok lete es sync.
4. Decision alignment: eredeti intent kontra aktualis terv a vegrehajtas elott.
5. Execution control: amit repo-szinten lehet, script-kapukban; eBPF/sandbox
   a futtatokornyezet feladata, nem allithato be puszta repo-dokumentacioval.

## Tiltott allitas

Tilos azt mondani, hogy eBPF, gateway OIDC vagy fizikai retegizolacio
tenylegesen be van vezetve, ha csak repo-szintu guard es eljaras keszult.
Mindig pontosan meg kell kulonboztetni:

- implementalt repo-kapu,
- dokumentalt szabaly,
- kulso infrastruktura igeny.
