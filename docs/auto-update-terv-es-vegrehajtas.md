# Automatikus frissítés (self-update) — Terv és végrehajtási utasítás

> Állapot: **1. ÉS 2. FÁZIS IMPLEMENTÁLVA** (PR #1618, 2026-08-12) · Terv készült: 2026-08-12
>
> A 8. szakasz döntései jóváhagyva. A végrehajtás jegyzőkönyve és a bizonyítékok:
> `.hermes/tickets/2026-08-12-auto-update-vegrehajtas-jegyzokonyv.md`.
>
> **Ami még nyitott:** (a) éles verifikáció — a feed és a manifestek csak
> `publish_release: true` futásnál keletkeznek; (b) a renderer-oldali
> műszak-állapot bejelentés és a „frissítés készen áll" jelölő (`frontend-react`);
> (c) 3. fázis — flotta-rollout `rollout_percent: 25`-tel.
>
> Cél: a végfelhasználói kliensek (Pénztár, Központi Munkaállomás) **maguktól frissüljenek
> a szerverről** — ne kelljen többé Drive-ról letöltögetni és kézzel újratelepíteni az új
> telepítőt. Nem-informatikus végfelhasználó elv: a kolléga csak egy „Újraindít és telepít"
> gombot lát, semmi mást.

---

## 0. Végrehajtási állapot (2026-08-12)

| Terv-lépés | Állapot | Hol |
|---|---|---|
| 5.1 Közös update-modul | ✅ KÉSZ | `packages/electron-platform/src/auto-update.ts` (`initElectronUpdater`, `isInRollout`) |
| 5.2 Központi kliens bekötés | ✅ KÉSZ | `kozponti-client/electron/main.ts`, `installMode: 'on-quit'` |
| 5.3 Release: feed-assetek | ✅ KÉSZ | `munkaallomas.yml` + `.blockmap` + sha512↔exe hash-kapu + `penztar.yml`-tilalom |
| 5.4/1 NSI `/S` audit | ✅ KÉSZ — **defektust talált és javított** | 7× `IfSilent +1` → `+2 0`; új kapu: `installer/tests/nsis-silent-mode-guard.py` |
| 5.4/2 `suite-update.ts` | ✅ KÉSZ | állapotgép + SHA-256 + Authenticode + downgrade-tilalom + rollout |
| 5.4/3 CI `update-manifest.json` | ✅ KÉSZ | publish job; hash a SHA-256 manifestből (egy igazságforrás) |
| 5.4/4 régi `app-update.yml` | ⏸️ MEGHAGYVA | a kint lévő verziók miatt; az új kód nem használja |
| 5.5 Végpont-végpont próba | ❌ NYITOTT | két egymást követő éles release kell hozzá |
| 5.6 Rollout | ❌ NYITOTT | `rollout_percent` input kész, az éles kör még nem indult |
| Renderer műszak-állapot UI | ❌ NYITOTT | a preload-API kész (`suiteUpdate.*`), a `frontend-react` bekötés hiányzik |

**Fail-safe következmény:** amíg a renderer nem jelent műszak-állapotot, a
suite-updater konzervatívan `SHIFT_OPEN`-t feltételez, tehát **letölt és ellenőriz,
de nem telepít**. Ez nem hiba, hanem a 3.6/2. szabály szándékolt viselkedése.

### A menet közben talált defektus (dokumentálva, mert visszatérhet)

A `Penztar-Setup.nsi` 7 helyen `IfSilent +1`-et használt. NSIS-ben a `+1` a
**következő** utasítás, azaz nem ugrik semmit → a MessageBox néma (`/S`) módban is
megjelent, és a telepítő blokkolt. Empirikus mérés (makensis 3.x):

| Változat | `/S` futás |
|---|---|
| `IfSilent +1` | MessageBox megjelent, process timeout (exit 124) |
| `IfSilent +2 0` | átugorta, lefutott (exit 0) |

A `Abort` néma módban **exit 2**-t ad (siker: 0) — erre támaszkodik az updater.

---

## 1. Vezetői összefoglaló

A rendszer **félig már fel van készítve** az önfrissítésre, de a lánc három ponton szakad meg:

| Komponens | Ami MÁR megvan | Ami HIÁNYZIK |
|---|---|---|
| Pénztár kliens | `electron-updater` függőség, működő `auto-update.ts` (4 óránként ellenőriz), `app-update.yml` a telepített gépeken (`penztar` channel, GitHub provider) | A release-ben nincs `penztar.yml` manifest és electron-builder NSIS csomag → a check mindig üresen/hibával tér vissza. **ÉS: az electron-updater önmagában nem is elég** (lásd 3.2 — a suite-telepítő miatt) |
| Központi kliens | `publish` config (`munkaallomas` channel), aláírt electron-builder NSIS build, `verifyUpdateCodeSignature: true` | Nincs updater-kód a main processben, nincs `electron-updater` függőség, a release-be nem kerül fel a `munkaallomas.yml` + `.blockmap` |
| Release pipeline | `windows-signed-release.yml`: aláírt exe-k + SHA-256 manifest GitHub Release-be | Nem tölti fel az update-manifesteket (`munkaallomas.yml`, `update-manifest.json`), a penztár electron-builder artifactot |

**Javasolt megoldás (két különböző mechanizmus, közös feed):**

- **Update-feed = GitHub Releases** (a repo PUBLIKUS, tehát token nélkül, ingyen, CDN-ről
  elérhető; a kód-aláírás + SHA-256 + HTTPS adja a biztonságot). Ez a „szerver" szerepét
  tölti be; opcionálisan később áttehető az `excvaluta.com`-ra (lásd 4.3).
- **Központi kliens → standard `electron-updater`** (tiszta electron-builder NSIS, ez a
  tankönyvi eset; 1-2 nap munka, alacsony kockázat). **Ez az 1. fázis.**
- **Pénztár kliens → saját „suite-updater"**: a teljes aláírt `Penztar-Setup-*.exe`-t tölti
  le, SHA-256 + Authenticode ellenőrzés után csendes (`/S`) upgrade-ként futtatja. Azért
  kell így, mert a pénztár telepítő nem csak az Electron appot rakja fel, hanem a **lokális
  backend JAR-t, JRE-t, PostgreSQL-t és NSSM service-eket is** — ha csak az Electron app
  frissülne (electron-updater), a kliens és a lokális backend verziója szétcsúszna.
  **Ez a 2. fázis.**

---

## 2. Jelenlegi állapot — tények, fájlhivatkozásokkal

Ez a szakasz a 2026-08-12-i `main` (v2.28.78) beolvasásán alapul.

### 2.1 Pénztár kliens

- `penztar-client/electron/auto-update.ts` — kész modul: induláskor +10 mp, majd 4 óránként
  `checkForUpdates()`; háttérletöltés; letöltés után magyar nyelvű dialog („Újraindít és
  telepít / Később"); staged rollout támogatás (`UPDATE_ROLLOUT_PERCENT`, determinisztikus
  gép-hash). A `main.ts:1634` hívja (`initAutoUpdate(mainWindow)`).
- `penztar-client/electron-builder.json` — `publish: { provider: github, owner: kosazoltan,
  repo: valutavalto-program, channel: penztar }`, `verifyUpdateCodeSignature: true`,
  `artifactName: Penztar-Setup-${version}.exe`.
- `installer/build-installer.ps1` (335. sor környéke): az Electron **`--win dir`** (unpacked)
  targettel épül, majd a saját `installer/Penztar-Setup.nsi` csomagolja be a teljes suite-ot
  (Electron + backend JAR + jlink JRE + PostgreSQL + NSSM + VC++ redist). A 358–377. sor
  kézzel legenerálja az `app-update.yml`-t a resources alá — tehát **a már kint lévő pénztár
  telepítések ténylegesen keresik a `penztar.yml`-t a GitHub Releases-ben**, csak sosem
  találják (jelenleg ez csak Sentry-warningot termel).
- `installer/Penztar-Setup.nsi`: `InstallDir $PROGRAMFILES64\Valutavalto Penztar`, saját
  uninstall registry-kulcs (`...\Uninstall\ValutavaltoPenztar`), NSSM service-ek, DB-adat és
  `.env` a DataDir-ben.

### 2.2 Központi kliens

- `kozponti-client/electron-builder.json` — `publish.channel: munkaallomas`,
  `verifyUpdateCodeSignature: true`, NSIS target, `artifactName:
  Kozponti-Munkaallomas-Setup-${version}.exe`. Ez **tiszta electron-builder NSIS** telepítő
  (nincs suite-wrapper) → az electron-updater kompatibilis vele out-of-the-box.
- `kozponti-client/electron/` — NINCS auto-update modul, a `package.json`-ban NINCS
  `electron-updater`.
- A `packages/electron-platform` közös csomagban sincs update-kód (grep: 0 találat) —
  a közös modul ide való (Platform-irány szabály: kliens→kliens import TILOS).

### 2.3 Release pipeline

- `.github/workflows/windows-signed-release.yml`: build-integritási kapu (csak main HEAD),
  Azure Key Vault HSM aláírás, `Get-AuthenticodeSignature` verifikáció, GitHub Release
  `v<verzió>` taggel, SHA-256 manifest (`windows-signed-release-sha256.txt`).
- A kozponti job `--publish never`-rel fut → az electron-builder legenerálja a
  `munkaallomas.yml`-t és a `.blockmap`-et a `kozponti-client/release/` alá, de a workflow
  **csak az exe-t** tölti fel artifactként/release-be. A yml+blockmap elveszik.
- A repo **publikus** (`gh repo view`: PUBLIC) → az electron-updater GitHub providere
  hitelesítés nélkül eléri a release-eket.
- Verziózás: 9-utas verzió-bump, minden `package.json` szinkronban (jelenleg 2.28.78);
  a release tag formátuma `v<verzió>` — pontosan ez kell az electron-updaternek.

---

## 3. Célarchitektúra

### 3.1 Áttekintés

```
┌────────────────────── GitHub Releases (v2.28.79) ──────────────────────┐
│  Kozponti-Munkaallomas-Setup-2.28.79.exe        (aláírt, electron-builder NSIS)
│  Kozponti-Munkaallomas-Setup-2.28.79.exe.blockmap
│  munkaallomas.yml                               (electron-updater manifest)
│  Penztar-Setup-2.28.79-<datum>.exe              (aláírt suite-telepítő)
│  Penztar-Eltavolito-2.28.79-<datum>.exe
│  update-manifest.json                           (suite-updater manifest, ÚJ)
│  windows-signed-release-sha256.txt
└─────────────────────────────────────────────────────────────────────────┘
        ▲ HTTPS, anonim letöltés (publikus repo)          ▲
        │                                                  │
┌───────┴───────────────┐                    ┌─────────────┴──────────────┐
│ KÖZPONTI KLIENS        │                    │ PÉNZTÁR KLIENS             │
│ electron-updater       │                    │ suite-updater (ÚJ modul)   │
│ munkaallomas.yml       │                    │ update-manifest.json       │
│ delta (blockmap) DL    │                    │ teljes Setup exe DL        │
│ /S csendes app-update  │                    │ SHA-256 + Authenticode     │
│ aláírás-verify beépítve│                    │ ellenőrzés, majd /S upgrade│
└────────────────────────┘                    │ (backend+JRE+PG is frissül)│
                                              └────────────────────────────┘
```

### 3.2 Miért NEM electron-updater a pénztárnál? (kulcsdöntés)

Az electron-updater NSIS-frissítője a **saját electron-builder GUID-alapú registry-kulcsa**
alapján találja meg a telepítési könyvtárat. A pénztárt viszont az egyedi
`Penztar-Setup.nsi` telepíti (`ValutavaltoPenztar` kulcs, lapos `$PROGRAMFILES64` layout,
NSSM service-ek). Ha a meglévő `auto-update.ts`-t „csak bekapcsolnánk" a `penztar.yml`
feltöltésével, az update-installer **egy második, párhuzamos telepítést** hozna létre másik
könyvtárba, miközben a suite (backend JAR, JRE, PostgreSQL, parancsikonok, service-ek) a
régi helyen maradna régi verzióval → verzió-szétcsúszás a kliens és a lokális backend
között, törött parancsikonok, két „Valutavalto Penztar" a programlistában.

**Ezért a pénztárnál a frissítési egység a TELJES suite-telepítő**, amely már ma is tud
felülírásos upgrade-et (registry-ből olvassa a meglévő InstallDir-t, megőrzi a DataDir-t /
DB-t / `.env`-et). A suite-updater csak letölti, ellenőrzi és elindítja.

Következmény: a meglévő `penztar-client/electron/auto-update.ts` (electron-updater alapú)
a pénztárban **lecserélendő** a suite-updaterre; az electron-updater ág a központi kliensbe
kerül át (közös platformmodulként).

### 3.3 Biztonsági követelmények (mindkét kliensre kötelező)

1. **Csak HTTPS** feed és letöltés (GitHub Releases: adott).
2. **Kód-aláírás ellenőrzés a telepítés ELŐTT**:
   - Központi: `verifyUpdateCodeSignature: true` + `publisherName: ["EXCLUSIVE BEST Change Zrt."]`
     (már konfigurálva — az electron-updater letöltés után ellenőrzi az Authenticode-ot).
   - Pénztár suite-updater: letöltés után saját ellenőrzés:
     (a) SHA-256 egyezés az `update-manifest.json`-ban közölt hash-sel,
     (b) `Get-AuthenticodeSignature` / WinVerifyTrust: `Valid` státusz ÉS a subject
     tartalmazza az `EXCLUSIVE BEST Change Zrt.` nevet. Bármelyik bukik → törlés + hiba-log,
     SOHA nem fut le a telepítő.
3. **Downgrade tilos**: csak szigorúan nagyobb semver telepíthető (electron-updaternél
   default; a suite-updaterben explicit semver-összehasonlítás).
4. **Kill-switch / staged rollout**: az `update-manifest.json`-ban `rolloutPercent` mező
   (0 = frissítés felfüggesztve az egész flottán, CI nélkül szerkeszthető a release
   asseten); a meglévő determinisztikus gép-hash logika (auto-update.ts 29–37. sor)
   átemelendő a közös modulba.
5. **Pénzügyi integritás**: frissítés-telepítés csak felhasználói megerősítéssel indul
   (nyitott műszak/kassza közben nincs kényszerített restart); a dialog szövege
   figyelmeztet a munka mentésére. Napzárás-kritikus folyamat közben (ha a renderer jelez)
   a prompt elhalasztandó.
6. **Secret nem kerül a kliensbe**: a feed publikus, tokenre nincs szükség — ez tervezési
   invariáns, NE kerüljön GH_TOKEN a kliens kódjába/env-jébe.

### 3.4 Az `update-manifest.json` sémája (ÚJ, a CI generálja)

```json
{
  "schemaVersion": 1,
  "version": "2.28.79",
  "releasedAt": "2026-08-20T10:00:00Z",
  "rolloutPercent": 100,
  "mandatory": false,
  "notes": "Rövid, magyar nyelvű változásjegyzék a dialoghoz.",
  "penztar": {
    "file": "Penztar-Setup-2.28.79-20260820.exe",
    "url": "https://github.com/kosazoltan/valutavalto-program/releases/download/v2.28.79/Penztar-Setup-2.28.79-20260820.exe",
    "sha256": "<hash a windows-signed-release-sha256.txt-ből>",
    "sizeBytes": 293601280,
    "silentArgs": ["/S"]
  }
}
```

Stabil lekérési URL (mindig a legutóbbi release-re mutat, nem kell tag-et ismerni):
`https://github.com/kosazoltan/valutavalto-program/releases/latest/download/update-manifest.json`

### 3.5 Opció B — feed az excvaluta.com-on (később, NEM az első ütem)

Ha üzletileg fontos, hogy szó szerint a saját Hetzner-szerverről frissüljön a flotta
(pl. GitHub-elérés tűzfalon tiltva az üzletekben), a feed átköltöztethető:
nginx statikus könyvtár (`/var/www/updates/`), a `deploy-hetzner.yml` mintájára egy
workflow SCP-vel feltölti a release-assetek másolatát + a manifesteket; a kliensben csak
a feed-URL változik (`config/production-urls.json`-ba: `update_feed_url`). A biztonsági
modell változatlan (HTTPS + aláírás + SHA-256), ezért ez tisztán infrastrukturális csere.
**Javaslat: GitHub Releases-szel indulni** (0 üzemeltetés, CDN, már minden oda épül), és
csak igazolt igény esetén költözni.

---

## 4. Ütemezett terv

### 1. fázis — Központi kliens önfrissítése (alacsony kockázat, ~1-2 nap)

Tankönyvi electron-updater eset; itt gyakoroljuk be a teljes láncot éles flottakockázat
nélkül (a központi gépből kevés van, a pénztárból sok).

1. Közös update-modul a `packages/electron-platform`-ba (a Platform-irány szabály szerint;
   a pénztár meglévő `auto-update.ts`-éből kiemelve: event-wiring, magyar dialogok,
   staged-rollout hash, logolás).
2. `kozponti-client`: `electron-updater` függőség + a közös modul bekötése a `main.ts`-be.
3. `windows-signed-release.yml` kozponti job: a `release/munkaallomas.yml` és a
   `*.exe.blockmap` felvétele az artifact- és release-fájllistába.
4. Teszt (5. fázis szerinti forgatókönyvek), majd éles próba két egymást követő release-szel.

### 2. fázis — Pénztár suite-updater (közepes kockázat, ~3-5 nap)

1. `Penztar-Setup.nsi` csendes upgrade-út auditja és megerősítése: `/S` módban
   (a) NSSM service-ek leállítása, (b) meglévő InstallDir/DataDir tisztelete,
   (c) DB + `.env` + secret megőrzése, (d) service-ek visszaindítása, (e) app-restart.
   Ha bármelyik hiányzik, előbb az NSI-t kell kiegészíteni (külön PR, teszttel).
2. Új `suite-update.ts` a pénztár main processébe (a régi `auto-update.ts` helyére):
   manifest-poll (indulás +10 mp, majd 4 óránként) → semver-összehasonlítás →
   rolloutPercent-szűrés → háttérletöltés temp könyvtárba → SHA-256 + Authenticode
   ellenőrzés → magyar dialog → `/S` indítás + `app.quit()`.
3. CI: `update-manifest.json` generálása a publish-release jobban (a SHA-256 manifest
   sorából), feltöltés a release-be.
4. A `build-installer.ps1`-ben generált `app-update.yml` maradhat (a régi, kint lévő
   verziók miatt), de az új kód már nem használja; egy későbbi release-ben eltávolítható.

### 3. fázis — Flotta-rollout és üzemeltetés

1. Első éles kör `rolloutPercent: 25`-tel (pénztár), 24 óra megfigyelés (Sentry/log),
   utána 100%.
2. Runbook-frissítés: `vault/operations/windows-signed-release-runbook.md` — az új
   release-lépés („manifest ellenőrzése"), kill-switch eljárás (manifest-asset szerkesztése
   `rolloutPercent: 0`-ra a GitHub UI-on), rollback-eljárás.
3. A Drive-os terjesztés kivezetése: az első sikeres flotta-frissítés után a Drive-mappa
   csak archívum.

---

## 5. Végrehajtási utasítás (lépésről lépésre)

> Minden lépés után futtatandó ellenőrzés dőlttel. A teszt-integritás szabály érvényes:
> bukó tesztre az implementációt javítjuk, nem a tesztet.

### 5.1 — Közös update-modul (`packages/electron-platform`)

1. Új fájl: `packages/electron-platform/src/auto-update.ts`
   - Exportok: `initElectronUpdater(opts)` (electron-updater ág, a mai
     `penztar-client/electron/auto-update.ts` logikájával: autoDownload,
     autoInstallOnAppQuit, magyar Notification + dialog, progress-IPC, error-log) és
     `isInRollout(version: string, percent: number): boolean` (determinisztikus gép-hash,
     a mai 29–37. sorból kiemelve).
   - Az `electron-updater` és `electron-log` a platform-csomag függősége legyen
     (`packages/electron-platform/package.json` + saját lockfile, `npm ci` a csomag alatt).
2. Unit-teszt: `isInRollout` determinizmus + eloszlás-smoke (0% → mindig false,
   100% → mindig true, azonos input → azonos eredmény).
3. *Ellenőrzés:* `cd packages/electron-platform && npm ci && npm test` (ha van test-script),
   valamint `npm run check:platform-boundaries` a gyökérből.

### 5.2 — Központi kliens bekötése

1. `cd kozponti-client && npm install electron-updater@^6.8.9 electron-log` (lockfile-frissítéssel).
2. `kozponti-client/electron/main.ts`: az ablak létrehozása után
   `initElectronUpdater({ mainWindow })` hívás (mintaként: `penztar-client/electron/main.ts:1632–1634`).
3. Ellenőrizd, hogy a `kozponti-client` electron-builder NSIS buildje a
   `resources/app-update.yml`-t automatikusan tartalmazza (NSIS target + publish config →
   electron-builder generálja; NEM kell kézzel írni, mint a pénztárnál).
4. *Ellenőrzés:* `cd kozponti-client && npm run typecheck && npm test`, majd lokális
   `npm run package -- --publish never` és nézd meg, hogy a `release/` alatt ott van-e:
   `munkaallomas.yml`, `Kozponti-Munkaallomas-Setup-<ver>.exe`, `...exe.blockmap`, és az
   exe-ben (7-Zip-pel kibontva vagy telepítve) a `resources/app-update.yml`.

### 5.3 — Release workflow: manifestek feltöltése

`.github/workflows/windows-signed-release.yml` módosítások:

1. **Kozponti artifact-lista bővítése** (Upload Kozponti artifacts lépés):
   ```yaml
   path: |
     kozponti-client/release/Kozponti-Munkaallomas-Setup-*.exe
     kozponti-client/release/Kozponti-Munkaallomas-Setup-*.exe.blockmap
     kozponti-client/release/munkaallomas.yml
   ```
2. **FONTOS — yml-hash konzisztencia**: a `munkaallomas.yml`-t az electron-builder a build
   végén, az aláírt exe-ről generálja (a signtool-hook a csomagolás közben fut), így a benne
   lévő sha512 az aláírt exe-re vonatkozik. A publish-release jobban ezt NE módosítsd és az
   exe-t a yml generálása után már NE írd felül. Verifikációs lépés a publish-release jobba:
   a `munkaallomas.yml`-ben szereplő sha512 (base64) egyezzen a feltöltendő exe tényleges
   hash-ével — eltérés esetén a job bukjon.
3. **`update-manifest.json` generálása** a „Flatten artifacts" lépés után (PowerShell):
   a Penztar-Setup exe nevéből + `Get-FileHash`-éből + a preflight `version`/`build_date`
   outputokból összeállítva (3.4-es séma), `rolloutPercent` alapértéke workflow-inputból
   (`rollout_percent`, default `100`).
4. **Release fájllista bővítése** (Create GitHub Release):
   ```yaml
   files: |
     release-flat/*.exe
     release-flat/*.exe.blockmap
     release-flat/*.yml
     release-flat/update-manifest.json
     release-flat/*.jar
     release-flat/windows-signed-release-sha256.txt
   ```
   (A flatten-lépésben a `.blockmap`/`.yml`/`.json` kiterjesztéseket is másolni kell.)
5. *Ellenőrzés:* workflow-szintaxis lint (`gh workflow view` / actionlint, ha elérhető);
   éles verifikáció csak az első próba-release-nél lehetséges.

### 5.4 — Pénztár suite-updater

1. **NSI csendes-upgrade audit** (KÖTELEZŐ ELŐFELTÉTEL): olvasd végig a
   `installer/Penztar-Setup.nsi` upgrade-ágát, és bizonyítsd teszttel (VM-ben:
   régi verzió telepítve → új Setup `/S`-sel):
   - a meglévő `InstallDir`-be települ (`InstallDirRegKey` — megvan, 109. sor),
   - NSSM service-ek stop → fájlcsere → start sorrend hibamentes,
   - `DataDir` (PostgreSQL adat), `.env`, generált secretek érintetlenek,
   - `/S` módban egyetlen MessageBox sem jelenik meg (a jelenlegi NSI-ben több
     `MessageBox MB_OK|MB_ICONSTOP` hibaág van — ezeket `/S` alatt `IfSilent` ágra kell
     terelni: log + `SetErrorLevel <nem-nulla>` + `Abort`, hogy a néma telepítő ne
     akadjon be egy láthatatlan dialogon),
   - nem-nulla exit code hibánál (a suite-updater erre támaszkodik).
   Ha bármelyik nem teljesül: előbb NSI-javító PR.
2. **Új modul**: `penztar-client/electron/suite-update.ts`
   - Poll: indulás +10 mp, majd 4 óránként a `releases/latest/download/update-manifest.json`.
   - Guardok: `schemaVersion === 1`; semver: manifest.version > app.getVersion();
     `isInRollout(version, rolloutPercent)` a platform-modulból; már letöltött és
     ellenőrzött exe cache-elése (ne töltsön 280 MB-ot minden ciklusban újra).
   - Letöltés: `app.getPath('temp')` alá, ideiglenes névre, atomikus rename a végén;
     letöltési progress IPC a rendererbe (a meglévő `autoUpdate:progress` csatorna
     újrahasznosítható).
   - Ellenőrzés: SHA-256 (Node `crypto`, streamelve) egyezés a manifesttel; Authenticode:
     `powershell -NoProfile -Command (Get-AuthenticodeSignature '<exe>').Status` +
     Subject-ellenőrzés (`EXCLUSIVE BEST Change Zrt.`). Bármely hiba → fájl törlése,
     error-log, következő ciklusban újrapróbálkozás.
   - Dialog (magyar): „Új verzió érhető el: v<X>. A telepítéshez a program újraindul,
     és a frissítés kb. 2-3 percig tart." Gombok: „Frissítés most" / „Később".
     „Később" → 4 óra múlva újra kérdez; a letöltött exe megmarad.
   - Indítás: `spawn(exePath, ['/S'], { detached: true, stdio: 'ignore' })` +
     `child.unref()` + `app.quit()`. (A telepítő állítja le/indítja a service-eket és a
     végén indítja a Penztar.exe-t — az NSI-audit szerint.)
   - A `main.ts:1632–1634`-ben az `initAutoUpdate` hívás cseréje `initSuiteUpdate`-re;
     a régi `auto-update.ts` törlése (a benne lévő rollout-hash már a platform-modulban él).
3. **Tesztek**: unit — semver-összehasonlítás, manifest-validálás (hibás séma/hash-formátum
   elutasítása), rollout-gate; integráció — mock HTTP-szerverrel manifest+exe kiszolgálás,
   hash-eltérés → elutasítás; Authenticode-lépés Windows-on smoke-tesztelve.
4. *Ellenőrzés:* `cd penztar-client && npm run typecheck && npm test`;
   `python scripts/dev-tools/missing-test-files.py --module penztar-client` (ha értelmezett);
   `.\scripts\dev-tools\pre-push-gate.ps1 -Fast`.

### 5.5 — Végpont-végpont próba (kötelező, VM-ben vagy tesztgépen)

1. Készíts két egymást követő verziót (pl. 2.28.79 és 2.28.80) a signed workflow-val,
   `publish_release: true`-val — az első kör mehet előre-datált teszt-tagre is, de a
   `releases/latest` szemantika miatt a próbát érdemes úgy időzíteni, hogy a teszt-release
   lehessen a legfrissebb, majd a próba után törölhető.
2. **Központi**: telepítsd a 79-est → indítsd → várj (vagy dev-triggerrel `checkForUpdates`)
   → a 80-as háttérben letölt → dialog → „Újraindít és telepít" → app 80-asként indul újra.
   Bizonyíték: `%LOCALAPPDATA%\<app>\logs` electron-log bejegyzések + Névjegy-verzió.
3. **Pénztár**: telepítsd a 79-es suite-ot VM-be → indítsd → manifest-poll → letöltés →
   hash+aláírás OK a logban → dialog → „Frissítés most" → csendes telepítő lefut →
   Penztar.exe 80-asként indul, NSSM service-ek futnak, DB-adat és `.env` érintetlen,
   backend `/actuator` vagy bootstrap-status a 80-as JAR-t mutatja.
4. **Negatív tesztek** (pénztár): (a) manifestben rontott sha256 → a kliens elutasítja,
   nem indul telepítő; (b) `rolloutPercent: 0` → „update-not-available" viselkedés;
   (c) hálózat-hiba letöltés közben → tiszta hiba-log, következő ciklusban újrapróbál.
5. *Bizonyíték a zárójelentésbe:* log-kivonatok, verzió-képernyőképek, a futtatott
   parancsok kimenete (evidence-first).

### 5.6 — Rollout és üzemeltetési szabályok

1. Első pénztár-flotta release: `rollout_percent: 25` workflow-inputtal → 24 óra
   megfigyelés → ha tiszta, új manifest 100%-kal (az asset a GitHub release-oldalon
   kézzel is cserélhető, build nélkül).
2. **Kill-switch**: hibás release esetén a legfrissebb release `update-manifest.json`
   assetjét cseréld `rolloutPercent: 0`-ra (letiltja a suite-frissítést), a
   `munkaallomas.yml`-t pedig töröld az assetek közül (letiltja a központi frissítést).
3. **Rollback**: mivel downgrade tilos, a visszaállás módja mindig egy ÚJ, magasabb
   verziószámú release a javított (vagy visszaállított) kódból.
4. Runbook-frissítés: `vault/operations/windows-signed-release-runbook.md` egészüljön ki
   a fenti eljárásokkal; a release-checklistába kerüljön be: „update-manifest.json +
   munkaallomas.yml jelen van a release-ben, hash egyezik".

---

## 6. Elfogadási kritériumok (Definition of Done)

- [ ] Központi kliens: két egymást követő éles release között felhasználói beavatkozás
      nélkül (egy megerősítő kattintással) frissül; aláírás-ellenőrzés bizonyítottan fut.
- [ ] Pénztár kliens: teljes suite (Electron + backend JAR + JRE + PG-stack) egyben frissül
      `/S` upgrade-del; DB-adat, `.env`, secretek érintetlenek; kliens- és lokális
      backend-verzió a frissítés után azonos.
- [ ] Rontott hash-ű / aláíratlan exe SOHA nem települ (negatív teszt bizonyítékkal).
- [ ] Kill-switch (rolloutPercent: 0) 4 órán belül megállítja a flotta-frissítést.
- [ ] A release workflow minden szükséges assetet automatikusan feltölt; kézi lépés nincs.
- [ ] Runbook frissítve; Drive-terjesztés kivezetve.
- [ ] `npm run check:platform-boundaries` zöld (nincs kliens→kliens import).

## 7. Kockázatok és ellenintézkedések

| Kockázat | Hatás | Ellenintézkedés |
|---|---|---|
| NSI `/S` módban rejtett MessageBox-on beragad | pénztárgép „fagyott" telepítővel | 5.4/1 audit + IfSilent-ágak; timeout-figyelés a suite-updaterben (ha a gyerekfolyamat 15 perc után is él, log + riasztás) |
| 280 MB-os letöltés üzleti sávszélességen | lassú, ismételt letöltések | háttérletöltés + cache + csak egyszeri letöltés verziónként; később: delta-tömörítés vagy Opció B lokális tükör |
| Frissítés napzárás közben | pénzügyi folyamat megszakad | telepítés csak explicit user-megerősítéssel; „Később" mindig elérhető; mandatory-flag is csak prompt-gyakoriságot növel, kényszer-restartot nem |
| Régi (már kint lévő) pénztár-kliensek a `penztar.yml`-t keresik | ha véletlenül feltöltünk `penztar.yml`-t, a RÉGI kliensek electron-updater úton kezdenének frissíteni (3.2-es duplikált-install probléma) | **`penztar.yml`-t TILOS a release-be feltölteni**; a régi flotta az utolsó kézi (Drive) frissítéssel kapja meg a suite-updatert |
| GitHub-elérés hiánya az üzletben | frissítés nem jut el | monitoring a logból; tartós esetben Opció B (excvaluta.com feed) aktiválása |
| Publikus repo → bárki látja a release-eket | információ-kitettség | eddig is publikus; a telepítők aláírtak, secret nincs bennük (production secret gate a buildben) — változatlan kockázat |

## 8. Döntések (JÓVÁHAGYVA — 2026-08-12, Kósa Zoltán)

| # | Kérdés | DÖNTÉS |
|---|---|---|
| 1 | Feed | **GitHub Releases.** A repo publikus → anonim HTTPS + CDN, 0 üzemeltetés. Az excvaluta.com-os Opció B (3.5) csak igazolt tűzfal-akadály esetén aktiválódik. |
| 2 | Központi kliens telepítési mód | **Automatikus, kilépéskor** (`autoDownload: true` + `autoInstallOnAppQuit: true`). Kevés gép, nincs pénztári munkafolyamat-kockázat. |
| 3 | Pénztár kliens telepítési mód | **NINCS kényszerített frissítés, DE nincs „örökre elhalasztható" sem: állapotvezérelt telepítési ablak** — lásd 3.6. |

### 3.6 Pénztár: állapotvezérelt telepítési ablak (a 3. döntés kifejtése)

A pénztárgépen a frissítés soha nem szakíthat meg pénzügyi folyamatot, ugyanakkor nem
maradhat a kolléga döntésén, hogy egyáltalán frissül-e a gép. Ezért a suite-updater
**három állapotot** különít el, és a telepítés csak a semleges ablakokban indul:

| Állapot | Mit tesz az updater |
|---|---|
| **Munka közben** (nyitott műszak: van nyitott pénztár/kassza, folyamatban lévő tranzakció, napzárás-varázsló aktív) | Csak **jelzés**: nem tolakodó értesítés + állandó jelölő a felületen („Frissítés készen áll: v<X> — a következő napnyitás előtt telepszik"). Letöltés + hash/aláírás-ellenőrzés a háttérben lefut. Telepítő NEM indul, dialógus NEM ugrik fel. |
| **Napzárás UTÁN** (az adott napra a napzárás lezárva, nincs nyitott kassza) | Telepítés **felajánlása azonnal**, előtérbe hozott dialógussal: „Frissítés most (kb. 2-3 perc)" / „Holnap, napnyitás előtt". |
| **Napnyitás ELŐTT** (app elindult, de a napi műszak/nyitás még nem kezdődött el) | Telepítés **felajánlása belépéskor**, ez az elsődleges ablak. A kolléga a nap indítása előtt egy kattintással telepít. |

Szabályok, amelyek ebből következnek:

1. **A telepítés kiváltója nem az időzítő, hanem az állapotátmenet.** Az updater a
   letöltés befejeztével csak „készenálló" állapotba lép; a telepítést a napzárás
   lezárása vagy a napnyitás előtti állapot detektálása indítja (ill. ajánlja fel).
2. **Az állapotot a renderer/backend jelenti, nem az updater találgatja.** Kell egy
   IPC/állapot-lekérdezés (`suiteUpdate:shiftState` → `IDLE_BEFORE_OPEN` |
   `SHIFT_OPEN` | `CLOSED_AFTER_DAY_END`), amelynek forrása a meglévő
   műszak-/napzárás-állapot. Ha az állapot **nem megállapítható**, a viselkedés
   konzervatív: úgy kezeljük, mintha `SHIFT_OPEN` lenne (nem telepítünk).
3. **A jelzés nem tűnik el.** Amíg készen álló frissítés van, a felület jelöli — így
   a kolléga látja, és nem kell rá emlékezni.
4. **A `mandatory` flag nem kényszerít restartot**, csak azt jelenti, hogy a
   napnyitás előtti ablakban a dialógus alapértelmezett gombja a „Frissítés most",
   és a „Később" csak a következő állapotátmenetig halasztja (nem 4 órára).
5. **Kényszerített, munka közbeni restart tilos** — pénzügyi integritási invariáns
   (3.3/5. pont), a `mandatory` sem írja felül.

> A 2. fázis végrehajtási utasítása (5.4) ennek megfelelően bővül: a suite-updater
> állapotgépe `IDLE → CHECKING → DOWNLOADING → VERIFYING → READY → (ablak) → INSTALLING`,
> és a `READY → INSTALLING` átmenet **kizárólag** `IDLE_BEFORE_OPEN` vagy
> `CLOSED_AFTER_DAY_END` állapotban, felhasználói megerősítéssel történhet.
