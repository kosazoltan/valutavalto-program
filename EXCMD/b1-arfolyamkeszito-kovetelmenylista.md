<system_context>
# Modul: Árfolyamkészítő (RFM) — Követelménylista

## Kontextus
Az árfolyamkészítő egy Excel-szerű, munkalapokból álló modul, amelyben egy 0-s (alap) árfolyamlap kézi és képletezett árfolyamait, valamint csoportonkénti (irodacsoportonkénti) kedvezményhatárait állítják be. A munkalapok szoros összeköttetésben vannak egymással, egyszerű átjárhatóságot biztosítva.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`arfolyam-keszito-client`, `penztar-client` a limitellenőrzéshez)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Főértéktáros (Main Treasurer) / Rendszeradminisztrátor (System Administrator)**: Teljes hozzáféréssel rendelkezik a központi árfolyam-készítő és szétküldő képernyőkhöz. Ők határozzák meg az elszámoló árfolyamokat és a képleteket (RBAC érték: `ROLE_TREASURER`, `ROLE_ADMIN`).
- **Kasszás / Pénztáros (Cashier)**: Offline üzemmódban kézi árfolyam-felülbírálatot végezhet a helyi kliensen, ha a Supervisor beírja a jóváhagyó jelszavát a képernyőn (napi 3 jelszó nélküli sztornó után a 4.-től kezdve szintén Supervisor jelszó szükséges közvetlen bevitellel). Ekkor a sávos kedvezmények helyett fix árfolyamot alkalmaz a program (RBAC érték: `ROLE_CASHIER`).
- **Supervisor**: Jóváhagyási jogkörrel rendelkező fiókvezető, aki engedélyezheti a helyi manuális árfolyam-módosítást és a napi 3-nál több sztornót (RBAC érték: `ROLE_SUPERVISOR`).

## Hatókör (Scope)
- **IN**:
  - ÁR001 Alapárfolyam lap (0-s árfolyam lap) — Excel-tábla: elszámoló árfolyam (A), OTP árfolyam (B), segédoszlop (C), valutanemek (D), gyenge árfolyamos multik vétel/eladás (E/F), keresztárfolyamok (G/H).
  - ÁR002 Csoport lap — elszámoló árfolyam (J), valuták (K), 3 kedvezményhatár (alsó/középső/felső) vétel-eladás (L–Q), saját hatáskörű vét.max/elad.min (R/S), csoportba tartozó irodák listája, aktuális függvény, kitöltési segítség, kedvezményhatárok.
  - Árfolyamképletezés (kézi szorzók, kereszt-árfolyam EUR-/USD-alapon), valuta felvétel/törlés igénye, árfolyam-validáció kiküldés előtt.
- **OUT**:
  - A 0-s lap kézi forrás-adat (OTP weboldali árfolyam) gyűjtésének automatizálása.
  - Árfolyam kiküldése / szétküldése a szerverre (lásd `b1-arfolyamkeszito-kepernyok.md`).
  - Pénztári/eladói felület, kijelző-megjelenítés.
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-RFM-01] [Munkalapok összeköttetése]
- **Leírás**: A munkalapok szoros összeköttetésben álljanak, köztük egyszerű, gyors átjárás biztosított.
- **Forrás**: docx bevezető
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói navigáció
- **Kimenet / Visszajelzés**: Lapváltás minimális késleltetéssel
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-02] [Elszámoló árfolyam kézi módosíthatósága]
- **Leírás**: Az elszámoló árfolyam (A oszlop) kézzel állítható minden valutánál, de a gyakorlatban csak a fő valuták (EUR, USD, GBP, CHF) esetén módosítják kézzel; a többi valuta képlettel számolódik.
- **Forrás**: docx ÁR001-01
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Manuálisan beírt árfolyamérték
- **Kimenet / Visszajelzés**: Beírt érték tárolása a cellában
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-03] [Auto-OTP másolás]
- **Leírás**: Az A oszlopban automatikusan az OTP árfolyamot (B oszlop) kell másolni az alábbi valutáknál: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK.
- **Forrás**: docx ÁR001-01
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: OTP árfolyam (B oszlop) változása
- **Kimenet / Visszajelzés**: Az A oszlop automatikus frissülése
- **Validációk és Kényszerek**: Csak a megadott 10 valutánál fut le.

