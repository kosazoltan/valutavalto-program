# 2026-05-23 — Verzió- és telepítő-build stratégia (token/idő-spórolás)

## User-direktíva
"Térjünk át minor/major verziókra a telepítők készítésénél. Tesztelői javítás (szűk
szkóp) → minor; teljes refaktor/revízió → csak a lezáráskor major telepítő."

## Döntés (AskUserQuestion megerősítve)
- **Build-trigger: Electron-natív VAGY milestone.** A tisztán backend/frontend-react
  (server-served) javítások merge+deploy-jal mennek, EXE nélkül.
- A futó v2.26.25-öt befejeztük (utolsó patch-telepítő a régi módon); az új szabály a
  következő változástól él.

## Kulcs-elv: a merge ≠ telepítő
- frontend-react + backend MINDEN merge után Hetzner auto-deploy (excvaluta.com).
- Electron-kliensek a szerverről töltik a frontendet → webes/backend fix azonnal náluk.
- 283 MB Penztar LZMA-build = a drága rész → CSAK indokolt esetben.

## Mikor KELL telepítő-build
1. **Electron-natív réteg:** `*/electron/*` (sync-engine, sqlite, scanner, IPC, soros
   nyomtató, preload, main), natív npm-dep, bundle-elt JRE, auto-update baseline.
2. **Milestone:** minor (2.MINOR.0) tesztelhető csomag VAGY major (MAJOR.0.0) revízió vége.

## Verzió-szintek
| Szint | Mikor | Telepítő |
|---|---|---|
| PATCH 2.26.x | minden PR | ❌ csak merge+deploy |
| MINOR 2.27.0 | tesztelhető csomag / Electron-natív | ✅ 1 build batch-végén |
| MAJOR 3.0.0 | teljes revízió/refaktor lezárva | ✅ 1 build milestone-on |

## Döntési teszt release-záráskor
`git diff main~N..main --name-only` → ha CSAK `backend/**` + `frontend-react/**`
(nincs `*/electron/**` / natív dep) → NINCS build. Egyébként build.

## Megtakarítás
PR-enként ~5-8 perc build + teljes release-ceremónia (SHA/Downloads/anchor/vault/PR)
→ csak batch-pontokon. A javítások deploy-cadenciája NEM lassul (per-merge marad).

Rögzítve: CLAUDE.md "KÖTELEZŐ ÉRVÉNYŰ: Verzió- és telepítő-build stratégia".
