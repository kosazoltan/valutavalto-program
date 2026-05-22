# Modul: Fejlesztesi lepesek + rendszerfunkciok + adatmodell-szabalyok (Valuta)  (forras: Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx; Kósa Szervezés/Specifikációk/Névtelen dokumentum.docx; Kósa Szervezés/c.docm)

## 1. Cel (egy mondat)
A tervezett valutavalto-rendszer modul-bontasanak (34 fejlesztesi lepes), korai rendszerfunkcio-specifikacioinak es a PowerDesigner-szeru adatmodell (entitasok, domenek, 11 uzleti szabaly) hu rogzitese.

## 2. Scope
### IN
- 34 fejlesztési lépés / modul-bontás a "Fejlesztés lépései.docx"-ból (v01 2024.11.08, v02 2024.11.13, MR & NG) — adatbázis-tervezéstől az architektúráig.
- Korai rendszerfunkció-spec a "Névtelen dokumentum.docx"-ból: belépés/kilépés, jelszó-csere (3 havi kötelező), folyamat-zárás kilépés előtt, replikáció, ügyfél/feketelista/pénzmosás vázlat.
- Adatmodell a `c.docm`-ből: entitások (szervezet, saját cég, munkaállomás, cím-hierarchia, ügyfél/személy/cég, árfolyam-családok, díj, pénztár/mozgás/címletezés, körlevél, tiltólisták, stb.), domének (típus-definíciók), 11 üzleti szabály.

