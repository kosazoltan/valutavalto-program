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
