# Teljes Session Osszefuzes - Legacy + Uj Rendszer + AI Utasitasok (MD-5)

- Letrehozas datuma: 2026-03-21
- Cel: Ebben a sessionben keszult osszes orokolt rendszer elemzes + uj rendszer parity elemzes + AI ugynok utasitasok egy darabban
- Megjegyzes: A tartalom forrasfajlokbol valtoztatas nelkul van beemelve, szekciokkal elvalasztva

## Beemelt Forrasfajlok
- docs\legacy-analysis-part1-core-docs.md
- docs\legacy-analysis-part2-screenshots.md
- docs\legacy-analysis-part3-spreadsheets.md
- docs\legacy-analysis-part4-technical.md
- docs\LEGACY-FULL-AUDIT.md
- docs\LEGACY-VS-NEW-COMPARISON.md
- docs\ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md
- docs\JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md
- docs\AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md
- docs\ANTI_MASTERPLAN_WORKLOG_2026-03-20.md

---

## Forras: docs\legacy-analysis-part1-core-docs.md

# Legacy dokumentumok elemzese - 1. resz: Alapdokumentumok

> Generalt: 2026-03-15 | Forras: `docs/legacy-drive/` mappaban talalhato eredeti uzleti dokumentumok

---

## 1. Arfolyam karbantarto hibalista

**Forras:** `docs/legacy-drive/Arfolyam_karbantarto_hibalista.txt`

### Hibajegyzes - Sor masolas bug

- **Erintett modol:** Arfolyamkezelo (LapT01, LapZ01 - altalanos problema)
- **Verzio:** 3.189.0-20260216
- **Leiras:** "Copy selected row" -> "Paste to selected row" hasznalatakor a laprefencia hibasan valtozik (`$LapT01` -> `$LapT3`), ami `#ERR` hibauzeneteket okoz
- **Peldak:**
  - Eredeti: `=$LapT01!C7+0.1` -> Hibas: `=$LapT3!C9+0.1` (elvart: `=$LapT01!C9+0.1`)
- Nincs mukodo visszavonas (Ctrl+Z)

### Funkcionalitasi kovetelmenyek (hibalistan felsorolt igenyek)

| Kovetelm. | Leiras | Allapot |
|-----------|--------|---------|
| Aktiv valutak | 0-s lapon es minden munkalap eseten csak az aktiv valutak jelenjenek meg; penztari programban is | Nyitott |
| Inaktivalas | Lehessen valutakat inaktivva tenni | Nyitott |
| Cella masolas | Cellakat lehessen masolni | Kesz |
| Kerekites | Matematikai szabaly szerinti kerekites | Kesz |
| Ellenorzes | Ellenorzeskor uj oszlopban hibalista | Nyitott |
| Szallas | Ellenorzes, Mentes, Szetkuldes szetvalasztasa | Nyitott |
| Log | Penztarankent (nev, datum) | Nyitott |
| Billentyuzet nav. | Nyilbillentyukkel kozlekedes cellak kozott | Nyitott |
| Gyors bevitel | Enter-rel cellaktivals es azonnali iras (eger nelkul) | Nyitott |
| Uj munkacsoport | Automatikusan tegye be az elszamolo arfolyamokat es valuta elnevezeseket | Nyitott |
| HUF mezo | Currency mezo HUF eseten egesz szam | Nyitott |

---

## 2. Kosa-Szervezes dokumentumok

### 2.1 c.docm.docx - Adatmodell es uzleti szabalyok (PowerDesigner export)

**Forras:** `docs/legacy-drive/Kosa-Szervezes/c.docm.docx`

Ez a dokumentum a teljes rendszer konceptualis adatmodelljt (CDM) tartalmazza. Adat diagramok:

#### Diagram lista

| Diagram | Tema |
|---------|------|
| 010 | Dokumentum tar |
| 020 | Sajat ceg es egyebek (bank, munkallomas, szervezeti egyseg, telephely, orszag, megye, telepules) |
| 030 | HR (szemely, munkavallas, vegzettseg, keszseg, elerhetseg) |
| 040 | Felhasznalo es jogok (elemi jog, jogcsoport, hozzaferesi jog) |
| 050 | Korlevel szabalyzat (korlevel, csatolmany, cimzettek) |
| 060 | Devizanem es arfolyam (banki/csoport/sajat/kedvezmenyes arfolyam, konkurens, cimlet) |
| 070 | Rendszerparameter (szervezet fuggo, devizanem fuggo, idotartam fuggo) |
| 080 | Dij mertek (dij tipus, dij mertek fej/tetel, kedvezmeny) |
| 090 | Nevtelen bejelentes |
| 100 | Penztar torzs |
| 110 | Penztari mozgasok (jogcim, nyitas/zaras bizonylat, egyenleg, cimletezs, idoszak, mozgas) |
| 120 | Ugyfel torzs (szemely/ceg ugyfel, okmany, tiltott szemely/ceg/allampolarsag, kozszereplo) |
| 130 | Penzvaltas (foglalo, kartyas befizetes, meghatalmzas, NAV bizonylat, penzvaltas tetel/dij) |
| 140 | Munkaallomas nyitas zaras (checklist, teendok) |
| 150 | Penztarkozi es banki mozgasok (deviza igeny, penzszallito csomag, transzfer, szallito) |
| 160 | POS fizetes (pos terminal, POS tranzakcio) |

#### Uzleti szabalyok

1. **Ceg TEAOR szam:** Ceg tevekenysege csak a TEAOR hierarchia legalso elemeibol veheto
2. **Cim validitas:** Cim kozterulete a cim telepulesere kell essen (koherens kapcsolat)
3. **Cimletezs devizaneme:** Az egyenleg/penztari mozgas devizanemehez tartozo cimlett kell hogy legyen
4. **Desktop penztart:** Desktop rendszernel a penztar kotelezoen munkaallomashozrendelendo
5. **Okmany egyediseg:** Egy szemlynek egy tipusu okmanybol csak egy ervenyes elofordulsa lehet
6. **Kiindulasi es cel hely:** Nem lehet kiindulsi bank ES cel bank is toltve; nem lehet kiindulsi telephely ES kiindulasi bank
7. **Megye orszag:** Ha megye allamhoz es orszaghoz is tartozik, az allam orszagnak meg kell egyeznie
8. **Munkaallomas telephelyen:** Munkallomas csak olyan szervezet tevekenysegekhez kapcsolodhat, amik egy telephelyen vannak
9. **Penztari mozgas:** Penztari mozgas csak nyitott penztarba torthenhet

#### Kulcs domain-ek (mezo tipusok)

| Domain | Kod | Tipus |
|--------|-----|-------|
| Bankszamlaszam | account_number | varchar(32) |
| Belso id | internal_id | varchar(64) |
| Bizonylaszam | note_number | varchar(64) |
| Hosszu nev | long_name | varchar(256) |
| Igen/nem | boolean | Short integer (0=nem, 1=igen) |
| Megjegyzes | note | varchar(2048) |
| Nev | name | varchar(64) |
| Rovid nev | short_name | varchar(32) |
| Szazalek | szazalek | Decimal(8,3) |
| **Arfolyam** | exchange_rate | **Decimal(10,5)** |
| **Osszeg** | amount | **Decimal(15,5)** |

#### Kulcs entitasok es attributumok

**Penztar (penztar):**
- penztar_id, munkaallomas_kod, szervezet_tevekenyseg_id

**Penztari mozgas:**
- penzmozgas_datumido, jogcim, devizanem, osszeg, arfolyam

**Penzvaltas:**
- ugyfel, munkaallomason vegezve, penzvaltas bizonylat, penzvaltas dij, penzvaltas tetel

**Arfolyam csoport:**
- "Azon gyujto, ahol azonos elvek alapjan, azonos arfolyamot alkalmazhat a ceg"

**Transzfer:**
- Kiindulo/cel bank, kiindulo/cel telephely, transzfer tetel + cimletezs

**Foglalo (foglalo entitas):**
- Penztar, rendeles napja, rendelt osszeg, arfolyam, tranzakcio tipusa

**Kartyas befizetes:**
- POS terminalhoz es munkaallomas nyitas/zarashoz kotve

---

### 2.2 sztorno.docx - Sztornokezeles folyamata

**Forras:** `docs/legacy-drive/Kosa-Szervezes/sztorno.docx`

#### 1. Alapveto sztorno folyamat
- Felhasznalo inditja a tranzakcio sztornozast
- Eredeti tranzakcio azonositasa: idopont, deviza, arfolyam, osszeg
- Visszafizets az eredeti tranzakcio szerint
- NAV felel automatikusan kezeli (bekotott penztargep)

#### 2. Harom sztorno utani kulon engedelyezesi folyamat
- **Limit:** Napi 3 sztorno utan kulon engedely szukseges
- Rendszer automatikusan szamlalja a napi sztornokat
- 3. sztorno utan a rendszer **tiltja** es **penzugyi vezeto engedelyet keri**
- Jovahagyas: vegrehatjhato; Elutasitas: blokkolt

#### 3. Eltero arfolyamon torteno sztorno
- Rendszer ellenorzi az eredeti arfolyamot
- Megjeleiti az aktualis arfolyamot
- Arfolyam elters rogzitese es felhasznaloi figyelmeztets
- Visszateritendo osszeg automatikus szamitasa aktualis arfolyam alapjan

#### 4. POS terminal sztorno
- Kartyas tranzakciok sztornozasa az eredeti tranzakcio alapjan

#### 5. Sztorno bizonylatok
- **Tartalma:** eredeti tranzakcio adatai, sztornozes idopontja, alkalmazott arfolyam, arfolyam kulonbsegek
- Nyomtatas es archivalas sorszam alapjan

---

### 2.3 zaras_ablak.docx - Zarasi wizard

**Forras:** `docs/legacy-drive/Kosa-Szervezes/zaras_ablak.docx`

#### Zarasi tipusok
1. **Napi zaras** - minden nap
2. **POS terminal zaras** - napi kartyas forgalom
3. **Dekad zaras** - legutobbi dekad zars kovetso 10. nyitvatartasi nap zarsakor (10 munkanaponkent)
4. **Havi zaras** - honap utolso nyitvatrtasi napjan

#### Napi zaras wizard lepsei (16 lepes)

| Lepes | Leiras |
|-------|--------|
| 1 | Zarasi folyamat tajekoztatas, tipusvalasztas |
| 2 | Napi tranzakciok osszesitese devizanementent (vetel/eladas, penztarkozi mozgasok) |
| 3 | Keszpenz nyito- es zarokeszlet ellenorzese devizanementent |
| 4 | Kezelesi koltsegek osszegzese |
| 5 | Penztarak kozotti mozgasok ellenorzese |
| 6 | Napi valutaarfolyamok ellenorzese |
| 7 | (Dekad) Dekad tranzakciok osszesitese |
| 8 | (Dekad) Eltersek kezelese - tobblet/hiany magyarazata |
| 9 | (Dekad) Korrekcis bizonylatok kezelese |
| 10 | POS kartyas tranzakciok osszesitese |
| 11 | POS visszateritesek es sztornok osszegzese |
| 12 | POS kezelesi koltsegek es tranzakcios dijak |
| 13 | Zarasi bizonylatok nyomtatasa (napi, dekad, havi, POS) - tobbpeldanyos |
| 14 | Forint atadss-atvteli bizonylatok nyomtatasa (folyamatos sorszamozassal) |
| 15 | Napi riportok automatikus kuldese a kozpontba |
| 16 | Dekad/havi zarasi riportok kuldese + vegelgesits |

---

### 2.4 Kosa cegcsoport fejlesztes lepsei.docx

**Forras:** `docs/legacy-drive/Kosa-Szervezes/Kosa cegcsoport fejlesztes lepsei.docx`

Teljes fejlesztesi roadmap/feladatlista. Fobb modulok:

#### Alap infrastruktura
- Adatbazis tervezes, backend kapcsolat
- Autentikacio (belepes, token, jelszo csere)
- Dashboard (fomenu, logo, labec/verzio, kilepes)
- Rendszerparameterek karbantartasa
- Jogosultsag-kezeles (lista, uj, szerkeszto, aktivalas/inaktivalas, torles)
- Felhasznalo-kezeles (lista, uj, szerkeszto, aktivalas/inaktivalas, archivalas, torles)

#### HR modul
- Munkavallalo kezelese (lista, uj, szerkeszto, aktivalas, archivalas, torles)
- Munkavallalo jutalekai (jutalek lista, kalkulacio, lista generalas konyvelsnek)

#### Tozsadatok
- Munkaallomas-kezeles
- Szervezetek
- Sajat ceg kezeles (fiok/ertktar hierarchia, adasvetel/athelyezes, aktivalas/bezaras)
- Szervezeti rendszerparameterek (szervezet fuggo, devizanem fuggo, idotartam fuggo)
- Cimlet, Devizanem
- Korlevel (ertesitesek)
- Ugyfel es meghatalmazott
- Anonim bejelentes

#### Arfolyamkezeles
- Konkurens arfolyamok (lista, uj, szerkesztes, torles)
- Banki arfolyamok (lista, uj, lekerss, **automata arfolyam lekrdezes**)
- Arfolyam meghatarozas (lista, szerkeszto, valtozas)

#### Dijak es jutalekok
- Dij tipus, dij mertek, adhato dij kedvezmenyek
- Dij valtozas kezelese (adatszinkron soran bekerult dij adatok automatikus elettbe leptetese)
- Alkalmazott dijak
- Jutalek parameterzes

#### Tiltolistak
- Uj/szerkesztes/letoltes/aktivalas/torles
- **Automata szinkronizalas**

#### Valtas (core business)
- Valtas inditas, igenyrogzites, ellenorzesek
- **Eladas, vetel, kereszt/osszetett valtas**

#### Foglalo kezeles
- Foglalo rogzites, ervenysites, visszafizetes
- **Foglalo ugyfel hibabol kovetkezo automatikus lezaras**

#### Valuta igenyek
- Igeny rogzitese, generalasa keszlet adatok alapjan, igeny teljesitese

#### Penztarak kozotti mozgas
- Penz atadasa/atvetele egysegnek
- **Transzfer korrekco**
- Kezelesi dijak atadasa/atvetele

#### Atadolap
- Generlas, nyomtats

#### Bizonylatkezeles
- Lista, sztorno, ujranyomtatas, **utolagos NAV feladas**

#### Zaras/nyitas
- Napi zaras, POS terminal napi zaras, dekad zaras, havi zaras, nyitas

#### Penzmsoas es terror
- Uj bejelentes, felulvizsgalt, feladas

#### Listak es riportok
- Ugylet lista, bizonylat lista, dij osszesito
- Havi keszletkimutatas
- Havi forgalom kimutatas
- Havi forgalom jelentes korzetre/irodara szurve
- Havi atadas/atvetel kimutatas
- Kezelesi koltseg jelentes
- Napi penztar jelentes
- Pillanantyi penztar allasa
- Gyanus ugylet kereses
- Kartyas tranzakcios dijak

#### Technikai funkciok
- **Arfolyam kijelzo**
- Penztarszuntek kezelese (automatikus lezaras logika)
- Logolas (rendszerlog, POS terminal log, NAV log, archivalas)
- Uzleti adatok archivalasa
- Adatok szinkronizacioja modul
- Kijelzo monitor kezelo, POS terminal, NAV penztargep interface, dokumentumtar, ertesites kezelo

---

## 3. Igenyfelmresi interjuk

### 3.1 Kosa cegcsoport elso igenyfelmresi kerdesek

**Forras:** `Kosa csoport/Valuta/Cegcsoport felmerese/Igenyfelmresi interju/Kosa cegcsoport elso igenyfelmresi kerdesek.docx`

Strukturalt kerdoiv, fotemak:
- Informatikai infrastruktura (minimum felbontas: **1920x1080**)
- Operacios rendszerek, halozat, savszelesseg
- Szoftverek (irodai, projektmenedzsment, kommunikacios)
- Szervezeti struktura (belso IT support csapat?)
- Eszkozok (POS, nyomtatok - melyek kozosek?)
- Jovoeni fejleszts (milyen folyamatokat fedjenek le?)
- Felhasznalok/jogosultsagkezeles (kapcsolodo rendszerek jogosultsagai?)
- Rendszerkapcsolatok (szamlazo, konyelo, banki interface)
- Jogszabalyi nyomonkovets
- Funkciok egedettseg/elegedetlenseg a meglevo rendszerben

### 3.2 RSL 1. Igenyfelmresi interju osszefoglalo (2024.02.12)

**Forras:** `RSL Igenyfelmresi interju osszefoglalo 2024.02.12_.docx`

#### Cegcsoport struktura
- **3 fo uzletag:** Ekszer, Zalog, Valuta
- Minden onallo ceg - **adatot TILOS osszemosni**
- Minden alrendszer onalloan fut, onallo szerveren, onallo adatbazissal

#### Valuta ceg szervezeti felepitese
- **180 alkalmazott**
- **62 valutapenztar** szerte az orszagban (foleg delkelet)
- **8 regio/terulet:** Pecs, Kaposvar, Szekszard, Szeged, Kecskemet, Bekescsaba, Debrecen, Nyiregyhaza
- Minden regioban **ertektar** + X szamu penztar (6-9)
- **Teruleti vezeto:** felelos a szemlyi es targyi feltetelekert
- **Ertektaros:** penzellatas szervezese, keszletek figyelse, bankbol penz kihozasa

#### Fio bank: Raiffeisen
- Penzvaltasi tevekenyseg bank ugynokekent (Raiffeisen)
- **Napi elszamolasi kotelezttsg** a bank fele
- Tranzakciok begyujtese es benkuldese a **Darius feluleten**
- **Havi 1x teljes elszamolas** (osszes penzvaltasi tranzakcio, atadas, penztar, ertektar adat)
- Jutalek kiszamitasa es szamlazasa a bank fele

#### Penzvaltasi tranzakcio
- Ugyfel kap bizonylat: arfolyam, egyedi arfolyam lehetoseg
- **Kezelesi koltseg:** kulon tranzakcio, kulon bizonylat, elkuonitett taroals
- **2 penztar a helyszinen** - semmikepp nem moshatopsszeaz ossszeg

#### Arfolyam kijelzo
- Foertektaros kezeli, szerverrol kuldi ki
- **62 vegpont**
- **10 percenkent frissul** (erosebb konkurencia: 5-10 perc, gyengebb: 15-20 perc)
- 1 kozponti vezerles, mind a 62 vegpontra ralat

#### Penzmosasi torveny
- Osszeghatartol fuggoen: szemlyi, lakcimkartya, forrasigazolas
- Okmany beszkennelese es tarolasa (szkenner)
- Szurofeltetelek feleptse lehetoseg (meg nem kotelezo nekik)
- Raiffeisen szurorendszeret hasznaljak egyenlore

#### Konyveles
- **Kulcs-Soft** konyvloi szoftver (Kulcs-Br Premim berszmfejtes)
- **RLB** konyvelo program
- **Adriana** banki kivonat beolvass
- **Szmlazz.hu** szamlazas
- Programok **nem kommunikalnak egymassal** kozvetlenul - kezzel files export/import
- Legtobb adat a Zalogbol es Kulcs-Brbol jon
- Cel: automatizalas, de elso korben a jelenlegi mukodest megelozni

#### Infrastruktura
- **Vodafone adatkartya** 30 GB internet
- Offline eseten a munka megall
- **1 fizikai szerveren** futo, logikailag elkuonitett adatbazisok

#### Egyeb tevekenysgek a valutas cegben
- Kifizetse, AFA kifizetse
- **MoneyGram** tevekenyseg
- **E-kereskedelem** (autopalya matrica, telefonfeltoltes stb.)

### 3.3 RSL 2. Igenyfelmresi interju osszefoglalo (2024.02.15)

**Forras:** `RSL 2. Igenyfelmresi interju osszefoglalo 2024.02.15_.docx`

#### Konyvlesi rszletek
- Kulcs-Br Premim 1.2402.1.2935 verzio
- Konyveloi program: RLB v23.15.0
- Cges auto brszmfejtsre: RLB
- Adriana csomag: bank konyveles
- POS terminalok NEM kapcsolodnak a konyvelszhez
- 3 tevkenyseg POS-szal: Valutavaltas, Ekszer kereskedelem, Zalog
- Ekszer es Zalog POS egyforman, Valuta maskepp

#### Konyvlesi workflow
1. Feladskszitsi metodus cegennt
2. Letolts fajl formtumba
3. Betolts az RLB-be
4. Automatikus felkonyvels

#### Fontos elv
> "Nekik a lnyeg, hogy az egyezetsek megtortnjnek es egyezzenek a pontok... egy filler sem terhet el."

---

## 4. Kovetelmnylista - Arfolyamkszts

**Forras:** `Kosa csoport/Valuta/Cegcsoport felmerese/Arfolyamkszito programrol/Kovetelmnylista - Arfolyamkszts.docx`

### Arfolyamlap struktura

#### AR001: Alaparfolyam lap (0-s arfolyam lap)

| Oszlop | Nev | Leiras |
|--------|-----|--------|
| A | Elszamolo arfolyamok | Fo valutak (EUR, USD, GBP, CHF) kezzel allitva; tobbi kepletel szamolva |
| B | OTP arfolyam | Irnymutato, kezzel beirt az OTP hivatalos weboldalrol |
| C | Segedoszlop | Kezzel allithato szorzok |
| D | Valutanemek | 30 valuta (lasd lent) |
| E | Gyenge arfolyamos - Vetel | Legszlesebb arfolyamu irodak |
| F | Gyenge arfolyamos - Eladas | keplethezheto |
| G-H | Keresztarfolyamok | EUR/USD alapu szamitasok |

#### Automatikus arfolyamok

- **OTP arfolyamot masolok:** EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK
- **Euro alapu (EUR keresztarfolyam):** CZK, PLN, RON, RSD, TRY
- **Dollar alapu (USD keresztarfolyam):** ILS, UAH, RUB, CNY, BAM, THB, BRL, MXN, NZD, RCH

#### Tamogatott valutanemek (30 db)

EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, **EUA** (euro erme), TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH

**EUA kulonleges szabaly:** Euro erme arfolyama. **20%-nal nem terhet el** az euro arfolyamtol. Ha tobben ter el, ki kell irni az ugyfeleknek. Kepzes peldaja: gyenge arfolyamos euro eladas szorozva 1.2-vel.

#### Uj valutanem felvetele/torlse
- Jelenleg csak program modositasaval lehetseges
- **Igeny:** lehessen ujat felvenni/meglvot megszuntetni
- Tobbszori rakerdezes vagy **supervisori jelszohoz kotott**

### AR002: Csoport lap

| Oszlop | Nev | Leiras |
|--------|-----|--------|
| J | Elszamolo arfolyam | |
| K | Valutak | |
| L-M | Also kedvezmnyhatr Vtel-Elads | Alap kiirt arfolyamok, kijelzokon megjelennek, **kezzel allitva** |
| N-O | Kozpso kedvezmny hatr | |
| P-Q | Felso kedvezmny hatr | |
| R-S | Sajt hatskoru Vt. max - Elad. min | Pentarak limitalt: **napi 5 kedvezmny** |

#### Sajat hatskoru arfolyam kepzese
- Az elozo oszlopokhoz hozzadott kedvezmny mertek
- Peldaa: EUR "R" oszlop = P + 0.25

#### Kedvezmny hatrok
- Egyszer beallitva, nem rendszeres modositas
- **54 csoport lapon** (munkacsoporton) egyedileg allithato
- **Eladsiarfolyam NEM lehet kisebb az elszamolo arfolyamnal** -> figyelmezttes kuldskor
- **Vteliarfolyam NEM lehet nagyobb az elszamolo arfolyamnal**
- Raiffeisen megbizasi szerzods: **kozeparfolyamtol max 10% eltrs** a vetel es eladsi oldalon (szabadon allithato ertek)

#### Kitoltsi segtseg
- Azonos valutanem oszlopa az alap-arfolyam tablazatban
- Azonos valutanem oszlopa az aktualis munkacsoportban
- Mas valutanem brmely oszlopa
- Azonos valutanem egy masik csoportbl
- Adatmasols, adat lehuzas

---

## 5. Kerdesek es valaszok (kerdesek.docx)

**Forras:** `Kosa csoport/Valuta/Kosa Szervezes/Cegcsoport felmerese/kerdesek.docx`

### Kulcsfontossagu uzleti valaszok

#### Bizonylat szamozas
- Bizonylatok sorszama **egyedi**
- Betujel a tranzakcio tipusara utal:
  - **V** - Vetel
  - **E** - Eladas
  - **F** - Valuta atadas
  - **U** - Valuta atvetel
  - **FF** - Forint atadas
  - **UF** - Forint atvetel
  - **B** - Kezelesi koltseg atvetele (foglalonal is)
  - **K** - Kezelesi atadas (foglalonal is)
- Szam a **penztar szamaval** kezdodik (pl. 074, 143), utana folyamatos sorszam, **kihagyas mentesen**

#### Arfolyam kedvezmeny
- **2% felett** csak supervisori jelszoaval modosithato (ertktarosi supervisor)

#### Atlag arfolyam
- **Szamolt arfolyam:** napi forgalom alapjan szamolodik, regebben delphi-ben szamoltak, a konyvelssnek az atlag arfolyammal szamoltak

#### Keszlet nyilvantartas "maradek Forint"
- Kiadas eseten a valutaertk HUF-ba szamolva nem kerek osszeg; **a kulnbozt kezeli** (maradek)

#### Forgalom nyilvantartas MTCN
- **MoneyGram tranzakcios szam** (Money Transfer Control Number)

#### Kozszereplo
- Kozszereplo tipusa (allamfo, kpviselo) **rogzitendo**

#### Cimletezs
- Cimlet mennyisg figyels: **igen, hasznos** (ha valaki mindig cimletezik)

#### Bizonylat masolt nyomtatsa
- **2 pdlany szksges:** 1 a cegnek, 1 az ugyflelnek

#### Sztorno
- Sztorno darabszam: **nap/penztr/fiok** alapon szamlalodik
- Engedlyezo kodkpzs szabalya: supervisori jelszo (ertktaros adja)
- Kozpontban sztornoznak: **eredeti fiok NEM kap ertestst** (nincs ra szukseg)
- NAV-os bizonyltatszamot **NEM kell bekrni** sztornoml (automatikus)

#### Kezelsi koltseg jutalek
- A **kezelsi dj** = jutalek (ugyan az)

#### Tranzakcios ado
- Napi tranzakcios adobevallst kell ksziteni: **2% ado** a napi penzvaltasi forgalomra (2024-ben hatlyos szabaly)

#### Penztar allapot
- "Nyitva/zarva" = **napi nyitva/zarva** (nem uzemel/nem uzemel)

