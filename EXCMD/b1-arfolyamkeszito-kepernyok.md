---
title: "Árfolyamkészítő (RFM) — Képernyők"
modul: b1-arfolyamkeszito-kepernyok
kategoria: arfolyamkeszito
alkalmazas: arfolyam-keszito-client
szerepokor:
  - ROLE_TREASURER
  - ROLE_ADMIN
forrasok:
  - "Felmérés/Valuta/Cégcsoport felmérése/Árfolyamkészítőről/0-s lap, alapárfolyamok.jpg"
  - "Felmérés/Valuta/Cégcsoport felmérése/Árfolyamkészítőről/Árfolyamok szétküldése log_.jpg"
  - "Felmérés/Valuta/Cégcsoport felmérése/Árfolyamkészítőről/Csoport karbantartó 2.jpg"
  - "Felmérés/Valuta/Cégcsoport felmérése/Árfolyamkészítőről/Csoport, nem kézzel állítós hanem a 0-s árfolyamlapról töltődik.png"
  - "Felmérés/Valuta/Cégcsoport felmérése/Árfolyamkészítőről/Csoportok karbantartó.jpg"
prio: Magas
utolso_frissites: "2026-06-02"
media_eredetu: true
---

<system_context>
# Modul: Árfolyamkészítő (RFM) — Képernyők

## Kontextus
A meglévő (Delphi-szerű) árfolyamkészítő program képernyőinek leírása 5 db screenshot alapján: `0-s lap, alapárfolyamok.jpg`, `Csoportok karbantartó.jpg`, `Csoport karbantartó 2.jpg`, `Csoport, nem kézzel állítós hanem a 0-s árfolyamlapról töltődik.png`, `Árfolyamok szétküldése log_.jpg`. Ez a modul felelős a 0-s alapárfolyam-lap karbantartásáért, az irodacsoportok kiosztásáért (csoport-karbantartó), a csoport árfolyamlapok megtekintéséért és az árfolyamok szerverre történő szétküldéséért.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`arfolyam-keszito-client`)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Főértéktáros (Main Treasurer) / Rendszeradminisztrátor (System Administrator)**: Teljes hozzáféréssel rendelkezik a központi árfolyam-készítő és szétküldő képernyőkhöz. Ők határozzák meg az elszámoló árfolyamokat és a képleteket (RBAC érték: `ROLE_TREASURER`, `ROLE_ADMIN`).
- **Kasszás / Pénztáros (Cashier)**: Offline üzemmódban kézi árfolyam-felülbírálatot végezhet a helyi kliensen, ha a Supervisor beírja a jóváhagyó jelszavát a képernyőn (napi 3 jelszó nélküli sztornó után a 4.-től kezdve szintén Supervisor jelszó szükséges közvetlen bevitellel). Ekkor a sávos kedvezmények helyett fix árfolyamot alkalmaz a program (RBAC érték: `ROLE_CASHIER`).

## Hatókör (Scope)
- **IN**:
  - Felső menüsor (közös): "CSOPORTOK KARBANTARTÁSA", "ÁRFOLYAMOK SZÉTKÜLDÉSE (A SZERVEREN ÁT)", "INTERNET CÍMEK KARBANTARTÁSA", "KILÉPÉS A PROGRAMBÓL".
  - Csoport-karbantartó almenü: "VISSZA AZ ALAPLAPADATOK KARBANTARTÁSÁRA", "ÚJ PÉNZTÁRI/PÉNZTÁR FELVÉTELE MUNKACSOPORTBA", "PÉNZTÁR TÖRLÉSE EGY MUNKACSOPORTBÓL", "MUNKACSOPORT ÁTNEVEZÉSE", "PÉNZTÁR ÁTHELYEZÉSE MÁSIK CSOPORTBA".
  - 0-s alapárfolyam-lap teljes oszlopkiosztása (A–I + internet).
  - Csoport árfolyamlap oszlopkiosztása (J–S) + csoport-fej panel (csoportszám, csoportnév, irodalista, aktuális függvény, kitöltési segítség, kedvezményhatárok).
  - Csoport-karbantartó rács (1–54 számozott iroda-csempék) + jobb oldali "A JELÖLT CSOPORTOKAT ELLENŐRZI A PROGRAM" checklista (1–54).
  - Szétküldés művelet-log (sikeres lokális mentés + sikertelen szerverre mentés üzenetek).
