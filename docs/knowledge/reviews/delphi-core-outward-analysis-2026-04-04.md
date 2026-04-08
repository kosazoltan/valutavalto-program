---
type: analysis
scope: workspace-shared
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Valutavalto Delphi — Core-bol Kifele Elemzes (2026-04-04)"
load: on-demand
---

# Valutaváltó Delphi — Core-ból Kifelé Elemzés (2026-04-04)

> **Elemző:** Eszter (Controller Chief)
> **Megrendelő:** Zoltán — üzleti prioritás alapú újraelemzés
> **Forrás:** `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\`
> **Referencia:** Junior core-analysis (2026-04-04), Eszter delphi-full-analysis (2026-04-04)
> **Delphi verzió:** Delphi 7 (Borland), Object Pascal
> **Adatbázis:** Firebird (InterBase), WIN1250 kódolás
> **Teljes forrásbázis:** ~645.000 Pascal sor, 1102 .pas, 4 rendszer

---


---

## S1 TARTALOMJEGYZEK

1. [Zoltán Üzleti Prioritásai — Ring Modell](#1-zoltán-üzleti-prioritásai--ring-modell)
2. [P0 — MAG: Pénztári Valutaváltás](#2-p0--mag-pénztári-valutaváltás)
3. [P0 — MAG: Értéktári Logika](#3-p0--mag-értéktári-logika)
4. [P0 — MAG: Főértéktári Árfolyamkészítés](#4-p0--mag-főértéktári-árfolyamkészítés)
5. [P1 — RING 1: Pénztárak Közti Átadás/Átvétel, Készletezés](#5-p1--ring-1-pénztárak-közti-átadásátvétel-készletezés)
6. [P2 — RING 2: Értéktár↔Pénztár, Értéktár↔Bank Mozgások](#6-p2--ring-2-értéktárpénztár-értéktárbank-mozgások)
7. [P3 — RING 3: Szerver Adattárolás, Adminisztráció, Belső Ellenőrzés](#7-p3--ring-3-szerver-adattárolás-adminisztráció-belső-ellenőrzés)
8. [Szerver Modulok: CORE vs. Periphery Besorolás](#8-szerver-modulok-core-vs-periphery-besorolás)
9. [Adatbázis Séma Összesítés](#9-adatbázis-séma-összesítés)
10. [Üzleti Szabályok Teljes Katalógusa](#10-üzleti-szabályok-teljes-katalógusa)
11. [Compliance és Jogszabályi Követelmények](#11-compliance-és-jogszabályi-követelmények)
12. [Migrációs Kockázatmátrix](#12-migrációs-kockázatmátrix)
13. [Összefoglalás és Javaslatok](#13-összefoglalás-és-javaslatok)

---


---

## S2 1_ZOLTAN_UZLETI_PRIORITASAI_RING_MODELL

```
                    ┌─────────────────────────────────────────┐
                    │            P3 — RING 3                  │
                    │  Szerver adattárolás, adatkezelés,      │
                    │  főértéktár belső ellenőrzés, admin     │
                    │                                         │
                    │   ┌─────────────────────────────────┐   │
                    │   │         P2 — RING 2             │   │
                    │   │  Értéktár↔Pénztár átadás        │   │
                    │   │  Értéktár↔Bank átadás           │   │
                    │   │                                 │   │
                    │   │   ┌─────────────────────────┐   │   │
                    │   │   │      P1 — RING 1        │   │   │
                    │   │   │  Pénztárak közti         │   │   │
                    │   │   │  átadás/átvétel          │   │   │
                    │   │   │  Készletezés             │   │   │
                    │   │   │                         │   │   │
                    │   │   │   ┌─────────────────┐   │   │   │
                    │   │   │   │   P0 — MAG      │   │   │   │
                    │   │   │   │                 │   │   │   │
                    │   │   │   │ Valutaváltás    │   │   │   │
                    │   │   │   │ (vétel/eladás)  │   │   │   │
                    │   │   │   │ Értéktár        │   │   │   │
                    │   │   │   │ Árfolyamkészítés│   │   │   │
                    │   │   │   └─────────────────┘   │   │   │
                    │   │   └─────────────────────────┘   │   │
                    │   └─────────────────────────────────┘   │
                    └─────────────────────────────────────────┘
```

**Zoltán szó szerinti prioritásai:**
1. **MAG** = pénztári valutaváltás (vétel/eladás), értéktár, főértéktári árfolyamkészítés
2. **RING 1** = pénztárak közti átadás/átvétel, készletezés
3. **RING 2** = értéktár↔pénztár átadás/átvétel, értéktár↔bank átadás/átvétel
4. **RING 3** = szerver adattárolás, adatkezelés, főértéktár és belső ellenőrzés, adminisztráció

**Alaptétel:** A pénztári program **minden adat forrása** — eköré épül az értéktár, a főértéktár, és mögé a szerver.

---


---

## S3 2_P0_MAG_PENZTARI_VALUTAVALTAS

### 2.1 Rendszerarchitektúra — A MAG Elhelyezkedése

A pénztári program (`IBVALTO.exe`) a **VALUTA** rendszer. Ez a fizikai pénztárgépen fut, ez az adatok eredeti forrása. Minden egyéb rendszer (értéktár, szerver) ebből merít.

```
VALUTA (ibvalto.exe) — 109 DLL, 261K sor
├── VASARLAS (Unit2.pas — 104K, ~3100 sor) ← CORE VÉTEL
├── ELADAS (Unit2.pas — 137K, ~4100 sor)   ← CORE ELADÁS
├── STORNO (Unit2.pas — 36K, ~1100 sor)    ← VISSZAVONÁS
├── NAPZAR (Unit2.pas — 45K, ~1600 sor)    ← NAPI ZÁRAS
├── CIMLET (5 DLL)                         ← CÍMLETEZÉS
├── BIZODISP + BLOKNYOM + GETNYUGT         ← BIZONYLAT
├── BIGCTRL.DLL                            ← 300K+ KONTROL
└── ... (további 90+ DLL)
```

### 2.2 Vásárlás — Deviza Vétel az Ügyféltől

**Fájl:** `VALUTA\VASARLAS\Unit2.pas` (104K, ~3100 sor)
**Osztály:** `TVasarlasForm`

#### 2.2.1 Adatbázis Kapcsolatok

| Kapcsolat | Cél | Firebird DB |
|-----------|-----|-------------|
| `ValutaDbase` | Helyi pénztári DB | `c:\valuta\{lokális}.fdb` |
| `RemoteDbase` | Szerver oldali DB | irodai szintű FDB |
| `TetDbase` | Tétel DB | bizonylat tételek |
| `TempDbase` | Ideiglenes DB | munkaterület |

#### 2.2.2 Core Workflow

```
1. FormActivate → AlapadatBeolvasas
   └── VTEMP tábla nullázás
   └── HARDWARE, PENZTAR, ARFOLYAM táblák beolvasás
2. Pénztáros kiválaszt devizanemet (DnemKeyDown)
   └── Devizanem adatok betöltése (árfolyam, készlet, név)
3. Bankjegy összeg bevitel (BankjegyKeyDown)
   └── Soronkénti számítás
4. Forintérték számítás (CORE KÉPLET)
5. SorbeirasVtempbe → VTEMP INSERT
6. FizetendoDisplay → Nettó/bruttó/díj/kerekítés
7. Bizonylat → nyomtatás → könyvelés
```

#### 2.2.3 CORE KÉPLET: Forintérték Számítás

```pascal
// Alap forintérték képlet:
_aktErtek := round((_aktArfolyam / 100 * _aktBankjegy) + _rounder);

// JPY speciális eset (1000 egységre normalizált):
if _aktDnem = 'JPY' then _aktErtek := round(_aktErtek / 10);