### OUT
- Üzleti folyamatok részletes leírása (lásd b7-igenyfelmeres-interjuk.md).
- Jelenlegi rendszer architektúra (lásd b7-uzemeltetes-megbeszeles.md).
- A jelenlegi (megvalósult) programmal való összevetés.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Felhasznalo (altalanos) | Bejelentkezés egyedi user+jelszó, 3 havi kötelező jelszócsere, folyamat lezárása kilépés előtt | TBD (forrás csak jog-listát ad fejlesztési lépésként) |
| Penztaros | Váltás, foglaló, pénztári mozgás, zárás/nyitás | TBD |
| Ertektaros / Foertektaros | Árfolyamkezelés, díjak, jutalék, valuta-igény | TBD |
| Belsoellenor | Anonim bejelentés, gyanús ügylet, log-megtekintés | TBD |
| admin | Jogosultság-/felhasználó-/rendszerparaméter-kezelés, szervezetek, saját cég | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-53 | Adatbázis-tervezés: táblák + táblák közötti kapcsolatok létrehozása. | fejlesztés lépései (949-951) | Must | backend |
| FR-54 | Autentikáció: belépés, token, jelszócsere endpointokkal. | fejlesztés lépései (955-959) | Must | backend |
| FR-55 | Bejelentkezés egyedi felhasználónév+jelszóval, minden tevékenység logolva; jelszó nem megosztható. | Névtelen dok (1592-1593) | Must | backend |
| FR-56 | Kijelentkezés: egyszeri megerősítés; lezáratlan folyamat esetén tiltja a kilépést, jelzi a felhasználónak (vond vissza / hajtsd végre). | Névtelen dok (1597-1598) | Must | penztar-client |
| FR-57 | Jelszóváltoztatás: felhasználó által + 3 havonta belépéskor kötelező csere. | Névtelen dok (1602) | Must | backend |
| FR-58 | Dashboard: főmenü, logó, lábléc (verzió), kilépés. | fejlesztés lépései (960-965) | Should | frontend-react |
| FR-59 | Rendszerparaméter-karbantartás: lista + szerkesztő. | fejlesztés lépései (966-969) | Should | backend |
| FR-60 | Jogosultság-kezelés: lista, új, szerkesztő, aktiválás/inaktiválás, törlés. | fejlesztés lépései (970-976) | Must | backend |
| FR-61 | Felhasználó-kezelés: lista, új, szerkesztő, aktiválás/inaktiválás, archiválás, törlés. | fejlesztés lépései (977-984) | Must | backend |
| FR-62 | HR modul: munkavállaló lista/új/szerkesztő (+felhasználóhoz kapcsolás), aktiválás, archiválás, törlés, jutalékai (lista, kalkuláció, könyvelési lista-generálás). | fejlesztés lépései (985-996) | Should | kozponti-client |
| FR-63 | Munkaállomás-kezelés: lista, új, szerkesztő, aktiválás, archiválás, törlés. | fejlesztés lépései (997-1004) | Should | backend |
| FR-64 | Szervezetek + saját cég kezelés: fiók/értéktár lista/új/szerkesztés, hierarchia-módosítás, adásvétel/áthelyezés, aktiválás, bezárás. | fejlesztés lépései (1005-1021) | Must | kozponti-client |
| FR-65 | Szervezeti rendszerparaméterek: szervezet-/devizanem-/időtartam-függő variánsok. | fejlesztés lépései (1022-1035) | Should | backend |
| FR-66 | Címlet-kezelés: lista/új/szerkesztő/aktiválás/archiválás/törlés. | fejlesztés lépései (1036-1043) | Must | backend |
| FR-67 | Devizanem-kezelés: lista/új/szerkesztő/aktiválás/archiválás/törlés. | fejlesztés lépései (1044-1051) | Must | arfolyam-keszito-client |
| FR-68 | Körlevél: lista/új/szerkesztő/aktiválás/archiválás/törlés + értesítések + "értettem" felugró ablak. | fejlesztés lépései (1052-1061) | Should | kozponti-client |
| FR-69 | Ügyfél és meghatalmazott: lista/új/szerkesztő/aktiválás/archiválás/törlés. | fejlesztés lépései (1062-1069) | Must | backend |
| FR-70 | Anonim bejelentés: lista, új, inaktiválás. | fejlesztés lépései (1070-1074) | Should | kozponti-client |
| FR-71 | Árfolyamkezelés: konkurens árfolyamok (lista/új/szerkesztés/törlés), banki árfolyamok (lista/új/lekérés), árfolyam-meghatározás (lista/szerkesztő/változás), automata árfolyam-lekérdezés. | fejlesztés lépései (1075-1090) | Must | arfolyam-keszito-client |
| FR-72 | Díjak/díjmértékek: díjtípus (lista/új/szerkesztés/archiválás/törlés), díjmérték, adható díjkedvezmény, díjváltozás (szinkron utáni automata életbeléptetés), alkalmazott díjak. | fejlesztés lépései (1091-1117) | Must | backend |
| FR-73 | Jutalék-paraméterezés: jutalékmérték lista/új/szerkesztés/törlés. | fejlesztés lépései (1118-1123) | Should | backend |
| FR-74 | Tiltólisták: új/szerkesztés/letöltés/aktiválás/törlés + automata szinkronizálás. | fejlesztés lépései (1124-1131) | Must | backend |
| FR-75 | Váltás: indítás, igényrögzítés, ellenőrzések, művelet-végrehajtás (eladás, vétel, kereszt/összetett váltás). | fejlesztés lépései (1132-1140) | Must | penztar-client |
| FR-76 | Foglaló-kezelés: rögzítés, érvényesítés, visszafizetés, ügyfél-hibából automata lezárás. | fejlesztés lépései (1141-1146) | Must | penztar-client |
| FR-77 | Valuta-igények: igény rögzítése, generálása készletadatból, teljesítése. | fejlesztés lépései (1147-1151) | Should | kozponti-client |
| FR-78 | Pénztárak közötti mozgás: pénz átadás/átvétel egységnek, transzfer-korrekció, kezelési díjak átadása/átvétele. | fejlesztés lépései (1152-1157) | Must | penztar-client |
| FR-79 | Átadólap: ablak, generálás, nyomtatás. | fejlesztés lépései (1158-1162) | Must | penztar-client |
| FR-80 | Bizonylatkezelés: lista, sztornó, újranyomtatás, utólagos NAV-feladás. | fejlesztés lépései (1163-1168) | Must | backend |
| FR-81 | Zárás/nyitás: napi zárás, POS-terminál napi zárás, dekád-zárás, havi zárás, nyitás. | fejlesztés lépései (1169-1175) | Must | penztar-client |
| FR-82 | Járulék/jutalék kalkuláció időszakra. | fejlesztés lépései (1176-1178) | Should | backend |
| FR-83 | Pénzmosás/terror-gyanús eset bejelentés: új, felülvizsgálat, feladás. | fejlesztés lépései (1179-1183) | Must | backend |
| FR-84 | Listák/riportok: ügylet-, bizonylat-, díjösszesítő-lista; havi készlet/forgalom/körzet/iroda/átadás-átvétel; kezelési költség; napi pénztár; pillanatnyi pénztárállás; gyanús ügylet keresés; kártyás tranzakciós díjak. | fejlesztés lépései (1184-1201) | Must | kozponti-client |
| FR-85 | Technikai funkciók: árfolyam-kijelző; pénztárszünet-kezelés (lista/új/szerkesztés/törlés + automata lezárás); logolás (rendszer-/POS-/NAV-log, kimásolás, archiválás); üzleti adat archiválás. | fejlesztés lépései (1202-1223) | Must | penztar-client / backend |
| FR-86 | Architektúra: adat-szinkronizációs modul. | fejlesztés lépései (1224-1226) | Must | backend |
| FR-87 | Felhasznált általános modulok: kijelző-monitor kezelő, POS-terminál, NAV pénztárgép interface, dokumentumtár, értesítés-kezelő. | fejlesztés lépései (1227-1233) | Must | penztar-client / backend |
| FR-88 | Adat-replikáció + verziókezelés + hírlevél/hirdetmény (korai rendszerfunkció-vázlat, részletek nélkül). | Névtelen dok (1604-1608) | Could | backend |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-13 | Kötelező jelszócsere periódus | 3 hónap (Névtelen dok 1602) |
| NFR-14 | Teljes tevékenység-logolás (ki, mit) | minden bejelentkezett művelet logolt (1593) |
| NFR-15 | Cím-validitás: a cím rész-területei koherensek (közterület a településen, megye az országban) | c.docm "cím validitás" üzleti szabály (1660-1668) |
| NFR-16 | Adattípus-domének rögzített hossza | pl. bankszámlaszám VARCHAR(32), belső id (64), bizonylatszám (64), hosszú név (256) — c.docm domének |

