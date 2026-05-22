# Modul: Régi Delphi valutaprogram — Pénztárak közötti pénzmozgás  (forrás: Képernyőképek/Pénztár választása.JPG, Pénztár választása 2..JPG, Társpénztár kiválasztása új pénztár felvétele.jpeg, Pénztárak karbantartása .jpeg, Pénztárak karbantartása 2.jpeg, Pénztárak közötti pénzforgalom főmenüje.jpeg, Pénztárak közötti forgalom főmenüje.jpeg, Szállítás pénztárak között menü.jpeg, Pénztárak közötti szállításhoz.jpeg, Pénz átvétele egy egységtől menü .jpeg, Pénztárátvétele egy egységtől menü2.jpeg)

## 1. Cel (egy mondat)
A régi valutaprogram pénztárak/egységek közötti pénzmozgás-funkciói (társpénztár-választás, pénztár-karbantartás, átadás/átvétel főmenük, szállítás-űrlap, pénz átvétele egy egységtől) hűen leírva.

## 2. Scope
### IN
- Társpénztár-választó lista (két lapozott állapot + új pénztár felvétel gombbal).
- Pénztárak karbantartása rács (oszlopok + művelet-gombok).
- "Pénztárak közötti pénzforgalom főmenüje" / "Pénztárak közötti forgalom főmenüje" menülisták.
- Szállítás pénztárak között űrlap (társpénztár, szállító, plomba, megjegyzés).
- "Pénz átvétele egy egységtől" almenü.
### OUT
- Maga a könyvelés/tranzakció-végrehajtás logikája (nem látszik számértékkel).
- Kezelési díj átadás/átvétel részletei (külön EXCMD MD: kezelés-címletezés-engedélyezés).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Pénztáros | Társpénztár-választás, szállítás-űrlap kitöltése, pénz átvétele/átadása | TBD |
| Értéktáros / Főértéktáros | Értéktár felé/től történő mozgás (a listában "ÉRTÉKTÁR" célok) | TBD |
| Adminisztrátor (pénztár-karbantartás) | Pénztár adatainak módosítása, új pénztár felvétele, pénztár törlése | TBD (vélhetően supervisor/jelszavas) |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-PM-01 | Társpénztár-választó dialógus címe "VÁLASSZA KI A TÁRSPÉNZTÁRT", oszlopai: SZÁM, MEGNEVEZÉS; gombok: "EZT VÁLASZTOM", "NEM VÁLASZTOK", "ÚJ PÉNZTÁR FELVÉTELE". | Pénztár választása.JPG | M | penztar-client, kozponti-client |
| FR-PM-02 | A társpénztár-lista görgethető; tartalmaz numerikus és betűkódos azonosítókat. Megfigyelt sorok: 71 GYULA BELVAROS, 50 DEBRECEN ÉRTÉKTÁR, 63 NYÍREGYHÁZI ÉRTÉKTÁR, 0074 TESCO BÉKÉSCSABA, FRB FORINT MOZGÁS RB, ERB FIXING VALUTA MOZGÁS RB, TRB EGYEDI KÖTÉS RB, 76 TER. KÖZÖTTI MOZGÁS RB, JRB BÉKÉSCSABA BELVÁR, 77 JUTALÉK BEFIZETÉS RB, MNB GYULA TESCO, MNB. | Pénztár választása.JPG | M | penztar-client |
| FR-PM-03 | A lista további sorai (lapozott állapot): TH TÖBBLET-HIÁNY PÉNZTÁR, 78 OROSHÁZA TESCO, 79 SZARVAS TESCO, 105 BÉKÉSCSABA BELVÁROS II., PRB POS ÁTVÉTEL BANKTÓL, 143 (NEW) PÉCS PLAZA, WU UJ PÉNZTÁR, UL WU ELLÁTMÁNY, TV UTON LÉVŐ PÉNZTÁR, 20 TÉVES KÖNYVELÉS, 145 SZEGEDI ÉRTÉKTÁR, KAPOSVÁR ÉRTÉKTÁR. | Pénztár választása 2..JPG | M | penztar-client |
| FR-PM-04 | Szűkített társpénztár-lista (pl. új pénztár felvétel kontextus): 75 BÉKÉSCSABA ÉRTÉKTÁR, TH TÖBBLET-HIÁNY PÉNZTÁR, 1 FŐPÉNZTÁR. | Társpénztár kiválasztása új pénztár felvétele.jpeg | S | penztar-client |
| FR-PM-05 | Pénztár-karbantartás rács címe "PÉNZTÁRAK KARBANTARTÁSA", oszlopai: PÉNZTÁR (kód), PÉNZTÁR MEGNEVEZÉSE, PÉNZTÁR CIME, TELEFONSZÁM. | Pénztárak karbantartása .jpeg, Pénztárak karbantartása 2.jpeg | M | penztar-client |
| FR-PM-06 | Pénztár-karbantartás megfigyelt sorai: 105 <FIOK_NEV> (<CIM>, 06XXXXXXXXX), 75 ÉRTÉKTÁR, TH TÖBBLET-HIÁNY PÉNZTÁR, 1 FŐPÉNZTÁR. | Pénztárak karbantartása .jpeg/2.jpeg | M | penztar-client |
| FR-PM-07 | Pénztár-karbantartás művelet-gombjai: "ADATOK MÓDOSÍTÁSA", "ÚJ PÉNZTÁR FELVÉTELE", "PÉNZTÁR TÖRLÉSE", "VISSZA A FŐMENÜRE". | Pénztárak karbantartása .jpeg/2.jpeg | M | penztar-client |
| FR-PM-08 | "Pénztárak közötti pénzforgalom főmenüje" menüpontjai: "Pénz átvétele egy egységtől", "Pénz átadása egy egységnek", "Kezelési díjak átadása-átvétele", "Horvát kuna beküldése", "E-kereskedelem pénzforgalma", "Vissza a valutaprogram főmenüjére". | Pénztárak közötti pénzforgalom főmenüje.jpeg, Pénztárak közötti forgalom főmenüje.jpeg | M | penztar-client |
| FR-PM-09 | Szállítás-űrlap (társpénztárak közötti) mezői: TÁRSPÉNZTÁR (kód + megnevezés, pl. 75 BÉKÉSCSABA ÉRTÉKTÁR), SZÁLLÍTÓ NEVE, PLOMBASZÁM, MEGJEGYZÉS; gombok: "KÖNYVELHETŐ", "MÉGSEM". | Szállítás pénztárak között menü.jpeg, Pénztárak közötti szállításhoz.jpeg | M | penztar-client |
| FR-PM-10 | "Pénz átvétele egy egységtől" almenü pontjai: "Pénz átvétele az értéktártól", "Teljes készlet visszavétele az értéktártól", (egy szürkített/takart sor: "Kezelési díjak átadása-átvétele"), "Horvát kuna beküldése", "E-kereskedelem pénzforgalma", "Vissza a valutaprogram főmenüjére". | Pénz átvétele egy egységtől menü .jpeg, Pénztárátvétele egy egységtől menü2.jpeg | M | penztar-client |
| FR-PM-11 | A szállítás-űrlap a társpénztár adatát előre kitöltve mutatja a kiválasztott egység alapján. | Szállítás pénztárak között menü.jpeg (TÁRSPÉNZTÁR: 75 BÉKÉSCSABA ÉRTÉKTÁR előkitöltve) | S | penztar-client |
| FR-PM-12 | A "PÉNZTÁRAK KARBANTARTÁSA" képernyő alsó funkcióbillentyű-sora azonos a főmenüével (F1 ÁRFOLYAM ... Esc KILÉPÉS), és tartalmaz "FUTÓFÉNY", "KÖRLEVELEK", "PÉNZTÁR SZÜNET", "NÉVTELEN BEJELENTÉS", "Napi stornózott bizonylat darab" elemeket. | Pénztárak karbantartása .jpeg/2.jpeg | C | penztar-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-PM-01 | A társpénztár-lista hosszú is lehet (görgethető), keresés/lapozás szükséges. | Görgetősáv jelen van a listán |
| NFR-PM-02 | A szállítás csak akkor könyvelhető, ha a kötelező mezők kitöltöttek (szállító, plomba). | "KÖNYVELHETŐ" gomb feltétele — TBD pontos validáció |
| NFR-PM-03 | Pénztár-karbantartás műveletek jogosultsághoz kötöttek. | TBD (forrásból nem olvasható konkrét gate) |