// Kerekítési konstans:
_rounder = 0.001
```

**Üzleti szabály:** Az árfolyam **100 egységre** van megadva (fillér pontosságú). A JPY 1000-es egységben kezelt, ezért plusz osztás 10-zel.

#### 2.2.4 CORE KÉPLET: Fizetendő Számítás

```pascal
// Vétel (vásárlás) esetén:
_netto := SUM(tételek forintértéke)
_origkezdij := GetKezelesidij(_netto)     // kezelési díj
_brutto := _netto - _kezelesidij          // VÁSÁRLÁSNÁL: MÍNUSZ
_fizetendo := Kerekito(_brutto)           // 5 Ft-ra kerekítés
_kerekites := _fizetendo - _brutto        // kerekítési különbözet
```

#### 2.2.5 CORE KÉPLET: Kezelési Díj Logika (`GetKezelesidij`)

A kezelési díj háromféle módban működhet:

| Mód | Feltétel | Képlet |
|-----|----------|--------|
| **Nincs díj** | `_realEzrelek = 0` | díj = 0 |
| **Ezrelékes** | `_realEzrelek > 0` | `díj = trunc(nettó × ezrelék / 1000)`, max `_kezdijmax` |
| **Sávos** | `_realEzrelek = -1` | Tranzakciósáv-táblázatból: `_tranzsav[n]` → `_kdij[n]` |

**Speciális esetek:**
- Konverziónál: díj = 0
- EUR érme akciónál: díj = 0

**DB táblák:**
- `KEZELESIDATA` — kezelési díj konfiguráció
- `TRANZDIJTABLA` — tranzakciós díj sávok (sávos mód esetén)

#### 2.2.6 Kedvezmény Rendszer

| Kedvezmény típus | Mechanizmus | Korlát |
|------------------|-------------|--------|
| Árfolyam kedvezmény | `ArfolyamotModosit` — engedélyező kijelölés | Supervisor jóváhagyás |
| Kezelési díj engedmény | `KezdijEngedmenyGomb` — fix felülírás | — |
| Saját hatáskörű (SHK) | `HARDWARE.SAJATHATASKORU` számláló | Max 5/nap/pénztáros |
| Kis árfolyam kedvezmény | `kisarfolyamkedvezmeny` DLL | DLL hívás |
| Nagy árfolyam kedvezmény | `bigarfolyamkedvezmeny` DLL | DLL hívás |

**SHK szabály:** Maximum 5 saját hatáskörű kedvezmény naponta pénztárosonként. A `HARDWARE.SAJATHATASKORU` mezőben számolja. Napi záráskor nullázódik.

#### 2.2.7 Bizonylat Rendszer

```
GetBizonylatSzam → HARDWARE táblából egyedi sorszám
BlokkFejIro + BlokktetelIro → nyomtatás (bloknyom.dll)
Bizregiszter → INSERT INTO bizonylat tábla
MakeXml → XML bizonylat (NAV felé)
QrKodLerendezes → QR kód generálás
```

**Bizonylat mezők (jogszabályból):**
- SORSZAM — egyedi bizonylatszám
- LAKCIM — ügyfél címe (300K+ felett kötelező)
- OKMANYTIP — okmány típusa
- DATUM, IDO — időbélyeg
- FORINTERTEK — forint értéke a tranzakciónak

#### 2.2.8 Ügyfél Azonosítás (AML/KYC)

```
300.000 Ft felett → ügyfél azonosítás KÖTELEZŐ (Pmt. törvény)
├── KisugyfelLerendezes → kisügyfél tranzakció összeg frissítés szerveren
├── RemoteLerendezes → nagyügyfél adatok szerverre
├── RemoteJogiLerendezes → jogi személyek
└── BIGCTRL.DLL → nagy összegű tranzakció kontrol
```

**DB tábla:** `UGYFEL.NAPIGONGYOLTFORINT` — napi limit, zárásnál nullázódik.

### 2.3 Eladás — Deviza Eladás az Ügyfélnek

**Fájl:** `VALUTA\ELADAS\Unit2.pas` (137K, ~4100 sor)

Tükrözött logika a vásárláshoz képest:

```pascal
// Eladás esetén:
_brutto := _netto + _kezelesiDij   // ELADÁSNÁL: PLUSZ
_elojel := '-'                      // eladásnál mínusz jel a bizonylatban
```

**Plusz funkciók eladásnál:**
- `Dnem2Vtemp` → eladási devizanem kezelés (VTEMPD tábla)
- `GetPtParams` → POS terminál paraméterek
- `Limitdisplay` → készlet limit figyelés
- Konverzió kezelés: ha konverzió → kezelési díj = 0

**Készlet kontrol:**
```pascal
if _fizetendo > _aktzaro then
  → "NINCS ENNYI FORINT KÉSZLETÜNK" — tranzakció megtagadva
```

### 2.4 Stornó

**Fájl:** `VALUTA\STORNO\Unit2.pas` (36K, ~1100 sor)

Tranzakció visszavonás: eredeti bizonylat alapján visszaállítja a készletet, könyveli a sztornót.

### 2.5 Napi Záras — Pénztári Szint

**Fájl:** `VALUTA\NAPZAR\Unit2.pas` (45K, ~1600 sor)

**Kritikus workflow — a nap végén kötelező:**

```
1. FormActivate → HARDWARE lezárt nap ellenőrzés
2. ForgalomBeolvasas → napi tételek összegzése
3. NapiForgalomSzamitas → devizánkénti nettó (ARFOLYAM tábla alapján)
4. Árfolyam archiválás → INSERT INTO éves árfolyam tábla
5. Címlet archiválás → INSERT INTO éves címlet tábla
6. Ügyfél napi limit nullázás:
   UPDATE UGYFEL SET NAPIGONGYOLTFORINT = 0
   UPDATE JOGISZEMELY SET ...
7. WU mozgás (WUMOZGAS tábla feldolgozás)
8. OTP lezárás
9. HARDWARE lezárt nap frissítés
10. INSERT INTO éves forgalmi tábla
11. BLOKKFEJ + BLOKKTETEL archiválás
```

### 2.6 Címletezés

5 DLL a bankjegy/érme készlet kezelésére:

| DLL | Funkció |
|-----|---------|
| `CIMLET` | Címlet bevitel (bankjegy típusonkénti darabszám × névérték) |
| `CIMLCTRL` | Címlet ellenőrzés |
| `CIMLMENU` | Címletezési menü |
| `CIMLNYOM` | Címletnyomtatás |
| `KCIMLET` | Kis címlet (érme) |

### 2.7 P0 MAG — DB Táblák Összesítés

| Tábla | Funkció | Elsődleges modul |
|-------|---------|------------------|
| `VTEMP` | Ideiglenes tranzakciós munkaterület | VASARLAS, ELADAS |
| `VTEMPD` | Eladási devizanem ideiglenes tábla | ELADAS |
| `ARFOLYAM` | Aktuális árfolyamok (devizanem, vétel, eladás, MNB) | Mindenütt |
| `HARDWARE` | Pénztár konfig (gép, lezárt nap, SHK, BKKS) | Mindenütt |
| `PENZTAR` | Pénztár adatok | VASARLAS, NAPZAR |
| `UGYFEL` | Ügyfelek (személyi, napi limit) | VASARLAS, ELADAS |
| `JOGISZEMELY` | Jogi személyek | VASARLAS |
| `KEZELESIDATA` | Kezelési díj konfiguráció | VASARLAS |
| `TRANZDIJTABLA` | Tranzakciós díj sávok | VASARLAS |
| `BLOKKFEJ` | Bizonylat fejléc (napi) | NAPZAR, ATADVET |
| `BLOKKTETEL` | Bizonylat tételek | NAPZAR, ATADVET |
| `CIMINI` | Címlet inicializálás | NAPZAR |
| `WUMOZGAS` | Western Union mozgások | NAPZAR |
| `MEDIA` | Szkennelt dokumentumok | VASARLAS |
| `QRPARAMS` | QR kód paraméterek | VASARLAS, NAPZAR |

---


---

## S4 3_P0_MAG_ERTEKTARI_LOGIKA

### 3.1 Az Értéktár Szerepe

Az értéktár (`ERTEKTAR` rendszer) a pénztárak **felett álló** készletkezelő központ. **60 DLL modul**, szinte minden VALUTA DLL-nek van értéktári párja — de értéktári szintű logikával (több pénztár összegzése, bank felé mozgás).

```
ERTEKTAR — 60 DLL, 105K sor
├── atadvet (138K — legnagyobb modul!) ← ÁTADÁS/ÁTVÉTEL
├── irarfoly                           ← IRODAI ÁRFOLYAM
├── napzar                             ← ÉRTÉKTÁRI NAPI ZÁRAS
├── havizar                            ← HAVI ZÁRAS
├── atadolap (64K)                     ← ÁTADÓLAP DOKUMENTUM
├── cimlet/cimlctrl/cimlmenu/cimlnyom  ← CÍMLETEZÉS
├── listak                             ← PÉNZTÁR FORGALOM
├── pillall/pillkesz                   ← PILLANATNYI ÁLLAPOT
├── storno                             ← SZTORNÓ
└── ... (további ~45 DLL)
```

### 3.2 Értéktári Átadás/Átvétel (`atadvet`) — A Legnagyobb Modul

**Fájl:** `ERTEKTAR\etdll\atadvet\debug\unit2.pas` (138K+ — a teljes rendszer legnagyobb DLL-je)
**Osztály:** `TAtadAtvetForm`

#### 3.2.1 Adatbázis Kapcsolatok (5 független DB!)

| Kapcsolat | Cél |
|-----------|-----|
| `AxaDbase/AxaQuery/AxaTranz` | Értéktári fő DB |
| `TempDbase/TempQuery/TempTranz` | Ideiglenes munkaterület |
| `TradeDbase/TradeQuery/TradeTranz` | Kereskedelmi DB |
| `ValdataDbase/ValdataQuery/ValdataTranz` | Valuta adat DB |
| `ValutaDbase/ValutaQuery/ValutaTranz` | Pénztári DB |

#### 3.2.2 Devizanem Kezelés

A rendszer **27 devizanemet** kezel fix sorrendben:

```pascal
_dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD',
       'PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');
```

Minden devizanemhez: bankjegy címletek (típusonként), darabszám, érték.

#### 3.2.3 Core Workflow: Átadás/Átvétel

```
1. FormActivate → AlapadatBeolvasas + AlapNullazas
2. Menüből választás:
   ├── AtvetGomb (_irany=1) → ÁTVÉTEL társpénztártól
   ├── AtadGomb (_irany=2) → ÁTADÁS társpénztárnak
   ├── PENZATVETGomb → Valuta átvétel (_dtype='DEV', _tipus='U')
   └── PRNZATADGomb → Valuta átadás (_dtype='DEV', _tipus='F')
3. KozosAdvet (közös rutin):
   a. penztarrutin → társpénztár kiválasztás (getptar.dll)
   b. PenztarBeolvasas → választott pénztár adatai
   c. UPDATE VTEMP SET TIPUS=...
   d. Ha cél='TH' vagy '1' → supervisorjelszo szükséges
   e. keszleteditalorutin(_irany) → készlet szerkesztés
   f. PiszkozatBeolvasas → kitöltött tábla beolvasása
   g. KeszletControl → készlet ellenőrzés
   h. getplombarutin → plomba(pecsét)szám bekérése
   i. PlombaadatBeolvasas
   j. TranzakcioKonyveles → könyvelés + nyomtatás
