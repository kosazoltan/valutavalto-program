---
type: reference
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Anti Valutavalto — UI/UX Design Elemzes es Modern Migracios Terv"
load: on-demand
---

# Anti Valutaváltó — UI/UX Design Elemzés és Modern Migrációs Terv

> **Szerző:** Gábor (Design & Graphics Chief)
> **Dátum:** 2026-04-02
> **Forrás:** `antivaluta-junior.md` (rendszer áttekintés) + `anti-dfm-pack.md` (DFM form layout-ok)
> **Kontextus:** Delphi 7 legacy rendszer → Java + React + Electron modern ERP migráció
> **Scope:** UI/UX elemzés, design antipattern feltárás, modern UX javaslatok, ASCII wireframe-ek

---


---

## S1 TARTALOMJEGYZEK

1. Vezetői összefoglaló
2. A legacy rendszer vizuális DNA-ja — DFM alapú elemzés
3. Navigációs architektúra elemzés
4. Képernyő-katalógus és ASCII wireframe-ek
   - 4.1 Főmenü (TRADE.EXE / Form1)
   - 4.2 Devizavásárlás (VASARLASFORM)
   - 4.3 Devizaeladás (ELADASFORM)
   - 4.4 Sztornó (STORNOFORM)
   - 4.5 Napzárás (NAPZARFORM)
   - 4.6 Bizonylat megjelenítő (BIZONYLATDISP)
   - 4.7 Ügyfél bevitel (UGYFELINPUT)
   - 4.8 Pénztáros belépés (PROSBELEP)
   - 4.9 Supervisor menü (SUPERVISORFORM)
   - 4.10 Foglalás (FOGLALO)
   - 4.11 Címletezés (CIMLETEZES)
   - 4.12 Bizonylat nyomtatás (BLOKKNYOM)
5. UI/UX antipatternák — részletes kritikai elemzés
6. Felhasználói folyamatok (User Flows) elemzése
7. Kognitív terhelés és ergonómia
8. Modern design rendszer javaslat
9. Komponens-könyvtár és design token-ek
10. Képernyő-architektúra a modern rendszerhez
11. Kritikus UX döntési pontok
12. Prioritás-mátrix és implementációs ütemterv
13. Összefoglalás

---


---

## S2 1_VEZETOI_OSSZEFOGLALO

Az Anti Valutaváltó rendszer egy **Delphi 7-ben írt, Win32 asztali alkalmazás**, amely 2000-es évek közepének design paradigmáit tükrözi. A 110+ DLL modulra épülő architektúra, a hardkódolt abszolút koordináták, a `bsNone` border-stílus és a TShape-alapú layout mind egy olyan korszak termékei, amikor a desktop UI fejlesztés legjobb práktikái alapvetően mások voltak.

### Kulcsmegállapítások

**Erősségek (amit meg kell tartani):**
- A valutaváltási workflow logikailag érthető és lineáris
- A nagy betűs, kontrasztos fejlécek (ELADÁS, VÁSÁRLÁS) vizuálisan segítik a gyors orientációt
- A keyboard-first megközelítés (End/Escape billentyűk) profi pénztáros-munkavégzést támogat
- A moduláris DLL-architektúra izolált funkcionalitást biztosít

**Kritikus problémák (amit modernizálni kell):**
- Abszolút pixel-pozicionálás → nem skálázható, nem reszponzív
- Konzisztens design language hiánya (minden form más színvilágban, más fontokban)
- Nulla accessibility support (screen reader, billentyűzet-navigáció rendszertelen)
- Modal-heavy UX (minden DLL `ShowModal`) → párhuzamos munkavégzés lehetetlen
- Hardkódolt 1024×768 → modern kijelzőkön használhatatlan skálán fut
- Nincs state management, nincs visszavonás, nincs undo
- Az ügyfél-azonosítási flow rendkívül hosszú és megzavarható

### Migrációs stratégia egy mondatban

> A modern rendszernek meg kell tartania a **pénztáros-centrikus, gyors billentyűzetes munkavégzési paradigmát**, miközben egy egységes, skálázható, hozzáférhető React component library-n alapuló design rendszert vezet be.

---


---

## S3 2_A_LEGACY_RENDSZER_VIZUALIS_DNA_JA_DFM_ALAPU_ELEMZES

### 2.1 Szín- és stílusrendszer rekonstrukció

A DFM fájlok alapján az egyes formok saját, egymástól eltérő színvilágot használnak:

