# Valutavalto ERP - Claude/agent projektkontekstus

> ## ⛔ KÖTELEZŐ ÉRVÉNYŰ SZABÁLY — TESZT-INTEGRITÁS (NINCS KIVÉTEL, MINDEN MODELLRE KÖTELEZŐ)
>
> **TILOS A TESZTET ÁTÍRNI AZÉRT, HOGY ZÖLD LEGYEN.** SEMMIKÉPPEN NEM LEHET EGY BUKÓ TESZTET
> ÁTÍRNI, GYENGÍTENI, TÖRÖLNI, SKIPPELNI VAGY KIKOMMENTEZNI CSAK A ZÖLD EREDMÉNYÉRT. HA EGY
> TESZT BUKIK, ÁT KELL NÉZNI A TELJES KÓDOT ÉS A SPECET, ÉS AZ IMPLEMENTÁCIÓT VAGY A SPECET
> KELL JAVÍTANI — **SOHA A TESZTET A BUKÁS ELFEDÉSÉRE.** (Új teszt írása vagy valódi,
> dokumentált spec-változás külön feladatként megengedett; a tilalom a meglévő teszt
> bukás-elfedő átírására vonatkozik.)

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
- Context engineering: threat-model/cel-kontextus elol; nagy/ismeretlen valtozasnal
  repomap-first (`dep-map.py`/`blast-radius.py` szimbolum-terkep) a teljes forras helyett;
  befejezett fazisok tomoritese, kritikus info surun a kontextus vegen (context-rot ellen).
  Reszletek: `vault/feedback/security-audit-mandate-2026-06-15.md` §8 + playbook §4.4.
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
- Desktop: vegfelhasznaloi Electron telepitok: `penztar-client` es
  `kozponti-client`. Az arfolyamkeszito/rate-maker mod a `kozponti-client`
  resze; az `arfolyam-keszito-client` legacy/kozos kodforras, onallo
  release-telepito nem keszul belole.

## Fontos invariansok

- Multi-tenant: minden vedett adat `companyId` szerint izolalt.
- OSIV kikapcsolva: lazy asszociaciot service tranzakcion belul kell rendezni.
- HUF kerekites: 5 Ft-os kerekites.
- AML/Pmt. es arfolyam TTL szabalyok nem kerulhetok meg.
- Secret soha nem kerulhet kodba, chatbe vagy memoriaba.
- Minden Hetzner-deploy KOTELEZOEN ellenorzi a DB-migraciot: a prod 'valuta' DB
  Flyway-szintje == repo max V (Gate A), es a Neon backup-DB sema is migralva (Gate B,
  `flyway migrate`). Automatizalva a `deploy-hetzner.yml`-ben; tilos kikapcsolni. Lasd AGENTS.md 4.
- PLATFORM-IRANY (2026-08-10 ota): az Electron-kliensekben **kliens -> kliens import
  TILOS** (CI-blokkolo). A kozos kod a `packages/electron-platform`-ba kerul; csak
  bizonyitottan azonos logika emelheto ki. Kapu: `npm run check:platform-boundaries`.
  Lasd AGENTS.md 4 "Platform-irany" es a `valutavalto-platform-architecture` skillt.

## Helyi toolok (scripts/dev-tools/ — 45 db, zero-API-cost)

Trigger: a megfelelo eszkozt a valtozas tipusahoz futtasd (lasd az alabbi blokkokat).

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

## Kod-stilus (Prettier)

Gepfuggetlen formazas: a gyoker `.prettierrc.json` rogziti a stilust (Prettier 3.x,
pinned verzio). Ellenorzes `npm run format:check`, teljes formazas `npm run format`,
egy fajl `npx prettier --write <fajl>`. Modul-elteres: `penztar-client` pontosvesszos
(`semi: true`), a tobbi modul (frontend-react, kozponti-client, arfolyam-keszito-client)
pontosvesszo nelkuli. Az ESLint NEM formaz, igy nincs utkozes. Reszletes leiras es a
masik-gep / masik-ugynok munkafolyamat: `docs/code-style.md`.

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

Telepito/release feladatnal kotelezo, sorrendben:

1. A repo sajat forrasait kell hasznalni, nem feltetelezest: root `package.json`
   `package:*` scriptek, kliens `package.json` `package`,
   `scripts/installer-smoke-preflight.ps1`, `installer/build-installer.ps1`,
   `installer/build-cleanup.ps1`,
   `.github/workflows/windows-signed-release.yml`, es az erintett
   `electron-builder.json` fajlok.
2. Dependency-t nem szabad "hianyzik" alapon atlepni. Ellenorizni vagy telepiteni
   kell lockfile-bol: root, `frontend-react`, `penztar-client`,
   `kozponti-client` es a `packages/electron-platform` alatt `npm ci` (a platform
   sajat fuggeit a platform lockfilejabol kell telepiteni); Python
   requirement eseten celzott `python -m pip install -r ...`; Mavennel a repo
   wrapper (`mvnw.cmd`) hasznalando. Letoltott/binaris dependency csak forras-
   es hash-ellenorzes utan hasznalhato.
