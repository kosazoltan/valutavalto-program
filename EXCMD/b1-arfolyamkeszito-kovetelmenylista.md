# Modul: Árfolyamkészítő (RFM) — Követelménylista  (forrás: `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Árfolyamkészítő programról/Követelménylista - Árfolyamkészítés.docx`)

## 1. Cel (egy mondat)
Az árfolyamkészítő egy Excel-szerű, munkalapokból álló modul, amelyben egy 0-s (alap) árfolyamlap kézi és képletezett árfolyamait, valamint csoportonkénti (irodacsoportonkénti) kedvezményhatárait állítják be, a munkalapok szoros összeköttetésben, egymás közti egyszerű átjárással.

## 2. Scope
### IN
- ÁR001 Alapárfolyam lap (0-s árfolyam lap) — Excel-tábla: elszámoló árfolyam (A), OTP árfolyam (B), segédoszlop (C), valutanemek (D), gyenge árfolyamos multik vétel/eladás (E/F), keresztárfolyamok (G/H).
- ÁR002 Csoport lap — elszámoló árfolyam (J), valuták (K), 3 kedvezményhatár (alsó/középső/felső) vétel-eladás (L–Q), saját hatáskörű vét.max/elad.min (R/S), csoportba tartozó irodák listája, aktuális függvény, kitöltési segítség, kedvezményhatárok.
- Árfolyamképletezés (kézi szorzók, kereszt-árfolyam EUR-/USD-alapon), valuta felvétel/törlés igénye, árfolyam-validáció kiküldés előtt.