- **OUT**:
  - A program belső technológiája/forráskódja.
  - A pénztáros/eladói felület.
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-RFMUI-01] [Felső fő menüsor]
- **Leírás**: Felső fő menüsor biztosítása 4 ponttal: Csoportok karbantartása, Árfolyamok szétküldése (a szerveren át), Internet címek karbantartása, Kilépés a programból.
- **Forrás**: img1 (0-s lap), img5 (szétküldés) felső sáv
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói kattintás
- **Kimenet / Visszajelzés**: Megfelelő almodul vagy párbeszédablak megnyitása
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-02] [0-s alapárfolyam-lap táblázat oszlopai]
- **Leírás**: A 0-s alapárfolyam-lap táblázat oszlopfejléceinek megjelenítése: A=Elszámoló árfolyamok, B=OTP, C=SEGÉD, D=VALUTA NEMEK, E/F=GYENGE ÁRF-OS MULTIK (VÉTEL/ELADÁS), G/H=KERESZT ÁRFOLYAMOK (EUR/USD), I=NAGYBANI, plusz az INTERNET oszlop.
- **Forrás**: img1 fejléc
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: 0-s lap betöltése
- **Kimenet / Visszajelzés**: 9 oszlopos táblázatos nézet
- **Validációk és Kényszerek**: Az oszlopok sorrendje fix.

### ### [FR-RFMUI-03] [0-s lap valutasorrend]
- **Leírás**: A 0-s lapon a D oszlopban a valuták sorrendje felülről lefelé: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH.
- **Forrás**: img1 D oszlop
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valutalista
- **Kimenet / Visszajelzés**: A megadott sorrendű valuták táblázatban
- **Validációk és Kényszerek**: Pontosan a megadott 28 elemnek kell megjelennie ebben a sorrendben.

### ### [FR-RFMUI-04] [Kézi cellák vizuális kiemelése]
- **Leírás**: A 0-s lapon a kézzel állított elszámoló cellák vizuálisan kiemeltek (pl. AUD elszámoló piros kerettel; a B/C oszlop egyes cellái zöld háttérrel).
- **Forrás**: img1
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cella módosítási állapota
- **Kimenet / Visszajelzés**: Különböző háttérszín vagy keret a manuálisan szerkesztett cellákon
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-05] [Kereszt-árfolyamok kitöltése]
- **Leírás**: A kereszt-árfolyam oszlopok (G/H) csak a nem-fő valutáknál töltöttek, EUR/USD bázis-feliratokkal; a fő valutáknál (EUR..SEK) a G/H/I érték 0.
- **Forrás**: img1 G/H/I oszlop
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valuta típusa
- **Kimenet / Visszajelzés**: 0-ás érték vagy keresztárfolyam érték
- **Validációk és Kényszerek**: Fő valuták esetén a keresztárfolyam cellák lezártak (0).

### ### [FR-RFMUI-06] [INTERNET oszlop tartalom]
- **Leírás**: Az INTERNET oszlop forrásmegjelölést tartalmaz valutánként (pl. OTP, Feco, EUR/CZK, Realtime FX, BRN RON, Szerb Dínár, BGN, SHEKEL, HRIVNYA, RUBEL, CNY), és a fejlécben a forrás URL látható: http://www.exchange-rates.org/MajorRates/Byname/R.
- **Forrás**: img1 INTERNET oszlop + fejléc URL
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Internet konfigurációs adatok
- **Kimenet / Visszajelzés**: URL címer és forráscímkék
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-07] [Csoport-karbantartó rács]
- **Leírás**: Csoport-karbantartó képernyőn 54 számozott iroda-csempe rácsban való megjelenítése (1..54), mindegyik iroda nevével (pl. 1 ÁRKÁD, 2 PÉCS FERENCSEK, 16 PAKSÉK, 54 PÉCS RÁKÓCZI).
- **Forrás**: img2, img3 csempe-rács
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Irodák listája
- **Kimenet / Visszajelzés**: 54 csempéből álló hálós nézet
- **Validációk és Kényszerek**: Pontosan 54 csempének kell megjelennie.