3. Ha a kert deliverable telepito/release, a helyes vegfelhasznaloi EXE-keszlet
   3 darab: `Penztar-Setup-<version>-<date>.exe`,
   `Penztar-Eltavolito-<version>-<date>.exe`,
   `Kozponti-Munkaallomas-Setup-<version>.exe`. Kulon
   `Arfolyamkeszito-Setup-*.exe` release-telepitot TILOS vart artifactkent
   kezelni, mert a rate-maker mod a kozponti munkaallomasba van integralva.
4. Tenyleges build: penztar setuphoz `installer/build-installer.ps1`, penztar
   eltavolitohoz `installer/build-cleanup.ps1`, kozponti modulhoz
   `npm run package:kozponti`, vagy a dokumentalt signed GitHub workflow.
   Build utan kotelezo `npm run installer:smoke:signed`.
5. A "nem lehet telepitot kesziteni" allitas csak akkor megengedett, ha a fenti
   scriptkeszlet es lockfile-alapu dependency telepites lefutott vagy konkret,
   bizonyitott blocker maradt fenn (pl. secret/alairasi jogosultsag).

Telepito-build utan a feladat CSAK akkor teljes, ha a telepito .exe-k le
vannak toltve a felhasznalo Letoltesek mappajaba (`gh release download`),
es a zarojelentes fajllista + meret + SHA-256 egyezes bizonyitekot mutat
(Kosa Zoltan direktiva, 2026-06-12).

## Opus Enterprise OS — fajlalapu mukodesi reteg (`.claude/`)

Fajlalapu, teszt-vezerelt, bizonyitek-alapu fejlesztoi operacios reteg a `.claude/`
alatt (forras: `Opus48_Enterprise_OS_Real_Full.md` bootstrap, 2026-06-17). NEM uj
politikat vezet be, hanem **fajlalapu skill/agent/reference formaba onti** a mar
ervenyes vault-mandate-eket (teszt-integritas, evidence-first, human-approval gate,
minimal patch, context-discipline).

**Precedencia (valtozatlan):** `AGENTS.md` (elsodleges agent-szabaly) → ez a `CLAUDE.md`
→ `vault/feedback/**` mandate-ek **felülirjak** az Enterprise OS skilljeit, ha ütköznek.
Az Enterprise OS reteg ezeket kiegesziti, nem helyettesiti.

**Skillek (`.claude/skills/`):** `prompt-contract`, `isolated-test-driven-opus`, `repo-map`,
`tdflow-opus`, `ads-architecture`, `debug-one`, `validation-gate`, `anti-test-hacking-audit`,
`counter-review`, `security-review`, `deployment-gate`, `ci-cd-gate`, `context-budget`.
(A meglevo 6 skill + 4 security-agent + `security-gate` command valtozatlan.)

**Nem-trivialis fejlesztoi feladat ajanlott menete** (lasd `.claude/commands/implement-feature.md`,
`fix-bug.md`): prompt-contract → teszt-iras → **test-freeze** → repo-map → minimal patch →
validation-gate → anti-test-hacking-audit → counter-review → evidence-first zarojelentes.

**Kemeny szabalyok** (osszhangban a vault teszt-integritas mandate-tel): a teszt a szerzodes —
fagyasztas utan tilos tesztet/fixture-t/snapshotot modositani a bukas elkerulesere; sikert csak
futtatott parancs + valodi kimenet alapjan jelentunk; DB-migracio / auth / payment / public API /
production deploy / secret elott emberi jovahagyas. Reszletek: `.claude/references/operating-model.md`,
`test-freeze-policy.md`, `anti-test-hacking-rubric.md`, `human-approval-gates.md`.

**Hookok:** csak JAVASLAT keszult (`.claude/references/hooks-proposal.md`), automatikus
aktivalas nelkul; a `settings.json`/`settings.local.json` valtozatlan.

<!-- CODEX_SHARED_QUALITY_RULES_START v1 -->
## Kikényszerített közös Codex minőségkapu

Ez a blokk minden repo-ban kötelező minimumszabály Codex/AI-agent munkához. A
repo-specifikus szabályokat nem helyettesíti, hanem kikényszerített módon
kiegészíti. Repo-specifikus szabály csak szigoríthatja vagy pontosíthatja ezt a
blokkot; nem gyengítheti, nem kapcsolhatja ki és nem írhatja felül. Ütközésnél
mindig a szigorúbb, biztonságosabb, jobban verifikálható szabály érvényes. Ha a
repo-specifikus szöveg enyhébb mércét engedne, azt Codex-munkánál érvénytelen
kivételként kell kezelni.

