# Modul: Árfolyamkészítő (RFM) — Képernyők  (forrás: `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Árfolyamkészítő programról/` 5 db screenshot: `0-s lap, alapárfolyamok.jpg`, `Csoportok karbantartó.jpg`, `Csoport karbantartó 2.jpg`, `Csoport, nem kézzel állítós hanem a 0-s árfolyamlapról töltődik.png`, `Árfolyamok szétküldése log_.jpg`)

## 1. Cel (egy mondat)
A meglévő (Delphi-szerű) árfolyamkészítő program képernyőinek hű leírása: 0-s alapárfolyam-lap, csoport-karbantartó (irodacsoportok kiosztása), egy konkrét csoport árfolyamlapja (a 0-s lapról töltődő), valamint az árfolyamok szétküldése a szerverre (művelet-log).

## 2. Scope
### IN
- Felső menüsor (közös): "CSOPORTOK KARBANTARTÁSA", "ÁRFOLYAMOK SZÉTKÜLDÉSE (A SZERVEREN ÁT)", "INTERNET CÍMEK KARBANTARTÁSA", "KILÉPÉS A PROGRAMBÓL".
- Csoport-karbantartó almenü: "VISSZA AZ ALAPLAPADATOK KARBANTARTÁSÁRA", "ÚJ PÉNZTÁRI/PÉNZTÁR FELVÉTELE MUNKACSOPORTBA", "PÉNZTÁR TÖRLÉSE EGY MUNKACSOPORTBÓL", "MUNKACSOPORT ÁTNEVEZÉSE", "PÉNZTÁR ÁTHELYEZÉSE MÁSIK CSOPORTBA".
- 0-s alapárfolyam-lap teljes oszlopkiosztása (A–I + internet).
- Csoport árfolyamlap oszlopkiosztása (J–S) + csoport-fej panel (csoportszám, csoportnév, irodalista, aktuális függvény, kitöltési segítség, kedvezményhatárok).
- Csoport-karbantartó rács (1–54 számozott iroda-csempék) + jobb oldali "A JELÖLT CSOPORTOKAT ELLENŐRZI A PROGRAM" checklista (1–54).
- Szétküldés művelet-log (sikeres lokális mentés + sikertelen szerverre mentés üzenetek).

