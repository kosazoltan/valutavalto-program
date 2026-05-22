# Modul: Árfolyam-karbantartó hibalista  (forrás: Árfolyam karbantartó hibalista.docx)

## 1. Cel (egy mondat)
Az Árfolyamkezelő (árfolyam-karbantartó) modulra bejelentett hibák és felhasználói igények javítási követelményekké alakítása a forrás-hibalista alapján.

## 2. Scope
### IN
- Sor másolás/beillesztés lapreferencia-hiba javítása.
- Aktív/inaktív valuták kezelése (megjelenítés, inaktiválás).
- Cella-műveletek (másolás, kerekítés, billentyűzet-navigáció, enter-bevitel).
- Ellenőrzés-folyamat (hibalista oszlop, művelet-szétválasztás, log).
- Munkacsoport-létrehozás automatikus feltöltése.
- Currency mező HUF egész.
### OUT
- A teszt-verzió (3.189.0-20260216) belső felépítése — csak hivatkozási kontextus.
- Egyéb modulok (a forrás csak az Árfolyamkezelőre vonatkozik).

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Árfolyamkezelő felhasználó (a forrás nem nevez meg konkrét szerepet; a domain szerint vélhetően Főértéktáros/árfolyamkészítő, de a forrás nem mondja) | Árfolyam-karbantartás | TBD |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Sor másolás/beillesztéskor a lapreferencia maradjon helyes: `$LapT01` ne változzon `$LapT3`-ra. „Copy selected row" → „Paste to selected row" után a beillesztett sor képletei az eredeti lapra hivatkozzanak (E: `=$LapT01!C9+0.1`, G: `=$LapT01!G9+0.1`), ne dobjanak #ERR-t. | Hibalista: „Hibajelentés – Sor másolásakor helytelen lapreferencia"; Várt vs. tényleges tábla | Magas (kritikus, #ERR) | arfolyam-keszito-client |
| FR-2 | A hiba LapZ01 lapon is reprodukálható → a javítás általános legyen a sor másolás/beillesztés funkcióra, nem lapspecifikus. | Megjegyzések: „LapZ01 lapon is reprodukálható" | Magas | arfolyam-keszito-client |
| FR-3 | Működő visszavonás (Ctrl+Z) a beillesztés/szerkesztés visszaállítására (jelenleg nincs, csak kézi javítás). | Megjegyzések: „nincs működő visszavonás (Ctrl+Z)" | TBD | arfolyam-keszito-client |
| FR-4 | A 0-ás lapon csak az aktív valuták jelenjenek meg. | „0-ás lapon csak az aktív valuták jelenjenek meg" | TBD | arfolyam-keszito-client |
| FR-5 | Minden munkalapon csak az aktív valuták jelenjenek meg, és a pénztári programban is. | „Minden munkalap esetében csak az aktív valuták ... és a pénztári programban is" | TBD | arfolyam-keszito-client + penztar-client |
| FR-6 | Valuták inaktívvá tehetők legyenek (jelenleg nem lehet). | „nem tudok inaktívvá tenni valutákat -> tudjak" | TBD | arfolyam-keszito-client |
| FR-7 | A cellákat lehessen másolni. | „A cellákat lehessen másolni. 👍" | TBD | arfolyam-keszito-client |
| FR-8 | Kerekítés matematikai szabály szerint. | „Kerekítés matematikai szabály szerint 👍" | TBD | arfolyam-keszito-client |
| FR-9 | Ellenőrzés elvégzésekor egy új oszlopban jelenjen meg a hibalista. | „Ellenőrzés elvégzésekor egy új oszlopban hibalista" | TBD | arfolyam-keszito-client |
| FR-10 | Az Ellenőrzés, Mentés, Szétküldés műveletek szétválasztása (külön gomb/lépés). | „Ellenőrzés, Mentés, Szétküldés szétválasztása" | TBD | arfolyam-keszito-client |
| FR-11 | Log pénztáranként (név, dátum). | „Log pénztáranként (név,dátum)" | TBD | arfolyam-keszito-client + backend |
| FR-12 | Billentyűzet nyilaival lehessen a cellák között navigálni. | „Szeretnék a billentyűzet navigációs nyilaival közlekedni a cellák között" | TBD | arfolyam-keszito-client |
| FR-13 | Bevitelnél enterrel aktiválható legyen a cella és egyből írható (jelenleg: kattintás → szövegmező → enter). Cél: egér nélküli gyors, hatékony kezelés. | „bevitelkor tudjam enterrel aktiválni a cellát ... egér használata nélkül is gyorsan" | TBD | arfolyam-keszito-client |
| FR-14 | Új munkacsoport létrehozásakor automatikusan kerüljenek be az elszámoló árfolyamok és a valuta-elnevezések a megfelelő oszlopokba. | „Ha új munkacsoportot hozok létre automatikusan tegye be az elszámoló árfolyamokat és a valuta elnevezéseket" | TBD | arfolyam-keszito-client |
| FR-15 | A Currency mező HUF érték egész szám legyen. | „Currency mező HUF egész" | TBD | arfolyam-keszito-client |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Gyors, egér nélküli adatbevitel támogatása | Cella-navigáció + enter-bevitel csak billentyűzettel működik (FR-12, FR-13) |
| NFR-2 | Adatintegritás másolásnál | Beillesztett képletek 0 #ERR a lapreferencia-megőrzés miatt (FR-1) |