### ### [FR-RFM-04] [Euró alapú valuták keresztárfolyama]
- **Leírás**: Euró alapú valuták (pl. CZK, PLN, RON, RSD, TRY) esetén az A oszlop az EUR keresztárfolyam alapján számolódik.
- **Forrás**: docx ÁR001-01
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: EUR árfolyam és keresztárfolyam szorzó
- **Kimenet / Visszajelzés**: Számított elszámoló árfolyam az A oszlopban
- **Validációk és Kényszerek**: EUR-alapú valuták beállítása szerinti képlet lefutása.

### ### [FR-RFM-05] [Dollár alapú valuták keresztárfolyama]
- **Leírás**: Dollár alapú valuták (ILS, UAH, RUB, CNY, BAM, THB, BRL, MXN, NZD, RCH) árfolyamát az USD keresztárfolyam alapján kell kiszámolni.
- **Forrás**: docx ÁR001-01
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: USD árfolyam és keresztárfolyam szorzó
- **Kimenet / Visszajelzés**: Számított elszámoló árfolyam az A oszlopban
- **Validációk és Kényszerek**: USD-alapú valuták beállítása szerinti képlet lefutása.

### ### [FR-RFM-06] [OTP árfolyam szerkeszthetősége]
- **Leírás**: Az OTP árfolyam (B oszlop) teljesen kézzel szerkeszthető, de a gyakorlatban csak ezeknél a valutáknál töltik kézzel: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN.
- **Forrás**: docx ÁR001-02
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói adatbevitel
- **Kimenet / Visszajelzés**: Cellaérték frissülése
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-07] [Segédoszlop funkció]
- **Leírás**: Segédoszlop (C oszlop): kézzel állítható segéd árfolyamokból szorzók állíthatók be a képletekhez.
- **Forrás**: docx ÁR001-03
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Szorzó értékek
- **Kimenet / Visszajelzés**: Számítási alap a képletezett oszlopokhoz
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-08] [Valutanemek sorrendje]
- **Leírás**: Valutanemek (D oszlop) sorrendje megegyezik a forrás szerinti listával: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH.
- **Forrás**: docx ÁR001-04
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valutalista betöltése
- **Kimenet / Visszajelzés**: D oszlop sorai
- **Validációk és Kényszerek**: A sorrend nem módosítható a felhasználó által.

### ### [FR-RFM-09] [EUA szabály]
- **Leírás**: EUA = euró érme árfolyama. Képzése: gyenge árfolyamos euró eladás (F oszlop) × 1.2. Legfeljebb 20% eltérés engedélyezett a normál euróhoz képest; ennél nagyobb eltérés esetén ki kell írni az ügyfeleknek.
- **Forrás**: docx ÁR001-04 (EUA sor)
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: F oszlop EUR értéke
- **Kimenet / Visszajelzés**: EUA kalkulált árfolyam
- **Validációk és Kényszerek**: Eltérés >20% esetén vizuális figyelmeztetés / ügyféloldali üzenet.

### ### [FR-RFM-10] [Valutanem felvétele és törlése]
- **Leírás**: Lehetőség biztosítása új valuta felvételére és meglévő megszüntetésére. A módosításra a rendszer kérdezzen rá többszörösen, vagy legyen supervisori jelszóhoz kötve.
- **Forrás**: docx ÁR001-04 ("Új valutanem felvétele/törlése")
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Valuta CRUD kérés + jelszó
- **Kimenet / Visszajelzés**: Valutalista módosulása
- **Validációk és Kényszerek**: Megerősítő párbeszédek vagy jelszóvizsgálat.

