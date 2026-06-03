# Modul: Átlagárfolyam riport

<system_context>
## Rendszerkontextus és Cél
A régi program átlagárfolyam-számító riportjának STRUKTÚRÁJÁT leírni. Bár a legacy Excel állományok (`AcAtlagarf.xlsx` és `Atlagarfolyam.xlsx`) jelszóval védett OLE2 binary formátumúak, a Delphi/Pascal forráskódok (`unit2.pas`) és az új Java backend (`AverageRateReportService.java`) alapján a teljes üzleti és adatbázis-logika, valamint a riportok struktúrája pontosan meghatározásra és implementálásra került.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Főértéktáros | Átlagárfolyam riport megtekintés/generálás | HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | Átlagárfolyam riport (elszámolás, haszon ellenőrzés) | EXECUTIVE / INTERNAL_AUDITOR |
| Adminisztrátor | Minden | ADMIN |

## Hatókör (Scope)
### IN
- Átlagárfolyam riport generálása: valutánkénti súlyozott átlagárfolyam számítása egy tetszőleges időszakra.
- Külön vétel (BUY) és eladás (SELL) átlagok vezetése valutánként.
- Szűrési lehetőségek: cég (companyId), időszak (from/to), opcionális iroda (branchId), és opcionális valuta (currencyId).
- Tranzakciók aggregálása dinamikusan, kiszűrve a nem lezárt vagy duplikált konverziós tranzakciókat.

### OUT
- A legacy Excel állományok közvetlen bináris olvasása (a modern implementáció SQL-alapú aggregációval váltja fel).
- Készletértékelés haszonszámítás nélkül (a haszonszámítás a WAC haszon modul feladata).

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | Multi-tenant + multi-currency | minden átlag companyId + currency dimenzióval |
| NFR-2 | Árfolyam-frissesség | Dinamikus lekérdezés a lezárt tranzakciókból, valós időben |
| NFR-3 | Kerekítési pontosság | Az átlagárfolyam 4 tizedesjegyre kerekítve (HALF_UP) |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-1 Átlagárfolyam riport megléte
- **Leírás**: Súlyozott átlagárfolyam riport generálása a kiválasztott időszakra és cégre.
- **Forrás**: `AcAtlagarf.xlsx`, `Atlagarfolyam.xlsx` (fájl-szintű tény), `AverageRateReportService.java`
- **Prio**: M
- **Csomag/Komponens**: frontend-react, kozponti-client, backend
- **Bemenő adatok**: Cég ID, Kezdő dátum, Vég dátum, opcionális iroda szűrő, opcionális valuta szűrő
- **Kimenet / Visszajelzés**: Valutánkénti összesített táblázat (vétel/eladás darabszám, valutamennyiség, HUF ellenérték, súlyozott átlagárfolyam)
- **Validációk és Kényszerek**: Kezdő dátum nem lehet későbbi, mint a vég dátum. Cégazonosító megadása kötelező.

### FR-2 Súlyozott átlagárfolyam számítás
- **Leírás**: A vétel és eladás súlyozott átlagárfolyamának számítása a teljesített tranzakciók alapján.
- **Forrás**: `unit2.pas` (legacy számítási elv: `_va := int(100*_ve/_vb)` és `_ea := int(100*_ee/_eb)`), `AverageRateReportService.java`
- **Prio**: M
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Completed tranzakciók HUF összege és valutamennyisége
- **Kimenet / Visszajelzés**: Súlyozott átlagárfolyam = `SUM(t.hufAmount) / SUM(t.currencyAmount)`
- **Validációk és Kényszerek**: Nullával való osztás elleni védelem (ha a valutamennyiség 0, az átlagárfolyam 0). Csak a pénzügyileg hatékony tranzakciók (`financialEffective = TRUE`) kerülnek figyelembevételre a duplikációk elkerülésére (különösen a konverzióknál).

### FR-3 Időszaki aggregáció
- **Leírás**: Tetszőleges napi/havi/éves időablakok aggregálása a tranzakciós táblából valós időben.
- **Forrás**: `AverageRateReportService.java` (`transactionDate BETWEEN :from AND :to`)
- **Prio**: M
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Kezdő dátum, vég dátum
- **Kimenet / Visszajelzés**: A megadott tartományba eső tranzakciók aggregált átlagai
</functional_spec>

