# Modul: Régi Delphi valutaprogram — Főmenü struktúra  (forrás: Képernyőképek/Főmenü.JPG, Főmenü 2.JPG)

## 1. Cel (egy mondat)
A régi (dekanySoft / Exclusive Best Change ZRT.) Delphi valutaváltó program 04.00 verziójú főmenüjének teljes menüstruktúrája — minden menüpont és az alsó (F1–F12 + Esc) gombsor — hűen leírva.

## 2. Scope
### IN
- A főmenü két képernyőképe (Főmenü.JPG az első menü-blokk; Főmenü 2.JPG a folytatás/második blokk).
- Bal oldali fej-panel (Verziószám, Munkanap dátuma, Pontos idő, telefon, bejelentkezett pénztáros, egység-azonosító).
- Központi menülista-elemek.
- Alsó funkcióbillentyű-sor (F1–F12, Esc) — Főmenü 2.JPG-n olvasható.
### OUT
- A menüpontok mögötti aldialógusok (külön EXCMD MD-kben: pénztár-mozgások, listák, kezelés/címletezés/engedélyezés).
- Beállítás-képernyők, napzárás-checklist (más források).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Bejelentkezett felhasználó (a fej-panelen "Bejelentkezett pénztáros: 07505-SARKADI TÜNDE") — alapfunkciók, főmenü-navigáció | TBD (forrásból a konkrét RBAC nem olvasható) |
| Értéktáros / egyéb | TBD — a forrás csak a bejelentkezett pénztárost mutatja | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-FM-01 | A főmenü fejléce megjeleníti a verziószámot ("04.00"). | Főmenü.JPG (bal felül: "Verziószám 04.00") | M | penztar-client |
| FR-FM-02 | A fejléc megjeleníti a munkanap dátumát ("2024 MÁRCIUS 12 KEDD"). | Főmenü.JPG ("Munkanap dátuma") | M | penztar-client |
| FR-FM-03 | A fejléc megjeleníti a pontos időt ("11:51"). | Főmenü.JPG ("Pontos idő 11:51") | S | penztar-client |
| FR-FM-04 | A fejléc megjeleníti az egység-azonosítót ("75") és telefont ("06/66-448-500"). | Főmenü.JPG (piros "75" + "Telefon") | S | penztar-client |
| FR-FM-05 | A fejléc megjeleníti a bejelentkezett pénztárost és az egységet/címet ("07505-SARKADI TÜNDE", "BÉKÉSCSABA", "ANDRÁSSY UT 24-28"). | Főmenü.JPG | M | penztar-client |
| FR-FM-06 | A főmenü háttérképe felett kiemelten megjelenik az egység neve/típusa ("BÉKÉSCSABA ÉRTÉKTÁR"). | Főmenü.JPG, Főmenü 2.JPG | C | penztar-client |
| FR-FM-07 | Főmenüpont: "PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL". | Főmenü.JPG (1. sor) | M | penztar-client, kozponti-client |
| FR-FM-08 | Főmenüpont: "MAI BIZONYLAT SZTORNÓJA". | Főmenü.JPG (2. sor) | M | penztar-client |
| FR-FM-09 | Főmenüpont: "A PILLANATNYI PÉNZTÁR ÁLLÁSA" (bal-jobb lapozó nyilakkal: "<<<" / ">>>"). | Főmenü.JPG (3. sor) | M | penztar-client |
| FR-FM-10 | Főmenüpont: "A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS". | Főmenü.JPG (4. sor) | M | penztar-client |
| FR-FM-11 | Főmenüpont: "BIZONYLATOK MEGTEKINTÉSE". | Főmenü.JPG (5. sor) | M | penztar-client |
| FR-FM-12 | Gomb/menüpont: "KILÉPÉS A FŐMENÜBŐL". | Főmenü.JPG, Főmenü 2.JPG | M | penztar-client |
| FR-FM-13 | A főmenü lapozható (nyíl-navigáció "<<<" / ">>>") a menü-blokkok között. | Főmenü.JPG + Főmenü 2.JPG (két blokk) | S | penztar-client |
| FR-FM-14 | Főmenüpont: "TÁRSPÉNZTÁRAK KARBANTARTÁSA". | Főmenü 2.JPG (1. sor) | M | penztar-client |
| FR-FM-15 | Főmenüpont: "KÜLÖNFÉLE LISTÁK NYOMTATÁSA". | Főmenü 2.JPG (2. sor) | M | penztar-client |
| FR-FM-16 | Főmenüpont: "PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA". | Főmenü 2.JPG (3. sor) | M | penztar-client |
| FR-FM-17 | Főmenüpont: "RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA". | Főmenü 2.JPG (4. sor) | S | penztar-client |
| FR-FM-18 | Főmenüpont: "WESTERN UNION ÉS ÁFA TRANZAKCIÓK". | Főmenü 2.JPG (5. sor) | S | penztar-client |
| FR-FM-19 | Alsó gombsor (F1–F12 + Esc) — felirataik: F1 ÁRFOLYAM, F2 FOGLALÓ, F3 TERMINÁL, F4 ÁFA TÁBLA, F5 MAI FORG., F6 (TESCO ÁFA — szürkített), F7 SUPERVISOR, F8 (üres), F9 KÉSZLET, F10 ÁTADÓLAP, F11 (METRO ÁFA / W.UNION — szürkített), F12 (W.UNION), Esc KILÉPÉS. | Főmenü 2.JPG (alsó sor jól olvasható) | M | penztar-client |
| FR-FM-20 | Alsó középső gombsor (a háttérkép felett): "NAPI JELENTÉS", "ÁTADÓLAP", "KÖRLEVELEK", "HAVI TABLÓK", "KÉSZLETEK", "ENGEDMÉNYEK", "PÉNZTÁRAK", "KILÉPÉS", "ZÁRÁS BEKÉSZÍTÉSE", "SUPERVISOR". | Főmenü.JPG (alsó gombsor, részben olvasható) | S | penztar-client |
| FR-FM-21 | Külön panel-elemek: "NÉVTELEN BEJELENTÉS", "FUTÓFÉNY", "PÉNZTÁR SZÜNET", "KÖRLEVELEK", "Napi stornózott bizonylat darab" (érték pl. 6). | Pénztárak karbantartása képek alsó sávja megerősíti; Főmenü-kontextus | C | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-FM-01 | A főmenü minden menüpontja egyetlen kattintással / billentyűvel elérhető. | Minden FR-FM-07..18 menüpont aktiválható |
| NFR-FM-02 | A fej-panel valós időben frissül (pontos idő). | Idő-kijelző másodperc/perc frissítés (TBD pontos intervallum) |
| NFR-FM-03 | A bejelentkezett pénztáros és egység mindig látható a főmenüben. | Fej-panel folyamatosan kitöltött |