```

#### 3.2.4 Tranzakció Könyvelés (SQL műveletek)

```sql
-- 1. VTEMP munkaterület törlés
DELETE FROM VTEMP

-- 2. Bizonylat tétel írás
INSERT INTO BLOKKTETEL (BIZONYLATSZAM, VALUTANEM, BANKJEGY, ...)
VALUES (...)

-- 3. Bizonylat fejléc írás
INSERT INTO BLOKKFEJ (BIZONYLATSZAM, TIPUS, DATUM, IDO,
  TETEL, FORINTERTEK, TARSPENZTARKOD,
  PENZTAROSNEV, IDKOD, PLOMBASZAM, SZALLITONEV,
  STORNO, TRBPENZTAR)
VALUES (...)

-- 4. VTEMP frissítés a bizonylat adatokkal
UPDATE VTEMP SET BIZONYLATSZAM=..., TIPUS=..., DATUM=..., IDO=...,
  TETEL=..., PENZTARKOD=..., TRBPENZTAR=..., TARSPENZTARNEV=...,
  OSSZESFORINTERTEK=..., SZALLITONEV=..., PLOMBASZAM=...,
  MEGJEGYZES=..., STORNO=1

-- 5. Pénzszállítás nyilvántartás
INSERT INTO WPENZSZALLITAS (DATUM, BIZONYLATSZAM, PLOMBASZAM,
  SZALLITONEV, WTIPUS)
VALUES (...)

-- 6. Utolsó blokk szám frissítés
UPDATE UTOLSOBLOKKOK SET {tema} = {ujblokknum}
```

#### 3.2.5 FTP Szinkronizáció

Az átadólap FTP-n megy a szerverre:

```pascal
_ftpPassword := 'klc+45%';
_userId := 'ebc-10%';
_ftpPort := 21100;
```

**KRITIKUS BIZTONSÁGI MEGJEGYZÉS:** Hardcoded FTP jelszó és felhasználó a forráskódban. Port: 21100 (nem standard). Titkosítatlan FTP protokoll.

#### 3.2.6 Külső DLL Hívások

| DLL | Funkció | Útvonal |
|-----|---------|---------|
| `super.dll` | Supervisor jelszó | `c:\ertektar\bin\` |
| `bloknyom.dll` | Blokk nyomtatás | `c:\ertektar\bin\` |
| `kezdij.dll` | Kezelési díj átadó | `c:\ertektar\bin\` |
| `logiro.dll` | Napló írás | `c:\ertektar\bin\` |
| `matptar.dll` | Anyagpénztár | `c:\ertektar\bin\` |
| `getptar.dll` | Pénztár választó | `c:\ertektar\bin\` |
| `getplomb.dll` | Plomba kezelés | `c:\ertektar\bin\` |
| `cimlctrl.dll` | Címlet kontrol | `c:\ertektar\bin\` |
| `cimlet.dll` | Címletező | `c:\ertektar\bin\` |
| `regen.dll` | Regenerálás | `c:\ertektar\bin\` |
| `keszedit.dll` | Készlet szerkesztés | `c:\ertektar\bin\` |
| `hrkget.dll` | HRK átvevő | `c:\ertektar\bin\` |

### 3.3 Értéktári Napi Záras (`napzar`)

**Fájl:** `ERTEKTAR\etdll\napzar\debug\unit2.pas`
**Osztály:** `TNapzarForm`

#### 3.3.1 Workflow

```
1. FormActivate → Képernyő inicializálás
2. InditoTimer:
   a. SELECT * FROM HARDWARE → _megnyitottnap beolvasás
   b. SELECT * FROM VTEMP → _zDatums (zárandó dátum)
   c. Ha _zDatums = '' → "NINCS BELÉPÉSI DÁTUM" — FATÁLIS HIBA
   d. Ha _zDatums > _megnyitottnap → "A zárandó nap a jövőben lesz!"
   e. regeneralorutin → adatok regenerálása
3. NapzarControl → 5 lépéses ellenőrzés:
   ├── errorcode=1: esti címletezés hibás
   ├── errorcode=2: kezelési díj címletezés hibás
   ├── errorcode=3: Western Union címletezés hibás
   ├── errorcode=4: ÁFA címletezés hibás
   └── errorcode=5: e-kereskedelem címletezés hibás
4. Ha errorcode>0 → cimletmenurutin (javítás lehetősége)
5. getellenorrutin → ellenőrző összeg
6. Checkcontrol(0) → ellenőrző lista
7. HRK záró kezelés (ha _hrkzaro>0 → kunacimletezes)
8. HavigyujtokbeMasolas → 10 másolási rutin:
   ├── BfCopy → BLOKKFEJ → BF{farok} havi gyűjtő
   ├── BtCopy → BLOKKTETEL → BT{farok}
   ├── CimtCopy → CIMINI → CIMT{farok}
   ├── NarfCopy → napi árfolyam
   ├── EdatCopy → eladási adatok
   ├── EkerCopy → e-kereskedelem
   ├── KdatCopy → kezelési adatok
   ├── KezdijCopy → kezelési díj
   ├── WuniCopy → Western Union
   └── WzarCopy → WU záras
9. napzarnyomtatorutin → záras kinyomtatása
10. UPDATE HARDWARE SET LEZARTNAP = {dátum} → záras nyugtázása
```

#### 3.3.2 Havi Gyűjtő Másolási Minta (BfCopy példa)

```sql
-- A BLOKKFEJ-et soronként beolvassa és BF{éévhh} táblába másolja:
SELECT * FROM BLOKKFEJ
→ soronként:
INSERT INTO BF{farok} (BIZONYLATSZAM, DATUM, TIPUS, IDO,
  FORINTERTEK, TETEL, TRBPENZTAR, TARSPENZTARKOD,
  PENZTAROSNEV, IDKOD, PLOMBASZAM, SZALLITONEV,
  STORNO, STORNOBIZONYLAT)
VALUES (...)

-- Majd a napi tábla törlése:
DELETE FROM BLOKKFEJ
```

**BLOKKFEJ séma (a kódból rekonstruálva):**

| Mező | Típus | Leírás |
|------|-------|--------|
| BIZONYLATSZAM | STRING | Egyedi bizonylatszám |
| DATUM | STRING | Dátum (ÉÉÉÉ.HH.NN formátum) |
| TIPUS | STRING | Típus kód (V=vétel, E=eladás, F=forint, U=utalás) |
| IDO | STRING | Időpont |
| FORINTERTEK | INTEGER | Forint érték |
| TETEL | INTEGER | Tételszám |
| TRBPENZTAR | STRING | TRB pénztár kód |
| TARSPENZTARKOD | STRING | Társpénztár kód |
| PENZTAROSNEV | STRING | Pénztáros neve |
| IDKOD | STRING | Azonosító kód |
| PLOMBASZAM | STRING | Plomba(pecsét) szám |
| SZALLITONEV | STRING | Szállító neve |
| STORNO | INTEGER | Stornó jelző (1=aktív) |
| STORNOBIZONYLAT | STRING | Stornózott bizonylat száma |

**BLOKKTETEL séma:**

| Mező | Típus | Leírás |
|------|-------|--------|
| BIZONYLATSZAM | STRING | Hivatkozás BLOKKFEJ-re |
| DATUM | STRING | Dátum |
| VALUTANEM | STRING(3) | Devizanem kód (EUR, USD, stb.) |
| FORINTERTEK | INTEGER | Forint érték |
| ARFOLYAM | INTEGER | Alkalmazott árfolyam |
| ELSZAMOLASIARFOLYAM | INTEGER | Elszámolási árfolyam |
| BANKJEGY | INTEGER | Bankjegy összeg |
| TORTRESZ | STRING | Tört rész |
| ELOJEL | STRING | Előjel (+/-) |
| STORNO | INTEGER | Stornó jelző |

### 3.4 Irodai Árfolyam (`irarfoly`)

**Fájl:** `ERTEKTAR\etdll\irarfoly\debug\unit2.pas`
**Osztály:** `TIRODAARFOLYAMOK`

Ez a modul az értéktári szintű **irodai árfolyam-kijelzést** végzi — nem maga készíti az árfolyamot (azt a szerver `arfolyam` modulja csinálja), hanem megjeleníti a pénztárak számára.

#### 3.4.1 Árfolyam Adatstruktúra

Az árfolyamokat **bináris fájlból** olvassa (`c:\ertektar\arfolyam\arfolyam.dat`), NEM adatbázisból:

```pascal
// Bináris struktúra (45 byte/devizanem, 27 devizanem):
_elszamarf[i] := intdekodol(1);    // Elszámolási árfolyam
_vetarf[i]    := intdekodol(6);    // Vételi árfolyam
_eladarf[i]   := intdekodol(11);   // Eladási árfolyam
_uvetarf[i]   := intdekodol(16);   // Ügyféllel szembeni vételi
_ueladarf[i]  := intdekodol(21);   // Ügyféllel szembeni eladási
_bvetarf[i]   := intdekodol(26);   // Bank vételi
_beladarf[i]  := intdekodol(31);   // Bank eladási
```

**Minden árfolyamrekord 7 árfolyam-értéket tartalmaz devizanemenként:**
1. Elszámolási árfolyam
2. Vételi árfolyam
3. Eladási árfolyam
4. Ügyfél vételi árfolyam
5. Ügyfél eladási árfolyam
6. Bank vételi árfolyam
7. Bank eladási árfolyam

#### 3.4.2 Pénztárcsoport Struktúra

Az árfolyam fájl **csoportonként** tárolja az adatokat:

```pascal
_sajcsoport := _bytetomb[_irnum];  // Pénztár → csoport mapping
_kezdet := 201 + trunc((_sajcsoport - 1) * 1221);  // Offset a bináris fájlban
```

Max **54 csoport**, csoportonként 1221 byte (27 devizanem × 45 byte + 6 byte limit).

#### 3.4.3 Limit Értékek (Sávos Kedvezmény Határok)

A bináris fájl végén 6 byte-os limit struktúra:

```pascal
_k1 := _bytetomb[1] + (256 * _bytetomb[2]);  // 1. limit
_k2 := _bytetomb[3] + (256 * _bytetomb[4]);  // 2. limit
_k3 := _bytetomb[5] + (256 * _bytetomb[6]);  // 3. limit

