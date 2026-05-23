# ERTEKTAR + SZERVER legacy alrendszer modul-térkép

> Készült: 2026-05-23. **Ground truth = a tényleges `Anti/SZERVER/_extracted/*` Delphi-forrás.**
> Korrekció: a korábbi `03-FELDOLGOZAS-KESZ.md` tévesen állította, hogy az ERTEKTAR-nak
> „nincs .pas (1 fájl)" és a SZERVER „mind duplikátum, nincs új egyedi forrás". A tényleges
> fájlrendszer-ellenőrzés (epistemológiai direktíva) **cáfolta ezt**:
> - **ERTEKTAR/etdll**: 56 modul, 180 .pas — valódi értéktár-forrás.
> - **SZERVER/ujdll**: 36 modul, 235 .pas — valódi központi-szerver/adatgyűjtő forrás.

## Generált modul-MD-k
- `EXCMD/legacy/modules-ertektar/*.md` — **56** értéktár modul (mély: export + .pas + SQL + üzenet + DFM)
- `EXCMD/legacy/modules-szerver/*.md` — **36** szerver modul (ugyanaz a mélység)
- Generátor: `scripts/legacy-ertektar-md-generator.py` (argv: ROOT OUT SUBSYS)

## ERTEKTAR — értéktár-EGYEDI modulok (nincs VALUTA-megfelelő)
| Modul | Funkció (forrásból) | Jelenlegi program (verifikálandó) |
|---|---|---|
| RATECTRL | értéktáros engedélyezés-kontroll (ENGEDELY tábla: mely bizonylatok/kedvezmények engedélyezettek; "EZ AZ IRODA NEM ÉRTÉKTÁR!") | ❓ SupervisorPin / approval flow |
| RATEPERM | kedvezmény + árfolyam-eltérés engedélyezése pénztáraknak (értéktáros) | ❓ discount/rate approval |
| PENZTARAK | pénztárak kezelése értéktár-szintről | ❓ Branch/cashdesk admin |
| IRARFOLY | iroda-árfolyam | ❓ branch rate |
| GETELLEN | get ellenőrzés | ❓ |
| HRKATVEVO / HRKCIMLET | HRK értéktári átvevő + címletezés | ❓ e-kereskedelem |
| NIFVAL / PICTLOAD | nif valuta / kép-betöltés | ⚙️ |

A többi ~47 ERTEKTAR-modul az értéktár-kontextusú variánsa a VALUTA pénztári moduloknak
(cimlet, napzar, storno, atadolap, listak, napkonyv stb.) — a vault-oldali zárás/címletezés/
átadás-átvétel.

## SZERVER — központi-szerver / adatgyűjtő EGYEDI modulok (33)
| Modul | Funkció (forrásból) | Jelenlegi program (verifikálandó) |
|---|---|---|
| ADATGYUJTO | adatgyűjtő (irodák→központ) | ❓ central sync |
| ATLAGARF | átlagárfolyam-riport (Excel kivitel) | ✅ AverageRateReportService (gyanú) |
| BANKFORG | banki forgalom | ✅ BankTurnoverReportService (gyanú) |
| BEERKCTRL / BEERKEZES | szállítmány-beérkezés kontroll/rögzítés | ❓ ShipmentRequest/receiving |
| BEJELENTES | NAV/MNB bejelentés | ✅ NavReport/MnbReport (gyanú) |
| DBOOKCTRL | napkönyv-kontroll | ✅ DailyJournalService (gyanú) |
| DOLGOZOK | dolgozó-törzs | ✅ Employee (gyanú) |
| FORGALOMDISP / KESZLETDISP / GETDISP / DATADISP / TRBDISP / WUNIDISP / STORNODISP / KEZDTRANZDISP | megjelenítő/riport képernyők | ❓ reports modul |
| GETUZLET | üzlet/iroda lekérés | ✅ Branch |
| IRTMK | iroda törzs-karbantartás | ✅ BranchPage admin |
| JUTSZAMITO / JUTSZAZALEK | jutalék-számító / százalék | ✅ CommissionRate (gyanú) |
| MNBGYUJTO / MNBHIBAK | MNB adatgyűjtő / hibák | ✅ MnbReport (gyanú) |
| PTARKOZOTT | pénztárközi (átvezetés) | ✅ Transfer (gyanú) |
| SUMWUAFA / WUAFATRANZ / WESTERN | Western Union + ÁFA | ✅ WesternUnion modul (gyanú) |
| USERBELEP | user-belépés | ✅ auth/login |
| ZARASCTRL | zárás-kontroll | ✅ ClosingService (gyanú) |
| HOVALASZ / HRKSERVER / IMPORT / TRANZAKC / UNPACKER / ADATGYUJTO | szerver-infra | ⚙️ backend/sync |

## Következő lépés
A „gyanú/❓" jelöléseket a **tényleges jelenlegi kód ellen** kell verifikálni (file:line),
NEM a névből következtetni. A verifikáció után csak a VALÓS hiányt implementáljuk.