### OUT
- A 0-s lap kézi forrás-adat (OTP weboldali árfolyam) gyűjtésének automatizálása — a forrás szerint kézi beírás (TBD: automatizálás).
- Árfolyam kiküldése / szétküldése a szerverre (külön képernyő-forrás írja le, lásd `b1-arfolyamkeszito-kepernyok.md`).
- Pénztári/eladói felület, kijelző-megjelenítés (a forrás csak hivatkozik rá: "kijelzőkön megjelennek").

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Árfolyamkészítő (forrás: "Tamás" dönti el a metódust) | 0-s lap és csoportlap szerkesztése, képletezés, kiküldés | TBD |
| Pénztáros | Saját hatáskörű kedvezmény napi limittel (forrás: "csak napi 5-t adhat") | TBD |
| Supervisor | Új valuta felvétele/törlése supervisori jelszóhoz köthető (forrás-javaslat) | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-RFM-01 | A munkalapok szoros összeköttetésben álljanak, köztük egyszerű átjárás | docx bevezető | Must | arfolyam-keszito-client |
| FR-RFM-02 | Elszámoló árfolyam (A oszlop) kézzel állítható minden valutánál, de gyakorlatban csak a fő valuták (EUR, USD, GBP, CHF) esetén állítják kézzel; a többi képlettel számolt | docx ÁR001-01 | Must | arfolyam-keszito-client |
| FR-RFM-03 | A oszlopban automatikusan az OTP árfolyamot másolják ezek a valuták: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK | docx ÁR001-01 | Must | arfolyam-keszito-client |
| FR-RFM-04 | Euró alapú valuták (pl. CZK, PLN, RON, RSD, TRY) esetén az A oszlop az EUR keresztárfolyam alapján számol | docx ÁR001-01 | Must | arfolyam-keszito-client |
| FR-RFM-05 | Dollár alapú valuták (ILS, UAH, RUB, CNY, BAM, THB, BRL, MXN, NZD, RCH) árfolyamát az USD keresztárfolyam alapján számolja | docx ÁR001-01 | Must | arfolyam-keszito-client |
| FR-RFM-06 | OTP árfolyam (B oszlop) teljesen kézzel szerkeszthető; kézzel csak ezeknél: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN | docx ÁR001-02 | Must | arfolyam-keszito-client |
| FR-RFM-07 | Segédoszlop (C oszlop): kézzel állítható segéd árfolyamokból szorzók beállíthatók | docx ÁR001-03 | Should | arfolyam-keszito-client |
| FR-RFM-08 | Valutanemek (D oszlop) sorrendje a forrás szerint: EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH | docx ÁR001-04 | Must | arfolyam-keszito-client |
| FR-RFM-09 | EUA = euró érme árfolyama; max 20% eltérés engedett, ennél nagyobb eltérésnél ki kell írni az ügyfeleknek; képzés: gyenge árfolyamos euró eladás × 1.2 | docx ÁR001-04 (EUA sor) | Must | arfolyam-keszito-client |
| FR-RFM-10 | Új valutanem felvétele/törlése: legyen lehetőség új valuta felvételére és meglévő megszüntetésére; a módosításra rákérdezzen (akár többször) vagy supervisori jelszóhoz kötve | docx ÁR001-04 ("Új valutanem felvétele/törlése") | Should | arfolyam-keszito-client |
| FR-RFM-11 | Gyenge árfolyamos multik (legszélesebb árfolyamú irodák): Vétel (E oszlop), Eladás (F oszlop); a Vétel (E) képletezhető legyen | docx ÁR001-05, 05-01, 05-02 | Must | arfolyam-keszito-client |
| FR-RFM-12 | Raiffeisen megbízási szerződés alapján középárfolyamtól a vétel és eladás eltérése max 10%; a 10% legyen szabadon állítható | docx ÁR001-05 | Must | arfolyam-keszito-client |
| FR-RFM-13 | A 10%-os sávot vagy az elszámolóból (+/- 10%), vagy az OTP-ből számolja; a módot az árfolyamkészítő ("Tamás") szezonálisan dönti el, nincs állandó metódus | docx ÁR001-05 | Should | arfolyam-keszito-client |
| FR-RFM-14 | Keresztárfolyamok a G és H oszlopban jelenjenek meg ezeknél: CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH | docx ÁR001-06 | Must | arfolyam-keszito-client |
| FR-RFM-15 | Csoport lap: elszámoló árfolyam (J oszlop), valuták (K oszlop) | docx ÁR002-01, ÁR002-02 | Must | arfolyam-keszito-client |
| FR-RFM-16 | Alsó kedvezményhatár Vétel-Eladás (L, M oszlop): az alap kiírt, kijelzőkön megjelenő árfolyamok, kézzel állítva | docx ÁR002-03 | Must | arfolyam-keszito-client |
| FR-RFM-17 | Középső kedvezményhatár Vétel-Eladás (N, O oszlop) | docx ÁR002-04 | Must | arfolyam-keszito-client |
| FR-RFM-18 | Felső kedvezményhatár Vétel-Eladás (P, Q oszlop) | docx ÁR002-05 | Must | arfolyam-keszito-client |
| FR-RFM-19 | Saját hatáskörű Vét.max - Elad.min (R, S oszlop): képletezve, az előző (P/Q) értékhez hozzáadva a kedvezmény mértéke (pl. EUR R oszlop képlete: P+0,25) | docx ÁR002-06 | Must | arfolyam-keszito-client |
| FR-RFM-20 | A pénztáros saját hatáskörű kedvezménye limitált: napi 5 adható | docx ÁR002-06 | Must | penztar-client / backend |
| FR-RFM-21 | A csoportlapon megjelenjen a csoportba tartozó irodák listája | docx ÁR002-07 | Must | arfolyam-keszito-client |
| FR-RFM-22 | "Aktuális függvény" megjelenítése a csoportlapon | docx ÁR002-08 | Should | arfolyam-keszito-client |
| FR-RFM-23 | Kitöltési segítség (függvények kezelése): azonos valutanem oszlopa az alaplapban; azonos valutanem oszlopa az aktuális munkacsoportban; más valutanem bármely oszlopa; azonos valutanem másik csoportból; adatmásolás; adat lehúzás | docx ÁR002-09 | Should | arfolyam-keszito-client |
| FR-RFM-24 | Kedvezményhatárok: egyszer beállítva, ritkán állítják, de maradjon állítható; az 54 lapon (csoport) mindegyiknél egyedileg állítható | docx ÁR002-10 | Must | arfolyam-keszito-client |
| FR-RFM-25 | Validáció kiküldés előtt: az eladási árfolyam nem lehet kisebb az elszámolónál, a vételi nem lehet magasabb az elszámolónál; ha nem megfelelő, a rendszer figyelmeztetést küld, amikor ki akarja küldeni az árfolyamot | docx ÁR002-10 | Must | arfolyam-keszito-client / backend |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-RFM-01 | Munkalapok közti egyszerű átjárás (UX) | Forrás: "egyszerű átjárás" — konkrét mérőszám TBD |
| NFR-RFM-02 | 54 csoportlap egyedi kedvezményhatár-tárolása | A forrás 54 csoportot említ; mindegyik egyedileg állítható |
| NFR-RFM-03 | Kézi vs. képletezett cellák megkülönböztetése, képletmegoldó motor (Excel-szerű) | TBD a konkrét toleranciák/teljesítmény |

