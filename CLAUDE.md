# Valutavalto ERP - Claude/agent projektkontekstus

Elsodleges agent-szabaly: `AGENTS.md`. Ez a fajl csak a projekt legfontosabb
domain- es parancskontekstusa, hogy az agent ne vesszen el hosszu mandate-ekben.

## Projekt

Magyar valutavalto / penzvalto ERP. Domain: vetel, eladas, storno, napzaras,
cimletezes, arfolyam, atadas-atvetel, foglalo.

## Munkamod ebben a repoban

- Builder-first: a cel mukodo kod vagy celzott dokumentaciojavitas.
- Olvass celzottan, kodolj, majd ellenorizz kockazataranyosan.
- Ne tolts be minden `vault/**` vagy historikus mandate fajlt session-startkor.
- Teljes security/deploy gate csak deploy/release vagy security/auth/dependency/CI
  valtozasnal kotelezo.
- Ha ugyanaz a hiba ket kor utan megmarad, valts diagnosztikai tengelyt; ne
  futtasd ujra ugyanazt a gate-et.

## Token-optimalizacio es model-routing (agent-kotelezo)

- Prompt Caching: stabil kontextus elol, volatilis tartalom hatul; `cache_control`
  minden Claude API-integracioban. Reszletek:
  `vault/feedback/prompt-caching-mandate-2026-06-10.md`.
- Dynamic Model Routing: Fable 5 csak komplex/penzu-gyi/security feladathoz;
  Sonnet/Haiku rutin szerkesztesre; Explore-subagent L1/L0-on. Reszletek:
  `vault/feedback/fable5-optimization-mandate-2026-06-10.md`.
- Cache-biztos routing (hibrid): a fo loop modelljet sessionon belul nem valtjuk
  (a cache modell-scoped, a valtas kiuti a teljes prefixet); olcsobb modell csak
  subagentben vagy /clear utani uj taskban. CLAUDE.md/AGENTS.md/mandate szerkesztest
  kotegelve. Reszletek + Console-diagnosztika a prompt-caching mandate-ben.
- Context Window: >80% token-terheltsegnel /clear ajanlott uj independent taskhoz.
- Task Completion: csonka deliverable TILOS; `max_tokens` explicit API-hivasokban.
- Fallback Signaling: `[WARNING: MODEL_REGRESS_DETECTED]` ha penzu-gyi-kritikus feladat
  nem Fable 5 / L3-as szinten fut.

## Nem-informatikus vegfelhasznalo elv

Kollegaknak nem adunk parancssort vagy manualis rendszergazdai lepeseket. A
telepito/diagnosztika vegezze el automatikusan, amit lehet. Vegfelhasznaloi
deliverable csak akkor adható ki, ha a fejlesztoi oldali javitas es validacio
tenyszeruen megtortent.

## Tech stack

- Backend: Java 21, Spring Boot, PostgreSQL, Flyway, multi-tenant.
- Frontend: React + TypeScript + Vite.
- Desktop: Electron kliensek (`penztar-client`, `kozponti-client`,
  `arfolyam-keszito-client`).

## Fontos invariansok

- Multi-tenant: minden vedett adat `companyId` szerint izolalt.
- OSIV kikapcsolva: lazy asszociaciot service tranzakcion belul kell rendezni.
- HUF kerekites: 5 Ft-os kerekites.
- AML/Pmt. es arfolyam TTL szabalyok nem kerulhetok meg.
- Secret soha nem kerulhet kodba, chatbe vagy memoriaba.
- Minden Hetzner-deploy KOTELEZOEN ellenorzi a DB-migraciot: a prod 'valuta' DB
  Flyway-szintje == repo max V (Gate A), es a Neon backup-DB sema is migralva (Gate B,
  `flyway migrate`). Automatizalva a `deploy-hetzner.yml`-ben; tilos kikapcsolni. Lasd AGENTS.md 4.

## Helyi toolok (scripts/dev-tools/ — 44 db, zero-API-cost)

**Trigger-mátrix:** `memory/reference_dev_tools_trigger_matrix.md`

```powershell
# Backend Java valtozas utan (mindig)
python scripts/dev-tools/blast-radius.py <OsztályNév>
python scripts/dev-tools/transaction-audit.py
python scripts/dev-tools/multi-tenant-audit.py
.\scripts\dev-tools\typecheck-all.ps1

# Flyway migracio hozzaadasakor
python scripts/dev-tools/flyway-validate.py
python scripts/dev-tools/flyway-content-audit.py --last 3
python scripts/dev-tools/sql-index-gap.py

# Push / PR elott (mindig)
.\scripts\dev-tools\pre-push-gate.ps1 -Fast
python scripts/dev-tools/secrets-deep-scan.py
.\scripts\dev-tools\branch-hygiene.ps1

# Teszt futtatasa utan
python scripts/dev-tools/junit-report-parse.py
python scripts/dev-tools/test-timing-analyze.py

# React komponens hozzaadasakor
python scripts/dev-tools/missing-test-files.py --module <modul>
python scripts/dev-tools/react-complexity-scan.py --module <modul>

# Kiadas elott
python scripts/dev-tools/changelog-gen.py --from <elozo-tag>
python scripts/dev-tools/api-surface-report.py
.\scripts\dev-tools\bundle-size-check.ps1
```

## Gyakori parancsok

```powershell
cd backend; .\mvnw.cmd test
cd frontend-react; npm run typecheck; npm test
cd penztar-client; npm run typecheck; npm test
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

A security gate parancs deploy/release vagy security-sensitive valtozas elott
kell, nem minden apro kod- vagy dokumentacios szerkeszteshez.

## Defenziv biztonsagi audit (on-demand)

Biztonsagi auditnal / sebezhetoseg-keresesnel tobbkoros, taint-flow alapu munkamod
(discovery → verification → remediation), domain-fokusszal (multi-tenant companyId-scope,
business logic: storno/napzaras/foglalo/arfolyam-TTL, HUF-kerekites, AML). A kodot tilos
elore „biztonsagosnak" framelni. Determinisztikus eszkozok (multi-tenant-audit.py,
secrets-deep-scan.py, endpoint-audit.py, `npm/pip audit`) az AI-reteg melle, nem helyette.
Reszletek: `vault/feedback/security-audit-mandate-2026-06-15.md` (mandate),
`docs/security/ai-security-audit-playbook.md` (prompt-pack), `docs/security/ai-audit-profile.yaml` (profil).

## Release megjegyzes

`merge != telepito`. Telepito-build csak Electron/nativ reteg valtozasnal vagy
milestone release-nel kell.

Telepito-build utan a feladat CSAK akkor teljes, ha a telepito .exe-k le
vannak toltve a felhasznalo Letoltesek mappajaba (`gh release download`),
es a zarojelentes fajllista + meret + SHA-256 egyezes bizonyitekot mutat
(Kosa Zoltan direktiva, 2026-06-12).