# Modul: Zárás-képernyők és zárási bizonylatok (napi/dekád/havi/értéktári + címletezés)  (forrás: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/ — Képernyőképek/ és Bizonylatok/ képei)

> Forrásképek (NFC-egyező fájlnevekkel): Bizonylatok/Napi zárás.jpg, Havi zárás.jpg, Havi zárás 2_.jpg, Zárás-Értéktár.jpeg, 2024. március. 1. havi dekádzárás.jpeg; Képernyőképek/Dekédzárás.jpeg, Címletezés -Zárások menü.jpeg, Címletezés - Zárások napi pénztárzárás.jpeg, Címletezés Zárások - Cimletezés.JPG, Címletezés nyomtatása.jpeg, Napi összefoglaló (X).jpeg, Értéktári zárás előtti check list.JPG, Értéktári zárást ellenőrző személy adatai.JPG.

## 1. Cel (egy mondat)
A meglévő (legacy) zárási képernyők és nyomtatott bizonylatok hű leírása: a napi/dekád/havi/értéktári zárás felületi elemei, a záráshoz kapcsolódó címletezés-menü és -nyomtatás, a napi összefoglaló (X) képernyő, az értéktári zárás-előtti checklist és a zárást ellenőrző személy adatainak rögzítése, valamint a kinyomtatott zárási bizonylatok blokk-struktúrája.