### ### [FR-RFMUI-08] [Csoport-karbantartó ellenőrző panel]
- **Leírás**: Csoport-karbantartó jobb oldali panelje: "A JELÖLT CSOPORTOKAT ELLENŐRZI A PROGRAM" — 1..54 sorszámozott checklista pipákkal.
- **Forrás**: img2, img3, img5 jobb panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Ellenőrzési státuszok
- **Kimenet / Visszajelzés**: Checkbox lista 1-től 54-ig
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-09] [Csoport-karbantartó almenü]
- **Leírás**: Csoport-karbantartó almenü biztosítása 5 művelettel: Vissza az alaplapadatok karbantartására, Új pénztár felvétele munkacsoportba, Pénztár törlése egy munkacsoportból, Munkacsoport átnevezése, Pénztár áthelyezése másik csoportba.
- **Forrás**: img2, img5 almenü-sáv
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói kattintás
- **Kimenet / Visszajelzés**: Adott csoport-művelet elindítása
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-10] [Művelet panel és beviteli mező]
- **Leírás**: A karbantartó képernyő középső sárga panele "MŰVELET = KARBANTARTÁS" felirattal + beviteli mezővel a kijelölt művelethez.
- **Forrás**: img2
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Kiválasztott művelet
- **Kimenet / Visszajelzés**: Karbantartási beviteli felület
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-11] [Üres csoport jelzése]
- **Leírás**: Üres-csoport állapot jelzése: ha egy csoporthoz nincs iroda rendelve, a panel "NINCS IRODA ITT" üzenetet mutat.
- **Forrás**: img3 középső panel
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Csoport irodatagsága
- **Kimenet / Visszajelzés**: "NINCS IRODA ITT" szöveges figyelmeztetés
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-12] [Iroda-csempe státusz-szín]
- **Leírás**: Az iroda-csempék színei a kijelölési állapotot tükrözik. A piros háttér (`Color := clRed`) a felhasználó által éppen kijelölt és aktív irodacsoportot/irodát mutatja a karbantartó felületen. Kattintásra vagy rámutatásra az érintett csempe piros hátteret és fehér betűszínt kap. A zöld háttér (`clLime`) az automatikus érték-lehúzás (Zöldrutin) futása során az éppen kitöltés alatt álló sorokat jelöli a folyamat alatt (sleep-es animáció mellett).
- **Forrás**: Unit7.pas, Unit9.pas, img2, img5 csempe-színek
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói egér- és kijelölési események
- **Kimenet / Visszajelzés**: Piros háttér az aktívan kiválasztott csempén
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-13] [Csoport árfolyamlap fejléc]
- **Leírás**: Csoport árfolyamlap fejlécének megjelenítése: csoportszám + csoportnév (pl. "16 CSOPORT", "PAKSÉK"), valamint "A CSOPORTBA TARTOZÓ IRODÁK" lista (Kalocsa - Tesco / Paks - Tesco).
- **Forrás**: img4 jobb panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Csoport azonosító
- **Kimenet / Visszajelzés**: Fejléc adatok és irodalista megjelenítése
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-14] [Csoport árfolyamlap oszlopai]
- **Leírás**: Csoport árfolyamlap oszlopfejléceinek megjelenítése: J=Elsz.árf, K=Valuták, L/M=0-50.000 Vétel/Eladás, N/O=50.001-300.000 Vétel/Eladás, P/Q=300.001-1.000.000 Vétel/Eladás, R/S=Saját hatáskörű (Vét.max/Elad.min).
- **Forrás**: img4 bal táblázat fejléc
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Csoportlap betöltése
- **Kimenet / Visszajelzés**: Megfelelő oszlopszámú csoportlap táblázat
- **Validációk és Kényszerek**: Fix oszlopkiosztás és sávhatárok.