## 6. Adatmodell-erintettseg
- Entitás: Pénztár/Társpénztár (mezők a karbantartás-rácsból: kód, megnevezés, cím, telefonszám). Postgres: Branch / pénztár-tábla; SQLite mirror IGEN (offline választáshoz/könyveléshez).
- Entitás: Pénztárak közötti szállítás/átadás-átvétel (mezők: forrás/cél társpénztár, szállító neve, plombaszám, megjegyzés, irány). SQLite mirror IGEN (offline rögzítés + outbox sync).
- Speciális gyűjtő-pénztárak/kódok a listából: TH (többlet-hiány), TV (úton lévő pénztár), 20 (téves könyvelés), PRB (POS átvétel banktól), FRB/ERB/TRB/JRB (mozgás-kategóriák). Migráció szükséges lehet ezek seedeléséhez — TBD a teljes lista.

## 7. Fuggosegek
- Belső: főmenü ("PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL" menüpont), kezelési díj modul, pillanatnyi pénztárállás, készlet-modul.
- Külső: TBD (POS átvétel banktól = banki integráció? Western Union? — a forrás csak kód-feliratot ad).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Társpénztár | A pénzmozgás másik oldalán álló pénztár/értéktár/gyűjtő-kód. |
| Értéktár | Központi készlettartó egység, ahonnan/ahová a pénztár pénzt vesz át/ad. |
| Plombaszám | A szállítmány (zacskó/doboz) lezáró plombájának azonosítója — szállítás kötelező adata. |
| TH (Többlet-hiány pénztár) | Technikai gyűjtő-pénztár a többlet/hiány elszámolásához. |
| TV (Úton lévő pénztár) | Technikai pénztár a szállítás alatt lévő (még át nem vett) pénzre. |
| Téves könyvelés (20) | Technikai pénztár hibás könyvelések korrekciójához. |
| POS átvétel banktól (PRB) | Banki/POS forrásból érkező pénz átvételének technikai célja. |
| Horvát kuna beküldése | Külön menüpont a HRK valuta központba küldésére (kivezetett valuta — TBD aktuális státusz). |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be mind a 11 forrásképet; készíts társpénztár-kód-leltárt (FR-PM-02..04) és menü-leltárt (FR-PM-08, FR-PM-10).
### 9.2 Fazisok
- Fázis 1 — Társpénztár-modell: kódok + megnevezések leltára. Acceptance: minden látható sor szerepel FR-ként, forrás-hivatkozással.
- Fázis 2 — Pénztár-karbantartás: rács-oszlopok + 4 művelet-gomb. Acceptance: FR-PM-05..07 dokumentált.
- Fázis 3 — Mozgás-menük + szállítás-űrlap: átadás/átvétel struktúra + űrlapmezők. Acceptance: FR-PM-08..11.
### 9.3 Tesztes
- Forrás-kép vs. spec összevetés (minden FR-hez kép). Implementáció nem cél ebben a fázisban.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | "Pénztárak közötti pénzforgalom főmenüje" vs. "Pénztárak közötti forgalom főmenüje" — ugyanaz a képernyő két verziója? | Duplikáció vagy két külön nézet azonosítása. | A menüpontok azonosak; vélhetően ugyanaz, eltérő felbontás/cím. |
| 2 | A szállítás-űrlap "KÖNYVELHETŐ" gomb pontos validációi (mely mező kötelező)? | Adatminőség, AML/szállítás-követés. | A forrás üres mezőket mutat; a kötelezőség nem olvasható. |
| 3 | A teljes társpénztár/technikai-kód lista (a görgetett részeken túl)? | Hiánytalan seed. | Csak a látható sorok vannak meg. |
| 4 | Mely szerep végezhet pénztár-törlést / új pénztár felvételt? | Jogosultság-kapuk. | A forrás nem mutat jogosultság-ellenőrzést. |
| 5 | "E-kereskedelem pénzforgalma" és "Horvát kuna beküldése" tényleges aktív funkció-e ma? | Hatókör/kivezetés. | Forrásból csak menüfelirat. |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (nem olvasható részek TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=12 db, TBD=5 db, érintett csomag(ok)=penztar-client, kozponti-client
