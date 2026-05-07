---
type: reference
date: 2026-04-29
source: D:\repo\valutavalto-program\Anti\ (Delphi 7 + Java legacy)
priority: P0 — modern Pénztár Electron bug-ok forrásigazsága
related_docs:
  - D:\repo\valutavalto-program\Anti\antivaluta.md (805 sor, top-level)
  - D:\repo\valutavalto-program\Anti\ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md
  - D:\repo\valutavalto-program\docs\knowledge\legacy-reverse-engineering\INDEX.md (27 fájl)
  - D:\repo\valutavalto-program\docs\knowledge\legacy-reverse-engineering\legacy-dll-parity-matrix.md
  - D:\repo\valutavalto-program\docs\knowledge\legacy-reverse-engineering\RE-eszter-uzleti-logika-minoseg.md
  - D:\repo\valutavalto-program\docs\knowledge\legacy-reverse-engineering\RE-junior-teljes-rendszer-architektura.md
  - D:\repo\valutavalto-program\docs\knowledge\legacy-reverse-engineering\RE-gap-analysis-legacy-vs-modern.md
---

# Legacy Anti-Valutaváltó Rendszer — Forrás-igazság a moderntől szétcsúszott üzleti logikához

> **Cél:** A modern (Java + React + Electron) Pénztár alkalmazás üzleti logikai bug-jait
> (mode-mismatch, főértéktár vs értéktár vs pénztár szétkavarodás) a Delphi 7 legacy rendszerhez
> mint **kanonikus forráshoz** képest azonosítani és javítani.
>
> **A részletes RE-elemzések ([INDEX.md](../../repo/valutavalto-program/docs/knowledge/legacy-reverse-engineering/INDEX.md))
> NEM lettek törölve** — a 2026-04-02 + 2026-04-05 + 2026-04-09 elemzések git-ben élnek.
> Ez a vault dokumentum egy **fókuszált indexálás + szerep-szerinti operatív összegzés** a jelenlegi
> bug-okhoz, hogy ne kelljen 27 nagy fájlt átolvasni minden session-ben.

---

## 1. A legacy rendszer fő alkotóelemei (top-level)

