---
name: valutavalto-platform-architecture
description: >-
  Use for any Valutavalto Electron client or packages/** change. Enforces
  client→platform only (never client→client), extraction criteria, boundary
  gate, suite vs electron-updater topology, and CI dependency pitfalls.
---

# Valutaváltó — platform-first Electron

Load on every change under `penztar-client/electron/**`,
`kozponti-client/electron/**`, `packages/**`, any "extract to shared"
request, or a failing `npm run check:platform-boundaries`.

Hermes long form (read if this file is not enough), when Hermes is
installed — machine-local path, resolve from the env var:
`$HERMES_HOME/skills/software-development/valutavalto-platform-architecture/SKILL.md`

## Binding rule (CI-blocking)

**Client → platform may import. Client → CLIENT never.**
Shared code goes in `packages/electron-platform` (or `local-first-core`,
`shared-ipc`, `shared-api`, `shared-logging`). Gate:
`npm run check:platform-boundaries` (`scripts/check-platform-boundaries.mjs`).
CI: `business-invariant-guard.yml` #15.

Only **proven-identical** logic may be extracted (diff/clone measurement,
not eyeballing). Client-specific difference = **required parameter**,
never a hidden file-level default.

## Topology (do not mix)

| | Pénztár | Központi |
|---|---|---|
| Installer | hand-written `installer/Penztar-Setup.nsi`, per-machine | electron-builder, per-user |
| Updater | **suite-updater** + `update-manifest.json` (Electron+JAR+JRE+PostgreSQL+NSSM) | `electron-updater`, `munkaallomas.yml` |

Uploading `penztar.yml` to a GitHub Release is forbidden (CI gate):
electron-updater would resolve a second install. Pénztár install only in
`IDLE_BEFORE_OPEN` / `CLOSED_AFTER_DAY_END`; `SHIFT_OPEN` = download only.

`arfolyam-keszito-client` is legacy leftover: no standalone installer;
rate-maker is a kozponti flavor.

## New shared module

1. `npm run memory:query -- "<kw>" --area <area>`
2. Prove identity.
3. `packages/electron-platform/src/<mod>.ts` + export from `src/index.ts`
4. Client shim < 80 lines
5. `npm run typecheck` (all clients + platform) ·
   `npm run check:platform-boundaries` ·
   `npm --prefix penztar-client run test:unit` ·
   `node scripts/check-version-sync.mjs`
6. New platform npm dependency → `npm ci` in **both**
   `windows-signed-release.yml` installer jobs, else release fails not the PR.

## Pitfalls (measured)

- `userData` is keyed off `package.json` `name`, not appId — do not
  harmonize names.
- Resolve `app.getPath('userData')` at **call time**, never module-level const
  (`#ERR-INST-01`). kozponti sets path after `app.setPath` for rate-maker.
- Worktree `node_modules` is a false green. Repro CI TS2307 by deleting it.
- NSIS `!include` of a shared macro is unusable (makensis CWD) —
  duplicate installer snippets are intentional; guard:
  `installer/tests/installer-cleanup-parity.tests.ps1`.
- Platform barrel pulls `electron-log` → import pure functions from the
  module file in unit tests, not the barrel.

## After the change

Renderer/Electron code does **not** reach offices via `deploy-hetzner.yml`.
Say so. Signed installer only.
