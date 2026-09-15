# FK-112: "Készletek, címletek" nézet korrekciója — fix címlet-oszlopok, árfolyam-alapú összesítő

## 1. Cél
A FK-111-gyel leszállított "Készletek, címletek" fül (`/central/received-data`) két ponton tér el az eredeti specifikációtól: (1) az oszlopfejlécek pozíció-alapúak ("1."–"6.") a legacy rendszer fix, névérték-alapú oszlopai helyett; (2) az összesítő sáv nem tartalmaz árfolyam-alapú, valuták közötti forint-összesítést. Ez a kérés mindkettőt pótolja.

## 2. Scope

### IN
- Fix, minden valutánál azonos névérték-oszlopok bevezetése a táblázatban, katalógus-alapú "–" jelöléssel a nem létező címleteknél, és egy "Egyéb" gyűjtőoszloppal a törtrészes névértékekre (FR-1).
- Árfolyam-alapú "Valuta érték" és "Összesen" mező hozzáadása az összesítő sávhoz, a meglévő árfolyam-lekérdezési mechanizmus felhasználásával (FR-2).

### OUT
- **TILOS** a bankjegy/érme azonos névértékű ütközésére külön kezelést építeni — a jelenlegi aktív katalógus szerint ilyen kombináció nem fordul elő; ha a jövőben mégis felmerülne, az külön kérés tárgya lesz.
- **TILOS** az "időszak" (dátum-tartomány) szűrés vagy bármilyen más cég/tenant adatainak bevonása ("együtt" nézet) bevezetése.
- **TILOS** a meglévő "Átadólap-egyeztetés" fül, a `TransferReconciliationController`, vagy a Darius-kontroller/validátor bármilyen módosítása.
- **TILOS** a záráskori snapshot adatmodell (`daily_denomination_snapshot`) módosítása vagy bővítése bármilyen árfolyam-mezővel — az árfolyam mindig lekérdezésen alapul, nem kerül tárolásra a snapshot rekordban.
- **TILOS** új route/menüpont létrehozása.

## 3. RBAC
Változatlan: Főértéktáros, Belső ellenőr, Admin.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Csomag | Acceptance |
|---|---|---|---|---|
| FR-1 | Fix, katalógus-alapú címlet-oszlopok | FELTERKEPEZES_280 Q1/Q2 | backend + kozponti-client | Adott: a mai pozíció-alapú ("1."–"6.") oszlopfejlécek. Amikor: a backend válasz kiegészül a hívó cég aktív címlet-katalógusával (a meglévő `denomination_allowed` tábla, `findActiveByCompanyId` alapján — devizánként az engedélyezett névértékek uniója). Akkor: a táblázat oszlopfejlécei mindig a 14 fix névérték, csökkenő sorrendben (20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1); minden cella a tényleges darabszámot mutatja, ha a valutának a katalógus szerint van ilyen névértéke (0 is lehet); "–" jelenik meg, ha a valutának nincs ilyen névértéke a katalógusban; egy külön "Egyéb" oszlop gyűjti a törtrészes (`FRACTIONAL_FACE_VALUE` jelzésű) tételeket, hogy egyik se vesszen el a válaszból; a táblázat megtartja a meglévő alternáló sorszínezést (`.data-grid` osztály, FK-050 minta). |
| FR-2 | Árfolyam-alapú "Valuta érték" és "Összesen" mező | FELTERKEPEZES_280 Q3/Q4 | backend + kozponti-client | Adott: a mai összesítő sáv "Forint érték / Valutanemek száma / Összes darab". Amikor: a nem-HUF sorokra lekérdezzük az adott záráskori dátumhoz tartozó árfolyamot a meglévő `MnbExchangeRateService.getRatesForDate` mechanizmussal; ha az adott napra nincs MNB-árfolyam (hétvége, ünnepnap), a legutóbbi elérhető korábbi napig visszafelé kell keresni (a `DecadeReportService.resolveUnitRate` mintája szerint); az MNB által nem jegyzett devizákra a kézi elszámolási árfolyam-history szolgál forrásul (`MnbSettlementRateService.findSettlementRateAsOf`, FK-028 minta). Akkor: az összesítő sáv három mezőt mutat — "Valuta érték" (a nem-HUF sorok forintra átszámított összege), "Forint érték" (változatlanul a HUF sor saját összege), "Összesen" (a kettő együtt); minden átszámított devizasorhoz megjelenik a felhasznált árfolyam dátuma és forrása (MNB / kézi elszámolási); ha egy adott devizára semmilyen forrásból nem található árfolyam, az adott sor "nincs adat" jelzést kap az összesítésben, de ez **nem** dobja el a teljes választ — a táblázat és a többi sor változatlanul megjelenik. |

## 5. Adatmodell-érintettség
Nincs új tábla/migráció. A backend válasz DTO bővül: (a) a katalógus-alapú engedélyezett névértékek listájával devizánként, (b) devizánkénti árfolyam-mezőkkel (felhasznált árfolyam, dátuma, forrása).

## 6. Kockázatok / TBD
| # | Kérdés / kockázat |
|---|---|
| 1 | A fő lekérdező metódus ma `@Transactional(readOnly = true)`; az árfolyam-lekérdezés írhat az árfolyam-gyorsítótárba (SOAP-eredmény mentése). Implementáció közben el kell dönteni: `REQUIRES_NEW` propagáció az árfolyam-hívásra, vagy a readOnly megszüntetése a fő metóduson — ne ütközzön a kettő. |
| 2 | Ritkán lekérdezett, régebbi dátumoknál a lekérdezés gombnyomás több élő külső (SOAP) hívást indíthat, ami lassabb válaszidőt eredményezhet — elfogadható-e alapból, vagy kell hozzá egy explicit "árfolyam frissítése" folyamatjelző a felületen. |
| 3 | Ha egy névérték időközben inaktívvá válik a katalógusban, de egy korábbi záráskori adatban még szerepelt, a fix oszlop-készlet kezelje ezt helyesen (ne tűnjön el, ne kapjon hibásan "–"-t) — implementáció közben eldöntendő. |

## 7. Végrehajtási utasítás
1. `cd D:\repo\valutavalto-program`, `git checkout -b feature/beerkezett-cimletek-korrekcio`
2. `git log --all --grep="FK-112"` + `git branch -a | grep -i fk112` — kollízió-ellenőrzés már megtörtént (2026-09-13, tiszta eredmény), de commit előtt ismételd meg.
3. Fázis 1: backend (FR-1 katalógus-mező, FR-2 árfolyam-integráció). Fázis 2: frontend (fix oszlopok, "Egyéb" oszlop, összesítő sáv bővítése).
4. DoD: lint, `mvn verify`, `npm run test`, code review, merge/push/deploy.

---
FR-ek száma: 2 db | Csomagok: backend, kozponti-client