### OUT
- A program belső technológiája/forráskódja (csak a UI látszik).
- A pénztáros/eladói felület.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Árfolyamkészítő | Teljes hozzáférés a karbantartó és szétküldő képernyőkhöz | TBD |
| (egyéb szerep a képeken nem azonosítható) | TBD | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-RFMUI-01 | Felső fő menüsor 4 ponttal: Csoportok karbantartása, Árfolyamok szétküldése (a szerveren át), Internet címek karbantartása, Kilépés a programból | img1 (0-s lap), img5 (szétküldés) felső sáv | Must | arfolyam-keszito-client |
| FR-RFMUI-02 | 0-s alapárfolyam-lap táblázat oszlopfejlécei: A=Elszámoló árfolyamok, B=OTP, C=SEGÉD, D=VALUTA NEMEK, E/F=GYENGE ÁRF-OS MULTIK (VÉTEL/ELADÁS), G/H=KERESZT ÁRFOLYAMOK (EUR/USD), I=NAGYBANI, + INTERNET oszlop | img1 fejléc | Must | arfolyam-keszito-client |
| FR-RFMUI-03 | 0-s lap valutasorrend (D oszlop, fentről): EUR, USD, GBP, CHF, AUD, CAD, DKK, JPY, NOK, SEK, CZK, HRK, PLN, RON, RSD, BGN, ILS, UAH, RUB, EUA, TRY, CNY, BAM, THB, BRL, MXN, NZD, RCH | img1 D oszlop | Must | arfolyam-keszito-client |
| FR-RFMUI-04 | 0-s lapon a kézzel állított elszámoló cellák vizuálisan kiemeltek (img1: AUD elszámoló 249.01 piros kerettel; a B/C oszlop egyes cellái zöld háttérrel) | img1 | Should | arfolyam-keszito-client |
| FR-RFMUI-05 | A kereszt-árfolyam oszlopok (G/H) csak a nem-fő valutáknál töltöttek, EUR/USD bázis-feliratokkal; a fő valutáknál (EUR..SEK) a G/H/I érték 0 | img1 G/H/I oszlop | Must | arfolyam-keszito-client |
| FR-RFMUI-06 | Az INTERNET oszlop forrásmegjelölést tartalmaz valutánként (pl. OTP, Feco, EUR/CZK, Realtime FX, BRN RON, Szerb Dínár, BGN, SHEKEL, HRIVNYA, RUBEL, CNY); fent az internet cím: http://www.exchange-rates.org/MajorRates/Byname/R | img1 INTERNET oszlop + fejléc URL | Should | arfolyam-keszito-client |
| FR-RFMUI-07 | Csoport-karbantartó képernyő: 54 számozott iroda-csempe rácsban (1..54), mindegyik iroda nevével (pl. 1 ÁRKÁD, 2 PÉCS FERENCSEK, 16 PAKSÉK, 54 PÉCS RÁKÓCZI) | img2, img3 csempe-rács | Must | arfolyam-keszito-client |
| FR-RFMUI-08 | Csoport-karbantartó jobb oldali panel: "A JELÖLT CSOPORTOKAT ELLENŐRZI A PROGRAM" — 1..54 sorszámozott checklista pipákkal | img2, img3, img5 jobb panel | Must | arfolyam-keszito-client |
| FR-RFMUI-09 | Csoport-karbantartó almenü 5 művelettel: Vissza az alaplapadatok karbantartására, Új pénztár felvétele munkacsoportba, Pénztár törlése egy munkacsoportból, Munkacsoport átnevezése, Pénztár áthelyezése másik csoportba | img2, img5 almenü-sáv | Must | arfolyam-keszito-client |
| FR-RFMUI-10 | A karbantartó képernyő középső sárga panele "MŰVELET = KARBANTARTÁS" felirattal + beviteli mezővel (a kijelölt művelethez) | img2 | Should | arfolyam-keszito-client |
| FR-RFMUI-11 | Üres-csoport állapot jelzése: ha egy csoporthoz nincs iroda rendelve, a panel "NINCS IRODA ITT" üzenetet mutat | img3 középső panel | Should | arfolyam-keszito-client |
| FR-RFMUI-12 | Iroda-csempe státusz-szín: egyes csempék piros háttérrel (pl. img2: 17 BONYHÁD; img5: 36 KAP KORZÓ, 54 PÉCS RÁKÓCZI) — jelentés TBD | img2, img5 csempe-színek | Should | arfolyam-keszito-client |
| FR-RFMUI-13 | Csoport árfolyamlap fejléc: csoportszám + csoportnév (img4: "16 CSOPORT", "PAKSÉK"), "A CSOPORTBA TARTOZÓ IRODÁK" lista (Kalocsa - Tesco / Paks - Tesco) | img4 jobb panel | Must | arfolyam-keszito-client |
| FR-RFMUI-14 | Csoport árfolyamlap oszlopfejlécek: J=Elsz.árf, K=Valuták, L/M=0-50.000 Vétel/Eladás, N/O=50.001-300.000 Vétel/Eladás, P/Q=300.001-1.000.000 Vétel/Eladás, R/S=Saját hatáskörű (Vét.max/Elad.min) | img4 bal táblázat fejléc | Must | arfolyam-keszito-client |
| FR-RFMUI-15 | Csoport árfolyamlap "AKTUÁLIS FÜGGVÉNY" mezője képletkódot mutat (img4: #01M) | img4 | Should | arfolyam-keszito-client |
| FR-RFMUI-16 | Csoport árfolyamlap "KEDVEZMÉNY HATÁROK" panel 3 mezővel: ALSÓ 50.000, KÖZÉPSŐ 300.000, FELSŐ 1.000.000 | img4 jobb-alsó panel | Must | arfolyam-keszito-client |
| FR-RFMUI-17 | Csoport árfolyamlap "KITÖLTÉSI SEGÍTSÉG" feliratú szekció (a kedvezményhatárok felett) | img4 | Should | arfolyam-keszito-client |
| FR-RFMUI-18 | A csoport árfolyamlap a 0-s árfolyamlapról töltődik (NEM kézzel állított) | img4 fájlnév: "Csoport, nem kézzel állítós hanem a 0-s árfolyamlapról töltődik" | Must | arfolyam-keszito-client |
| FR-RFMUI-19 | Árfolyamok szétküldése: a művelet-log lépéssorrendet jelenít meg: ARFDATA.DAT file rögzítése a lokális gépen → árfolyamok mentése a saját gépre → irodák adatainak rögzítése → internet címek rögzítése → alapárfolyamok rögzítése → munkacsoportok rögzítése | img5 log-panel | Must | arfolyam-keszito-client |
| FR-RFMUI-20 | Szétküldés-log sikeres lokális mentés visszajelzése: "A saját gépemre sikeresen lementettem az adatokat" | img5 log-panel | Must | arfolyam-keszito-client |
| FR-RFMUI-21 | Szétküldés-log: biztonsági mentés a békéscsabai szerverre; hiba esetén "A BIZTONSÁGI MENTÉS SIKERTELEN VOLT! A szerverre nem sikerült kitenni az adatokat" üzenet | img5 log-panel | Must | arfolyam-keszito-client / backend |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-RFMUI-01 | 54 csoport-csempe egy képernyőn áttekinthető rácsban + 1..54 ellenőrző checklista | A rács 54 elemet jelenít, a checklista 1..54 |
| NFR-RFMUI-02 | Szétküldés művelet-log lépésenkénti, ember által olvasható visszajelzéssel, sikeres/sikertelen elkülönítve | A log külön jelzi a lokális sikert és a szerver-hibát |
| NFR-RFMUI-03 | Color-coding a cellák/csempék állapotához (kiemelés, üres, piros) | TBD a pontos szín-jelentés |

## 6. Adatmodell-erintettseg
- Iroda (pénztár) törzs + csoport-iroda hozzárendelés: 54 csoport, csempénként iroda-név. Postgres: érintett (branch + csoport reláció). SQLite mirror: IGEN (offline kliens-szerkesztés), indok: a program lokálisan dolgozik (ARFDATA.DAT a lokális gépen). Migráció: TBD.
- Árfolyam-adat export-formátum: ARFDATA.DAT (lokális fájl) — a forrás fájlnévként említi. Konkrét séma: TBD.
- Internet-cím törzs valutánként (INTERNET oszlop forrásmegjelölésekkel + fő URL). Tábla/mező: TBD.
- Csoport kedvezményhatár (alsó/középső/felső + sávküszöbök 50.000/300.000/1.000.000) és aktuális függvény-kód (#01M). Tárolás: TBD.

## 7. Fuggosegek
- Békéscsabai szerver (biztonsági mentés célja) — hálózat/elérhetőség. A szétküldés szerver-oldali fogadása: backend/központi szerver. Pontos protokoll: TBD.
- Külső internet árfolyamforrás: exchange-rates.org (img1 fejléc URL) + valutánkénti egyéb forrás (OTP, Feco, Realtime FX stb.). Lekérés módja: TBD.
- Belső: 0-s alaplap → csoportlap adattöltés (FR-RFMUI-18).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Csoportok karbantartása | Az irodacsoportok (54) kezelése: felvétel, törlés, átnevezés, áthelyezés |
| Munkacsoport / csoport | Irodák csoportja, egyedi árfolyamlappal és kedvezményhatárral |
| ARFDATA.DAT | Lokálisan rögzített árfolyam-adatfájl, a szétküldés első lépése |
| Árfolyamok szétküldése | A lokálisan mentett árfolyamok kitétele a (békéscsabai) szerverre |
| Aktuális függvény (#01M) | A csoportlapon aktív képletkód-azonosító |
| Kedvezményhatárok (alsó/középső/felső) | A csoportlap sávküszöbei (50.000 / 300.000 / 1.000.000) |
| Nagybani (I oszlop) | A 0-s lap nagybani árfolyam-oszlopa |
| Internet (oszlop) | Valutánkénti árfolyamforrás-megjelölés + fő forrás-URL |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be ezt az MD-t és a `b1-arfolyamkeszito-kovetelmenylista.md`-t együtt — a két forrás kiegészíti egymást (a docx szöveges követelmény, a képek a meglévő UI-szerkezet).
- Igazold a 0-s lap oszlopkiosztását (FR-RFMUI-02) a docx A–I oszlop-leírásával.

### 9.2 Fazisok (acceptance criteria-val)
- Fázis 1 — 0-s lap UI: A–I + internet oszlopok, 28 valuta sora, kiemelt kézi cellák. AC: a táblázat fejléce és a 28 sor a forrás sorrendjében jelenik meg.
- Fázis 2 — Csoport-karbantartó: 54 csempe rács + 1..54 ellenőrző checklista + 5 művelet-almenü + üres-csoport ("NINCS IRODA ITT") állapot. AC: 54 csempe + checklista; üres csoport jelez.
- Fázis 3 — Csoport árfolyamlap: J–S oszlopok, csoport-fej (szám+név+iroda-lista), aktuális függvény, kitöltési segítség, kedvezményhatárok (50.000/300.000/1.000.000), a 0-s lapról töltődés. AC: a csoportlap értékei a 0-s lapból származnak (nem kézi).
- Fázis 4 — Szétküldés: lépéssorrendű művelet-log (FR-RFMUI-19), lokális siker-visszajelzés (FR-RFMUI-20), szerver-mentés és hiba-üzenet (FR-RFMUI-21). AC: a log külön jelzi a lokális sikert és a szerver-hibát.

### 9.3 Tesztes
- UI/komponens: 54 csempe + checklista renderelése; üres-csoport állapot; csoport-fej kitöltése.
- Integráció: 0-s lap → csoportlap adattöltés; szétküldés lépéslog (lokális mentés OK, szerver-mentés hibaág).
- Negatív: szerver elérhetetlen → "A BIZTONSÁGI MENTÉS SIKERTELEN VOLT!" üzenet jelenik meg, a lokális mentés viszont sikeresként jelzett.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A piros háttérszínű iroda-csempék (pl. BONYHÁD, KAP KORZÓ, PÉCS RÁKÓCZI) jelentése | Státusz-logika | A képből nem derül ki (inaktív? kijelölt? hiányos?) |
| 2 | Az "Aktuális függvény" kódkatalógus (#01M, …) teljes listája és szemantikája | Csoportlap-számítás | Csak egy érték (#01M) látszik |
| 3 | ARFDATA.DAT pontos formátuma/sémája | Export/import implementáció | Csak fájlnévként jelenik meg a logban |
| 4 | A szerver-szétküldés protokollja (FTP/HTTP/share) a békéscsabai szerverre | Integráció | A log csak "kitenni az adatokat"-ot ír |
| 5 | Az I (Nagybani) oszlop képzése/szerepe | Adatmodell | A docx nem nevezi meg az I oszlopot (csak G/H keresztet) |
| 6 | Az INTERNET oszlop forrás-feliratok (Feco, Realtime FX, BRN RON stb.) automatizált lekérése-e | Adatforrás | Csak címkék láthatók |
| 7 | A checklista "ELLENŐRZI A PROGRAM" pipa pontos validáció-tartalma csoportonként | Kiküldés-előtti validáció | A pipa jelentése nem részletezett |
| 8 | A kedvezményhatár-küszöbök (50.000/300.000/1.000.000) globálisak vagy csoportonként eltérők | Sáv-besorolás | A docx szerint csoportonként egyedi; a kép egy csoport értékeit mutatja |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak az 5 képernyőkép tartalma)
- [x] minden TBD jelölt
VERIFIKACIO: FR=21 db, TBD=8 db, érintett csomag(ok)=arfolyam-keszito-client (fő), backend (FR-RFMUI-21 szerver-mentés)