## 6. Adatmodell-erintettseg
- Postgres entitas-jeloltek (c.docm export, hu nevek): dokumentum, dokumentum file, bank, irányítószám, közterület, közterület-település/-típus, megye, munkaállomás, ország, saját cég, saját cég bankszámla, saját cég tevékenysége, szervezet tevékenysége, szervezeti egység, TEAOR, személy, személy azonosító okmány, végzettség, elemi jog, felhasználó (+elemi joga, +jogcsoportjai), hozzáférési jog, jogcsoport, körlevél (+csatolmány, +hivatkozás, +olvasva, +címzett szervezeti egység/felhasználó/jogcsoport/telephely), banki/csoport/kedvezményes/saját árfolyam, címlet, devizanem, konkurens (+deviza árfolyam, +nyitvatartás), árfolyam csoport, szervezet konkurense, rendszerparaméter (+szervezet-/devizanem-/időtartam-függő), alkalmazható díj kedvezmény, díj kedvezmény típus, díj mérték fej/tétel, díj típus, szervezetnél alkalmazandó díj, névtelen bejelentés, pénztár, jogcím, nyitás-zárás bizonylat, pénztár nyitás-zárás, pénztári egyenleg (+címletezés), pénztári időszak, pénztári mozgás (+címletezés), tevékenységnél alkalmazható jogcím, cég tulajdonos, cég ügyfél, céges dokumentum, közszereplő típus, okmány típus, személy ügyfél, tiltott cég/személy/állampolgárság, ügyfél, ügyfél igazoló okmány.
- Domének: bankszámlaszám(32), belső id(64), bizonylatszám(64), hosszú név(256), igen-nem, megjegyzés, név, rövid név, százalék, árfolyam, összeg.
- 11 üzleti szabály (c.docm): (1) cég TEAOR a hierarchia legalsó eleméből; (2) cím-validitás koherencia; (3) címletezés devizaneme = egyenleg/mozgás devizaneméhez tartozó címlet; (4) desktop rendszernél pénztár kötelezően munkaállomáshoz rendelt; (5) egy személynek egy okmánytípusból csak egy érvényes; (6) transzfer/pénzszállító csomag kiindulási és cél hely kizárólagosság (nem lehet kiindulási bank ÉS cél bank, telephely ÉS bank együtt); (7) megye az országhoz tartozik; (8) munkaállomás csak egy telephely tevékenységeihez; (9) pénztári mozgás csak nyitott pénztárba; (10) Rule_10 (definíció nélkül a forrásban → TBD); (11) ügyfél vagy személy, vagy cég.
- SQLite mirror: a pénztári mozgás/egyenleg/címletezés/bizonylat IGEN (offline pénztáros). Törzs (szervezet, díj, árfolyam, tiltólista) read-only mirror IGEN a kliensen. Indok: kliensoldali váltás offline.
- Migracio szukseges: TBD (a c.docm logikai modell, nem fizikai séma; Flyway-séma külön fázis).

