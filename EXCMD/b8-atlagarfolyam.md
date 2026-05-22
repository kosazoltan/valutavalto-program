# Modul: Átlagárfolyam riport  (forrás: `Felmérés/Valuta/Cégcsoport felmérése/Személyes találkozó összefoglalók, kapott dokumentumok, képernyőképek/Dokumentumok/AcAtlagarf.xlsx`, `.../Atlagarfolyam.xlsx`)

## 1. Cel (egy mondat)
A régi program átlagárfolyam-számító riportjának STRUKTÚRÁJÁT leírni — a forrásfájlok azonban régi OLE2 (Excel 97-2003) binary formátumúak, így a tényleges lap- és oszlopstruktúra nem nyerhető ki, csak a fájl-szintű tény dokumentálható.

## 2. Scope
### IN
- Átlagárfolyam riport megléte mint funkció (valutánkénti súlyozott/egyszerű átlag árfolyam egy időszakra).
- Két forrásfájl ténye: `AcAtlagarf.xlsx` (16 KB) és `Atlagarfolyam.xlsx` (35 KB) — mindkettő OLE2 binary.
### OUT
- A lapok, oszlopfejlécek, képletek tényleges tartalma → TBD (nem kinyerhető a binary formátum miatt).
- Az átlagolás algoritmusa (egyszerű vs vétel/eladás-súlyozott vs mennyiség-súlyozott) → TBD.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
|---|---|---|
| Főértéktáros | Átlagárfolyam riport megtekintés/generálás | HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | Átlagárfolyam riport (elszámolás, haszon ellenőrzés) | EXECUTIVE / INTERNAL_AUDITOR |
| admin | Minden | ADMIN |

## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
|---|---|---|---|---|
| FR-1 | Átlagárfolyam riport mint önálló funkció létezik (két külön munkafüzet a régi rendszerben) | `AcAtlagarf.xlsx`, `Atlagarfolyam.xlsx` (fájl-szintű tény) | M | frontend-react, kozponti-client |
| FR-2 | Valutánkénti átlagárfolyam egy adott időszakra | a fájlnevek + modul-cél (átlagárfolyam) | M | frontend-react |
| FR-3 | A részletes lap/oszlop-struktúra a megnyitható eredeti munkafüzetből pótolandó | mindkét fájl OLE2 binary → TBD | C | TBD |

## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
|---|---|---|
| NFR-1 | Multi-tenant + multi-currency | minden átlag companyId + currency dimenzióval |
| NFR-2 | Árfolyam-frissesség (a forgalmi adat, amelyből az átlag számol) | TBD (a forrásból nem derül ki az időablak) |

## 6. Adatmodell-erintettseg
- Átlagárfolyam = aggregáció tranzakciókból (vétel/eladás árfolyam súlyozva mennyiséggel vagy egyszerű átlag) valuta × időszak dimenzión.
- Postgres: read-only nézet/aggregáció a tranzakció + árfolyam entitásokból.
- SQLite mirror: NEM (cég-szintű riport). Migráció: TBD (a meglévő séma alkalmas-e — ellenőrzendő).

## 7. Fuggosegek
- Belső: tranzakció modul, árfolyam modul.
- Külső API: nincs (kizárólag belső tranzakciós adatból).
- Adatbázis: Postgres.

## 8. Domain-szotar
| Fogalom | Magyarazat |
|---|---|
| Átlagárfolyam | Egy valuta adott időszakra számított átlagos vétel/eladási árfolyama |
| Súlyozott átlag | Mennyiséggel/forgalommal súlyozott árfolyam-átlag (algoritmus TBD) |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- A két forrásfájl OLE2 binary (`.xlsx` kiterjesztés ellenére Excel 97-2003 formátum, magic `D0CF11E0`). Konvertáld először modern xlsx-szé (LibreOffice/Excel) a struktúra kinyeréséhez — NE találgasd az oszlopokat.
### 9.2 Fazisok
- F1: Forrás-konverzió + struktúra-kinyerés (előfeltétel) — acceptance: lapok és oszlopfejlécek dokumentálva, az FR-3 TBD feloldva.
- F2: Valutánkénti átlagárfolyam riport (FR-1..2) — acceptance: valuta × időszak átlag megjelenik (az F1 után pontosított képlettel).
### 9.3 Tesztes
- Unit: átlag-számítás (egyszerű + súlyozott), üres időszak edge-case.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A riport lap- és oszlopstruktúrája | spec-alap | mindkét xlsx OLE2 binary, zipfile-lal nem kinyerhető |
| 2 | Átlagolás algoritmusa (egyszerű vs súlyozott) | helyes átlagérték | a forrásból nem derül ki |
| 3 | `AcAtlagarf` vs `Atlagarfolyam` különbsége | két fájl szerepe | feltételezhetően "Ac" = egy cég/aliasz, de NEM bizonyított → TBD |
| 4 | Időablak (napi/havi/egyedi tartomány) | aggregációs dimenzió | nem kinyerhető |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (binary tartalom = TBD, nem találgatva)
- [x] minden TBD jelölt
VERIFIKACIO: FR=3 db, TBD=4 db, érintett csomag(ok)=frontend-react, kozponti-client
