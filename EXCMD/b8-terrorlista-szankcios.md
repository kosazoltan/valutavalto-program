# Modul: Terror / szankciós lista

<system_context>
## Rendszerkontextus és Cél
A szankciós/terror-lista állományok és az ügyfél-átvilágítási (AML) névszűrés STRUKTÚRÁJÁT és üzleti szabályait leírni. A rendszer a statikus 2008-as szöveges állomány (`Terrorlista2008.txt`) importálásán túl támogatja az EU és ENSZ hivatalos XML alapú szankciós listáinak beolvasását és a valós idejű, fuzzy és alias-alapú névszűrést.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Pénztáros | Szankciós találat figyelmeztetés tranzakció közben, találat jelzése | CASHIER |
| Belsőellenőr | Találat-felülvizsgálat, manuális feloldás/jóváhagyás | INTERNAL_AUDITOR |
| Adminisztrátor | Lista import/csere (XML/TXT feltöltés) | ADMIN |

## Hatókör (Scope)
### IN
- Statikus plain-text névlista (`Terrorlista2008.txt`) importálása és feldolgozása.
- Hivatalos EU szankciós XML (`sanctionEntity` és `sanctionEntityList` struktúra) és ENSZ szankciós lista importálása.
- Valós idejű tranzakció előtti névszűrés (fuzzy és alias keresés).
- Szűrési eredmények és audit naplózás (`sanction_screening_log`).
- Listák elavultságának figyelmeztetése (`listAgeDays` ellenőrzés).

### OUT
- Automatikus rendőrségi/hatósági értesítés küldése (csak belső naplózás és belső ellenőri eszkaláció valósul meg).

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | Karakterkódolás-tolerancia | Név-egyezés Unicode dekompozícióval (NFD) + kisbetűsítés + diakritika és írásjelek eltávolítása |
| NFR-2 | Találati teljesítmény tranzakció közben | Név-szűrés <200 ms a teljes aktív listán |
| NFR-3 | Fuzzy/alias egyezés | Levenshtein-távolság alapú egyezés (max 2 eltérés tolerálása) |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-1 Lista importálási formátumok
- **Leírás**: A rendszer képes fogadni a statikus `.txt` fájlokat, valamint a hivatalos EU XML formátumot (`xmlFullSanctionsList_1_1`).
- **Forrás**: `Terrorlista2008.txt`, `SanctionScreeningService.java` (`importEuSanctionList`, `importSanctionList`)
- **Prio**: M
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Feltöltött fájl stream
- **Kimenet / Visszajelzés**: Importált bejegyzések száma, utolsó frissítés dátumának beállítása.

### FR-2 Unicode normalizálás
- **Leírás**: A keresett név és a listában szereplő nevek az ellenőrzés előtt normalizálásra kerülnek: Unicode NFD dekompozíció (pl. `Á` -> `A`), kisbetűsítés, diakritikus jelek (`\\p{M}+`) eltávolítása, és nem-alfanumerikus írásjelek törlése.
- **Forrás**: `SanctionScreeningService.java` (`normalizeName`)
- **Prio**: M
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Nyers név string
- **Kimenet / Visszajelzés**: Normalizált név string (pl. "DE-B-RE-CEN")

### FR-3 Névszűrési algoritmus és fokozatok
- **Leírás**: Tranzakció indításakor a rendszer leellenőrzi az ügyfél nevét az aktív szankciós listán.
- **Szabályok és Pontszámok**:
  - **EXACT**: Ha a normalizált név teljesen megegyezik a szankcionált névvel vagy valamelyik aliasával (Pontszám: 1.0). Risk szint: `CONFIRMED` -> a tranzakció automatikusan zárolásra kerül.
  - **ALIAS**: Ha a normalizált név pontosan egyezik a bejegyzéshez társított alias listájának (JSON array) valamelyik tagjával (Pontszám: 0.9).
  - **PARTIAL**: Ha a normalizált név tartalmazza a keresett nevet, vagy fordítva (Pontszám: 0.8).
  - **FUZZY**: Levenshtein-távolság számítása. Ha az eltérés kisebb vagy egyenlő, mint 2 (`MAX_LEVENSHTEIN_DISTANCE = 2`), a találat pontszáma: `1.0 - (távolság / max_hossz)` (minimum 0.3).
- **Forrás**: `SanctionScreeningService.java` (`screenName`, `levenshteinDistance`)
- **Prio**: M
- **Csomag/Komponens**: backend, penztar-client
- **Kimenet / Visszajelzés**: Szűrési eredmény: `CLEAR` (nincs találat), `POSSIBLE` (részleges/fuzzy találat, felülvizsgálatot igényel), `CONFIRMED` (pontos egyezés, tranzakció blokkolva).

### FR-4 Screening Audit naplózás
- **Leírás**: Minden szűrés eredménye mentésre kerül a `sanction_screening_log` táblába (ki, mikor, kit szűrt, találatok száma, részletei JSON-ben, jóváhagyta-e supervisor).
- **Forrás**: `SanctionScreeningService.java` (`logScreening`)
- **Prio**: M
- **Csomag/Komponens**: backend
</functional_spec>

