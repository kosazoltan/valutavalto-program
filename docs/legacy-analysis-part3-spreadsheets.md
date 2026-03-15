# Legacy Drive - Tablazatok es adatfajlok elemzese (Part 3)

> Keszult: 2026-03-15 | Forras: `docs/legacy-drive/` konyvtar

## Osszefoglalas

A legacy drive **~20 egyedi spreadsheet/adatfajlt** tartalmaz (sok duplikat kulonbozo mappakban). 7 db `.xlsx` fajl titkositott (Google Sheets OLE2 encrypted export), 2 db `.ods` fajl szinten titkositott tartalommal rendelkezik. A tobbi sikeresen feldolgozva.

---

## 1. Forgalmi jelentes (Forgalom 2024.09.xlsx)

**Fajl:** `Dokumentumok/Forgalom 2024.09.xlsx`
**Formatum:** XLSX (OpenXML), 1 munkalap ("Munka1"), 1305 sor, 9 oszlop

### Struktura

| Oszlop | Tartalom |
|--------|----------|
| B | VALUTA NEME (ISO 3-betus kod) |
| C | VALUTA VETEL - OSSZEGE (deviza) |
| D | VALUTA VETEL - FT ERTEKE |
| E | VALUTA ELADAS - OSSZEGE (deviza) |
| F | VALUTA ELADAS - KESZPENZES (Ft) |
| G | VALUTA ELADAS - BANKARTYAS (Ft) |
| H | VALUTA ATADAS (deviza) |
| I | VALUTA ATVETEL (deviza) |

### Hierarchia
```
EXCLUSIVE BEST CHANGE KFT 2024 SZEPTEMBER HAVI FORGALMA
  SZEKSZARDI KORZET
    10. SZEKSZARD ERTEKTAR
      AUD, BAM, BGN, CAD, CHF, CZK, EUR, GBP, HUF, ILS, JPY, NZD, PLN, RON, RSD, TRY, USD
      OSSZESEN: [vetel Ft] [eladas keszpenzes] [eladas bankartyas]
    11. BONYHAD
      ...
    12. SZEKSZARD BELVAROS
      ...
  [TOVABBI KORZETEK...]

  Best Change Kft Osszesitese:
    [valutankent aggregalt]
    O S S Z E S E N: vetel=5,308,988,190 Ft | eladas=2,469,551,960 Ft | bankartyas=653,224,100 Ft
```

### Kezelt valutak (24 db)
AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, EUR, GBP, HUF, ILS, JPY, MXN, NZD, PLN, RON, RSD, RUB, THB, TRY, USD + (DKK, HRK, NOK, SEK, UAH a keszlet-jelento formaban)

### Uzleti logika
- **Vetel** (V): ugyfel ad devizat, kapja a Ft-ot → vetel osszege (deviza) + Ft erteke
- **Eladas** (E): ugyfel vesz devizat, fizet Ft-ban → eladas osszege (deviza) + keszpenzes/bankartyas bontas
- **Atadas/Atvetel**: penztarak kozotti bankjegy-mozgas (nem ugyfeltranzakcio)
- Korzeti + valtohaz szintu aggregacio

---

## 2. Havi atadas-atvetel kimutatas (Havi atadas-atvetel kimutatas.xlsx)

**Fajl:** `Dokumentumok/Havi atadas-atvetel kimutatas.xlsx`
**Formatum:** XLSX, 1 munkalap ("Munka1"), 1839 sor, 6 oszlop

### Struktura

| Oszlop | Tartalom |
|--------|----------|
| B | VALUTA NEME |
| C | ATADOTT BANKJEGY (deviza osszeg) |
| D | HOVA LETT ATUTALVA (penztar nev / bank) |
| E | ATVETT BANKJEGY (deviza osszeg) |
| F | HONNAN LETT ATUTALVA (penztar nev / bank) |