### ### [FR-RFMUI-15] [Aktuális függvény megjelenítés és képlet-szemantika]
- **Leírás**: A Csoport árfolyamlap "AKTUÁLIS FÜGGVÉNY" mezője az adott cellához tartozó képletet jeleníti meg és validálja. A képlet szintaxisa a következő elemekből állhat:
  - Oszlopbetű: Aktuális sor adott oszlopának értéke, pl. `J` (Elszámoló árfolyam), `L` (0-50k vétel). Megengedett oszlopok: A-C, E-J, L-S. A D (valutanem) és K (valutanem név) szöveges mezők, ezért a képletekből ki vannak zárva.
  - `!col_letterCUR` (Felkiáltójel + oszlopbetű + valuta kód): Egy konkrét másik valuta sorának adott oszlopértéke, pl. `!LEUR` (az EUR vétel sávja) vagy `!JUSD` (az USD elszámoló árfolyama).
  - `#group_indexcol_letter` (Kettőskereszt + 2 jegyű csoportindex + oszlopbetű): Másik irodacsoport aktuális valutára vonatkozó értékének beemelése, pl. `#01M` (01-es csoport M eladási sávja a jelenlegi valutára).
  - Standard műveletek: összeadás (`+`), kivonás (`-`), szorzás (`*`), osztás (`/`) és tetszőlegesen beágyazott zárójelek `(` és `)`.
- **Forrás**: Unit3.pas (TGetFuggveny.Fit, Besorol, JoBetu), Unit1.pas (FvenybolNum, GetcsoportErtek)
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Képletszöveg beviteli mezőből
- **Kimenet / Visszajelzés**: Számított értékek, hibás szintaxis esetén a mentés letiltása
- **Validációk és Kényszerek**: A szintaxist a Unit3.pas mintájára felépített Fit állapotgép ellenőrzi karakterenként (például betű után nem állhat szám, csak ha kettőskereszt utáni csoportkód és oszlop jelölés részei).

### ### [FR-RFMUI-16] [Kedvezményhatárok panel]
- **Leírás**: Csoport árfolyamlap "KEDVEZMÉNY HATÁROK" panel 3 mezővel: ALSÓ 50.000, KÖZÉPSŐ 300.000, FELSŐ 1.000.000.
- **Forrás**: img4 jobb-alsó panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Sávhatár adatok
- **Kimenet / Visszajelzés**: Határérték mezők
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-17] [Kitöltési segítség szekció]
- **Leírás**: Csoport árfolyamlap "KITÖLTÉSI SEGÍTSÉG" feliratú szekció megjelenítése a kedvezményhatárok felett.
- **Forrás**: img4
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: N/A
- **Kimenet / Visszajelzés**: Segítő címkék
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-18] [0-s lapról való automatikus töltődés]
- **Leírás**: A csoport árfolyamlap értékei a 0-s árfolyamlapról töltődnek be, a felhasználó közvetlenül nem írhatja át azokat kézzel ezen a felületen.
- **Forrás**: img4 fájlnév ("Csoport, nem kézzel állítós...")
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: 0-ás lap adatai
- **Kimenet / Visszajelzés**: Csoportlap kalkulált cellái
- **Validációk és Kényszerek**: A J-S cellák szerkesztése letiltott ezen a lapon.

### ### [FR-RFMUI-19] [Szétküldés művelet-log]
- **Leírás**: Árfolyamok szétküldése során a művelet-log lépéssorrendet jelenít meg: `ARFDATA.DAT` bináris állomány generálása és rögzítése a helyi gépen, majd feltöltése az aktív FTP szerverekre (elsődleges: Békéscsaba `_bcsabaHost: 185.43.207.99:21100`, másodlagos: Pécs `_pecsHost: 21` FTP szerver). A logban megjelenő lépések: `ARFDATA.DAT` rögzítése -> fiókok, internet címek, alapárfolyamok és munkacsoportok feltöltése. A feltöltés végén a távoli szerveren lévő ideiglenes `RF*.DAT` és `NR*.DAT` állományok törlésre kerülnek a szinkronizáció lezárásaként.
- **Forrás**: Unit6.pas (TAdatSzetkuldes.UploadFiles, FtpPutFile, FtpDeleteFile), img5 log-panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Szétküldési folyamat állapota
- **Kimenet / Visszajelzés**: Lépésenként frissülő log lista
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-20] [Lokális mentés log visszajelzés]
- **Leírás**: Szétküldés-log sikeres lokális mentés esetén az alábbi visszajelzést írja ki: "A saját gépemre sikeresen lementettem az adatokat".
- **Forrás**: img5 log-panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Lokális mentés státusza
- **Kimenet / Visszajelzés**: "A saját gépemre sikeresen lementettem az adatokat" szöveg a logban
- **Validációk és Kényszerek**: N/A

