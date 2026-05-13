---
title: CI hibauzenet beolvasas es blokk-szintu javitas
type: procedural-memory
trigger: "Lint, merge, push, deploy, CI failure, Sourcery/Codex/Copilot/GitHub jelzes"
authority: KOTELEZO user direktiva
created: 2026-05-12
sources:
  - user directive 2026-05-12: CI hibakat az AI olvassa ki, nem a felhasznalo masolja
  - scripts/ci-error-digest.mjs
  - scripts/github-signal-check.ps1
---

# CI hibauzenet beolvasas es blokk-szintu javitas

## Kotelezo szabaly

Az AI ugynok feladata kiolvasni a teljes CI/review hibakepet. A felhasznalotol nem kerhetjuk, hogy Sorcery, GitHub Actions, Copilot vagy Codex hibakat kezzel bemasoljon.

## Forrasok

- GitHub Actions checkek es failed run logok
- GitHub check-run annotationok
- Sourcery review es inline comment
- Codex review es inline comment
- Copilot review es inline comment
- Lokalis Codex/dev logok: `/tmp/logs`, `/tmp`

## Kotelezo parancsok

```bash
npm run ci:errors -- --pr <PR>
```

Blokkolo ellenorzeshez:

```bash
npm run ci:errors -- --pr <PR> --fail-on-findings
```

PR minosegi jelzeshez:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/github-signal-check.ps1 <PR>
```

Push elott:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/pre-push-quality-gate.ps1
```

## Javitas elve

- Nem kiragadott sorokat javitunk.
- A teljes hiba-blokkot, a kornyezetet es az erintett logikai kodblokkot kell ertelmezni.
- Egy hiba valodi oka alapjan kell javitani, nem egymas utani apro talalgato patch-ekkel.
- Ha a finding egy teljes validacios, jogosultsagi, adatfolyam vagy publikacios folyamatot erint, akkor azt a teljes folyamatblokkot kell rendbe tenni.

## Kotelezett kapuk

- Lint elott: `npm run self-check:before-lint`
- Push elott: `npm run self-check:before-push`
- Merge elott: `npm run self-check:before-merge`
- Deploy elott: `npm run self-check:before-deploy`

## Kimenet

Az automatikus digest minden futasnal `.agent/ci/` ala ir:

- osszefoglalo markdown
- bukott Actions run nyers logja, ha elerheto
- teljes hiba-blokkok kontextussal

Megjegyzes: a `.agent/ci/` lokalis/ignored kimenet, mert futasi logokat es potencialisan erzekeny kornyezetet tartalmazhat.

## Tiltott mintak

- "Kuldd el a hibat, bemasolom" - tilos.
- Egyetlen sor alapjan javitas teljes blokk olvasasa nelkul - tilos.
- Lint/push/merge/deploy onellenorzes nelkul - tilos.
- `--no-verify` vagy ellenorzes megkerulese - tilos.