### Celallomasyok
- Penztarak kozotti: `"11. BONYHAD"`, `"12. SZEKSZARD BELVAROS"`, stb.
- Bankba: `"ERB BANK"`, `"FRB BANK"`, `"RB BANK"`, `"TRB BANK"`
- Specialis: `"toblet-hiany penztar"` (keszletelteres rendezese)

### Tobb ceg, tobb korzet
- **Best Change** sheet: fo valutavalto ceg
- **East Change** sheet: masodik ceg
- **Pannon Change** sheet: harmadik ceg
- **Expressz Zalog** sheet: zalogos korzetr

---

## 3. Keszlet jelentes (Keszlet 2024 02 ho.xlsx)

**Fajl:** `Segedanyagok Valuta/Keszlet 2024 02 ho.xlsx`
**Formatum:** XLSX, 4 munkalap (Best Change, East Change, Pannon Change, Expressz Zalog)

### Struktura

| Oszlop | Tartalom |
|--------|----------|
| B | VALUTA NEME |
| C | NYITO KESZLET (deviza) |
| D | EGYENLEG ADAS-VETEL (deviza) |
| E | EGYENLEG ATADAS-ATVETEL (deviza) |
| F | ZARO KESZLET (deviza) |

### Keplet
```
ZARO KESZLET = NYITO KESZLET + ADAS-VETEL EGYENLEG + ATADAS-ATVETEL EGYENLEG
```

### Pelda
```
BONYHAD / EUR: nyito=6952, adas-vetel=+109623, atadas-atvetel=-108100, zaro=8475
BONYHAD / HUF: nyito=8,154,230, adas-vetel=-49,984,435, atadas-atvetel=+45,311,320, zaro=3,481,115
```

---

## 4. WU, kezelesi koltseg, AFA (WU e ker kktg afa 2024 02 ho.xlsx)

**Fajl:** `Segedanyagok Valuta/WU e ker kktg afa 2024 02 ho.xlsx`
**Formatum:** XLSX, 3 munkalap (Best Change: 2359 sor/24 oszlop, Expressz: 585 sor, Munka1)

### Struktura (24 oszlop!)

| Oszlopok | Tartalom |
|----------|----------|
| B | DATUM (napi bontasban) |
| C-D | WESTERN UNION NYITO (USD + HUF) |
| E-F | WESTERN UNION BEVETEL (USD + HUF) |
| G-H | WESTERN UNION KIADAS (USD + HUF) |
| I-J | WESTERN UNION ZARO (USD + HUF) |
| K | KEZELESI KOLTSEG - BEFIZETES ERTEKTARNAK |
| L | KEZELESI KOLTSEG - BEVETEL UGYFELTOL |
| M | KEZELESI KOLTSEG - ATVETEL PENZTARTOL |
| N | ELEKTRONIKUS KERESKEDES - NYITO |
| O | ELEKTRONIKUS KERESKEDES - MATRICA |
| P | ELEKTRONIKUS KERESKEDES - TELEFON |
| Q | ELEKTRONIKUS KERESKEDES - ATADAS |
| R | ELEKTRONIKUS KERESKEDES - ATVETEL |
| S | ELEKTRONIKUS KERESKEDES - ZARO |
| T | AFA VISSZATERITES - NYITO |
| U | AFA VISSZATERITES - BEVETEL BANKTOL |
| V | AFA VISSZATERITES - KIADAS PENZTARNAK |
| W | AFA VISSZATERITES - VISSZATERITES |
| X | AFA VISSZATERITES - ZARO |

### Uzleti logika
- **Western Union**: napi USD+HUF keszlet kovetes, nyito-bevetel-kiadas-zaro egyenleg
- **Kezelesi koltseg**: napi tranzakcios dijak nyilvantartasa
- **Elektronikus kereskedes**: matricak es telefonkartya keszlet
- **AFA visszaterites**: TAX FREE keszlet/forgalom

---