### ### [FR-RFMUI-21] [Szerver biztonsági mentés log és hiba]
- **Leírás**: Szétküldés-log: biztonsági mentés végzése a békéscsabai szerverre. Ha az elsődleges FTP kapcsolat sikertelen vagy megszakad, a rendszer automatikusan megpróbálja a feltöltést a másodlagos (Pécsi) szerverre. Ha mindkét feltöltés meghiúsul, a következő hibaüzenetet írja ki a logban: "A BIZTONSÁGI MENTÉS SIKERTELEN VOLT! A szerverre nem sikerült kitenni az adatokat".
- **Forrás**: Unit6.pas (UploadFiles, try-catch FTP connect), img5 log-panel
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client / backend
- **Bemenő adatok**: Szerveroldali FTP mentés státusza
- **Kimenet / Visszajelzés**: Hibaüzenet megjelenítése a logban
- **Validációk és Kényszerek**: A szerver-feltöltési hiba nem akadályozhatja meg a helyi `ARFDATA.DAT` sikeres mentésének rögzítését.

### ### [FR-RFMUI-22] [B-csoport valuta sorrendje]
- **Leírás**: A B-csoportos árfolyamlap rácsában (`RateCreationPage.tsx`) a valutáknak szigorúan a Főlap (`MainRateSheetPage.tsx`) alapértelmezett sorrendjében kell megjelenniük: `EUR, USD, GBP, CHF, AUD, CAD, JPY, CZK, PLN, RON, RSD, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD`. (DKK, NOK, SEK, HRK, BGN, RCH inaktív devizák nem jelennek meg).
- **Forrás**: FK02-B audit 1.1 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Szerverről letöltött valuták listája
- **Kimenet / Visszajelzés**: Főlap sorrendjére rendezett rács

### ### [FR-RFMUI-23] [Drag cella-kijelölés és lebegő toolbar]
- **Leírás**: A csoportos árfolyamlap táblázatában (`RateGrid.tsx`) a cellák kijelölésének támogatnia kell a tartomány alapú kijelölést egérrel történő vonszolással (drag) vagy Shift+kattintással. A kijelölt tartomány mellett egy kontextuális lebegő eszköztárnak kell megjelennie, amely az alábbi három funkciót kínálja:
  - "Lehúzás (üres)": a kijelölt cellák értékének vagy képletének törlése.
  - "Lehúzás (mind)": a kijelölt tartomány legelső sorának értékeit vagy képleteit másolja végig az oszlop többi kijelölt cellájába.
  - "Sávok törlése": csak a kijelölt sorok N-S (kedvezményes sáv) oszlopaiból törli a rátákat, a fő vételi/eladási oszlopokat (L-M) békén hagyja.
- **Forrás**: FK02-B audit 1.3 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cella egeres drag/Shift-kattintás koordináták
- **Kimenet / Visszajelzés**: Lebegő toolbar akciókkal a kijelölt rács mellett

### ### [FR-RFMUI-24] [Irodák kezelése szűrt választó]
- **Leírás**: Az Árfolyamkészítő irodaválasztó dialógusában ("Irodák kezelése") kizárólag aktív lakossági pénztárak (`branchType.code == 'PENZTAR'` és `isVault != true`) szerepelhetnek. A belső banki/speciális partnerek (`VAULT_COUNTERPARTY`: `ERB`, `FRB`, `RB`, `MNB`, `TH`, `UPT`, `TRB`, `PRB`, `JRB`, `FOP1`) és értéktárak (`isVault = true`) nem jelenhetnek meg a listában.
- **Forrás**: FK02-C audit
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Irodák törzslistája
- **Kimenet / Visszajelzés**: Kizárólag pénztárakat tartalmazó választható irodalista
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

A forrásképernyők és logok alapján az alábbi adatmodell-entitások szükségesek:

### PostgreSQL (Szerver oldali tárolás)
- **Branch (Iroda)**:
  - `id` (int, primary key)
  - `code` (varchar, egyedi azonosító, pl. '1', '17') -- Legacy leképzés: `PENZTAR.KOD`
  - `name` (varchar, pl. 'ÁRKÁD', 'BONYHÁD')
- **OfficeGroup (Munkacsoport)**:
  - `id` (int, primary key) -- Legacy leképzés: `MUNKACSOPORT.ID` (1..54 csoport)
  - `name` (varchar, pl. 'PAKSÉK')
  - `formula_code` (varchar, pl. '#01M')
