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