Repo-specifikus szabályok betöltése kötelező. Minden munkamenetben azonosítsd
és olvasd el a legközelebbi repo-vezérlő fájlt (AGENTS.md, CLAUDE.md, CODEX.md,
GEMINI.md), valamint csomag/alrepo munka esetén a közelebbi vezérlő fájlokat is.
Csak a közös blokk alapján dolgozni tilos, ha a repo saját szabályt tartalmaz. A
telepített közös blokk a repo saját szövegét nem törölheti és nem írhatja át
kézzel; csak markerelt blokkban frissíthető.

- Magyarul kommunikálj a felhasználóval, kivéve ha a repo vagy a feladat más
  nyelvet kér a végtermékben.
- Tényből dolgozz: ne találj ki fájlt, API-t, route-ot, teszteredményt, logot,
  buildet, deployt, review-t vagy külső forrást. Ha nem ellenőrizted, írd le,
  hogy nem ellenőrzött.
- Munka előtt olvasd el a legközelebbi vezérlő fájlt (AGENTS.md, CLAUDE.md,
  CODEX.md, GEMINI.md), az adott repo/alrepo saját kiegészítő szabályait és az
  érintett forrás/teszt fájlokat. Nagy dokumentumot eleje-közepe-vége
  mintavétellel olvass, ne ess Lost in the Middle hibába.
- 3+ fájlt, architektúrát, adatmodellt, migrációt, authot, pénzügyi/üzleti
  logikát, deployt vagy agent/CI szabályt érintő munkánál előbb rövid contract:
  cél, nem-cél, érintett fájlok, edge case-ek, elfogadási feltételek.
- Minimális, célzott változtatást készíts. Ne overpolisholj, ne refaktorálj
  mellékesen, és ne keverd össze a feladatot más nyitott munkával.
- Tesztet gyengíteni, törölni, skipelni, snapshotot kozmetikázni vagy
  test-only kerülőutat betenni tilos. A bukó teszt okát javítsd, ne a mércét.
- Minden érdemi változtatás után futtasd a legszűkebb hasznos ellenőrzést:
  célzott teszt, lint, typecheck, build, smoke vagy diff-check. Kész állapotot
  csak valós parancskimenettel vagy pontosan dokumentált blockerrel állíts.
- UI/megjelenítési változásnál a renderer/unit teszt nem elég. Kötelező valós,
  teljes képernyős Browser/Playwright render ellenőrzés, amely nézi az átfedést,
  levágott szöveget, váratlan scrollbart, viewport overflow-t és a javított
  felhasználói állapotot.
- Titkot, tokent, privát kulcsot, személyes adatot vagy secret-like azonosítót
  ne írj chatbe, logba, commitba, dokumentációba vagy fájlnévbe. Használj
  placeholdert vagy secret-store/environment hivatkozást.
- Destruktív művelet, adatbázis-migráció, tömeges törlés, deploy, release,
  credential/cert kezelés vagy külső rendszer módosítása előtt legyen explicit
  kockázatkezelés és visszaállási pont; ha nincs biztonságos default, állj meg.
- Dirty worktree-ben ne revertáld és ne írd felül más munkáját. Státusz alapján
  különítsd el a saját szeletet, user/unknown munkát és generált zajt.
- Windows hoston parancsoknál preferáld az explicit futtatókat (npm.cmd,
  npx.cmd, pwsh/powershell -ExecutionPolicy Bypass), ne támaszkodj olyan
  shimre, amely szerkesztőben nyílhat meg.
- Záró válaszban sorold fel: módosított fájlok, futtatott ellenőrzések
  PASS/FAIL eredménnyel, nem futtatott ellenőrzések oka és maradó kockázat.
<!-- CODEX_SHARED_QUALITY_RULES_END v1 -->

## Globális működési alapelv — minden programozási feladat

> A `~/.claude/CLAUDE.md` globális szabály repó-szintű megerősítése. Biztonság,
> verifikáció és git kérdésben a repó saját szabályai (pl. `AGENTS.md`) az irányadók.

Kötelező munkafolyamat (a többi szabálytól függetlenül, azokon felül):

1. **Utasítás** megértése: cél, nem-célok, edge case, mérhető elfogadás.
2. **Terv** készítése az utasításból: lépések, érintett fájlok, kockázat,
   verifikáció (nagyobb munkánál spec-first).
3. **Implementáció a terv szerint**, a saját Dynamic Workflow orkesztrálásával:
   a rutin/mechanikus/párhuzamos részeket olcsóbb subagentre delegálva
   (Haiku 4.5 mechanikus munkára, Sonnet 4.6 közepes implementációra), a
   kiemelten bonyolult, magas-effortú gondolkodást Opus 4.8-on tartva.
4. **Verifikáció + önreview**: teszt/build/lint, majd a diffet a tervhez/spechez
   mérd vissza.

A főhurok **Opus 4.8** marad (nincs `opusplan`/Sonnet-váltás); token-takarékosan
delegálj, és csak a valóban nehéz részeket csináld magad.