- **OfficeGroupMember (Csoport-tagok)**:
  - `group_id` (foreign key -> OfficeGroup)
  - `branch_id` (foreign key -> Branch)
- **GroupThresholds (Kedvezményhatárok)**:
  - `group_id` (foreign key -> OfficeGroup)
  - `lower_limit` (decimal, default 50000) -- Alsó sáv határ
  - `middle_limit` (decimal, default 300000) -- Középső sáv határ
  - `upper_limit` (decimal, default 1000000) -- Felső sáv határ
- **CurrencyRateSource (Internet forrás)**:
  - `currency_code` (varchar, pl. 'EUR', 'USD')
  - `source_label` (varchar, pl. 'OTP', 'Feco', 'Realtime FX')
  - `main_url` (varchar, default 'http://www.exchange-rates.org/MajorRates/Byname/R')

### SQLite (Offline mirror a kliensen)
- A kliensnek tükröznie kell a `Branch`, `OfficeGroup`, `OfficeGroupMember` és `GroupThresholds` táblákat a helyi szerkesztéshez és az `ARFDATA.DAT` generálásához.

### Bináris fájl struktúra: `ARFDATA.DAT`
Az árfolyam-elosztás a legacy Delphi rendszerben egy fix méretű bináris fájlon keresztül történik, amelyet a kliensek letöltenek.
- **Fájl teljes mérete**: `58 848 byte`.
- **Szerkezet**:
  - `1. byte`: Verziószám / fejléc azonosító.
  - `2-201. byte`: Csoportok aktív kódjai és nevei (54 csoport * 3 byte csoportkód + nevek, kitöltve).
  - `202-58845. byte`: Árfolyam és limit adatok a 54 csoporthoz. Minden csoport rekordja pontosan `1086 byte` hosszúságú:
    - **Árfolyam tömb**: `1080 byte` (24 valutanem * 9 árfolyam oszlop * 5 byte Real48 lebegőpontos érték). A 9 oszlop: J (elszámoló), L/M (alsó vétel/eladás), N/O (közép vétel/eladás), P/Q (felső vétel/eladás), R/S (saját max vétel/min eladás).
    - **Limit tömb**: `6 byte` (3 db kedvezményhatár-küszöb * 2 byte Word egész érték: alsó, középső, felső limitek).
  - `58846-58848. byte`: Lezáró aláírás / checksum szekció (`_signing = true` esetén).
</data_structure>

<integration_points>
## Integrációs Pontok
- **FTP Árfolyam Elosztó Szerverek**:
  - Biztonsági mentés és árfolyam-terjesztés célpontjai a szétküldés során.
  - **Elsődleges szerver**: Békéscsaba FTP (`_bcsabaHost = '185.43.207.99'`, port: `21100`).
  - **Másodlagos szerver**: Pécs FTP (`_pecsHost = '21.sz.szerver'`, port: `21` - fallback hálózati probléma esetén).
  - **Protokoll**: FTP passzív mód, bináris átviteli mód. A fájlokat a távoli `_arfolyamdir` könyvtárba kell elhelyezni, majd a sikeres feltöltést követően a kliensek értesítésére a távoli könyvtárban lévő korábbi `RF*.DAT` és `NR*.DAT` állományokat törölni kell.
- **Külső árfolyam-szolgáltató (exchange-rates.org)**:
  - Globális URL alapú árfolyam-adatforrás (FR-RFMUI-06).
  - Valutánkénti egyedi források (OTP, Feco, Szerb Dínár, stb.).
- **NAV Online Kassza Integráció**:
  - A klienseken a sztornózás és módosítás automatikusan nyomtatásra kerül az online pénztárgép driveren keresztül, ami beküldi a sztornó bizonylatot a NAV-hoz.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd el ezt az MD fájlt és a `b1-arfolyamkeszito-kovetelmenylista.md` fájlt együtt.
- Ellenőrizd a 28 darabos valutalistát és a 0-ás lap oszlopait az A-tól I-ig tartó leírásokkal.

### Phase 2: Backend (Backend)
- Hozd létre az adatbázis sémát (Postgres + Flyway migrációk).
- Valósítsd meg a mentési és szétküldési végpontokat a szerveren, beleértve a Békéscsabára küldés hibakezelését és logolását.
- Fejleszd ki az `ARFDATA.DAT` fájl szerializációs logikáját.