## 5. Banki import CSV (Banki import TXT fajl ugyfeles ZALOG ZA20241029.csv)

**Fajl:** `Dokumentumok/Banki import TXT fajl ugyfeles ZALOG ZA20241029.csv`
**Formatum:** CSV, pontosvesszo (`;`) elvalaszto, CP1250 kodolas, 30 sor

### Oszlopok (32 db!)

```
1.  ugyfel tipus (ceg, termeszetes szemely)
2.  uzlethelyiseg azonosito
3.  tranzakcio datuma (EEEE.HH.NN)
4.  osszeg (deviza)
5.  valutanem (ISO 3)
6.  eladas/vetel
7.  alkalmazott arfolyam
8.  tranzakcio forint osszege
9.  tranzakcio egyedi azonositoja (V/E + penztarszam + sorszam)
10. csaladi es utonev
11. szuletesi csaladi es utonev
12. szuletesi datum (EEEE.HH.NN)
13. szuletesi hely
14. anyja neve
15. allampolgarsaga (ISO 2)
16. azonosito okmany tipusa (SZIG/UTLEVEL/JOGOSITVANY)
17. azonosito okmany szama
18. allando lakcim telepules
19. allando teljes lakcim
20-25. ceges ugyfel adatai (nev, orszag, szekhely, cim, TEAOR, cegjegyzekszam)
26-32. ceg neveben eljaro szemely adatai
```

### Tranzakcio azonosito formatum
- **V** prefix = vetel (pl. `V151005694`)
- **E** prefix = eladas (pl. `E151001558`)
- Kozepe: penztarazonosito (3 szamjegy)
- Vege: sorszam

### Fejlec szerkezet
```
;tranzakcio adatai;;;;;;;;termeszetes szemely ugyfelet azonosito adatok;;;;;;;;;;ceges ugyfel adatai;;;;;;ceg neveben eljaro szemely adatai;;;;;;;
```
Elso sor ures mezo-val kezdodik (`;` az elejen) = csoportositasra hasznalja.

---

## 6. Ugyfeles jelentes CSV (Ugyfeles jelentes_ BE20241026.csv)

**Fajl:** `Dokumentumok/Ugyfeles jelentes_ BE20241026.csv`
**Formatum:** CSV, pontosvesszo (`;`) elvalaszto, CP1250 kodolas, 139 sor

**Azonos szerkezet** mint a banki import CSV (ld. fent). A kulonbseg:
- `BE` prefix a fajlnevben = Bekescsaba korzet
- `ZA` prefix = Zalog korzet
- A fajlnev tartalmazza a datumot: `20241026`
- Tobb uzlethelyiseg adatai egyetlen fajlban

---

## 7. P91.TXT - Legacy tranzakcios bizonylat lista

**Fajl:** `Dokumentumok/P91.TXT`
**Formatum:** fix szelessegu szoveges fajl, UTF-8 BOM, 402 sor

### Formatum
```
                 A 2024.02.08 es 2024.02.14 kozotti bizonylatok.

-------------------------------------------------------------------------------
    Datum    Ido     Blokk   Valuta osszege    Ft. osszege   Kedv.arf  Arfolyam
-------------------------------------------------------------------------------
 2024.02.08 08:38  V091100773    EUR     100          38030               38 030
 2024.02.08 09:00  V091100774    EUR    3000        1141350               38 045
             (NAZARETH ETHAN NIKHIL    , azonosito: -                   )
```

### Mezo-definiciok
| Mezo | Pozicio (approx) | Tartalom |
|------|-------------------|----------|
| Datum | 1-11 | EEEE.HH.NN |
| Ido | 12-17 | OO:PP |
| Blokk | 19-30 | V/E + penztarszam + sorszam |
| Valuta | 33-36 | ISO 3-betus kod |
| Osszege | 37-44 | deviza osszeg |
| Ft. osszege | 45-58 | forint osszeg |
| Kedv.arf | 59-68 | kedvezmenyes arfolyam (ha van) |
| Arfolyam | 69-76 | alkalmazott arfolyam (szokozzel: "38 030") |