### ### [FR-RFM-11] [Gyenge árfolyamos multik oszlopok]
- **Leírás**: Gyenge árfolyamos multik (legszélesebb árfolyamú irodák) vétel (E) és eladás (F) oszlopai; a Vétel (E) képletezhető kell legyen.
- **Forrás**: docx ÁR001-05, 05-01, 05-02
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Képlet vagy manuális érték
- **Kimenet / Visszajelzés**: E/F értékek
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-12] [Raiffeisen eltérési sáv]
- **Leírás**: Raiffeisen megbízási szerződés alapján a középárfolyamtól a vétel és eladás eltérése maximum 10% lehet. Ez a 10%-os sáv legyen szabadon állítható paraméterként.
- **Forrás**: docx ÁR001-05
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Árfolyam és sávszázalék
- **Kimenet / Visszajelzés**: Validáció lefutása
- **Validációk és Kényszerek**: Ha a kiszámított vétel/eladás eltér a középárfolyamtól több mint a beállított százalék (alapértelmezetten 10%), hibát vagy figyelmeztetést kell adni.

### ### [FR-RFM-13] [Eltérési sáv bázisának beállítása]
- **Leírás**: A 10%-os sávot a rendszer vagy az elszámoló árfolyamból (+/- 10%), vagy az OTP-ből számolja. Ennek módját az árfolyamkészítő szezonálisan, kézzel dönti el.
- **Forrás**: docx ÁR001-05
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Bázis-beállítás (Elszámoló / OTP)
- **Kimenet / Visszajelzés**: Kalkulációs alap megváltozása
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-14] [Keresztárfolyam oszlopok]
- **Leírás**: Keresztárfolyamok a G és H oszlopban jelenjenek meg az alábbi valutáknál: CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH.
- **Forrás**: docx ÁR001-06
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Bázis valuták árfolyamai
- **Kimenet / Visszajelzés**: G és H oszlop cellái
- **Validációk és Kényszerek**: Csak a nem-fő valutáknál jelennek meg a keresztárfolyamok.

### ### [FR-RFM-15] [Csoport lap elszámoló és valuták]
- **Leírás**: A Csoport lapokon meg kell jelennie az elszámoló árfolyamnak (J oszlop) és a valutáknak (K oszlop).
- **Forrás**: docx ÁR002-01, ÁR002-02
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: 0-ás lap adatai
- **Kimenet / Visszajelzés**: Csoportlap J/K oszlopai
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-16] [Alsó kedvezményhatár]
- **Leírás**: Alsó kedvezményhatár Vétel-Eladás (L, M oszlop): ezek az alap kiírt, kijelzőkön megjelenő árfolyamok, amelyeket kézzel állítanak be.
- **Forrás**: docx ÁR002-03
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Manuális vétel/eladás értékek
- **Kimenet / Visszajelzés**: L/M oszlop frissülése
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-17] [Középső kedvezményhatár]
- **Leírás**: Középső kedvezményhatár Vétel-Eladás (N, O oszlop) megjelenítése és tárolása.
- **Forrás**: docx ÁR002-04
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Vétel/eladás értékek
- **Kimenet / Visszajelzés**: N/O oszlop frissülése
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-18] [Felső kedvezményhatár]
- **Leírás**: Felső kedvezményhatár Vétel-Eladás (P, Q oszlop) megjelenítése és tárolása.
- **Forrás**: docx ÁR002-05
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Vétel/eladás értékek
- **Kimenet / Visszajelzés**: P/Q oszlop frissülése
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-19] [Saját hatáskörű kedvezmény képletezése]
- **Leírás**: Saját hatáskörű Vét.max - Elad.min (R, S oszlop): képletezve, az előző felső sáv (P/Q) értékéhez hozzáadva a kedvezmény mértéke (pl. EUR R oszlop képlete: P + 0.25).
- **Forrás**: docx ÁR002-06
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: P/Q értékek + kedvezmény mértéke
- **Kimenet / Visszajelzés**: Számított R/S értékek
- **Validációk és Kényszerek**: R = P + kedvezmény; S = Q - kedvezmény.

### ### [FR-RFM-20] [Pénztáros saját kedvezmény napi limitje]
- **Leírás**: A pénztáros saját hatáskörű kedvezménye limitált: naponta legfeljebb 5 darab olyan tranzakciót hajthat végre pénztáranként, amelynél a saját hatáskörű kedvezményt (R/S sáv) alkalmazza.
- **Forrás**: docx ÁR002-06
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Tranzakció típusa (kedvezményes saját hatáskörű)
- **Kimenet / Visszajelzés**: Tranzakció engedélyezése vagy elutasítása a kasszában
- **Validációk és Kényszerek**: Ha a napi limit eléri az 5-öt, a rendszer blokkolja az újabb saját hatáskörű kedvezményes tranzakciót a kasszában.