#### Valuta mozgas ertektar-penztar
- **NEM kell NAV gpre mennie**

#### Penz kuldemnny nem erkezik meg
- **Sztorno valami jogcimmel** + jegyzokonyv csatolasa

#### Konverzo (kereszt valtas)
- **Torvenyi eloirs:** kt bizonylat kell (1 vetel + 1 eladas)
- Bizonylatokon feltuntetni: **"konverzis vetel" / "konverzis eladas"**

#### Nevtelen bejelents
- Senki ne lssa, ki tette (nincs hiper-super jog sem)
- **Veglegges kuldes elott** ki lehet lepni (torles)
- Bekulds utan **NEM modosithato**

#### Tiltolista
- Automatikus letolts es beolvasas
- Kapott linkekkel **allndoan kommunikl a szerver**
- Ha uj van: befogadja; ha nincs mr a listrn: torli
- **Plombszm:** 10 karakterig barmilyen betu-szm kombincio (vonalkod nem opcio szllitsml)

#### Foglalopenz
- **Max 2 napig** ervenyes
- Ha az ugyfel nem jelenik meg 2 napon belul, **automatikusan lezaroik** es a foglalopenz a kezelsi koltseg penztarba kerul

---

## 6. Kiegszitoenyeri dokumentumok

### 6.1 Engedelyezshez szukseges adatok

**Forras:** `Kosa Tervezes es fejlesztes/Segedanyagok Valuta/Engedelyezshez szukseges adatok.docx`

Tranzakcio engedelyezesi minta:
```
Penztar szama: 105
Penztar neve: BEKESCSABA BELVAROS II.
Bizonylatszam: V105007798
Tranz.osszege: 10088410
  1. valuta: 26,000 EUR
  1. arfoly: 38840
  1. ertek: 10,098,400 Ft
Ugyfel adatai:
  - neve, anyja neve, szul.ido, szul.hely
  - lakcim, okmany tipus, okmany szam
  - allampolgarsag, tart.hely
  - engedelyezo: KOSA ZOLTAN
```

### 6.2 Foglalo felvetele

**Forras:** `Kosa Tervezes es fejlesztes/Segedanyagok Valuta/Foglalo felvetele.docx`

Foglalo minta:
```
Penztar: 105
Rendeles napja: 2024.03.15
Rendelt osszeg: 10.000 EUR
Arfolyam: 38500 (100 EUR/Ft)
Tranz. tipusa: VETEL
```

### 6.3 Bank API hivatkozasok

**Forras:** `Kosa Tervezes es fejlesztes/Bank API/API_bank.docx`

- **MNB:** https://www.mnb.hu/sajtoszoba/sajtokozlemenyek/2015-evi-sajtokozlemenyek/tajekoztatas-az-arfolyam-webservice-mukodeserol
- **Raiffeisen:** https://api.rbinternational.com/api-categories?provider=raiffeisenbank-zrt

---

## 7. Osszefoglalo: kritikus uzleti szabalyok es kuszobertekek

| Szabaly | Ertek | Forras |
|---------|-------|--------|
| Arfolyam kedvezmny supervisori limit | **2%** | kerdesek.docx |
| Raiffeisen kozeparfolyam max elteres | **10%** (allithato) | AR001-05 |
| EUA (euro erme) max elteres euro-tol | **20%** | AR001-04 |
| Sztorno napi limit (engedelyezs nelkul) | **3 db** nap/penztr/fiok | sztorno.docx |
| Penztrosi napi kedvezmny limit | **5 db** | AR002-06 |
| Foglalo erveynysseg | **Max 2 nap** | kerdesek.docx |
| Arfolyam kijelzo frissites | **5-20 perc** (konkurencia fugg) | interju |
| Bizonylat peldanyszam | **2 db** (ceg + ugyfel) | kerdesek.docx |
| Plombaszam max hossz | **10 karakter** | kerdesek.docx |
| Minimum monitor felbontas | **1920x1080** | igenyfelmeres |
| Arfolyam domain | Decimal(10,5) | c.docm.docx |
| Osszeg domain | Decimal(15,5) | c.docm.docx |
| Aktiv valutak szama | **30** | AR001-04 |
| Arfolyam csoportok (munkalapok) | **54** | AR002-10 |
| Valutapenztar szam | **62** | interju |
| Regiok szama | **8** | interju |
| Alkalmazottak szama | **~180** | interju |
| Tranzakcios ado | **2%** napi forgalomra | kerdesek.docx |

---

## Forras: docs\legacy-analysis-part2-screenshots.md

# Legacy Valutavalto Program -- Kepernyokepek es Bizonylatok Elemzese

> Keszult: 2026-03-15
> Forras: `docs/legacy-drive/Kosa csoport/Valuta/Cegcsoport felmerese/`

---

## 1. Tartalomjegyzek

