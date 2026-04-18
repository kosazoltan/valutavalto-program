---
type: company-baseline
scope: public-company-data
version: 2026-04-09
format: structured-lookup
description: "Public-source baseline for BestChange / Exclusive Best Change company rules, branch topology and public conditions"
---

# BestChange Company Public Baseline

> Cel: a ceg publikus, webrol bizonyithato adataibol olyan strukturalt baseline keszitese, amely szervezeti, telephelyi, kereskedelmi es compliance parameterkent felhasznalhato a programtervezesben.
> Megjegyzes: a `bestchange.hu` kozvetlen lekerdezese certificate name mismatch hibaba futott; a nyilvanosan elerheto, tenylegesen kiszolgalt tartalom a vizsgalat idejen fo forraskent az `excbestchange.hu` domainen volt igazolhato.

---

## S1 FORRASKOR ES BIZONYTASI SZINT

### Kozvetlenul elert forrasok

1. `https://www.bestchange.hu/robots.txt`
   - a domain el, de csak minimalis publikus tartalom igazolodott

2. `https://www.excbestchange.hu/hu/`
   - brand-homepage

3. `https://www.excbestchange.hu/hu/impresszum`
   - cegadatok, partneri es engedelyezesi allitasok

4. `https://www.excbestchange.hu/hu/egyedi-arfolyam`
   - publikus egyedi arfolyam szabalyok

5. `https://www.excbestchange.hu/hu/penzkuldes`
   - publikus penzkuldesi szabalyok

6. `https://www.excbestchange.hu/uzletek.xlsx`
   - a fiokkereso altal hasznalt publikus branch feed

7. `https://www.excbestchange.hu/legal/exc_best_change_adatkezelesi_tajekoztato.pdf`
   - ceges adatkezelesi tajekoztato

### Megbizhatosagi megjegyzes

- `bestchange.hu` direkt HTML-lekerese certificate mismatch miatt nem volt megbizhatoan feldolgozhato;
- `excbestchange.hu` tobb publikus, strukturalt, sajat tartalmat adott;
- a fioklista mar nem keresotalalatbol, hanem a ceg sajat `uzletek.xlsx` feedjebol lett visszaigazolva.

---

## S2 PUBLIKUSAN IGAZOLT CEGADATOK

Az impresszum es homepage alapjan:

- cegnev: `Exclusive Best Change Zrt.`
- szekhely: `7621 Pécs, Citrom u. 2-6.`
- cegjegyzekszam: `02-10-060505`
- adoszam: `32313332-2-02`
- e-mail: `info@excbestchange.hu`
- telefon: `+36703800203`
- allitas: `a Magyar Nemzeti Bank engedelye alapjan vegzi szolgaltatasait`
- allitas: `a Raiffeisen Bank kiemelt partnere`

Rendszerkovetelmeny:

1. a szervezeti master data-ban ezeket kulon `company_profile` objektumban kell tartani;
2. a `partner bank` kapcsolat explicit legyen;
3. a `licensed entity` es a `branch operator` kapcsolat ne legyen implicit string.

---

## S3 PUBLIKUS UZLETI SZABALYOK / KONDICIOK

### 1. Egyedi arfolyam

A publikus `egyedi-arfolyam` oldal alapjan:

- mar `100 000 Ft` feletti valtasi igenynel kerheto egyedi arfolyam;
- az ajanlat `2 oraig ervenyes`;
- vagy az adott napon nyitva tarto irodak zarasaig;
- az ajanlat e-mailben vagy telefonon erkezhet.

Kozvetlen programkovetelmeny:

- kulon `quoted-rate request` workflow kell;
- kotelezo mezok: `requested_amount_huf`, `quote_channel`, `quote_valid_until`, `quote_status`;
- a quote nem azonos a publikus arfolyamjegyzekkel;
- a quote-nak telephely- es nyitvatartas-fuggo ervenyessegi logika kell.

### 2. Penzkuldes

A publikus `penzkuldes` oldal alapjan:

- `Western Union` penzkuldes elerheto;
- bankszamla nelkul is mukodhet;
- keszpenzes be- es kifizetes tamogatott;
- 200+ orszag, 500 000+ kiszolgalohely allitas szerepel;
- ervenyes okmany szukseges.

Kovetelmeny:

- a penzkuldes nem kezelheto sima penzvaltasi flow-kent;
- kulon compliance es partneri workflow kell;
- a service availability telephelyhez kotott.

### 3. Bankkartyas fizetes

A publikus homepage szerint:

- bankkartyas fizetesi lehetoseg elerheto.

Kovetelkezmeny:

- a tranzakcios modulban a `payment_method` kotelezo top-level mezo;
- a keszpenzes 5 Ft kerekitesi szabaly nem kenheto ossze a kartyaalapu teljesitessel.

### 4. Valuta elorendeles

A publikus site sitemapja kulon `valuta-elorendeles` oldalt jelez.

