---
title: 2026-05-12 - Teljes handoff es memoria mentes (v2.5.48)
type: handoff
created: 2026-05-12
status: active
version: 2.5.48
repo: D:\repo\valutavalto-program
memory_status: synced
---

# Handoff - valutavalto-program v2.5.48

## TL;DR

A repo jelenlegi fejlesztesi iranya negy osszehangolt kliens/blokk:

- Penztar: lokalis Electron, `appMode=penztar`, default route `/cashier`.
- Ertektar: lokalis mukodes a penztar kliensen belul, `appMode=ertektar`,
  default route `/treasury`.
- RFM / arfolyamkeszito: kulon lokalis Electron, `appMode=rate-maker`,
  default route `/rates/creation`.
- Kozponti iranyitokozpont: kulon lokalis Electron, `appMode=full`,
  default route `/central-workstation`.

Legfontosabb user-direktivak:

- Minden uj telepito nagyobb verzioszamot kap.
- Minden telepito a `C:\Users\Kósa Zoltán\Downloads` mappaba kerul.
- Telepito keszitese elott kotelezo a negy terulet kommunikacios vegpontjainak
  ellenorzese: `npm run check:four-area-alignment`.
- CI/Sourcery/GitHub/Copilot/Codex hibakat az AI olvassa ki, nem a user masolja.
- Nem sorokat, hanem teljes logikai blokkokat javitunk.
- Minden lint/push/merge/deploy elott kotelezo onellenorzes.
- Repo-memoriat minden erdemi workflow utan frissiteni kell.

## Jelenlegi telepitok

Downloads mappaban leteznek:

- `C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.48.exe`
- `C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.48.exe`
- `C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.48.exe`

Ismert SHA256 ertekek a korabbi buildbol:

- Penztar: `53C8BA6887772D3699D66F9A9152AF03CDF819C6DA2A3D5C93EBBD1CB54AD430`
- Arfolyamkeszito: `8178408E46C60915EE49DD85C1A3ADA0888403D0C19AF2BEC99BC6947D9617E7`
- Kozponti: `DC2A03659EC09A9BC197B44241284F4F443BF9A94E0AD8460CB96995CC712714`

Uj telepito keszitesekor mar nem maradhat 2.5.48; kotelezo verzioemeles.

## Mai fo dontesek es implementaciok

### 1. Kulon lokalis arfolyamkeszito

A foertektaros nem a szerveren, hanem kulon helyi Electron alkalmazasban kesziti
az arfolyamot. A kliens a szerveren keresztul kommunikal a penztarakkal.

Fontos memoria:

- `docs/architecture/local-rate-maker-architecture.md`
- `vault/procedures/local-rate-maker-publication.md`
- `vault/sessions/2026-05-12-local-rate-maker-architecture.md`
- `vault/sessions/2026-05-12-arfolyamkeszito-installer-build.md`

### 2. Kozponti iranyitokozpont

A legacy szerver-mappaban talalt kulon exe/dll funkciok modern kozponti helyi
munkaallomasba kerultek. Nem kozvetlen DB-hez nyul, hanem backend API-n keresztul
mukodik.

Fontos memoria:

- `docs/architecture/central-workstation-legacy-module-inventory.md`
- `vault/sessions/2026-05-12-server-legacy-module-inventory.md`
- `vault/sessions/2026-05-12-kozponti-iranyitokozpont-electron.md`
- `vault/sessions/2026-05-12-central-workstation-sprint.md`
- `vault/sessions/2026-05-12-central-workstation-services-completion.md`

### 3. Kozponti moduljogosultsagi manifest

Friss gap volt: a memoria backend module-permission manifestet kert, de a
kozponti launcher korabban frontend role-listabol dontott.

Implementalt:

- `backend/src/main/java/hu/puzzleir/valuta/util/CentralModuleManifest.java`
- `LoginResponseDto.centralModules`
- `WorkerService.login(...)`
- `GoogleLoginService.loginWithGoogle(...)`
- `AuthController.selectRole(...)`
- `frontend-react/src/stores/authStore.ts`
- `frontend-react/src/pages/central/CentralWorkstationPage.tsx`

Fontos memoria:

- `vault/sessions/2026-05-12-four-block-central-module-manifest.md`

### 4. Google OAuth auto-detection

Vezetoi/kozponti dolgozok Google OAuth-tal lepnek be. Az email alapjan a
master data azonositja a dolgozot, fiokot es szerepkort. Penzterosoknek marad
a jelszavas belepes.

Fontos memoria:

- `docs/architecture/google-oauth-auto-detection-setup.md`
- `vault/references/google-oauth-auto-detection-setup.md`
- `vault/sessions/2026-05-12-google-oauth-auto-detection-setup.md`