// Sávok:
// 1 — sk1 Ft: alapszint
// sk1+1 — sk2 Ft: közepes
// sk2+1 — sk4 Ft: nagy
// sk4+1 — ∞: kiemelt
```

Ez a 3 sávos kedvezmény-rendszer határa: kis/közepes/nagy összegű tranzakciókra eltérő árfolyam alkalmazható.

#### 3.4.4 Devizanem Sorrend (irarfoly — eltérő a VALUTA-tól!)

```pascal
// ERTEKTAR sorrend (irarfoly):
_sdnem: ('EUR','USD','GBP','CHF','AUD','CAD','DKK','JPY','NOK','SEK',
         'CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH','RUB','EUA',
         'TRY','CNY','BAM','THB','BRL','MXN','NZD');
```

**KRITIKUS:** Az értéktári devizanem sorrend **eltér** a pénztári sorrendtől! A VALUTA abc-sorrendben tartja (AUD, BAM, ..., USD), az ERTEKTAR EUR-val kezdi. A migrációnál a mapping-et pontosan meg kell őrizni.

---


---

## S5 4_P0_MAG_FOERTEKTARI_ARFOLYAMKESZITES

### 4.1 A Szerver Árfolyamkészítő Modul

**Útvonal:** `SZERVER\fejleszt\arfolyam\verzio22\`
**4 verzió:** v20, v21, v22 + old (v22 az aktív)

Ez a **főértéktár legkritikusabb funkciója** — egy **beépített spreadsheet alkalmazás**, amivel az árfolyamtáblát készítik.

### 4.2 Spreadsheet Architektúra

```
TMunkaForm — táblázatos felület (Excel-szerű rács)
├── Sorok = devizanemek (27 db)
├── Oszlopok = pénztárak/csoportok (10 oszlop)
├── Minden cella tartalmaz:
│   ├── érték (numerikus)
│   ├── függvény (képlet string)
│   ├── betűszín
│   └── háttérszín
├── FuggvenyKezelo → cellánkénti képlet szerkesztés
├── FuggvenyKijelzes → képlet kiértékelés
├── AdatMasolorutin → cellák másolása csoportok között
└── szetkuldogombClick → ÁRFOLYAM SZÉTKÜLDÉS AZ IRODÁKBA
```

### 4.3 Adatszerkezet (Tömb Alapú)

```pascal
// 10 oszlop tömbjei (minden oszlopnak 4 mező):
_jertek[csoport, sor]      // 1. oszlop — érték
_jfuggveny[csoport, sor]   // 1. oszlop — függvény
_jBetuszin[csoport, sor]   // 1. oszlop — betűszín
_jHatterszin[csoport, sor] // 1. oszlop — háttérszín

// Hasonlóan: _lertek, _mertek, _nertek, _oertek,
//            _pertek, _qertek, _rertek, _sertek
// (3-10. oszlop)
```

### 4.4 Függvény-Alapú Számítás

A képleteket saját parserre értékeli ki a rendszer:

```pascal
EgyFuggvenyKiszamitasa  // Egyetlen képlet kiértékelése
Fuggvenybontas          // Képlet szintaktikai elemzés
SubFvbontas             // Alcsoport képlet
FvenybolNum             // String → szám konverzió
CsoportLapAtszamolo     // Csoport szintű újraszámítás
CsoportTagSzamito       // Csoport-tagok összesítése
SummaTagok              // Summa számítás
ErtekControl            // Validálás
LapRegeneralo           // Teljes tábla újraszámítás
```

### 4.5 Szétküldés Workflow

```
1. szetkuldogombClick
2. PenztarListaTolto → pénztárak listája a szétküldéshez
3. AdatSzetkuldes.ShowModal → felhasználó kiválasztja a célokat
4. ArfdataIras.ShowModal → bináris árfolyam fájl generálása
5. → FTP szétküldés az irodákba
```

**Üzleti szabály:** Az árfolyamkészítés centralizált — a főértéktári szinten készül el a teljes árfolyamtábla, képletekkel. Csak ezután kerül szétküldésre minden irodába.

---


---

## S6 5_P1_RING_1_PENZTARAK_KOZTI_ATADASATVETEL_KESZLETEZES

### 5.1 Modul Lista

| Modul | Rendszer | Funkció |
|-------|----------|---------|
| `atadvet` (138K) | ERTEKTAR | **Átadás/átvétel fő modul** — lásd fent részletesen |
| `keszedit` | ERTEKTAR | Készlet szerkesztés |
| `keszup` | ERTEKTAR | Készlet frissítés |
| `ptarkesz` | ERTEKTAR | Pénztár készlet lekérés (aktuális) |
| `ptartmk` | ERTEKTAR | Pénztár táblázat makró |
| `penztarak` | ERTEKTAR | Pénztárak kezelése (értéktári szintről) |
| `pillall` | ERTEKTAR | Pillanatnyi összesített állapot |
| `pillkesz` | ERTEKTAR | Pillanatnyi készlet + grafikon |
| `cimlet` | ERTEKTAR | Címlet kezelés |
| `cimlctrl` | ERTEKTAR | Címlet ellenőrzés |
| `cimlmenu` | ERTEKTAR | Címlet menü |
| `cimlnyom` | ERTEKTAR | Címlet nyomtatás |
| `kcimlet` | ERTEKTAR | Kis címlet (érme) |
| `storno` | ERTEKTAR | Sztornó |
| `getptar` | ERTEKTAR | Pénztár kiválasztó |
| `getplomb` | ERTEKTAR | Plomba kezelés |
| `getellen` | ERTEKTAR | Ellenőrző összeg |
| `regen` | ERTEKTAR | Regenerálás |

### 5.2 Készlet Kezelési Logika

A készletezés **címlet-szintű** — nem csak devizanem összegben, hanem bankjegy-típusonként:

```
Devizánként max 14 címlet típus:
_cimletstring: ('20.000','10.000','5.000','2.000','1.000','500','200','100',
                '50','20','10','5','2','1')
_cimletertek: (20000,10000,5000,2000,1000,500,200,100,50,20,10,5,2,1)
```

Devizanemenként eltérő a használt címletek száma:
```pascal
_cimletdarab: array[1..27] of byte = (5,5,7,7,5,6,7,6,5,9,4,7,12,14,4,5,5,5,5,7,
         9,7,7,9,7,9,7);