| Form | Háttérszín | Fejléc | Akcentus |
|------|-----------|--------|---------|
| TRADE főmenü | `clMoneyGreen` (#00FF80 jellegű) | Fehér keret | Fehér szegély 8px |
| VASARLASFORM | `6324288` (sötét kékeszöld) | `clNavy` szöveg | `clSilver` árnyék-duplikátum |
| ELADASFORM | `16756991` (halvány kék) + `clNavy` keret | `clRed` + `clSilver` duplikátum | Piros/ezüst 3D-effekt |
| STORNOFORM | `clTeal` | `clWhite` Elephant font | `clGreen` panel |
| NAPZARFORM | `3289650` (sötétzöld) | `clYellow` szöveg | `clWhite` keret |
| UGYFELINPUT | `10526880` (ólomszürke-kék) | — | AlphaBlend=True |
| PROSBELEP | `clBlack` + `5592405` (szürkéskék) | `clYellow` szöveg | `10066329` (sötét) |
| SUPERVISORFORM | `clGray` + `clBlack` | `clYellow` szöveg | `5592405` panel |
| BIZONYLATDISP | `clWhite` alap | `4210752` (sötétszürke) | `clYellow` fejléc |
| FOGLALO | `clMedGray` | háttérkép (tengerpart JPEG) | TImage fullscreen |
| CIMLETEZES | `11599871` (kékeszöld) | `clMoneyGreen` keret | `15782096` (arany) |

**Következtetés:** A rendszerben **legalább 8 különböző színséma** van párhuzamosan alkalmazva. Nincs egységes design token, nincs brand guideline, nincs konzisztens UX.

### 2.2 Tipográfia elemzés

A DFM-ekben előforduló fontok:

| Font | Előfordulás | Kontextus |
|------|------------|---------|
| `MS Sans Serif` | MINDEN form alapértelmezése | Alap UI szöveg (11pt) |
| `Times New Roman` | ELADÁS/VÁSÁRLÁS fejlécek | 96pt (!) szuperméretű fejlécek |
| `Arial Narrow` | STORNO instrukciós szövegek | Bold Italic |
| `Arial` | Bizonylat grid, STORNO bizonylat | Bold, 19-29pt |
| `Elephant` | STORNO főcím | 27pt Bold — dekoratív |
| `Britannic Bold` | BIZODISP NAV gomb | Monospaced decorative |
| `Stencil` | Verziófelirat (főmenü) | 32pt Bold Italic — katonai stencil |
| `Times New Roman Italic` | Napzárás checklist | 21pt Italic |

**Kritika:** 8 különböző fontcsalád, 5+ különböző méreti skála, inkonzisztens stílus. A `Elephant` és `Stencil` fontok kifejezetten dekoratív, nem üzleti célra tervezett betűtípusok — egy pénztári rendszerben ez professzionalizmus-hiányra utal.

### 2.3 Layout koordináták elemzése

**VASARLASFORM (1031×752 px) layout mérés:**
- Fejléc blokk: Shape1 @ Left=152, Top=10, W=649, H=105 → a form szélességének 63%-a
- Fő beviteli terület: Shape2 @ Left=24, Top=128, W=945, H=361 → 91% széles, 48% magas
- Árfolyam panel: Shape20 @ Left=816, Top=8, W=169, H=105 → jobb felső sarok
- Devizanem panel: Shape22 @ Left=8, Top=8, W=129, H=105 → bal felső sarok
- Számoló terület: Shape3-4 @ Left=40-232, Top=550, H=105 → alsó harmad
- Akció gombok: Shape6-7 @ Left=432-712, Top=660, H=49 → legalul

**ELADASFORM (1001×755 px) layout mérés:**
- Fejléc: Shape1 @ Left=296, Top=16, W=441, H=105 → középen, kisebb mint a VASARLAS
- Árfolyam box: Shape2 @ Left=752, Top=24, W=225, H=105
- Fő beviteli: Shape3 @ Left=24, Top=136, W=945, H=353
- Devizanem bal: Shape21 @ Left=24, Top=16, W=257, H=105

**Megállapítás:** Még a két legfontosabb, egymáshoz legszorosabban kapcsolódó képernyő (vétel/eladás) sem egységes layout-on alapul. A fejléc pozíciója, a panel méretek, a gomb elhelyezések mind különböznek.

### 2.4 Interakciós modellek

**Billentyűzetes navigáció:**
- `End` → tranzakció rögzítése / jóváhagyás (mindkét form alján felirat: "End")
- `Escape` → kilépés a formból (mindkét form alján felirat: "Escape")
- `FormKeyDown` eseménykezelők → billentyűzetes workflow-k
- `DBGrid OnDblClick` → bizonylat megnyitás dupla kattintással

**Modális ablakok:**
- Minden DLL `ShowModal`-lal hívódik → a teljes alkalmazás blokkolódik
- Nincs párhuzamos munkafolyamat (pl. árfolyam ellenőrzése tranzakció közben)
- Nincs Tab-sorend dokumentáció a DFM-ekben

### 2.5 A "3D árnyék" szöveg technika

Az ELADÁS és VÁSÁRLÁS fejléceken alkalmazott vizuális technika:

```
Label11 (clRed, 96pt, Left=328, Top=16)    ← előtér, piros
Label1  (clSilver, 96pt, Left=344, Top=24) ← árnyék, ezüst, 16px offsettel
```

Ez egy 2000-es évekbeli Delphi "3D szöveg" trükk — két azonos szöveges label pixeleltolással, hogy mélység-illúziót keltsen. Érdemes megjegyezni, hogy ez a mai CSS `text-shadow` egyenértékűje volt, egykor.

---


---

## S4 3_NAVIGACIOS_ARCHITEKTURA_ELEMZES

### 3.1 A jelenlegi navigáció

A jelenlegi rendszer navigációs modellje: **Lapos, közvetlen modal-hívás**.

```
TRADE.EXE (főmenü)
    │
    ├── [TelefonGomb] → TELEFONFORM.dll (ShowModal)
    ├── [MatricaGomb] → AUTOPALYAFORM.dll (ShowModal)
    ├── [ListaGomb]   → ZARAS.dll → (belül tovább)
    │                              ├── NAPZAR.dll
    │                              ├── NAPKONYV.dll
    │                              ├── NAPIFORG.dll
    │                              └── ...
    ├── [KilepesGomb] → QUITFORM.dll (megerősítés)
    ├── [TanusitvanyGomb] → SUPER.dll jelszó → GETTANUSITVANY.dll
    └── [LOGOLVASOGOMB]   → SUPER.dll jelszó → LOGOLVASAS.dll

Devizaváltás (nincs külön gomb a főmenün! — belső flow)
    └── ELADAS.dll / VASARLAS.dll → UGYFEL.dll → TERROR.dll → BLOKNYOM.dll
```

**Probléma:** A devizaváltás — a rendszer elsődleges funkciója — nem látható a főmenün! A pénztáros a "Lista és Zárás" gombból navigál a tényleges váltási funkciókhoz, ami kontra-intuitív.

### 3.2 Navigációs mélység-térkép

```
Szint 0: TRADE.EXE főmenü (4+2 gomb)
    │
    Szint 1: DLL modal (egyszerre egy látható)
        │
        Szint 2: Belső DLL-hívás más DLL-ből
            │
            Szint 3: Megerősítő dialog (CONFIRM.dll, QUITFORM.dll)
```

Maximális navigációs mélység: **3-4 szint**, de mivel minden szint blokkoló modal, a felhasználó nem látja, hol tart a folyamatban.

### 3.3 Kontextus-elvesztési pontok

1. A STORNO formban bizonylat kiválasztása után ha a pénztáros visszanavigál, az indoklás mező ürül
2. A VASARLAS és ELADAS formokban ha internetkapcsolat szakad, a form bezárul adatvesztéssel (VTEMP tábla maradvány)
3. UGYFEL bevitelkor ha a terror szűrés meghiúsul, az egész ügyfél-adatbevitel elvész

---


---

## S5 4_KEPERNYO_KATALOGUS_ES_ASCII_WIREFRAME_EK

### 4.1 Főmenü (TRADE.EXE / Form1)

**DFM adatok:**
- Méret: 1022×740px, `bsNone`, `wsMaximized`
- Háttér: `Shape2` — `clMoneyGreen` fill, `clWhite` Pen.Width=8
- Verziófelirat: `Label4` — "35.10 verzió", `Stencil` font, 32pt, clRed
- Jobb felső: `Shape4` RoundRect

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│██████████████████████████████████████████████████████████████████████████████████████│
│█                                                                                    █│
│█  35.10 verzió          [EXCLUSIVE BEST CHANGE logó/fejléc]       [Tanúsítvány]    █│
│█  (Stencil, piros)                                                [Szerkesztés]     █│
│█                                                                                    █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         T E L E F O N                       │                      █│
│█              │         feltöltés                           │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         M A T R I C A                       │                      █│
│█              │         autópálya                           │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │     L I S T Á K  /  Z Á R Á S              │                      █│
│█              │                                             │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         K I L É P É S                       │                      █│
│█              │                                             │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█  [NAPLÓ]                                          [háttérkép: NYC skyline]        █│
│██████████████████████████████████████████████████████████████████████████████████████│
```

**UX kritika:**
- A **devizaváltás nincs a főmenün** — a rendszer primér funkciója láthatatlan
- 4 főgomb + 2 supervisor gomb = nagyon szűk funkcionális felület
- A "Lista és Zárás" összevont gomb kettős felelősséget hordoz (riport + napi zárás)
- A háttérkép (New York City skyline) `Image1` komponensként be van ágyazva → teljesen irreleváns a pénztári kontextusban

---

### 4.2 Devizavásárlás (VASARLASFORM)

**DFM adatok:**
- Méret: 1031×752px, `bsNone`
- Háttér: `6324288` (sötét kékeszöld)
- Fejléc: VÁSÁRLÁS — kétréteges Label (clNavy + clSilver árnyék), 96pt Times New Roman Bold
- `AlphaBlendValue = 225` (95% opák)
- Shape22 = devizanem bal felső (Left=8, W=129)
- Shape20 = árfolyam jobb felső (Left=816, W=169)
- Shape2 = fő input zóna (Left=24, Top=128, W=945, H=361)
- Shape3 = bal alsó panel (Left=40, Top=550, W=177, H=105)
- Shape4 = jobb alsó panel (Left=232, Top=550, W=745, H=105)
- Shape6, Shape7 = akció gombok alul

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ [EUR]      ╔══════════════════════════════════════════╗      [Árfolyam: 395.50]     │
│ devizanem  ║         V Á S Á R L Á S                 ║      [Vételi / Eladási]      │
│            ║         (96pt Times, Navy+Silver)        ║                              │
│            ╚══════════════════════════════════════════╝                              │
│                                                                                      │
│ ╔══════════════════════════════════════════════════════════════════════════════════╗ │
│ ║  DEVIZA BEVITEL                                                                  ║ │
│ ║                                                                                  ║ │
│ ║  Összeg 1: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 2: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 3: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 4: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 5: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 6: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║                                                                                  ║ │
│ ║  [WA1..WA6 = összegmezők, WB1..WB6 = bankjegy, WD1..WD6 = darab]               ║ │
│ ╚══════════════════════════════════════════════════════════════════════════════════╝ │
│                                                                                      │
│ ╔═══════════╗  ╔═══════════════════════════════════════════════════════════════╗    │
│ ║  KÉSZLET  ║  ║  FIZETENDŐ:                              [125 480 Ft]         ║    │
│ ║  [állapot]║  ║  Kezelési díj: [500 Ft]     Nettó: [124 980 Ft]              ║    │
│ ╚═══════════╝  ╚═══════════════════════════════════════════════════════════════╝    │
│                                                                                      │
│              [  End — RÖGZÍT  ]              [  Escape — KILÉP  ]                   │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A WA1-WA6, WB1-WB6, WD1-WD6 mező-elnevezések szoftverfejlesztői nómenklatúra, nem felhasználóbarát
- 6 sor × 3 mező = 18 input mező egyidejűleg látható → kognitív túlterhelés
- Az árfolyam csak a jobb felső sarokban látható — nem kiemelkedő pozíció egy tranzakció szempontjából kritikus adatnak
- Nincs vizuális visszajelzés a gépelt összeg érvényességéről (keret-szín váltás, ikon)
- A `End` billentyű nem ENTER — nem intuitív első használatra
- A devizanem (EUR, USD stb.) kis méretű dobozban, bal felső sarokban → elveszett

---

### 4.3 Devizaeladás (ELADASFORM)

**DFM adatok:**
- Méret: 1001×755px, `bsNone`
- Háttér: `16756991` (halvány égkék)
- Fejléc: ELADÁS — kétréteges Label (clRed + clSilver árnyék, 96pt Times New Roman Bold Italic)
- Shape1 = fejléc keret (Left=296, Top=16, W=441, H=105) — KISEBB mint a VÁSÁRLÁSNÁL
- Shape21 = bal panel (Left=24, Top=16, W=257) — NINCSEN a VÁSÁRLÁSNÁL

**Megállapítás:** Az ELADÁS és VÁSÁRLÁS form szinte tükörképek üzletileg, de design szempontból különbözők:
- Más háttérszín (halvány kék vs. sötét kékeszöld)
- Más fejléc-pozíció és méret
- A fejléc szín más (piros vs. navy)
- Bal felső panel eltér (Shape21 vs. Shape22 eltérő méretű)

Ez azt jelenti, hogy a pénztáros vizuálisan is különbséget tud tenni vétel és eladás között — ez pozitív. De a végrehajtás ad hoc, nem rendszer-szintű designdöntés.

**Rekonstruált layout (összehasonlításban VASARLAS-szal):**

```
VÁSÁRLÁS (sötét háttér, navy fejléc):        ELADÁS (világos háttér, piros fejléc):
┌──────────────────────────────────┐          ┌──────────────────────────────────┐
│ [EUR]          VÁSÁRLÁS          │          │ [bal box]      ELADÁS            │
│                (navy/silver)     │ [Árfolyam│                (red/silver)      │
│                                  │  jobb f.]│                                  │
│  ╔══════════════════════════╗   │          │  ╔══════════════════════════╗   │
│  ║ 6×3 input mező           ║   │          │  ║ 6×3 input mező           ║   │
│  ╚══════════════════════════╝   │          │  ╚══════════════════════════╝   │
│  [Készlet] [Fizetendő panel]     │          │  [bal panel] [jobb panel]        │
│      [End]           [Escape]    │          │       [End]          [Escape]    │
└──────────────────────────────────┘          └──────────────────────────────────┘
```

---

### 4.4 Sztornó (STORNOFORM)

**DFM adatok:**
- Méret: 612×517px, `bsNone`
- Háttér: `clTeal`
- Fejléc: "MAI BIZONYLAT STORNÓJA" — `Elephant` font, 27pt Bold, fehér szöveg
- Panel1 (clGreen háttér): a fő tartalmi panel
- `radiok: TGroupBox` (Left=24, Top=64, W=193, H=281) — 4 radio gomb (VR/ER/UR/FR)
- `BIZONYLATRACS: TDBGrid` (Left=224, Top=76, W=329, H=267) — bizonylat lista
- Label9 "Bizonylat:" + Label1 "keresése ..." — szöveges vezető
- `INDOKEDIT` — indoklás mező

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────┐
│  MAI BIZONYLAT STORNÓJA   (Elephant font, 27pt, fehér/teal) │
│                                                              │
│  ╔════════════════════════════════════════════════════════╗  │
│  ║ (clGreen panel)                                        ║  │
│  ║                                                        ║  │
│  ║  VÁLASSZA KI A SZTORNÓZANDÓ BIZONYLATOT                ║  │
│  ║                                                        ║  │
│  ║  ┌─────────────────┐   ┌───────────────────────────┐  ║  │
│  ║  │ ( ) Vétel (VR)  │   │ BIZONYLAT  │ ÖSSZEG       │  ║  │
│  ║  │ ( ) Eladás (ER) │   │────────────┼──────────────│  ║  │
│  ║  │ ( ) Ügyfél (UR) │   │ 00123456   │   125 480    │  ║  │
│  ║  │ ( ) Forrás (FR) │   │ 00123457   │    45 200    │  ║  │
│  ║  │                 │   │ 00123458   │   318 000    │  ║  │
│  ║  │                 │   │            │              │  ║  │
│  ║  └─────────────────┘   └───────────────────────────┘  ║  │
│  ║                                                        ║  │
│  ║  Bizonylat: [___________________]   keresése ...       ║  │
│  ║                                                        ║  │
│  ║  Indoklás: [_____________________________________________]║  │
│  ║                                                        ║  │
│  ║   [ IGEN — Sztornózom ]     [ NEM — Mégsem ]          ║  │
│  ║                                                        ║  │
│  ╚════════════════════════════════════════════════════════╝  │
└──────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A `radiok` TGroupBox-ban 4 rádió gomb van (VR/ER/UR/FR) — ezek kódbetűk, nem felhasználóbarát megnevezések
- A bizonylat grid csak 2 oszlopot mutat (BIZONYLATSZAM, FIZETENDO) — hiányzik a dátum, devizanem, ügyfél
- A dupla megerősítés (`Surestorno`) külön DLL-ből hívódik — a flow megszakad
- Az indoklás mező helye (alul, a grid alatt) nem logikus — inkább a kiválasztás után kellene

---

### 4.5 Napzárás (NAPZARFORM)

**DFM adatok:**
- Méret: 578×504px, `bsNone`, `AlphaBlendValue = 180` (30% átlátszó!)
- Háttér: `3289650` (nagyon sötétzöld)
- Fejléc: "NAPI PÉNZTÁRZÁRÁS" — `clYellow`, 32pt Times New Roman Bold Italic
- `DATUMPANEL`: 2017.05.22 felirat (hardkódolt demo dátum!), 29pt Arial Bold Italic, fehér
- `ELLENORPANEL` (Visible=False): 5 ellenőrzési lépés panel

**Az ELLENORPANEL 5 lépése:**
- E1: MTCN számok ellenőrzése
- E2: Pénztárzárás címletezése
- E3: Kezelési díj ellenőrzése
- E4: W.U. címletezése
- E5: ÁFA pénztár címletezése

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│       NAPI PÉNZTÁRZÁRÁS                              │
│       (clYellow, 32pt, sötétzöld háttér)             │
│                                                      │
│  ╔══════════════════════════════════════════════╗    │
│  ║  2017.05.22   (DATUMPANEL — aktuális dátum)  ║    │
│  ╚══════════════════════════════════════════════╝    │
│                                                      │
│  ╔══════════════════════════════════════════════╗    │
│  ║ [ELLENORPANEL — kezdetben Visible=False]      ║    │
│  ║                                              ║    │
│  ║  ╔═══════════════════════════════════════╗   ║    │
│  ║  ║  Ellenőrzési folyamatok               ║   ║    │
│  ║  ╟───────────────────────────────────────╢   ║    │
│  ║  ║  E1: MTCN számok ellenőrzése    [ OK ]║   ║    │
│  ║  ║  E2: Pénztárzárás címletezése   [ .. ]║   ║    │
│  ║  ║  E3: Kezelési díj ellenőrzése   [ .. ]║   ║    │
│  ║  ║  E4: W.U. címletezése           [ .. ]║   ║    │
│  ║  ║  E5: ÁFA pénztár címletezése    [ .. ]║   ║    │
│  ║  ╚═══════════════════════════════════════╝   ║    │
│  ║                                              ║    │
│  ╚══════════════════════════════════════════════╝    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**UX kritika:**
- `AlphaBlendValue = 180` → a form 30%-ban átlátszó, az alatta lévő háttér átütközik — ez nem szándékos design, hanem véletlen konfiguráció
- Az ELLENORPANEL `Visible=False`-szal indul — a felhasználó nem látja rögtön, mi fog történni
- A lépések (E1-E5) szekvencián belüli státuszjelzés csak a panel megjelenésekor látható
- Nincs haladásjelző (progress bar), nincs becsült idő
- A napzárás 14+ eljárásból áll, de ezek a felhasználó számára teljesen láthatatlanok

---

### 4.6 Bizonylat megjelenítő (BIZONYLATDISP)

**DFM adatok:**
- Méret: 1067×767px, `bsNone`
- Háttér: `clWhite`
- `blokkfejpanel`: 333×33px, `4210752` (sötétszürke), clYellow szöveg — "Blokk fejek"
- `BLOKKFEJRACS: TDBGrid` (Left=4, Top=40, W=325, H=641) — bal oldali lista
  - Oszlopok: BIZONYLATSZAM, DATUM, IDO, OSSZESFORINTERTEK (BLOKK FT), KEZELESIDIJ (KEZ-DIJ)
- Jobb oldal: részlet panel (nem teljes a DFM excerpt-ben, de következtethető)
- `Panel1`: "NAV NYUGTA" gomb (Color=7829367, Britannic Bold, fehér)

**Rekonstruált layout:**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ Blokk fejek                  │  [NAV NYUGTA]  │ [szűrő gombok] │ [akció panel]     │
│ (sötétszürke, sárga szöveg)  │                │                │                   │
│                              │                │                                     │
│ ┌──────────────────────────┐ │ ┌────────────────────────────────────────────────┐  │
│ │BIZONYLAT│DATUM │IDO │FT  │ │ │                                                │  │
│ │─────────┼──────┼────┼────│ │ │  BIZONYLAT RÉSZLETEI                          │  │
│ │00123456 │04-01 │09:15│125k│ │ │                                                │  │
│ │00123457 │04-01 │10:22│ 45k│ │ │  Típus:      Devizavásárlás                   │  │
│ │00123458 │04-01 │11:05│318k│ │ │  Devizanem:  EUR                              │  │
│ │00123459 │04-01 │11:47│ 82k│ │ │  Összeg:     320 EUR                          │  │
│ │00123460 │04-01 │12:30│201k│ │ │  Árfolyam:   395.50                           │  │
│ │         │      │    │    │ │ │  Kezelési díj: 500 Ft                          │  │
│ │         │      │    │    │ │ │  Fizetendő:  126 560 Ft                        │  │
│ │         │      │    │    │ │ │  Pénztáros:  KOVÁCS ANNA                       │  │
│ │         │      │    │    │ │ │  Ügyfél:     KISS BÉLA                         │  │
│ │         │      │    │    │ │ │                                                │  │
│ └──────────────────────────┘ │ │  [Újranyomtatás] [NAV Nyugta] [Sztornó]       │  │
│                              │ └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A bal oldali grid tömör, sűrű — az `OSSZESFORINTERTEK` és `KEZELESIDIJ` mezőneveket a fejléc felülírja, de az eredeti DB-mezőneveket megőrzi
- A szűrési lehetőségek (dátum, típus, pénztáros, ügyfél) vizuálisan nem kiemelkedők
- Nincs keresés mező — a TDBGrid görgetéssel navigálható
- Nem derül ki a DFM-ből, hogy van-e lapozás nagy adathalmaznál

---

### 4.7 Ügyfél bevitel (UGYFELINPUT)

**DFM adatok:**
- Méret: 781×820px (a legmagasabb form!), `bsNone`, `AlphaBlend = True`
- Háttér: `10526880` (ólomszürkéskék)
- Tartalmaz egy `VIRAG` nevű TImage-t (Left=-2200!) — off-screen, valószínűleg deaktiváltan maradt
- `NaturAdatok` és `JogiAdatok` — két váltható panel

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL ADATBEVITEL                                                  │
│                                                                      │
│  [ Természetes személy ]   [ Jogi személy ]   ← TabControl          │
│                                                                      │
│  TERMÉSZETES SZEMÉLY:                                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Név:          [________________________]                       │  │
│  │  Anyja neve:   [________________________]                       │  │
│  │  Szül. hely:   [______________]  Dátum: [____.__.__]           │  │
│  │  Állampolgárság: [__________]                                   │  │
│  │  Lakcím:       [________________________]                       │  │
│  │                [________________________] (irányítószám/város)  │  │
│  │  Okmánytípus:  ( ) Személyi  ( ) Útlevél  ( ) Egyéb            │  │
│  │  Okmányszám:   [______________]  Lejárat: [____.__.__]         │  │
│  │  ( ) Belföldi  ( ) Külföldi                                     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  JOGI SZEMÉLY:                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Cégnév:       [________________________]                       │  │
│  │  Székhely:     [________________________]                       │  │
│  │  Adószám:      [______________]                                 │  │
│  │  Cégforma:     [______________]   TEÁOR: [______]              │  │
│  │  Megbízott személy adatai (természetes személy panel)           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│           [ MENTÉS — End ]              [ MÉGSEM — Escape ]         │
└──────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- `AlphaBlend = True` — nem látni a DFM-ben az AlphaBlendValue-t, ha 0 akkor teljesen átlátszó!
- A `VIRAG` TImage `Left=-2200`-nál van — ez szándékos off-screen elhelyezés (valószínűleg eltávolítottak egy háttérképet, de a komponens maradt)
- Az ügyfél-adatbeviteli form 820px magas — 1024×768-as képernyőn is alig fér el
- A 300.000 Ft feletti tranzakcióknál kötelező azonosítás, de nincs vizuális visszajelzés arról, hogy a küszöböt átléptük

---

### 4.8 Pénztáros belépés (PROSBELEP)

**DFM adatok:**
- Méret: 641×316px, `bsNone`, `AlphaBlendValue = 200`
- Háttér: `clBlack`
- `PENZTAROSLISTAPANEL` (Color=10066329): pénztáros lista grid
  - Shape6: lista keret (Left=32, Top=56, W=577, H=201, RoundRect)
  - Shape7: gomb keret (Left=240, Top=264, W=169, H=48, RoundRect)
- `BIZTOSPANEL` (Color=5592405): azonosítás megerősítés
  - ELSONEVPANEL: első megadott név megjelenítés
  - HASNEVPANEL: hasonló nevű személy megjelenítés
  - SAMEPERSONGOMB: "A KÉT NÉV UGYANAZ A SZEMÉLY"
  - MISTAKEGOMB: "ELTÉVESZTETTEM A JELÖLÉST"

**Rekonstruált layout — Login képernyő:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  (clBlack háttér, sötétkék panel)                                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │  PÉNZTÁROS NEVE           │ KÓDJA │ ÁLLAPOT                   │  │
│  │  ─────────────────────────┼───────┼───────────────────────── │  │
│  │  KOVÁCS ANNA              │ KA01  │ szabad                    │  │
│  │  NAGY PÉTER               │ NP02  │ szabad                    │  │
│  │  HORVÁTH MÁRIA            │ HM03  │ elfoglalt                 │  │
│  │  TÓTH ZSOLT               │ TZ04  │ szabad                    │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│                    ┌─────────────────┐                               │
│                    │   BELÉPÉS       │                               │
│                    └─────────────────┘                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Rekonstruált layout — Dupla azonosítás megerősítés:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  (5592405 sötétkék panel)                                           │
│                                                                      │
│                   Biztos, hogy                                       │
│                                                                      │
│  KOVÁCSNÉ HERGERÖDER VILMALLE                                        │
│         (előző azonosítás neve)                                      │
│                                                                      │
│                      azonos                                          │
│                                                                      │
│  KOVÁCSNÉ H. ALADÁR LAJOSNÉ-VAL                                     │
│         (hasonló névminta a listából)                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │         [ A KÉT NÉV UGYANAZ A SZEMÉLY ]                     │    │
│  │         [ ELTÉVESZTETTEM A JELÖLÉST  ]                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- Az `AlphaBlendValue = 200` (~80% opák) → az alatta lévő tartalom látszik belőle — ez login képernyőn biztonsági kockázat (az előző session adatai látszanak)
- A duplaellenőrzési panel (BIZTOSPANEL) jó UX ötlet, de a szöveg ("A KÉT NÉV UGYANAZ A SZEMÉLY") nagybetűs, zord tónusú
- A pénztáros lista állapota (szabad/elfoglalt) jó funkció — megtartandó

---

### 4.9 Supervisor menü (SUPERVISORFORM)

**DFM adatok:**
- Méret: 610×418px, `bsNone`
- Háttér: `clGray`
- Panel1 (clBlack): teljes leftpanel
  - Shape1 (5592405 sötétkék, Left=160, W=377): a jobb oldali funkciók területe
  - Shape2 (10066329 sötétbarna, Left=24, W=329): a bal oldali gombterület
  - Label2: "SUPERVISOR MENÜJE" — Times New Roman 27pt Bold Italic, clYellow

**Gombok (bal oldali lista):**
1. XTRANZGOMB: "EXTRA TRANZAKCIÓS DÍJAK" (Left=40, Top=120)
2. BitBtn2: "CÍMLETEK BEÁLLÍTÁSA" (Top=152)
3. BitBtn1: "LOGFILE KIOLVASÁSA" (Top=184)
4. checklistgomb: "CHECKLISTA ELLENŐRZÉSE" (Top=248)
5. BitBtn4: "PÉNZTÁRI SZÜNETEK" (Top=280)
6. BitBtn3: "KILÉPÉS A SUPERVISORI MENÜBŐL" (Top=312)

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────┐
│  (clGray + clBlack panel)                                        │
│                                                                  │
│  SUPERVISOR MENÜJE                ┌──────────────────────────┐  │
│  (sárga, 27pt Times Bold Italic)  │                          │  │
│                                   │  [tartalom területe]     │  │
│  ╔════════════════════════════╗   │                          │  │
│  ║                            ║   │                          │  │
│  ║ [EXTRA TRANZAKCIÓS DÍJAK]  ║   │                          │  │
│  ║ [CÍMLETEK BEÁLLÍTÁSA    ]  ║   │                          │  │
│  ║ [LOGFILE KIOLVASÁSA     ]  ║   │                          │  │
│  ║ [CHECKLISTA ELLENŐRZÉSE ]  ║   │                          │  │
│  ║ [PÉNZTÁRI SZÜNETEK      ]  ║   │                          │  │
│  ║ [KILÉPÉS                ]  ║   │                          │  │
│  ║                            ║   │                          │  │
│  ╚════════════════════════════╝   └──────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A supervisor menü 5+1 funkciót tartalmaz — ez elfogadható méret
- Azonban a "SZTORNÓ INDÍTÁSA" nincs itt (az a főmenüből elérhető, de supervisor jelszóval) — az architektúra nem egyértelmű
- A jobb oldali panel (Shape1) üres a DFM-ben — valószínűleg dinamikusan töltődik tartalommal

---

### 4.10 Foglalás (FOGLALO)

**DFM adatok:**
- Méret: 996×764px, `bsNone`
- Háttér: `clMedGray` + `Image1` teljes képernyős JPEG (tengerpart fotó, `alClient`)
- A TImage `alClient` → a háttérkép lefedi a teljes formot

**UX kritika:**
- A devizafoglalás — amely üzleti szempontból kritikus funkcionalitás — tengerpartot ábrázol háttérképként
- A háttérkép JPEG bele van kompilálva a DFM-be (a Picture.Data óriási base64 blob) → a DLL méretét drasztikusan megnöveli
- A `clMedGray` szürke színnel kombinálva a tengerpart fotó nagyon inkonzisztens üzleti megjelenést ad

---

### 4.11 Címletezés (CIMLETEZES)

**DFM adatok:**
- Méret: 1054×798px, `bsNone`
- Háttér: `11599871` (kékeszöld), `clMoneyGreen` keret, Pen.Width=5
- Shape1: jobb fele (Left=480, W=497, H=641) — a tényleges bejegyzési terület
- Shape2..Shape15: 14 soros, egyenként 35px magas deviza-sor (Left=488, W=160) — szélességük: 15% arányban
- KK1..KK15: bal oldali devizanem-jelölők (Left=408, W=26, H=24) — apró négyzetek

**Rekonstruált layout:**

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  CIMLETEZES   (kékeszöld háttér, arany/moneygreen keret)                          │
│                                                                                   │
│  ╔═══════════════════════════════════════╗  ╔═══════════════════════════════════╗ │
│  ║                                       ║  ║  Devizanem │ 1  │ 2  │ 5  │ 10 │  ║ │
│  ║  [KK]  EUR  [bevitel mező]            ║  ║  ─────────────────────────────── ║ │
│  ║  [KK]  USD  [bevitel mező]            ║  ║  EUR  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  GBP  [bevitel mező]            ║  ║  USD  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  CHF  [bevitel mező]            ║  ║  GBP  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  CZK  [bevitel mező]            ║  ║  CHF  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  PLN  [bevitel mező]            ║  ║  CZK  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  ...  ...                       ║  ║  PLN  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  ... (14 devizanem összesen)    ║  ║  ...  │    │    │    │    │    ║ │
│  ║                                       ║  ║       │    │    │    │    │    ║ │
│  ╚═══════════════════════════════════════╝  ╚═══════════════════════════════════╝ │
│                                                                                   │
│       [ MENTÉS ]               [ MÉGSE ]                                          │
└───────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- 14 devizanem × több títusi darabszám = nagyon sok mező egyszerre
- A KK1-KK15 komponensek (26×24px kis négyzetek) vizuálisan nehezen értelmezhetők
- A Shape2-Shape15 sorok egységes 35px magasak — ez nagyon tömör a szem számára

---

### 4.12 Bizonylat nyomtatás (BLOKKNYOM)

**DFM adatok:**
- Méret: 272×56px (!) — ez messze a legkisebb form
- Háttér: Shape1 `4539717` (sötétzöld), Pen.Width=3
- Label1: "Nyomtatás" — Times New Roman 32pt Bold Italic, clYellow

**UX értékelés:**
- Ez valójában nem egy valódi UI form, hanem egy átmeneti "nyomtatás folyamatban" indikátor
- A 272×56px-es mini-ablak a képernyő közepén megjelenik és eltűnik
- Semmiféle haladásjelzés, visszaszámlálás vagy állapotinformáció nincs rajta

---


---

## S6 5_UIUX_ANTIPATTERNAK_RESZLETES_KRITIKAI_ELEMZES

### 5.1 A "minden szín más" antipattern

**Probléma:** A rendszerben legalább 15 különböző háttérszín van azonosítva. Néhány példa a DFM-ekből:
- `clTeal` (STORNO) — türkiz
- `3289650` (NAPZAR) — sötétzöld
- `10526880` (UGYFEL) — szürkéskék
- `clMedGray` (FOGLALO)
- `6324288` (VASARLAS) — sötétkékeszöld
- `16756991` (ELADAS) — halvány kék
- `clMoneyGreen` (TRADE főmenü)
- `clWhite` (BIZONYLATDISP)
- `clGray` (SUPERVISOR)
- `clBlack` (PROSBELEP)
- `11599871` (CIMLET) — kékeszöld
- `clBtnFace` (BLOKNYOM)

**Következmény:** A felhasználó minden új form megnyitásakor vizuálisan "újraorientálódik". Nincs brand identity, nincs vizuális hierarchia a rendszer egészén belül.

**Modern megoldás:** 3-5 szem-barát, kontrasztos szín az egész rendszerre + tokenzált design system.

### 5.2 A "font-káosz" antipattern

**Probléma:** 8+ különböző fontcsalád, 5+ méret, random stílus-kombinációk (Bold, Italic, BoldItalic, BoldItalic együtt).

Legszélsőségesebb példa: `Elephant` font a STORNO főcímén — egy kalandregény borítón talán elfogadható, de pénztári rendszerben professzionalizmus-hiány.

**Modern megoldás:** 1 fontcsalád (Inter vagy Roboto), 3 méret (body/heading/display), 2 súly (Regular/Bold).

### 5.3 A "modal-pokol" antipattern

**Probléma:** 110+ DLL mind `ShowModal`-lal hívódik. Ez azt jelenti:
- Párhuzamos munkavégzés lehetetlen
- Nincs "vissza" gomb — Escape az egyetlen out
- Ha egy belső DLL hibát dob, az egész lánc leszakad
- A felhasználó nem látja a breadcrumb-ot (hol tart a folyamatban)

**Legrosszabb eset:** VASARLAS → UGYFEL → TERROR → (TERROR feltételesen) → BLOKNYOM
Ez 4 egymásba ágyazott modális ablak, mindegyik blokkol.

**Modern megoldás:** Wizard-alapú step-by-step flow egyetlen oldalon, state machine-nel.

### 5.4 A "hardkódolt koordináták" antipattern

**Probléma:** Minden elem abszolút pixel-pozícióban van (Left=, Top=, Width=, Height=). Nincs layout manager, nincs flexbox ekvivalens, nincs responsive.

Következmény:
- 1024×768 under → egyes elemek kilógnak
- 4K felett → az egész UI egyötöd méretben jelenik meg
- Betűméret-növelés (accessibility) → törések

**Modern megoldás:** CSS Flexbox/Grid, relative units (rem/%), media query-k.

### 5.5 A "láthatatlan elsődleges funkció" antipattern

**Probléma:** A rendszer elsődleges üzleti funkciója (devizaváltás) nem szerepel a főmenün. A pénztáros a "Lista és Zárás" menüponton keresztül jut el hozzá.

Ez valószínűleg egy "lista → napi forgalom → új tranzakció" workflow-ból eredő tervezési döntés, amely az idők során megváltozott, de a menüstruktúra nem követte a változást.

**Modern megoldás:** A főképernyőn a devizaváltás prominens helyzetben — quick-access gombok (Vétel, Eladás, Sztornó).

### 5.6 A "beágyazott JPEG háttérkép" antipattern

**Probléma:** A FOGLALO és UGYFEL formok fotográfiákat tartalmaznak base64-kódoltan beágyazva a DFM-be. Ez:
- Megnöveli a DLL fájl méretét (a FOGLALO DFM-ben látható óriási Picture.Data blob)
- A fotók nem kapcsolódnak az üzleti funkcióhoz
- Beágyazott fotó módosításhoz a forráskódot kell újrafordítani

**Modern megoldás:** Külső asset (SVG vagy PNG), CSS background, teljes grafikamentesség lehetséges és javasolt.

### 5.7 A "kriptikus mezőnevek" antipattern

**Probléma:** `WA1..WA6`, `WB1..WB6`, `WD1..WD6`, `VR`, `ER`, `UR`, `FR` — ezek mind belső kódneveket használnak a felhasználói felületen.

A WA/WB/WD prefix valószínűleg: W=Window, A=Amount/Összeg, B=Banknote, D=Darab. Ez fejlesztői naming convention, ami kiszivárg a UI-ba.

**Modern megoldás:** Magyar nyelvű, leíró mezőcímkék: "Összeg (EUR)", "Bankjegy típus", "Darabszám".

### 5.8 A "35 karakter wide nyomtató" legacy antipattern

**Probléma:** A blokknyomtató formátum 39 karakteres sorokban gondolkodik, ESC/POS parancsokkal. Ez LPT1-es párhuzamos portos nyomtatót feltételez.

A `VetelSzamlaNyomtatas`, `EladasSzamlaNyomtatas` stb. eljárások fix szélességű szöveges sorokba "formatálnak" — nem valódi dokumentum-renderelés.

**Modern megoldás:** HTML/CSS nyomtatási template, ESC/POS megtartása hardveres kompatibilitáshoz de logika szétválasztva a megjelenítéstől.

### 5.9 A "XOR titkosítás" biztonsági antipattern

**Probléma:** A logfájlok `chr(255 - ord(karakter))` invertálással "titkosítottak" — ez nem titkosítás, csak invertálás. Bármilyen szövegszerkesztő ANSI dekódolással olvassa a logokat.

Ez egy UI/UX szempontból releváns pont: az "XOR-kódolt napló" megjelenítéshez egy LOGDISP.dll van, ami vizuálisan "visszatérít" — a felhasználó nem tudja közvetlenül olvasni a logokat.

**Modern megoldás:** Strukturált JSON logging, valódi titkosítás (AES), log viewer UI-jal.

### 5.10 A "hardkódolt FTP credentials" antipattern

**Probléma:** A COPY2FTP DLL-ben:
```
_userid := 'ebc-10%';
_ftpPassword := 'klc+45%';
```
Ez a UI/UX szempontból azért releváns, mert a hibakezelési dialógokban ezek megjelenhetnek (pl. "FTP kapcsolódási hiba: ebc-10%@185.43.207.99").

---


---

## S7 6_FELHASZNALOI_FOLYAMATOK_USER_FLOWS_ELEMZESE

### 6.1 Devizavásárlás teljes flow (as-is)

```
[Pénztáros bejelentkezik]
        ↓
[Főmenü megjelenik]
        ↓ (Lista és Zárás gomb → ZARAS.dll)
[Napi listák menü]
        ↓ (Új tranzakció → VASARLAS.dll)
[VASARLASFORM megjelenik]
        ↓
[Devizanem kiválasztás] ← ha ez nincs meg a form betöltésekor, prompt
        ↓
[WA1-WA6 összegek bevitele, WB1-WB6 bankjegyek, WD1-WD6 darabszámok]
        ↓ (Újraszámolás automatikusan)
[Fizetendő összeg megjelenik]
        ↓ (ha > 300 000 Ft)
[UGYFELINPUT megnyílik] ← kötelező azonosítás
        ↓
[Természetes/jogi személy adatok]
        ↓ (TERROR.dll)
[Terror szűrés ellenőrzés]
        ↓ (ha átment)
[BLOKNYOM.dll] ← bizonylat nyomtatás
        ↓
[VASARLASFORM bezárul]
        ↓
[Visszatér a Napi listák menübe]
```

**Teljes flow lépéseinek száma:** 10-15 lépés, ebből 4-6 különböző DLL-ablak
**Becsült idő normál esetben:** 2-4 perc/tranzakció
**Hibakezelési pontok:** Nincs visszavonás, nincs checkpoint

### 6.2 Modern devizavásárlás flow (to-be)

```
[Gyorsbillentyű: F1 = Vásárlás]
        ↓
[Egységes képernyő: devizanem + összeg + árfolyam]
        ↓ (auto-számítás gépelés közben)
[Limit ellenőrzés → banner megjelenik ha > 300k]
        ↓
[Ha szükséges: ügyfél-azonosítás inline panel kinyílik]
        ↓ (End/Enter)
[Megerősítés overlay]
        ↓ (Igen)
[Bizonylat nyomtatás auto + PDF mentés]
        ↓
[Visszatér az üres beviteli képernyőre]
```

**Lépéseinek száma:** 4-6 lépés
**Becsült idő:** 1-2 perc/tranzakció
**Hibakezelési pontok:** Undo az utolsó 30 másodpercben, auto-mentett draft

---

### 6.3 Napzárás flow (as-is)

```
[Supervisor engedélyezi a napzárást]
        ↓
[NAPZAR.dll ShowModal]
        ↓
[ELLENORPANEL felvillan (Visible→True)]
        ↓
[E1: MTCN ellenőrzés (async WU query)]
        ↓
[E2: Pénztárzárás címletezése (CIMLMENU.dll hívás)]
        ↓
[E3: Kezelési díj ellenőrzés]
        ↓
[E4: WU. címletezése]
        ↓
[E5: ÁFA pénztár címletezése]
        ↓
[Adatok feltöltés szerverre (COPY2FTP.dll)]
        ↓
[Nyomtatás (NZNYOMT.dll)]
```

**Probléma:** Ha az E1 MTCN ellenőrzés megakad (pl. WU szerver nem elérhető), az egész napzárás blokkolódik. Nincs "kihagyom ezt a lépést" opció, nincs részleges zárás.

---


---

## S8 7_KOGNITIV_TERHELES_ES_ERGONOMIA

### 7.1 Miller-törvény alkalmazása

A Miller-törvény szerint az emberi rövid távú memória 7±2 elemet képes egyszerre kezelni. A VASARLAS form beviteli területe:
- 6 összegmező + 6 bankjegymező + 6 darabszámmező = **18 mező egyszerre**

Ez háromszorosa az optimálisnak. A pénztáros valójában ritkán tölt ki mind a 6 sort — legtöbbször 1-2 devizanem-sor elegendő. Az összes többi mező vizuális zaj.

**Modern megoldás:** Dinamikus sorkezelés — alapesetben 1-2 sor látható, "+" gombbal bővíthető.

### 7.2 Hick-törvény alkalmazása

A Hick-törvény szerint a döntési idő logaritmikusan nő a lehetőségek számával. A főmenü 4+2 gombja (6 opció) jó. A ZARAS DLL-en belüli almenü azonban (ha megnyílik) valószínűleg 10+ lehetőséget tartalmaz.

### 7.3 Fitts-törvény alkalmazása

A Fitts-törvény szerint a kattintás ideje függ a célterülettől és annak távolságától. A SUPERTSK form gombok:
- Gomb szélességek: mind 297px — ez nagyon bőséges, jó
- Gomb magasságok: 25px — ez **nagyon alacsony** — ujjal nem kattintható, egérrel is nehéz

**Modern megoldás:** Minimum 44px gombmagasság (Apple HIG iránya), touch-kompatibilis méretek.

### 7.4 Billentyűzet-navigáció értékelés

**Pozitív:** End/Escape billentyűk következetesen alkalmazva — ez profi pénztárosi munkamódot segít.

**Negatív:**
- Nincs Tab-sorrend dokumentáció a DFM-ekben
- A `FormKeyDown` eseménykezelők custom logikát implementálnak — ez debug-ban nehézkes
- Nincs keyboard shortcut rendszer (pl. F2=Vásárlás, F3=Eladás, F4=Sztornó)

### 7.5 Error prevention

A jelenlegi rendszer error prevention stratégiái:
- `Surestorno` dupla megerősítés sztornónál ✓
- `UresPenztarControl` üres pénztár ellenőrzés napzárnál ✓
- `MTCNControl` WU ellenőrzés napzár előtt ✓
- TERROR szűrés 300k felett ✓

**Hiányok:**
- Nincs valós idejű összeg-érvényesítés bevitel közben
- Nincs árfolyam-frissítési figyelmeztetés (ha régi árfolyammal dolgozik)
- Nincs "nem mentett adatok" figyelmezetés kilépéskor

---


---

## S9 8_MODERN_DESIGN_RENDSZER_JAVASLAT

### 8.1 Design elvek

A modern valutaváltó rendszer design elvei:

**1. Speed-first UX**
A pénztáros munkája repetitív, időkritikus. Minden extra kattintás, minden extra várakozás gazdasági veszteség. A design minden döntésénél az a kérdés: *"Hogyan csökkentjük az egy tranzakcióhoz szükséges interakciók számát?"*

**2. Error-resistant design**
A hibás tranzakció visszavonása bonyolult (sztornó DLL, supervisor jelszó, indoklás). Ezért a bevitel előtt kell megelőzni a hibákat: összeg-érvényesítés, árfolyam-konfirmáció, ügyfél-azonosítási figyelmeztetés.

**3. Regulatory compliance by design**
Az AML/KYC, PEP ellenőrzés, NAV bizonylatolás NEM opcionális funkció — ezek a jogszabályból következő kötelezettségek. A designnak ezeket elsőrendű elemként kell kezelni, nem "popup"-ként.

**4. Keyboard-first, touch-optional**
A pénztáros billentyűzettel dolgozik. Az egér másodlagos. De a modern rendszer touch-képernyős táblagépen is futhat (remote pénztár). Ezért: keyboard-first, touch-compatible.

**5. Consistent visual language**
Minden képernyő azonos design language-t használ. A különböző műveletek (vétel vs. eladás) vizuálisan megkülönböztethetők, de nem zavarba ejtően más rendszert alkotnak.

### 8.2 Szín-token rendszer

```
-- Primer (branding)
--color-primary:          #1E3A5F    /* sötétkék — EBC brand */
--color-primary-light:    #2563EB    /* medium kék — interactive */
--color-primary-dark:     #0F1E35    /* nagyon sötét — header */

-- Szemantikus (funkcionális)
--color-buy:              #047857    /* sötétzöld — VÁSÁRLÁS */
--color-sell:             #B91C1C    /* sötétvörös — ELADÁS */
--color-storno:           #92400E    /* sötétbarna — SZTORNÓ */
--color-warning:          #D97706    /* narancs — figyelmeztetés */
--color-success:          #059669    /* zöld — siker */
--color-error:            #DC2626    /* piros — hiba */

-- Háttér
--color-bg-primary:       #F8FAFC    /* szinte fehér — fő tartalom */
--color-bg-secondary:     #EFF6FF    /* halvány kék — panel */
--color-bg-dark:          #0F1E35    /* sötétkék — navigáció */

-- Szöveg
--color-text-primary:     #0F172A    /* majdnem fekete */
--color-text-secondary:   #475569    /* középszürke */
--color-text-inverse:     #F8FAFC    /* fehér — sötét háttéren */
--color-text-muted:       #94A3B8    /* halvány — placeholder */

-- Keret
--color-border:           #E2E8F0    /* halvány szürke */
--color-border-focus:     #2563EB    /* kék — fókuszálva */
```

### 8.3 Tipográfia-rendszer

```
-- Font family
--font-primary:   'Inter', system-ui, -apple-system, sans-serif;
--font-mono:      'JetBrains Mono', 'Courier New', monospace;

-- Méretek
--text-xs:      0.75rem   (12px)   -- apró jelölések
--text-sm:      0.875rem  (14px)   -- secundary szöveg
--text-base:    1rem      (16px)   -- alap szöveg
--text-lg:      1.125rem  (18px)   -- kiemelés
--text-xl:      1.25rem   (20px)   -- al-fejléc
--text-2xl:     1.5rem    (24px)   -- fejléc
--text-3xl:     1.875rem  (30px)   -- szekció fejléc
--text-4xl:     2.25rem   (36px)   -- oldal cím
--text-display: 3rem      (48px)   -- tranzakció összeg (prominens)

-- Súlyok
--font-normal:   400;
--font-medium:   500;
--font-semibold: 600;
--font-bold:     700;
```

### 8.4 Spacing rendszer (8pt grid)

```
--space-1:   0.25rem   (4px)
--space-2:   0.5rem    (8px)
--space-3:   0.75rem   (12px)
--space-4:   1rem      (16px)
--space-5:   1.25rem   (20px)
--space-6:   1.5rem    (24px)
--space-8:   2rem      (32px)
--space-10:  2.5rem    (40px)
--space-12:  3rem      (48px)
--space-16:  4rem      (64px)
--space-20:  5rem      (80px)
--space-24:  6rem      (96px)
```

---


---

## S10 9_KOMPONENS_KONYVTAR_ES_DESIGN_TOKEN_EK

### 9.1 Tranzakció-összeg kijelző komponens

Ez a legkritikusabb vizuális elem. A pénztárosnak 1 másodperc alatt el kell tudnia olvasni a fizetendő összeget.

```
╔══════════════════════════════════════════════╗
║  FIZETENDŐ                                   ║
║                                              ║
║     125 480 Ft                               ║
║     (48px, Inter Bold, --color-text-primary) ║
║                                              ║
║  Kezelési díj: 500 Ft      Nettó: 124 980 Ft ║
║  (14px, Inter Regular, --color-text-secondary)║
╚══════════════════════════════════════════════╝
```

### 9.2 Devizanem-választó komponens

```
┌────────────────────────────────────────────────────────────┐
│  Devizanem                                                 │
│                                                            │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐          │
│  │ 🇪🇺 │  │ 🇺🇸 │  │ 🇬🇧 │  │ 🇨🇭 │  │ 🇨🇿 │  │ 🇵🇱 │ ...    │
│  │ EUR│  │ USD│  │ GBP│  │ CHF│  │ CZK│  │ PLN│          │
│  └────┘  └────┘  └────┘  └────┘  └────┘  └────┘          │
│  [KIVÁLASZTVA: EUR]  ──  Aktuális árfolyam: 395.50 Ft/EUR  │
└────────────────────────────────────────────────────────────┘
```

### 9.3 Ügyfél-azonosítás inline banner

```
┌────────────────────────────────────────────────────────────┐
│  ⚠️  AML FIGYELMEZTETÉS                                    │
│                                                            │
│  Az összeg (318 000 Ft) meghaladja a 300 000 Ft limitet.   │
│  Kötelező ügyfél-azonosítás szükséges.                     │
│                                                            │
│  [ AZONOSÍTÁS MEGKEZDÉSE ]   [ Árfolyam módosítás ]        │
└────────────────────────────────────────────────────────────┘
```

### 9.4 Napzárás haladásjelző komponens

```
╔══════════════════════════════════════════════════════════════╗
║  NAPI PÉNZTÁRZÁRÁS — 2026.04.02.                            ║
║                                                             ║
║  Folyamat: 3 / 5                                            ║
║  ████████████████░░░░░░░░░░░░░░░░░  60%                    ║
║                                                             ║
║  ✓  MTCN számok ellenőrzése         OK                      ║
║  ✓  Pénztárzárás címletezése        OK                      ║
║  ⟳  Kezelési díj ellenőrzése        folyamatban...          ║
║  ○  W.U. címletezése                várakozik               ║
║  ○  ÁFA pénztár címletezése         várakozik               ║
║                                                             ║
╚══════════════════════════════════════════════════════════════╝
```

### 9.5 Billentyűzetes navigáció chip-ek

```
[ End = Rögzít ]   [ Esc = Mégse ]   [ F2 = Vásárlás ]   [ F3 = Eladás ]
```

Ezeket a keyboard shortcut-okat a képernyő állandó alap-sávjában kell megjeleníteni (status bar), hogy mindig láthatók legyenek.

---


---

## S11 10_KEPERNYO_ARCHITEKTURA_A_MODERN_RENDSZERHEZ

### 10.1 Főképernyő layout (shell)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│ │  [EBC logó]   Exclusive Best Change Zrt.   [Pénztár: PÉCS-01]   [KOVÁCS ANNA] ▼ │ │
│ │  (--color-bg-dark, fehér szöveg, 56px magas topbar)                              │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│ ┌────────────────┐  ┌──────────────────────────────────────────────────────────────┐ │
│ │ NAV SÁV        │  │  FŐ TARTALOM                                                 │ │
│ │ (240px, dark)  │  │                                                              │ │
│ │                │  │  [Devizaváltás / Napi forgalom / Bizonylatok / Zárás stb.]   │ │
│ │ ○ Devizaváltás │  │                                                              │ │
│ │   ├ Vásárlás   │  │                                                              │ │
│ │   ├ Eladás     │  │                                                              │ │
│ │   └ Sztornó    │  │                                                              │ │
│ │ ○ Foglalás     │  │                                                              │ │
│ │ ○ Ügyfelek     │  │                                                              │ │
│ │ ○ Bizonylatok  │  │                                                              │ │
│ │ ○ Listák       │  │                                                              │ │
│ │ ○ Pénztár      │  │                                                              │ │
│ │   ├ Nyitás     │  │                                                              │ │
│ │   ├ Napzárás   │  │                                                              │ │
│ │   └ Havi zárás │  │                                                              │ │
│ │ ─────────────  │  │                                                              │ │
│ │ ≡ Supervisor   │  │                                                              │ │
│ │ ─────────────  │  │                                                              │ │
│ │ → Kilépés      │  │                                                              │ │
│ └────────────────┘  └──────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│ ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│ │  [F2] Vásárlás   [F3] Eladás   [F4] Sztornó   [F5] Listák       [Esc] Mégse    │ │
│ │  (Status bar — állandó billentyűzet-segítség, 32px magas)                       │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Devizavásárlás képernyő (modern, to-be)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  DEVIZAVÁSÁRLÁS                          [2026.04.02. 09:15]   [KOVÁCS ANNA]        │
│  (--color-buy zöld fejlécsáv, fehér szöveg)                                          │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  DEVIZANEM  ───────────────────────────────────────────────                   │  │
│  │                                                                                │  │
│  │  [ EUR ▼ ]   Aktuális vételi árfolyam: 395.50 Ft/EUR   [Módosítás ▶]         │  │
│  │                                                                                │  │
│  │  ÖSSZEGEK  ────────────────────────────────────────────                       │  │
│  │                                                                                │  │
│  │  ┌──────────────────┬────────────────┬──────────────┬──────────────────────┐  │  │
│  │  │ Bankjegy értéke  │ Darabszám      │ Deviza összeg│ Forint érték         │  │  │
│  │  ├──────────────────┼────────────────┼──────────────┼──────────────────────┤  │  │
│  │  │ 100 EUR          │  [   3  ]      │  300 EUR     │  118 650 Ft          │  │  │
│  │  │ 50 EUR           │  [   1  ]      │   50 EUR     │   19 775 Ft          │  │  │
│  │  │ [+ Sor hozzáad]  │                │              │                      │  │  │
│  │  └──────────────────┴────────────────┴──────────────┴──────────────────────┘  │  │
│  │                                                                                │  │
│  │  Összesen: 350 EUR                                                             │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────┐ ┌───────────────────────────────┐   │
│  │  ELSZÁMOLÁS                               │ │  FIZETENDŐ                    │   │
│  │                                           │ │                               │   │
│  │  Bruttó deviza:      350.00 EUR           │ │     138 425 Ft                │   │
│  │  Kezelési díj:         1 000 Ft           │ │     (48pt, bold, --color-buy) │   │
│  │  Nettó forint:       137 425 Ft           │ │                               │   │
│  │  Kerekítés:               +0 Ft           │ │  [ End — RÖGZÍT ✓ ]           │   │
│  │  Fizetendő:          138 425 Ft           │ │  [ Esc — MÉGSE  ✗ ]           │   │
│  └───────────────────────────────────────────┘ └───────────────────────────────┘   │
│                                                                                      │
│  ⚠  Az összeg nem haladja meg a 300 000 Ft-os azonosítási limitet.                  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.3 Ügyfél-azonosítás modern flow (inline wizard)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL AZONOSÍTÁS   ●──────●──────○──────○                                         │
│                      1.Alap  2.Okm. 3.Ellenőr. 4.Kész                              │
│                                                                                      │
│  1. ALAPADATOK  ───────────────────────────────────────────────────────────────────  │
│                                                                                      │
│  Személy típusa:   ( ●) Természetes személy    ( ) Jogi személy                     │
│                                                                                      │
│  Teljes név:  [_________________________________]                                   │
│  Anyja neve:  [_________________________________]                                   │
│                                                                                      │
│  Születési hely: [______________]    Dátum: [ 1965 ▼ ] [ 03 ▼ ] [ 12 ▼ ]          │
│  Állampolgárság: [ Magyar ▼ ]                                                        │
│  Lakcím:  [_____________________________________]                                   │
│           [_____________] [__________________________]  (irányítószám, város)       │
│                                                                                      │
│  Lakóhely típusa:  ( ●) Belföldi    ( ) Külföldi                                   │
│                                                                                      │
│  ─────────────────────────────────────────────────────────────────────────────────  │
│  [ ← Vissza ]                                              [ Tovább: Okmányok → ]   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.4 Sztornó képernyő (modern)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  SZTORNÓ                                        [2026.04.02.]   [SUPERVISOR MÓD]   │
│  (--color-storno sötétbarna fejléccsík)                                              │
│                                                                                      │
│  Sztornó típusa:                                                                     │
│  [ ● Devizavétel ]  [ Devizaeladás ]  [ Ügyfél rekord ]  [ Forráskód ]              │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐    │
│  │  BIZONYLAT   │ DÁTUM       │ DEVIZANEM │  ÖSSZEG     │ PÉNZTÁROS  │ÜGYFÉL   │    │
│  │  ────────────┼─────────────┼───────────┼─────────────┼────────────┼─────── │    │
│  │  00123458    │ 2026.04.02. │ EUR       │  138 425 Ft │ KOVÁCS A.  │KISS B.  │    │
│  │  00123459    │ 2026.04.02. │ USD       │   45 200 Ft │ KOVÁCS A.  │ —       │    │
│  │  00123460    │ 2026.04.02. │ GBP       │  201 300 Ft │ KOVÁCS A.  │NAGY M.  │    │
│  └─────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
│  Keresés bizonylat szerint: [________________________]                              │
│                                                                                      │
│  Kiválasztott bizonylat: 00123458 — EUR vétel — 138 425 Ft — KISS BÉLA              │
│                                                                                      │
│  Indoklás (kötelező): [_______________________________________________________]     │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │  ⚠  FIGYELEM: Ez a művelet visszafordíthatatlan. Biztosan sztornózza?        │   │
│  │                                                                              │   │
│  │         [ SZTORNÓZOM ]                      [ MÉGSEM ]                      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---


---

## S12 11_KRITIKUS_UX_DONTESI_PONTOK

### 11.1 Single Page Application vs. Multi-Window

**Kérdés:** Az Electron alkalmazás egyszerre egy ablakot használjon (SPA-szerű), vagy nyithatók legyenek párhuzamos ablakok?

**Javaslat:** SPA + drawer/panel alapú megközelítés. Az eddigi modal-heavy rendszerrel szemben egyetlen ablakban, belső navigációval. Ez:
- Megakadályozza az ablakok összetévesztését
- Jobb állapotkezelés (React state)
- Könnyebb keyboard-navigáció

**Kivétel:** A VFD ügyfélkijelző (customer-facing display) külön ablakban futhat.

### 11.2 Bizonylat nyomtatás stratégia

**Jelenlegi:** LPT1 párhuzamos port → közvetlen ESC/POS
**Modern opciók:**
1. ESC/POS over USB (megtartja a hardver-kompatibilitást, Node.js driver)
2. Thermal printer WebUSB API (Electron-kompatibilis)
3. HTML→PDF→print (rugalmasabb, de lassabb)

**Javaslat:** Hibrid megközelítés — az ESC/POS nyomtató-specifikus layer megtartása (gazdasági kényszerpálya), de a bizonylat-template HTML/CSS alapú legyen, amit runtime konvertál ESC/POS-ra.

### 11.3 Offline működés

**Jelenlegi:** A rendszer induláskor `Vaninternet` ellenőrzés — ha nincs internet, NEM indul el.

**Modern javaslat:** Offline-first architektúra:
- Helyi SQLite/IndexedDB a tranzakciók átmeneti tárolására
- Szinkronizáció hálózat-visszaálláskor
- "Offline mód" banner a UI-ban, amely jelzi az állapotot
- Árfolyamok lokálisan cache-elve (max. 24 órás érvényesség)

### 11.4 Supervisor auth modern megközelítés

**Jelenlegi:** SUPER.dll → jelszó dialog → tovább

**Modern javaslat:**
- PIN-kód alapú supervisor auth (nem jelszó gépelés, hanem 4-6 számjegy)
- Biometrikus opció (Windows Hello kompatibilis Electron-ban)
- Supervisor session token: 15 perces érvényes, utána újra auth
- Audit log minden supervisor műveletről

### 11.5 Árfolyam módosítás UX

**Jelenlegi:** `ArfolyamGomb` → ARFVALT.dll / BIGARFVALT.dll / KISARFVALT.dll → supervisor jelszó

**Modern javaslat:**
- Inline árfolyam-szerkesztés a tranzakciós képernyőn (supervisor auth után)
- Változásnapló: mikor, ki, mennyivel módosított
- Szándékos jóváhagyás: "Biztos, hogy 395.50-ről 393.00-re módosítja?"
- Opcionális: piaci árfolyam-lekérés (MNB API) referencia célból

---


---

## S13 12_PRIORITAS_MATRIX_ES_IMPLEMENTACIOS_UTEMTERV

### 12.1 UX problémák prioritás-mátrix

| # | Probléma | Üzleti hatás | Fejlesztési effort | Prioritás |
|---|----------|-------------|-------------------|-----------|
| 1 | Modal-heavy UX → blokkoló folyamatok | MAGAS | MAGAS | P1 |
| 2 | Devizaváltás rejtett a főmenün | MAGAS | ALACSONY | P1 |
| 3 | 18 mező egyszerre → kognitív terhelés | MAGAS | KÖZEPES | P1 |
| 4 | Nincs haladásjelző napzárnál | KÖZEPES | ALACSONY | P1 |
| 5 | Inkonzisztens szín- és font rendszer | KÖZEPES | KÖZEPES | P2 |
| 6 | Abszolút koordináták → nem skálázható | MAGAS | MAGAS | P2 |
| 7 | Nincs keyboard shortcut rendszer | KÖZEPES | ALACSONY | P2 |
| 8 | Ügyfél-azonosítás nem wizard-alapú | KÖZEPES | KÖZEPES | P2 |
| 9 | Nem érthető mezőcímkék (WA1-WA6) | ALACSONY | ALACSONY | P3 |
| 10 | Beágyazott JPEG háttérképek | ALACSONY | ALACSONY | P3 |
| 11 | Nyomtatás: LPT1 közvetlen | MAGAS | MAGAS | P1 |
| 12 | Offline működés hiánya | MAGAS | MAGAS | P1 |

### 12.2 Phased implementáció javaslat

**Fázis 1 — Alap UX (Sprint 1-4):**
- Design token rendszer (színek, tipográfia, spacing)
- Főmenü redesign: devizaváltás prominens helyen
- VASARLAS/ELADAS: dinamikus sor-hozzáadás, árfolyam kiemelés
- Status bar keyboard shortcutok

**Fázis 2 — Flow redesign (Sprint 5-8):**
- Ügyfél-azonosítás wizard komponens
- Napzárás haladásjelző
- Sztornó: grid bővítés (dátum, devizanem, ügyfél oszlopok)
- Bizonylat megjelenítő: keresés mező

**Fázis 3 — Modern UX (Sprint 9-12):**
- Offline-first architektúra
- Supervisor auth PIN/biometria
- Árfolyam inline szerkesztés
- ESC/POS hibrid nyomtatás

**Fázis 4 — Polish és accessibility (Sprint 13-16):**
- WCAG 2.1 AA megfelelőség
- Screen reader support
- Keyboard-only navigáció audit
- Dark mode (opcionális)

---


---

## S14 13_OSSZEFOGLALAS

### 13.1 A legacy rendszer értékelése

Az Anti Valutaváltó rendszer egy **funkcionálisan komplett, üzletileg érett, de vizuálisan és ergonómiailag elavult** Delphi 7 alkalmazás. A 110+ DLL modularitás mesteri mérnöki döntés volt a maga korában — de az ebből fakadó modal-heavy, blokkoló UX ma már nem elfogadható.

**Amit meg kell menteni:**
- A lineáris, logikus tranzakciós workflow (Vétel/Eladás/Sztornó)
- A billentyűzetes, keyboard-first munkamód (End/Escape paradigma)
- A supervisor/pénztáros szerepkör-elválasztás
- A 300k limit kötelező ügyfél-azonosítás vizuális jelzése
- A napzárás lépésenkénti checklist logikája

**Amit el kell hagyni:**
- Abszolút pixel-koordináták → CSS Flexbox/Grid
- 8+ különböző szín- és fontrendszer → design token
- Beágyazott JPEG háttérképek → SVG/CSS
- Modal-pokol → wizard-alapú SPA flow
- XOR "titkosítás" → valódi kriptográfia
- Hardkódolt IP/FTP credentials → environment config
- LPT1 közvetlen nyomtatás → modern printer API réteg

### 13.2 A legkritikusabb DFM-megfigyelések összegzése

1. **VASARLASFORM `AlphaBlendValue=225`** — ez az egyetlen form, amelynek alpha-blend értéke van, de a tesztben ez helyes (225/255 ≈ 88% opák, alig átlátszó)

2. **NAPZARFORM `AlphaBlendValue=180`** — 70% opák; a napzárás képernyő áttetsző, ami lehetővé teszi az alatta lévő tartalom átütközését — ez valószínűleg véletlen konfiguráció, nem szándékos design

3. **PROSBELEP `AlphaBlendValue=200`** — 78% opák login képernyőn; ez biztonsági aggályokat vet fel (az előző session data átütközik)

4. **FOGLALO `Image1` alClient JPEG** — egy tengerpart fotó teljes képernyős háttérként a foglalási modulban; üzleti célra teljesen inkongruens

5. **UGYFELINPUT `VIRAG` TImage Left=-2200** — egy off-screen komponens, valószínűleg egy korábbi háttérkép maradványa — code hygiene probléma

6. **STORNO `Elephant` font** — egy kalandregény-stílusú dekoratív font a pénztári rendszer legkritikusabb (visszavonási) formján

7. **VASARLAS `6324288` vs ELADAS `16756991`** — a két legfontosabb formnak teljesen eltérő háttérszíne van; ez ugyan segíti a megkülönböztetést, de nem rendszertervezett döntés

8. **CIMLETEZES 14×n input mező** — a 14 devizanem × több (legalább 4-6) bankjegy-típus × 2 (bevétel/kiadás) ≈ 100+ mező; ez még a legtapasztaltabb pénztáros számára is rendkívüli kognitív terhelés

9. **BLOKKNYOM `272×56px` form** — egy postage stamp méretű form, ami nyomtatás alatt villan fel; ez elfogadható, de egy modern toast notification elegánsabb megoldás lenne

10. **TRADE főmenü `Stencil` font + NYC háttérkép** — a katonai stencil betűtípus és a New York-i városképes háttérkép teljesen inkongruens egy pénztári rendszer főmenüjéhez

### 13.3 A modern rendszer design garanciái

A Java+React+Electron platformon épülő modern rendszer az alábbi design garanciákat kell teljesítse:

1. **Egy design language** — egyetlen szín-token rendszer, egyetlen fontcsalád, következetes spacing
2. **Keyboard-first** — minden funkció elérhető billentyűzetről, minden shortcut látható a status bar-ban
3. **< 3 kattintás** — bármely főfunkció (vétel, eladás, sztornó) legfeljebb 3 interakcióval kezdeményezhető
4. **Regulatory compliance by design** — a 300k limit, terror szűrés, PEP nyilatkozat vizuálisan kiemelkedő, nem elrejthető
5. **Offline-first** — internet-kiesés esetén a rendszer nem omlik össze, hanem szivárgásmentes módban működik tovább
6. **Auditálható** — minden supervisor művelet, árfolyam-módosítás, sztornó azonnal naplózódik és kereshető
7. **Skálázható** — 1080p, 1440p, 4K képernyőkön egyaránt jól néz ki és használható
8. **Akadálymentes** — WCAG 2.1 AA megfelelőség (főleg a kontrasztarány és a keyboard navigáció)

---

> **Gábor, Design & Graphics Chief** — 2026-04-02
>
> Ez az elemzés a `antivaluta-junior.md` rendszer-áttekintés és az `anti-dfm-pack.md` DFM layout-csomag alapján készült. Minden DFM-hivatkozás az eredeti Delphi 7 forráskódból származó tényleges adatot tükröz. Az ASCII wireframe-ek a koordináta-adatokból rekonstruált becsült layout-ok, nem pixel-pontos reprodukciók.

---


---

## S15 14_KIEGESZITO_WESTERN_UNION_ES_OTP_TERMINAL_UX

### 14.1 Western Union integráció felhasználói élmény (as-is)

A `WUNION` DLL (`TWesternUnionForm`) a WU pénzátutalási szolgáltatást kezeli. Jellemzői a DFM és kódelemzés alapján:

**Jelenlegi flow:**
1. WU menüpont → WUNION.dll ShowModal
2. Küldés vagy fogadás kiválasztása
3. MTCN szám bevitele (fogadásnál)
4. Összeg és devizanem
5. Küldőnél: kedvezményezett neve, ország, összeg
6. WU bizonylat nyomtatás
7. Napzárnál kötelező MTCN ellenőrzés (`MTCNControl`)

**UX problémák:**
- A WU flow teljesen elszigetelt a devizaváltástól — a felhasználó nem látja egyszerre a napi WU és devizaforgalmat
- Az MTCN számok kézi bevitele hibalehetőség (12 karakteres szám)
- Nincs keresés a korábbi WU tranzakciókban a pénztáros képernyőjéről

**Modern javaslat:**

```
┌──────────────────────────────────────────────────────────────────┐
│  WESTERN UNION UTALÁS                        [WU logo]           │
│                                                                  │
│  Típus:  ( ●) Pénz küldés    ( ) Pénz fogadás                   │
│                                                                  │
│  ──── FOGADÁS ESETÉN ────────────────────────────────────────    │
│                                                                  │
│  MTCN szám: [ _ _ _ _ _ _ _ _ _ _ _ _ ]                        │
│              (automatikus formázás: ####-####-####)              │
│                                                                  │
│  [ KERESÉS ▶ ]                                                   │
│                                                                  │
│  Eredmény (WU API visszajelzés):                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Küldő:         JOHN SMITH (USA)                         │   │
│  │  Összeg:        USD 500.00                               │   │
│  │  HUF egyenérték: 194 750 Ft (395.50 árfolyamon)         │   │
│  │  Állapot:       ✓ Fizethető                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Kedvezményezett neve: [______________________]                  │
│  Okmányszám:           [______________________]                  │
│                                                                  │
│         [ KIFIZETÉS ✓ ]              [ MÉGSE ✗ ]                │
└──────────────────────────────────────────────────────────────────┘
```

**Javítások:**
- MTCN szám automatikus formázása (4-4-4 blokkok) → kevesebb begépelési hiba
- WU API azonnali visszajelzés (nem szükséges külön lépés)
- Kedvezményezett adatai kitöltve az API válaszból (ha elérhető)

### 14.2 OTP terminál integráció UX

Az `OTP` DLL (`TOTPTERM`) az OTP POS terminál integrációját kezeli. A rendszer `OtpTermStorno` és `OtpAruVisszavet` eljárásokkal is rendelkezik — ezek a kártyás tranzakciók sztornójához szükségesek.

**UX kihívás:** A POS terminál fizikailag különálló eszköz, de logikailag a szoftverrel szinkronban kell lennie. Ha a terminál "elfogad", de a szoftver "elutasít" (pl. Firebird írás hiba), inkonzisztens állapot keletkezik.

**Modern javaslat:**
- POS terminál státusz-indikátor a status bar-ban (zöld: online, piros: offline)
- Sikeres kártyás tranzakció után automatikus bizonylat-rögzítés (nem kézi)
- Inkonzisztencia esetén automatikus sztornó-ajánlat

```
[●  OTP Terminál: ONLINE]   [Utolsó tranzakció: 09:15 — 45 200 Ft — ELFOGADVA]
```

---


---

## S16 15_KIEGESZITO_BIZONYLAT_FORMATUMOK_VIZUALIS_TERVEZESE

### 15.1 A jelenlegi blokknyomtató bizonylat struktúra

A `TBlokkNyom` modul 39 karakteres sorokba rendezi a tartalmat. Rekonstruált fejléc:

```
---------------------------------------
Kupon Portfolio es Kereskedelmi Kft.
  2161 Csomad, Liget utca 40.
       12896127-2-44

    EXCLUSIVE BEST CHANGE ZRT.

    [Pénztár neve]
    [Pénztár címe]

Adoszam       : 32313332-2-02
Terminal ID   : A1B2
Bizonylatszam : 00123456

NUSZ call center: +36 1-587-500
---------------------------------------
DEVIZAVASARLAS BIZONYLATJA
Datum: 2026.04.02.    Ido: 09:15:33
Penztaros: KOVACS ANNA

Devizanem    : EUR
Osszeg       :      320.00 EUR
Arfolyam     :      395.50
Fizetendo    :  126 560 Ft
Kezeles dij  :      500 Ft
Netto        :  126 060 Ft

Ugyfelnev    : KISS BELA
Szul.datum   : 1965.03.12
Okmanyszam   : 123456AB

      Penztar alairasa:

      ________________

      Ugyfel alairasa:

      ________________
---------------------------------------
```

**Elemzés:**
- 39 karakteres sor = a klasszikus 80mm thermal nyomtató formátuma
- Nincs grafikus elem (csak szöveges)
- ESC/POS parancsokkal félkövér és dupla-szélesség formázás
- Magyar ékezetes karakterek problémásak (WIN1250 → ESC/POS kódlap fordítás)

### 15.2 Modern bizonylat design javaslat

A modern rendszerben a bizonylat HTML/CSS template-en alapuljon, amelyet runtime konvertál ESC/POS-ra:

```
┌───────────────────────────────────────────┐
│                                           │
│         EXCLUSIVE BEST CHANGE ZRT.        │
│                                           │
│  ════════════════════════════════════    │
│  DEVIZAVÁSÁRLÁS BIZONYLATA               │
│  ════════════════════════════════════    │
│                                           │
│  Dátum:       2026.04.02.                │
│  Idő:         09:15:33                   │
│  Bizonylat:   00123456                   │
│  Terminál:    A1B2                       │
│  Pénztáros:   KOVÁCS ANNA                │
│                                           │
│  ──────────────────────────────────────  │
│  TRANZAKCIÓ                              │
│  ──────────────────────────────────────  │
│  Devizanem:   EUR (euró)                 │
│  Összeg:               320.00 EUR        │
│  Árfolyam:             395.50 Ft/EUR     │
│  Fizetendő:        126 560 Ft            │
│  Kezelési díj:          500 Ft           │
│  Nettó kifizetés:   126 060 Ft           │
│                                           │
│  ──────────────────────────────────────  │
│  ÜGYFÉL ADATAI                           │
│  ──────────────────────────────────────  │
│  Név:         KISS BÉLA                  │
│  Születési d: 1965.03.12.                │
│  Okmányazon:  123456AB                   │
│  Állampolgár: Magyar                     │
│                                           │
│  Adószám (EBC): 32313332-2-02            │
│  Pénztár:       PÉCS-01                  │
│  NUSZ: +36 1 587-500                     │
│                                           │
│  Pénztáros aláírása:  . . . . . . .      │
│  Ügyfél aláírása:     . . . . . . .      │
│                                           │
│  Ez a bizonylat 2 példányban készült.    │
│  ÁFA mentes (Pénzügyi szolgáltatás)      │
│                                           │
└───────────────────────────────────────────┘
```

### 15.3 E-matrica bizonylat modern verziója

Az eredeti `MatricaSellerCopy` és `MatricaCustomerCopy` kétnyelvű (magyar + angol) formátumának megtartása kötelező, de a formázás javítható:

```
┌───────────────────────────────────────────┐
│  e-matrica ellenőrző szelvény             │
│  e-vignette control slip                  │
│  ════════════════════════════════════    │
│                                           │
│  ELADÓI / SELLER'S COPY                  │
│  Nem adóügyi bizonylat / Non-tax doc.     │
│                                           │
│  Vásárlás / Purchase: 2026.04.02. 09:22  │
│  Rendszám / Plate:    ABC-123            │
│  Ország / Country:    HU                 │
│  Kategória / Cat.:    D1 (személyautó)   │
│  Típus / Type:        éves / annual      │
│  Érvényesség / Valid: 2026.04.01-2027.03.31│
│  Ár / Price:          50 140 Ft          │
│                                           │
│  Matricaazonosító:    VIG-2026-123456789  │
│  Termék ID:           HU-D1-2026-ANN     │
│                                           │
│  ⓘ  30 perces módosítási lehetőség       │
│     Az okmányt 2 évig megőrizni!          │
│                                           │
│  Ügyfél aláírása:     . . . . . . .      │
└───────────────────────────────────────────┘
```

---


---

## S17 16_KIEGESZITO_ACCESSIBILITY_ES_WCAG_MEGFELELOSEG

### 16.1 Jelenlegi accessibility állapot

A Delphi 7 Win32 rendszer accessibility szempontból:
- **Screen reader:** Microsoft Active Accessibility (MSAA) minimális szintű, TControl alapú automatikus
- **Keyboard navigation:** Tab sorrend nem dokumentált, de Win32 natívan kezel alapszintű Tab-ot
- **Colour contrast:** A DFM-ekben mért kontrast-arányok:
  - `clYellow` szöveg `clBlack` háttéren: ~19:1 ✓ (kiváló)
  - `clYellow` szöveg `clGray` háttéren: ~5.2:1 ✓ (AA megfelelő)
  - `clWhite` szöveg `clTeal` háttéren: ~4.6:1 ✓ (AA megfelelő)
  - `clNavy` szöveg `16756991` (halvány kék) háttéren: ~8.1:1 ✓ (AA megfelelő)
  - `clSilver` árnyék szöveg bármilyen háttéren: nagyon alacsony kontraszt ✗

### 16.2 WCAG 2.1 AA követelmények a modern rendszerben

| Kritérium | Kategória | Modern rendszer implementáció |
|-----------|-----------|------------------------------|
| 1.1.1 Non-text content | A | Minden ikon alt szöveggel |
| 1.3.1 Info and relationships | A | Szemantikus HTML (label, fieldset) |
| 1.4.3 Contrast (minimum) | AA | 4.5:1 normál szöveg, 3:1 nagy szöveg |
| 1.4.4 Resize text | AA | 200%-ig skálázható layout-törés nélkül |
| 2.1.1 Keyboard | A | Minden funkció billentyűzetről elérhető |
| 2.1.2 No keyboard trap | A | Minden modal Escape-pel bezárható |
| 2.4.3 Focus order | A | Logikus Tab sorrend minden formon |
| 2.4.6 Headings and labels | AA | Leíró mezőcímkék (nem WA1-WA6) |
| 3.3.1 Error identification | A | Valós idejű validáció és hibaüzenet |
| 3.3.2 Labels or instructions | A | Minden mező mellé instrukció |
| 4.1.2 Name, role, value | A | ARIA szerepkörök ahol szükséges |

### 16.3 Kritikus accessibility problémák a DFM-ekben

**Shape-alapú layout → nem hozzáférhető:**
A Delphi `TShape` komponensek vizuális elemek, nem interaktív UI elemek. Ha a layout megjelenítéséhez `TShape` kell (pl. keretek, panelek), azok nem rendelkeznek MSAA megfelelőként, és screen reader-ek számára láthatatlanok.

**Megoldás a modern rendszerben:**
- React komponensek natívan ARIA-kompatibilisek
- Minden `<input>` mező `<label>` párral
- Minden `<button>` önleíró `aria-label`-lel
- Dialog modalok `role="dialog"` és `aria-modal="true"` attribútummal

---


---

## S18 17_KIEGESZITO_MOBIL_ES_ERINTOKEPERNYOS_UX_MEGFONTOLASOK

### 17.1 Jelenlegi rendszer touch-kompatibilitása

Az Anti Valutaváltó rendszer kizárólag egér + billentyűzet interakcióra tervezett. Érintőképernyős eszközön:
- A 25px magas gombok (SUPERTSK) érintővel használhatatlanok
- A TDBGrid kétujjas görgetése nem működik Win32-ben
- Az abszolút pozicionált elemek 4K érintőképernyőn eltörnek

### 17.2 Electron + React érintőképernyős lehetőségek

Az Electron alkalmazás futhat Windows érintőképernyős kioszkon is. Ez lehetővé teszi:
- Tabletes pénztár (pl. iPad Pro + keyboard case)
- Ügyfél-felé fordított érintőképernyős panel
- Remote access (VPN-en keresztüli tablet kapcsolat)

**Minimum touch target méretek:**
- Apple HIG: 44×44pt minimum
- Google Material: 48×48dp minimum
- WCAG 2.5.5 (AAA): 44×44 CSS pixel minimum
- **Javasolt:** 48×48px minden interaktív elem

### 17.3 Érintőképernyős bizonylat-aláírás

Az ügyfél-aláíráshoz jelenleg papír bizonylatot nyomtat és fizikailag aláíratja. Modern alternatíva:

```
┌──────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL ALÁÍRÁSA                                                 │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │                                                            │  │
│  │         [aláírási terület — érintőképernyőn]               │  │
│  │                                                            │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  [ TÖRLÉS ]                             [ ELFOGADOM ✓ ]         │
└──────────────────────────────────────────────────────────────────┘
```

Az elektronikus aláírás JPEG/PNG formátumban menthető a bizonylat adatai mellé az adatbázisba.

**Megjegyzés:** Jogszabályi ellenőrzés szükséges, hogy az elektronikus aláírás elegendő-e a vonatkozó (Kúria, NAV) előírásoknak.

---


---

## S19 18_KIEGESZITO_ADATMEGJELENITESI_MINTAK_ES_TABLAZATOK

### 18.1 Napi forgalom összesítő modern layout

A `TNAPIFORGALOMFORM` (NAPIFORG DLL) a napi devizaforgalmat összesíti. Modern verziója:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  NAPI FORGALOM ÖSSZESÍTŐ — 2026.04.02.                         [PÉCS-01 pénztár]   │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │ DEVIZA  │ NYITÓKÉSZLET │  VÁSÁROLT  │    ELADOTT  │  EGYÉB     │ ZÁRÓKÉSZLET  │  │
│  │─────────┼──────────────┼────────────┼─────────────┼────────────┼──────────────│  │
│  │ EUR     │   5 000.00   │ +1 280.00  │  -  840.00  │     0.00   │   5 440.00   │  │
│  │ USD     │   2 000.00   │ +  350.00  │  -  200.00  │     0.00   │   2 150.00   │  │
│  │ GBP     │   1 000.00   │ +  100.00  │  -   50.00  │     0.00   │   1 050.00   │  │
│  │ CHF     │     800.00   │      0.00  │  -  100.00  │     0.00   │     700.00   │  │
│  │ CZK     │  50 000.00   │ +5 000.00  │      0.00   │     0.00   │  55 000.00   │  │
│  │ PLN     │   3 000.00   │ +  500.00  │  -  300.00  │     0.00   │   3 200.00   │  │
│  └─────────┴──────────────┴────────────┴─────────────┴────────────┴──────────────┘  │
│                                                                                      │
│  FORINT FORGALOM:                                                                    │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Vásárolt devizáért fizetett:    1 850 630 Ft                                  │  │
│  │  Eladott devizáért kapott:         942 180 Ft                                  │  │
│  │  Kezelési díj bevétel:              12 500 Ft                                  │  │
│  │  Nettó pénztárhatás:             +  920 950 Ft  (vásárlás > eladás)            │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  [ Nyomtatás ]    [ Excel export ]    [ PDF mentés ]    [ Bezárás ]                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 18.2 Bizonylat keresési képernyő bővített verziója

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  BIZONYLAT KERESŐ                                                                    │
│                                                                                      │
│  ╔═ SZŰRŐK ═══════════════════════════════════════════════════════════════════════╗  │
│  ║                                                                               ║  │
│  ║  Dátum:  [ 2026.04.01 ]  –  [ 2026.04.02 ]    Típus:  [ Minden ▼ ]           ║  │
│  ║  Deviza: [ Minden ▼ ]     Pénztáros: [ Minden ▼ ]                             ║  │
│  ║  Ügyfél: [________________________________]     Összeg min/max: [____] – [____]║  │
│  ║                                                                               ║  │
│  ║              [ KERESÉS ▶ ]    [ Szűrők törlése ]                              ║  │
│  ╚═══════════════════════════════════════════════════════════════════════════════╝  │
│                                                                                      │
│  Találatok: 47 bizonylat                                                            │
│                                                                                      │
│  ┌────────────┬──────────┬────────────┬──────────┬──────────┬──────────┬──────────┐ │
│  │ BIZONYLAT  │ DÁTUM    │    IDŐ     │ TÍPUS    │ DEVIZA   │  ÖSSZEG  │ÜGYFÉL    │ │
│  ├────────────┼──────────┼────────────┼──────────┼──────────┼──────────┼──────────┤ │
│  │ 00123456   │ 04.02.   │ 09:15      │ VÉTEL    │ EUR      │ 126 560  │KISS BÉLA │ │
│  │ 00123457   │ 04.02.   │ 10:22      │ ELADÁS   │ USD      │  45 200  │ —        │ │
│  │ 00123458   │ 04.02.   │ 11:05      │ VÉTEL    │ GBP      │ 201 300  │NAGY MÁRIA│ │
│  │ 00123459   │ 04.02.   │ 11:47      │ WU FOG.  │ USD      │  82 400  │TÓTH PÉTر│ │
│  └────────────┴──────────┴────────────┴──────────┴──────────┴──────────┴──────────┘ │
│                                                                                      │
│  [◀ Előző]   Oldal 1 / 3   [Következő ▶]         [ Export ]   [ Nyomtatás ]        │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---


---

## S20 19_KIEGESZITO_VERZIOKOVETES_ES_AUDIT_TRAIL_UX

### 19.1 Jelenlegi napló rendszer

A legacy rendszer XOR-kódolt naplófájlokat (`TRADELOG\`) és a `LOGDISP.dll` megjelenítőt használja. A naplózás esemény-szintű, de nem kereshető és nem exportálható közvetlenül.

### 19.2 Modern audit trail UX javaslat

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  RENDSZERNAPLÓ ÉS AUDIT TRAIL                                                        │
│                                                                                      │
│  Keresés: [_______________________]   Szint: [Minden ▼]   Dátum: [Ma ▼]            │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  IDŐ     │ SZINT     │ ESEMÉNY                            │ FELHASZNÁLÓ        │  │
│  │──────────┼───────────┼────────────────────────────────────┼────────────────────│  │
│  │ 09:00:12 │ INFO      │ Pénztár nyitás — KOVÁCS ANNA       │ KOVÁCS ANNA        │  │
│  │ 09:15:33 │ INFO      │ Devizavétel — 320 EUR, 126 560 Ft  │ KOVÁCS ANNA        │  │
│  │ 09:15:35 │ INFO      │ Bizonylat nyomtatva: 00123456      │ KOVÁCS ANNA        │  │
│  │ 10:05:11 │ WARN      │ Árfolyam módosítás: EUR 395.50→393 │ SUPERVISOR         │  │
│  │ 11:22:44 │ INFO      │ Devizavétel — 500 USD, 201 300 Ft  │ KOVÁCS ANNA        │  │
│  │ 11:47:09 │ WARN      │ AML küszöb átlépve — 318 000 Ft    │ KOVÁCS ANNA        │  │
│  │ 11:47:22 │ INFO      │ Ügyfél azonosítás rögzítve         │ KOVÁCS ANNA        │  │
│  │ 13:30:01 │ ERROR     │ WU API kapcsolat megszakadt         │ RENDSZER           │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  [ CSV export ]   [ PDF export ]   [ E-mail küldés ]   [ Bezárás ]                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 19.3 Változáskövetés az árfolyamoknál

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  ÁRFOLYAM MÓDOSÍTÁSOK — 2026.04.02.                                                 │
│                                                                                      │
│  ┌──────────┬──────────┬───────────┬───────────┬────────────┬─────────────────────┐ │
│  │ IDŐ      │ DEVIZA   │ ELŐZŐ VÉT.│ ÚJ VÉTELI │ SUPERVISOR │ INDOKLÁS            │ │
│  ├──────────┼──────────┼───────────┼───────────┼────────────┼─────────────────────┤ │
│  │ 08:30:00 │ EUR      │   393.00  │   395.50  │ NAGY PÉTER │ MNB reggeli árfolyam│ │
│  │ 10:05:11 │ EUR      │   395.50  │   393.00  │ NAGY PÉTER │ Piaci korrekcó      │ │
│  │ 14:00:00 │ USD      │   362.00  │   364.50  │ NAGY PÉTER │ Délutáni frissítés  │ │
│  └──────────┴──────────┴───────────┴───────────┴────────────┴─────────────────────┘ │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---


---

## S21 20_KIEGESZITO_DESIGN_QA_ELLENORZOLISTA_A_MIGRACIOHOZ

Az alábbi ellenőrzőlista minden egyes React komponens implementálásakor alkalmazandó:

### 20.1 Vizuális ellenőrzőlista

- [ ] A komponens design token-eket használ (nem hardkódolt hex értékeket)
- [ ] A szövegek Inter fontban jelennek meg, nem rendszer-default fontban
- [ ] A kontrasztarány WCAG AA szintet teljesít (minimum 4.5:1 normál szövegnél)
- [ ] A komponens 1080p, 1440p és 4K felbontáson egyaránt tesztelt
- [ ] A komponens 125% és 150% Windows kijelzőméret-skálánál is helyes
- [ ] A hover és focus állapotok vizuálisan megkülönböztethetők
- [ ] Az aktív/inaktív állapotok vizuálisan megkülönböztethetők
- [ ] A hibás állapot (validation error) vizuálisan egyértelmű (nem csak piros szín)

### 20.2 Interakciós ellenőrzőlista

- [ ] Minden gomb elérhető Tab-bal és Enter/Space-szel
- [ ] Minden dropdown/select navigálható nyíl billentyűkkel
- [ ] Minden modal bezárható Escape-pel
- [ ] A fókusz-sorrend logikus (balról jobbra, fentről lefele)
- [ ] A fókusz nem "szökik meg" modálok mögé (focus trap implementálva)
- [ ] Gyors gépelők számára: Enter az aktuális mezőből továbblép (nem submit-ol)

### 20.3 Üzleti logika ellenőrzőlista

- [ ] Az árfolyam feltűnően látható a tranzakciós képernyőn
- [ ] A 300 000 Ft-os AML küszöb vizuális figyelmeztetés
- [ ] A napzárás előrehaladása mindig látható (progress indicator)
- [ ] A sztornó dupla megerősítést kér (és az inaktív gomb nem kattintható véletlenül)
- [ ] Az ügyfél-azonosítás kötelező mezői be nem töltéskor nem enged továbblépni
- [ ] A bizonylat nyomtatás meghiúsulása esetén egyértelmű hibaüzenet és újrapróbálási lehetőség

### 20.4 Adatvédelmi ellenőrzőlista

- [ ] Az ügyfél személyes adatai csak a szükséges ideig jelennek meg a képernyőn
- [ ] A pénztáros-váltáskor az előző session adatai nem láthatók (nem átlátszó login képernyő)
- [ ] A bizonylat részletei csak jogosult pénztárosoknak láthatók
- [ ] Az exportált fájlok (CSV, PDF) jelszóvédhetők

---


---

## S22 21_KIEGESZITO_RESZLETES_KOMPONENS_SPEC

### 21.1 TransactionAmountDisplay komponens spec

```
Komponens: TransactionAmountDisplay
Props:
  - amount: number           // forint összeg
  - currency: string         // devizanem (pl. "EUR")
  - rate: number             // árfolyam
  - fee: number              // kezelési díj
  - transactionType: 'buy' | 'sell'
  
Megjelenítés:
  - Háttér: transactionType === 'buy' ? --color-buy-light : --color-sell-light
  - Főösszeg: --text-display (48px), --font-bold
  - Mellékletek: --text-sm, --color-text-secondary
  
States:
  - idle: alapállapot
  - calculating: spinner (ha async számítás folyik)
  - warning: ha közel van a 300k limithez (sárga keret)
  - limit-exceeded: ha átlépi a limitet (piros banner)
```

### 21.2 CurrencySelector komponens spec

```
Komponens: CurrencySelector
Props:
  - availableCurrencies: Currency[]    // [{code: 'EUR', name: 'euró', flag: '🇪🇺'}]
  - selectedCurrency: string
  - buyRate: number
  - sellRate: number
  - onSelect: (currency: string) => void
  
Megjelenítés:
  - Grid layout: 4 oszlop, automatikus törés
  - Minden deviza-kártya: 80×60px minimum (touch-compatible)
  - Kiválasztott: --color-primary-light keret, pipa ikon
  - Árfolyam: a kiválasztott deviza alatt azonnal látható

States:
  - default: normál lista
  - selected: kiemelés
  - rate-changed: sárga villanás (ha az árfolyam megváltozott az utolsó 5 percben)
```

### 21.3 DenominationInput komponens spec

```
Komponens: DenominationInput
Props:
  - currency: string
  - denominations: number[]    // [500, 200, 100, 50, 20, 10, 5, 1]
  - onChange: (lines: DenomLine[]) => void

DenomLine:
  - denomination: number    // bankjegy értéke
  - count: number           // darabszám
  - subtotal: number        // számított összrészeg

Megjelenítés:
  - Dinamikus sorok: kezdetben 1-2 sor, "+" gombbal bővíthető
  - Darabszám mező: numeric keyboard, auto-fokusz
  - Részösszeg: automatikusan számolja
  - Összesen sor: vizuálisan kiemelve (bold, larger text)
  
Shortcut:
  - Tab: következő sor darabszám mezőjére ugrik
  - Enter: sor lezárása és következő sor megnyitása
  - Delete: aktuális sor törlése
```

---


---

## S23 22_OSSZEFOGLALAS_ES_ZARO_GONDOLATOK

### 22.1 A legacy rendszer értékelése egyetlen mondatban

Az Anti Valutaváltó Delphi 7 rendszer **funkcionálisan korrekt, jogilag megfelelő, de ergonómiailag és vizuálisan elavult** — és migrációja nem egyszerű "újrafestés", hanem mélyreható UX-átgondolás.

### 22.2 A három legfontosabb UX befektetés

1. **Egységes design language bevezetése** — ez az összes többi UX-problémát részben megoldja, és minimális üzleti kockázattal jár
2. **Devizaváltás prominens helyre emelése a főmenüben** — ez azonnali, mérhető pénztárosi hatékonysági javulást hoz
3. **Napzárás haladásjelző** — a pénztáros stresszpontja jelenleg a "mi történik most?" bizonytalanság; egy progress indicator ezt feloldja

### 22.3 A migráció nem-céljai

- **Nem cél** a bizonylat-formátumok megváltoztatása (jogszabályi kötöttség)
- **Nem cél** az összes DFM-ben lévő vizuális "karakter" eltüntetése (néhány öröklött vizuális elem ismerős a régi felhasználóknak)
- **Nem cél** a touch-first redesign (a pénztáros billentyűzettel dolgozik — de legyen touch-compat)
- **Nem cél** a supervisor workflow gyökeres átírása (a jelszavas védelem üzleti igény, csak a UX-a modernizálható)

### 22.4 Zárszó

A Delphi 7 rendszer 15-20 éves örökség — és ez a kor nemcsak a kódban, hanem a UX döntésekben is látszik. A `Elephant` font a sztornó fejlécen, a New York-i látóképes foglalás-háttér, a VIRAG nevű off-screen TImage, a 96 pontos "ELADÁS" cím — ezek mind egy korszak lenyomatai.

Az új React+Electron rendszer megörökli a munkavégzési kultúrát (billentyűzetes, gyors, professzionális), de felváltja a vizuális döntéseket egy egységes, hozzáférhető, skálázható design language-dzsel.

A cél: az Exclusive Best Change pénztárosa **azonnal otthon érezze magát** az új rendszerben — mert az ismerős billentyűzetes workflow megmaradt —, miközben **objektíve gyorsabb és megbízhatóbb** legyen a napi munkája.

---

> **Gábor, Design & Graphics Chief** — 2026-04-02
>
> Ez az elemzés a `antivaluta-junior.md` rendszer-áttekintés és az `anti-dfm-pack.md` DFM layout-csomag alapján készült. Minden DFM-hivatkozás az eredeti Delphi 7 forráskódból származó tényleges adatot tükröz. Az ASCII wireframe-ek a koordináta-adatokból rekonstruált becsült layout-ok, nem pixel-pontos reprodukciók.

[TASK_COMPLETE]
