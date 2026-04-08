---
type: session-log
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Legacy Szerver Uzleti Logika"
load: on-demand
---

# Legacy Szerver Üzleti Logika
> Agent-optimalizált — számítási szabályok, küszöbértékek, validációk


---

## S1 1_DEVIZANEM_RENDSZER

### Fix 27 + HUF
```
Index 0: (üres/HUF)
Index 1-27: AUD BAM BGN BRL CAD CHF CNY CZK DKK EUR GBP HRK HUF ILS JPY MXN NOK NZD PLN RON RSD RUB SEK THB TRY UAH USD
```
- A modern rendszer dinamikus Currency entity-t használ → **OK, de a sorrend/indexelés nem garantált**
- Legacy: integer index alapú tömb → Modern: String currencyCode alapú

### Árfolyam típusok
| Mező | Jelentés | Modern |
|------|----------|--------|
| VETELIARFOLYAM | Vételi árfolyam (mennyit fizetünk) | `buyRate` |
| ELADASIARFOLYAM | Eladási árfolyam (mennyiért adjuk) | `sellRate` |
| ELSZAMOLASIARFOLYAM | Elszámolási árfolyam (belső, MNB közeli) | `officialRate` |


---

## S2 2_IRODA_BRANCH_RENDSZER

### Firebird IRODAK tábla mezők
| Mező | Típus | Jelentés | Modern |
|------|-------|----------|--------|
| UZLET | int | Iroda szám (1-180) | `branch.code` |
| CEGBETU | string | Cégcsoport betűjel (B/P/E/Z) | `company.code` |
| VAROS | string | Város | `branch.city` |
| BOLTNEV | string | Bolt név | `branch.name` |
| STATUS | string | Típus | `branch.type` |
| BANKKOD | string | Bank azonosító | `branch.bankCode` |
| ERTEKTAR | int | Értéktár (körzet) szám (1-9) | `branch.regionId` |
| SUNDAYCLOSE | string | 'X' ha vasárnap zárva | `branch.sundayClosed` |
| CLOSED | string | 'X' ha véglegesen bezárt | `branch.active` (negált) |

### Körzet → Értéktár mapping
```
Körzet 1-9 → Értéktár 1-9
Egy értéktár több irodát fed le
Értéktár saját cégbetű a legutolsó iroda cégbetűje
```


---

## S3 3_NAPI_KONYV_DAYBOOK_RENDSZER

### Logika
- Hónap első napján `DAYB{ÉÉHO}` tábla jön létre (pl. `DAYB2604` = 2026 április)
- Minden irodához egy sor, 31 nap oszlop (N1..N31)
- Oszlop értékek:
  - `' '` (szóköz) = adat nem érkezett
  - `'X'` = zárva (vasárnap, ünnep, bezárt)
  - `'1'` (vagy más) = adat beérkezett
- `TegnapControl` ellenőrzi: van-e üres (`' '`) mező az előző napra

### Ünnepnapok (hardcoded)
```
Január 1
Március 15
Május 1
Augusztus 20
Október 23
November 1
December 25, 26
```

### Modern megfelelő
`DailySession` entity — `status` mező jelzi a napzárás állapotát. A DayBook szerver-szintű összefoglaló nézet — a modern rendszerben query-vel oldható meg (`SELECT branch_id, closing_date, status FROM daily_session WHERE ...`).


---

## S4 4_FORGALOM_OSSZESITES_UNIT29PAS

### Változó struktúra per deviza
```pascal
// Nyitó/záró
_uny[0..27]: deviza nyitó (egységben)
_uz[0..27]:  deviza záró
_hny[0..27]: HUF nyitó
_hz[0..27]:  HUF záró
_any[0..27]: ÁFA nyitó
_az[0..27]:  ÁFA záró

// Mozgások (deviza)
_ubg[0..27]: beérkezett gazdálkodásból
_ubp[0..27]: beérkezett pénztárból
_ubu[0..27]: beérkezett ügyféltől
_ukg[0..27]: kimenő gazdálkodásba
_ukp[0..27]: kimenő pénztárba
_uku[0..27]: kimenő ügyfélnek

// Mozgások (HUF)
_hbg, _hbp, _hbu: HUF beérkezett
_hkg, _hkp, _hku: HUF kimenő

// Mozgások (ÁFA)
_abg, _abp: ÁFA beérkezett
_akg, _akp, _aku: ÁFA kimenő
```

### Készlet képlet
```
záró = nyitó + beérkezett_összesen - kimenő_összesen
záró = nyitó + (bg + bp + bu) - (kg + kp + ku)
```