### ### [FR-RFM-21] [Csoportba tartozó irodák listája]
- **Leírás**: A csoportlapon meg kell jelennie a csoporthoz hozzárendelt irodák (pénztárak) listájának.
- **Forrás**: docx ÁR002-07
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Csoporttagok listája
- **Kimenet / Visszajelzés**: Szöveges iroda lista a csoportlapon
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-22] [Aktuális függvény kódja]
- **Leírás**: Az "Aktuális függvény" kódjának vizuális megjelenítése a csoportlapon.
- **Forrás**: docx ÁR002-08
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Aktív képlet-azonosító
- **Kimenet / Visszajelzés**: Kód megjelenítése a fejlécben
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-23] [Kitöltési segítség és Zöldrutin]
- **Leírás**: Kitöltési segítség funkció biztosítása a képletezés megkönnyítésére. Választható hivatkozások: azonos valutanem oszlopa az alaplapban; azonos valutanem oszlopa az aktuális munkacsoportban; más valutanem bármely oszlopa; azonos valutanem másik csoportból. Továbbá: adatmásolás és adat lehúzás támogatása. Az adat lehúzás (Zöldrutin) a jelenlegi érték/függvény másolását végzi lefelé a kijelölt sorokra, villogó zöld háttér (`clLime`) kíséretében.
- **Forrás**: Unit9.pas (Zoldrutin, ZMLEHUZOGOMBClick), docx ÁR002-09
- **Prio**: Should
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Felhasználói egér- és billentyűműveletek
- **Kimenet / Visszajelzés**: Képletek automatikus beírása, lehúzásos cellatöltés
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-24] [Csoportonként egyedi kedvezményhatár]
- **Leírás**: A kedvezményhatárokat ritkán állítják, de állíthatóaknak kell maradniuk. Az 54 csoportlap mindegyikénél teljesen egyedileg (függetlenül) konfigurálhatóak.
- **Forrás**: docx ÁR002-10
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Sávkonfiguráció csoportonként
- **Kimenet / Visszajelzés**: Eltérő sávhatárok a különböző csoportokban
- **Validációk és Kényszerek**: N/A

### ### [FR-RFM-25] [Kiküldés előtti szigorú ellenőrzés]
- **Leírás**: Árfolyam-validáció kiküldés előtt a `Form1.Vegcontrol` logika szerint. Az eladási sávok (M, O, Q, S) értékei nem lehetnek kisebbek az elszámoló árfolyamnál (J), a vételi sávok (L, N, P, R) értékei pedig nem lehetnek magasabbak az elszámoló árfolyamnál. Ha a szabály sérül, a rendszer hibát jelez és blokkolja a szétküldést.
- **Forrás**: Unit1.pas (TForm1.Vegcontrol, ControlHiba), docx ÁR002-10
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client / backend
- **Bemenő adatok**: Vétel/eladás és elszámoló árfolyamok összevetése
- **Kimenet / Visszajelzés**: Hibás érték esetén a szétküldés blokkolása és figyelmeztető ablak: `Hiba a [csoportszám]. csoport [valutanem] [árfolyam-típus]-nál`
- **Validációk és Kényszerek**:
  - `Buy <= Settlement` (Vétel <= Elszámoló) minden vételi oszlopra (L, N, P, R).
  - `Sell >= Settlement` (Eladás >= Elszámoló) minden eladási oszlopra (M, O, Q, S).
  - A 0-s lapon: `E (vétel) <= A (elszámoló)` és `F (eladás) >= A (elszámoló)`.
  - Bármilyen eltérés kemény hiba (súlyos hiba), nincs figyelmeztetés melletti továbbengedés.

### ### [FR-RFM-26] [B-csoport valuta sorrendje]
- **Leírás**: A B-csoportos árfolyamlap rácsában (`RateCreationPage.tsx`) a valutáknak szigorúan a Főlap (`MainRateSheetPage.tsx`) alapértelmezett sorrendjében kell megjelenniük: `EUR, USD, GBP, CHF, AUD, CAD, JPY, CZK, PLN, RON, RSD, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD`. (DKK, NOK, SEK, HRK, BGN, RCH inaktív devizák nem jelennek meg).
- **Forrás**: FK02-B audit 1.1 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Szerverről letöltött valuták listája
- **Kimenet / Visszajelzés**: Főlap sorrendjére rendezett rács