// EUR: 9 címlet, GBP: 4, HUF: 12, JPY: 4
```

### 5.3 Üzleti Szabályok — RING 1

| Szabály | Leírás |
|---------|--------|
| Plomba kötelező | Pénztárak közti szállításnál plomba(pecsét)szám rögzítése kötelező |
| Supervisor jóváhagyás | Főértéktár ('TH') vagy kiemelt pénztár ('1') felé szállításnál supervisor jelszó kell |
| Készlet kontrol | Átadás előtt ellenőrzés: van-e elegendő készlet az adott címletekből |
| Bizonylat nyomtatás | Minden mozgásról blokk nyomtatás + BLOKKFEJ/BLOKKTETEL INSERT |
| Pénzszállítás napló | `WPENZSZALLITAS` táblába INSERT (dátum, bizonylatszám, plomba, szállító, típus) |

### 5.4 DB Táblák — RING 1

| Tábla | Funkció |
|-------|---------|
| `CIMLETPISZKOZAT` | Címlet piszkozat (szerkesztés közben) |
| `CIMLETEK` | Címlet nyilvántartás |
| `WPENZSZALLITAS` | Pénzszállítás napló |
| `UTOLSOBLOKKOK` | Utolsó bizonylat sorszámok |
| `PENZTARFORGALOM` | Pénztár forgalmi adatok |

---


---

## S7 6_P2_RING_2_ERTEKTARPENZTAR_ERTEKTARBANK_MOZGASOK

### 6.1 Átadólap (`atadolap`) — A Legkritikusabb Dokumentum

**Fájl:** `ERTEKTAR\etdll\atadolap\` (64K)

Az átadólap a pénztár↔értéktár és értéktár↔bank közti **devizamozgás hivatalos dokumentuma**.

#### 6.1.1 Átadólap Adatstruktúra

```
_etData[] tömb — 93+ mező:
[1]     Értéktárszám
[2]     Dátum
[3]     Átadó neve
[4]     Átvevő neve
[5]     Pénzkészlet: Egyezik
[6]     Pénzkészlet: Nem egyezik
[7]     Pénzkészlet: Eltérés
[8-16]  Tartozások (max 3 tétel: értéktárnak, összeg, devizanem)
[17-25] Követelések (max 3 tétel: értéktártól, összeg, devizanem)
[26-31] Western Union / ÁFA rendelés (max 2 tétel)
[32-47] Banki beszállítás (max 4 tétel: devizanem, összeg, név, árfolyam)
[48-59] Banki kiszállítás (max 4 tétel)
[60-79] Pénztári rendelések (max 4 tétel: devizanem, pénztár, név, összeg, árfolyam)
[80-91] Körlevelek (max 4 tétel)
[92-93] Egyéb fontos információk (2 sor szabad szöveg)
```

#### 6.1.2 Üzleti Szabályok — Átadólap

| Szabály | Leírás |
|---------|--------|
| Kötelező kitöltés | Minden értéktári mozgáshoz átadólap kell |
| FTP szinkron | Az átadólap FTP-n megy a szerverre |
| Készlet egyeztetés | Pénzkészlet egyezik/nem egyezik/eltérés rögzítése |
| Bank mozgás nyilvántartás | Max 4 banki beszállítás + 4 kiszállítás dokumentálása |
| Körlevél hivatkozás | Max 4 körlevél hivatkozás |

### 6.2 Értéktári Napkönyv és Záras Rendszer

| Modul | Funkció |
|-------|---------|
| `napzar` | Értéktári napi záras (lásd fent) |
| `havizar` | Havi záras — `CREATE TABLE + feltöltés → havi összesítés` |
| `estizar` | Esti záras — automatikus nap végi záras indítás |
| `regizaro` | Régi záras (archív) |
| `napijel` | Napi jelentés — `DELETE FROM VTEMP`, `DELETE FROM NAPIZAR` |
| `napikezd` | Napi kezdés — `DELETE FROM NAPIKEZD WHERE DATUM=...` |
| `napkonyv` | Napi könyv — `DELETE FROM NAPLO WHERE DATUM=...`, `DELETE FROM NAPIKONYV WHERE DATUM=...` |
| `maktablak` | Tábla létrehozó makró — 10+ CREATE TABLE |

### 6.3 Havi Záras DB Műveletek

```sql
-- havizar.dll:
DELETE FROM {hzTablanev}
CREATE TABLE {hzTablaNev} (...)
-- Feltöltés: napi záras adatok havi gyűjtőbe
```

### 6.4 Értéktári Modul — DB Tábla Összesítés

| Tábla | Funkció | Létrehozó |
|-------|---------|-----------|
| `BF{éévhh}` | Havi blokkfej gyűjtő (dinamikus névvel) | napzar |
| `BT{éévhh}` | Havi blokktetel gyűjtő | napzar |
| `CIMT{éévhh}` | Havi címletezés gyűjtő | napzar |
| `NAPIZAR` | Napi záras adatok | napijel |
| `NAPIKEZD` | Napi kezdés adatok | napikezd |
| `NAPIKONYV` | Napi könyvelés | napkonyv |
| `NAPLO` | Eseménynapló | napkonyv |
| `IKTATO` | Körlevél iktatószámok | korlev |
| `IDOSZAK` | Időszak definíciók | idoszak |
| `HRKNAPLO` | HRK (korábbi horvát kuna) napló | napzar |

### 6.5 Egyéb RING 2 Modulok

| Modul | Funkció |
|-------|---------|
| `arftmk` | Árfolyam táblázat makrók (értéktári szint) |
| `ratectrl` | Árfolyam kontrol és validálás |
| `rateperm` | Árfolyam engedélyezés |
| `getarf` | Árfolyam lekérdezés |
| `listak` | Pénztárforgalom listák |
| `logdisp/logiro` | Napló megjelenítés/írás |
| `mentes` | Adatbázis mentés |
| `super/supertsk` | Supervisor funkciók |
| `terminal` | POS terminál |
| `wunion` | Western Union (értéktári szint) |
| `korlev` | Körlevél |
| `nifval` | NIF validálás |
| `prosbe` | Belépés (supervisor) |

---


---

## S8 7_P3_RING_3_SZERVER_ADATTAROLAS_ADMINISZTRACIO_BELSO_ELLENORZES

### 7.1 server.exe — Központi Admin

**37 form**, központi admin alkalmazás. A szerver az összes iroda adatait gyűjti, összesíti, és az MNB/NAV felé jelent.

### 7.2 Haszonszámítás (`haszon`) — CORE Szerver Funkció

**Fájl:** `SZERVER\fejleszt\haszon\unit1.pas` + `unit2.pas` + `unit3.pas` + `unit4.pas` + `unit5.pas`
**Osztály:** `TForm1` (unit1), `TKijelzes` (unit2), `TIdoszakKeroForm` (unit3)

#### 7.2.1 Haszonszámítás CORE Képlete

A profit az **árfolyamrésből** számolódik — az alkalmazott és az elszámolási árfolyam különbsége:

```pascal
// VÉTEL (V típusú bizonylat):
_arfdiff := _elszarf - _arfolyam;                    // elszámolási - alkalmazott
_profit := round(_bankjegy * _arfdiff / 100);         // bankjegy × különbözet / 100
if _valutanem = 'JPY' then _profit := trunc(_profit * 100);  // JPY korrekció

// ELADÁS (E típusú bizonylat):
_arfdiff := _arfolyam - _elszarf;                    // alkalmazott - elszámolási
_profit := round(_bankjegy * _arfdiff / 100);
if _valutanem = 'JPY' then _profit := round(_profit * 100);

// KONVERZIÓ VÉTEL (+):
_arfdiff := _elszarf - _arfolyam;
_profit := round(_bankjegy * _arfdiff / 100);

// KONVERZIÓ ELADÁS (- és nem HUF):
_arfdiff := _arfolyam - _elszarf;
_profit := round(_bankjegy * _arfdiff / 100);
```

**Lényeg:** A haszon = bankjegy mennyiség × (árfolyamrés) / 100. Vétel: mennyit nyertünk az olcsóbb vételen. Eladás: mennyit nyertünk a drágább eladáson.

#### 7.2.2 Kedvezményes vs. Kedvezmény Nélküli Profit

A rendszer elkülöníti a **kedvezményes** és **kedvezmény nélküli** forgalmat:

```pascal
// Kedvezmény keresés (ARFE{farok} tábla, ENGEDMENYTIPUS > 7):
_voltkedvezmeny := KedvezmenySeek(_bizonylat);

if _voltkedvezmeny then
  _xkprofit := _xkprofit + _profit;     // kedvezményes profit
  _xkforgalom := _xkforgalom + _xforgalom;
else
  _xsprofit := _xsprofit + _profit;     // kedvezmény nélküli profit
  _xsforgalom := _xsforgalom + _xforgalom;
  // + forgalom sávozás: ≤50K, 50K-300K, >300K
```

#### 7.2.3 MNB Profit és Átlag Elszámoló Profit

A haszon modul **három profit-nézetet** számít:

| Profit típus | Számítás | Szín |
|-------------|----------|------|
| **Napi árfolyamrés profit** | `_tprofit` — alkalmazott vs. elszámolási | Teal |
| **MNB profit** | `_tmnbprofit` — alkalmazott vs. MNB árfolyam | Piros |
| **Átlag elszámolási profit** | `_tsprofit` — átlag vételi/eladási vs. elszámolási | Kék |

MNB profit képlet:
```pascal
// Vételi oldal:
_arfdiff := _mnbelsz[deviza] - _tvatlagarf[pénztár, deviza];
_vprofit := _svBankjegy[deviza] * _arfdiff / 100;

// Eladási oldal:
_arfdiff := _teAtlagArf[pénztár, deviza] - _mnbelsz[deviza];
_eprofit := _seBankjegy[deviza] * _arfdiff / 100;