### Összesítés szintek
1. **Iroda szint**: Egy pénztár napi forgalma
2. **Körzet szint**: `_kvett[1..9, 0..27]` — körzetenként összesített
3. **Cég szint**: `_kkvett[1..4, 0..27]` — cégcsoportonként összesített
4. **Globális**: `_sumvett[0..27]` — összes

### Modern megfelelő
A modern rendszer real-time query-kkel dolgozik:
```sql
SELECT currency_code, SUM(foreign_amount) FROM transaction 
WHERE branch_id IN (SELECT id FROM branch WHERE region_id = ?) 
AND created_at BETWEEN ? AND ?
GROUP BY currency_code
```


---

## S5 5_BIZONYLAT_RENDSZER

### Firebird táblák
| Tábla | Tartalom |
|-------|----------|
| BLOKKFEJ | Bizonylat fejléc: sorszám, dátum, iroda, típus |
| BLOKKTÉTEL | Bizonylat tétel: devizanem, összeg, árfolyam, irány |

### Bizonylat típusok
- Normál vétel/eladás
- Sztornó
- WU
- Bank

### Modern megfelelő
`Receipt`, `Transaction` entity-k — teljesen implementálva


---

## S6 6_CIMLET_KEZELES

### HUF címletek (14 db)
```
20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
```

### Logika
- Napzárásnál minden iroda jelenti a címlet-összetételt
- Szerver összesíti körzetenként és cég szinten
- `_scim[1..14]` tömb tárolja

### Modern megfelelő
`DenominationService`, `BanknoteBreakdownService` — implementálva


---

## S7 7_HASZON_SZAMITAS

### Legacy képlet (haszon/)
```
haszon = (eladott * eladási_árfolyam) - (eladott * elszámolási_árfolyam)
       + (vett * elszámolási_árfolyam) - (vett * vételi_árfolyam)
```

Egyszerűsítve:
```
haszon = eladott * (eladási - elszámolási) + vett * (elszámolási - vételi)
```

### Modern megfelelő
`DecadeReportService` használja — **ELLENŐRIZENDŐ** hogy a képlet egyezik-e


---

## S8 8_KEZELESI_DIJ_KEZDIJ

### Legacy logika
- Devizanemenként beállítható díj %
- Küszöbérték: alapdíj alatt nincs díj
- Cégcsoportonként eltérhet

### Modern megfelelő
`HandlingFeeService`, `HandlingFeeDecadeService` — implementálva


---

## S9 9_WESTERN_UNION_AFA

### Legacy logika (unit29.pas)
- WU tranzakciók külön ÁFA nyilvántartás
- `WuniAfaBerogzites`: WU ÁFA rögzítés
- `WuniNullazas`: WU ÁFA nullázás (havi)
- `GetWuniNyitasZaras`: WU nyitó/záró lekérés

### Modern megfelelő
`WesternUnionService` — ÁFA kezelés ellenőrizendő


---

## S10 10_VALIDACIOS_SZABALYOK

### TegnapControl (bejött-e minden zárás)
```
FOR EACH iroda IN daybook:
  IF napstatus = '' (üres):
    → HIÁNY: iroda nem zárta a napot
    → _missPenztar[] tömbbe kerül
```

### AdatControl (eltérés ellenőrzés)
```
FOR EACH sor IN MNB tábla:
  IF MEGJEGYZES <> 'OK' AND STATUS <> 'X':
    eltérés = ZARO - SZAMITOTTZARO
    → INSERT INTO HIBAK (IRODA, IRODANEV, VALUTANEM, ELTERES)
```

### Modern megfelelő
- `DailyClosingService.checkNavControlAndReport()` — részben
- `NavClosingDiscrepancyService.validateNavClosingAmount()` — 1:1


---

## S11 11_PENZTARKOZI_KONTROLL_INTERPTCONTROL

### Logika
- Pénztárak közötti mozgások egyeztetése
- Ha A iroda küld B irodának → mindkettőnél kell szerepelnie
- Eltérés → HIBAK

### Modern megfelelő
`TransferService` — real-time validáció


---

## S12 12_FTP_KOMMUNIKACIO

### Legacy flow
```
1. Pénztár → FTP szerver (C:\RECEPTOR\IRODA{xxx}\)
2. Szerver FTP-ről olvassa a .DAT fájlokat
3. Feldolgozza → Firebird DB-be
4. Árfolyamokat visszaírja → FTP
5. Pénztár letölti az új árfolyamokat
```

### Fájl típusok
- `NR*.DAT` — napi árfolyam
- Forgalom fájlok
- Címlet fájlok
- WU fájlok

### Modern megfelelő
REST API + SyncEngine (30s polling) — **TELJESEN KIVÁLTVA**