## 6. Adatmodell-erintettseg
- Valuta törzs: a D oszlop 28 valutaneme (EUR…RCH), köztük EUA (euró érme). Postgres `currency` érintett. SQLite mirror: IGEN (a kliens local-first árfolyam-szerkesztéshez), indok: a forrás Excel-szerű lokális szerkesztést ír le. Migráció szükséges: TBD (a meglévő sémához viszonyítás külön fázis).
- Árfolyam-rekordok oszloponként (A–S): elszámoló, OTP, segéd, multi vétel/eladás, kereszt G/H, csoportonkénti L–S. Konkrét tábla/mező: TBD.
- Csoport (munkacsoport) entitás + csoport-iroda hozzárendelés (54 csoport). Konkrét mező: TBD.
- Kedvezményhatár-paraméterek csoportonként (alsó/középső/felső + sáv-küszöbök). TBD.

## 7. Fuggosegek
- Külső árfolyamforrás: OTP hivatalos weboldal árfolyama (kézi beírás forrása). MNB/bank API: a docx nem említ automatikus lekérést — TBD.
- Belső: alaplap (ÁR001) → csoportlap (ÁR002) képlet-hivatkozások; keresztárfolyam EUR/USD bázison.
- Raiffeisen megbízási szerződés (üzleti szabály forrása a 10%-os sávhoz).
- Árfolyam kiküldése a szerverre (külön képernyő-forrás, lásd kepernyok MD).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| 0-s lap / alapárfolyam lap | ÁR001 alap Excel-tábla, ebből töltődnek a csoportlapok |
| Elszámoló árfolyam | A oszlop; a kalkuláció bázisa, az eladási nem lehet kisebb, a vételi nem magasabb nála |
| OTP árfolyam | B oszlop; kézzel beírt, OTP weboldalról vett irányadó árfolyam |
| Segédoszlop | C oszlop; kézi szorzók képzéséhez |
| Gyenge árfolyamos multik | A legszélesebb árfolyamú irodák vétel (E) / eladás (F) árfolyama |
| Keresztárfolyam | G/H oszlop; nem-fő valuták EUR- vagy USD-bázison számolt árfolyama |
| EUA | Euró érme árfolyama; max 20% eltérés, képzés: gyenge euró eladás × 1.2 |
| Kedvezményhatár | Csoportlap alsó/középső/felső sávja vétel-eladás oldalon |
| Saját hatáskörű vét.max/elad.min | R/S oszlop; pénztáros által adható kedvezmény (napi 5), P/Q + kedvezmény |
| Csoport (munkacsoport) | Irodacsoport, 54 db, egyedi kedvezményhatárokkal |
| Aktuális függvény | A csoportlapon megjelenített aktív képlet-azonosító |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be ezt az MD-t és a `b1-arfolyamkeszito-kepernyok.md`-t. A forrás-igazság a docx + 5 képernyőkép; TILOS a jelenlegi programhoz hasonlítani (külön fázis).
- Tisztázandó TBD-k listája a 10. szekcióból, mielőtt kódolnál.