| Komponens | Útvonal | Cél | Szerepkör (legacy) |
|---|---|---|---|
| **VALUTA/IBVALTO** | `Anti/VALUTA/IBVALTO/IBVALTO.DPR` | Pénztáros desktop EXE | **Pénztáros** (cashier) |
| **VALUTA/DLL** | `Anti/VALUTA/DLL/` | 110+ üzleti DLL (`c:\valuta\bin\`) | Pénztáros |
| **VALUTA/TRADE** | `Anti/VALUTA/TRADE/fejleszt/trade.dpr` | Telefon-feltöltés + autópálya-matrica EXE | Pénztáros (kiegészítő) |
| **ARFOLYAM** | `Anti/ARFOLYAM/Arfolyam.exe` (1.1 MB) | **Külön EXE — árfolyam-készítés** | **Főértéktár** (központi) |
| **ERTEKTAR** | `Anti/ERTEKTAR/etdll/` (55 alkönyvtár, DLL-ek) | Helyi értéktár modulok | **Értéktáros** (helyi) |
| **KESZLEX** | `Anti/KESZLEX/KESZLEX.EXE` | Készlet-export utility | Felügyelet/admin |
| **KORLEVEL_ZIP** | `Anti/KORLEVEL_ZIP/korlevel/` | Körlevél bizonylat-sablonok (109 db) | Központi (FOÉRTÉKTÁR + iroda) |
| **SZERVER** | `Anti/SZERVER/` (96+36+ modul üres mappa) | Központi szerver (REMOTEDBASE) | Központ |
| **camera/camera2/camera3** | `Anti/camera*/...` | Java multi-module kamera-rendszer | Biztonság |
| **firebird** | `Anti/firebird/` | Firebird 2.1.1 motor + tools | Adatbázis |

**Adatbázisok:**
- `c:\valuta\database\valuta.fdb` — fő törzsadat (pénztár, pénztárosok, ügyfelek, devizanem, árfolyam)
- `c:\valuta\database\valdata.fdb` — tranzakciós adatok
- `c:\valuta\database\trade.fdb` — kereskedés (havonta `TRADyymm` táblák)
- **REMOTEDBASE** (`193.68.57.146`) — központi szerver szinkron

---

## 2. Szerepkörök és modul-tulajdon (KRITIKUS a modern bug-okhoz!)

A legacy rendszer a következő **szigorú szerepköri szétválasztással** működött, amit a modern (React + Electron) rendszerben **össze-vissza kavart módon** valósítottunk meg:

### 2.1 Pénztáros (cashier — `penztar`)
**Hely:** `VALUTA/IBVALTO.exe` + `c:\valuta\bin\*.dll`

**Főmenü 1. oldal (FOMENUFORM Unit47, 9 pont):**
| # | Menüpont | DLL |
|---|---|---|
| 1 | VALUTA VÉTEL | `Vasarlas.dll` |
| 2 | VALUTA ELADÁS | `Eladas.dll` |
| 3 | VALUTA KONVERZIÓ | (Unit3 UJKONVERZIO) |
| 4 | PÉNZTÁRAK KÖZÖTTI ÁTADÁS-ÁTVÉTEL | `Atadolap.dll` + `Atadvet.dll` |
| 5 | MAI BIZONYLAT SZTORNÓJA | `Storno.dll` |
| 6 | NAPI FORGALOM KIMUTATÁSA | `Napiforg.dll` + `Maiforg.dll` |
| 7 | RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA | `REGIZARO.dll` |
| 8 | A PILLANATNYI ÁLLÁS REGENERÁLÁSA | `REGEN.dll` |
| 9 | EGYÉB BEÁLLÍTÁSOK ÉS PROGRAMOK | `Othertsk.dll` |

**Főmenü 2. oldal (8 pont):**
- ÁRFOLYAM **BEÁLLÍTÁSOK** (csak megtekintés, `getarf.dll` betölti, **NEM készíti!**)
- PILLANATNYI PÉNZTÁR ÁLLÁSA, BIZONYLAT MEGTEKINTÉSE, KÜLÖNFÉLE LISTÁK
- TÁRSPÉNZTÁRAK KARBANTARTÁSA (`ptartmk.dll`)
- VALUTA FORGALOM ÖSSZESÍTŐ (`Forgossz.dll`)
- NAPI- ÉS HAVIZÁRÁS (`Napzar.dll` + `Havizar.dll`)
- CÍMLETEZÉS (`Cimlet.dll` + `CIMLMENU.dll`)

**KRITIKUS:** A pénztáros **NEM készít árfolyamot** — kizárólag a központtól (FÖÉRTÉKTÁR) kapott, getarf.dll-en betöltött adatokat használja.

### 2.2 Értéktáros (helyi treasury — `ertektar`)
**Hely:** `Anti/ERTEKTAR/etdll/` (55 saját DLL alkönyvtár)

**A 55 értéktári DLL teljes listája:**
```
arftmk        atadolap     atadvet      bizodisp     bloknyom     checklst
cimlctrl      cimlet       cimlmenu     cimlnyom     cimsetup     estizar
getarf        getellen     getplomb     getptar      havizar      hrkatvevo
hrkcimlet     idoszak      irarfoly     kcimlet      keszedit     keszup
kezdij        korlev       listak       logdisp      logiro       maktablak
matptar       mentes       napijel      napikezd     napkonyv     napzar
nifval        nznyomt      penztarak    pictload     pillall      pillkesz
prosbe        prostmk      ptarkesz     ptartmk      quitform     ratectrl
rateperm      regen        regizaro     storno       super        supertsk
terminal      wunion
```

**Fő modulok szerep-szerinti csoportosítása:**

| Csoport | DLL-ek | Üzleti funkció |
|---|---|---|
| **Átadás-átvétel** | `atadolap`, `atadvet` | Pénztár ↔ értéktár belső mozgás (irodán belül) |
| **Címletezés** | `cimlet`, `cimlctrl`, `cimlmenu`, `cimlnyom`, `cimsetup`, `kcimlet`, `hrkcimlet` | Pénzkezelési címletezés (beérkező + kiadó) |
| **Készlet** | `pillall`, `pillkesz`, `keszup`, `keszedit`, `ptarkesz` | Pillanatnyi értéktári készlet |
| **Napi műveletek** | `napikezd` (nap-nyitás), `napzar` (nap-zár), `napkonyv` (napi könyv), `napijel` (napi jelentés), `nznyomt` (napzár-nyomtatás) | Napi értéktári műveletek |
| **Időszaki zárás** | `havizar`, `estizar`, `idoszak`, `regizaro`, `regen` | Hetente / havonta / dekád zárás |
| **Árfolyam-kapcsolódás** | `arftmk`, `irarfoly`, `ratectrl`, `rateperm`, `getarf` | **Árfolyamot KAP, ellenőriz, jóváhagy — DE NEM KÉSZÍT!** |
| **Pénztáros admin** | `prosbe`, `prostmk`, `super`, `supertsk` | Pénztáros belépés, supervisor jóváhagyás |
| **Pénztár-törzs** | `penztarak`, `ptartmk`, `getptar` | Pénztár-nyilvántartás |
| **Bizonylat** | `bizodisp`, `bloknyom` | Bizonylatok megjelenítése + nyomtatása |
| **Egyéb** | `wunion` (Western Union), `terminal` (POS), `kezdij` (kez. díj), `korlev` (körlevél), `listak`, `mentes`, `getellen`, `getplomb` | Speciális funkciók |

**KRITIKUS:** Az értéktáros (helyi):
- **NEM készít árfolyamot** (csak megkapja, ellenőrzi, jóváhagyja `ratectrl`/`rateperm`-en keresztül)
- **NEM lát országos dashboardot** (csak az iroda saját készletét, atadás-átvételét)
- **NEM kezel cross-iroda szállítást** (azt a főértéktár / szállító csinálja)

### 2.3 Főértéktáros (national main vault — `foertektar`)
**Hely:** `Anti/ARFOLYAM/Arfolyam.exe` + központi szerver REMOTEDBASE

**Funkciók (legacy):**
1. **Árfolyam-készítés** — `Arfolyam.exe` (1.1 MB önálló EXE)
   - Adatfájlok: `arfdata.dat` (272 KB), `ujdata.dat` (69 KB), `old_arfdata.dat` (41 KB)
   - **KÖZPONTILAG** állítja be a napi árfolyamokat
   - Az egész irodahálózatra publikálja `getarf.dll`-en keresztül
2. Központi készlet-monitor — minden iroda saját értéktári pillanatállapota
3. Cross-iroda szállítás (irányítás, jóváhagyás)
4. MNB kapcsolat (`mnbgyujto`, `mnbhibak`)
5. NAV kapcsolat (`SZERVER/ujdll/exclusive-nav-data-provider-server`)

**KRITIKUS:** A főértéktár:
- **NEM csinál pénztári vételet/eladást** (azt a pénztáros)
- **NEM csinál helyi átadást-átvételt** (azt a helyi értéktáros)
- **CSINÁL árfolyam-készítést, országos KPI-t, országos készletet, országos riportot**

### 2.4 Supervisor (felettes — ortogonális szerep)
**Hely:** `super.dll` (5 KB) + `SUPERTSK.dll`

A supervisor egy **szerep-független** jelszó-alapú jóváhagyás, ami bármely fenti szerepkör mellett működhet. Érzékeny műveleteket (sztornó, beállításmódosítás, dátum) supervisor-jelszóval kell engedélyeztetni.

`JELSZÓ RENDBEN !` / `ÉRVÉNYTELEN JELSZÓ !`

---

## 3. Modern (Java + React + Electron) megfeleltetés

A `docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md` adja a teljes mátrixot.
Itt csak a **szerepkör-szétválasztás** szempontból fontos részt összegezzük:

| Legacy szerep | Legacy hely | Modern hely | Modern menu group (`menuGroups.ts`) |
|---|---|---|---|
| Pénztáros | VALUTA/IBVALTO + DLL | Penztar Electron app, mode='penztar' | "Pénztár (Valutaváltó)" — `canonicalRoles: ["penztar"]`, `modes: ["penztar"]` |
| Helyi értéktáros | ERTEKTAR/etdll/* | Penztar Electron app, mode='ertektar' | "Értéktár (lokál)" — `canonicalRoles: ["ertektar"]`, `modes: ["ertektar"]` |
| Főértéktár | ARFOLYAM/Arfolyam.exe + központi szerver | frontend-react admin, mode='full' | "Főértéktár" + "Árfolyamok" — `canonicalRoles: ["foertektar","ugyvezeto"]`, `modes: ["full"]` |
| Supervisor | super.dll | RBAC + @PreAuthorize | (ortogonális jogosultság) |

### Modern app-mód → menu-csoport mátrix (ELVÁRT, legacy alapján)

| `app_mode` | Megjelenő menu csoportok | Tiltott |
|---|---|---|
| `penztar` | "Pénztár (Valutaváltó)", "Főoldal" (ha kell) | Mindenmás |
| `ertektar` | "Értéktár (lokál)", "Főoldal" (ha kell) | Mindenmás |
| `full` | "Főértéktár", "Árfolyamok", "Riportok", "AML", "Ügyfelek", "Adminisztráció", "HR", "Kamera", "Főoldal" | "Pénztár (Valutaváltó)" + "Értéktár (lokál)" — **NE jelenjen meg full módban**, mert ezek **lokális iroda-szintű mode-ok** (egy pénztár-gép vagy egy értéktár-gép) |

---

## 4. Modern Pénztár Electron — azonosított bug-ok (2026-04-29)

### Bug #1: SetupWizard nem futott, app_mode default = 'full'
**Tünet:** A user a v2.3.7 reinstall + Setup #3 SUCCESS után belépett, **DE a SetupWizard 5 lépés (Iroda → Program típus → Szerver → Admin → Telepítés) NEM jelent meg**. A program egyenesen a dashboardra vitte. Ez azt jelenti, hogy:
- Nem futott le a wizard, így `app_mode` SQLite config nincs beállítva
- A `useAppMode.ts` default-ja valószínűleg `'full'`
- Minden menu-csoport megjelenik, ami `modes: ["full"]`-vel rendelkezik + canonical role match

**Várt működés (legacy szerint):**
- Friss telepítés után a SetupWizard kötelezően lefut (Iroda kód, Program típus = `penztar` / `ertektar` / `full`, Szerver URL, Admin jelszó, Telepítés)
- A 2. lépés "Program típus" a `penztar-client/electron/.../sqlite-config.ts` `app_mode` mezőt írja be
- Default `'full'` **NEM ELFOGADHATÓ** értéktári vagy pénztári gépen

### Bug #2: Értéktár (lokál) menu látszik 'full' módban
**Tünet:** A user "főértéktáros módban" (valószínűleg `mode='full'` + `ugyvezeto`/`foertektar` role) látja az "Értéktár (lokál)" group-ot átadás-átvétel + naplókönyv + havi zárás menüpontokkal.

**Forrás:** A `frontend-react/src/layouts/menuGroups.ts` "Értéktár (lokál)" group-ja `modes: ["ertektar"]`-rel van címkézve, tehát 'full' módban **NEM SZABAD megjelennie**.

**Hipotézis a bug-ra:**
1. **A.** A layout szűrője nem AND-eli `modes` + `canonicalRoles`-t — csak az egyiket nézi (pl. csak role)
2. **B.** A layout fallback-elve megjeleníti az ertektar group-ot ha az `app_mode` `null` vagy `undefined`
3. **C.** A `useAppMode.ts` default-ja 'full', de a layout filter olyan logikát használ, ami 'full'-ban minden mode-ot include-ol (pl. `mode === 'full' || group.modes.includes(mode)` helyett `mode === 'full' && group.modes.includes('full')`)

**Helyes implementáció (legacy alapján):**
```typescript
// Csak az lát egy menü-csoportot, akinek
//   1. az app_mode-ja matchel a group.modes-szal (vagy a group nincs mode-szűrve)
//   2. a canonical role-jai egyikében szerepel a group.canonicalRoles
const visibleGroups = menuGroups.filter(g => {
  const modeOk = !g.modes || g.modes.includes(appMode)
  const roleOk = !g.canonicalRoles || userRoles.some(r => g.canonicalRoles.includes(r))
  return modeOk && roleOk
})
```

### Bug #3: "Árfolyam készítés F5" tab látszik értéktári dashboardon
**Tünet:** Az "Értéktár (lokál)" dashboardon megjelenik egy "Árfolyamkészítés F5" tab, amelyet a felhasználó megnyomva tud árfolyamot készíteni — **ez TILTOTT művelet helyi értéktárosnak!**

**Forrás:** Valószínűleg a treasury dashboard component (`frontend-react/src/pages/treasury/TreasuryDashboard.tsx` vagy hasonló) **hardkódolt módon** tartalmazza az árfolyamkészítés tab-ot, anélkül, hogy a `canonicalRoles: ["foertektar", "ugyvezeto"]`-szabályt ellenőrizné.

**Helyes implementáció (legacy alapján):**
- A helyi értéktáros dashboardján csak: dashboard összegzés, **átadás-átvétel** (cash desk → treasury), **átadás bank** (treasury → bank), szállítólevelek, úton lévő csomagok, helyi készlet, naplókönyv, napi/havi zárás, ügyfelek, **árfolyamok (csak nézet!)**.
- Árfolyam-készítés tab **CSAK** a `foertektar`/`ugyvezeto` role-os, mode='full' admin felületen.

### Bug #4: Főértéktár group-ban átadás-átvétel
**Tünet:** A user szerint "A főértéktárnál nincs átadás, átvétel, itt mégis van ilyen lista."

**Forrás:** A "Főértéktár" group jelenleg csak `Országos dashboard, Árfolyam kezelés, Árfolyam készítés, Árfolyam publikálás, MNB jelentések, Pénztáros KPI, Országos készlet, Készlet-snapshot, Értéktár leltár` menüpontokat tartalmaz. **Átadás-átvétel-t NEM!** Ez tehát **NEM** ebben a group-ban van.

A user feltehetően az "Értéktár (lokál)" csoport "Átadás-átvétel (pénztáraknak)" + "Átadás bank / másik értéktár" tételét látta — ami a **#2-es bug** (értéktár group hibás megjelenítése full módban).

---

## 5. Adatbázis-szintű forrás-igazságok (Firebird → PostgreSQL mapping)

A teljes Firebird séma `docs/knowledge/legacy-reverse-engineering/firebird-schema-reconstruction-index.md`-ben van.

**A jelenlegi bug-okhoz releváns 3 tábla:**

| Firebird tábla | PostgreSQL entity | Funkció |
|---|---|---|
| `PENZTAR` | `branch` (BranchService) | Iroda/pénztár-törzs |
| `PENZTAROSOK` | `worker` | Pénztáros-törzs |
| `IRODAK` | `branch` (alias-ként) | Iroda telephelyek |
| `ARFOLYAM` | `exchange_rate` (ExchangeRateService) | Devizanemenkénti vételi/eladási árfolyam |
| `BLOKKFEJ + BLOKKTETEL` | `transaction + transaction_item` | Bizonylat fejléc + tételek |
| `VTEMP` | (megszüntetve, stateless REST) | Ideiglenes munkaterület |

**Receipt prefix-mapping (legacy → modern):**
- Vétel: `V<3-digit branch code>NNNNNN` (pl. `V017000001` BR017-en) — `ReceiptSequenceService.extractBranchCode()`
- Eladás: hasonlóan, de `E` prefix
- Sztornó: `S` prefix
- Átadás kifelé: `F` (transfer_out)
- Átadás befelé: `U` (transfer_in)

---

## 6. Hivatkozási útmutató — hol mit találsz

```
Anti/antivaluta.md                     ← 805 sor top-level mapping (legacy struktúra + DLL lista)
Anti/ANTI_MODERNIZATION_*.md           ← modernizáció masterplan
Anti/ERTEKTAR/etdll/*/                 ← 55 értéktári DLL forrás
Anti/VALUTA/IBVALTO/IBVALTO.DPR        ← pénztáros fő EXE projekt
Anti/VALUTA/DLL/                       ← 110+ pénztári DLL forrás
Anti/ARFOLYAM/Arfolyam.exe             ← főértéktár árfolyam-készítő app
Anti/SZERVER/ujdll/                    ← 36 szerver DLL modul

docs/knowledge/legacy-reverse-engineering/
  INDEX.md                             ← tartalomjegyzék (S1-S3)
  RE-junior-teljes-rendszer-architektura.md     ← 50 KB, 110 DLL katalógus
  RE-egyestitett-osszes-csapat-elemzes.md       ← 180 KB, egyesített
  RE-tamas-technikai-architektura.md            ← 50 KB, technikai
  RE-eszter-uzleti-logika-minoseg.md            ← 50 KB, üzleti szabályok
  RE-gabor-uiux-design-wireframes.md            ← 40 KB, UI/UX
  RE-gap-analysis-legacy-vs-modern.md           ← gap analysis
  legacy-dll-parity-matrix.md                   ← legacy → modern mapping
  legacy-binary-functional-index.md             ← bináris index
  firebird-schema-reconstruction-index.md       ← DB séma
  firebird-table-to-modern-entity-matrix.md     ← tábla → entity
  szerver-business-logic.md                     ← szerver-oldali üzleti logika
  szerver-modules-index.md                      ← szerver-modulok
  aml-bigctrl-rule-parity.md                    ← AML-szabályok
  felmeres-hang-002..005-structured-summary.md  ← interjú-elemzések

docs/legacy-analysis-part1..4.md       ← 4-részes elemzés (core/screens/spreadsheets/technical)
docs/anti-code-files.txt               ← teljes Anti/ fájl-lista
docs/anti-code-summary.csv             ← Anti/ fájl-statisztika
```

---

## 7. Akció-lista a következő session-be (a bug-ok javításához)

1. **`useAppMode.ts` audit:** verifikálni hogy a default mód NEM 'full', hanem `null` (vagy a SetupWizard kényszerítése).
2. **`AppLayout.tsx` (vagy hasonló) menu-szűrés audit:** A `modes` + `canonicalRoles` AND-elése.
3. **`TreasuryDashboard.tsx` audit:** "Árfolyam készítés F5" tab eltávolítása (vagy `canonicalRoles` ellenőrzés a tab-on).
4. **SetupWizard kényszerítése:** Friss telepítés után, ha `app_mode` SQLite config nincs beállítva, a `App.tsx` redirectálja `/setup-wizard`-ra (NEM dashboardra).
5. **Playwright e2e teszt:** `excvaluta-full-menu.spec.ts` mintájára egy `mode-isolation.spec.ts` ami:
   - mode='penztar' → csak Pénztár csoport látszik
   - mode='ertektar' → csak Értéktár (lokál) csoport látszik
   - mode='full' → Pénztár + Értéktár (lokál) csoport NEM látszik

---

*Ez a dokumentum a legacy `Anti/` mappa + a 2026-04-02-i 5-fős RE-csapat-elemzés + a 2026-04-29-i Pénztár Electron bug-felderítés + a `frontend-react/src/layouts/menuGroups.ts` 174-soros forrásának összegzése. A részletes elemzések a `docs/knowledge/legacy-reverse-engineering/` mappában találhatók (27 fájl, ~450 KB), és NEM lettek törölve a 2026-04-27-i memória-tisztítás során.*