_mprofit := round(_vprofit + _eprofit);
```

#### 7.2.4 Adatforrás

A haszon modul a `DAYB{éévhh}` (DayBook) és `BT{éévhh}` (BlokkTetel) havi gyűjtő táblákból dolgozik, irodánkénti FDB fájlokból:

```pascal
_fdbPath := 'c:\receptor\database\v' + inttostr(_aktpenztar) + '.fdb';
// Pl: c:\receptor\database\v101.fdb, v102.fdb, ...
```

#### 7.2.5 Excel Export

A haszon modul **Excel COM automatizálással** készít riportot:
- Körzetenként csoportosítva (8 körzet: Szekszárd, Szeged, Kecskemét, Debrecen, Nyíregyháza, Békéscsaba, Pécs, Kaposvár)
- Oszlopok: pénztárszám, megnevezés, engedmény nélküli árfolyamrés + forgalom, kedvezményes árfolyamrés + forgalom, 50K alatti/50K-300K/300K feletti forgalom bontás

#### 7.2.6 DB Táblák — Haszon

| Tábla | Típus | Funkció |
|-------|-------|---------|
| `IRODAK` | Statikus | Irodák listája (UZLET, KESZLETNEV, ERTEKTAR) |
| `DAYB{éévhh}` | Dinamikus | Napi könyv (havi, pénztáranként) |
| `BT{éévhh}` | Dinamikus | Blokk tételek havi gyűjtő |
| `ARFE{éévhh}` | Dinamikus | Árfolyam engedmények (kedvezmény tracking) |
| `MNB` | Statikus | MNB elszámolási árfolyamok |

### 7.3 Könyvelés (`booking`) — CORE Szerver Funkció

**Útvonal:** `SZERVER\fejleszt\booking\` (7 almodul)

| Almodul | Funkció |
|---------|---------|
| `booking` | Fő könyvelési modul (AdatlegyujtoProgram, BookingControl, Konyveles) |
| `advetexcel` | Átadás/átvétel Excel export |
| `forgexel` | Forgalom Excel export |
| `keszexcel` | Készlet Excel export |
| `proba` | Próba könyvelés |
| `save/` | Mentett verziók (minden almodulból) |

**SQL műveletek:**
```sql
DELETE FROM TRANZAKCIOK
DELETE FROM ATADATVET
DELETE FROM EVHONAP
```

**DB Táblák — Booking:**

| Tábla | Funkció |
|-------|---------|
| `TRANZAKCIOK` | Tranzakciós összesítő |
| `ATADATVET` | Átadás/átvétel könyvelés |
| `EVHONAP` | Éves-havi összesítő |

### 7.4 Ügyfélkontrol (`ugyfelcontrol`) — COMPLIANCE Core

**Útvonal:** `SZERVER\fejleszt\ugyfelcontrol\` (13 DLL + 1 főprogram)

#### 7.4.1 Főprogram

`ugyfctrl.exe` — főmenü 5 gombbal:
1. Időszak kereső
2. Ügyfél kereső
3. Évi max (300.000+ Ft kötelező ügyfélkezelés)
4. Terror napló
5. Új import

#### 7.4.2 DLL Modulok

| DLL | Funkció | Compliance? |
|-----|---------|------------|
| `adatgyujto.dll` | Adatgyűjtő | — |
| `adatlista.dll` | Adat lista | — |
| `evimax.dll` | Évi maximum tranzakciók (300K+ Ft kötelező) | ✅ Pmt. |
| `excel.dll` | Excel export | — |
| `idoszak.dll` | Időszak kezelés | — |
| `idoszakos.dll` | Időszakos lekérdezés | — |
| `import.dll` | Import | — |
| `kereso.dll` | Kereső + tiltások | ✅ AML |
| `letilt.dll` | Letiltás (ügyfél/tranzakció tiltas) | ✅ AML |
| `makeexcel.dll` | Excel export | — |
| `okmdisp.dll` | Okmány megjelenítés | ✅ KYC |
| `terrornaplo.dll` | Terror napló (ENSZ szankciós lista) | ✅ AML |
| `tiltasok.dll` | Tiltások kezelése | ✅ AML |
| `ujimport.dll` | Új import | — |

### 7.5 MNB Legyűjtés és Jelentés

| Modul | Funkció |
|-------|---------|
| `server.exe Unit14` (MNBLEGYUJTO) | MNB tábla ürítés + újratöltés irodánként |
| `server.exe Unit6` (MNBLISTAK) | `SELECT * FROM MNB` — MNB listák Excel CSV |
| `server.exe Unit17` (MNBLISTADISPLAY) | `SELECT SUM(VETELDARAB), SUM(ELADASDARAB) FROM MNB` |
| `mnbgyujto.dll` | MNB adat gyűjtés — `DELETE FROM MNB` |
| `mnbhibak.dll` | MNB hibák (eltérés jelentés) |

**MNB tábla séma:**
```sql
MNB (
  VALUTANEM,       -- devizanem kód
  IRODASZAM,       -- iroda azonosító
  VETELDARAB,      -- vételi darabszám
  ELADASDARAB,     -- eladási darabszám
  ZARO,            -- záró készlet (tényleges)
  SZAMITOTTZARO,   -- számított záró készlet
  MEGJEGYZES       -- eltérés megjegyzés
)
```

### 7.6 Terror Lista (`terror`)

**Útvonal:** `SZERVER\fejleszt\terror\`

| Lépés | Művelet |
|-------|---------|
| 1 | TWebBrowser → `https://www.un.org/securitycouncil/content/un-sc-consolidated-list` |
| 2 | XML letöltés |
| 3 | Parseolás: `FIRST_NAME`, `SECOND_NAME`, `THIRD_NAME` |
| 4 | `DELETE FROM UNOLIST` |
| 5 | `INSERT INTO UNOLIST (TERROR_NAME)` — soronként |
| 6 | Távoli szerverre is: `185.43.207.99` |

### 7.7 Rendőrségi Adatszolgáltatás (`police`)

4 almodulban (több verzió) — rendőrségi adatlekérdezések kezelése.

### 7.8 Western Union / WAFA

| Modul | Funkció |
|-------|---------|
| `western` | Értéktári WU adatok, Excel tábla generálás |
| `westuni` | WU második verzió |
| `wucontrol` | WU kontrol |
| `wuniforg` | WU forgalom |
| `sumwuafa.dll` | WU + WAFA összesítés |
| `wuafatranz.dll` | `DELETE FROM WAFATRANZ`, `DELETE FROM WUNITRANZ` |
| `server.exe Unit37` | WUNIWAFACONTROL — nyitó/zárókészlet INSERT/UPDATE |

### 7.9 HELGA Rendszer

**Helyi szerver** (`locserver.exe`) — irodai szintű admin. 9 külső DLL:
- `arftmk.dll` — árfolyam karbantartó
- `beerk.dll` — beérkezett adatok
- `mnbhibak.dll` — MNB hibák
- `jszorzo.dll` — jutalék szorzó
- `import.dll` — import felíró
- `zarasctrl.dll` — záras beérkezések
- `irtmk.dll` — iroda karbantartó
- `westforg.dll` — Western forgalom
- `dolgjutalek.dll` — dolgozó jutalék számító

---


---

## S9 8_SZERVER_MODULOK_CORE_VS_PERIPHERY_BESOROLAS

### 8.1 CORE Modulok (a MAG működéséhez nélkülözhetetlen)

| Modul | Ring | Indoklás |
|-------|------|----------|
| `arfolyam` (v22) | P0 | **Árfolyamkészítés — a rendszer szíve** |
| `haszon` | P0/P3 | **Haszonszámítás — üzleti döntések alapja** |
| `booking` | P3 | **Könyvelés — jogszabályi kötelezettség** |
| `tranzacs` + `tranzdb` + `tranzdij` | P3 | **Tranzakció kezelés — adattárolás gerince** |
| `ugyfelcontrol` | P3 | **Ügyfélkezelés — compliance kötelezettség** |
| `terror` | P3 | **ENSZ terrorlista — compliance kötelezettség** |
| `senddata` / `frissdat` | P3 | **Adatszinkron — irodák közti kommunikáció** |
| `mnbgyujto` / `mnbhibak` | P3 | **MNB legyűjtés — hatósági jelentés** |
| `police` | P3 | **Rendőrségi adatszolgáltatás — hatósági kötelezettség** |
| `statiszt` / `beszam` | P3 | **Statisztika/beszámoló — vezetői döntéshozatal** |
| `helga` (locserver) | P3 | **Helyi szerver — irodai admin** |

### 8.2 Periphery Modulok (opcionális, kiegészítő)

| Modul | Típus | Indoklás |
|-------|-------|----------|
| `western` / `westuni` / `wucontrol` / `wuniforg` | Integráció | WU szolgáltatás — nem alap valutaváltás |
| `monegram` | Integráció | MoneyGram — pénzküldés |
| `summa` / `sumrate` / `sumtablo` / `sumtrade` | Riport | Összesítők — nem operatív |
| `recptor` / `recguard` | Dokumentum | Bizonylat admin — nem napi operáció |
| `foglalo` | Logisztika | Foglalás — kiegészítő funkció |
| `verseny` / `everseny` | BI | Versenytárs figyelés — üzleti intelligencia |
| `korlevel` | Kommunikáció | Körlevél — belső kommunikáció |
| `litenews` | Kommunikáció | Hírlevél |
| `palyadij` | HR | Pályadíj számítás |
| `fdbtomorito` / `fdbtorlo` | Legacy | Firebird karbantartás |
| `gbakall` | Legacy | GBak backup |
| `etrade` / `setrade` | Kereskedelem | Elektronikus kereskedelem |
| `lemento` | Archív | Bizonylat mentés |
| `tiltcopy` | Biztonság | Másolásvédelem |

---


---

## S10 9_ADATBAZIS_SEMA_OSSZESITES

### 9.1 Fő Adatbázisok

| Útvonal | Tartalom | Szint |
|---------|----------|-------|
| `c:\valuta\{lokális}.fdb` | Pénztári helyi DB | Pénztár |
| `c:\ertektar\{lokális}.fdb` | Értéktári helyi DB | Értéktár |
| `c:\receptor\database\receptor.fdb` | Központi receptor DB | Szerver |
| `c:\receptor\database\V{irodaszám}.FDB` | Irodánkénti DB (V101, V102...) | Szerver |
| `185.43.207.99:{path}` | Távoli szerver | Terror lista |

### 9.2 Teljes Tábla Katalógus

#### 9.2.1 Statikus (állandó) táblák

| Tábla | Funkció | Ring |
|-------|---------|------|
| `ARFOLYAM` | Aktuális árfolyamok | P0 |
| `HARDWARE` | Pénztár konfig (gép, lezárt nap, SHK, BKKS) | P0 |
| `PENZTAR` | Pénztár adatok | P0 |
| `UGYFEL` | Ügyfelek (személyi, napi limit) | P0 |
| `JOGISZEMELY` | Jogi személyek | P0 |
| `KEZELESIDATA` | Kezelési díj konfiguráció | P0 |
| `TRANZDIJTABLA` | Tranzakciós díj sávok | P0 |
| `IRODAK` | Irodák listája (150 pénztár) | P3 |
| `USERS` | Felhasználók | P3 |
| `PENZTAROSOK` | Pénztárosok (dolgozók) | P3 |
| `MNB` | MNB jelentes tábla | P3 |
| `UNOLIST` | ENSZ terrorlista | P3 |
| `MAINCURR` | Fő devizák | P3 |
| `FOGLALO` | Foglalási összegek (150 × 5) | P3 |