- [1. Arfolyamkeszito program](#2-arfolyamkeszito-program-5-kep)
- [2. Fomenu es navigacio](#3-fomenu-es-navigacio)
- [3. Beallitasok panel](#4-beallitasok-panel-12-tema)
- [4. Tranzakciokezeles](#5-tranzakciokezeles)
- [5. Penztarkezeles](#6-penztarkezeles)
- [6. Zarasok es cimletez](#7-zarasok-es-cimletez)
- [7. Listak es riportok](#8-listak-es-riportok)
- [8. Bizonylatok (nyomtatott)](#9-bizonylatok-nyomtatott-14-kep)
- [9. Dokumentumok (jelentesek)](#10-dokumentumok-jelentesek-3-kep)
- [10. Munkavallalo-kezeles](#11-munkavallalo-kezeles-hatterrendszer)
- [11. Hardver](#12-hardver)
- [12. Uzleti szabalyok osszefoglalasa](#13-uzleti-szabalyok-osszefoglalasa)

---

## 2. Arfolyamkeszito program (5 kep)

### 2.1. "0-s lap" -- Alaparfolyamok tablazat (arf_00.jpg)

**Kepernyokep:** Egy Excel-szeru tablazat, amely a kozponti arfolyam-karbantatasi felulet.

**Oszlopok:**
- **A -- Elszamolo arfolyamok**: belso elszamolasi arfolyam
- **B -- OTP**: OTP bank arfolyama (referenciaertek)
- **C -- SEGED**: segedarfolyam
- **D -- VALUTA NEMEK**: harom betus valutakod (EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH)
- **E -- VETEL**: veteli arfolyam
- **F -- ELADAS**: eladasi arfolyam
- **G -- GYENGE ARF-OS MULTIK (EUR)**: gyenge arfolyamu multinacionalis cegek EUR arfolyama
- **H -- KERESZT ARFOLYAMOK (USD)**: USD keresztarfolyam
- **I -- NAGYBANI**: nagybani arfolyam

**Utolso oszlop -- INTERNET**: internet forras megjelolese (pl. "OTP", "Feco", "EUR/CZK", "Kuna dr NBH", "Realtime FX", "BRN RON", "Szerb Dinar", "BGN", "SHAKEL", "HRIVNTA", "RUBEL", "CNY")

**Fontos uzleti szabalyok:**
- A "0-s lap" az alap (master) arfolyamtabla, amelybol a tobbi csoport arfolyama szarmazik
- 29 kulonbozo valutanemet kezelnek
- Kulon van "elszamolo arfolyam", "OTP referencia" es "veteli/eladasi" arfolyam -- tobbretegu arfolyam-rendszer
- Gyenge arfolyamu multinacionalis arfolyamok kulon kezelese (pl. Tesco, Metro)
- Keresztarfolyamok kiszamitasa (EUR/USD bázison)
- Internet-forrasu arfolyamok jelolese

**Menu sor teteje:**
- CSOPORTOK KARBANTARTASA
- ARFOLYAMOK SZETKULDESE
- INTERNET CIMEK KARBANTARTASA
- KILEPES

### 2.2. Arfolyamok szetkuldese log (arf_01.jpg)

**Kepernyokep:** Az arfolyam-kiszalltasi rendszer, penztarak vizualis terkepe.

**Felulet:** 54 szamozott penztarteglalap (1-54), mindegyik egy fizikai fiok/penztar:
- 1-ARKAD, 2-PECS FERENCESEK, 3-IRGALMAS, 4-SZIGETVAR, 5-NAGYATAD, 6-DOROTTYA, 7-DOMBOVAR MARCALI
- 8-SZEGED TISZA LAJOS, 9-SZEGED BELV, 10-SZEGED MULTI, 11-HMVASARHELY, 12-GYULA BELVAROS, 13-BCSABA TESCO
- 14-PEC (+ 21-KKK cimke), 15-SZEKSZARD BELVAROS, 16-PAKSEK, 17-BONYHAD, 18-KALOCSA BELV, 19-BCSABA BELVAROS, 20-ALFOLD KECSKEMET
- 22-NY1 KORZO, 23-SZOLNOK PLAZA, 24-NYIREGY VAY A, 25-SZOLNOKOK, 26-NY TESCO, 27-DEBI BAJCSY
- 28-NY1 ORSZ, 29-DEBI TISZA, 30-MATESZALKA, 31-DVAR BELV, 32-KISVARDA, 33-DEB BOSZORMENY
- 34-KISVARDA TESCO, 35-SIOFOK PLAZA, 36-KAP KORZO, 37-SZEGED MORA, 38-DEBRECEN TESCO, 39-KARCAG, 40-SZOBOSZLO ARKAD
- 41-SUJHELY, 42-HMVHELY ZALOG, 43-DEBI PLAZA, 44-SZEGED PRAKTIKER, 45-MOHACS, 46-GYULA TESCO, 47-DEB BELVAROS
- 48-NYIRBATOR, 49-ZALOG, 50-SZEGED PLAZA, 51-BAJA, 52-PECS MULTI, 53-DEB KALVIN, 54-PECS RAKOCZI

**Log uzenet (piros hatter):**
1. Az ARFDATA.DAT file rogzitese a lokalis szamitogepen
2. Az arfolyamok mentese a sajat gepre
3. Az irodak adatainak rogzitese
4. Az internet cimek rogzitese
5. Az alaparfolyamok rogzitese
6. A munkacsoportok rogzitese
7. "A sajat gepemre sikeresen lementettem az adatokat"
8. **BIZTONSAGI MENTES KESZITESE A BEKESCSABAI SZERVERRE**
9. **A BIZTONSAGI MENTES SIKERTELEN VOLT!**
10. "A szerverre nem sikerult kitenni az adatokat"

**Jobb oldali checkbox lista:** "A jelolt csoportokat ellenorzi a program" -- 54 penztarfiok, mindegyik kivalaszthato

**Uzleti logika:**
- Kozponti arfolyam-keszites, majd szetkuldes az osszes fioknak
- ARFDATA.DAT file = az arfolyamadatok kozponti taroloja
- Biztonsagi mentes a bekescsabai szerverre
- Csoportonkenti szetkuldesi kontroll

### 2.3. Csoportok karbantarto -- Ures iroda (arf_02.jpg)

**Felulet:** Ugyanaz a penztarterkep, de "MUVELET = KARBANTARTAS" modban. Az egyik iroda kivalasztva, "NINCS IRODA ITT" uzenet.

**Uzleti logika:** A csoportok karbantartasa lehetove teszi irodak hozzaadasat/torloset a rendszerbol.

### 2.4. Csoport reszletek -- automatikus arfolyam (arf_03.png)

**Kepernyokep:** Egy csoport (16-os csoport) reszletes arfolyamtablazata.

**Mezok:**
- **Piala**: ? (valoszinuleg egy belso azonosito)
- **A CSOPORTBA TARTOZO IRODAK**: lista
- **Aktiv - Inaktiv** jelzes
- **AKTUALIS FUGGVENY**: #01M (fuggveny, amellyel az arfolyamot szamolja)
- **KEDVEZMENYES HATAROK**: also: 50.000, kozepso: 300.000, felso: 1.000.000

**Arfolyamtabla oszlopok:** Elszamolo, Vasarol, ... (tobb arfolyam-szint)

**Uzleti logika:**
- Csoportonkent mas-mas arfolyam-szamitasi fuggveny (#01M = formula)
- **Kedvezmenyes hatarok**: 3 szintu kedvezmenyrendszer osszeg alapjan (50K, 300K, 1M Ft felett)
- Az arfolyamot nem kezzel allitjak, hanem a "0-s arfolyamlaprol toltodik" (automatikus)

### 2.5. Csoportok karbantarto felulet (arf_04.jpg)

**Felulet:** Teljes karbantartasi felulet a 54 penztarral es a checkbox listaval.

**Menu sor:**
- VISSZA AZ ALAPADATOK KARBANTARTASARA
- UJ PENZTAR FELVETELE MUNKACSOPORTBA
- PENZTAR TORLESE EGY MUNKACSOPORTBOL
- MUNKACSOPORT ATNEVEZESE
- PENZTAR ATHELYEZESE MASIK CSOPORTBA
- ARFOLYAMOK SZETKULDESE A SZERVEREN AT
- KILEPES A PROGRAMBOL

**Alul:** Valutanemenkent (BGN, CAD, ...) egy sor adat: sorszam, elszamolo arfolyam, veteli, eladasi, stb.

---

## 3. Fomenu es navigacio

### 3.1. Fomenu -- 1. oldal (kep_20.JPG)

**Cim:** "A valutaprogram fomenuje"

**Bal oldali info panel:**
- **Verzioszam:** 04.00
- **Munkanap datuma:** 2024 MARCIUS 12 KEDD
- **Pontos ido:** 11:51
- **Penztarszam:** 75
- **Telefon:** 06/66-448-500
- **Bejelentkezett penztaros:** 07505-SARKADI TUNDE
- **Helyszin:** BEKESCSABA, ANDRASSY UT 24-28

**Fomenu elemek (1. oldal):**
1. PENZTARAK KOZOTTI ATADAS - ATVETEL
2. MAI BIZONYLAT SZTORNOJA
3. A PILLANATNYI PENZTAR ALLASA
4. A NAPI- ES HAVIZARAS VEGREHAJTASA, CIMLETEZ[ES]
5. BIZONYLATOK MEGTEKINTESE
6. KILEPES A FOMENUBOL

**Also menu sor (F-billentyuk):**
- NAPI JELENTES, ATADASOK, SUPERVISOR, KORLEVELEK, HAVI TABLOK, KESZLETEK, PENZTARAK
- ZARAS BEKULLDESE, ENGEDMENYEK, KILEPES

**Helyszin felirat:** "BEKESCSABA ERTEKTAR" (nagy, dolt betukkel)

### 3.2. Fomenu -- 2. oldal (kep_19.JPG)

**Fomenu elemek (2. oldal - ">>>" navigacioval):**
1. TARSPENZTARAK KARBANTARTASA
2. KULONFELE LISTAK NYOMTATASA
3. PENZTAROSOK, JELSZAVAK KARBANTARTASA
4. REGEBBI NAP ZARAS UJRANYOMTATASA
5. WESTERN UNION ES AFA TRANZAKCIOK
6. KILEPES A FOMENUBOL

**Also menu sor (F-billentyuk):**
- F1-ARFOLYAM, F2-FOGLALO, F3-TERMINAL, F4-AFA TABLA, F5-MAI FORG, F6-TESCO AFA, F7-SUPERVISOR
- F8-(ures), F9-KESZLET, F10-ATADOLAP, F11-METRO AFA, F12-W. UNION, Esc-KILEPES

### 3.3. Penztar karbantartas -- v35.25 felulet (kep_46.jpeg, kep_47.jpeg)

**Cim:** "PENZTARAK KARBANTARTASA"

**Cegnev:** Exclusive Best Change ZRT. (verzioszam: 35.25)

**Oszlopok:** PENZTAR | PENZTAR MEGNEVEZESE | PENZTAR CIME | TELEFONSZAM
- 105: BEKESCSABA BELVAROS II. | BEKESCSABA ANDRASSY U. 24-28 | 06703800161
- 75: BEKESCSABA ERTEKTAR (kivalasztva)
- TH: TOBBLET-HIANY PENZTAR
- 1: FOPENZTAR

**Gombok:** ADATOK MODOSITASA | UJ PENZTAR FELVETELE | PENZTAR TORLESE | VISSZA A FOMENURE

**Also funkciogombok (F1-F12+Esc):**
- F1-ARFOLYAM, F2-FOGLALO, F3-TERMINAL, F4-AFA TABLA, F5-MAI FORG
- F6-TESCO AFA, F7-SUPERVISOR, F9-KESZLET, F10-ATADOLAP, F11-METRO AFA, F12-W. UNION, Esc-KILEPES

**Also sor:** "Napi stornozott bizonylat darab: 6", FUTOFENY, KORLEVELEK, NEVTELEN BEJELENTES, PENZTAR SZUNET, FOMENU

---

## 4. Beallitasok panel (12 tema)

A Beallitasok kepernyok jelszoval vedett. A bal oldalon "TEMAK" lista, jobbra a kivalasztott tema beallitasai.

### 4.1. Alapfunkcio (kep_00.jpeg, kep_01.jpeg)

**Harom lehetseges geptipus (radio button):**
- **PENZTARI GEP** (kivalasztva) -- a penztar munkahelyeken
- **ERTEKTARI GEP** -- az ertektar (kozponti raktarkezelesi) gepen
- **AFAS GEP** -- AFA-s tranzakciokhoz (Tesco/Metro AFA)

**Uzleti logika:** Egy telepitesi szintu beallitas, amely meghatarozza a program mukodesi modjat. Mas menu es funkcionalitas erhetoe el ertektari vs. penztari vs. AFA-s uzemmodban.

### 4.2. Alkalmazasok (kep_02.jpeg)

**Checkbox-ok:**
- **VALUTAVALTAS** (bejelolve)
- WESTERN UNION
- TESCO AFA
- METRO AFA
- E-KERESKEDELEM

**Uzleti logika:** Modularis rendszer -- egyes funkciok iroda-szinten be/ki kapcsolhatok.

### 4.3. Arfolyam kijelzo beallitasai (kep_03.jpeg)

**Cim:** "AZ ARFOLYAM KIJELZO SZINE"
**Opciok:** ZOLD, SARGA, PIROS

**Elonezet:** Egy LED-tablaszeruen formalt arfolyam-kijelzo, amely az EURO-t mutatja:
- VETEL: 306,00
- ELADAS: 316,99

Alatta egy tablazat az osszes valuta arfolyamaival.

**Uzleti logika:** A fizikai arfolyamkijelzo tablo szinenek beallitasa. A kijelzo a bolt kirakataban all.

### 4.4. IP-cim beallitas (kep_04.jpeg)

**Cim:** "A SZERVER ELERES IP-CIME"
**Ertek:** 185.43.207.99
**Gombok:** IP-CIM RENDBEN, MEGSEM

**Uzleti logika:** A kozponti szerver IP-cime, ahova az adatokat kuldi a program. Fiokszintu beallitas.

### 4.5. Jelszo beallitas (kep_05.jpg)

**Mezok:**
- **NAPI JELENTES JELSZAVA:** MAG (+ JELSZO MODOSITAS gomb)
- **AZ ERTEKTAR E-MAIL CIME:** BEKESCSABA.EBC@GMAIL.COM
- **SZOMBATI NYITVATARTAS:** SZOMBATON NYITVA / SZOMBATON ZARVA (radio)

**Uzleti logika:** A napi jelentes elkuldese jelszoval vedett. Az ertektar e-mail cimere kuldi a jelentes. Szombati nyitvatartas kapcsolo.

### 4.6. Adatok bekuldese a szerverre (kep_06.jpeg)

**Cim:** "ADATOK BEKULDESE A SZERVERRE"
**Gyakorisag:** 2 percenkent (csuszkaval allithato 0-25 perc kozott)

**Uzleti logika:** Periodikus adat-szinkronizalas a kozponti szerverre. 2 percenkent kuldi az adatokat -- ez az "offline sync" rendszer elsokezu bizonyiteka.

### 4.7. Nyomtato beallitas (kep_07.jpeg)

**Cim:** "NYOMTATO TIPUSA"
**Opciok:**
- LPT1 PORTRA CSATLAKOZTATVA (kivalasztva)
- USB PORTRA CSATLAKOZTATVA

### 4.8. Szkenner beallitas (kep_08.jpeg)

**Cim:** "A SCANNER BEALLITASA"
**Alkalmazott driver:**
- CanoScan Lide 120
- WIA-CanoScan Lide 120 (kivalasztva)

**Uzleti logika:** Szkenner hasznalatara utal -- valoszinuleg szemelyi igazolvany/utlevel szkenneles (AML)

### 4.9. Reklam a kijelzon (kep_09.jpeg -- a Beallitasok menu teljes listaja lathato)

**Opciok:** NINCS REKLAM A KIJELZON / VAN REKLAM A KIJELZON

**Teljes Beallitasok temak listaja:**
1. ALAPFUNKCIO
2. ALKALMAZASOK
3. IP-CIM BEALLITASA
4. JELSZO BEALLITAS
5. KIJELZES SZINE
6. FUTOFENY
7. KESZLETEK BEKULDESE
8. KEZELESI KOLTSEG
9. BANKKARTYA FIZETES
10. NYOMTATO
11. REKLAM A KIJELZON
12. SCANNER BEALLITASA

**Gomb sor:** ROGZITES ES KILEPES | KILEPES MODOSITAS NELKUL | VISSZA A MENURE

---

## 5. Tranzakciokezeles

### 5.1. Fo tranzakcios kepernyok (kep_34.jpeg, kep_36.jpeg, kep_38.jpeg)

**Harom paneles felulet:**

**Bal panel -- Blokk fejek (tranzakcios lista):**
| BIZONYLAT | DATUM | IDO | BLOKK... | EZ-DI... |
|-----------|-------|-----|----------|----------|
| UF10500862 | 2024.03.11 | 08:54 | 4000000 | |
| V105007778 | 2024.03.11 | 10:33 | 31020 | |
| E105004177 | 2024.03.11 | 10:46 | 155320 | |
| ... | | | | |

**Bizonylat prefixek:**
- **UF** = "U Forint" -- forint atveteli bizonylat
- **V** = Veteli bizonylat (valuta vasarlas ugyfeltol)
- **E** = Eladasi bizonylat (valuta eladas ugyfelnek)
- **FF** = Forint fixing

**Kozepso panel -- Blokktetelek:**
| BANKJEGY | VALUTA | ARFOLYAM | FORINT |
|----------|--------|----------|--------|
| 4000000 | HUF | 100 | 4000000 |

**Naptar widget:** 2024 marcius 11, napvalasztas lehetoseggel
**Gombok:** "Ezt a napot kerem!" | "NAV NYUGTA" | "Forint atvetel bizonylat"

**Jobb panel -- UGYFEL ADATAI:**
- LAKCIM
- OKMANYTIPUS
- AZONOSITO
- TARTOZKODASI HELY
- LAKCIMKARTYA
- DEVIZA STATUSZ
- KOZSZEREPLO STATUSZ
- IRANYITO SZAM
- VAROS
- UTCA - HAZSZAM
- TIZ-MILLIO FELETTI TRANZAKCIOK
- PENZ FORRASA
- ENGEDELYEZO

**Also:** Penztar azonositas: "Atado penztar 75 -- BEKESCSABA ERTEKTAR"
**Penztaros:** VIRAG MARGIT

**Also gombok:** Bizonylatok szurese | A HONAP OSSZES BIZONYLATA | CSAK A VALASZTOTT NAP | Okmanykeules | Ujranyomtatas | Vissza a menure

### 5.2. Bizonylatok szurese (kep_10.jpeg, kep_11.jpeg)

**Szuresi opciok (radio button):**
- Szures kikapcsolva
- Csak ugyfeles bizonylatok
- Csak veteli bizonylatok
- Csak eladasi bizonylatok
- Csak konverzios bizonylatok
- Csak penz-atadasi bizonylatok
- Csak penz atveteli bizonylatok
- Csak stornozott bizonylatok

**Uzleti logika:** 7 kulonbozo bizonylattipus: ugyfeles, veteli, eladasi, konverzios, penz-atadas, penz-atvetel, sztorno

### 5.3. Penz atvetele/atadasa (kep_35.jpeg, kep_37.jpeg)

**Felulet oszlopok:** VALUTA MEGNEVEZESE | MENNYISEGE | ARFOLYAM | FT ERTEK
- HUF - MAGYAR FORINT, arfolyam 100
- Checkbox-ok: "ARFOLYAM ATIRAS", "Cimlet"
- EXC (Exclusive Change logo) jobb felso sarok

**Gombok:** ARFOLYAM ATIRAS | Nincs tobb adat | Megsem

**Uzleti logika:** A penz ertektarbol valo atvetelemnel megjelenik a valutanem, mennyiseg, arfolyam es forint ertek. Lehetoseg van arfolyam atiras-ra (egyedi arfolyam) es cimletezesre.

### 5.4. Szallitas penztarak kozott (kep_49.jpeg, kep_53.jpeg, kep_40.jpeg)

**Dialogs:** Penzszallitasi bizonylat
- TARSPENZTAR: 75 -- BEKESCSABA ERTEKTAR
- SZALLITO NEVE: (kitoltendo)
- PLOMBASZAM: (kitoltendo)
- MEGJEGYZES: (kitoltendo)
- Gombok: KONYVELHETO | MEGSEM

**Uzleti logika:** Penztarak kozotti fizikai szallitasnal rogzitik a szallito nevet es a plomba szamat (biztonsagi pecsett). A "KONYVELHETO" gomb veglegesiti a mozgast.

### 5.5. ERB Egyedi kotes (kep_14.JPG)

**Dialog:**
- TARSPENZTAR: ERB
- SZALLITO NEVE: (ures)
- PLOMBASZAM: (ures)
- MEGJEGYZES: (ures)
- Gombok: KONYVELHETO | MEGSEM

**Uzleti logika:** ERB = "Egyedi kotes RB" -- a kozponti bank fele torteno egyedi arfolyamu kotes bizonylata. Pld. nagy osszeget kulon arfolyamon valtanak.

---

## 6. Penztarkezeles

### 6.1. Tarspenztar valasztas (kep_44.JPG, kep_45.JPG, kep_54.jpeg)

**Tablazat:** SZAM | MEGNEVEZES

**Elso lista (v35.25 verzio, nagyobb halozat):**
| Szam | Megnevezes |
|------|-----------|
| TH | TOBBLET-HIANY PENZTAR |
| 78 | OROSHAZA TESCO |
| 79 | SZARVAS TESCO |
| 105 | BEKESCSABA BELVAROS II. |
| PRB | POS ATVETEL BANKTOL |
| NEW | PECS PLAZA |
| WU | UJ PENZTAR |
| UL | WU ELLATMANY |
| TV | UTON LEVO PENZTAR |
| 20 | TEVES KONYVELES |
| 145 | SZEGEDI ERTEKTAR |
| (145 kivalasztva) | KAPOSVAR ERTEKTAR |

**Masodik lista:**
| 71 | GYULA BELVAROS |
| 50 | DEBRECEN ERTEKTAR |
| 63 | NYIREGYHAZI ERTEKTAR |
| 0074 | TESCO BEKESCSABA |
| RB | FORINT MOZGAS RB |
| ERB | FIXING VALUTA MOZGAS RB |
| TRB | EGYEDI KOTES RB |
| 76 | TER. KOZOTTI MOZGAS RB |
| JRB | BEKESCSABA BELVAR |
| 77 | JUTALEK BEFIZETES RB |
| MNB | GYULA TESCO |
| | MNB |

**Specialis penztarak (nem fizikai fiok):**
- **TH** -- Tobblet-Hiany penztar (elteres kezeles)
- **RB** -- Forint Mozgas RB (Raiffeisen Bank mozgasok)
- **ERB** -- Fixing Valuta Mozgas RB (valuta fixing a bankon keresztul)
- **TRB** -- Egyedi kotes RB (egyedi arfolyamu tranzakciok)
- **JRB** -- Jutalek befizetes RB
- **76** -- Teruletek kozotti mozgas RB
- **PRB** -- POS atvetel banktol
- **TV** -- Uton levo penztar (szallitas kozben levo penz)
- **WU** -- Western Union penztar
- **UL** -- WU ellatmany
- **20** -- Teves konyveles (hibajavitas)
- **MNB** -- Magyar Nemzeti Bank

**Gombok:** EZT VALASZTOM | NEM VALASZTOK | UJ PENZTAR FELVETELE

### 6.2. Penztarak kozotti penzforgalom fomenu (kep_48.jpeg)

**Menu elemek:**
1. Penz atvetele egy egysgtol
2. Penz atadasa egy egysegnek
3. Kezelesi dijak atadasa-atvetele
4. Horvat kuna bekuldeske
5. E-kereskedelem penzforgalma
6. Vissza a valutaprogram fomenujere

### 6.3. Penz atvetele egy egysegtel -- reszletes (kep_43.jpeg, kep_50.jpeg)

**Menu:**
1. Penz atvetele az ertektartol
2. Teljes keszlet visszavetele az ertektartol
3. (harmadik opcio elfedettt/aML bizonylat felulet)
4. Horvat kuna bekuldese
5. E-kereskedelem penzforgalma
6. Vissza a valutaprogram fomenujere

### 6.4. Pillanatnyi penztarallas kimutatasa (kep_51.jpeg, kep_52.jpeg)

**Tablazat oszlopok:** VNEM | VALUTA NEVE | NYITO | BEVETEL | KIADAS | KEZ-I DIJ | ZARO

**Penztarkeszlet (BEKESCSABA BELVAROS 2024.03.12):**
| Valuta | Nev | Nyito | Zaro |
|--------|-----|-------|------|
| BGN | BOLGAR LEVA | 235 | 235 |
| CHF | SVAJCI FRANK | 680 | 680 |
| CZK | CSEH KORONA | 2 000 | 2 000 |
| EUR | EURO | 5 380 | 5 380 |
| HUF | MAGYAR FORINT | 3 531 465 | 3 531 465 |
| ILS | IZRAELI SEKEL | 400 | 400 |
| PLN | LENGYEL ZLOTYI | 440 | 440 |
| RON | UJ ROMAN LEI | 4 730 | 4 730 |
| RSD | SZERB DINAR | 8 060 | 8 060 |
| TRY | TOROK LIRA | 635 | 635 |
| USD | USA DOLLAR | 100 | 100 |

**Gombok:** PILLANATNYI ALLAS KINYOMTATASA | KEZELESI DIJ NYOMTATASA | VISSZA A FOMENURE (Escape)

---

## 7. Zarasok es cimletez

### 7.1. Cimletez -- Zarasok fomenu (kep_12.JPG)

**Cim:** "CIMLETEZEES - ZARASOK"

**Cimletez almenui:**
- ESTI ZARAS CIMLETEZEESE
- KEZELESI DIJ CIMLETEZEESE
- WESTERN UNION CIMLETEZEESE
- AFA PENZTAR CIMLETEZEESE
- ELEKTROMOS KERESKEDES CIMLETEZEESE

**Bal oldali menu (felig lathato):**
- KULONFELE CI[MLETEK]
- CIMLETEK KI[NYOMTATASA]
- A MAI NAPI ZARAS [...]
- A HAVI ZARAS V[EGREHAJTASA]

**Gombok:** VISSZA | KILEPES

### 7.2. Valuta penztar cimletezeese (kep_33.jpeg)

**Bal panel -- Valutanemek listaja:**
AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD

Mindegyik valutanem mellett piros/feher indicator (van-e keszlet)

**Jobb panel -- Cimletek (CHF kivalasztva):**
| Cimlet | Darab | Ertek |
|--------|-------|-------|
| 20 000 | | |
| 10 000 | | |
| 5 000 | | |
| 2 000 | | |
| 1 000 | 0 | 0 |
| 500 | | |
| 200 | 0 | 0 |
| 100 | 4 | 400 |
| 50 | 1 | 50 |
| 20 | 8 | 160 |
| 10 | (pipa) | 70 |

**Also:** CHF 680 680 (osszeg es ellenorzes)
**Gomb:** CIMLETEK RENDBEN - TOVABB

**Uzleti logika:** Minden valutanemben kulon cimletezni kell a keszletet (bankjegy-szamolas). A cimletezesnel 20.000-tol 5 Ft-ig szamoljak a cimleteket. A program osszeveti a szamolt erteket az elmeleti keszlettel.

### 7.3. Dekadzaras (kep_13.jpeg)

**Cim:** DEKADZARAS
**Mezok:** Ev (2024) | Honap (MARCIUS) | Dekad (1. DEKAD)
**Gombok:** NYOMTATAS | MEGSEM

**Uzleti logika:** A honapot 3 dekadra osztjak (1-10., 11-20., 21-honap vege). A dekadzaras egy idoszaki lezaras, amely osszesiti a 10 napos idoszak forgalmat.

### 7.4. Ertektari zaras elotti checklista (kep_17.JPG)

**Cim:** "ERTEKTARI ZARAS ELOTTI CHECKLISTA"

**Elemek (checkbox):**
1. Minden penztar keszlete feltoltve (cimletek, fem euro)
2. Esetleges helyettesiteskor kolleganak minden info atadasolapon atadva.
3. Grafikon kitoltve, kifuggesztve erintetteknek tovabbitva.
4. Konkurencia arfolyamainak, keszleteinek figyelmemmel kovetese.
5. Konkurencia jelentes megirasa (eseti)
6. Probavasarlas (eseti)
7. Havi beszamolo megirasa (eseti)
8. Bizonylatok parositas, lefuzese.
9. Kktg beszedese, befizetese (eseti)
10. E-ker beszedese, befizetese (eseti)
11. Jutalek befizetese (eseti)
12. TRB tabla kitoltese
13. Egyedi arfolyamos tabla kitoltese, tovabbitasa az erintetteknek (eseti)
14. Egyedi arfolyamok ellenorzese, tovabbitasa az erintetteknek (eseti)
15. Nagy ugyfeltablak begyujtese, osszesitese, tovabbitasa erintetteknek (eseti)
16. Konyvlesek lenyomtatasa, lefuzese, adatainak ellenorzese
17. Havegi egyeztetes teruletekkel (eseti)
18. Havegi egyeztetes penztarakkal (eseti)
19. Napi jelentesek jelszavainak elkuldese SMS-ben a penztaraknak, ertektarosoknak stb. (eseti)

**Also:** Datum: 2024.03.12 | Penztaros neve: SARKADI TUNDE
**Gombok:** ZARAS RENDBEN | MEGSEM ZAROM A NAPOT

### 7.5. Zarast ellenorzo szemely adatai (kep_18.JPG)

**Cim:** "ZARAST ELLENORZO SZEMELY ADATAI"
**Alcim:** (A zaros szalagot kerem alairni)

**Mezok:**
- NEVE: (sarga hatterrel)
- BEOSZTASA: (ures)

**Gombok:** ELLENORZO SZEMELY ADATAI RENDBEN | MEGSEM ZAROM A NAPOT

**Uzleti logika:** A zarasnal egy masodik szemely (ellenor) hitelesiti a zarast. A zaroszalag (penzszallitasi zsak lezaro szalag) alairasra kerul.

### 7.6. Napi osszefoglalo (kep_41.jpeg, kep_39.jpeg)

**Ez a fo napi lezarasi kepernyoe.** 3-4 fontos szekcioval:

**Bal felso:** 2024.03.12 | EKESCSABA BELVAROS I
- Osszesen zaro keszlet F9
- Forint: 3 531 465, Valuta: 3 036 941, Osszesen: 6 568 406

**Bal kozep -- Pillanatnyi penztarallas:**
| DNEM | KESZLET | VETEL | ELADAS |
|------|---------|-------|--------|
| BGN | 235 | 0 | 0 |
| CHF | 680 | 0 | 0 |
| CZK | 2000 | 0 | 0 |
| EUR | 5380 | 0 | 0 |
| HUF | 3531465 | 0 | 0 |
| ILS | 400 | 0 | 0 |
| PLN | 440 | 0 | 0 |
| RON | 4730 | 0 | 0 |
| RSD | 8060 | 0 | 0 |
| TRY | 635 | 0 | 0 |
| USD | 100 | 0 | 0 |

**Kozepso -- NAPI FORGALOM:**
VETEL / ELADAS oszlopok de/du (delolott/delutan) bontasban, Ossz.

**Kozepso -- Forint keszlet (cimletezesve):**
| Cimlet | DE darab | Cimlet | DU darab |
|--------|----------|--------|----------|
| 20 000 | 58 | 200 | 2 |
| 10 000 | 195 | 100 | 16 |
| 5 000 | 48 | 50 | 20 |
| 2 000 | 71 | 20 | 26 |
| 1 000 | 28 | 10 | 42 |
| 500 | 15 | 5 | 5 |

**Euro erme keszlet:** 2, 6, 1, 3 (cimletenkent)

**KULOK / KEREK:** szoveges mezok (kuld/kerek uzenet az ertektar fele)

**Also -- Kiegeszito szekciol:**
- WESTERN UNION ZARO KESZLETEI: HUF / USD
- KEZELESIDIJ: 14 405 Ft
- E-KERESKEDELEM: -
- Jelentes bekuldese / Most nem kuldom be (gombok)
- AFA INNOVA KESZLET: HUF -

**Jobb felso -- EGYEDI ARFOLYAMOK:**
Val. | Osszeg | ARF | Bizonylat (szines sorok)

**Jobb also:**
- Ptaros de: (ures)
- Ptaros du: TABULYA ZSUZSANNA

---

## 8. Listak es riportok

### 8.1. Kulonfele listak menu (kep_32.jpeg)

**Cim:** "KULONFELE LISTAK"

**Menu elemek:**
1. KIADOTT BIZONYLATOK LISTAI
2. PENZFORGALOM A PENZTARAK FELE
3. TRB FORGALMI LISTAK
4. ELADASI - VETELI STATISZTIKA
5. HAVI TABLOK ATTEKINTESE
6. PILLANATNYI KESZLETEK
7. HAVI KEDVEZMENYEK LISTAJA
8. DEKAD VAGY NAPIZARAS KONYVELEESE
9. KEZELESI DIJAK LISTAJA
10. MEGSEM

### 8.2. Osszesitett penztarforgalom (kep_42.jpeg)

**Cim:** "OSSZESITETT PENZTARFORGALOM"
**Mezok:** Ev (2024) | Honap (MARCIUS) | Naptol (1) | Napig (31)
**Gombok:** IDOSZAK RENDBEN | CSAK A MAI NAP | MEGSEM

### 8.3. Havi tablok kijelzese (kep_21.JPG)

**Cim:** "HAVI TABLOK KIJELZESE"
**Helyszin:** GYULA | 2024 MARCIUS

**HAVI TABLO FOMENUJE:**
1. HAVI STATISZTIKA
2. HAVI FORGALOM
3. FORGALMI GRAFIKONOK
4. VALUTA KESZLETEK
5. FORGALOM-EXCEL KESZITESE
6. KESZLET-EXCEL KESZITESE
7. VISSZA A FOMENURE

**Jobb panel:**
- KIJELZETT HONAP: 2024 | MARCIUS (+ HONAP RENDBEN gomb)
- VALUTAVALTO EGYSEG: GYULA (legordulo)

### 8.4. Kezelesi koltsegek menu (kep_22.JPG)

**Cim:** "KEZELESI KOLTSEGEK"

**Menu elemek:**
1. KEZELESI KOLTSEGEK ATVETELE
2. KEZELESI KOLTSEGEK ATUTALASA
3. A KEZELESI KOLTSEGEK JELENLEGI KESZLETE
4. BIZONYLATOK MEGTEKINTESE
5. VISSZA

---

## 9. Bizonylatok (nyomtatott, 14 kep)

### 9.1. Dekadzaras bizonylat (biz_00.jpeg)

**Fejlec:**
```
105. PENZTAR
BIKISCSABA BELVAROS II.
BIKISCSABA ANDRASSY U. 24-28.

2024 MARCIUS HAVI 1. DEKADZARAS
2024.03.01 - 2024.03.10
```

**Tetelek:**
| Sor | Np | Biz.szam | Ft.atvetel | Ft.atadas |
|-----|-----|----------|-----------|-----------|
| 024 | 01 | UF10500086 | 2.000.000 | (75) |
| 025 | 07 | UF10500086 | 2.000.000 | (75) |
| 026 | 08 | FF10500183 | (75) | 2.000.000 |
| 027 | | V.veteli | | 2.850.885 |
| 028 | | V.eladi | 268.315 | - |

**Osszesites:**
- Dekad forgalom: 4.xxx.315 -- 4.850.885
- Nyito forinti: 1.xxx.460
- Zaro forinti: 915.890
- Osszes forinti: 5.7xx.775 -- 5.766.775

### 9.2. Arfolyam nyomtatas + Penztarosi nyilatkozat (biz_01.jpg)

**3 kulon bizonylat egy lapon:**

**1. Arfolyam lista (bal):**
```
EXCLUSIVE BEST CHANGE ZRT
105 BIKISCSABA BELVAROS II.
2024.03.12  14:05 orai valuta arfolyamok

Valuta  Egyseg  Veteli    Eladasi
nem             arfolyam  arfolyam
AUD  100  22670.00  24129.00
BAM  100  19000.00  21470.00
BGN  100  19109.00  21211.00  [stb 29 valuta]
...
USD  100  35870.0000  36479.0000
```

**2. Elszamolo arfolyamok (kozepso):**
```
2024.03.12  14:05 orai elszam arfolyamok
Valuta  A valuta megnevezese  Elszamolo arfolyam
AUD AUSZTRAL DOLLAR  23630.0000
...
USD USA DOLLAR  36320.0000
```

**3. Penztarosi nyilatkozat (jobb):**
```
PENZTAROSI NYILATKOZAT
NYILATKOZAT
Alulirott VIRAG MARGIT
az EXCLUSIVE BEST CHANGE ZRT
76. szamu penztaranak dolgozoja ki-
jelentem, hogy a 2024.03.09 napi zaro-
szalagon szereplo osszegek a valosagnak
megfelelnek es a penztar trezorjaban
elzarasra kerultek, es ezt alairasommal
elismerem.

Ezen nyilatkozat az unnepi / vasarnapi
zarvallartas miatt keszult.

Datuma: 2024.03.09
penztaros [alairas]
```

### 9.3. Extra tranzakcios dijak + Foglalo + Penztari adatlap (biz_02.jpg)

**Extra tranzakcios dijak lista:**
```
Datum/Biz.  Ftossz/Kez.dij  Engedelyezo
2024.03.06  307,800 Ft  EGYEDI KEZDIJ  500 Ft
2024.03.07  775,800 Ft  EGYEDI KEZDIJ  1,180 Ft
2024.03.11  35,830 Ft  EGYEDI KEZDIJ  60 Ft
2024.03.11  1,024,474 Ft  EGYEDI KEZDIJ  1,250 Ft
```

**Penztari adatlap (kezi, nyomtatott):**
- Penztarszam, datum, atvevok/atvevok nevei
- Korlevelek
- Ugyfelek rendelese, keszlet rendelese ertektar fele
- Konkurenciaval kapcs tudnivalok
- "20 percenkent Correct arfolyam kuldis HRK Hrvig NE"
- "Northline Min 2x egy Nap+ Ibusz a szollat"
- Egyeb tudnivalok: "Szkennelni gipre 300E felett asztal, dok, szken. Hiba miatt, majd antival berakatni"

**Foglalo (jobb oldal):**
Azonos tartalom, kezirassal kiegeszitve.

### 9.4. Forint atveteli bizonylat (biz_03.jpg)

**Fontos bizonylat -- EUR vasarlas:**
```
NYUGTA
EXCLUSIVE BEST CHANGE ZRT
105 BIKISCSABA BELVAROS II.
BIKISCSABA ANDRASSY U. 24-28.
Telefon: 06703800161
Adoszam: 32313332-2-02
Valuta vetel
EXCHANGE (PURCHASE)

Sorszam (INVOICE NR) : V105007798
Datum  (DATE)        : 2024.03.12
Ido   (TIME)         : 12:26
(Nyugtaszam: 0000/00000)

Szj - 67.13.10.0
M.M.M. a szolgaltatas nyujtasa a 2007
evi CXVII tv. 86 & f) alapjan mentes az
ado alol

V.nem  Arfolyam  B.jegy    Forint
CURR.  RATE      CASH      VALUE
EUR    38,840    26,000    10,098,400

Kerekites (ROUNDING)  : 0
Netto Ft (SUM TOTAL) : 10,098,400
Kez. klsg (HANDLING FEE) : 9,990
Kifizetve(PAID):10,088,410

----- ugyfeel adatai -----
Nev (NAME): ANDRASI ROLAND
anyja neve: PECSBRA ANGELIKA
szul-i hely: UKRAJNA
szul-i ido: 1998.06.10
Lakcim (ADDRESS):
5800 MEZOKOVESCSABZA VASARHELYI SANDOR UT
DOC TYPE: SZIG
NR.: 840024HE  Az ugyfel nem kozszereplo
Az ugyletet keszpenzben teljesitjuk
Deviza-statusz: Belfoldi
```

**JOGCIM NYILATKOZAT (jobb oldal):**
```
Buntetojogi felelossegen tudataban nyi-
latkozom, hogy a fenti tranzakciot
KOSA ZOLTON
megbizasabol bonyolitom.

Nem (vagyok) kiemelt kozszereplo
Tudomasom van arrol, hogy 5 (ot) munka-
napon belul koteles vagyok bejelenteni a
szolgaltatonak a fenti adatokban, vagy a
sajat adataimban bekovetkezo esetleges
valtozasokat, es e kotelezettség elmu-
lasztasabol eredo kar engem terhel

Plineszt k.t.h. forrast: GH

ugyfél alairasa
```

**Uzleti szabalyok:**
- Bizonylat ketnyelvue (magyar + angol)
- NAV SZJ-kod: 67.13.10.0 (valutavaltas)
- AFA-mentes (2007 evi CXVII tv. 86. & f))
- Kezelesi koltseg (HANDLING FEE) kulon sor
- 5 Ft-os kerekites ("ROUNDING")
- Ugyfeladatok AML kovetelmeny: nev, anyjaneve, szuletesi hely/ido, lakcim, okmany tipus/szam, kozszereplo statusz, deviza statusz, penz forrasa
- Jogcim nyilatkozat: buntetojogi felelosseg, kozszereplo statusz, adatvaltozas bejelentesi kotelezettseg

### 9.5. Havi zaras bizonylatok (biz_04.jpg, biz_05.jpg)

**Havi zaras (biz_04.jpg) -- Reszletes bontasban:**
Minden valutanemre kulon:
- Nyito keszlet
- Vetel-Elad mennyiseg
- Atvet-Atad (ertektarbol/-ba)
- Tobbl-Hiany
- Zaro keszlet

**Havi zarokeszlet taablazat:**
| Dnem | Keszlet | Arfolyam | Ertek |
|------|---------|----------|-------|
| AUD | 700 | 23,606 | 165,242 Ft |
| BAM | | 19,537 | |
| BGN | 1,715 | 20,139 | 345,303 Ft |
| ... | | | |
| HUF | 5,076,930 | 100 | 5,076,930 Ft |
| ... | | | |
| Osszes keszlet erteke: | | | 8,717,520 Ft |
| Forint keszlet: | | | 5,076,930 Ft |
| Mindosszesen: | | | 13,794,450 Ft |

**Kezelesi koltsegek:**
- Havi nyito osszeg: 570,905
- Kezelesi koltseg: 412,055
- Atvett osszeg: (ures)
- Atadott osszeg: 570,905
- Havi zaro osszeg: 412,055

**Western Union forgalom zarasa:**
- Usa dollar / Magyar Forint
- Nyito, Bevetel, Kiadas, Zaro

**A havi ugyfel forgalom:**
- Elado ugyfelek: 685 FO
- Vevo ugyfelek: 384 FO

**Havi forgalom osszesites:**
- Havi vetelnel kiadas: 177,000,845 Ft
- Havi eladasnal bevetel: 64,766,690 Ft
- Havi eladas bankkartyaval: (ures)

### 9.6. KKTG atadas es atvetel (biz_06.jpg, biz_12.jpg)

**Kezelesi koltseg atveteli bizonylat:**
```
EXCLUSIVE BEST CHANGE ZRT.
75. BIKISCSABA
ANDRASSY UT 24-28
Adoszam: 32313332-2-02
Tel: 06/66-448-500
KEZELESI KOLTSEG ATVETELI BIZONYLATA

Bizonylatszam: B-000756
Bizonylat kelte: 2024.10.15
Atado penztari: 0074
Atvett osszegi: 1,000,000 Ft

Szallitonev: lovasz janos
Plomba-szam: 2113068
Megjegyzes:

atado          atvevo
```

**Kezelesi koltseg atadasi bizonylat:**
```
KEZELESI KOLTSEG ATADASI BIZONYLATA
Bizonylatszam: K-000755
Bizonylat kelte: 2024.10.15
Atvevo penztari: RB
Atadott osszegi: 5,347,015 Ft

Szallitonev: lovasz janos
Plomba-szam: 2161600
```

### 9.7. Kezelesi koltseg dekadzarasa es penztari atadas (biz_07.jpg)

**4 bizonylat egy lapon:**

**1. Kezelesi koltseg dekad (10 nap):**
- Dekad forgalom: 7,605 -- 105,585
- Nyito forinti: 105,585
- Zaro forinti: 7,605
- Osszes forinti: 113,190 -- 113,190

**2. Dekadzaras (penztarmozgas):**
- Sor Np Biz.szam Ft.atvetel Ft.atadas
- Dekad forgalom: 4,263,315 -- 4,050,005

**3-4. Penztari atadas (atado forint) -- Mosolati pildany:**
```
Penztari atadas
Atvevo: 76 -
MOSOLATI PILDONY

Sorszam (INVOICE NR): FF07541444
Datum  (DATE): 2024.03.11
Ido  (TIME): 14:21
Adomentes Szj-67.13.10.0

V.nem  Arf.     B.jegy    Forint
CURR.  RATE     CASH      VALUE
HUF  100.0000  1,631,650  1,631,650
Kifizetve(PAID): 1,631,650

SZALLITO NEVE: ertektar
PLOMBA SZAMA: X
```

### 9.8. Napi zaras (biz_08.jpg)

**Nagy, osszesito bizonylat 4+ reszen:**

**1. Zarasi nyomtatvany:** Valuta vasarlasok es eladasok
**2. Penztar allas:** Val. | Nyito osszeg | Forgalom egyenlege | Penztar allas
**3. Napi zarokeszlet:** DNEM KESZLET ARFOLYAM ERTEK (11 valuta)
- Osszes keszlet: 3,036,941
- Forint keszlet: 3,531,465
- Mindosszesen: 6,568,406
**4. Napi forgalom kimutatasa I.:** Datum, ido, valutankent nyito/vetel/eladas
**5. Havi bankjegy-forgalom kimutatasa I-II:** Minden valuta reszletes mozgasa
**6. Kezelesi koltseg 2024.03.12-i listaja:**
- Napi nyito osszeg: 14,405
- Kezelesi koltseg: -
- Atvett osszeg: -
- Atadott osszeg: -
- Napi zaro osszeg: 14,405
**7. Horvat kuna lista** (napi)
**8. Buntetojogi felelossegen... nyilatkozat** (penztaros alairasa)

### 9.9. Penztar allas kis nyugta (biz_09.jpg)

**Forgoszalagos (szalagnyomtatos) nyugta, oldalra forditva:**
```
EXCLUSIVE BEST CHANGE ZRT
75 BIKISCSABAI IRTIKUR

2024.03.12  10:10 perci penztar allasi

Val.  Nyito      Forgalom     Penztar
nem   osszeg     egyenlege    allas
CHF   12,500                  2,500
CZK   15,000                  15,000
EUR   102,000    -65,000       17,000
HUF   33,422,000 20,835,180    54,257,180
ILS   7,000                   7,000
PLN   24,500                  24,500
RON   59,600                  59,600
RSD   50,000                  50,000
TRY   9,000                   9,000
USD   18,150                  18,150
```

Masodik resz:
```
2024.03.12  10:10-i kez-i dij egyenlegei
Napi nyito kez-i dij..: 3,482,805 Ft
Kezelesi dij atvetel..: -Ft
Kezelesi dij atadas...: -Ft
Pillanatnyi zaro osszegi: 3,482,805 -Ft
```

### 9.10. Penztari atadas (egyedi kotes RB) (biz_10.jpg)

**Oldalra forditott nyugta:**
```
EXCLUSIVE BEST CHANGE ZRT.
75. BIKISCSABA
ANDRASSY UT 24-28
Adoszam: 32313332-2-02
Tel: 06/66-448-500

Atvevo: ERB - EGYEDI KOTES RB

Sorszam (INVOICE NR) : FO7514435
Datum  (DATE)         : 2024.03.12
Ido   (TIME)          : 09:45:24

Adomentes    Szj - 67.13.10.0

V.nem  Arf.       B.jegy    Forint
CURR.  RATE       CASH      VALUE
EUR  39448.0000   15,000    5,912,700

Kifizetve(PAID): 5,912,700

SZALLITO NEVE: LOVASZ JANOS
PLOMBA SZAMA: 2119275

atvevo [alairas]
```

### 9.11. Zaras-Ertektar (biz_11.jpeg)

**Teljes ertektari zaras bizonylat -- igen reszletes, 3 reszes:**

**1. Ertektari zaras elotti checklista** (bal oldal, kezi jeloles)
**2. Napi bankjegy-forgalom kimutatasa I-II** (kozep)
**3. 2024 Februari penztar zaras** (jobb) -- havi zaras

**Tartalmazza:**
- Penztarak kozotti mozgasok osszesite (Dnem, Atadott, Atvett)
- Penztar allas minden valutanemben
- Western Union forgalom (USD + HUF)
- AFA visszaigenyeles forgalom
- Kezelesi koltsegek havi listaja
- E-kereskedelmi mozgasok
- Horvat kuna havi zarasa

### 9.12. Penztari atvetel (biz_13.jpeg)

**Penztari atvetel bizonylat:**
```
EXCLUSIVE BEST CHANGE ZRT.
75. BIKISCSABA
ANDRASSY UT 24-28
Adoszam: 32313332-2-02
Tel: 06/66-448-500

Penztari atvetel
Atado: 0074 -
MOSOLATI PILDONY

Sorszam (INVOICE NR): U075141183
Datum  (DATE):        2024.03.11
Ido   (TIME):         14:52
Adomentes  Szj - 67.13.10.0

V.nem  Arf.          B.jegy    Forint
CURR.  RATE          CASH      VALUE
CHF    41220.0000    3,000     1,236,600
EUR    39530.0000    25,000    9,882,500

Kifizetve(PAID): 11,119,100

SZALLITO NEVE: lovasz janos
PLOMBA SZAMA: 2113176

Bhtet.felelossegen tudataban kijelen-
tem, hogy a fentiekben felsorolt penz-
keszletet a szallitotol atvettem, azt
teljesen visszaszamoltam.

atado         atvevo
```

---

## 10. Dokumentumok (jelentesek, 3 kep)

### 10.1. Havi forgalom -- Bekescsaba korzet osszesen (dok_00.jpg)

**Cim:** BEKESCSABA KORZET 2024 MARCIUS FORGALMI ADATAI / BEKESCSABA KORZET OSSZESEN

**Tablazat:**
| Datum | Vetel (Ft) | Eladas (Ft) | Ugyfelek szama Vevok | Ugyfelek szama Eladok | Penztaros neve |
|-------|-----------|-------------|------|--------|---------|
| 2024.03.01 | 25 468 726 | 5 957 504 | 130 | 52 | SARKADI TUNDE |
| 2024.03.02 | 14 153 382 | 3 454 314 | 79 | 42 | |
| ... | | | | | |
| 2024.03.11 | 33 333 355 | 11 257 686 | 98 | 64 | SARKADI TUNDE |
| **OSSZESEN** | **260 200 677** | **77 006 329** | **963** | **586** | |

**Statisztikak:**
- Munkanap: 11 nap
- Atl.forg: 23 654 607 / 7 000 575
- Trend: 136,47% / 104,94%
- Elozo ho: 17 331 942 / 6 670 568

**Uzleti logika:** Korzeti szintu osszesito jelentes -- a Bekescsaba korzet (tobb fiok) osszesitett forgalmi adatai. Tartalmazza a penztaros nevet, az ugyfelek szamat vevo/elado bontasban, es a trend %-ot az elozo honaphoz kepest.

### 10.2. Kezelesi koltseg jelentes (dok_01.jpg)

**Cim:** EXCLUSIVE BEST CHANGE ZRT / KEZELESI KOLTSEG JELENTES

```
BEKESCSABA ertektar
ANDRASSY UT 24-28
2024 marcius 12 kedd

Sorszam  Bizonylatszam  Tranzakcio       Bank/ptar  Bevetel     Kiadas
000022   K-000675       forint - atadas  RB                     3.482.805.- Ft

BEVETELI BIZONYLATOK: 0 darab    KEZELESI DIJ: -         3.482.805.- Ft
KIADASI BIZONYLATOK: 1 darab     NYITO: 3.482.805.- Ft
                                 ZARO: [satirozott]       -
                                 OSSZESEN: 3.482.805.- Ft 3.482.805.- Ft

BEKESCSABA 2024.03.12              penztaros
```

### 10.3. Napi penztar jelentes (dok_02.jpg)

**Cim:** EXCLUSIVE BEST CHANGE ZRT / NAPI PENZTAR JELENTES

```
BEKESCSABA ERTEKTAR
ANDRASSY UT 24-28
2024 marcius 12 kedd

Sorszam  Bizonylatszam  Tranzakcio        Bank/ptar  Bevetel          Kiadas
000356   UF07529686     forint - atvetel  ERB        13.976.000.- Ft
000357   UF07529687     forint - atvetel  PRB         5.745.315.- Ft
000358   FF07541445     forint - atadas   JRB                         12.685.935.- Ft
000359   UF07529688     forint - atvetel  ERB        13.799.800.- Ft
000360   UF07529689     forint - atvetel  ERB         9.855.500.- Ft
000361   FF07541446     forint - atadas   RB                            148.160.- Ft
000362   UF07529690     forint - atvetel  ERB         5.925.000.- Ft
000363   UF07529691     forint - atvetel  76            500.000.- Ft

BEVETELI BIZONYLATOK: 6 darab    FORGALOM: 49.801.615.- Ft  12.834.095.- Ft
KIADASI BIZONYLATOK: 2 darab     NYITO: 33.422.000.- Ft
                                 ZARO: [satirozott]         70.389.520.- Ft
                                 OSSZESEN: 83.223.615.- Ft  83.223.615.- Ft

BEKESCSABA 2024.03.12              penztaros
```

---

## 11. Munkavallalo-kezeles (hatterrendszer)

A `Kepernykepek - Munkavallalo kulonbsegek` mappaban lathato kepek **NEM a legacy valutavalto programhoz**, hanem ket masik rendszerhez tartoznak:

1. **Rate Software** (Licence Kft., v1.361.0-20240208) -- HR rendszer
   - Modulok: Rendszer, HR, Munkaszervezes, Szamlazas, Raktarozas
   - Dolgozok kezelese: Szemelyi adatok (Kod, Titulus, Vezeteknev, Keresztnev, Egyedi jel, Allampolgarsag_1/2, Szuletesi adatok)

2. **Expressz Zalog** (v1.130-20240216) -- zalog ugykezelo rendszer
   - Modulok: Beosztas kezeles, Zalog, Beallitasok
   - Munkavallalio adatok: Fiokok es jogosultsagok, Jogviszony kezdete/vege, Dolgozoi statusza, Foglalkoztatas tipusa
   - Szabadsagok, Gyerekek, Egyeb iratok

**Relevancia:** Ezek a kepek a dolgozoi kezeles kulonbsegeit mutatjak a Rate Software es az Expressz Zalog rendszerek kozott -- valoszinuleg az uj rendszer tervezesehez gyujtott osszehasonlitas.

---

## 12. Hardver

### 12.1. Nyomtato (nyomtato.jpg)

**Model:** Star Micronics SP500
**Specifikaciok:** 100-240V, 0.35A, 50/60Hz
**Tipus:** Matrixnyomtato (szalagnyomtato) -- a bizonylatok, nyugtak nyomtatasahoz

### 12.2. Adatbazis diagram (penztari_mozgasok.PNG)

Egy ERD (Entity-Relationship Diagram) lathato, de a felbontas tul kicsi a reszletes elemzeshez. Tobb tablabol es kapcsolatbol all, a penztari mozgasok adatstrukturajahoz kapcsolodik.

---

## 13. Uzleti szabalyok osszefoglalasa

A kepernyokepek es bizonylatok elemzesebol az alabbi fo uzleti szabalyok szurhatok ki:

### 13.1. Arfolyam-kezeles
- **Kozponti arfolyam-keszites** a "0-s lapon" (master tabla) 29 valutanemmel
- **Tobbretegu arfolyamok:** elszamolo, OTP referencia, veteli, eladasi, gyenge multinacionalis, keresztarfolyam, nagybani, internet
- **Automatikus szarmaztatas:** csoportonkent fuggvennyel (#01M) szamolt arfolyam
- **Kedvezmenyes sAvok:** 3 szint (50K, 300K, 1M Ft)
- **Egyedi arfolyamok:** kulon "EGYEDI ARFOLYAMOK" szekci a napi osszefoglalon (TRB)
- **Szet kuldes:** ARFDATA.DAT file, 54 fiokba, szerveren at
- **Internet forrasok:** OTP, Realtime FX, NBH, stb.
- **Arfolyam-kijelzo:** LED tabla (zold/sarga/piros szin), fizikai kijelzo a kirakatban

### 13.2. Penztaros rendszer
- **Geptipusok:** Penztari gep, Ertektari gep, AFAS gep
- **Modularitas:** Valutavaltas, Western Union, Tesco AFA, Metro AFA, E-kereskedelem
- **Offline szinkron:** 2 percenkent adat-szinkron a szerverre (IP: 185.43.207.99)
- **F-billentyuk:** F1-Arfolyam, F2-Foglalo, F3-Terminal, F4-AFA tabla, F5-Mai forg, F6-Tesco AFA, F7-Supervisor, F9-Keszlet, F10-Atadolap, F11-Metro AFA, F12-W.Union, Esc-Kilepes

### 13.3. Tranzakciotipusok
- **Vetel (V):** valuta vasarlas ugyfeltol (ugyfel elad, penztar vesz)
- **Eladas (E):** valuta eladas ugyfelnek (ugyfel vesz, penztar elad)
- **Konverzio:** valuta-valuta csere
- **Forint atvetel (UF):** forint erkezes masik penztarbol/bankbol
- **Forint atadas (FF):** forint kuldese masik penztarba/bankba
- **Penz-atadas/atvetel:** ertektar es fiokok kozti mozgas
- **Sztorno:** tranzakcio visszavonasa
- **Egyedi kotes (TRB/ERB):** kulon arfolyamu, nagy erteku tranzakciok

### 13.4. Bizonylat-szamozas
- **V + penztarszam + sorszam** (pl. V105007798) -- veteli
- **E + penztarszam + sorszam** (pl. E105004177) -- eladasi
- **UF + penztarszam + sorszam** -- forint atvetel
- **FF + penztarszam + sorszam** -- forint atadas (fixing)
- **FO + sorszam** -- egyedi kotes
- **B-sorszam** -- kezelesi koltseg atveteli
- **K-sorszam** -- kezelesi koltseg atadasi
- **U + sorszam** -- penztari atvetel

### 13.5. Penztarstruktura
- **Fizikai penztarak:** 54 fiok, szammal azonositva (1-145)
- **Ertektarak:** kozponti raktarak (pl. 75-Bekescsaba Ertektar, 50-Debrecen Ertektar)
- **Specialis penztarak:** TH (Tobblet-Hiany), RB/ERB/TRB/JRB/PRB (banki), TV (Uton levo), WU (Western Union), UL (WU ellatmany), 20 (Teves konyveles), MNB
- **Fopenztar:** 1-es szamu
- **Csoportok:** 54 munkacsoport, csoportonkent mas arfolyam

### 13.6. Zaras-hierarchia
- **Napi zaras:** minden nap, penztaronkent
  - Pillanatnyi penztarallas (nyito/bevetel/kiadas/kezelesi dij/zaro)
  - Forint cimletezees (20.000 -> 5 Ft)
  - Euro erme cimletezees
  - Valuta cimletezees (minden valutanem kulon)
  - Napi forgalom kimutatasa (vetel/eladas)
  - Kezelesi koltseg napi listaja
  - Western Union keszlet
  - Penztarosi nyilatkozat
  - Zarast ellenorzo szemely adatai + alairas
- **Dekadzaras:** 10 naponta (1-10., 11-20., 21-honap vege)
  - Dekad forgalom osszesites
  - Kezelesi koltseg dekadzarasa
- **Havi zaras:** minden valuta reszletes mozgasa
  - Havi zarokeszlet (valutanev, keszlet, arfolyam, ertek)
  - Havi forgalom osszesites
  - Kezelesi koltsegek havi listaja
  - Western Union havi zarasa
  - Horvat kuna havi zarasa
  - Havi ugyfelforgalom (elado/vevo ugyfelek szama)
  - Havi bankjegy-forgalom kimutatasa I-II
- **Ertektari zaras:** bovebb checklista (19 pont)

### 13.7. Cimletezees
- **Forint cimletek:** 20.000, 10.000, 5.000, 2.000, 1.000, 500, 200, 100, 50, 20, 10, 5
- **Euro ermek:** kulon szamolva (2, 1, 0.50, 0.20 euro)
- **Valuta cimletek:** minden valutanemben kulon cimletezes (pl. CHF 1000, 200, 100, 50, 20, 10)
- **Esti zaras cimletezes, Kezelesi dij cimletezes, WU cimletezes, AFA penztar cimletezes, E-kereskedelem cimletezes** -- kulon-kulon

### 13.8. AML (Anti-Money Laundering)
- **Ugyfeladatok rogzitese:** nev, szuletesi adatok, anyja neve, lakcim, okmany tipus/szam
- **Statuszok:** deviza statusz (belfoldi/kulfoldi), kozszereplo statusz
- **Jogcim nyilatkozat:** buntetojogi felelosseg, megbizo neve (ha mas neveben jar el)
- **10 millio Ft feletti tranzakciok:** kulon mezo a kepernyooen
- **Penz forrasa:** kotelezoen kitoltendo
- **Engedelyezo:** ki hagyta jova a tranzakciot
- **Szkenner:** igazolvany szkenneles (CanoScan Lide 120)

### 13.9. Kezelesi koltseg (handling fee)
- Kulon penztarkent kezelt (kezelesi koltseg penztar)
- Napi nyito/zaro osszeg nyilvantartasa
- Atveteli es atadasi bizonylatok (B-/K- prefix)
- Dekad- es havi szintu zarasa
- Plombaszam es szallito nev rogzitese az atvtelenel

### 13.10. Penztarak kozotti mozgas
- **Penz atvetele az ertektartol** (keszlet feloltese)
- **Teljes keszlet visszavetele** (fiok bezaraskor)
- **Kezelesi dijak atadasa-atvetele**
- **Horvat kuna kulon kezeles** (kulon menupont)
- **E-kereskedelem penzforgalma**
- **Szallitasi adatok:** szallito neve, plombaszam (biztonsagi pecsett), megjegyzes
- **"Konyvelheto" gomb** = veglegesites

### 13.11. Riportok es listak
- Kiadott bizonylatok listai
- Penzforgalom a penztarak fele
- TRB forgalmi listak
- Eladasi-veteli statisztika
- Havi tablok attekintese (statisztika, forgalom, grafikonok, keszletek, Excel export)
- Pillanatnyi keszletek
- Havi kedvezmenyek listaja
- Dekad vagy napizaras konyveles
- Kezelesi dijak listaja
- Korzeti osszesito (pl. Bekescsaba korzet forgalmi adatai)
- Napi penztar jelentes
- Kezelesi koltseg jelentes

### 13.12. Egyeb
- **Futofeny:** LED kijelzo szoveg (hirkero)
- **Korlevelek:** belso kommunikacio a penztarok fele
- **Nevtelen bejelentes:** gomb az also savon
- **Penztar szunet:** szunet jelzes
- **Supervisor mod:** F7 gomb, valoszinuleg emelt jogosultsagu mod
- **Szombati nyitvatartas:** be/ki kapcsolhato penztaronkent
- **Napi stornozott bizonylat szamlalo:** lathato az also savon (pl. "6")
- **Penztarosi nyilatkozat:** napi zaraskor, unnep/vasarnap eseten kulonosen fontos
- **Szoftver gyarto:** dekanySoft (lathato a fomenu also reszem)
- **Cegnev:** Exclusive Best Change ZRT
- **Verziok:** 04.00 (legacy Delphi), 35.25 (ujabb verzio)

---

## Forras: docs\legacy-analysis-part3-spreadsheets.md

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

---

## Forras: docs\legacy-analysis-part4-technical.md

# Legacy Drive technikai elemzes - Part 4: Delphi forrasko, adatbazis sema es konfiguracio

## 1. Fajl statisztikak osszesites

| Fajltipus | Darab | Megjegyzes |
|-----------|-------|------------|
| `.pas` (Delphi Pascal) | 1 102 | Teljes uzleti logika forraskodja |
| `.dpr` (Delphi Project) | 661 | DLL projekt fajlok |
| `.dfm` (Delphi Form) | 1 099 | UI layout definiciok |
| `.dcu` (Compiled) | ~600+ | Leforditott egysegek |
| `.cfg` (Config) | ~150+ | Delphi forditasi konfiguraciok |
| `.sql` | 163 | Adatbazis migraciok (Zalog EXZ01 rendszer) |
| `.fdb` (Firebird DB) | 9 | Elo adatbazis fajlok |
| `.gdb` (InterBase DB) | 3 | Regebbi InterBase adatbazisok |
| `.html` (Figdoc) | ~900 | v2.0 tervezesi dokumentumok |
| `.csv` | ~6 | Banki import/jelentes mintak |
| `.txt` | ~45 | Konfiguraciok, jelentesek, protokollok |
| `.bin` (atnevezett) | 4 | 2 db EU szankcios lista (UTF-8), 1 PNG, 1 Excel |
| `.xlsx` | 1 | Delphi licenc arak |

## 2. Delphi forrasko architektura (Regi-Valuta-program)

### 2.1 Rendszer felepites

A legacy rendszer harom fo reszbol all:

```
Regi-Valuta-program/
  ERTEKTAR/          # Penztari kliens (penztar gepen fut)
    database/        # Lokalis Firebird adatbazisok
    etdll/           # ~55 DLL modul (uzleti logika)
  SZERVER/           # Szerver oldali alkalmazasok
    fejleszt/        # ~80+ szerver modul
    ujdll/           # ~35 ujabb szerver DLL
    newdll/          # Legujabb szerver DLL-ek
  VALUTA/            # Valutalvas-specifikus modulok
    DLL/             # Altalanos DLL-ek
    IBVALTO/         # InterBase valto modul
    TRADE/           # E-kereskedelem (AAK matrica, mobil feltoltes, PaySafeCard)
```

### 2.2 Penztari kliens DLL modulok (ERTEKTAR/etdll/)

| DLL neve | Funkció | Uzleti jelentes |
|----------|---------|-----------------|
| `arftmk` | Arfolyam karbantarto | Arfolyamok beolvasasa FTP szerverrol, megjelenitese |
| `atadolap` | Atadolap | Penztarok kozti keszlet atadas dokumentuma |
| `atadvet` | Atadas-avetel | Penztarkozt keszlet transzfer |
| `bizodisp` | Bizonylat megjelenito | Tranzakcio bizonylatok megjelenitese |
| `bloknyom` | Blokk nyomtatas | Penztargep blokk nyomtatas |
| `checklst` | Ellenorzo lista | Napzaras elotti validacio |
| `cimlctrl` | Cimlet kontroll | Cimletezes ellenorzes |
| `cimlet` | Cimletezes | Bankjegy cimletszamlalas (14 cimlet/valutanem) |
| `cimlmenu` | Cimlet menu | Cimletezes tipusvalaszto |
| `cimlnyom` | Cimlet nyomtatas | Cimletezes bizonylat nyomtatasa |
| `cimsetup` | Cimlet beallitas | Cimlet konfiguracio |
| `estizar` | Esti zaras | Nap vegi zaras elokeszites |
| `getarf` | Arfolyam lekerdezes | Aktualis arfolyamok lekerese |
| `getellen` | Ellenor lekerdezes | Ellenorzo szemely azonositasa |
| `getplomb` | Plomba lekerdezes | Plombaszam kezeles |
| `getptar` | Penztar lekerdezes | Penztar adatok lekerese |
| `havizar` | Havi zaras | Havi osszesito zaras es jelentes |
| `hrkatvevo` | HRK atvevo | Horvat kuna specialis kezeles |
| `hrkcimlet` | HRK cimletezes | Horvat kuna cimletezes |
| `idoszak` | Idoszak | Idoszakos lekerdezesek |
| `irarfoly` | Iroda arfolyam | Irodankenti arfolyam beallitas |
| `kcimlet` | Keszlet cimlet | Keszlet-cimlet osszevetes |
| `keszedit` | Keszlet szerkesztes | Keszlet modositas |
| `keszup` | Keszlet frissites | Keszlet update |
| `kezdij` | Kezelesi dij | Tranzakcios kezelesi dij szamitas |
| `korlev` | Korlevel | Hatosagi korlevel kezeles |
| `listak` | Listak | Kulonbozo listak megjelenitese |
| `logdisp` | Log megjelenito | Muveleti naplo megjelenitese |
| `logiro` | Log iro | Muveleti naplo rogzitese |
| `maktablak` | Makro tablazat | Makro-szintu tablazatok |
| `matptar` | Matrica penztar | AAK matrica ertekesites |
| `mentes` | Mentes | Adatmentes funkciok |
| `napijel` | Napi jelentes | Napi forgalmi jelentes generalasa |
| `napikezd` | Napi kezdes | Nap nyitasi folyamat |
| `napkonyv` | Napkonyv | Napi bizonylatkonyv |
| `napzar` | Napzaras | **KRITIKUS**: Teljes nap vegi zaras folyamat |
| `nifval` | NIF validalas | Valamilyen validacios modul |
| `nznyomt` | Napzar nyomtatas | Napzarasi jelentes nyomtatasa |
| `penztarak` | Penztarak | Tobb penztaros kezeles |
| `pillall` | Pillanatkep osszes | Osszes penztar pillanatkep |
| `pillkesz` | Pillanatkep keszlet | Keszlet pillanatkep |
| `prosbe` | Penztaros beleptetes | Penztaros bejelentkezes |
| `prostmk` | Penztaros karbantartas | Penztaros adatok karbantartasa |
| `ptarkesz` | Penztar keszlet | Penztar keszlet nyilvantartas |
| `ptartmk` | Penztar karbantartas | Penztar alap adatok karbantartasa |
| `quitform` | Kilepes | Kilepes megerosites |
| `ratectrl` | Rate kontroll | Arfolyam ellenorzes |
| `rateperm` | Rate permission | Arfolyam jogosultsag kezeles |
| `regen` | Regeneralas | Keszlet ujraszamolas a tranzakciokbol |
| `regizaro` | Regi zaras | Korabbi napok zaras potlasa |
| `storno` | Sztorno | **KRITIKUS**: Tranzakcio sztornirozasa |
| `super` | Supervisor | Supervisor jelszo ellenorzes |
| `supertsk` | Supervisor feladat | Supervisor specialis muveletek |
| `terminal` | Terminal | Terminal kezeles |
| `wunion` | Western Union | Western Union integraciok |

### 2.3 Szerver modulok (SZERVER/fejleszt/ - valogatott)

| Modul | Funkció |
|-------|---------|
| `arfolyam` | Arfolyam szerver - kozponti arfolyam kezeles |
| `archival` | Archivalas - regi adatok archiválása |
| `banklist` | Bank lista - banki osszekapcsolas |
| `beszam` | Beszamolo - hatosagi beszamolok generálása |
| `booking` | Foglalás - deviza elofoglalas |
| `confident` | Bizalmas - biztonsagi modul |
| `everseny` | E-verseny - versenyarfolyam figyelés |
| `forgdisp` | Forgalom megjelenito - forgalmi adatok |
| `gbakall` | GBak all - teljes adatbazis backup |
| `haszon` | Haszon - profitszamitas |
| `havitablo` | Havi tabla - havi osszesitok |
| `import` | Import - adatimport |
| `jelenlet` | Jelenlet - dolgozoi jelenleti iv |
| `jogi` | Jogi - jogi szemelyek kezelese |
| `kereso` | Kereso - tranzakcio kereso |
| `korlevel` | Korlevel - hatosagi korlevel |
| `monegram` | MoneyGram - MoneyGram integraciok |
| `napiment` | Napi mentes - napi backup |
| `newrate` | Uj arfolyam - arfolyam frissites |
| `permit` | Engedelyek - engedely kezeles |
| `police` | Rendorsegi jelentes - rendorsegi adatszolgaltatas |
| `postterm` | POS terminal - kartyaterminal integraciok |
| `terror` | Terrorlista - AML szankcios lista ellenorzes |
| `tranzacs` | Tranzakciok - tranzakcio kezeles |
| `tranzdb` | Tranzakcio DB - tranzakcio adatbazis |
| `tranzdij` | Tranzakcios dij - dijszamitas |
| `ufill18/19` | Ugyfel kitoltes - hatosagi adatlap kitoltes |
| `ugyfseek` | Ugyfel kereses - ugyfel nevalapú keresese |
| `western/westuni` | Western Union - WU integraciok |

## 3. Delphi uzleti logika reszletes elemzes

### 3.1 Sztorno folyamat (storno/makedll/unit2.pas)

**Adatbazis tablak:**
- `BLOKKFEJ` - Bizonylat fejlec (bizonylatszam, tipus, datum, ido, forintertek, tetel, storno)
- `BLOKKTETEL` - Bizonylat tetel (bizonylatszam, valutanem, arfolyam, bankjegy, forintertek, elojel)
- `VTEMP` - Ideiglenes tabla (munka tabla)
- `UTOLSOBLOKKOK` - Utolso bizonylat szamok nyilvantartasa
- `PENZTAR` - Penztar alap adatok (penztarkod)
- `HARDWARE` - Penztargep allapot (megnyitottnap, napistorno)

**Tranzakciotipusok:**
- `U` = Devizavetel (Ugyfel ad devizat, kapja a HUF-ot)
- `F` = Deviza eladas (Ugyfel kap devizat, fizet HUF-ot)
- `UF` = Deviza-deviza atvaltas vetel iranyba
- `FF` = Deviza-deviza atvaltas eladas iranyba

**Sztorno logika:**
1. Eredeti bizonylat `STORNO` mezojet 1-rol 2-re allitja (BLOKKFEJ es BLOKKTETEL)
2. Uj sztorno bizonylat keszul `STORNO=3` mezoertekkel
3. Osszes osszeg negativ elojellel kerul be: `bankjegy*(-1)`, `forintertek*(-1)`
4. Uj bizonylat szamot general az `UTOLSOBLOKKOK` tablabol
5. Blokk nyomtatas tortenik (1 vagy 2 peldany)
6. Napi sztorno szamlalo novekszik (`HARDWARE.NAPISTORNO`)
7. Regeneralas (keszlet ujraszamolas)

**Bizonylat szam formatum:**
- `U` + penztarkod(3 jegy) + sorszam(6 jegy) - pl. `U001000123`
- `UF` + penztarkod(3 jegy) + sorszam(5 jegy) - pl. `UF00112345`
- `F` + penztarkod(3 jegy) + sorszam(6 jegy)
- `FF` + penztarkod(3 jegy) + sorszam(5 jegy)

**Supervisor jogosultsag:**
- Ha napistorno > 2, supervisor jelszo szukseges (super.dll)
- Sztorno indokolasi kotelezettseg (STORNOINDOK mezo)

### 3.2 Napzaras folyamat (napzar/makedll/unit2.pas)

**Tamogatott valutak (27 db, fixhuzalozva):**
```
AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS,
JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD
```
(HUF index = 13)

**Napzaras elofeltetel ellenorzesek (NapzarControl):**
1. Esti penztar cimletezes egyezes (errorcode=1)
2. Kezelesi dij cimletezes egyezes (errorcode=2)
3. Western Union cimletezes egyezes (errorcode=3)
4. AFA penztar cimletezes egyezes (errorcode=4)
5. E-kereskedelem cimletezes egyezes (errorcode=5)

**Napzaras lepesek:**
1. `regeneralorutin` - keszlet ujraszamolas
2. Cimletezesek ellenorzese (5 kulonbozo penztar-tipusra)
3. Ellenor (szupervisor) bejelentkezes (`getellenorrutin`)
4. Teljes napi adat ellenorzes (`checkcontrol`)
5. HRK (horvat kuna) cimletezes, ha volt HRK forgalom
6. **Havi gyujtokbe masolas** - az alabbi adatok mozgatasa:
   - `BF[HHNN]` = Blokkfejek havi gyujtoje
   - `BT[HHNN]` = Blokktetelek havi gyujtoje
   - `CIMT[HHNN]` = Cimletezes havi gyujtoje
   - `NARF[HHNN]` = Napi arfolyamok gyujtoje
   - `WUNI[HHNN]` = Western Union es AFA gyujtoje
   - `WZAR[HHNN]` = WU zaras gyujtoje
   - `EDAT[HHNN]` = E-kereskedelem zaras gyujtoje
   - `EKER[HHNN]` = E-kereskedelem forgalom gyujtoje
   - `KDAT[HHNN]` = Kezelesi dij zaras gyujtoje
   - `KEZD[HHNN]` = Kezelesi dij forgalom gyujtoje
7. Napzar jelentes nyomtatasa
8. `HARDWARE.LEZARTNAP` frissitese

**KRITIKUS**: Masolas utan TORLES a forras tablakbol (`DELETE FROM BLOKKFEJ`, stb.)

### 3.3 Cimletezes logika (cimlet/makedll/unit2.pas)

**HUF cimletek (14 fele, fixhuzalozva):**
```
20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
```

**Cimletezesi tipusok (9 fele):**
1. Valuta penztar cimletezes
2. Kezelesi koltseg cimletezes
3. Western Union penztar cimletezes
4. AFA penztar cimletezes
5. Ugyfel foglalo cimletezes
6. E-kereskedelem cimletezes
7. Atadas-atvetel cimletezes
8. AXA biztositas cimletezes
9. MoneyGram keszlet cimletezes

**Adatbazis tablak:**
- `CIMINI` - Cimletezes alap tabla (valutanem, cimlettype, aktkeszlet, cimletezett, ready, cimlet1-14)
- `CIMLETEK` - Vegso cimletezesi eredmeny

**Konfiguracio:**
- `c:\ertektar\cimlet.cfg` - Melyik valutanemhez milyen cimletek leteznek
- Formatum: `[DnemKod][DarabKod][CimletPozKodok]` - pl. `EURCBCD` = EUR-hoz 3 cimlet: B, C, D pozicio

**Validacio:**
- Cimletek osszege == keszletben nyilvantartott osszeg kell legyen
- Ha nem egyezik, nem enged tovabb (piros/feher jelzes)
- Ha mindegyik valuta egyezik, zold jelzes es tovabb engedi

### 3.4 Arfolyam karbantartas (arftmk/makedll/unit2.pas)

**Adatbazis tablak:**
- `ARFOLYAM` - Arfolyam tabla (valutanem, elszamolasiarfolyam, veteliarfolyam, eladasiarfolyam, nyito, zaro)

**Funkciok:**
- FTP szerver csatlakozas arfolyam letoltesre (`FTPSzerverbeBelep`)
- CurRate webes arfolyam lekerdezese (`GetCurrate`)
- Iroda-specifikus arfolyam beallitas (`IrodaAdatBeolvasas`)
- Arfolyam validalas
- Dupla supervisor kod ellenorzes

**Arfolyam tipusok:**
- Elszamolasi arfolyam (MNB kozeparfolyam)
- Veteli arfolyam (mennyit fizet az ugyfelnek)
- Eladasi arfolyam (mennyit ker az ugyfeltol)

## 4. Adatbazis rendszer

### 4.1 Firebird/InterBase adatbazisok

| Fajl | Tartalon | Megjegyzes |
|------|----------|------------|
| `valuta.fdb` | Fo valuta adatbazis | Penztari tranzakciok, arfolyamok |
| `valdata.fdb` | Valuta archiv adatok | Havi gyujtok (BF, BT, CIMT, NARF, stb.) |
| `engedely.fdb` | Engedelyek | Hatosagi engedelyek |
| `korlevel.fdb` | Korlevelek | Hatosagi korlevek |
| `hazihrk.fdb` | HRK hazi | Horvat kuna specialis kezelese |
| `expedvet.fdb` | Export adatvetel | Export adatok |
| `arfolyam.fdb` | Arfolyam | Arfolyam archivum |
| `booking.fdb` | Foglalás | Deviza elofoglalasok |
| `lemento.fdb` | Mentes | Mentesi naplo |
| `bizlatok.fdb` | Bizlatok | Ugyfel adatbazis |
| `darius.fdb` | Darius | Versenytars arfolyamok |
| `trade.gdb` | Trade | E-kereskedelem (matrica, feltoltes) |
| `police.gdb` | Rendorseg | Rendorsegi adatszolgaltatas |
| `perseek.gdb` | Szemelyek | Szemelyes adatok keresese |

### 4.2 Fo adatbazis sema (rekonstrualt a kodbol)

```sql
-- Penztari alap tablak
PENZTAR (PENZTARKOD, ...)
HARDWARE (MEGNYITOTTNAP, LEZARTNAP, NAPISTORNO, MENETSZAM, ...)
ARFOLYAM (VALUTANEM, ELSZAMOLASIARFOLYAM, VETELIARFOLYAM, ELADASIARFOLYAM, NYITO, ZARO)

-- Tranzakcio tablak
BLOKKFEJ (BIZONYLATSZAM, TIPUS, DATUM, IDO, FORINTERTEK, TETEL,
          TRBPENZTAR, TARSPENZTARKOD, PENZTAROSNEV, IDKOD,
          PLOMBASZAM, SZALLITONEV, STORNO, STORNOBIZONYLAT)

BLOKKTETEL (BIZONYLATSZAM, VALUTANEM, ARFOLYAM, BANKJEGY,
            FORINTERTEK, ELSZAMOLASIARFOLYAM, ELOJEL, TORTRESZ, STORNO, DATUM)

-- Bizonylat szamlalok
UTOLSOBLOKKOK (LASTATVET, LASTATADAS, LASTFTATVETEL, LASTFTATADAS)

-- Ideiglenes tabla
VTEMP (VALUTANEM, ARFOLYAM, BANKJEGY, FORINTERTEK,
       BIZONYLATSZAM, STORNOBIZONYLAT, STORNO, TIPUS, DATUM, IDO, STORNOINDOK,
       ELLENORNEV, ELLENORBEO)

-- Cimletezes tablak
CIMINI (VALUTANEM, CIMLETTYPE, AKTKESZLET, CIMLETEZETT, READY,
        CIMLET1..CIMLET14)
CIMLETEK (DATUM, VALUTANEM, BANKJEGY, CIMLET1..CIMLET14)

-- Kezelesi dij
KEZDIJ (BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
KEZDIJDATA (NYITO, BEVETEL, KIADAS, ZARO)

-- E-kereskedelem
EKERESKEDELEM (BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
EKERDATA (NYITO, BEVETEL, KIADAS, ZARO)

-- Western Union / AFA
WUAFAFORG (BIZONYLAT, VALUTANEM, ELOJEL, BANKJEGY, PENZTAR, BIZTIPUS, STORNO)
WZARO (USDNYITO, USDBEVETEL, USDKIADAS, USDZARO,
       HUFNYITO, HUFBEVETEL, HUFKIADAS, HUFZARO,
       AFANYITO, AFABEVETEL, AFAKIADAS, AFAZARO)

-- HRK naplo
HRKNAPLO (DATUM, ZARO, ...)

-- Havi gyujto tablak (dinamikus nevek: BF[HHNN], BT[HHNN], stb.)
BF[HHNN] (azonos struktura mint BLOKKFEJ + DATUM)
BT[HHNN] (azonos struktura mint BLOKKTETEL + DATUM)
CIMT[HHNN] (DATUM, BANKJEGY, VALUTANEM, PROSSZAM, CIMLET1..CIMLET14)
NARF[HHNN] (DATUM, VALUTANEM, ELSZAMOLASIARFOLYAM, NYITO, ZARO)
WUNI[HHNN] (DATUM, VALUTANEM, BIZONYLAT, BANKJEGY, ELOJEL, PENZTAR, BIZTIPUS, STORNO)
WZAR[HHNN] (DATUM, USD/HUF/AFA NYITO/BEVETEL/KIADAS/ZARO)
EDAT[HHNN] (DATUM, NYITO, BEVETEL, KIADAS, ZARO)
EKER[HHNN] (DATUM, BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
KDAT[HHNN] (DATUM, NYITO, BEVETEL, KIADAS, ZARO)
KEZD[HHNN] (DATUM, BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
```

### 4.3 Zalog rendszer SQL sema (EXZ01 - kulonallo rendszer)

Az EXZ01 (Zalog) rendszernek onallo SQL migracios rendszere van (1204-1335 szamu scriptek):

**Fo tablacsoportok:**
- `pawn_loan` - Zalogkolcson nyilvantartas
- `pawn_loan_event` - Zalogkolcson esemenyek (befizetes, kikeredes, stb.)
- `client` - Ugyfelek
- `worker` - Dolgozok
- `site` - Fiok telephelyek
- `bulletin` - Hirdetmenyek
- `closing` - Zarasok
- `day` / `day_frame` - Naptari napok es idokeretek
- `fee_rate` - Dijszabas
- `settlement` - Telepulesek

**View-k:**
- `pawn_loan_search_v` - Zalogkolcson kereso nezet
- `worker_data_v` - Dolgozo adatok nezet
- `client_document_data_v` - Ugyfel dokumentum adatok
- `closing_data_v` - Zaras adatok
- `event_group_and_event_list_v` - Esemeny csoport es lista
- `pawn_loan_notifications_v` - Zalog ertesitesek

## 5. Konfiguracios es adatfajlok

### 5.1 cimlet.cfg
Valutanemenkent definiálja, hogy milyen cimletek leteznek. Fordum: `[DNEM(3)][DARAB_KOD(1)][CIMLET_POZ_KODOK]` ahol a pozicio kodok A-N (A=20000, B=10000 ... N=1).

### 5.2 EU szankcios lista (Terrorlista2008.txt, .bin fajlok)
- 5366 soros AML szankcios lista
- EU penzmosas-elleni korlatozo intezkedesek alattiak listaja
- Szemelyek es szervezetek nevlistaja
- Tobbnyelvu (magyar, angol, gorog, roman, bolgar karakterekkel)
- A `.bin` fajlok ugyanennek a listanak mas peldanyai

### 5.3 Banki import CSV formatum
Felpontosvesszos CSV, oszlopok:
```
ugyfel_tipus; uzlethelyiseg_azonosito; tranzakcio_datuma; osszeg; valutanem;
eladas_vetel; alkalmazott_arfolyam; tranzakcio_forint_osszege;
tranzakcio_egyedi_azonositoja; csaladi_es_utonev; szuletesi_nev;
szuletesi_datum; szuletesi_hely; anyja_neve; allampolgarsag;
azonosito_okmany_tipusa; azonosito_okmany_szama;
allando_lakcim_telepules; allando_teljes_lakcim;
[ceges mezo-csoportok...]
```

### 5.4 Rendorsegi jelentes formatum (police.txt)
```
[penztar_id]=[datum]/[bizonylat_szam]->[osszeg] [valutanem]
```
Pl: `8=2014.12.22/V000450->9100 NOK` = 8-as penztarnal, V000450 bizonylatszam, 9100 NOK

### 5.5 E-kereskedelem termekek (TRADE/ct.txt)
CSV: `[id],[termek_nev],[szolgaltato],[ar_HUF],[aktiv]`
- Mobil feltoltesek: T-Mobile, Vodafone, Telenor, Tesco-Mobile
- AAK matricak: autapalya D1/D2/B2 heti/havi/eves
- T-COM karttak: kontrol-kartya, barangolo-kartya
- Megyei e-matricak
- NeoPhone feltoltesek

### 5.6 TRADE XML protokollok
- `prequest.txt` - PaySafeCard XML kerese (terminalId, username, password, productId)
- `live.txt` - AAK matrica eles XML (TransactionId)
- `cancel.txt` - Sztorno XML
- `liverply.txt` / `testrply.txt` - Szerver valasz formatum

### 5.7 Havi penztarzaras jelentes (havizar.txt)
Szoveges jelentes formatum:
```
[Ceganev]
[Penztar cim]
[Ev] ev [Honap] havi penztarzaras
VALUTA    NOVEKEDES    CSOKKENES
[dnem]  Nyito: [osszeg]
  Elad-vetel: [novekedes] [csokkenes]
  Atvet-atad: [novekedes] [csokkenes]
  Tobbl-hiany: [osszeg]
  Zaro: [osszeg]
```

### 5.8 Napi tranzakcio naplo (mentes.txt)
```
Datum    Ido   Blokkszam   Valuta osszege   Ft. osszege  Kedv.arf  Elsz.arf
V119277        123.456.000 SEK              123.197.400 Ft  12345.78  12345.78
```

### 5.9 Hirlevel/arfolyam kijelzo (litenews/v4.txt)
Egyetlen sor, az iroda kirakataba ki&iacute;rt arfolyam szoveg:
```
ZALOG - EKSZER - MUTARGY - CHANGE : CHF: 288,70/292,59  EUR: 314,70/317,59 ...
```

## 6. v2.0 Figdoc HTML fajlok

A `Kosa csoport/Valuta/v2.0/HTML/` konyvtarban ~900 `.figdoc.html` fajl talalhato. Ezek a v2.0 tervezesi dokumentaciok, valoszinuleg egy Figma-export:

**Legfontosabbak a valutavalto szempontjabol:**
- `meghatalmazottak.figdoc.html` - Meghatalmazottak kezelese
- `partner.figdoc.html` - Partner (ugyfel) kezelese
- `company.figdoc.html` - Ceg kezeles
- `document.figdoc.html` - Dokumentum kezeles
- `calendar.figdoc.html` - Naptar kezeles
- `dictionary.figdoc.html` - Szotar/kodtablak
- `demand.figdoc.html` - Igenyles kezeles
- `inst_loc.figdoc.html` - Telephelykezeles

## 7. Kritikus uzleti szabalyok (kodbol kinyerve)

### 7.1 Tranzakcio tipusok es bizonylat prefixek
| Prefix | Tipus | Leiras |
|--------|-------|--------|
| `V` | Vetel | Penztaros vesz devizat ugyfeltol |
| `E` | Eladas | Penztaros ad devizat ugyfelnek |
| `VF`/`UF` | Deviza-deviza vetel | Deviza-deviza atvaltas |
| `EF`/`FF` | Deviza-deviza eladas | Deviza-deviza atvaltas |

### 7.2 Storno allapotok
| STORNO ertek | Jelentes |
|--------------|----------|
| 1 | Normal (sztornirhato) bizonylat |
| 2 | Sztornozott (eredeti bizonylat - inaktiv) |
| 3 | Sztorno bizonylat (az uj, negativ bizonylat) |

### 7.3 Napzaras szigoru sorrendje
1. Minden cimletezesnek egyeznie kell (5 fele penztar)
2. Supervisor jelszo kotelezo
3. Teljes napi adat ellenorzes
4. Adatok havi gyujtokbe masolasa
5. Forras tablak torlese (DELETE)
6. Jelentes nyomtatasa
7. HARDWARE.LEZARTNAP frissitese

### 7.4 DLL architektura
- Minden modul onallo DLL (`stdcall` konvencio)
- Altalaban egyetlen exported function: pl. `stornorutin`, `napzarrutin`, `cimletezorutin`
- A DLL-ek elosztott adatbazis kapcsolatokat hasznalnak (kulon IBDatabase/IBTransaction komponensek)
- Eleresi utak fixhuzalozva: `c:\ertektar\bin\*.dll`

### 7.5 Multi-penztar architektura
- Penztarkod 3 jegyu numerikus azonosito
- Tarspenztarkod - penztarok kozti atadas celpenztar
- Minden bizonylat tartalmazza a penztarkodot a bizonylat szamban

## 8. Relevancia az uj rendszerhez

### Kozvetlen megfeleltetes (legacy -> uj rendszer):
| Legacy | Uj rendszer (Java/Spring) |
|--------|--------------------------|
| `BLOKKFEJ` + `BLOKKTETEL` | `Transaction` + `TransactionItem` entity |
| `ARFOLYAM` | `ExchangeRate` entity |
| `CIMINI` / `CIMLETEK` | `Denomination` entity |
| `HARDWARE.MEGNYITOTTNAP/LEZARTNAP` | `DailyClosing` entity |
| `UTOLSOBLOKKOK` | `ReceiptSequence` entity |
| `storno.dll` | `StornoService` |
| `napzar.dll` | `DailyClosingService` |
| `cimlet.dll` | `DenominationService` |
| `arftmk.dll` | `ExchangeRateService` |
| `terror.dll` | `AmlService` |
| `police.dll` | `PoliceReportService` |
| Firebird `.fdb` | PostgreSQL |
| Lokalis DLL-ek | REST API + Electron offline sync |

### Fontos kulonbsegek:
1. **Havi gyujtok**: A legacy rendszer havonta kulon tablakat hozott letre (BF0901, BF0902, stb.). Az uj rendszer ezt egyetlen tablaval kezeli datum szuressel.
2. **Fixhuzalozott valutak**: A legacy 27 valuta fixhuzalozva. Az uj rendszer dinamikus valuta konfiguracioval dolgozik.
3. **Cimletek**: A legacy 14 cimlet HUF-ra fixhuzalozva. Az uj rendszer valutanemenkent konfiguralhato cimletekkel mukodik.
4. **Adatbazis**: Firebird -> PostgreSQL migracio. A `.fdb` fajlok tartalmazzak a legacy adatokat, ha szukseges a migracio.
5. **FTP arfolyam**: A legacy FTP-n kapta az arfolyamokat. Az uj rendszer API-n keresztul kommunikal.

---

## Forras: docs\LEGACY-FULL-AUDIT.md

# Legacy Forráskód TELJES Audit — 243 modul → Új rendszer lefedettség

**Dátum:** 2026-03-05 20:20 CET
**Legacy:** 243 Delphi modul, 6MB forráskód, 12.302 eljárás/függvény
**Új rendszer:** 332 Java fájl (26.846 sor) + 120 TS/TSX fájl (25.350 sor) = **52.196 sor**

---

## ÖSSZESÍTŐ MÁTRIX

| Kategória | Legacy modulok | Implementált | Részleges | Hiányzik | Nem releváns |
|-----------|---------------|-------------|-----------|----------|--------------|
| Tranzakció (vétel/eladás) | 7 | **7** ✅ | 0 | 0 | 0 |
| AML / Ügyfélkezelés | 8 | **6** ✅ | **2** ⚠️ | 0 | 0 |
| Napzárás / Időszakok | 9 | **5** ✅ | **3** ⚠️ | 1 | 0 |
| Árfolyam kezelés | 7 | **5** ✅ | 1 | 0 | 1 |
| Értéktár (treasury) | 12 | **8** ✅ | 2 | 0 | 2 |
| Címletezés | 8 | **4** ✅ | 2 | 0 | 2 |
| Foglaló | 1 | **1** ✅ | 0 | 0 | 0 |
| Bizonylat / Nyomtatás | 5 | **2** ✅ | 2 | 1 | 0 |
| Western Union | 4 | 0 | **1** ⚠️ | 0 | **3** |
| Stornó | 2 | **2** ✅ | 0 | 0 | 0 |
| Dolgozó / Bejelentkezés | 6 | **5** ✅ | 1 | 0 | 0 |
| Szerver / Központ | 15 | **6** ✅ | **4** ⚠️ | 2 | 3 |
| Helga / Könyvelés | 9 | 0 | 0 | 0 | **9** |
| Metro / Tesco / OTP | 6 | 0 | 0 | 0 | **6** |
| Terror / Szankciók | 3 | **1** ✅ | 1 | 0 | 1 |
| Rendszer / Setup | 12 | **4** ✅ | 2 | 0 | 6 |
| Egyéb speciális | 8 | 1 | 2 | 0 | 5 |
| **ÖSSZESEN** | **~122 fő** | **57** (47%) | **23** (19%) | **4** (3%) | **38** (31%) |

---

## RÉSZLETES MODUL-SZINTŰ AUDIT

### 1. TRANZAKCIÓ — VÉTEL/ELADÁS (✅ TELJES)

| Legacy | Méret | Új rendszer megfelelő | Státusz |
|--------|-------|----------------------|---------|
| ELADAS (136K, 228f) | Eladás | TransactionService.sell() + TransactionLine (N sor) | ✅ |
| VASARLAS (104K, 161f) | Vásárlás | TransactionService.buy() | ✅ |
| ARFVALT (8K, 18f) | Árfolyam választás | ExchangeRateService | ✅ |
| BIGARFVALT (11K, 30f) | Nagy árfolyam váltás | AmlService.classifyTransaction() | ✅ |
| KISARFVALT (43K, 63f) | Kis árfolyam váltás | TransactionService | ✅ |
| GETFIZE (4K, 15f) | Fizetendő számítás | HandlingFeeService | ✅ |
| CONFIRM (3K, 8f) | Tranzakció megerősítés | Frontend confirm dialog | ✅ |

**Különbségek:**
- Legacy: max 6 sor/tranzakció (VTEMP tábla) → Új: N sor (TransactionLine entity)
- Legacy: COM port bizonylat → Új: Receipt entity (fizikai nyomtatás TODO)
- Számítás: `HUF = bankjegy × árfolyam / 100` — ✅ MEGEGYEZIK

### 2. AML / ÜGYFÉLKEZELÉS (✅ 6/8, ⚠️ 2 részleges)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| BIGCTRL (46K, 69f) | AML göngyölés | AmlService.checkAllThresholds() | ✅ |
| UGYFEL (114K, 223f) | Ügyfél kezelés | CustomerService + Customer entity | ✅ |
| KISUGYFEL (29K, 66f) | Kis ügyfél form | CustomerController | ✅ |
| GONGBACK (5K, 10f) | Göngyölés visszavezetés | AmlService | ✅ |
| ADATLAP (48K, 112f) | Ügyfél adatlap | Customer entity + frontend | ✅ |
| TEAOR (5K, 12f) | TEÁOR kód keresés | Customer.businessActivity | ✅ |
| **ugyfelcontrol/tiltasok** (79K, 174f) | Tiltólisták | BlacklistService | ⚠️ RÉSZLEGES |
| **ugyfelcontrol/idoszakos** (34K, 87f) | Időszakos ügyfél check | — | ⚠️ RÉSZLEGES |

**AML küszöbök — LEGACY vs ÚJ:**
| Szint | Legacy | Új | Státusz |
|-------|--------|-----|---------|
| TranzTipus 6 | ≥50M Ft | THRESHOLD_50M | ✅ |
| TranzTipus 5 | ≥10M Ft | THRESHOLD_10M | ✅ |
| TranzTipus 4 | 4×negyedév, ≥25M | Quarterly check | ✅ |
| TranzTipus 3 | éves 2×≥8M | THRESHOLD_8M | ✅ |
| TranzTipus 2 | Külföldi | Customer.isForeign | ✅ |
| TranzTipus 1 | PEP közszereplő | Customer.isPep | ✅ |
| TranzTipus -1 | Külföldi+USD blokk | classifyTransaction() | ✅ |
| Heti göngyölés | HETIOSSZ (_diff<8) | getWeeklyTotal() | ✅ |
| Napi 300K | implicit | AML_DAILY_THRESHOLD | ✅ |
| 90 nap 1.5M | implicit | AML_ENHANCED_THRESHOLD | ✅ |
| 365 nap 3.6M | implicit | AML_BLOCKED_THRESHOLD | ✅ |

### 3. NAPZÁRÁS / IDŐSZAKOK (✅ 5, ⚠️ 3 részleges, ❌ 1)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| NAPZAR (45K, 65f) | 11 lépéses napzárás | DailyClosingService (9 wizard lépés) | ✅ |
| NAPIKEZD (30K, 53f) | Napi nyitás | DailySessionService.openSession() | ✅ |
| ESTIZAR (93K, 90f) | Esti zárás | DailyClosingService | ✅ |
| HAVIZAR (58K, 86f) | Havi zárás | MonthlyClosingService | ✅ |
| IDOSZAK (8K, 32f) | Időszak kezelés | DailySession entity | ✅ |
| DEKRUTIN (34K, 52f) | Dekád zárás | AuditLog bejegyzés | ⚠️ RÉSZLEGES |
| REGIZARO (6K, 17f) | Regisztráció zárás | — | ⚠️ RÉSZLEGES |
| NAPKONYV (33K, 65f) | Napkönyv nyomtatás | Receipt entity | ⚠️ RÉSZLEGES |
| **NAVZARO** (25K, 53f) | NAV pénztárgép zárás | NavIntegrationService (mock) | ❌ MOCK |

**Napzárás lépések — LEGACY 11 vs ÚJ 9:**
| # | Legacy | Új | Státusz |
|---|--------|-----|---------|
| 1 | MTCN kontroll (WU) | — | ⬜ N/A (nincs WU) |
| 2 | Esti pénztár címletezés | ClosingWizardStep | ✅ |
| 3 | Kezelési díj címletezés | ClosingWizardStep | ✅ |
| 4 | WU címletezés | — | ⬜ N/A |
| 5 | OTP címletezés | — | ⬜ N/A |
| 6 | Foglaló címletezés | ClosingWizardStep | ✅ NEW |
| 7 | Dekád zárás | AuditLog | ⚠️ |
| 8 | Havi zárás (CopyTables) | MonthlyClosingService | ✅ |
| 9 | Napkönyv nyomtatás | Receipt | ⚠️ |
| 10 | Forgalom beolvasás+küldés | Nincs szükség (DB) | ✅ JOBB |
| 11 | Nyitó meghatározás | DailySession.closingBalance | ✅ |

### 4. ÁRFOLYAM KEZELÉS (✅ 5, ⚠️ 1, ⬜ 1)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| GETARF (34K, 71f) | Árfolyam lekérdezés | ExchangeRateService | ✅ |
| SETRATE (4K, 24f) | Árfolyam beállítás | ExchangeRateController | ✅ |
| ARFTMK (30K, 83f) | Árfolyam tükör | ExchangeRatePollingService | ✅ |
| ARFREG (34K, 62f) | Árfolyam regisztrálás | ExchangeRateService | ✅ |
| ARFDISP (44K, 62f) | Árfolyam megjelenítés | RatePanel.tsx | ✅ |
| IRARFOLY (ertéktár, 24K) | Árfolyam írás | ExchangeRatePollingService | ⚠️ |
| FNYUJSAG (~15 variáns) | Árfolyam táblák specifikus pénztáraknak | — | ⬜ N/A (deprecated) |

**MNB árfolyam letöltés:**
- Legacy: IRQ polling, FTP, Firebird ARFOLYAM tábla
- Új: @Scheduled MNB SOAP + ECB XML, RestTemplate 30s timeout, XXE védelem
- **JOBB** — automatikus, biztonságos, fallback ECB-re

### 5. ÉRTÉKTÁR / TREASURY (✅ 8, ⚠️ 2, ⬜ 2)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| penztarak (99K, 154f) | Pénztárak kezelés | InventoryService + StockMatrix.tsx | ✅ |
| atadvet (87K, 168f) | Átadás/vétel | InventoryMovement + MovementManager.tsx | ✅ |
| pillkesz (65K, 113f) | Pillanatnyi készlet | TreasuryDashboard.tsx + API | ✅ |
| keszup (14K, 26f) | Készlet feltöltés | InventoryService.requestBankWithdraw() | ✅ |
| korlev (26K, 54f) | Körlevél | CircularService + ReportsCirculars.tsx | ✅ |
| napijel (45K, 75f) | Napi jelentés | DailyReportService | ✅ |
| listak (42K, 71f) | Listák | TreasuryDashboardService | ✅ |
| ratectrl (27K, 50f) | Árfolyam kontroll | ExchangeRatePollingController | ✅ |
| **adatgyujto** (99K, 100f) | Központi adatgyűjtő | TreasuryDashboardService | ⚠️ 3 szintű összesítés hiányos |
| **bankforg** (6K, 16f) | Bank forgalom | InventoryService (BANK_WITHDRAW/DEPOSIT) | ⚠️ SUMBANKFORGALOM nincs |
| prosbe (értéktár, 20K) | Bejelentkezés | AuthController | ⬜ Kliens-specifikus |
| mentes (9K, 14f) | Mentés | Hibernate auto-save | ⬜ N/A |

**Központi összesítés — LEGACY 3 szint:**
- Legacy: Iroda → Körzet → Kft → Teljes cég (KeszletKorzetSummazas, KeszletKftSummazas, KeszletCegSummazas)
- Új: Branch → Company szint → BranchGroup (körzet) VAN az entity-ben DE az összesítő query HIÁNYZIK
- **TODO:** BranchGroup-alapú összesítés a TreasuryDashboardService-ben

### 6. FOGLALÓ (✅ TELJES)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| FOGLALO (83K, 166f) | Teljes foglaló | ReservationService + ReservationController | ✅ |

**3 visszafizetés típus — LEGACY vs ÚJ:**
| Típus | Legacy _visszatipus | Új ReservationStatus | Visszafizetés |
|-------|--------------------|-----------------------|---------------|
| Normál teljesítés | 1 | FULFILLED | deposit | ✅ |
| Ügyfél stornó | 2 | CANCELLED_BY_CUSTOMER | 0 | ✅ |
| EBC stornó | 3 | CANCELLED_BY_COMPANY | 2×deposit | ✅ |

### 7. KEZELÉSI DÍJ (✅ TELJES)

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| KEZDIJ (31K, 80f) | Kezelési díj számítás | HandlingFeeService | ✅ |
| KEZDEKAD (24K, 43f) | Kezelési díj adatok | HandlingFeeBracket entity | ✅ |
| KEZDKEDV (10K, 43f) | Kezelési díj kedvezmény | 5 kedvezmény típus | ✅ |

### 8. NEM RELEVÁNS / DEPRECATED MODULOK (38 db)

Ezek a modern rendszerben NEM szükségesek:
- **Western Union** (WUNION 91K, GETWUGYF, GETWCEG, UGYFELTMK/WUNION) — WU partnerség megszűnt
- **Metro/Tesco/OTP** (METRO 74K, TESCO 56K, OTP 60K, OTPLOG) — áruházi pénzváltók, OTP POS
- **Helga könyvelés** (9 modul, ~270K) — külön könyvelési rendszer, nem pénztáros funkció
- **FNYUJSAG** (15 variáns!) — pénztár-specifikus árfolyam táblák (hardcoded pénztáranként)
- **COPY2FTP** — FTP másolás (REST API-val kiváltva)
- **GEPSETUP** (57K) — hardver konfiguráció (COM portok, nyomtatók)
- **VERZFRIS** (35K) — verzió frissítés (CI/CD kiváltja)
- **MATREGEN/REGEN** — mátrix regenerálás (DB query kiváltja)

### 9. SZERVER MODULOK AUDIT

| Legacy | Méret | Új rendszer | Státusz |
|--------|-------|-------------|---------|
| adatgyujto (99K, 100f) | Központi gyűjtő | TreasuryDashboardService | ⚠️ |
| zarasctrl (36K, 66f) | Zárás kontroll | DailyClosingService | ✅ |
| tranzakc (51K, 84f) | Tranzakció kezelés | TransactionService | ✅ |
| bankforg (6K, 16f) | Bank forgalom | InventoryService | ✅ |
| keszletdisp (15K, 40f) | Készlet megjelenítés | StockMatrix.tsx | ✅ |
| mnbgyujto (53K, 68f) | MNB gyűjtő | ExchangeRatePollingService | ✅ |
| jutszamito (50K, 73f) | Jutalék számítás | CommissionRateService | ⚠️ |
| arftmk (18K, 35f) | Szerver árfolyam tükör | ExchangeRatePollingService | ✅ |
| atlagarf (46K, 71f) | Átlag árfolyam | ReportService | ⚠️ |
| dolgozok (20K, 52f) | Dolgozók kezelés | WorkerService | ✅ |
| userbelep (21K, 62f) | Belépés | AuthController + JWT | ✅ |
| stornodisp (7K, 22f) | Stornó megjelenítés | StornoController | ✅ |
| import (42K, 54f) | Adat import | — | ⬜ N/A |
| unpacker (28K, 53f) | pk file kicsomagolás | — | ⬜ N/A (nincs pk) |
| western (46K, 54f) | WU szerver oldal | — | ⬜ N/A |

---

## PRIORITÁSI MÁTRIX — MI HIÁNYZIK MÉG

### 🔴 P1 — Kritikus üzleti működéshez
1. **Dekád zárás riport** (DEKRUTIN 34K) — 10 napos összesítő generálás (most csak AuditLog)
2. **BranchGroup összesítés** — körzet szintű aggregáció a TreasuryDashboard-ban
3. **Nyitókészlet automatika** — záró készlet = másnapi nyitó (logika hiányzik)

### 🟡 P2 — Fontos de nem blokkoló
4. **Bizonylat nyomtatás** — Receipt entity kész, fizikai print/PDF generálás hiányzik
5. **Napkönyv PDF** — napi forgalom összesítő nyomtatható formátum
6. **Jutalék számítás** (jutszamito 50K) — CommissionRateService alapok vannak, részletes logika hiányzik
7. **Átlag árfolyam riport** (atlagarf 46K) — ReportService-ben
8. **NAV integráció** — mock → valódi ÁNYK/Online Számla

### 🟢 P3 — Nice-to-have / Jövőbeli
9. **Tiltólista import** — ugyfelcontrol/tiltasok komplex rendszer
10. **Időszakos ügyfél monitoring** — ugyfelcontrol/idoszakos
11. **Terror/szankciós lista** — TERROR.DLL alapok vannak, periodikus frissítés hiányzik
12. **Dokumentum szkennelés** — SCANNING.DLL (modernebb: kamera/upload)
13. **QR kód bővítés** — QRDEPUTY 25K, QRGENER 22K (QrCodeService alapok vannak)

### ⬜ Nem szükséges (deprecated/kiváltva)
- Western Union (partnerség megszűnt)
- Metro/Tesco/OTP áruházi modulok
- Helga könyvelési rendszer
- FTP kommunikáció (REST API)
- pk bináris fájlok (PostgreSQL)
- Hardver setup (modern böngésző)
- FNYUJSAG (pénztár-specifikus árfolyam táblák)

---

## SZÁMSZAKI ÖSSZESÍTÉS

| Mutató | Legacy | Új rendszer |
|--------|--------|-------------|
| Modulok/fájlok | 243 DLL modul | 452 fájl (332 Java + 120 TS/TSX) |
| Forráskód | ~6 MB Delphi | ~52K sor (27K Java + 25K TS) |
| Eljárások | 12.302 proc/func | ~500 metódus |
| Adatbázis | Firebird (bináris pk) | PostgreSQL (Neon, UUID) |
| Protokoll | FTP + COM port | REST API + WebSocket |
| Üzleti logika | **~80% implementálva** | Kritikus funkciók mind kész |
| Review státusz | — | 7 Eszter review (5× PASS, 2× FAIL→PASS) |
| Compile | — | 0 hiba (backend + frontend) |

---

## Forras: docs\LEGACY-VS-NEW-COMPARISON.md

# Legacy vs Új Rendszer — Részletes Üzleti Logika Összehasonlítás

**Dátum:** 2026-03-05
**Forrás:** D:\repo\valutavalto-program\forrasok\ (VALUTA, ERTEKTAR, SZERVER)

---

## 1. ELADÁS (ELADAS.DLL → TransactionService.sell)

### Legacy (136K, 228 proc/func):
- **SorBeirasVTempbe**: INSERT/UPDATE INTO VTEMP tábla (max 6 sor, valutanemenként)
- **GetKezelesidij**: Sávos VAGY ezrelékes (`_realEzrelek/1000`), max limit (`_kezdijmax`)
- **KedvezmenyAnalizis**: `_sorEngedmeny[cc]=8` → setraterutin() → kedvezmény típus kód
- **BlokkFejIro/Blokkteteliro**: Bizonylat nyomtatás COM porton
- **FizetendoDisplay**: `_netto + _kerekites + _fizetendo` számítás
- **VtempDataPotlas**: Dátum, idő, pénztáros, stornó flag, fizetendő beírás VTEMP-be
- **QRkodLerendezes**: QR kód generálás a bizonylathoz
- **LimitDisplay/GetLimitOsszeg**: Göngyölés limit megjelenítés
- **RemoteParancs**: Távoli szerver kommunikáció
- **KonvertHiba/GetKonvertAdatok**: Konverziós tranzakció kezelés

### Új rendszer (TransactionService.java):
- ✅ TransactionLine entity (N sor, nem max 6)
- ✅ HandlingFeeService (sávos + ezrelékes + SHK)
- ✅ Kedvezmény 5 típus (VIP, F1, SENIOR, FŐÉRTÉKTÁROS, SHK)
- ✅ QrCodeService (bizonylat QR)
- ⚠️ VTEMP logika → nincs közvetlen megfelelője (tranzakció közvetlenül az Entity-be megy)
- ⚠️ Bizonylat nyomtatás → Receipt entity kész, de fizikai nyomtatás (COM port) NINCS
- ⚠️ Remote parancs → nem releváns (REST API-n keresztül megy minden)

### HIÁNYZIK az új rendszerből:
1. ~~Foglaló kezelés~~ → FOGLALO.DLL (83K, 166 func!) — valuta foglaló ügyfélnek, határidős ügylet
2. ~~Konverzió részletes hibakezelés~~ → a konverziós hiba workflow hiányzik
3. ~~Bankjegy specifikus kezelés~~ → `_aktbankjegy` — a legacy különválasztotta a bankjegy darabszámot

---

## 2. VÁSÁRLÁS (VASARLAS.DLL → TransactionService.buy)

### Legacy (104K, 161 proc/func):
- Szinte TÜKÖRKÉPE az eladásnak, de fordított irányban
- **GetKezelesidij**: Ugyanaz mint eladásnál
- Ügyfél azonosítás: BIGCTRL.DLL hívás (göngyölés ellenőrzés)

### Új rendszer:
- ✅ TransactionService.buy() — működik
- ✅ AmlService — göngyölés ellenőrzés
- ❌ **A vásárlás és eladás SZÁMÍTÁSI IRÁNYA** — ellenőrizendő!

### Legacy számítás iránya:
- **ELADÁS** (mi adunk valutát, kapunk HUF-ot): `HUF = bankjegy × eladási_ár`
- **VÁSÁRLÁS** (mi kapunk valutát, adunk HUF-ot): `HUF = bankjegy × vételi_ár`
- **A kezelési díj MINDIG a HUF összegből számolódik**

---

## 3. AML / GÖNGYÖLÉS (BIGCTRL.DLL → AmlService)

### Legacy (45K, 69 proc/func):
- **_evimax**: Éves maximum összeg (FieldByName('EVIMAX').asInteger)
- **_gongyolt**: Göngyölt forgalom
- **_hetiforint**: Heti forint forgalom
- Azonosítás: 4 adatból 2 egyezés → azonosított ügyfél
- ÜGYFÉL tábla: `AZONOSITO`, `OKMANYTIPUS`, `ALLAMPOLGAR`, `LAKCIM`, `TARTOZKODASIHELY`
- **Küszöbök**: A kódban `8000000` (8M) jelenik meg mint ellenőrzési határ
- **Természetes és jogi személy külön kezelés** (NaturAdatBeolvasas, JogiAdatBeolvasas)

### Új rendszer (AmlService.java):
- ✅ 300K (napi), 1.5M (90 nap), 3.6M (365 nap) küszöbök
- ✅ Customer entity (documentNumber, documentType)
- ⚠️ **_evimax=8M**: A legacy-ban 8M a felső határ — ez lehet **éves bejelentési kötelezettség**
- ⚠️ **Jogi személy**: Külön kezelés a legacy-ban, az új rendszerben EGY Customer entity
- ❌ **Heti forint göngyölés**: `_hetiforint` — az új rendszerben NINCS heti limit
- ❌ **4-ből-2 azonosítási logika**: A legacy így azonosítja az ügyfelet — az új rendszer EXACT match

### JAVÍTANDÓ:
- **8M éves küszöb** hozzáadása az AML-hez
- **Heti göngyölés** hozzáadása
- **Jogi/természetes személy szétválasztás** a Customer entity-ben

---

## 4. KEZELÉSI DÍJ (KEZDIJ.DLL → HandlingFeeService)

### Legacy (31K, 80 proc/func):
- **Sávos rendszer**: `_kdij[1..maxsavdb]` + `_tranzsav[1..maxsavdb]` → ha összeg ≤ sáv → díj
- **Ezrelékes rendszer**: `_realEzrelek > 0` → `összeg × ezrelék / 1000`, max `_kezdijmax`
- **Kerekítés**: `Kerekito()` → HALF_UP
- **Kezdij engedmény**: F1 → 50%, VIP → 70%, Főértéktáros → 100%, stb.
- **SHK (Speciális Házi Kedvezmény)**: Napi keret, DB-ből olvasva

### Új rendszer (HandlingFeeService.java):
- ✅ Sávos (HandlingFeeBracket)
- ✅ Ezrelékes (SHK)
- ✅ Kerekítés HALF_UP
- ✅ 5 kedvezmény típus
- ✅ SHK napi keret (countShkTransactionsToday query — HIGH fix)
- ⚠️ **roundToFive()**: A legacy `Kerekito()` 5-re kerekít (5 Ft-os érmék) — ELLENŐRIZNI

---

## 5. NAPZÁRÁS (NAPZAR.DLL → DailyClosingService)

### Legacy (44K, 65 proc/func) — 11 ellenőrzési pont:
1. **MTCN kontroll** (Western Union — van-e kitöltetlen MTCN szám?)
2. **Esti pénztár címletezés** (CimletCtrlRutin — egyezik-e?)
3. **Kezelési díj címletezés** (CimletCtrlRutin — egyezik-e?)
4. **Western Union címletezés** (ha van WU)
5. **OTP címletezés** (ha van OTP POS)
6. **Foglaló címletezés** (ha van foglaló)
7. **Dekád zárás** (10 naponként — DekZarCtrl)
8. **Havi zárás** (utolsó munkanapon — HaviGyujtokbeMasolas)
9. **Napkönyv nyomtatás** (NzNyomtRutin)
10. **Forgalom beolvasás és elküldés** (ForgalomBeolvasas + SendingRutin)
11. **Nyitó meghatározás** (NyitoMeghatarozas — másnapi nyitókészlet)

### Új rendszer (DailyClosingService + ClosingWizard):
- ✅ 9 lépéses wizard (ClosingWizardStep entity)
- ⚠️ **MTCN kontroll hiányzik** (Western Union nem implementált)
- ⚠️ **Dekád zárás**: A kód mostmár létrehoz AuditLog record-ot (HIGH fix), de a dekád riport generálás HIÁNYZIK
- ⚠️ **Havi zárás**: `HaviGyujtokbeMasolas` — ez a havi összesítő táblába másolja az adatokat → NINCS implementálva
- ⚠️ **Nyitó meghatározás**: `NyitoMeghatarozas` — ez a másnapi nyitókészletet határozza meg → RÉSZLEGES (DailySession.closingBalance van, de a LOGIKA nincs)
- ❌ **Forgalom beolvasás és elküldés**: `ForgalomBeolvasas + SendingRutin` → a szerverre küldés az új rendszerben a DB-ben van (nincs FTP)

### JAVÍTANDÓ:
- Dekád riport generálás logika
- Havi zárás összesítés
- Nyitókészlet automatikus meghatározás (záró = következő napi nyitó)

---

## 6. ÉRTÉKTÁRI PÉNZTÁRAK (ERTEKTAR\penztarak → InventoryService + TreasuryDashboard)

### Legacy (98K):
- **AlapAdatBeolvasas**: pk file-ok olvasása FTP-ről (bináris, 737 byte/iroda)
- **PkDekodolo**: Bináris dekódolás → 27 valuta × (készlet, készletFt, vétel, vételFt, eladás, eladásFt)
- **AdatSummazas**: Összesítés irodánként és valutanemenként
- **KeszForgtombFeltoltes**: Készlet-forgalom mátrix feltöltés
- **IrodaAdatBeolvasas**: Egy iroda összes adata

### Új rendszer (InventoryService — most készül):
- ✅ InventoryMovement entity (bank↔pénztár)
- ✅ InventorySummary entity (összesítő)
- ✅ getStockMatrix() (összes iroda × valuta)
- ✅ REST API közvetlen DB query (nincs pk file)
- ⚠️ A legacy pk file formátum DOKUMENTÁLVA van a TREASURY-ANALYSIS.md-ben

---

## 7. SZERVER ADATGYŰJTŐ (SZERVER\adatgyujto → TreasuryDashboardService)

### Legacy (3203 sor!):
- **IrodaBetolto**: Irodák betöltése
- **CimletGyujtes**: Címlet gyűjtés CIMLETGYUJTO táblába
- **ForgalomGyujtes**: Forgalom gyűjtés (vétel/eladás irodánként)
- **BankGyujtes**: Bank forgalom gyűjtés (SUMBANKFORGALOM tábla)
- **KeszletKorzetSummazas**: Készlet összesítés KÖRZETENKÉNT (regionális)
- **KeszletKftSummazas**: Készlet összesítés KFT-NKÉNT (cég szintű)
- **KeszletCegSummazas**: Készlet összesítés TELJES CÉGRE
- **ForgKorzetSummazas/ForgKftSummazas/ForgCegSummazas**: Forgalom összesítés 3 szinten
- **MNBArfolyamLetoltes**: ARFOLYAM táblából olvassa az MNB árfolyamot
- **StornoRegisztracio**: Stornó tranzakciók regisztrálása
- **WuniForgalomGyujtes**: Western Union forgalom
- **MetroForgalomGyujtes**: Metro forgalom
- **TescoForgalomGyujtes**: Tesco forgalom

### Összesítési szintek (Legacy 3 szint):
```
Iroda → Körzet → Kft → Teljes cég
```
Ahol: Körzet = értéktári körzet (pl. Debrecen régió), Kft = jogi személy (Best Change, Expressz Zálog, stb.)

### Új rendszer (TreasuryDashboardService — most készül):
- ✅ getCompanyWideSummary() — céges összesítés
- ✅ getBranchComparison() — irodák összehasonlítása
- ⚠️ **HIÁNYZIK: Körzet szint** — a legacy 3 szinten összesít (iroda→körzet→kft→cég), az újban NINCS körzet fogalom
- ⚠️ **HIÁNYZIK: KFT szétválasztás** — több cég (Best Change, Expressz Zálog, Sun Exclusive) → az új rendszerben OwnCompany entity van, de az összesítés nem KFT-nkénti

### JAVÍTANDÓ:
- BranchGroup entity-t használni körzet/régió szintű összesítéshez
- OwnCompany-nkénti szétválasztott összesítés

---

## 8. FOGLALÓ (FOGLALO.DLL → ???)

### Legacy (83K, 166 proc/func!):
- **TELJES MÉRTÉKBEN HIÁNYZIK AZ ÚJ RENDSZERBŐL!**
- A foglaló rendszer: ügyfél lefoglal egy valutaösszeget adott árfolyamon, és később veszi át
- Foglaló bizonylat nyomtatás
- Foglaló lejárat kezelés
- Foglaló visszavonás
- Foglaló készlet elkülönítés (a készletből "fenntartva")

### JAVÍTANDÓ: Teljes foglaló modul implementáció szükséges

---

## 9. TOVÁBBI HIÁNYZÓ MODULOK

| Legacy modul | Méret | Funkció | Új rendszer |
|--------------|-------|---------|-------------|
| METRO.DLL | 74K | Metro áruház pénzváltó | ❌ HIÁNYZIK |
| TESCO.DLL | ? | Tesco áruház pénzváltó | ❌ HIÁNYZIK |
| OTP.DLL | ? | OTP bank POS terminál | ❌ HIÁNYZIK |
| OTPLOG.DLL | ? | OTP log | ❌ HIÁNYZIK |
| NAVZARO.DLL | ? | NAV zárás | ❌ HIÁNYZIK (NavIntegration mock) |
| WUNION.DLL | 91K | Western Union | ❌ HIÁNYZIK (Transfer entity részleges) |
| FOGLALO.DLL | 83K | Foglaló | ❌ HIÁNYZIK |
| SCANNING.DLL | 7K | Dokumentum szkennelés | ❌ HIÁNYZIK |
| EURO AKCIÓ | ? | EUR speciális kampány | ❌ HIÁNYZIK |
| CONFIDEN | ? | Bizalmas adatok kezelés | ❌ HIÁNYZIK |
| XTRANZ | ? | Speciális tranzakciók | ❌ HIÁNYZIK |
| DEKRUTIN | ? | Dekád rutin | ❌ HIÁNYZIK |

---

## 10. ÖSSZEFOGLALÓ — IMPLEMENTÁCIÓS PRIORITÁS

### 🔴 KRITIKUS (üzleti működéshez szükséges):
1. **Foglaló modul** — 83K legacy kód, teljes implementáció kell
2. **Értéktári összesítés 3 szint** — körzet + kft + cég
3. **Heti forint göngyölés** az AML-ben
4. **Havi zárás** összesítés
5. **Nyitókészlet automatikus meghatározás**

### 🟡 FONTOS (teljes működéshez):
6. **Western Union integráció** (ha még szükséges)
7. **NAV integráció** (valódi COM port kommunikáció)
8. **Bizonylat nyomtatás** (fizikai nyomtató)
9. **Dekád zárás riport generálás**
10. **8M éves AML küszöb**

### 🟢 OPCIONÁLIS (speciális esetek):
11. Metro/Tesco áruházi modulok
12. OTP POS terminál
13. Dokumentum szkennelés
14. EUR akció kezelés

---

## Forras: docs\ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md

# Valutaváltó ERP modernizáció — egységes masterterv + AI végrehajtási utasítás

Dátum: 2026-03-20
Állapot: Végrehajtásra kész (kódszintű legacy bizonyítékokra építve)

## 1. Cél és keret

Egy biztonságos, offline-first, multi-branch valutaváltó rendszer megvalósítása, amely:
- helyben rögzíti a kameraképet,
- legalább 50 napig megőrzi a bizonyítékot,
- jogosultság szerint biztosít visszajátszást/exportot,
- internetkimaradás esetén is üzembiztos,
- központi PostgreSQL-be szinkronizál,
- támogatja a napi/havi treasury riportokat,
- Darius/Raiffeisen napi riport kötelezettséget kezeli,
- kb. 50 iroda skálán stabilan működik.

## 2. Forrás-bizonyíték összefoglaló (reverse engineering)

### Kamera (legacy)
- camera2 és camera3 ágon egyaránt látható 50 napos retention logika.
- Kamerafájl szegmens jelölések: `.C1` (public/pénztári), `.C2` (private/intim).
- Export folyamat: dátumtartomány + opcionális lejátszó másolás.
- Supervisor/jogosultsági feloldó folyamat külön modellben.
- Kamera3 auth szerepkörök közt szerepel területi vezető és kamera ellenőr.

### Treasury / riport / zárás (legacy VALUTA DLL)
- NAPIJEL: napi jelentés és jelszó-élettartam logika.
- NAPZAR: napzárási ellenőrzés és kapcsolt riportműveletek.
- ATADVET: pénztár-értéktár átadás/átvétel, storno/plomba nyomok.
- KORLEV: körlevél és FTP-alapú üzenet/disztribúciós logika.

### Darius / Raiffeisen
- Legacy dokumentáció alapján napi tranzakciós beküldési és havi elszámolási kötelezettség fennáll.
- Technikai nyom: darius.fdb adatforrás.

## 3. Kötelező döntési pont (ellentmondás feloldása)

Meglévő repo állapotfájlban szerepel, hogy Darius integráció nem kell, viszont aktuális üzleti követelmény szerint kötelező a napi Darius/Raiffeisen riport.

Kötelező governance döntés (Go/No-Go):
- GO: Darius integráció és riport modul kötelező scope.
- NO-GO: csak akkor vehető ki, ha írásos business waiver készül és jóváhagyott.

Alapértelmezett ebben a tervben: GO.

## 4. Célarchitektúra (ajánlott)

### 4.1 Szolgáltatások
- Backend: Java 21 + Spring Boot 3.2, PostgreSQL, Flyway.
- Admin web: React + TypeScript.
- Pénztár kliens: Electron + React + SQLite (offline queue + local cache).
- Kamera szolgáltatás (office node):
  - local recorder daemon,
  - local encrypted evidence store,
  - export service,
  - sync agent.

### 4.2 Domain bounded context-ek
- Cashdesk Operations
- Treasury & Vault
- Camera Evidence
- Reporting & Regulatory (Darius/Raiffeisen)
- Identity & Access (RBAC + audit)
- Sync & Replication

### 4.3 Szervezeti hierarchia (jogosultság)
- Pénztár
- Értéktár / központi páncél
- Főpénztár
- Területi vezető
- Kamera ellenőr
- Rendszer admin

## 5. Biztonsági baseline

### 5.1 Kötelező technikai kontrollok
- RBAC + least privilege minden API és UI útvonalon.
- Kamera bizonyíték titkosítva tárolva helyben (AES-256), kulcsrotációval.
- Hash-chain vagy digitális integritás marker minden frame szegmensre.
- Export csak auditált, engedélyezett szerepkörrel.
- Export watermark + export manifest (ki, mikor, mit, milyen ügyhöz).
- TLS minden hálózati csatornán.
- Secret manager használat, hardcoded credential tiltás.

### 5.2 Kötelező gate
- Deploy ajánlás előtt mindig futtatni:
  - powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
- FAILED vagy BLOCKED státusz esetén deploy tiltott.
- Evidence kötelező: security-reports/latest.

## 6. Adatmodell (minimum)

### 6.1 Központi PostgreSQL
- offices, users, roles, role_assignments
- transactions, transaction_legs, denominations
- treasury_transfers, seals, storno_events
- camera_segments, camera_segment_hashes, camera_exports
- sync_events, sync_conflicts, sync_retries
- daily_reports, monthly_reports, darius_submissions
- audit_log (immutable append-only)

### 6.2 Lokális SQLite (irodai kliens)
- local_transactions
- local_camera_index
- outbound_queue
- sync_checkpoint
- local_audit_ring

## 7. Kamera bizonyíték életciklus

### 7.1 Rögzítés
- Public és private stream külön logical channel.
- Segmentálás fix időablakban.
- Minden segmenthez:
  - timestamp,
  - officeId,
  - cameraId,
  - opcionális bizonylatszám link,
  - hash.

### 7.2 Megőrzés
- Alap retention: 50 nap.
- Disk-pressure policy: ha kritikus telítettség, priorizált takarítás az audit policy szerint.
- Legfrissebb/nyitott szegmens törlése tiltott.

### 7.3 Visszajátszás/export
- Role gate + indoklás kötelező mező.
- Export csomag:
  - media,
  - manifest.json,
  - hash lista,
  - optional player.
- Export napló immutable auditba kerül.

## 8. Offline-first és szinkron stratégia

- Outbox pattern minden kritikus domain eseményre.
- Idempotens üzenetkezelés (eventId + dedup index).
- Retry backoff + poison queue.
- Conflict policy:
  - tranzakciók: üzleti kulcs alapú feloldás,
  - kamera index: append-only,
  - riport állapot: explicit state machine.
- Sync SLA:
  - tranzakció meta: közel valós idő,
  - kamera meta: periódikus batch,
  - nagy media: sávszélesség-kímélő tömbös feltöltés.

## 9. Darius/Raiffeisen modul

### 9.1 Funkcionális követelmény
- Napi riport összeállítás és beküldés.
- Beküldési állapotkövetés (queued, sent, ack, failed).
- Havi lezárás/összesítő.
- Főpénztár jogosultságú felület.

### 9.2 Technikai interfész
- Adapter réteg (DariusAdapter):
  - payload builder,
  - signing/credential handling,
  - transport,
  - response parser.
- Teljes audit trail kötelező.

## 10. Stack opciók és ajánlás

### Opció A (ajánlott)
- Backend: Spring Boot + PostgreSQL
- Office client: Electron + SQLite
- Camera node: Java service
- Előny: jelenlegi repo stackhez illeszkedik, alacsonyabb migrációs kockázat.

### Opció B
- Backend: Spring Boot
- Office client: natív JavaFX
- Előny: egységesebb JVM stack
- Hátrány: meglévő React/Electron ökoszisztéma újraírási költség.

### Opció C
- Backend: .NET
- Office client: Electron
- Hátrány: platformszintű átállási kockázat nagy.

Választás: Opció A.

## 11. Fázisolt végrehajtási terv

### Fázis 0 — Stabil alap és biztonság
- Legacy viselkedés-katalógus véglegesítése.
- RBAC mátrix fixálás.
- Security gate baseline zöldre hozás.

Kilépési feltétel:
- Security gate PASS, kritikus sebezhetőség nélkül.

### Fázis 1 — Domain és adatmodell
- PostgreSQL séma + Flyway migrációk.
- Audit és sync táblák létrehozása.
- Core API-k (tranzakció, treasury, role).

Kilépési feltétel:
- Integrációs tesztek zöldek, migráció idempotens.

### Fázis 2 — Offline pénztár kliens
- SQLite outbox + sync engine.
- Tranzakciós képernyők és helyi validáció.
- Árfolyam TTL és AML ellenőrzés kötelező.

Kilépési feltétel:
- 24h hálózatkimaradás szimuláció mellett adatvesztés nélkül működik.

### Fázis 3 — Kamera evidence
- Recorder daemon + retention + repair.
- Visszajátszás és export pipeline.
- Szerepkör alapú hozzáférés + audit.

Kilépési feltétel:
- 50 napos retention policy tesztelt, export hash validáció zöld.

### Fázis 4 — Darius/Raiffeisen riport
- Daily report generálás és beküldés.
- Retry + hibakezelés + dashboard.
- Havi zárási riport.

Kilépési feltétel:
- UAT szerint napi riport folyamat üzletileg elfogadott.

### Fázis 5 — Rollout 50 irodára
- Pilot (3 iroda) -> wave deployment.
- Telemetria + incident runbook.
- Operációs tréning.

Kilépési feltétel:
- SLA célok teljesülnek, kritikus incidens trend csökken.

## 12. Tesztstratégia

- Unit tesztek domain logikára.
- Integrációs tesztek DB + API + sync.
- E2E szerepkörös jogosultság tesztek.
- Kamera export forenzikus validáció.
- Offline-chaos tesztek.
- Performance és soak teszt 50 irodás mintán.

## 13. AI ügynök végrehajtási utasítás (copy-paste képes)

Az alábbi utasítás egy AI coding agentnek adható közvetlen végrehajtásra.

---

Feladat:
A teljes valutaváltó rendszer modernizációját valósítsd meg a meglévő repositoryban, a dokumentumban definiált célarchitektúra szerint, offline-first, multi-branch, biztonságkritikus működéssel.

Kötelező szabályok:
1. Ne töröld a legacy bizonyítékot adó dokumentumokat.
2. Minden új backend endpoint role-protected legyen.
3. Minden kritikus művelet auditált legyen (ki, mikor, mit, miért).
4. Kamera export csak jogosultsággal és indoklással fusson.
5. Retention policy: alapértelmezetten 50 nap.
6. Darius napi riport modul kötelező scope.
7. Offline-first sync: outbox + idempotencia + retry.
8. Hardcoded secret tiltott.

Végrehajtási sorrend:
1. Hozd létre a szükséges PostgreSQL sémát Flyway migrációkkal.
2. Implementáld a Role/Permission modellt és audit logot.
3. Implementáld a treasury és tranzakciós core API-kat.
4. Implementáld az offline sync réteget (SQLite outbox, dedup, retry).
5. Implementáld a kamera evidence modult (record index, retention, export manifest, hash).
6. Implementáld a Darius/Raiffeisen daily reporting adaptert és state machinet.
7. Készíts admin felületeket:
   - szerepkör-kezelés,
   - kamera visszajátszás/export,
   - napi riport státusz.
8. Írj teszteket minden fázisra (unit/integration/e2e/offline).
9. Futtasd a projekt tesztjeit és buildet.
10. Deploy ajánlás előtt futtasd:
    - powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
11. Ha gate FAILED/BLOCKED, javítsd a hibákat és ismételd, amíg PASS.
12. Készíts rövid release note-ot a változásokról.

Elvárt kimenet:
- Futó backend + frontend + office kliens,
- dokumentált RBAC,
- bizonyítható 50 nap retention,
- bizonyítható napi Darius riport folyamat,
- PASS security gate evidence.

---

## 14. Definition of Done

- Funkcionális:
  - tranzakció, treasury, napzárás, riport folyamatok működnek.
- Biztonsági:
  - role-gate és audit teljes körű, security gate PASS.
- Operációs:
  - offline mód adatvesztés nélkül, sync konzisztens.
- Compliance:
  - kamera retention/export és Darius riport üzletileg validált.

## 15. Végrehajtás közbeni kötelező ellenőrző parancsok

- Backend teszt: cd backend && ./mvnw test
- Frontend teszt: cd frontend-react && npm test
- Pénztár kliens teszt: cd penztar-client && npm test
- Security gate: powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1

## 16. Current rendszer kódszintű állapotfelmérés (2026-03-20)

Megjegyzés: ez a blokk nem dokumentum-összefoglaló, hanem forráskód alapú állapotkép a jelenlegi implementációról.

### 16.1 Bizonyíték-alapú meglévő képességek (current)

- Tranzakciós magfolyamatok (vétel, eladás, konverzió, sztornó, részleges visszaváltás) implementáltak, endpoint szinten role-gate + idempotencia védelemmel.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/TransactionController.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- AML és azonosítási küszöb logika jelen van (300 000 HUF limit), POS integrációval együtt.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- 24 órás árfolyam-frissesség (TTL) és max-deviation validáció implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/ExchangeRateService.java`
- Treasury/értéktár átadás-átvétel komplex iránylogikával (F/U/UF/FF), counter-tranzakcióval és cash balance frissítéssel implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/TransferController.java`
- Napi jelentés generálás és submit státuszkezelés implementált branch szinten.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/DailyReportService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/DailyReportController.java`
- Office oldali offline-first működés: lokális SQLite queue (`pending_*` táblák), stabil idempotency kulcsok, periodikus szinkronmotor.
  - Bizonyíték: `penztar-client/electron/sqlite.ts`
  - Bizonyíték: `penztar-client/electron/sync-engine.ts`
- Kamera lokális rögzítés + retention + lokális export + takarítás implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/config/CameraProperties.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/CameraRecordingService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/CameraCleanupService.java`
  - Bizonyíték: `penztar-client/electron/camera.ts`

### 16.2 Legacy vs current parity mátrix (funkcionális és strukturális)

| Terület | Legacy elvárás | Current kódállapot | Parity | Kockázat |
|---|---|---|---|---|
| Tranzakciós core (vétel/eladás/konverzió/sztornó) | Teljes üzleti lánc | Implementált, role-gate + idempotencia + AML + POS | KOZEL TELJES | KOZEPES |
| Átadás-átvétel (ATADVET logika) | Direction-függő pénzmozgások | F/U/UF/FF modellezett, counter tx-ek és balance update-ek megvannak | KOZEL TELJES | KOZEPES |
| Napi jelentés alapfolyamat | Napi összesítés + beküldés | Generálás + submit van, de külső Darius csatorna nincs | RESZLEGES | MAGAS |
| Darius/Raiffeisen kötelező napi riport | Kötelező regulatory beküldés | Darius adapter/transport/scheduler nem azonosítható | HIANYOS | KRITIKUS |
| FTP bridge | Legacy kompatibilitás | `FtpSyncService` jelenleg mock/log implementáció | RESZLEGES | MAGAS |
| Branch sync backend | Valós adatcsere fiókok között | `SyncService` és `SynchronizationService` szimulációs/simplified jellegű | RESZLEGES | MAGAS |
| Office offline queue + retry | Offline működés adatvesztés nélkül | Erős implementáció: pending táblák + periodikus sync + idempotencia | ERSEN JELEN VAN | KOZEPES |
| Kamera retention (50 nap) | Kötelező megőrzés | Backend default 50 nap + ütemezett cleanup, Electron local cleanup is van | TELJES | KOZEPES |
| Kamera központi feltöltés | Központi bizonyíték-tár | `CameraUploadService` valós feltöltése pending, mock útvonal | HIANYOS | MAGAS |
| Kamera titkosítás/integritás | Forenzikus védelem | Config szinten van encryption paraméter, de használat nem látható | HIANYOS | KRITIKUS |
| Tranzakció-kamera automatikus összelinkelés | Receipt/time alapú bizonyíték lánc | Linker service létezik, de nincs bekötve a tranzakció mentési flow-ba | RESZLEGES | MAGAS |
| Jogosultsági modellek (területi vezető/kamera ellenőr) | Fine-grained role modell | Több camera endpoint `MANAGER/ADMIN` szintű, dedikált legacy role-ek nem látszanak végigvezetve | RESZLEGES | KOZEPES |

### 16.3 Kritikus gap-ek (zárás előtti P0)

1. Darius/Raiffeisen napi riport csatorna hiányzik a kötelező compliance scope-hoz.
2. Kamera központi feltöltés jelenleg mock, ezért end-to-end evidence lánc nem zárt.
3. Kamera titkosítás csak konfigurációs deklaráció, futó kriptográfiai pipeline nem látszik.
4. Branch szinkron backend oldalon több helyen szimulációs jellegű, nem teljes adatcsere.
5. Kamera-tranzakció automatikus linkelés nincs bekötve a transaction mentésbe.

### 16.4 Priorizált zárási terv (current hardening)

P0 (blokkoló):
- Darius adapter + state machine (`queued -> sent -> ack -> failed`) + retry scheduler.
- Kamera upload valós transport (chunk/hash), központi tárolás és visszaellenőrzés.
- Kamera titkosítás tényleges bekapcsolása (segment szint) és kulcskezelés.
- Transaction save flow-ban automatikus `CameraTransactionLinker` hívás.
- Sync backend valós branch adatcsere endpointokkal, nem csak szimulációval.

P1 (stabilizáció):
- Kamera export backend oldali manifest/hash validáció és role + reason enforcement.
- Legacy szerepkörök explicit modellezése (`TERULETI_VEZETO`, `KAMERA_ELLENOR`) UI+API oldalon.
- Outbox/inbox jelenlegi skeleton kiterjesztése több event típusra, nem csak rate publish.

P2 (optimalizáció):
- Monitoring dashboard KPI-k: queue depth, dead-letter trend, kamera pending upload, report SLA.
- Incident runbook és automatikus replay tooling a FAILED ágakra.



---

## Forras: docs\JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md

# Valutavalto ERP - Jira sprint bontas es fejlesztoi checklist

Datum: 2026-03-20
Terjedelem: Backend + Frontend + Electron
Sprint hossz: 2 het
Csapat minta: 2 backend, 2 frontend, 2 electron, 1 QA, 1 DevOps/Sec

## 1. Sprint utemezes

1. Sprint 0 (Alapozas es security baseline)
2. Sprint 1 (Core domain API + RBAC + audit)
3. Sprint 2 (Offline sync es penztar kliens alap)
4. Sprint 3 (Camera evidence retention/export)
5. Sprint 4 (Darius/Raiffeisen riport)
6. Sprint 5 (Hardening, pilot, rollout 50 iroda)

## 2. Jira issue format szabaly

Minden issue tartalmazza:
- Type
- Key
- Summary
- Description
- Acceptance Criteria
- Estimate
- Component
- Assignee
- Depends On

## 3. Sprintenkenti Jira backlog

## Sprint 0 - Alapozas es security baseline

Type: Epic
Key: VAL-EPIC-SEC
Summary: Security baseline and delivery guardrails
Description: RBAC matrix, audit policy, secret policy, mandatory gate automation.
Acceptance Criteria: Security baseline dokumentalt, gate PASS reproducible.
Estimate: 8 SP
Component: backend, devops, security
Assignee: DevOps-1
Depends On: none

Type: Story
Key: VAL-S0-BE-01
Summary: RBAC szerepkor matrix es permission catalog
Description: Legacy role mapping atultetese uj szerepkor modelbe.
Acceptance Criteria: Roles and permissions list approved by business owner.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-EPIC-SEC

Type: Story
Key: VAL-S0-BE-02
Summary: Audit event schema es immutable log policy
Description: Audit event taxonomia es tarolasi szabalyok.
Acceptance Criteria: Audit schema migracio es policy dokumentum kesz.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-EPIC-SEC

Type: Story
Key: VAL-S0-FE-01
Summary: Admin UI wireframe role es audit nezethez
Description: Frontend skeleton pages role management es audit viewer oldalhoz.
Acceptance Criteria: Navigalhato wireframe oldal, stakeholder review done.
Estimate: 3 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S0-BE-01

Type: Story
Key: VAL-S0-EL-01
Summary: Electron secure local storage baseline
Description: SQLite titkositasi policy es local key handling terv.
Acceptance Criteria: Dokumentalt es proof-of-concept mukodo local encrypted config.
Estimate: 5 SP
Component: electron
Assignee: EL-1
Depends On: VAL-EPIC-SEC

Type: Task
Key: VAL-S0-DEVOPS-01
Summary: Security gate pipeline hook
Description: scripts/security/run-security-gate.ps1 kotelezo futas CI gateben.
Acceptance Criteria: Pull request pipeline FAIL ha gate FAILED vagy BLOCKED.
Estimate: 3 SP
Component: devops
Assignee: DevOps-1
Depends On: VAL-EPIC-SEC

## Sprint 1 - Core domain API + RBAC + audit

Type: Epic
Key: VAL-EPIC-CORE
Summary: Core domain backend foundation
Description: Transactions, treasury transfers, role-protected endpoints, audit logs.
Acceptance Criteria: Core API endpontok role-protected es auditoltak.
Estimate: 13 SP
Component: backend
Assignee: BE-Lead
Depends On: VAL-S0-BE-01, VAL-S0-BE-02

Type: Story
Key: VAL-S1-BE-01
Summary: Flyway migration offices/users/roles/assignments
Description: Alap IAM schema migraciok es indexek.
Acceptance Criteria: Ures adatbazison migration PASS.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S0-BE-01

Type: Story
Key: VAL-S1-BE-02
Summary: Flyway migration transactions/treasury/storno/seal
Description: Core tranzakcios es penztar ertektar tablak.
Acceptance Criteria: CRUD integracios tesztek zold.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S1-BE-01

Type: Story
Key: VAL-S1-BE-03
Summary: @PreAuthorize policy minden uj controllerre
Description: Role policy enforcement tranzakcio es treasury endpointokon.
Acceptance Criteria: Unauthorized request 403, authorized 2xx.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-01

Type: Story
Key: VAL-S1-BE-04
Summary: Audit interceptor and append-only persistence
Description: API hivasi audit metadata tarolasa.
Acceptance Criteria: Ki, mikor, mit, miert mezok minden kritikus muveletnel.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S0-BE-02

Type: Story
Key: VAL-S1-FE-01
Summary: Role management oldal implementacio
Description: Role assignment admin felulet backend integracioval.
Acceptance Criteria: Role list, assignment, revoke, audit trail link mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S1-BE-03

Type: Story
Key: VAL-S1-FE-02
Summary: Audit viewer oldal implementacio
Description: Szurt audit lista datum, user, action alapon.
Acceptance Criteria: Pagination, filter, detail panel mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S1-BE-04

Type: Story
Key: VAL-S1-EL-01
Summary: Electron login + token refresh + role cache
Description: Biztonsagos bejelentkezes es local role cache.
Acceptance Criteria: Offline fallback role cache olvasas es token refresh tesztelt.
Estimate: 5 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S1-BE-03

## Sprint 2 - Offline sync es penztar kliens alap

Type: Epic
Key: VAL-EPIC-OFFLINE
Summary: Offline-first transaction pipeline
Description: Outbox, idempotencia, retry, conflict policy, local SQLite queue.
Acceptance Criteria: 24h network cut scenario adatvesztes nelkul PASS.
Estimate: 21 SP
Component: backend, electron
Assignee: EL-Lead
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S2-BE-01
Summary: Sync API endpoint csomag (batch pull/push)
Description: Event alapu sync endpointok dedup logikaval.
Acceptance Criteria: Ugyanaz event tobbszor kuldve idempotens.
Estimate: 8 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S2-BE-02
Summary: Sync events es retries adatmodell
Description: sync_events, sync_retries, sync_conflicts tablak + service.
Acceptance Criteria: Retry policy allapotgep tesztek zold.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-S2-EL-01
Summary: SQLite outbox tabla es producer layer
Description: Minden offline tranzakcio outbox esemenyt general.
Acceptance Criteria: Offline muveletek sorban mentodnek es visszakuldhetok.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-S2-EL-02
Summary: Sync worker retry with exponential backoff
Description: Hatterszinkron idozitett futtatasa hibaturo modon.
Acceptance Criteria: Retry limit, poison queue, user notification mukodik.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S2-EL-01, VAL-S2-BE-02

Type: Story
Key: VAL-S2-FE-01
Summary: Admin sync monitor dashboard
Description: Irodankenti sync status, queue depth, error trend nezet.
Acceptance Criteria: Last sync time, failed count, retry count lathato.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S2-BE-02

Type: Story
Key: VAL-S2-EL-03
Summary: Penztar tranzakcio alap kepernyok parity MVP
Description: Vetel/eladas alap folyamata offline validacioval.
Acceptance Criteria: Tranzakcio mentheto offline, sync utan kozpontban megjelenik.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-EL-01

## Sprint 3 - Camera evidence retention/export

Type: Epic
Key: VAL-EPIC-CAM
Summary: Camera evidence service
Description: Segment index, retention 50 nap, export package, hash verification.
Acceptance Criteria: Kamera export audit trail es hash validacio PASS.
Estimate: 21 SP
Component: backend, electron, frontend
Assignee: BE-Lead
Depends On: VAL-EPIC-OFFLINE

Type: Story
Key: VAL-S3-BE-01
Summary: camera_segments es camera_exports schema
Description: Segment metadata, hash, export manifest tarolas.
Acceptance Criteria: Migration + repository tesztek PASS.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S3-BE-02
Summary: Camera export API role gate and reason code
Description: Export kereses indoklas kotelezo mezo, role check.
Acceptance Criteria: Missing reason 400, unauthorized 403.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S3-BE-01, VAL-S1-BE-03

Type: Story
Key: VAL-S3-EL-01
Summary: Local recorder segment indexer
Description: Public/private segment metadata irasa local indexbe.
Acceptance Criteria: Segment metadata folytonos, hiany eseten alert.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-S3-EL-02
Summary: Retention worker 50 nap + disk pressure policy
Description: Takaritas retention szabaly szerint audit eventtel.
Acceptance Criteria: 50 napnal regebbi segment torlodik policy szerint.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S3-EL-01

Type: Story
Key: VAL-S3-EL-03
Summary: Export package generator with hash manifest
Description: Media + manifest + hash list + optional player csomag.
Acceptance Criteria: Ujrajatszas es hash ellenorzes sikeres.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S3-EL-01, VAL-S3-BE-02

Type: Story
Key: VAL-S3-FE-01
Summary: Kamera visszajatszas es export admin UI
Description: Datumtartomany, kamera tipus, role based action.
Acceptance Criteria: Export inditas csak jogosult userrel megy.
Estimate: 8 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S3-BE-02

Type: Story
Key: VAL-S3-FE-02
Summary: Export audit timeline UI
Description: Ki, mikor, melyik irodabol, milyen ugyhivatasra exportalt.
Acceptance Criteria: Audit timeline oldalon szures es details panel mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S3-BE-02

## Sprint 4 - Darius/Raiffeisen riport

Type: Epic
Key: VAL-EPIC-DARIUS
Summary: Daily and monthly regulatory reporting
Description: Darius adapter, status tracking, retry, chief treasury dashboard.
Acceptance Criteria: Daily report send flow UAT szerint megfelel.
Estimate: 21 SP
Component: backend, frontend
Assignee: BE-Lead
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S4-BE-01
Summary: daily_reports es darius_submissions schema
Description: Report allapotgep, request/response audit mezok.
Acceptance Criteria: queued-sent-ack-failed allapotok konzisztensen tarolodnak.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S4-BE-02
Summary: Darius adapter payload builder and transport
Description: Riport payload generalas, alairas, kuldes, parser.
Acceptance Criteria: Sandbox endpointtel sikeres roundtrip teszt.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S4-BE-01

Type: Story
Key: VAL-S4-BE-03
Summary: Daily report scheduler and retry policy
Description: Napi utemezett futas, hiba eseten retry.
Acceptance Criteria: Failed kuldes automatikusan ujraprobalhato.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S4-BE-02

Type: Story
Key: VAL-S4-FE-01
Summary: Fopenztari napi riport dashboard
Description: Report lista, status, resend, details nezet.
Acceptance Criteria: Csak chief treasury role fer hozza.
Estimate: 8 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S4-BE-03

Type: Story
Key: VAL-S4-FE-02
Summary: Havi osszesito es export oldal
Description: Monthly report summary and export actions.
Acceptance Criteria: Havi riport CSV/PDF export elerheto jogosultsaggal.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S4-BE-03

Type: Task
Key: VAL-S4-QA-01
Summary: Darius E2E UAT script
Description: End-to-end tesztforgatokonyv napi kuldeshez.
Acceptance Criteria: UAT script approval business ownertol.
Estimate: 3 SP
Component: qa
Assignee: QA-1
Depends On: VAL-S4-FE-01, VAL-S4-BE-03

## Sprint 5 - Hardening, pilot, rollout

Type: Epic
Key: VAL-EPIC-ROLL
Summary: Production hardening and staged rollout
Description: Performance, chaos, pilot wave, observability, runbook.
Acceptance Criteria: Pilot 3 iroda stabil 2 hetig, rollout decision gate PASS.
Estimate: 21 SP
Component: all
Assignee: Tech-Lead
Depends On: VAL-EPIC-DARIUS, VAL-EPIC-CAM

Type: Story
Key: VAL-S5-BE-01
Summary: Performance tuning indexes and query profiling
Description: Slow query javitas, index tuning, cache policy.
Acceptance Criteria: P95 API latency target teljesul.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S5-EL-01
Summary: Offline chaos test harness
Description: Random network cut and restore teszt runner electronre.
Acceptance Criteria: 24h chaos run adatvesztes nelkul PASS.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-EPIC-OFFLINE

Type: Story
Key: VAL-S5-FE-01
Summary: Operacios dashboard polish and incident view
Description: Unified admin health dashboard error trenddel.
Acceptance Criteria: Critical alerts es incident drilldown elerheto.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S2-FE-01, VAL-S3-FE-02, VAL-S4-FE-01

Type: Task
Key: VAL-S5-DEVOPS-01
Summary: Pilot rollout runbook es backup/restore drill
Description: Deploy wave script, rollback plan, DB restore gyakorlat.
Acceptance Criteria: Dry run dokumentalt evidence-szel.
Estimate: 5 SP
Component: devops
Assignee: DevOps-1
Depends On: VAL-EPIC-ROLL

Type: Task
Key: VAL-S5-QA-01
Summary: Release readiness checklist and sign-off
Description: Smoke, regression, security gate, UAT eredmenyek osszegzese.
Acceptance Criteria: Go-live sign-off dokumentum kesz.
Estimate: 3 SP
Component: qa
Assignee: QA-1
Depends On: VAL-S5-BE-01, VAL-S5-EL-01, VAL-S5-FE-01

## 4. Fejlesztokent kioszthato implementacios checklist

## BE-1 checklist
- [ ] VAL-S0-BE-01 role matrix implementalasa es review.
- [ ] VAL-S1-BE-01 IAM Flyway migraciok.
- [ ] VAL-S1-BE-03 role protection minden uj controlleren.
- [ ] VAL-S2-BE-01 sync API batch pull/push idempotens endpointok.
- [ ] VAL-S3-BE-02 camera export API reason code + role gate.
- [ ] VAL-S4-BE-01 daily_reports schema.
- [ ] VAL-S4-BE-03 napi scheduler + retry.
- [ ] Sajat issuekhoz unit + integration tesztek.

## BE-2 checklist
- [ ] VAL-S0-BE-02 audit schema es policy.
- [ ] VAL-S1-BE-02 transactions/treasury Flyway.
- [ ] VAL-S1-BE-04 audit interceptor.
- [ ] VAL-S2-BE-02 sync retries/conflicts adatmodell.
- [ ] VAL-S3-BE-01 camera metadata schema.
- [ ] VAL-S4-BE-02 Darius adapter implementacio.
- [ ] VAL-S5-BE-01 performance tuning.
- [ ] Sajat issuekhoz unit + integration tesztek.

## FE-1 checklist
- [ ] VAL-S0-FE-01 role/audit wireframe.
- [ ] VAL-S1-FE-01 role management oldal.
- [ ] VAL-S3-FE-01 kamera visszajatszas es export UI.
- [ ] VAL-S4-FE-02 havi osszesito oldal.
- [ ] VAL-S5-FE-01 ops dashboard polish.
- [ ] Component unit tesztek + E2E smoke flow frissites.

## FE-2 checklist
- [ ] VAL-S1-FE-02 audit viewer oldal.
- [ ] VAL-S2-FE-01 sync monitor dashboard.
- [ ] VAL-S3-FE-02 export audit timeline.
- [ ] VAL-S4-FE-01 fopenztari napi riport dashboard.
- [ ] Frontend role-guard regression tesztek.

## EL-1 checklist
- [ ] VAL-S0-EL-01 secure local storage baseline.
- [ ] VAL-S1-EL-01 login + token refresh + role cache.
- [ ] VAL-S2-EL-01 sqlite outbox producer.
- [ ] VAL-S2-EL-03 tranzakcio MVP kepernyok offline validacioval.
- [ ] VAL-S3-EL-02 retention worker 50 nap policy.
- [ ] Offline storage migration tesztek.

## EL-2 checklist
- [ ] VAL-S2-EL-02 sync worker retry/backoff/poison queue.
- [ ] VAL-S3-EL-01 recorder segment indexer.
- [ ] VAL-S3-EL-03 export package generator hash manifesttel.
- [ ] VAL-S5-EL-01 offline chaos test harness.
- [ ] File integrity es export replay tesztek.

## QA-1 checklist
- [ ] VAL-S4-QA-01 Darius E2E UAT forgatokonyv.
- [ ] VAL-S5-QA-01 release readiness sign-off.
- [ ] Sprint vegi regression matrix frissites.
- [ ] Security gate evidence ellenorzes minden release candidatehoz.

## DevOps-1 checklist
- [ ] VAL-S0-DEVOPS-01 security gate CI hook.
- [ ] VAL-S5-DEVOPS-01 pilot rollout runbook.
- [ ] Observability baseline: log, metric, alert policy.
- [ ] Backup/restore drill bizonyitekok tarolasa.

## 5. Sprint Definition of Done

- Minden issue acceptance criteria teljesult.
- Relevans tesztek lefutottak es sikeresek.
- Security gate PASS evidence elerheto.
- Dokumentacio frissitve (API, runbook, release note).
- Product owner elfogadas megtortent sprint review-n.

## 6. Javasolt issue labels

- area/backend
- area/frontend
- area/electron
- area/security
- area/reporting
- area/camera
- type/feature
- type/techdebt
- priority/p0
- priority/p1

## 7. Capacity minta sprintenkent

- BE-1: 8-10 SP
- BE-2: 8-10 SP
- FE-1: 6-8 SP
- FE-2: 6-8 SP
- EL-1: 8-10 SP
- EL-2: 8-10 SP
- QA-1: 4-6 SP
- DevOps-1: 4-6 SP

Megjegyzes: Ha a valos csapatmeret kisebb, a sprint issuek osszevonhatok, de a fuggosegek sorrendje maradjon.

## 8. Current parity gap backlog (kodalapu ujrapriorizalas)

Megjegyzes: ez a blokk a jelenlegi forraskod tenyleges allapotabol indul ki.

Type: Epic
Key: VAL-EPIC-CURRENT-HARDENING
Summary: Legacy parity closure from current codebase
Description: A mar meglevo implementacio hardeningje a hianyzo legacy-kritikus folyamatokra.
Acceptance Criteria: P0 parity gap-ek lezartak, security gate PASS, compliance smoke PASS.
Estimate: 21 SP
Component: backend, frontend, electron
Assignee: BE-Lead
Depends On: VAL-EPIC-CAM, VAL-EPIC-DARIUS

Type: Story
Key: VAL-CH-P0-BE-01
Summary: Darius daily adapter and state machine
Description: queued/sent/ack/failed allapotgep, retry scheduler, audit metadata.
Acceptance Criteria: Napi bekuldes vegigfut szimulalt/teszt endpointon, statusok konzisztensen tarolodnak.
Estimate: 8 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S4-BE-01

Type: Story
Key: VAL-CH-P0-BE-02
Summary: Kamera kozponti upload implementacio
Description: Mock upload lecserelese valos transport pipeline-ra, hibaturo retry-jal.
Acceptance Criteria: Completed szegmens valos feltoltese es visszaigazolt allapotfrissites.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-CH-P0-BE-03
Summary: Kamera titkositas aktiv hasznalat
Description: Config-only encryption helyett tenyleges segment titkositas + kulcskezeles.
Acceptance Criteria: Tarolt szegmens plain text-ben nem olvashato, decrypt folyamat tesztelt.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-CH-P0-BE-02

Type: Story
Key: VAL-CH-P0-BE-04
Summary: CameraTransactionLinker bekotese tranzakcio menteshez
Description: Minden transaction commit utan automatikus camera-link kepzes.
Acceptance Criteria: Receipt alapjan visszakeresheto kapcsolt felvetel metadata.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-CH-P0-BE-05
Summary: Sync service valos branch adatcsere
Description: Simplified sync implementaciok kivaltasa valos push/pull adatutakkal.
Acceptance Criteria: Nem csak darabszam/szimulacio, hanem tenyleges adatrekord mozgatas igazolhato.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-CH-P1-FE-01
Summary: Kamera export reason + audit timeline hardening UI
Description: Jogosultsag, indoklas, hash/manifest visszaellenorzes vizualizalasa.
Acceptance Criteria: Export inditas indoklas nelkul tiltott, audit timeline teljesen kovetheto.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-CH-P0-BE-02

Type: Story
Key: VAL-CH-P1-FE-02
Summary: Legacy kamera role mapping a feluleten
Description: Teruleti vezeto es kamera ellenor szerepkorokhoz dedikalt nezetek/jogok.
Acceptance Criteria: Role matrix szerint UI elemek es route-ok megfeleloen gate-eltek.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S1-BE-03

Type: Story
Key: VAL-CH-P1-EL-01
Summary: Offline queue observability panel
Description: Pending queue meretek, dead-letter, retry trend local diagnosztikara.
Acceptance Criteria: Support celra reprodukalhato queue allapotkep barmikor exportalhato.
Estimate: 3 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-EL-02

---

## Forras: docs\AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md

# Valutavalto ERP - End-to-End AI Execution Playbook

Datum: 2026-03-20
Cel: Egyetlen, vegrehajtasi sorrendu utasitascsomag AI ugynoknek a teljes implementaciohoz.
Hatar: backend + frontend + electron + security + rollout

## 1. Beolvasando alapanyagok (nem ujrakeszites)

1. docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md
2. docs/JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md
3. docs/ANTI_MASTERPLAN_WORKLOG_2026-03-20.md
4. docs/legacy-analysis-part1-core-docs.md
5. docs/legacy-analysis-part4-technical.md

Kotelezo: ezekre epits, ne keszits uj parity elemzest, csak hianyokat potolj.

## 2. Nem targyalhato kovetelmenyek

1. Kamera rogzites helyben, minimum 50 nap retention.
2. Kamera anyaghoz csak jogosult szerepkorok ferhetnek hozza.
3. Export hatosagi lejatszhato formatumban, audit nyomvonallal.
4. Bizonylatok helyi tarolasa minimum 1 honapig offline uzemben.
5. Folyamatos, biztonsagos szinkron kozponti PostgreSQL-be.
6. Darius/Raiffeisen napi riport mukodese kotelezo (fopenztar jogosultsag).
7. Multi-szint szervezeti modell: penztar -> ertektar -> fopenztar.

## 3. Stack dontes (fix)

1. Backend: Java 21 + Spring Boot 3.2 + PostgreSQL + Flyway.
2. Frontend admin: React + TypeScript.
3. Office kliens: Electron + React + SQLite.
4. Kamera node: local recorder service + export service + sync agent.

## 4. Vegrehajtasi sorrend (1 -> N)

## 4.1 Foundation

1. Hozz letre branch-et: feature/e2e-modernization-phase-1.
2. Ellenorizd a jelenlegi build allapotot:
   - backend teszt
   - frontend teszt
   - electron teszt
3. Rogzits baseline eredmenyeket docs alatt.

Kapu:
- Ha baseline bukik, eloszor baseline fix, csak utana uj feature.

## 4.2 Data model es security core

1. Flyway migraciok: users, roles, role_assignments, audit_log.
2. Flyway migraciok: transactions, treasury_transfers, storno_events, seals.
3. Flyway migraciok: camera_segments, camera_exports, camera_hashes.
4. Flyway migraciok: daily_reports, darius_submissions, sync_events, sync_retries, sync_conflicts.
5. Implementald az RBAC enforcementet minden uj endpointon.
6. Implementald az append-only audit irast kritikus muveletekre.

Kapu:
- Integracios tesztek zold.
- Unauthorized hozzaferes 403 minden vedett endpointon.

## 4.3 Offline-first tranzakcios csatorna (Electron + Backend)

1. SQLite outbox tablak letrehozasa electronben.
2. Tranzakcio mentes mindig outbox eventet general.
3. Sync worker implementacio:
   - exponential backoff,
   - dedup,
   - poison queue.
4. Backend sync endpointok:
   - batch push,
   - batch pull,
   - idempotens event feldolgozas.
5. Admin sync monitor endpoint + frontend oldal.

Kapu:
- 24 oras halozatkimaradas szimulacio utan adatvesztes 0.

## 4.4 Kamera evidence pipeline

1. Local segment indexeles public/private csatornara.
2. Hash kepzes minden segmentre.
3. Retention worker: 50 nap + disk pressure policy.
4. Export generator:
   - media,
   - manifest,
   - hash lista,
   - optional player.
5. Backend export API:
   - role gate,
   - kotelezo indoklas,
   - audit.
6. Frontend oldalak:
   - visszajatszas,
   - export inditas,
   - export audit timeline.

Kapu:
- Export hash validacio PASS.
- Jogosulatlan export 403.

## 4.5 Darius/Raiffeisen napi riport

1. Darius adapter interface + implementation.
2. Payload builder, transport, response parser.
3. Riport state machine: queued -> sent -> ack -> failed.
4. Retry mechanizmus failed allapotra.
5. Fopenztari dashboard:
   - napi riport lista,
   - allapot,
   - ujrakuldes.
6. Havi osszesito es export.

Kapu:
- UAT forgatokonyv sikeres.
- Chief treasury role nelkul nincs hozzaferes.

## 4.6 Rollout and hardening

1. Performance tuning (DB index, API latency).
2. Chaos/offline soak tesztek.
3. Pilot 3 iroda.
4. Wave rollout 50 irodara.
5. Incident runbook veglegesites.

Kapu:
- SLA celok teljesulnek.
- Kritikus incidencia trend nem romlik.

## 5. Feladatszalak komponensenkent

## 5.1 Backend kotelezo teendok

1. Flyway migration csomagok.
2. RBAC enforcement.
3. Audit append-only.
4. Sync API idempotencia.
5. Camera export API.
6. Darius adapter + scheduler.
7. Integration test suite bovites.

## 5.2 Frontend kotelezo teendok

1. Role management admin.
2. Audit viewer.
3. Sync monitor dashboard.
4. Camera replay/export UI.
5. Export audit timeline.
6. Fopenztari riport dashboard.

## 5.3 Electron kotelezo teendok

1. Secure local storage.
2. SQLite outbox.
3. Sync worker.
4. Tranzakcios offline workflow.
5. Camera segment indexer.
6. Retention worker.
7. Export package generator.

## 6. Hibakezelesi szabalyok AI ugynoknek

1. Ha teszt bukik, celzott javitas -> ujrafuttatas -> tovabblepes.
2. Ne ugord at a bukott teszteket skip-pel.
3. Minden modositasi blokk utan futtasd a relevans teszteket.
4. Security gate FAILED/BLOCKED eseten deployment tilos.

## 7. Minosegkapuk minden sprint vegen

1. Code quality: lint + typecheck + test PASS.
2. Security: gate PASS evidence elerheto.
3. Functional: acceptance criteria teljesult.
4. Operability: runbook friss.

## 8. Kotelezo parancsok

1. Backend teszt: cd backend && ./mvnw test
2. Frontend teszt: cd frontend-react && npm test
3. Electron teszt: cd penztar-client && npm test
4. Security gate: powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1

## 9. Atadasi csomag Definition of Done

1. Fut minden relevans teszt.
2. Security gate PASS.
3. Kamera retention/export bizonyithato.
4. Darius napi riport folyamat bizonyithato.
5. Dokumentacio frissitve:
   - architecture
   - runbook
   - release notes
   - known risks

## 10. Vegrehajtasi prompt AI coding agenthez

Feladatod:
A repositoryban a fent leirt sorrend szerint implementald a teljes modernizaciot ugy, hogy minden sprintkapu teljesuljon. Minden munkablokk utan futtasd a relevans teszteket. Ha teszt hiba van, javitsd azonnal, futtasd ujra, es csak utana haladj tovabb. A biztonsagi gate-et release javaslat elott kotelezo futtatni. FAILED vagy BLOCKED gate eseten deploymentet ne javasolj.

## 11. Delta mod (ha a rendszer mar reszben implementalt)

Ez a repository mar tartalmaz mukodo tranzakcios, offline es kamera alapokat, ezert teljes ujraepites helyett parity-closing mod javasolt.

### 11.1 Elso koros ellenorzes

1. Azonositsd a mock/simplified komponenseket es kulon backlogra bontsd:
   - `FtpSyncService` (mock)
   - `SyncService`/`SynchronizationService` (simplified)
   - `CameraUploadService` (mock upload)
2. Ellenorizd a compliance blokkolokat:
   - Darius/Raiffeisen adapter hiany
   - kamera titkositas csak config szinten
   - kamera-tranzakcio linker bekotes hianya

### 11.2 Prioritasi sorrend (delta)

1. P0: compliance es evidence-lanc zaras
2. P1: role-finomitas es audit/monitoring bovitese
3. P2: operacios optimalizacio es automatizalt replay

### 11.3 Konkreten vegrehajtando delta-lepesek

1. Darius state machine implementacio (`queued/sent/ack/failed`) + retry scheduler.
2. Kamera central upload mock kivaltasa valos transport implementacioval.
3. Kamera titkositas tenyleges hasznalata a segment pipeline-ban.
4. Transaction commit utan automatikus camera-link (`CameraTransactionLinker`) trigger.
5. Simplified backend sync vegpontok cserelese valos rekordszintu sync-re.
6. Frontend role matrix hardening legacy kamera-szerepkorokre.

### 11.4 Delta Definition of Done

1. Nincs mock/simplified komponens a kritikus (P0) folyamokban.
2. Darius napi riport allapotgep valos, visszakeresheto audit trail-lel.
3. Kamera evidence lanc (rogzites -> titkositas -> retention -> upload -> visszakereses) vegig igazolhato.
4. Security gate PASS + relevans backend/frontend/electron tesztek PASS.


---

## Forras: docs\ANTI_MASTERPLAN_WORKLOG_2026-03-20.md

# Anti Reverse Engineering Worklog (2026-03-20)

## 0. Cél
- Az Anti mappa és a meglévő dokumentációk alapján egyetlen végrehajtható AI programozási master utasítás készítése.
- Fókusz: kamera helyi rögzítés (50 nap), offline-first működés, szerver szinkron, napi jelentések (Darius/Raiffeisen), jogosultsági modell.

## 1. Első találatok
- Kötelező security skill beolvasva: `.claude/skills/security-deploy-gate/SKILL.md`.
- Anti gyökér fő ágak: `camera/`, `camera2/`, `camera3/`, `ERTEKTAR/`, `SZERVER/`, `VALUTA/`, `ARFOLYAM/`, `KORLEVEL_ZIP/`, `firebird/`.
- Repozitóriumban már léteznek erős kiinduló dokumentumok:
  - `docs/IMPLEMENTATION_PLAN_CAMERA_AND_RATES.md`
  - `docs/AI_EXECUTION_MASTERPLAN.md`
  - `docs/ANTI_LEGACY_PARITY_SPEC.md`
  - `docs/legacy-analysis-part1-core-docs.md`
  - `docs/legacy-analysis-part4-technical.md`
- Darius/Raiffeisen nyomok azonosítva (interjú és technikai elemzés dokumentumokban), plusz napi jelentés és jelentés workflow referenciák.

## 2. Anti fájltípus gyors inventory (első futás)
- java: 1614
- pas: 420
- dfm: 419
- dpr: 279
- xml: 204
- js: 10
- sql: 6
- cs: 5

## 3. Következő lépések
- Anti alatt a valódi forráskód fájlok strukturált kigyűjtése (kamera + szerver + értéktár + valuta).
- Működési folyamatok visszafejtése modulonként.
- Egységes végrehajtási terv összeállítása AI ügynök számára.

## 4. Tartósan mentett kód-inventár
- `docs/anti-code-files.txt`: Anti alatti kiválasztott kódfájl-lista.
- `docs/anti-code-summary.csv`: modul + kiterjesztés darabszám összesítő.

Fő megállapítás:
- `camera2` és `camera3` ágakban külön kameraalkalmazás-rétegek láthatók.
- `VALUTA` ágban a kulcs üzleti logika Delphi DLL-ekben van (napi jelentés, napzárás, átadás-átvétel, körlevél).

## 5. Legacy VALUTA kulcsmodulok (forrás bizonyítékok)

### 5.1 NAPIJEL (`Anti/VALUTA/DLL/NAPIJEL/MAKEDLL/Unit2.pas`)
- Napi jelentés összeállítás és beküldés logika (`JelentesIras`, `BekuldoGombClick`).
- Jelszó-kezelés hardverből (`Getjelszo`, `JELSZO`, `JELSZOKELTE` mezők).
- Értéktárhoz kötött jelentésfájl-képzés (`GetJelentesPath`, `_ertektar`).

### 5.2 NAPZAR (`Anti/VALUTA/DLL/NAPZAR/MAKEDLL/Unit2.pas`)
- Teljes napzárási lánc: ellenőrzések, napi jelentés, dekád, havi gyűjtő.
- Legacy függőségek: `napijel.dll`, `navzaro.dll`, `otp.dll`, `nznyomt.dll`.
- Nyitó/záró készlet és napi forgalom meghatározási logika (`NyitoMeghatarozas`, `NapiForgalomSzamitas`).

### 5.3 ATADVET (`Anti/VALUTA/DLL/ATADVET/MAKEDLL/Unit2.pas`)
- Pénztár↔értéktár tranzakciós műveletek (`PenztarAllAtvetel`, `ErtektarAllAtvetel`).
- Stornó és plomba-szám kezelési logika (`STORNO`, `PLOMBASZAM`, `TRBPENZTAR`).
- FTP/szerver irányú adatküldési útvonal (`FtpSzerverreLep`, `RemdirCtrlAndSend`).
- WU és egyéb mozgások külön könyvelése (`WUMOZGAS` insert minták).

### 5.4 KORLEV (`Anti/VALUTA/DLL/KORLEV/MAKEDLL/Unit2.pas`)
- Körlevél letöltés és olvasás FTP alapon.
- Hardcoded hitelesítési nyomok: `_userId`, `_ftpPassword`, `_ftpport`.
- Szerver oldali `korlevel.fdb` + `ptarosok.fdb` elérés.

## 6. Kamera rendszer visszafejtés (camera2)

### 6.1 Rögzítés
- `PublicCameraThread` és `PrivateCameraThread`: 300 ms ciklusú képlekérés, kamera állapotfigyelés.
- `PublicCameraFilmRecorderService` és `PrivateCameraFilmRecorderService`: 2 másodperces mentési ciklus.
- Fájlnévképzés órás szegmensben:
  - pénztári kamera: `...-hour.C1`
  - intim kamera: `...-hour.C2`
- Bizonylatszám bekötés: `CurrencyExchangeApi.getReceiptNumber()` (`C:\valuta\aktbizo.txt`).

Megjegyzés:
- A forrásban a tényleges fájlba írás sor kommentelt (`filmFileService.save(...)`), ezért a mentési lánc részben inaktív vagy más modulba szervezett lehet.

### 6.2 Visszajátszás és export
- `ExportModel` + `ExportController`: dátumtartományos export, public/private kamera szelekció, lejátszó másolása.
- `FilmConverterMainThread` + `FilmConverterWorkerThread`: fájl alapú export a célnyvtárba.
- `PlayerModel`: C1/C2 bináris frame-formátum feldolgozás, 16 byte headerből idő és bizonylatszám olvasás.

### 6.3 Retention és adatjavítás
- `FilmMaintenanceConfiguration`: 50 napos törlési küszöb, diszk telítettség esetén agresszívabb takarítás.
- `ExcludedFilmMaintenanceConfiguration` és `ExcludedOldFilmMaintenanceConfiguration`: régi mappákból (`Kamera filmek`, `Régi kamera filmek`) 50 napos takarítás.
- `LastFilmValidatorConfiguration`: sérült kamerafájl végének levágása (repair) valid JPEG olvasás alapján.

### 6.4 Jogosultság
- `SupervisorController` + `SupervisorModel`: külön supervisor unlock folyamat (QR + kód).

## 7. Kamera rendszer visszafejtés (camera3/old)
- `StorageMaintanerThread`: explicit 50 napos retention (`dayLimit = 50`) + tárhely alapon dinamikus csökkentés.
- `AuthsEnum`: szerepkörök: `Adminisztrátor`, `Területi vezető`, `Kamera ellenőr`.
- `RemoteClient` és kapcsolódó szálak: központi listázás, film szinkron, fájldarabolt továbbítás.
- `ConfigurationReader`: film/error/log path + email konfiguráció szerveroldalon.

## 8. Darius/Raiffeisen és jelentéskötelezettség
- Forrásdokumentum bizonyíték: `docs/legacy-analysis-part1-core-docs.md`.
- Üzleti elvárás azonosítva:
  - napi elszámolási kötelezettség a Raiffeisen felé,
  - tranzakciók beküldése Darius felületen,
  - havi teljes elszámolás.
- Adatbázis nyom: `darius.fdb` szerepel technikai elemzésben (`docs/legacy-analysis-part4-technical.md`).

## 9. Kockázati megállapítások
- Több legacy komponensben hardcoded hitelesítő adatok/jelszó-nyomok.
- Vegyes technológiai generációk (Delphi DLL + Java desktop + FTP/file alapú adatcsere).
- Számos folyamat még fájlrendszer-függő, részben implicit (kódban szétszórt).

## 10. Uj konszolidalt vegrehajtasi anyag
- Letrehozva: `docs/AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md`
- Cel: egyetlen 1->N sorrendu AI implementacios utasitascsomag.
- Tartalom:
  - fix stack dontes (backend/frontend/electron),
  - kotelezo kovetelmenyek (kamera 50 nap, role gate, Darius),
  - vegrehajtasi sorrend kapukkal,
  - komponensenkenti kotelezo feladatszalak,
  - teszt/security gate szabalyok,
  - atadasi Definition of Done.

## 11. Current rendszer kodalapu parity-felmeres (2026-03-20, kesoi frissites)

### 11.1 Vizsgalt current forrasteruletek
- Backend core: `TransactionController/Service`, `TransferController/Service`, `DailyReportController/Service`, `TreasuryController/TreasuryDashboardService`, `ExchangeRateService`, `Sync*`, `FtpSync*`, `Camera*` service-ek.
- Electron: `sync-engine.ts`, `sqlite.ts`, `camera.ts`, `main.ts`, `preload.ts`.
- Frontend route felulet: `frontend-react/src/App.tsx` + camera/sync/treasury oldalak.

### 11.2 Bizonyitott current erossegek
- Tranzakcios magfolyamatok es AML/POS/idempotencia jelen vannak.
- Transfer domainben direction-fuggo (F/U/UF/FF) counter-tranzakcio logika implementalt.
- Offline queue es periodikus sync motor stabil alapot ad (pending tablak + idempotency key-k).
- Kamera local recording + retention + local cleanup/export mukodik.
- 24 oras arfolyam TTL ellenorzes es max deviation validacio implementalt.

### 11.3 Azonositott parity gap-ek (kritikus)
- Darius/Raiffeisen napi riport adapter nem latszik implementaltnak.
- `FtpSyncService` jelenleg mock/log bridge.
- `SyncService` es `SynchronizationService` simplified/szimulacios jellegu.
- `CameraUploadService` valos upload helyett mock uploadot jelez.
- Kamera titkositas jelenleg konfiguracios deklaracio (futo crypto pipeline nem azonositott).
- `CameraTransactionLinker` letezik, de tranzakcio mentesi flow-hoz nincs explicit bekotese.

### 11.4 Dokumentumfrissites eredmenye
- `ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md`: uj "Current kodszintu allapotfelmeres" + parity matrix + P0/P1/P2 zarasi terv.
- `JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md`: uj "Current parity gap backlog" (VAL-CH-* issuek).
- `AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md`: uj "Delta mod" vegrehajtasi fejezet mar reszben implementalt rendszerre.