## 2. Scope
### IN
- Címletezés–Zárások menü gombjai: "Különféle címletezések", "Címletek kinyomtatása", "A mai napi zárás végrehajtása", "A havi zárás végrehajtása", "Mégsem" (forrás: Címletezés -Zárások menü.jpeg).
- "Címletezés" almenü: "Esti zárás címletezése", "Kezelési díj címletezése", "Western Union címletezése", "ÁFA pénztár címletezése", "Elektromos kereskedés címletezése"; "Vissza" / "Kilépés" (forrás: Címletezés Zárások - Cimletezés.JPG).
- "Címletek kinyomtatása" párbeszéd checkboxokkal: Valutaváltás címletek, Kezelési díj címletek (bejelölve); Western Union, ÁFA, Foglalók, Elektromos kereskedés, AXA biztosítás címletek (halványítva/inaktív); gombok: "Nyomtatás indul", "Minden kijelölése", "Kilépés" (forrás: Címletezés nyomtatása.jpeg).
- Napi pénztárzárás címletezés-figyelmeztetés: "A NAV-OS FORINT FIÓKÉRTÉKE ELTÉR A CÍMLETEZÉSTŐL" + pénztáros megjegyzés mező + "E-mail küldése és mehet tovább a zárás" gomb (forrás: Címletezés - Zárások napi pénztárzárás.jpeg).
- Dekádzárás dialógus: év (2024), hónap (MÁRCIUS), dekád (1. DEKÁD) legördülők + "Nyomtatás" / "Mégsem" (forrás: Dekédzárás.jpeg).
- Napi összefoglaló (X) képernyő: dátum/fiók, Összesen záró készlet F9 (Forint/Valuta/Összesen), Pillanatnyi pénztárállás (DNEM/KÉSZLET/VÉTEL/ELADÁS), Napi forgalom (Vétel/Eladás de/du/Össz), Forint készlet (címletenként db), Euró érme készlet, Egyedi árfolyamok (Val./Összeg/ÁRF/Bizonylat), KÜLDÖK/KÉREK, Western Union záró készletei (HUF/USD), ÁFA innova készlet (HUF), Kezelésidíj, E-kereskedelem, Jelentés beküldése / Most nem küldöm be, Ptáros de/du (forrás: Napi összefoglaló (X).jpeg).
- Értéktári zárás-előtti checklist (forrás: Értéktári zárás előtti check list.JPG) — soronkénti tételek a 4. szekcióban.
- Zárást ellenőrző személy adatai dialógus: "NEVE", "BEOSZTÁSA", "Ellenőrző személy adatai rendben" / "Mégsem zárom a napot"; alcím: "A zárószalagot kérem aláírni" (forrás: Értéktári zárást ellenőrző személy adatai.JPG).
- Nyomtatott bizonylatok blokk-struktúrája: Napi zárás, Havi zárás, Havi dekádzárás, Értéktári zárás (forrás: Bizonylatok/* képek).

### OUT
- A legacy felület újraépítésének UI-stílusa (csak a tartalmi elemeket írjuk le, vizuális design TBD).
- A NAV-eltérés e-mail küldés technikai háttere (csak a gomb és a figyelmeztetés látszik) — TBD-1.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Napi/dekád/havi pénztárzárás, címletezés, napi összefoglaló (X), zárás-bizonylat nyomtatás (forrás: Napi összefoglaló (X).jpeg "Ptáros", Napi zárás.jpg "penztaros") | TBD-2 |
| Értéktáros / pénztáros értéktári záráskor | Értéktári zárás-előtti checklist kitöltése, értéktári zárás (forrás: Értéktári zárás előtti check list.JPG; Zárás-Értéktár.jpeg "penztaros") | TBD-2 |
| Zárást ellenőrző személy | Név + beosztás megadása, zárószalag aláírása ("Ellenőrző személy adatai rendben") (forrás: Értéktári zárást ellenőrző személy adatai.JPG) | TBD-2 |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Címletezés–Zárások menü: Különféle címletezések / Címletek kinyomtatása / A mai napi zárás végrehajtása / A havi zárás végrehajtása / Mégsem | Címletezés -Zárások menü.jpeg | Magas | penztar-client |
| FR-2 | "Címletezés" almenü 5 típus szerint: Esti zárás, Kezelési díj, Western Union, ÁFA pénztár, Elektromos kereskedés; Vissza/Kilépés | Címletezés Zárások - Cimletezés.JPG | Magas | penztar-client |
| FR-3 | "Címletek kinyomtatása" checkbox-os választó: Valutaváltás + Kezelési díj alapból bejelölve; Western Union/ÁFA/Foglalók/Elektromos keresk./AXA inaktív; Nyomtatás indul / Minden kijelölése / Kilépés | Címletezés nyomtatása.jpeg | Magas | penztar-client |
| FR-4 | Napi pénztárzárásnál címletezés-egyezőség ellenőrzés: ha a NAV-os forint fiókérték eltér a címletezéstől, piros figyelmeztetés + kötelező pénztáros-megjegyzés + "E-mail küldése és mehet tovább a zárás" | Címletezés - Zárások napi pénztárzárás.jpeg | Magas | penztar-client / backend |
| FR-5 | Dekádzárás dialógus: év + hónap + dekád (pl. 1. DEKÁD) választása, majd "Nyomtatás" / "Mégsem" | Dekédzárás.jpeg | Magas | penztar-client |
| FR-6 | Napi összefoglaló (X) képernyő fejléce: dátum + fiók megnevezés (pl. 2024.03.12, Békéscsaba Belváros) | Napi összefoglaló (X).jpeg | Magas | penztar-client |
| FR-7 | "Összesen záró készlet F9": Forint, Valuta, Összesen érték megjelenítése (F9 funkcióbillentyű) | Napi összefoglaló (X).jpeg | Magas | penztar-client |
| FR-8 | Pillanatnyi pénztárállás tábla: DNEM / KÉSZLET / VÉTEL / ELADÁS soronként devizanemenként | Napi összefoglaló (X).jpeg | Magas | penztar-client |
| FR-9 | Napi forgalom: Vétel és Eladás de/du bontásban + Összesen | Napi összefoglaló (X).jpeg | Magas | penztar-client |
| FR-10 | Forint készlet címletenkénti darabszáma (20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5) + Euró érme készlet | Napi összefoglaló (X).jpeg | Magas | penztar-client |
| FR-11 | Egyedi árfolyamok blokk: Val. / Összeg / ÁRF / Bizonylat | Napi összefoglaló (X).jpeg | Közepes | penztar-client |
| FR-12 | KÜLDÖK / KÉREK panelek (pénztárak közötti mozgás kezdeményezése a zárás képernyőn) | Napi összefoglaló (X).jpeg | Közepes | penztar-client |
| FR-13 | Western Union záró készletei (HUF/USD), ÁFA innova készlet (HUF), Kezelésidíj összeg, E-kereskedelem | Napi összefoglaló (X).jpeg | Közepes | penztar-client |
| FR-14 | Jelentés beküldése / "Most nem küldöm be" választás a zárás képernyőn | Napi összefoglaló (X).jpeg | Magas | penztar-client / backend |
| FR-15 | A napi összefoglalón a délelőtti/délutáni pénztáros (Ptáros de/du) rögzítése | Napi összefoglaló (X).jpeg | Közepes | penztar-client |
| FR-16 | Értéktári zárás-előtti checklist képernyő tételekkel, dátummal és pénztáros nevével | Értéktári zárás előtti check list.JPG | Magas | penztar-client |
| FR-17 | Checklist tétel "Minden pénztár készlete feltöltve (címletek, fém euró)" (kiemelt) | Értéktári zárás előtti check list.JPG | Magas | penztar-client |
| FR-18 | Checklist tétel: esetleges helyettesítéskor kollégának minden infó átadólapon átadva | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-19 | Checklist tétel: grafikon kitöltve, kifüggesztve, érintetteknek továbbítva | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-20 | Checklist tétel: konkurencia árfolyamainak/készleteinek figyelemmel követése; konkurencia-jelentés megírása (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-21 | Checklist tétel: próbaváltás (eseti); havi beszámoló megírása, lefűzése (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-22 | Checklist tétel: bizonylatok párosítása, lefűzése; Kkts/E-ker/jutalék beszedése-befizetése (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-23 | Checklist tétel: TRB tábla kitöltése; egyedi árfolyamos tábla kitöltése+továbbítása (eseti); egyedi árfolyamok ellenőrzése+továbbítása (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-24 | Checklist tétel: nagy ügyfélkártyák begyűjtése/összesítése, továbbítása (eseti); könyvelések lenyomtatása, lefűzése, adatainak ellenőrzése (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-25 | Checklist tétel: hóvégi egyeztetés területekkel (eseti); hóvégi egyeztetés pénztárakkal; napi jelentések leszavainak elküldése SMS-ben a pénztáraknak/értéktárosoknak stb. (eseti) | Értéktári zárás előtti check list.JPG | Közepes | penztar-client |
| FR-26 | Zárást ellenőrző személy adatai dialógus: NEVE + BEOSZTÁSA megadása, "Ellenőrző személy adatai rendben" / "Mégsem zárom a napot"; alcím a zárószalag aláírásáról | Értéktári zárást ellenőrző személy adatai.JPG | Magas | penztar-client |
| FR-27 | Nyomtatott napi zárás bizonylat: cégfejléc + dátum, valuta vásárlások/eladások, összes vételi/eladási érték, pénztárak közötti mozgások (DNEM/Átadott/Átvett), napi valutaárfolyamok (Vételi/Eladási), napi záró-/nyitókészlet, napi forgalom kimutatás I–II., kezelési költség listák, "Büntetőjogi felelősségem tudatában..." nyilatkozat + penztaros aláírás | Bizonylatok/Napi zárás.jpg | Magas | penztar-client |
| FR-28 | Nyomtatott havi zárás bizonylat: cégfejléc + havi időszak (kezdő/záró dátum), valutánkénti nyitó/növekedés/csökkenés/záró, pénztárak közötti mozgások, havi bankjegy-forgalom kimutatás I–II., havi záró készlet valutánként, Western Union forgalom (USD/HUF), ÁFA, kezelési költségek havi listája, havi ügyfélforgalom (eladó/vevő ügyfelek) | Bizonylatok/Havi zárás.jpg; Havi zárás 2_.jpg | Magas | penztar-client |
| FR-29 | Nyomtatott havi dekádzárás bizonylat: fiókfejléc + "havi 1. dekádzárás" + dekád időszak (pl. 2024.03.01–2024.03.10), soronként (Sor/Np/Bizony./Ft.atvetel/Ft.atadas), V.vetel/V.elad, dekád forgalom, nyitó/záró/összes forint + penztaros | Bizonylatok/2024. március. 1. havi dekádzárás.jpeg | Magas | penztar-client |
| FR-30 | Nyomtatott értéktári zárás bizonylat (1 bizonylat, többhasábos): cégfejléc, napi/időszaki záró-tételek, bankjegy-forgalom kimutatás I–II. (nyitó/átvett/átadott/záró), pénztárak közötti mozgások összesítve, pénztár állása, Western Union forgalom, gép-vissztérítendő/ügyfélforgalom + penztaros aláírás | Bizonylatok/Zárás-Értéktár.jpeg | Magas | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | NAV-fiókérték / címletezés egyezőség | Eltérés esetén a zárás csak kötelező megjegyzés + e-mail küldés után folytatható (forrás: Címletezés - Zárások napi pénztárzárás.jpeg) |
| NFR-2 | Kétszemélyes zárás-kontroll | Az értéktári zárás véglegesítéséhez ellenőrző személy neve+beosztása kötelező; "Mégsem zárom a napot" megszakít (forrás: Értéktári zárást ellenőrző személy adatai.JPG) |
| NFR-3 | Checklist teljesség | Az értéktári zárás-előtti checklist tételei (kiemelt + eseti) megjeleníthetők és kipipálhatók (forrás: Értéktári zárás előtti check list.JPG) |
| NFR-4 | Bizonylat-tartalmi teljesség | A nyomtatott bizonylatok a forrásképeken látható összes blokkot tartalmazzák (forgalom, készlet, árfolyam, mozgás, kezelési költség, nyilatkozat/aláírás) |
| NFR-5 | Forint címlet-bontás teljessége | A forint készlet a forráson látható címleteket darabszámmal bontja (20000…5 Ft) + euró érme készlet (forrás: Napi összefoglaló (X).jpeg) |

## 6. Adatmodell-erintettseg
A források képernyők/bizonylatok; konkrét tábla/mező nem olvasható ki. Levezetett szükséges fogalmak (konkrét séma TBD-3):
- Címletezés-rekord típusonként (esti zárás, kezelési díj, Western Union, ÁFA pénztár, elektromos kereskedés) + címlet-darabszámok (forint címletek + euró érme).
- Napi összefoglaló adatai: záró készlet (forint/valuta/összesen), pillanatnyi pénztárállás devizanemenként, napi forgalom de/du, egyedi árfolyamok, Western Union/ÁFA/kezelésidíj/e-kereskedelem készletek, pénztáros de/du.
- NAV-fiókérték vs. címletezés eltérés + pénztáros-megjegyzés + e-mail státusz.
- Értéktári checklist tételek + dátum + pénztáros neve.
- Zárást ellenőrző személy: név, beosztás, "rendben" jelölés.
- Nyomtatott bizonylatok típusonként (napi/havi/dekád/értéktári) blokkjaikkal.
SQLite mirror: IGEN (a zárás és címletezés a penztar-client offline folyamata; mezők TBD-3). Migráció szükséges? TBD-3.

## 7. Fuggosegek
- Külső: NAV (a "NAV-os forint fiókérték" forrása; pénztárgép-kötés) (forrás: Címletezés - Zárások napi pénztárzárás.jpeg).
- Külső: e-mail küldés (NAV-eltérés esetén) (forrás: ugyanott) — csatorna TBD-1.
- Külső: Western Union, ÁFA innova (külön készletblokkok a zárásban) (forrás: Napi összefoglaló (X).jpeg).
- Belső: tranzakció-/készlet-nyilvántartás, árfolyamtábla, kezelési díj, pénztárak közötti mozgás (KÜLDÖK/KÉREK).
- Belső kapcsolat: a b2-zaras-ablak.md wizard-folyamata (ezek a képernyők/bizonylatok annak felületi/kimeneti megvalósulásai).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Címletezés | A készlet címletenkénti darabszámának nyilvántartása/nyomtatása záráskor (forint címletek + euró érme) (forrás: Címletezés képek) |
| Esti zárás címletezése | A napi (esti) zárás címletbontása (forrás: Címletezés Zárások - Cimletezés.JPG) |
| Napi összefoglaló (X) | A nap aktuális állását mutató összesítő képernyő (X funkció) záró készlettel, forgalommal, készletekkel (forrás: Napi összefoglaló (X).jpeg) |
| Összesen záró készlet F9 | F9 billentyűvel előhívott záró készlet (Forint/Valuta/Összesen) (forrás: ugyanott) |
| NAV-os forint fiókérték | A NAV felé nyilvántartott forint fiókérték, amely eltérhet a fizikai címletezéstől (forrás: Címletezés - Zárások napi pénztárzárás.jpeg) |
| KÜLDÖK / KÉREK | Pénztárak közötti deviza-/forint-mozgás kezdeményezése a zárás felületen (forrás: Napi összefoglaló (X).jpeg) |
| Értéktári zárás-előtti checklist | Az értéktári zárás előtt kötelező/eseti teendők listája (forrás: Értéktári zárás előtti check list.JPG) |
| Zárást ellenőrző személy | A zárószalagot aláíró, név+beosztás szerint rögzített ellenőr (forrás: Értéktári zárást ellenőrző személy adatai.JPG) |
| Dekádzárás | 1 dekád (10 nap) zárása év/hónap/dekád választással, nyomtatással (forrás: Dekédzárás.jpeg) |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A forrásképeket tekintsd igazságforrásnak; a kézzel olvasott bizonylat-számok illusztratívak (egy konkrét nap/hó adata), a struktúra a követelmény.
- Ne hasonlíts a jelenlegi kódhoz ebben a fázisban. Tisztázd a TBD-1..TBD-4 kérdéseket.

### 9.2 Fazisok (acceptance criteria-val)
- 1. fázis — Címletezés menü + almenü + nyomtatás-választó. AC: az 5 címletezés-típus elérhető; a "Címletek kinyomtatása" checkboxai a forrás szerinti alap-bejelölésekkel és inaktív tételekkel jelennek meg (FR-1..FR-3).
- 2. fázis — Napi pénztárzárás + NAV-eltérés gate. AC: NAV-fiókérték ≠ címletezés esetén kötelező megjegyzés + e-mail nélkül a zárás nem folytatható (FR-4, NFR-1).
- 3. fázis — Napi összefoglaló (X) képernyő. AC: minden blokk (záró készlet F9, pillanatnyi pénztárállás, napi forgalom de/du, forint+euró címlet-készlet, egyedi árfolyamok, WU/ÁFA/kezelésidíj/e-keresk., KÜLDÖK/KÉREK, jelentés-küldés, ptáros de/du) megjelenik (FR-6..FR-15, NFR-5).
- 4. fázis — Dekádzárás dialógus. AC: év/hónap/dekád választás + nyomtatás/mégsem (FR-5).
- 5. fázis — Értéktári zárás: checklist + ellenőrző személy. AC: a checklist tételei kipipálhatók (kiemelt + eseti), a véglegesítéshez ellenőrző név+beosztás kötelező, "Mégsem zárom a napot" megszakít (FR-16..FR-26, NFR-2, NFR-3).
- 6. fázis — Nyomtatott bizonylatok. AC: a napi/havi/dekád/értéktári bizonylatok a forrásképeken látható összes blokkot tartalmazzák, aláírás-/nyilatkozat-mezőkkel (FR-27..FR-30, NFR-4).

### 9.3 Tesztes
- Egységteszt: NAV-eltérés gate (eltérés → kötelező megjegyzés+e-mail; egyezés → akadálytalan).
- Egységteszt: ellenőrző személy kötelező mezők (üres név/beosztás → nem zárható; "Mégsem" → megszakít).
- Egységteszt: forint címlet-bontás darabszám × címletérték = forint készlet összeg.
- Integrációs teszt: napi összefoglaló blokkjainak adatforrás-egyezése (készlet/forgalom/árfolyam).
- Snapshot-teszt: napi/havi/dekád/értéktári bizonylat blokk-struktúra a forráskép szerint.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A NAV-eltérés "E-mail küldése" címzettje, tartalma és technikai csatornája | Zárás-gate működése | A képen csak a gomb + figyelmeztetés látszik |
| TBD-2 | A pénztáros / értéktáros / ellenőrző személy konkrét RBAC szerepkör-értéke | Jogosultság-implementáció | Csomag szereplő-listához kötés |
| TBD-3 | Címletezés/napi összefoglaló/checklist/bizonylat pontos adatmodellje + SQLite mirror mezők | Tárolás és offline működés | Konkrét entitás/mező-terv |
| TBD-4 | A halványított (inaktív) címlet-nyomtatás tételek (Western Union, ÁFA, Foglalók, Elektromos keresk., AXA) aktiválási feltétele | Címletnyomtatás-választó logika | Mikor válnak elérhetővé (fiók-profil/jogosultság?) |
| TBD-5 | Az értéktári checklist tételek pontos teljes szövege (egyes sorok a fotón nehezen olvashatók) | Checklist hűsége | Nagyobb felbontású forrás vagy szöveges lista |
| TBD-6 | Néhány bizonylatkép kézzel írt/áthúzott számokat tartalmaz (Dekádzárás, Értéktár) | A számértékek nem általánosíthatók | Csak a struktúra a követelmény, az értékek illusztratívak |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás (kép-fájlnév)
- [x] 0 hallucináció (csak a képeken látható elemek)
- [x] minden TBD jelölt (nehezen olvasható részek külön jelölve: TBD-5, TBD-6)
VERIFIKACIO: FR=30 db, TBD=6 db, érintett csomag(ok)=penztar-client, backend.