### Azonositott szemely sor
Ha az ugyfel azonositva lett (>300.000 Ft tranzakcio), kovetkezo sorban:
```
             (UGYFEL NEVE                , azonosito: -                   )
```

### Arfolyam formatum
- Egesz szamkent, szokozzel tagolva: `38 030` (= 380.30 Ft/EUR)
- JPY eseten 100 egysegre: `265 99` (= 2.6599 Ft/JPY)

---

## 8. Forgalmi es keszlet jelentes (ZM241024.txt)

**Fajl:** `Dokumentumok/Forgalmi es keszlet jelentes ZALOG ZM241024.txt`
**Formatum:** strukturalt szoveges fajl, CP1250 kodolas, 1044 sor

### Szekciok

#### 8.1. Fejlec
```
# EXPRESSZ EKSZERHAZ - 2024 Oktober 24
BEGIN
TNAP	2024-10-25
# EXPRESSZ EKSZERHAZ
PV_AZONOSITO	A0AYTS
```

#### 8.2. JELENTES PENZTARALLOMANY (cimletezes)
```
JELENTES PENZTARALLOMANY
UZLETHELYISEG_AZONOSITO	1551
ERTEKNAP	-1
IDOPONT	 9:13
KP	BGN	20	14        ← valuta / cimlet / darabszam
KP	BGN	10	1
KP	EUR	100	39
KP	EUR	50	27
KP	HUF	20000	2
KP	HUF	10000	424
JELENTES END
```

**Formatum:** `KP\t{VALUTA}\t{CIMLET}\t{DARAB}`

Minden uzlethelyiseg kulon blokk, `JELENTES PENZTARALLOMANY` / `JELENTES END` kozott.

#### 8.3. JELENTES UGYFELFORGALOM V3
```
JELENTES UGYFELFORGALOM V3
UZLETHELYISEG_AZONOSITO	1588
ERTEKNAP	-1
EUR	2844	1305	0	0	0		0
HUF	755035	1223000	0	0	0		17795
PLN	0	130	0	0	0		0
JELENTES END
```

**Formatum:** `{VALUTA}\t{ertek1}\t{ertek2}\t{ertek3}\t{ertek4}\t{ertek5}\t\t{ertek6}`

Feltetelezett oszlopok: valuta | vetel | eladas | atadas | atvetel | ? | | kezelesi_koltseg

#### 8.4. Lezaras
```
END
```

---

## 9. Terrorlista / Szankcios lista (Terrorlista2008.txt)

**Fajl:** `Dokumentumok/Terrorlista2008.txt` (es root-ban is `Terrorlista2008.txt`)
**Formatum:** UTF-8 BOM, 5366 sor, ~190 KB

### Struktura
```
Exclusive Cegcsoport		2008

Az Europai Unio altal elrendelt penzugyi es vagyoni korlatozo intezkedesek ala vont szemelyek, szervezetek.

 Sayed Ghias
 Sayed Ghiasuddin Sayed Ghousuddin
   El Para (combat name) 1098
ABAS Mohamad Nasir   1033
   Abdul Azis 1066
Abdul Baseer Abdul Qadeer  706
```

### Formatum-elemek
- **Fo bejegyzes**: nev bal margon, szam a sor vegen (azonosito)
- **Alias/alternativ nev**: behuzassal (`   `), szam a sor vegen
- **Szam**: EU szankcios lista referencia-szam
- **Tobbnyelvuseg**: tartalmaz cirill, gorog, arab atirasos neveket is
- Az eredeti 2008-as EU szankcios listabol keszult

---

## 10. Heti tranzakcios adatszolgaltatas (minta)