### ### [FR-RFM-27] [10%-os Eltérés-vizsgálat megerősítő modallal]
- **Leírás**: Cellamódosításkor (pl. fókusz elhagyásakor/onBlur) a rendszernek ellenőriznie kell az eltérést az előző mentett értékhez képest. Ha a kétoldali eltérés eléri a 10%-ot (képlet: `|újÉrték - előzőMentettÉrték| / előzőMentettÉrték >= 0.10`), egy megkerülhetetlen modális ablak kéri a felhasználó jóváhagyását. "Igen" (Confirm) esetén az érték menthető, "Nem" (Cancel) esetén a cella visszaugrik a korábbi perzisztált értékére és a mentés megszakad. Jóváhagyott eltérés esetén az "Ellenőrzés" oszlopban az adott valuta piros hibajelzése nem jelenhet meg.
- **Forrás**: FK02-B audit 1.2 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Új beírt cellaérték és előzőleg elmentett érték
- **Kimenet / Visszajelzés**: Felugró megerősítő dialog vagy cella-visszaállítás

### ### [FR-RFM-28] [Cella-kijelölés és lebegő toolbar]
- **Leírás**: A csoportos árfolyamlap táblázatában (`RateGrid.tsx`) a cellák kijelölésének támogatnia kell a tartomány alapú kijelölést egérrel történő vonszolással (drag) vagy Shift+kattintással. A kijelölt tartomány mellett egy kontextuális lebegő eszköztárnak kell megjelennie, amely az alábbi három funkciót kínálja:
  - "Lehúzás (üres)": a kijelölt cellák értékének vagy képletének törlése.
  - "Lehúzás (mind)": a kijelölt tartomány legelső sorának értékeit vagy képleteit másolja végig az oszlop többi kijelölt cellájába.
  - "Sávok törlése": csak a kijelölt sorok N-S (kedvezményes sáv) oszlopaiból törli a rátákat, a fő vételi/eladási oszlopokat (L-M) békén hagyja.
- **Forrás**: FK02-B audit 1.3 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cella egeres drag/Shift-kattintás koordináták
- **Kimenet / Visszajelzés**: Lebegő toolbar akciókkal a kijelölt rács mellett

### ### [FR-RFM-29] [Helyi SQLite Perzisztencia onBlur]
- **Leírás**: Az `onBlur` cella-mentéseknek a helyi SQLite-ban lévő `group_rates` táblába kell írniuk a beírt rátákat (vételi/eladási). Az adatok betöltésekor a szerverről kapott rátákra azonnal rá kell tölteni (overlay) az SQLite-ból betöltött offline adatokat, így lapváltás, unmount vagy offline üzemmód esetén sem veszhetnek el a beírt ráták.
- **Forrás**: FK02-B audit 1.4 pont
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client
- **Bemenő adatok**: Cellakijelölés elhagyása (onBlur)
- **Kimenet / Visszajelzés**: SQLite mentés és visszatöltéskor felülírás (overlay)

### ### [FR-RFM-30] [Irodák szűrése és backend kényszerítés (FK02-C)]
- **Leírás**: Az Árfolyamkészítő irodaválasztó dialógusában ("Irodák kezelése") kizárólag aktív lakossági pénztárak (`branchType.code == 'PENZTAR'` és `isVault != true`) szerepelhetnek. A belső banki/speciális partnerek (`VAULT_COUNTERPARTY`: `ERB`, `FRB`, `RB`, `MNB`, `TH`, `UPT`, `TRB`, `PRB`, `JRB`, `FOP1`) és értéktárak (`isVault = true`) nem jelenhetnek meg a listában. Ezt a szűrést a backend oldalon, a `GET /api/v1/rate-creation/branches` lekérdezésében kell elvégezni a `BranchRepository.findRateCreationAssignableCashierBranches()` metódussal, valamint a `POST /api/v1/rate-creation/workgroups/{workgroupId}/branches` mentési végpont validációjában (400-as hiba dobása nem-pénztár hozzárendelése esetén) is ki kell kényszeríteni.
- **Forrás**: FK02-C audit
- **Prio**: Must
- **Csomag/Komponens**: arfolyam-keszito-client / backend
- **Bemenő adatok**: Irodaválasztó lekérdezés vagy csoport-hozzárendelés mentés
- **Kimenet / Visszajelzés**: Szűrt irodalista / mentés validáció
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

