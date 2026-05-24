# Session: G22 54-csempe munkacsoport-rács UI — v2.26.38 (2026-05-24)

## Összefoglaló

A G22 sub-scope (utolsó befejezetlen tervrészlet) lezárva: a TCSOPORTDISPLAY legacy
54-csempe munkacsoport-rács vizuális paritása az RFM árfolyamkészítőben.

### PR #828 — G22 54-csempe munkacsoport-rács (v2.26.38)

**Háttér:** A 23/23 EXCMD gap már KÉSZ volt; a G22 számítási mag (rfmRules.ts: EUA ×1.2,
Raiffeisen ±10%, R/S, kereszt) + TLIMITALLITOFORM limit-setter (Alsó/Középső/Felső) már
implementálva (PR #792, v2.26.23). Az egyetlen hátralévő elem a TCSOPORTDISPLAY
**vizuális csempe-rács** volt — a munkacsoport-választó addig apró `w-6 h-6` számozott
gombokból állt.

**Változás (tisztán frontend-react UI):**
- `RateCreationPage.tsx` munkacsoport-választó: apró számozott gombok → 2-oszlopos
  csempe-rács (`grid grid-cols-2`, `max-h-52 overflow-y-auto`)
- Csempénként: legacy csoportszám (`legacyGroupNumber`) + munkacsoport-név (truncate) +
  iroda-darabszám (`wg.branches.length`)
- Aktív/inaktív vizuális megkülönböztetés (zöld vs szürke), kiválasztott = telt zöld
- `title` tooltip: teljes név + iroda-szám
- Verzió-bump 2.26.37 → 2.26.38 (mind az 5 package.json + backend/pom.xml)

## CI/AI review gate

- **Minden CI check ZÖLD:** Backend Build+Test, frontend Lint+TypeCheck, Playwright
  (Auth Reload Smoke), CodeQL/Analyze ×3 (actions/java-kotlin/javascript-typescript),
  GitLeaks, Trivy Backend SCA, npm audit, Dependency Review, UTF-8 Guardrail, auto-fix.
- **Copilot review:** 0 finding ("generated no comments") — tiszta.
- **Sourcery:** weekly rate-limit (2.5M diff char) — zaj, nem blokkoló.
- **Merge:** admin-merge (REVIEW_REQUIRED branch protection, user-jóváhagyott), squash
  `85c582d09`, branch törölve.

## Verzió / telepítő

**v2.26.38 — server-served, NINCS telepítő-build szükséges.** A változás kizárólag
`frontend-react/` (+ verzió-fájlok) → Hetzner auto-deploy a kollégákhoz, Electron-natív
réteg érintetlen. A build-stratégia döntési teszt szerint (`git diff` csak frontend-react
+ verzió) → nincs 283 MB-os build.

## Production állapot

- Hetzner deploy: backend HEALTHY `/api/v1/auth/bootstrap-status` → 200
- Main HEAD: `85c582d09`

## Tanulságok

- A TCSOPORTDISPLAY paritás már funkcionálisan kész volt (választó + limit-setter); a G22
  "sub-scope" tisztán esztétikai/UX javítás volt — a számozott gombok helyett a legacy
  54-csempe vizuális megjelenítés (név + iroda-szám csempénként).
- A `WorkgroupDetailDTO.branches: WorkgroupBranchInfo[]` mező miatt a `wg.branches.length`
  típushelyes — nem kellett új API-hívás az iroda-számhoz.
- Auth-redirect miatt a `/rates/creation` böngészős vizuális verifikáció nem volt
  lehetséges (login-fal) → `tsc --noEmit` (0 hiba) + lint (0 hiba) a bizonyíték.

## Hátralévő (alacsonyabb prioritás, Should)

- FR-RFM-22 "Aktuális függvény" kijelzés — nem implementálva
- FR-RFM-23 Kitöltési segítség — nem implementálva