<data_structure>
## Legacy és Jelenlegi Adatmodell
### Legacy Adatbázis Kapcsolat (InterBase)
A régi rendszer az átlagárfolyam számításhoz egy ideiglenes/aggregált `ATLAGARFOLYAM` táblát használt, az alábbi mezőkkel:
- `VALUTANEM`: Valuta kódja (pl. EUR, USD)
- `VETELBANKJEGY` / `VETELERTEK`: A megvásárolt valutamennyiség és annak HUF ellenértéke (`_vb` és `_ve` a Pascal kódban)
- `ELADASBANKJEGY` / `ELADASERTEK`: Az eladott valutamennyiség és annak HUF ellenértéke (`_eb` és `_ee` a Pascal kódban)

### Jelenlegi Postgres Adatmodell
Az új backend dinamikusan aggregálja a tranzakciókat a `transaction` táblából:
- `transaction` tábla érintett mezői:
  - `currency_id` / `currency_code`: A tranzakció valutája
  - `currency_amount`: A tranzakció valutamennyisége (SUM)
  - `huf_amount`: A tranzakció HUF értéke (SUM)
  - `status`: Csak a `'COMPLETED'` státuszú tranzakciók
  - `financial_effective`: Csak a `TRUE` értékű sorok (kiszűri a parent conversion rekordokat, megelőzve a vétel/eladás duplázódását)
  - `transaction_date`: Szűrési tartomány

SQLite tükrözés: **NEM** szükséges (ez egy központi vezetői/ellenőri riport).
</data_structure>

<integration_points>
## Integrációs Pontok és Végpontok
- **Java Végpont**: `GET /api/reports/average-rate`
  - Paraméterek: `from`, `to`, `branchId` (opcionális), `currencyId` (opcionális), `transactionType` (opcionális)
- **JPQL Lekérdezési Logika**:
  ```jpa
  SELECT t.currency.id, t.currency.code, COUNT(t), SUM(t.currencyAmount), SUM(t.hufAmount)
  FROM Transaction t
  WHERE t.company.id = :companyId
    AND t.transactionDate BETWEEN :from AND :to
    AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED
    AND t.financialEffective = TRUE
  GROUP BY t.currency.id, t.currency.code
  ORDER BY t.currency.code
  ```
- **Súlyozott átlag számítása**:
  ```java
  if (totalCurrency != null && totalCurrency.signum() > 0 && totalHuf != null) {
      weightedAvg = totalHuf.divide(totalCurrency, 4, RoundingMode.HALF_UP);
  }
  ```
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Tranzakciók lekérése**: Az `AverageRateReportService` lekéri a szűrt időszak teljesített tranzakcióit.
2. **Aggregáció**: JPQL GROUP BY segítségével kiszámítja a valutánkénti darabszámot, valutamennyiséget és HUF összeget.
3. **Osztás**: A HUF összeget elosztja a valutamennyiséggel (súlyozott átlag).
4. **Megjelenítés**: A frontend táblázatosan ábrázolja az eredményt.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | A riport lap- és oszlopstruktúrája | Specifikáció alapja | **RESOLVED**: A backend dinamikus JPQL aggregációt végez. A frontend oszlopai: Valuta, Tranzakció darabszám, Összes valutamennyiség, Összes HUF ellenérték, Súlyozott átlagárfolyam. |
| 2 | Átlagolás algoritmusa (egyszerű vs súlyozott) | Helyes átlagérték számítása | **RESOLVED**: Súlyozott átlagárfolyam számítás történik: `SUM(hufAmount) / SUM(currencyAmount)` formában. |
| 3 | `AcAtlagarf` vs `Atlagarfolyam` különbsége | Két fájl szerepe | **RESOLVED**: A legacy rendszerben a különböző irodák/körzetek miatti elnevezési eltérések voltak; a modern rendszerben ezt a `branchId` szűrés egységesen lefedi. |
| 4 | Időablak (napi/havi/egyedi tartomány) | Aggregációs dimenzió | **RESOLVED**: Bármilyen egyedi időintervallum megadható (kezdő és végdátum szűrővel), a JPQL dinamikusan szűri a tranzakciókat. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (bináris fájlok miatti korlátozások feloldva).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=3 db, TBD=4 db, érintett csomagok=frontend-react, kozponti-client, backend.
</verification_checklist>