**Fajl:** `Regi-Valuta-program/SZERVER/fejleszt/senddata/penzvallo heti tranzakcios adatszolgaltatas (minta).xlsx`
**Formatum:** XLSX, 5 sor (2 fejlec + 2 pelda + 1 leirasor)

### Oszlopok (29 db) - MNB felugyeleti jelentesformatum

```
TRANZAKCIO ADATAI:
1.  tranzakcio datuma (eeee.hh.nn.)
2.  osszeg (csak szam)
3.  valutanem (3 betus, nem lehet HUF)
4.  eladas/vetel ("eladas" vagy "vetel")
5.  alkalmazott arfolyam (szam, JPY: 100 egysegre)
6.  tranzakcio forintosszege (szam)
7.  tranzakcio egyedi azonositoja (szabadszoveges)
8.  penzvallo ugynok megnevezese
9.  penzvaltas helye (cim)

TERMESZETES SZEMELY ADATAI:
10. csaladi es utonev
11. szuletesi csaladi es utonev
12. szuletesi datum
13. szuletesi hely
14. anyja neve
15. allampolgarsaga (ISO orszagkod)
16. azonosito okmany tipusa (utlevel / SZIG / jogositvany)
17. azonosito okmany szama

CEGES UGYFEL:
18. ceg neve
19. bejegyzes orszaga (ISO)
20. szekhely
21. cegjegyzekszam

CEG NEVEBEN ELJARO:
22-29. (azonos mezok mint termeszetes szemely)
```

### Megjegyzesek
- Ez a **felugyeleti (MNB/rendorseg) heti jelentesformat**
- Minden 300.000 Ft feletti tranzakciot kell jelenteni
- A banki import CSV (ZA fajl) ennek bovitett valtozata (+ uzlethelyiseg azonosito)

---

## 11. Terrorista gyanussag naplo (minta.xlsx)

**Fajl:** `Regi-Valuta-program/SZERVER/fejleszt/ugyfelcontrol/minta.xlsx`
**Formatum:** XLSX, 7 sor

### Oszlopok
```
PENZTAR SZAMA | PENZTAR MEGNEVEZESE | DATUM | IDO | A VIZSGALT UGYFEL NEVE | ENGEDELYEZES (IGEN/NEM) | ENGEDELYEZO NEVE
```

Pelda:
```
143 | NYIREGYHAZA, PIROSHAZ | 2022.12.31 | 18:41:33 | ABAEDEKJTR DFLFLLLG | IGEN | VOROSMARTY VITEZ BENEDEK
```

---

## 12. Delphi Licence arak (Delphi_Licence_arak.xlsx)

**Fajl:** `Delphi_Licence_arak.xlsx`
**Formatum:** XLSX, 17 sor, 4 oszlop

Delphi 12 fejlesztokornyezet licence-arak osszehasonlitasa (nem uzleti adat, csak beszerzesi informacio).

---

## 13. Arfolyam karbantarto hibalista

**Fajl:** `Arfolyam_karbantarto_hibalista.txt`
**Formatum:** UTF-8 szoveg

Bug report az arfolyamkezelo feluleten talalatos hibakrol:
- Sor masolasakor helytelen lapreferencia a kepletekben ($LapT01 → $LapT3)
- Inaktiv valutak megjelenitese problema
- Kerekites matematikai szabaly szerinti javitasa
- Log penztarankent kerelmezese
- Billentyunavigacio cellak kozott
- Currency mezo HUF egesz szam

---

## 14. Titkositott (nem olvashatoak) fajlok

Az alabbi fajlok OLE2 encrypted formatumban vannak, jelszo nelkul nem olvashatoak:

| Fajl | Feltelezheto tartalom |
|------|----------------------|
| AcAtlagarf.xlsx | Atlagos szamolt arfolyam |
| Atlagarfolyam.xlsx | Atlagarfolyam szamitas |
| Afa, kktg 2024 10 09 ho.xlsx | AFA es kezelesi koltseg (okt) |
| EXZ haszon pt 202409 ho.xlsx | Haszon penztarankent |
| KEZD2410.xlsx | Nyitokeszlet 2024 oktober |
| Keszletek 2024 09 ho.xlsx | Keszletek szeptemberben |
| Zalog kk 202409 ho.xlsx | Zalog kezelesi koltseg |
| Expressz Ekszerhaz forgalom 202409 ho.ods | Expressz havi forgalom |
| Forgalmak 2015-2024.ods | Tobbeves forgalmi adat |

---

## Osszefoglalo tablazat: adatformatumok

| Funkció | Format | Separator | Encoding | Azonosító formátum |
|---------|--------|-----------|----------|-------------------|
| Havi forgalom | XLSX | - | UTF-8 | Körzet > Pénztár > Valuta |
| Átadás-átvétel | XLSX | - | UTF-8 | Pénztárnév / Bank |
| Készlet | XLSX | - | UTF-8 | Nyitó+Egyenleg=Záró |
| WU/ÁFA/Kktg | XLSX | - | UTF-8 | Napi bontás, pénztáranként |
| Banki import CSV | CSV | `;` | CP1250 | V/E + 3dig pénztár + sorszám |
| Ügyfeles jelentés | CSV | `;` | CP1250 | Azonos mint banki import |
| Pénztári bizonylat | TXT fixed | pozíció | UTF-8 BOM | V/E + pénztárszám + sorszám |
| Címletezés/készlet | TXT tab | `\t` | CP1250 | UZLETHELYISEG_AZONOSITO |
| Terrorlista | TXT | nincs | UTF-8 BOM | Név + EU referenciaszám |
| Heti MNB jelentés | XLSX | - | UTF-8 | 29 oszlop, szabvány |

---

## Kulcs uzleti kovetkeztetesek az uj rendszerhez

### 1. Multi-entity szerkezet
A rendszer 4 jogi szemelyt kezel:
- **Exclusive Best Change Kft** (fo valutavalto)
- **Exclusive East Change Kft**
- **Exclusive Pannon Change Kft**
- **Expressz Ekszerhaz** (zalog + valutavaltas)

### 2. Penztar hierarchia
```
Ceg → Korzet → Penztar (szamozott: 10, 11, 12, ... 151, 152, ...)
```
+ Specialis celok: ertektar (10), bankok (ERB, FRB, RB, TRB), "toblet-hiany penztar"

### 3. Jelento-kotelezetsegek
- **Napi**: penztarallomany cimletezessel (ZM format)
- **Havi**: forgalom, keszlet, atadas-atvetel, kezelesi koltseg, AFA
- **Heti**: MNB tranzakcios jelentes (>300k Ft ugyfelek)
- **Eseti**: terrorlista-ellenorzes naplo

### 4. Arfolyam tarolasi formatum
- Egesz szam, szokozzel tagolva: `38 030` = 380.30 Ft
- JPY: 100 egysegre vonatkozo arfolyam
- Kulon vetel/eladas arfolyam (a CSV-kben lathato: vetelnel alacsonyabb, eladasnal magasabb)

### 5. Tranzakcio-azonosito rendszer
```
[V|E] + [penztarszam 3 digit] + [sorszam 6 digit]
Pelda: V091100773 = Vetel, 091-es penztar, 100773. sorszam
       E151001558 = Eladas, 151-es penztar, 001558. sorszam
```

### 6. Keszletkezeles keplete
```
Záró készlet = Nyitó készlet + (Vétel - Eladás) + (Átvétel - Átadás)
```
Minden valutanemre kulon, minden penztarra kulon szamolva.

### 7. Import/export interfeszek
- **Banki CSV export**: `;` elvalasztos, CP1250, MNB szabvany oszlopokkal
- **ZM format**: strukturalt szoveges, TAB elvalaszto, blokkos felepites (BEGIN/END)
- **P91 format**: fix szelessegu, nyomtatasi/megjelenites cel