<data_structure>
## Jelenlegi Postgres Adatmodell Mappings

- `sanction_entries` (szankciós entitások):
  - `id` (uuid primary key)
  - `full_name` (varchar(500)) -- Szankcionált személy/szervezet teljes neve
  - `aliases` (text) -- Aliases/névváltozatok JSON tömbje (pl. `["The Base", "La Base"]`)
  - `date_of_birth` (varchar(50))
  - `nationality` (varchar(100))
  - `document_number` (varchar(100))
  - `list_type` (varchar(20)) -- 'EU', 'UN', 'OFAC'
  - `list_reference` (varchar(500)) -- Hivatkozott jogszabály vagy sorszám (pl. 329)
  - `added_date` (date)
  - `last_updated` (date)
  - `active` (boolean) -- Aktív/Inaktív státusz
  - `created_at` (timestamp)
- `sanction_screening_log` (szűrési audit napló):
  - `id` (uuid primary key)
  - `screened_name` (varchar(500)) -- Ügyfél beküldött neve
  - `screened_document_number` (varchar(100))
  - `screened_date_of_birth` (varchar(50))
  - `result` (varchar(20)) -- 'CLEAR', 'POSSIBLE', 'CONFIRMED'
  - `match_count` (integer) -- Találatok száma
  - `match_details` (text) -- Találati adatok részletei (JSON)
  - `worker_id` (varchar(50)) -- Kasszás azonosítója
  - `worker_name` (varchar(200)) -- Kasszás neve
  - `branch_code` (varchar(20)) -- Iroda azonosítója
  - `supervisor_approved` (boolean) -- Supervisor által jóváhagyva/feloldva
  - `supervisor_name` (varchar(200))

SQLite mirror támogatás: **IGEN**, a `sanction_entries` tábla le van tükrözve a `penztar-client` SQLite adatbázisába, így az offline üzemmódban végzett tranzakciók során is lefut az AML névellenőrzés. Hálózati kapcsolat esetén a `sanction_screening_log` bejegyzések a Sync Agenten keresztül felszinkronizálódnak a Postgres szerverre.
</data_structure>

<integration_points>
## Integrációs Pontok és API-k
- **Névszűrő API**:
  - `POST /api/sanctions/screen`
  - Body: `{ "name": "...", "documentNumber": "...", "dateOfBirth": "..." }`
  - Response: `{ "matched": true/false, "riskLevel": "CLEAR/POSSIBLE/CONFIRMED", "matches": [...] }`
- **Lista Import API**:
  - `POST /api/sanctions/import/eu` (EU XML feltöltés)
  - `POST /api/sanctions/import/un` (ENSZ XML feltöltés)
- **Stale warning**: A rendszer a lekérdezéseknél ellenőrzi a szankciós lista korát (`listAgeDays`). Ha ez meghaladja a 30 napot (`MAX_SANCTION_LIST_AGE_DAYS`), a rendszer adminisztrátori figyelmeztetést generál a lista frissítésére.
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Névellenőrzés**: Tranzakció indításakor a kassza-kliens elküldi az ügyfél nevét és adatait a szűrő szolgáltatásnak.
2. **Keresés és Pontozás**: A `SanctionScreeningService` a megadott Levenshtein és alias keresési szabályokkal végigfuttatja a névszűrést.
3. **Döntés**:
   - `CLEAR`: A tranzakció folytatódhat.
   - `POSSIBLE` / `CONFIRMED`: A tranzakció zárolásra kerül. A feloldáshoz a supervisor beírja a jóváhagyását a bizonylathoz, amit a rendszer naplóz a `sanction_screening_log` táblában.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | Személy vs szervezet típus megkülönböztetése | Szűrési/megjelenítési logika | **RESOLVED**: Az EU/ENSZ XML-ek explicit tartalmazzák az entitás típusát (Individual/Entity), amely az import során a `list_type` és `list_reference` mezőkben rögzítésre kerül. |
| 2 | A lista frissítési forrása élesben | Jogszabályi megfelelőség | **RESOLVED**: Az admin felületen keresztül kézzel feltölthetőek az EU/ENSZ hivatalos XML fájljai; a rendszer automatikusan jelzi, ha a betöltött adatok elavultak (30 napnál régebbiek). |
| 3 | Az azonosító-szám tartomány/jelentése | Esetleges kategória | **RESOLVED**: A 2008-as txt-ben lévő sorvégi számok a szankciós nyilvántartási azonosítók (Reference ID), melyeket a rendszer a `list_reference` mezőbe parsol be az import során. |
| 4 | Pontos egyezés vs fuzzy küszöb | Hamis pozitív arány optimalizálása | **RESOLVED**: A rendszer a Levenshtein-távolságot 2-ben határozza meg (`MAX_LEVENSHTEIN_DISTANCE = 2`), ez alatt részleges egyezést riaszt, míg az egyezés mértékét 0.3 - 1.0 közötti pontszámmal jelzi. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (az algoritmus paraméterei a Java forráskódból lettek kinyerve).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=4 db, TBD=4 db, érintett csomagok=backend, penztar-client.
</verification_checklist>