### Phase 3: Frontend/Client (Frontend/Client)
- Készítsd el a 0-s lap táblázatos felületét (28 sor, A-I oszlopok, kiemelt kézi cellák, internet forrás URL).
- Fejleszd le a Csoport-karbantartó felületet a 54 iroda-csempével és a jobb oldali ellenőrző checklisttel.
- Készítsd el a Csoport árfolyamlapot (nem módosítható J-S oszlopok, képletkód, sávértékek).
- Valósítsd meg a Szétküldés oldalt a futási logpanellel.

### Phase 4: Ellenőrzés (Verification)
- **Komponens tesztek**: 54 csempe és a 1-54 checklista helyes kirajzolódása, üres csoport státusz kijelzése.
- **Integrációs tesztek**: Adatátvitel ellenőrzése a 0-s lapról a Csoportlapra.
- **Negatív tesztek**: Szerver elérhetetlenség szimulációja -> a lokális mentésnek sikeresnek kell lennie, a szervermentésnek hibát kell naplóznia.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | A piros háttérszínű iroda-csempék (pl. BONYHÁD, KAP KORZÓ, PÉCS RÁKÓCZI) jelentése | Státusz-logika és színezési szabályok | **LEZÁRVA**: A piros szín (`clRed`) a felületen az éppen kijelölt/aktív csoportot vagy irodát jelzi szerkesztés közben. |
| 2 | Az "Aktuális függvény" kódkatalógus (#01M, …) teljes listája és szemantikája | Csoportlap-számítás | **LEZÁRVA**: A képletek Oszlopbetűt (A-C, E-J, L-S), `!col_letterCUR` valutahivatkozást (pl. `!LEUR`), vagy `#group_indexcol_letter` csoporthivatkozást (pl. `#01M`) tartalmazhatnak standard operátorokkal és zárójelekkel. |
| 3 | ARFDATA.DAT pontos formátuma/sémája | Export/import implementáció | **LEZÁRVA**: 58 848 byte méretű bináris fájl, csoportonként 1086 byte-os rekordszerkezettel (1080 byte Real48 lebegőpontos árfolyam tömb + 6 byte Word típusú sávlimitek). |
| 4 | A szerver-szétküldés protokollja (FTP/HTTP/share) a békéscsabai szerverre | Integráció és hálózati réteg | **LEZÁRVA**: FTP passzív mód a `wininet.dll` API-n keresztül. Elsődleges a békéscsabai szerver (`185.43.207.99:21100`), másodlagos fallback a pécsi szerver (`port 21`). |
| 5 | Az I (Nagybani) oszlop képzése/szerepe | Adatmodell és kalkuláció | **LEZÁRVA**: Az I oszlop a nagy értékű (nagybani) ügyletek elszámoló alapja, a 0-s lapon kézzel megadott érték, a csoportlapokon nem képez közvetlen sávot. |
| 6 | Az INTERNET oszlop forrás-feliratok (Feco, Realtime FX, BRN RON stb.) automatizált lekérése-e | Adatforrás integráció | **LEZÁRVA**: Csak leíró címkék és külső URL referenciák a kézi beírás támogatására, nincs automatikus háttér-lehívás integrálva a kliensben. |
| 7 | A checklista "ELLENŐRZI A PROGRAM" pipa pontos validáció-tartalma csoportonként | Kiküldés-előtti validáció | **LEZÁRVA**: A pipával jelölt csoportokat a `Form1.Vegcontrol` metódus kötelezően ellenörzi szétküldés előtt: vétel <= elszámoló és eladás >= elszámoló szabályok mentén. Ha bármely aktív csoportban hiba van, a szétküldés blokkolva van. |
| 8 | A kedvezményhatár-küszöbök (50.000/300.000/1.000.000) globálisak vagy csoportonként eltérők | Sáv-besorolás | **LEZÁRVA**: Csoportonként teljesen egyedileg konfigurálható határok, amelyek az `ARFDATA.DAT` fájlban csoportonként 6 bájton tárolódnak. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelményhez (FR-RFMUI) tartozik forrás-hivatkozás a screenshotok alapján.
- [x] 0 hallucináció (csak a képeken látható elrendezések és szövegek szerepelnek).
- [x] Minden TBD pont pontosan átvéve és katalogizálva.
</verification_checklist>