## 6. Adatmodell-erintettseg
- A főmenü maga nem perzisztens entitás; a megjelenített adatok: bejelentkezett felhasználó (Pénztáros/Worker), egység (Branch/pénztár), munkanap (napi dátum), verziószám, napi stornózott bizonylat darabszám.
- SQLite mirror: IGEN a megjelenítéshez szükséges helyi állapotra (bejelentkezett user, aktív pénztár, munkanap) — offline-képesség indokolja.
- Migráció: a főmenü-leírás önmagában nem igényel migrációt. (Konkrét entitás-mezők a forrásból nem olvashatók → TBD.)

## 7. Fuggosegek
- Belső: pénztár-mozgás modul, sztornó modul, pillanatnyi pénztárállás, napi/havi zárás + címletezés, bizonylat-megtekintés, társpénztár-karbantartás, listák, pénztáros/jelszó karbantartás, Western Union/ÁFA modul (mindegyik külön menüpont).
- Külső: TBD (a főmenüből közvetlen külső API nem azonosítható; F3 TERMINÁL és F12 W.UNION valószínűleg POS-terminál ill. Western Union integráció, de a forrás csak a feliratot adja → TBD).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Társpénztár | Egy szervezeti egységen belüli másik pénztár/értéktár, amellyel pénzforgalom bonyolódik. |
| Pillanatnyi pénztárállás | Az aktuális készlet kimutatása valutánként (nyitó/bevétel/kiadás/kez. díj/záró). |
| Címletezés | A pénztár készletének címletenkénti (bankjegy/érme) lebontása zárásnál. |
| Western Union (W.UNION) | Nemzetközi pénzküldési szolgáltatás-tranzakciók kezelése. |
| Futófény | Vélhetően a kijelzőn futó árfolyam/üzenet (forrásból csak gombfelirat). |
| Névtelen bejelentés | Gombfunkció (forrásból csak felirat) — vélhetően anonim bejelentés/visszaélés-jelentés. TBD |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mindkét főmenü-képet (Főmenü.JPG, Főmenü 2.JPG).
- Készíts teljes menüpont-leltárt FR-szinten (fent).
### 9.2 Fazisok
- Fázis 1 — Menü-leltár: minden menüpont + gombsor feliratának dokumentálása. Acceptance: FR-FM-07..21 mind szerepel, forrás-hivatkozással.
- Fázis 2 — Fej-panel adatmezők leltára. Acceptance: FR-FM-01..06 mind dokumentált.
- Fázis 3 — Navigációs modell (lapozás, kilépés). Acceptance: FR-FM-12, FR-FM-13 leírva.
### 9.3 Tesztes
- A spec verifikálható a két képpel való összevetéssel (minden FR-hez egy képi forrás). Implementáció itt nem cél.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | Az alsó F1–F12 sor pontos viselkedése (mit nyit F6, F8, F11)? | Funkció-leképezés a billentyűkhöz. | F6/F8/F11 szürkített vagy üres a képen — szerep-/módfüggő engedélyezés? |
| 2 | A "NÉVTELEN BEJELENTÉS" és "FUTÓFÉNY" gombok pontos funkciója? | Teljes funkció-lefedettség. | A forrás csak feliratot ad. |
| 3 | A két képen eltérő verziószám (Főmenü.JPG: 04.00; Pénztárak karbantartása: 35.25). | Verzió-azonosítás. | A főmenü 04.00, egyes alképernyők 35.25 — eltérő verzió-kijelzés magyarázata TBD. |
| 4 | A menüpontok RBAC-szerinti láthatósága (mely szerep mit lát)? | Jogosultságkezelés. | A forrás csak a bejelentkezett pénztárost mutatja. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (a nem olvasható részek TBD-ként jelölve)
- [x] minden TBD jelölt

VERIFIKACIO: FR=21 db, TBD=4 db, érintett csomag(ok)=penztar-client (+ kozponti-client a pénztár-közötti átadásnál)