#### 9.2.2 Operatív (napi) táblák

| Tábla | Funkció | Ring |
|-------|---------|------|
| `VTEMP` | Tranzakciós munkaterület | P0 |
| `VTEMPD` | Eladási deviza munkaterület | P0 |
| `BLOKKFEJ` | Bizonylat fejléc (napi) | P0 |
| `BLOKKTETEL` | Bizonylat tételek (napi) | P0 |
| `CIMINI` | Címlet inicializálás | P0 |
| `CIMLETEK` | Címlet nyilvántartás | P1 |
| `CIMLETPISZKOZAT` | Címlet piszkozat | P1 |
| `WPENZSZALLITAS` | Pénzszállítás napló | P1 |
| `UTOLSOBLOKKOK` | Utolsó bizonylat sorszámok | P1 |
| `NAPIKEZD` | Napi kezdés adatok | P2 |
| `NAPIZAR` | Napi záras | P2 |
| `NAPIKONYV` | Napi könyvelés | P2 |
| `NAPLO` | Eseménynapló | P2 |
| `IKTATO` | Körlevél iktatószámok | P2 |
| `IDOSZAK` | Időszak definíciók | P2 |
| `HRKNAPLO` | HRK napló | P2 |

#### 9.2.3 Dinamikus (havi/éves) táblák

| Tábla minta | Funkció | Ring |
|-------------|---------|------|
| `BF{éévhh}` | Havi blokkfej gyűjtő | P2 |
| `BT{éévhh}` | Havi blokktetel gyűjtő | P2 |
| `CIMT{éévhh}` | Havi címletezés | P2 |
| `DAYB{éévhh}` | Napi könyv (havi) | P3 |
| `ARFE{éévhh}` | Árfolyam engedmények | P3 |
| `UGYFELyy` | Éves ügyfél tábla | P3 |
| `JOGIBIZyy` | Éves jogi bizonylat | P3 |
| Havi tranzakció tablak | Dinamikus nevek | P3 |
| Havi elszámolás tablak | Dinamikus nevek | P3 |

#### 9.2.4 Külső integrációs táblák

| Tábla | Funkció | Ring |
|-------|---------|------|
| `WUMOZGAS` | Western Union mozgások | P0 (napzar) |
| `WAFATRANZ` | WAFA tranzakciók | P3 |
| `WUNITRANZ` | WU tranzakciók | P3 |
| `TRANZAKCIOK` | Tranzakció összesítő (booking) | P3 |
| `ATADATVET` | Átadás/átvétel könyvelés (booking) | P3 |
| `EVHONAP` | Éves-havi összesítő (booking) | P3 |
| `ADATATADO` | Adat átadás | P3 |
| `PENZTAROSFORGALOM` | Pénztáros forgalom (jutalék) | P3 |
| `JUTALEK` | Jutalék eredménye | P3 |
| `PENZTARFORGALOM` | Pénztár forgalom | P2 |
| `SUMALLOMANY` | Összesített állomány | P3 |
| `SUMBANKFORGALOM` | Összesített bank forgalom | P3 |
| `SUMUGYFELFORGALOM` | Összesített ügyfél forgalom | P3 |
| `QRPARAMS` | QR kód paraméterek | P0 |
| `MEDIA` | Szkennelt dokumentumok | P0 |
| `ARFOLYAMELTERITES` | Árfolyam eltérítések napló | P0 |

### 9.3 Karakterkódolás

```sql
-- Minden tábla:
CHARACTER SET WIN1250 COLLATE WIN1250
```

**Migrációs követelmény:** WIN1250 → UTF-8 konverzió szükséges PostgreSQL-re.

---


---

## S11 10_UZLETI_SZABALYOK_TELJES_KATALOGUSA

### 10.1 P0 — Valutaváltás Szabályok

| # | Szabály | Képlet/Logika | Forrás |
|---|---------|---------------|--------|
| BS-001 | Forintérték számítás | `round((árfolyam / 100 × bankjegy) + 0.001)` | VASARLAS/Unit2 |
| BS-002 | JPY speciális kezelés | `round(forintérték / 10)` | VASARLAS/Unit2 |
| BS-003 | 5 Ft-os kerekítés | `Kerekito()` — 5 Ft-ra kerekít | VASARLAS/Unit2 |
| BS-004 | Vétel bruttó | `bruttó = nettó - kezelési_díj` | VASARLAS/Unit2 |
| BS-005 | Eladás bruttó | `bruttó = nettó + kezelési_díj` | ELADAS/Unit2 |
| BS-006 | Kezelési díj (ezrelékes) | `trunc(nettó × ezrelék / 1000)`, max díjmaximum | VASARLAS/Unit2 |
| BS-007 | Kezelési díj (sávos) | `_tranzsav[n]` → `_kdij[n]` lookup | VASARLAS/Unit2 |
| BS-008 | Konverzió díj = 0 | Konverziónál nincs kezelési díj | VASARLAS, ELADAS |
| BS-009 | EUR érme akció díj = 0 | EUR érme konverzió akciónál nincs díj | VASARLAS/Unit2 |
| BS-010 | SHK limit | Max 5 saját hatáskörű kedvezmény / nap / pénztáros | HARDWARE |
| BS-011 | Eladási készlet kontrol | `if fizetendő > aktuális_záró` → MEGTAGADVA | ELADAS/Unit2 |
| BS-012 | Bizonylat sorszám | HARDWARE táblából egyedi + növekvő | VASARLAS/Unit2 |

### 10.2 P0 — Árfolyam Szabályok

| # | Szabály | Logika | Forrás |
|---|---------|--------|--------|
| BS-013 | Árfolyam 100 egységre | Az árfolyam 100 devizaegységre van megadva | Konvenció |
| BS-014 | 7 árfolyam-típus | Elszámolási, vételi, eladási, ügyfél vételi/eladási, bank vételi/eladási | irarfoly |
| BS-015 | Bináris árfolyam fájl | 45 byte/devizanem, 54 csoport × 1221 byte | irarfoly |
| BS-016 | 3 sávos kedvezmény | Kis/közepes/nagy összeg sávonként eltérő árfolyam | irarfoly |
| BS-017 | Centralizált árfolyamkészítés | Főértéktárban képletekkel számolva, FTP szétküldés | arfolyam v22 |

### 10.3 P1 — Készletezési Szabályok

| # | Szabály | Logika | Forrás |
|---|---------|--------|--------|
| BS-018 | Címlet-szintű nyilvántartás | Bankjegy típusonkénti darabszám × névérték | CIMLET |
| BS-019 | Plomba kötelező | Pénztárak közti szállításnál plombaszám rögzítése | atadvet |
| BS-020 | Supervisor jóváhagyás | Főértéktár/kiemelt pénztár felé supervisor jelszó | atadvet |
| BS-021 | Regenerálás | Záras előtt kötelező adatregenerálás | regen.dll |

### 10.4 P2 — Értéktári Záras Szabályok

| # | Szabály | Logika | Forrás |
|---|---------|--------|--------|
| BS-022 | 5 címletezés ellenőrzés | Esti + kez.díj + WU + ÁFA + e-kereskedelem | napzar |
| BS-023 | Havi gyűjtőbe másolás | 10 másolási rutin napzáráskor | napzar |
| BS-024 | DELETE→INSERT minta | Adatfrissítés = törlés + újraírás (nem inkrementális) | Minden modul |
| BS-025 | Dinamikus táblanevek | `BF{éévhh}`, `BT{éévhh}`, `DAYB{éévhh}` — havi/éves | Táblakezelés |

### 10.5 P3 — Szerver Szabályok

| # | Szabály | Logika | Forrás |
|---|---------|--------|--------|
| BS-026 | Haszon = árfolyamrés × bankjegy / 100 | Vétel: elszámolási - alkalmazott. Eladás: alkalmazott - elszámolási | haszon |
| BS-027 | Kedvezményes/normál elkülönítés | ARFE tábla ENGEDMENYTIPUS > 7 = kedvezményes | haszon |
| BS-028 | 3 profit-nézet | Napi árfolyamrés + MNB profit + átlag elszámolási | haszon |
| BS-029 | 150 pénztáras rendszer | Max 150 pénztár, 8 körzet, 54 csoport | Rendszer |
| BS-030 | MNB tábla teljes csere | `DELETE FROM MNB` → `INSERT INTO MNB` irodánként | mnbgyujto |
| BS-031 | Booking 3 tábla törlés | Tranzakciók + átadátvétel + évhónap törlés és újraépítés | booking |

---


---

## S12 11_COMPLIANCE_ES_JOGSZABALYI_KOVETELMENYEK

### 11.1 Pénzmosás Elleni Törvény (Pmt.)

| Kötelezettség | Implementáció | Modul |
|---------------|---------------|-------|
| **300.000 Ft feletti azonosítás** | BIGCTRL.DLL — automatikus trigger | VASARLAS, ELADAS |
| **Ügyfél azonosítás** | Személyi + okmány rögzítés + szkennelés | SENDOKMANY, UJSCANNER |
| **Napi limit nyilvántartás** | `UGYFEL.NAPIGONGYOLTFORINT` — zárásnál nullázódik | NAPZAR |
| **Éves maximum** | `evimax.dll` — éves összegkorlát figyelés | ugyfelcontrol |
| **Letiltás** | `letilt.dll` + `tiltasok.dll` — ügyfél/tranzakció blokkolás | ugyfelcontrol |
| **Okmány nyilvántartás** | `okmdisp.dll` — okmány megjelenítés/keresés | ugyfelcontrol |
| **Jogi személy kezelés** | JOGISZEMELY tábla + RemoteJogiLerendezes | VASARLAS |