## 6. Adatmodell-erintettseg
- Valuta aktív/inaktív állapot (FR-4, FR-5, FR-6) → valuta entitás `is_active`-jellegű mező érintett. Pontos Postgres-mező/SQLite-mirror/migráció a forrásból nem derül ki → TBD.
- Pénztárankénti log (FR-11) → log/audit tárolás érintett; konkrét séma TBD.
- A többi FR UI/számítási logika, nem feltétlen adatmodell. (Migráció szükségessége: TBD.)

## 7. Fuggosegek
- Belső modul: Árfolyamkezelő táblázat-motor (cella/képlet/lapreferencia), valuta-nyilvántartás, pénztári program (FR-5 megjelenítés).
- Külső API: nincs a forrásban.
- Adatbázis: valuta aktív-flag, log-tárolás (séma TBD).

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| LapT01 / LapZ01 / 0-ás lap | Az Árfolyamkezelő munkalapjai; a képletek lapra hivatkoznak (`$LapT01!C7`). |
| Copy/Paste selected row | Toolbar-funkció sor másolásra/beillesztésre; visszajelez („Sor 7 kimásolva"). |
| #ERR | Cella-hibaüzenet érvénytelen képlet/lapreferencia esetén. |
| Elszámoló árfolyam | Munkacsoport-létrehozáskor automatikusan betöltendő árfolyam-adat. |
| Munkacsoport | Új lap/csoport, amelybe az elszámoló árfolyamok és valutanevek automatikusan kerülnek. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A modul az arfolyam-keszito-client. FR-1/FR-2 a legkritikusabb (#ERR-t okoz). A „👍"-vel jelölt tételek (FR-7, FR-8, FR-13a) felhasználói jóváhagyást kaptak, prioritás-jelzésként.
### 9.2 Fazisok (acceptance criteria-val)
- Fázis 1 (kritikus): FR-1 + FR-2 lapreferencia-megőrzés. AC: sor 7 (LapT01) → sor 9 beillesztés után E=`=$LapT01!C9+0.1`, G=`=$LapT01!G9+0.1`, 0 db #ERR; LapZ01-en is helyes.
- Fázis 2 (aktív valuták): FR-4/FR-5/FR-6. AC: inaktivált valuta eltűnik minden munkalapról és a pénztári programból; valuta inaktiválható UI-ból.
- Fázis 3 (cella-UX): FR-7, FR-8, FR-12, FR-13, FR-15. AC: cella másolható; kerekítés matematikai; nyíl-navigáció + enter-bevitel egér nélkül; HUF egész.
- Fázis 4 (ellenőrzés/log): FR-9, FR-10, FR-11. AC: ellenőrzés új oszlopba hibalistát ír; Ellenőrzés/Mentés/Szétküldés külön; log pénztáranként (név+dátum).
- Fázis 5: FR-3 (Ctrl+Z), FR-14 (munkacsoport auto-feltöltés).
### 9.3 Tesztes
- FR-1 regressziós teszt a forrás várt/tényleges táblával (E és G cella sor 7→9). FR-4/5/6 megjelenítési teszt aktív/inaktív valutával. FR-12/13 billentyűzet-UX teszt. Többi: AC-alapú teszt fázisonként.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | Mely szerepkör/RBAC kezeli az Árfolyamkezelőt? | Jogosultság | A forrás nem nevez meg szerepet |
| TBD-2 | „Munkacsoport" pontos fogalma és hol jönnek az elszámoló árfolyamok (FR-14)? | Auto-feltöltés forrása | A forrás nem részletezi |
| TBD-3 | Log pénztáranként (FR-11): hova kerül (DB/audit), mely eseményekre? | Adatmodell + compliance | Csak „név, dátum" van megadva |
| TBD-4 | „Szétküldés" (FR-10) hová/kiknek küld? | Folyamat | Nincs részletezve |
| TBD-5 | Inaktív valuta a pénztári programban (FR-5): retroaktív vagy csak új tranzakciókra? | Készlet/megőrzés (Pmt./NAV) | Nincs a forrásban |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (a kért funkciók a forrás szövegéből, részletek TBD)
- [x] minden TBD jelölt

VERIFIKACIO: FR=15 db, TBD=5 db, érintett csomag(ok)=arfolyam-keszito-client (+ penztar-client FR-5, + backend FR-11)