Kovetelmeny:

- kell `reservation/pre-order` bounded context;
- teljesen mas eletciklus, mint az azonnali penztari valtas.

---

## S4 FIOKLISTA / TELEPHELYI TOPOLOGIA

### 1. Bizonyithato fiokfeed

A `fiokkereso` oldal HTML-je alapjan a telephelyek nem statikus HTML-listakent, hanem kulso feedbol toltodnek:

- store-locator page: `https://www.excbestchange.hu/hu/fiokkereso`
- publikus feed: `https://www.excbestchange.hu/uzletek.xlsx`

### 2. Feed schema

A feed oszlopai:

- `id`
- `nev`
- `cim`
- `telefon`
- `hp_nyitva`
- `sz_nyitva`
- `v_nyitva`
- `lat`
- `lng`
- `MG`
- `WU`

### 3. Feldolgozott osszesitok

A feed alapjan:

- telephelyek szama: `48`
- `WU` jelolesu telephely: `47`
- `MG` jelolesu telephely: `32`
- mindkettovel jelolt telephely: `32`

### 4. Eltérés a publikus marketing allitasok kozott

Nyilvanosan tobb kulonbozo allitas is latszik:

- homepage: `200+ uzlet orszagszerte`
- fiokkereso meta leiras: `kozel 50 pont orszagszerte`
- branch feed: `48` rekord

Ez jelenleg nem feltehetoen egyszeru hiba, hanem valoszinuleg eltero halo-zati scope:

- teljes regio / franchise / partnerhalozat vs
- magyarorszagi sajat vagy aktualis webes fioklista.

Rendszerkovetelmeny:

- a belso branch master adathalmazt nem szabad pusztan marketing-oldalrol generalni;
- kell `branch_status`, `service_scope`, `country`, `brand_scope`, `is_publicly_listed`.

### 5. Kiemelt kovetkeztetes

A branch feed mar onmagaban elegendo bizonyitek arra, hogy:

1. a telephelyekhez cimszintu es nyitvatartasi adat kell;
2. a szolgaltatasok (`WU`, `MG`) telephelyhez kotott capability-k;
3. teruleti kereso / nearest-branch funkcio kulon publikus es belso modul lehet;
4. geokoordinata is resze a publikus topologianak, tehat branch geo-modellezes indokolt.

### 6. Reszletes telephelymelleklet

Teljes lista:

- `docs/knowledge/bestchange-branch-feed.md`

---

## S5 CEGES JOGLINKEK ES SZABALYZATI DOKUMENTUMOK

Az impresszum HTML-je kozvetlenul hivatkozza az alabbi dokumentumokat:

- `ADATKEZELÉSI TÁJÉKOZTATÓ`
- `ÜZLETSZABÁLYZAT`
- `WU ÜZLETSZABÁLYZAT`
- `MONEYGRAM ÜZLETSZABÁLYZAT`
- `PANASZKEZELÉSI SZABÁLYZAT`
- `IMPRESSZUM`

Kovetelmeny:

- a program tudastaraban ezek kulon artifactkent kezelendok;
- az `uzletszabalyzat` es a `partner-specific rules` kulon policy reteg legyen;
- a telephelyi UI-knak tudniuk kell, hogy mely telephelyen mely szolgaltatas aktiv.

---

## S6 KULON KIEMELENDO RENDSZERTERVEZESI KOVETKEZMENYEK

1. `Branch capability matrix` kell: money exchange / WU / MoneyGram / card payment / VIP.
2. `Public quote workflow` kell a `100 000 Ft+` es `2 oras` egyedi arfolyam szabalyhoz.
3. `Branch locator dataset` kulon master adatforras legyen.
4. `Public branch feed import` validator hasznos lehet, mert a sajat weboldal publikus feedje ellenorizheto baseline.
5. `Opening hours` es `quote validity` kapcsolatot modellezni kell.
6. `Brand vs legal entity` kulon mezok kellenek.
7. `bestchange.hu` domain-hozzaferesi / certificate allapot kulon operacios megfigyelendo pont.

---

## S7 NYITOTT CEGES GAP-EK

| Gap ID | Kerdes | Statusz |
|--------|--------|---------|
| `COMPANY-GAP-01` | A `bestchange.hu` es az `excbestchange.hu` milyen pontos brand/domain viszonyban allnak? | nyitott |
| `COMPANY-GAP-02` | A `200+ uzlet` allitas milyen halo-zati scope-ot takar a `48` magyar publikus fiokfeedhez kepest? | nyitott |
| `COMPANY-GAP-03` | A publikus `uzletszabalyzat` PDF konkret penzvaltasi fee/szolgaltatasi felteteleit teljes koruen beemeltuk-e mar? | nyitott |
| `COMPANY-GAP-04` | A branch feed es a belso repo-ban vart branch-entity schema teljesen fedik-e egymast? | nyitott |