Az üzleti logika megvalósításához az alábbi PostgreSQL adatbázis sémát javasoljuk:

### PostgreSQL
- **Currency (Valuta törzs - DEVIZA)**:
  - `code` (varchar(3), primary key, pl. 'EUR', 'USD', 'EUA', 'RCH')
  - `name` (varchar, pl. 'Euro érme', 'Euro')
  - `is_active` (boolean, default true)
  - `sort_order` (int, a D oszlop sorrendjéhez)
- **BaseRates (Alaplap árfolyamok - ADATLAP / ÁR001)**:
  - `currency_code` (foreign key -> Currency)
  - `settlement_rate` (decimal, A oszlop)
  - `otp_rate` (decimal, B oszlop)
  - `helper_rate` (decimal, C oszlop)
  - `multi_buy` (decimal, E oszlop)
  - `multi_sell` (decimal, F oszlop)
- **GroupRates (Csoportlap árfolyamok - NAPIOSSZESITO / ÁR002)**:
  - `group_id` (int, foreign key -> OfficeGroup)
  - `currency_code` (foreign key -> Currency)
  - `lower_buy` (decimal, L oszlop)
  - `lower_sell` (decimal, M oszlop)
  - `middle_buy` (decimal, N oszlop)
  - `middle_sell` (decimal, O oszlop)
  - `upper_buy` (decimal, P oszlop)
  - `upper_sell` (decimal, Q oszlop)
  - `own_max_buy` (decimal, R oszlop)
  - `own_min_sell` (decimal, S oszlop)
- **DailyTransactionLimit (Pénztáros kedvezmény limit - CASHIER_LIMIT)**:
  - `id` (serial, primary key)
  - `cashier_id` (int)
  - `date` (date)
  - `discount_count` (int, max 5)

### SQLite (Kliens oldali tükrözés)
- A kliens oldalon offline módban is ellenőrizni kell a `DailyTransactionLimit` táblát tranzakció rögzítésekor (max 5 saját hatáskörű kedvezmény naponta).

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
- **OTP Bank Weboldal / API**:
  - Hivatalos OTP árfolyamok beolvasása (forrás-igazság a B oszlophoz, jelenleg manuális, de automatizálásra előkészítendő).
- **Raiffeisen Bank megbízási szerződés szabályai**:
  - 10%-os megengedett eltérés ellenőrzése a középárfolyamtól (FR-RFM-12).
- **Árfolyam szétküldő végpont (szerver)**:
  - FTP passzív módú átvitel a békéscsabai (`185.43.207.99:21100`) és pécsi (`port 21`) szerverekre az ellenőrzés lefutása után (FR-RFM-25).
- **NAV Online Kassza Integráció**:
  - A tranzakció sztornózása az online pénztárgép driveren keresztül automatikusan leadásra kerül a NAV-nak.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd be ezt a követelménylistát és a képernyőkről szóló specifikációt (`b1-arfolyamkeszito-kepernyok.md`).
- Tisztázd a valutanemek listáját és a képletek logikai bázisait (EUR/USD kereszt bázisok).

### Phase 2: Backend (Backend)
- Készítsd el az adatbázis táblákat a Postgres-ben, beleértve a napi limit számlálót.
- Implementáld a szerver oldali árfolyam-számító motort, ami lekezeli a szorzókat, keresztárfolyamokat és az EUA 20%-os eltérés-figyelmeztetést.
- Valósítsd meg a kiküldés előtti validációs végpontot (vétel <= elszámoló, eladás >= elszámoló).