### 9.2 Fazisok (acceptance criteria-val)
- Fázis 1 — Adatmodell: valuta-törzs (28 valuta + EUA), oszlop-szerkezet (A–S), csoport-entitás (54), kedvezményhatár-paraméterek. AC: a D oszlop 28 valutaneme a forrás sorrendjében jelen.
- Fázis 2 — Alaplap (ÁR001) képletmotor: A oszlop auto-OTP-másolás (FR-03), EUR/USD-kereszt számolás (FR-04, FR-05), B/C kézi (FR-06, FR-07), E képletezhető + 10% sáv (FR-11, FR-12, FR-13), G/H kereszt (FR-14), EUA 20% szabály (FR-09). AC: a felsorolt valuták a megadott szabály szerint töltődnek; EUA >20% eltérésnél figyelmeztet.
- Fázis 3 — Csoportlap (ÁR002): J/K, L–Q három kedvezménysáv, R/S képlet (P+kedvezmény), iroda-lista, aktuális függvény, kitöltési segítség, csoportonként egyedi kedvezményhatár (54). AC: R = P + kedvezmény mértéke (pl. P+0,25).
- Fázis 4 — Validáció + valuta felvétel/törlés: kiküldés előtti ellenőrzés (eladási ≥ elszámoló, vételi ≤ elszámoló) figyelmeztetéssel (FR-25); valuta felvétel/törlés megerősítéssel vagy supervisori jelszóval (FR-10).

### 9.3 Tesztes
- Unit: kereszt-árfolyam számítás (EUR/USD bázis), EUA 20% szabály, R/S képlet (P+0,25), 10% Raiffeisen sáv mindkét forrásmódra (elszámoló vs OTP).
- Integráció: csoportlap a 0-s lapról töltődik (FR-01), 54 csoport egyedi kedvezményhatár.
- Validációs negatív teszt: eladási < elszámoló → figyelmeztetés; vételi > elszámoló → figyelmeztetés.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | RBAC értékek (árfolyamkészítő, supervisor, pénztáros) konkrétan | Jogosultság-kapuk implementálásához | Forrás nem ad RBAC kódot |
| 2 | A C (segéd) és a kereszt G/H oszlop pontos képletei | Számítási helyesség | Forrás csak elvet ad, nem képletet |
| 3 | OTP árfolyam betöltése kézi marad-e vagy automatizálandó | Adatforrás-integráció | Forrás kézi beírást ír; "legjobb lenne automatizálni" csak valutára |
| 4 | Az "Aktuális függvény" (#01M stb.) jelentése és katalógusa | Csoportlap-logika | A képeken #01M, #...M kódok láthatók (lásd kepernyok MD) |
| 5 | Kedvezménysáv-küszöbök (alsó/középső/felső) konkrét összegei | Sáv-besorolás | A docx nem ad összeget; a kép 50.000/300.000/1.000.000 (kepernyok MD) |
| 6 | "napi 5" kedvezmény pontos definíciója (5 tranzakció? 5 fillér?) | Pénztáros-limit | Forrás: "csak napi 5-t adhat" — egység TBD |
| 7 | Valutalista pontos záró eleme: a docx "RCH"-t ír, ennek ISO-kódja/jelentése | Valuta-törzs | Nem standard ISO kód |
| 8 | A 10%-os sáv kötés a Raiffeisen szerződéshez — más bankok eltérnek-e | Compliance | Forrás csak Raiffeisent említ |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak docx-tartalom)
- [x] minden TBD jelölt
VERIFIKACIO: FR=25 db, TBD=8 db, érintett csomag(ok)=arfolyam-keszito-client (fő), penztar-client + backend (FR-20, FR-25)