Titokkezeles: valodi client secret nem kerulhet chatbe vagy repo-ba.

### 5. Parallax / AgentWard repo-adaptacio

A user Parallax-ugynokhalozati utasitascsomagjabol a repo-ban kikenyszeritheto
reszek implementalva lettek:

- `scripts/agentward-guard.mjs`
- `scripts/agent-decision-log.mjs`
- `vault/procedures/parallax-agentward-protocol.md`
- `vault/agent-archive/decision-log.jsonl`
- `AGENTS.md` bovites
- `package.json` self-check kapukba bekotes
- `scripts/pre-push-quality-gate.ps1` guard bekotes
- `.gitignore` OAuth client secret JSON mintak tiltasa

Tudatos korlat: eBPF, fizikai MCP gateway vagy kulso OIDC gateway nem repo-szinten
implementalhato. A repo guard csak azt ellenorzi, amit lokalisan lehet.

Fontos memoria:

- `vault/sessions/2026-05-12-parallax-agentward-implementation.md`
- `vault/procedures/parallax-agentward-protocol.md`

## Kotelezo parancsok

Altalanos onellenorzes:

```powershell
npm run self-check:before-lint
```

Négy blokk osszhang:

```powershell
npm run check:four-area-alignment
```

AgentWard / titok / blocklist guard:

```powershell
npm run agent:guard
```

CI/review hiba digest:

```powershell
npm run ci:errors
```

Push elott:

```powershell
npm run self-check:before-push
```

Memoria szinkron:

```powershell
npm run memory:sync
```

Memoria statusz:

```powershell
npm run memory:status
```

Dontesi archiv:

```powershell
npm run agent:archive -- --summary "..." --type decision --status completed
```

## Legutobbi sikeres ellenorzesek

Friss handoff elott futott:

- `npm run memory:status`: QMD/YAML/Cognee/vector/Obsidian/reports OK,
  Cognee HTTP status 200, Obsidian Local REST status 200.
- `npm run memory:sync`: Obsidian sync status 204.
- `npm run self-check:before-lint`: four-area OK, AgentWard OK, CI digest 0 finding.
- `npm run lint`: 0 error; 217 ismert `i18next/no-literal-string` warning maradt.

## Munkaallapot / dirty tree

A repo jelenleg szandekosan erosen dirty. Sok fajl korabbi mai sprintbol es
mostani memoria/guard munkabol modosult vagy uj.

Fontos: ne revertalj ismeretlen vagy user/elozo agent altal keszitett valtozast.
Ha commit/push kovetkezik, eloszor `git status --short` es blokk-szintu diff
self-review kell.

Kulcs uj/valtozott elemek a mai munkabol:

- `arfolyam-keszito-client/`
- `kozponti-client/`
- `scripts/check-four-area-alignment.mjs`
- `scripts/check-three-client-endpoints.mjs`
- `scripts/ci-error-digest.mjs`
- `scripts/agentward-guard.mjs`
- `scripts/agent-decision-log.mjs`
- `backend/src/main/java/hu/puzzleir/valuta/util/CentralModuleManifest.java`
- `backend/src/test/java/hu/puzzleir/valuta/util/CentralModuleManifestTest.java`
- `frontend-react/src/pages/central/`
- `vault/agent-archive/`
- `vault/procedures/parallax-agentward-protocol.md`
- `vault/sessions/2026-05-12-*.md`

## Kockazatok / kovetkezo AI figyelme

- Telepito kesziteshez verzioemeles kell; 2.5.48 mar foglalt.
- Telepito keszites elott kotelezo a negy blokk vegpont-osszhang check.
- Ha `DEPLOY-INSTRUCTIONS.md` regi JDBC/JWT peldaja valaha eles titok volt,
  titokrotacio + redeploy kotelezo.
- A 217 i18next warning ismert, nem blokkolo, de nagyobb UI sprintnel erdemes
  fokozatosan csokkenteni.
- Az AgentWard guard intentionally fail-closed: ha uj doc valodi secret-szeru
  sort tartalmaz, javitani kell, nem kikapcsolni.
- Obsidian jelenleg elerheto Local REST API-n; memoria szinkronnal a vault tukor
  frissul.

## Handoff utani ajanlott kovetkezo lepes

Ha a user tovabbfejlesztest ker:

1. Olvasd vissza ezt a handoffot.
2. Futtasd: `npm run self-check:before-lint`.
3. Ha telepito kell: verzio bump, `npm run check:four-area-alignment`, majd csak
   ezutan package, es a kesz `.exe` menjen Downloads-ba.
4. Ha CI/review hiba van: `npm run ci:errors -- --pr <PR>` vagy
   `scripts/github-signal-check.ps1 <PR>`.
5. Minden erdemi workflow utan: `npm run memory:sync` es uj session memoria.
