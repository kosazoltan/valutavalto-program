---
title: CI hibabeolvasas es onellenorzo kapuk kotelezo mandatuma
date: 2026-05-12
type: session-memory
status: implemented
---

# CI hibabeolvasas es onellenorzo kapuk

## Dontes

Kotelezo ervenyu mukodesi szabaly lett, hogy a CI es AI review hibakat az AI ugynok olvassa ki kozvetlenul. A felhasznalot nem kerjuk Sorcery, GitHub Actions, Copilot vagy Codex hibak kezi bemasolasara.

## Implementacio

- Uj script: `scripts/ci-error-digest.mjs`
  - GitHub Actions bukott run logblokkok
  - check-run annotationok
  - Sourcery review es inline comment
  - Codex review es inline comment
  - Copilot review es inline comment
  - lokalis Codex/dev logblokkok `/tmp/logs` es `/tmp` alatt
  - kimenet: `.agent/ci/*.md` es raw Actions logok
- Root npm scriptek:
  - `npm run ci:errors`
  - `npm run self-check:before-lint`
  - `npm run self-check:before-push`
  - `npm run self-check:before-merge`
  - `npm run self-check:before-deploy`
- `npm run lint` elott automatikusan lefut a `self-check:before-lint`.
- `scripts/pre-push-quality-gate.ps1` lefuttatja a negy terulet osszhang ellenorzest es a CI digestet.
- `scripts/github-signal-check.ps1` PR-hez automatikusan general teljes CI/Sourcery/Copilot/Codex digestet.
- Deploy indito scriptek self-check nelkul nem inditanak deployt.

## Javitas elve

Nem sorokat javitunk, hanem teljes logikai blokkokat. A CI digest teljes hiba-blokkokat ad vissza kontextussal, hogy a javitas ne talalgatasbol es ne token-pazarló mikro-patchekbol alljon.

## Kovetkezmeny

Lint, merge, push es deploy elott kotelezo az onellenorzes. Ha a CI digest blokkolot talal, a munka nem tekintheto kesznek.