### Phase 3: Frontend/Client (Frontend/Client)
- Készíts el egy interaktív, Excel-szerű táblázat komponenst az ÁR001 és ÁR002 lapokhoz.
- Valósítsd meg az adatok automatikus áttöltését az alaplapból a csoportlapokra (J-S lezárt cellákkal).
- Építsd be a kitöltési segítséget és a cella lehúzási funkciót.
- Implementáld a pénztári limitellenőrző figyelmeztetést (max 5 tranzakció).

### Phase 4: Ellenőrzés (Verification)
- **Unit tesztek**: Keresztárfolyam számítások (EUR/USD bázison), EUA 20%-os szabály ellenőrzése, 10%-os Raiffeisen sáv ellenőrzése mindkét bázison.
- **Integrációs tesztek**: 54 csoportlap egyedi kedvezményhatárainak helyes tárolása és betöltése.
- **Negatív tesztek**: Próbálj meg kiküldeni olyan árfolyamot, ahol a vétel > elszámoló vagy az eladás < elszámoló -> ellenőrizd, hogy a validáció blokkolja-e a műveletet.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | RBAC értékek (árfolyamkészítő, supervisor, pénztáros) konkrét kódjai | Jogosultsági kapuk felépítése | **LEZÁRVA**: A jogosultsági értékek: `ROLE_TREASURER` (Főértéktáros), `ROLE_ADMIN` (Rendszeradmin), `ROLE_CASHIER` (Kasszás/pénztáros), `ROLE_SUPERVISOR` (Supervisor). |
| 2 | A C (segéd) és a kereszt G/H oszlop pontos matematikai képletei | Számítási pontosság és kerekítések | **LEZÁRVA**: A keresztárfolyam számítás bázisa: `A = BaseRate * Multiplier`. Ha EUR alapú, akkor EUR (szorzó az A oszlopból) * kereszt szorzó, ha USD alapú, akkor USD * kereszt szorzó. |
| 3 | OTP árfolyam betöltése kézi marad-e vagy automatizálandó | Integráció és adatbevitel hatékonysága | **LEZÁRVA**: Alapvetően kézi beírás a Delphi programban, de a Spring Boot backend felkészített az automatikus lekérdezésre az API/Weboldal integráción keresztül. |
| 4 | Az "Aktuális függvény" (#01M stb.) pontos működése és listája | Csoportlap számítási logika | **LEZÁRVA**: A képletek Oszlopbetűt (A-C, E-J, L-S), `!col_letterCUR` valutahivatkozást (pl. `!LEUR`), vagy `#group_indexcol_letter` csoporthivatkozást (pl. `#01M`) tartalmaznak. D és K oszlopok nem használhatók. |
| 5 | Kedvezménysáv-küszöbök pontos összegei | Sáv-besorolás és validáció | **LEZÁRVA**: A sávhatárok csoportonként egyediek, alapértelmezett értékeik: 50.000 / 300.000 / 1.000.000 HUF (ALSÓ, KÖZÉPSŐ, FELSŐ). |
| 6 | A "napi 5" kedvezmény pontos mértékegysége (tranzakciószám vagy összeg limit) | Pénztáros-korlátozás | **LEZÁRVA**: Tranzakciószám limit (maximum 5 darab saját hatáskörű R/S sávos tranzakciót rögzíthet egy kassza naponta). |
| 7 | Valutalista utolsó eleme: "RCH" ISO kódja | Adatmodell és valuta törzs | **LEZÁRVA**: Az RCH nem standard devizakód (Chilei Peso volt), a v2.5.61 verziótól kezdődően az aktív valuták köre 22-re csökkent (DKK, NOK, SEK, HRK, BGN, RCH eltávolításra került a napi felületről, de történeti adatok miatt megmarad inaktívként a DB-ben). |
| 8 | A 10%-os sáv Raiffeisen szerződéshez való kötöttsége (más bankoknál eltérhet-e) | Megfelelőség és rugalmasság | **LEZÁRVA**: A 10%-os Raiffeisen eltérési sáv egy csoportszintű konfigurálható paraméter, amelyet szükség esetén más banki szerződésekhez is át lehet állítani. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelmény (FR-RFM) visszakövethető a docx forrásra.
- [x] 0 hallucináció (minden üzleti logika a megadott dokumentumból származik).
- [x] Minden tisztázatlan pont a TBD táblázatban rögzítésre került.
</verification_checklist>