### 11.2 ENSZ Szankciós Lista

| Kötelezettség | Implementáció | Modul |
|---------------|---------------|-------|
| **Terror lista egyeztetés** | XML letöltés → UNOLIST tábla → ügyfélnév egyeztetés | terror |
| **Terror napló** | `terrnaplo.dll` — egyezések naplózása | ugyfelcontrol |

### 11.3 MNB Jelentés

| Kötelezettség | Implementáció | Modul |
|---------------|---------------|-------|
| **Napi/havi MNB legyűjtés** | Irodánkénti adatgyűjtés → MNB tábla | mnbgyujto |
| **Eltérés jelentés** | SZAMITOTTZARO vs ZARO → MEGJEGYZES | server Unit7 |
| **Valutanem összesítés** | `SUM(VETELDARAB)`, `SUM(ELADASDARAB)` | server Unit17 |

### 11.4 NAV (Adóhatóság)

| Kötelezettség | Implementáció | Modul |
|---------------|---------------|-------|
| **NAV záras** | NAVZARO modul — zárási jelentés | VALUTA/NAVZARO |
| **XML bizonylat** | MakeXml → XML generálás | VASARLAS |
| **QR kód** | QRGENER, QRDEPUTY | VALUTA/QR modulok |

### 11.5 Rendőrségi Adatszolgáltatás

| Kötelezettség | Implementáció | Modul |
|---------------|---------------|-------|
| **Rendőrségi megkeresés** | 4 almodul — adatlekérdezés + keresés | police |

---


---

## S13 12_MIGRACIOS_KOCKAZATMATRIX

### 12.1 KRITIKUS Kockázatok

| # | Kockázat | Szint | Hatás | Teendő |
|---|----------|-------|-------|--------|
| R-001 | **Függvény-alapú árfolyamszámítás** | 🔴 KRITIKUS | Helytelen árfolyam = üzleti veszteség | Tesztekkel 100%-ban lefedni a képlet-kiértékelő logikát |
| R-002 | **Kezelési díj háromféle módja** | 🔴 KRITIKUS | Rossz díj = compliance hiba | Mindhárom mód unit tesztje, sávos mód edge case-ek |
| R-003 | **Bináris árfolyam fájl** | 🔴 KRITIKUS | Fájlformátum elvesztése = árfolyam hiba | Dokumentált formátum + dekóder tesztek |
| R-004 | **Devizanem sorrend eltérés** | 🔴 KRITIKUS | VALUTA vs ERTEKTAR eltérő sorrend = adatkeveredés | Egységes mapping, nem pozíció-alapú |
| R-005 | **JPY speciális kezelés** | 🟠 MAGAS | Helytelen JPY kerekítés = veszteség | Unit tesztek JPY-re |
| R-006 | **5 Ft-os kerekítés** | 🟠 MAGAS | Kerekítési hiba = ügyfélpanasz | Kerekito() pontos portolása |
| R-007 | **Bizonylat = jogszabályi dokumentum** | 🔴 KRITIKUS | Hiányzó/hibás mező = jogszabálysértés | Mezőlista törvényből, nem designból |

### 12.2 MAGAS Kockázatok

| # | Kockázat | Szint | Hatás | Teendő |
|---|----------|-------|-------|--------|
| R-008 | **Hardcoded FTP jelszavak** | 🟠 MAGAS | Biztonsági rés | Titkosított kommunikáció + secret management |
| R-009 | **SQL injection** | 🟠 MAGAS | Adatsérülés | Parametrizált query-k |
| R-010 | **DELETE FROM → INSERT minta** | 🟠 MAGAS | Adatvesztés tranzakció nélkül | Rollback-protected tranzakciók |
| R-011 | **Dinamikus táblanevek** | 🟠 MAGAS | SQL injection + séma kezelési bonyodalom | Egységes séma, partíciós táblák |
| R-012 | **Excel COM automatizáció** | 🟡 KÖZEPES | Szerver oldalon nem skálázódik | Apache POI vagy server-side export |
| R-013 | **Hardcoded útvonalak** | 🟠 MAGAS | Deploy rugalmatlanság | Konfigurációs fájl |
| R-014 | **WIN1250 kódolás** | 🟡 KÖZEPES | Magyar ékezetes karakterek | UTF-8 migráció |

### 12.3 Hardcoded Értékek (azonosított)

| Érték | Hely | Típus |
|-------|------|-------|
| `c:\valuta\` | VALUTA | Útvonal |
| `c:\ertektar\` | ERTEKTAR | Útvonal |
| `c:\ertektar\bin\` | ERTEKTAR DLL-ek | Útvonal |
| `c:\receptor\database\` | Szerver | Útvonal |
| `185.43.207.99` | terror | IP cím |
| `klc+45%` | atadvet | FTP jelszó |
| `ebc-10%` | atadvet | FTP felhasználó |
| `21100` | atadvet | FTP port |
| `0.001` | VASARLAS | Kerekítési konstans |
| `300000` | BIGCTRL | AML limit (Ft) |
| `5` | HARDWARE | SHK napi limit |

---


---

## S14 13_OSSZEFOGLALAS_ES_JAVASLATOK

### 13.1 A Rendszer Lényege (Zoltán szavaival)

A pénztári program **minden adat forrása**. A ring-modell:

```
P0 MAG: Valutaváltás + Értéktár + Árfolyamkészítés
    ↓ adatot termel
P1 RING 1: Pénztárak közti mozgás + Készletezés
    ↓ mozgatja a készletet
P2 RING 2: Értéktár↔Pénztár + Értéktár↔Bank
    ↓ dokumentálja és archiválja
P3 RING 3: Szerver összesít, jelent, ellenőriz
```

### 13.2 Migrációs Prioritások (Core-ból Kifelé)

| Fázis | Mit | Miért | Komplexitás |
|-------|-----|-------|-------------|
| **1. P0-A** | Valutaváltás (vétel/eladás/stornó) | Üzlet nem működik nélküle | 🔴 Magas (képletek, kerekítés, AML) |
| **1. P0-B** | Árfolyamkészítés (spreadsheet logika) | Nincs árfolyam = nincs tranzakció | 🔴 Nagyon magas (egyedi parser) |
| **1. P0-C** | Napi záras | Jogszabályi kötelezettség | 🟠 Közepes-magas |
| **2. P1** | Átadás/átvétel + készletezés | Pénztárak közti forgalom | 🟠 Közepes |
| **3. P2** | Értéktári záras + bank mozgás | Dokumentálás, archiválás | 🟠 Közepes |
| **4. P3** | Szerver admin, MNB, booking, haszon | Riportok, hatósági | 🟡 Közepes (sok modul, de ismétlődő minták) |

### 13.3 Kulcs Architekturális Felismerések

1. **A rendszer extrém modularitása** — 60+ DLL az értéktárban, 36 a szerveren. Ez természetesen leképezhető microservice-ekre vagy Spring modulokra.

2. **Az árfolyamkészítő egy beépített spreadsheet** — saját képletnyelvvel, cellaformázással. Ez a legkomplexebb modul a migráláshoz.

3. **Bináris fájl kommunikáció** — az árfolyam nem DB-ben, hanem bináris fájlban utazik (45 byte/devizanem). A migráció REST API-ra cserélheti.

4. **DELETE→INSERT minta mindenhol** — az adat mindig "friss számolt", nem inkrementális. Ez egyszerűsíthető, de a szemantikát meg kell őrizni.

5. **Devizanem sorrend eltérés** — VALUTA (abc) vs ERTEKTAR (EUR-vezérelt). Pozíció-alapú mapping helyett kód-alapú kell.

6. **150 pénztáras rendszer, 8 körzet, 54 csoport** — a méretezés fix, de a migráció dinamikusra cserélheti.

7. **Compliance logika szétszórtan** — AML/KYC/terror lista több rendszerben is jelen van (VALUTA, ERTEKTAR, SZERVER). Egységesítés szükséges.

### 13.4 Számok

| Metrika | Érték |
|---------|-------|
| P0 MAG modulok | ~15 (vétel, eladás, stornó, napzar, 5×címlet, árfolyam, irarfoly) |
| P1 RING 1 modulok | ~18 (atadvet + készlet + címlet + kontrol) |
| P2 RING 2 modulok | ~20 (záras + könyvelés + dokumentálás) |
| P3 RING 3 modulok | ~60 (szerver admin, MNB, booking, haszon, ügyfélkontrol, terror, police) |
| Azonosított DB táblák | 50+ (statikus + dinamikus) |
| Üzleti szabályok | 31 azonosított (BS-001 → BS-031) |
| Kockázatok | 14 azonosított (R-001 → R-014) |
| Compliance területek | 5 (Pmt., ENSZ, MNB, NAV, Rendőrség) |
| Hardcoded értékek | 11+ |
| Devizanemek | 27 |
| Max pénztárak | 150 |
| Max körzetek | 8 |
| Max csoportok | 54 |

---

> **Dokumentum vége**
> Készítette: Eszter (Controller Chief), 2026-04-04
> Referenciák: Junior core-analysis, Eszter delphi-full-analysis
> Forrásbázis: `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\`