## 7. Fuggosegek
- Belső modul: minden 34 lépés egymásra épül (DB -> backend -> auth -> törzs -> tranzakció -> riport -> architektúra-szinkron).
- Külső API: NAV pénztárgép interface, automata árfolyam-lekérdezés (forrás bank), tiltólista-letöltés (FR-74).
- Adatmodell-eszköz: a forrás PowerDesigner/hasonló logikai modell-export (`c.docm`).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Elemi jog / jogcsoport / hozzáférési jog | A jogosultság-modell entitásai (c.docm). |
| Saját cég / szervezeti egység | A multi-tenant cég- és fiók/értéktár-hierarchia entitásai. |
| Pénztári mozgás címletezése | A pénztári mozgáshoz kötött címlet-bontás (címlet devizaneme = mozgás devizaneme). |
| Csoport árfolyam / saját árfolyam / kedvezményes árfolyam | Árfolyam-családok az árfolyamkezelő modulban. |
| Jogcím | Pénztári mozgáshoz/tevékenységhez rendelhető jogcím-entitás. |
| Dekád-zárás | 10 napos zárási ciklus (FR-81, fejlesztés lépései 1173). |
| Rule_10 | Üzleti szabály név definíció nélkül a c.docm-ben (TBD). |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A "Fejlesztés lépései" a 34-lépéses munkaterv (modul-sorrend); a `c.docm` adja a logikai adatmodellt; a "Névtelen dokumentum" csonka korai vázlat (sok üres alpont).
- Az entitás- és domén-neveket magyar nevükön rögzítsd; a c.docm angol Code-mezőket is ad (pl. account_number, internal_id, note_number, long_name).
### 9.2 Fazisok (acceptance criteria-val)
- 1. fazis: alap (FR-53, FR-54, FR-55, FR-57) + jogosultság/felhasználó (FR-60, FR-61). AC: token-auth, 3 havi jelszó-csere, RBAC entitások (elemi jog/jogcsoport/hozzáférési jog).
- 2. fazis: törzsadatok (FR-64..FR-69, FR-66, FR-67) + a 11 üzleti szabály validáció. AC: cím-koherencia, munkaállomás-telephely, ügyfél=személy XOR cég.
- 3. fazis: tranzakció (FR-75, FR-78, FR-79, FR-80, FR-81) + foglaló (FR-76). AC: pénztári mozgás csak nyitott pénztárba; címletezés-deviza egyezés.
- 4. fazis: árfolyam/díj (FR-71, FR-72) + AML (FR-83, FR-74) + riportok (FR-84) + szinkron (FR-86).
### 9.3 Tesztes
- Backend: a 11 üzleti szabály mindegyikére invariáns-teszt (különösen #3 címletezés-deviza, #6 kiindulási/cél hely XOR, #9 nyitott pénztár, #11 ügyfél XOR).
- Domén-validáció: hossz-határok (32/64/256), százalék/árfolyam/összeg típus.
- Frontend/Electron: kilépés-gate lezáratlan folyamatnál (FR-56), 3 havi jelszó-csere prompt (FR-57).

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-18 | Rule_10 üzleti szabály tartalma | adatmodell-integritás | A c.docm csak a nevet adja, leírás/definíció nincs (1790-1799). |
| TBD-19 | RBAC kód-értékek a szerepekhez | jogosultság-impl | A forrás csak entitás-listát ad, konkrét kódot nem. |
| TBD-20 | Névtelen dokumentum üres alpontjai (1.1 Felhasználó karbantartás, 1.4 Verziókezelés, 1.5 Adat replikáció, 1.6 Hírlevél, 2.5 Munkatárs, Beosztás, 5.x Ügyfél) | spec-teljesség | Címek léteznek, tartalom nincs — csonka dokumentum. |
| TBD-21 | "Pénzmosás figyelés (Pénzmosás megelőzése inkább?)" megnevezés/scope | AML-modul | A forrás maga is bizonytalan a megnevezésben (1624). |
| TBD-22 | Díjmérték fej/tétel pontos szerkezete | díjmodell | A c.docm entitásnevet ad, attribútum-részletet nem nyertünk ki teljesen. |
| TBD-23 | Konkurens nyitvatartás / konkurens deviza árfolyam használati cél | árfolyam-versenyfigyelés | Entitás létezik, üzleti folyamat-leírás nincs a forrásban. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció
- [x] minden TBD jelölt
VERIFIKACIO: FR=36 db (FR-53..FR-88), TBD=6 db (TBD-18..TBD-23), érintett csomag(ok)=backend, frontend-react, penztar-client, kozponti-client, arfolyam-keszito-client.
