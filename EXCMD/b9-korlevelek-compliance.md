# Modul: Körlevelek mint compliance/AML követelmény

<system_context>
## Rendszerkontextus és Cél
A belső körlevelek (7. sz. bankkártyás csalás-figyelmeztetés; 9. sz. FATF többszintű lista-változás) tartalmát AML/compliance funkcionális követelményként rögzíteni, beleértve a körlevél-kezelést (kiadás, elolvasás-visszaigazolás szerepkörönként), a benne foglalt szakmai szabályokat, valamint az 50 millió HUF feletti pénzszármazás igazolás szigorú előírásait.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Pénztáros / Értéktáros | Körlevél elolvasása + visszaigazolása; gyanú jelzése; tranzakció-flow pre-validáció | CASHIER |
| Területi vezető | Körlevél elolvasás/értelmezés; betartás figyelemmel kísérése; supervisor jóváhagyás | SUPERVISOR / MANAGER |
| Belső ellenőr | Ellenőrzéskor a betartás/ismeret meggyőződése | INTERNAL_AUDITOR |
| Compliance / Készítő | Körlevél kiadása, gyanú-jelzés fogadása, FATF lista karbantartása | ADMIN |

## Hatókör (Scope)
### IN
- **7. sz. körlevél** (iktató: FZS-35/2023, hatályos 2024.02.09.):
  - Bankkártyás csalások és stróman-számlák elleni védelem.
  - Gyanús ismertetőjegyek: napi többszöri váltás bankkártyás fizetéssel; PIN kód papírról olvasása; telefonról (üzenetből) nézett valutamennyiség.
  - Gyanú esetén: tranzakció felfüggesztése, telefonos eszkaláció a vezető felé.
- **9. sz. körlevél** (iktató: FZS-9/2024, hatályos 2024.02.27.):
  - FATF lista-változás (public statement 2024.02.27).
  - 1/a Csoport (ellenintézkedésekkel érintett): Észak-Korea, Irán.
  - 1/b Csoport (fokozott átvilágítás szükséges): Myanmar (Burma).
  - 2. Csoport (fokozott monitoring): 21 felsorolt ország (Bulgária, Horvátország, Törökország, Vietnam stb.). Kikerült: Barbados, Gibraltár, Uganda, Egyesült Arab Emírségek.
- **Pénzszármazás igazolás szabályai (Compliance/AML)**:
  - 50 millió HUF összeghatár felett kötelező a pénz származásának igazolása. A származást kizárólag ügyvéd vagy közjegyző által ellenjegyzett **"teljes bizonyító erejű magánokirat"** igazolhatja. Két tanús tanú-nyilatkozat (magánokirat) használata szigorúan TILOS.
  - Banki kifizetési bizonylat (készpénzfelvételi bizonylat) korlátja: nem lehet régebbi, mint 3 év (pl. 2024-es ügyletnél egy 2021-es vagy korábbi bizonylat nem fogadható el).
- **Blokkoló elolvasási kényszer**: unacknowledged körlevél megléte esetén a pénztáros nem indíthat tranzakciót.

### OUT
- A bankkártyás fizetés technikai tiltása/limitálása (emberi mérlegelést és telefonos eszkalációt igényel).

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-01 | A FATF lista-ellenőrzés a tranzakció előtt lefut | Ellenőrzés belép a tranzakció-flow-ba mentés előtt |
| NFR-02 | A körlevél-elolvasás visszaigazolása auditálható | Megváltoztathatatlan circular_acknowledgment bejegyzés |
| NFR-03 | FATF lista változatlanság / verziózás | A betöltött lista verziójának (pl. "FZS-9/2024") visszakereshetősége |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-01 Belső körlevelek kezelése metaadatokkal
- **Leírás**: A rendszer kezeli a belső körleveleket metaadatokkal: iktatószám (registration_number), tárgy (title), készítő, hatályosság kezdete (valid_from) és vége (valid_to), csatolmányok és verzió-követés.
- **Forrás**: 7. sz. + 9. sz. körlevél fejléc, `Circular.java`
- **Prio**: M
- **Csomag/Komponens**: backend, frontend

### FR-02 Kötelező körlevél visszaigazolás és blokkolás
- **Leírás**: A pénztáros bejelentkezésekor a rendszer lekérdezi az olvasatlan körleveleket (`findUnacknowledgedForCurrentWorker`). Amennyiben van olvasatlan körlevél, a kliens zárolja a tranzakciós felületet, és kötelezi a dolgozót a körlevél elolvasására és digitális visszaigazolására (gombra kattintás).
- **Forrás**: `CircularService.java`
- **Prio**: M
- **Csomag/Komponens**: frontend (penztar-client), backend
- **Validációk és Kényszerek**: A tranzakciós végpontok 403 Forbidden hibát adnak vissza, ha a dolgozónak van visszaigazolatlan aktív körlevele.

### FR-03 Bankkártyás-csalás gyanú-bejelentés és naplózás
- **Leírás**: Gyanú esetén (pl. kártyás váltások száma magas, PIN papírról olvasása) a pénztáros a tranzakciót "SUSPENDED" állapotba helyezi, és telefonon egyeztet a területi vezetővel. A felfüggesztés okát és a gyanús jeleket a rendszer elmenti a `customer_screening_log` táblába.
- **Forrás**: 7. sz. körlevél
- **Prio**: M
- **Csomag/Komponens**: penztar-client, backend

### FR-04 FATF többszintű országbesorolás ellenőrzés
- **Leírás**: Tranzakció pre-validációjakor a rendszer ellenőrzi az ügyfél állampolgárságát (citizenship) és lakcímét (address) a FATF listán (`FatfCountryRiskService`).
- **Társuló rendszer-intézkedések**:
  - **1/a (ellenintézkedéssel érintett - Észak-Korea, Irán)**: A tranzakció azonnal BLOKKOLVA / elutasítva. AmlService `approved(false)` választ ad.
  - **1/b (fokozott átvilágítás - Myanmar)**: A rendszer megköveteli a Fokozott Ügyfél-átvilágítási (EDD) kérdőív és nyilatkozat kötelező kitöltését a tranzakció engedélyezése előtt.
  - **2 (fokozott monitoring - 21 ország)**: A pénztáros figyelmeztető üzenetet (warning) kap a képernyőre, amely felhívja a figyelmet a fokozott óvatosságra.
- **Forrás**: `FatfCountryRiskService.java`
- **Prio**: M
- **Csomag/Komponens**: backend, penztar-client

### FR-05 50 Millió HUF feletti pénzszármazás igazolás
- **Leírás**: Ha a tranzakció értéke meghaladja az 50 000 000 HUF-ot, a kassza-kliens kötelezően megköveteli a származást igazoló dokumentum feltöltését.
- **Validációs szabályok**:
  - A származást igazoló okirat kizárólag közjegyző vagy ügyvéd által ellenjegyzett **"teljes bizonyító erejű magánokirat"** lehet. Két tanú által aláírt sima magánokirat elfogadása TILOS (a rendszer elutasítja).
  - Amennyiben a származást banki készpénzfelvételi bizonylat igazolja, a bizonylat kiállítási dátuma nem lehet régebbi, mint 3 év. A 3 évnél régebbi bizonylatokat a rendszer érvénytelenként jelöli meg és blokkolja a tranzakciót.
- **Forrás**: Pmt. compliance és audit szabályzat
- **Prio**: M
- **Csomag/Komponens**: backend, penztar-client
- **Validációk**: Dátum ellenőrzés (bizonylat dátuma >= ma - 3 év).
</functional_spec>

<data_structure>
## Jelenlegi Postgres Adatmodell Mappings

- `circular` (belső körlevelek táblája):
  - `id` (bigserial primary key)
  - `company_id` (uuid REFERENCES company)
  - `registration_number` (varchar(50)) -- Iktatószám (pl. "FZS-9/2024")
  - `title` (varchar(255)) -- Tárgy
  - `circular_type` (varchar(30)) -- Pl. 'AML_COMPLIANCE', 'GENERAL'
  - `target` (varchar(30)) -- Célcsoport (pl. 'ALL_BRANCHES')
  - `priority` (varchar(20)) -- Prioritás (pl. 'HIGH', 'NORMAL')
  - `attachment_path` (varchar(500))
  - `valid_from` (date)
  - `valid_to` (date)
  - `archived` (boolean)
  - `archived_at` (timestamp)
  - `archive_year` (integer)
  - `category` (varchar(20)) -- Pl. 'VIP', 'ZALOG'
- `circular_acknowledgment` (dolgozói visszaigazolások):
  - `id` (bigserial primary key)
  - `circular_id` (bigint REFERENCES circular ON DELETE CASCADE)
  - `worker_id` (bigint REFERENCES worker)
  - `acknowledged_at` (timestamp NOT NULL DEFAULT NOW())
  - `ip_address` (varchar(45))
  - `acknowledger_role` (varchar(50)) -- A dolgozó szerepköre a visszaigazolás pillanatában (pl. 'CASHIER')
  - `UNIQUE(circular_id, worker_id)`

SQLite mirror támogatás: **IGEN**, a `circular` és `circular_acknowledgment` táblák a `penztar-client` SQLite adatbázisába szinkronizálódnak, így offline módban is kikényszeríthető a bejelentkező dolgozó elolvasási/visszaigazolási kötelezettsége.
</data_structure>

<integration_points>
## Integrációs Pontok és API-k
- **Körlevél Lekérdezések**:
  - `GET /api/circulars/unacknowledged`: Olvasatlan aktív körlevelek listázása a jelenlegi dolgozónak.
  - `POST /api/circulars/{id}/acknowledge`: Körlevél elolvasásának visszaigazolása (rögzíti az IP címet és az aktív szerepkört).
- **FATF Ország-kockázat szerviz**:
  - `FatfCountryRiskService.classify(String country)`
  - A betöltött lista verziója (`FatfCountryRiskService.LIST_VERSION`): `"FZS-9/2024 (2024-02-27)"` static metadata.
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Belépés és Blokkolás**: A dolgozó belép a kliensbe. Ha a `findUnacknowledgedForCurrentWorker()` nem üres listát ad vissza, a tranzakciós felület lezárul, és a körlevél megjelenik elolvasásra.
2. **Visszaigazolás**: A dolgozó a "Visszaigazolom az elolvasást" gombra kattint. A rendszer a `circular_acknowledgment` táblába menti a bejegyzést, rögzítve az IP címet és az aktív szerepkört (`acknowledger_role`). A zárolás feloldódik.
3. **Tranzakciós szűrés**: Tranzakció rögzítésekor a rendszer ellenőrzi az ügyfél országát és a pénzösszeg származásának igazolását (ügyvédi/közjegyzői teljes okirat 50M felett, 3 évnél nem régebbi banki bizonylat).
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | A FATF lista frissítése kézi vagy automatikus külső forrásból történik? | Lista naprakészsége | **RESOLVED**: A `FatfCountryRiskService` statikus ország-szűrést végez a verziózott körlevélnek megfelelően; frissítése a kód/metadata szerkesztésével vagy admin felületen történik új körlevél kiadásakor. |
| 2 | A szintekhez (1/a, 1/b, 2) pontosan milyen rendszer-intézkedés társul? | Validációs viselkedés | **RESOLVED**: 1/a azonnali elutasítás/blokkolás, 1/b kötelező fokozott átvilágítási (EDD) kérdőív, 2. csoport figyelmeztetés a képernyőn. |
| 3 | Melyik ország-mező (állampolgárság, születési ország, lakcím ország) ellenőrizendő? | Ellenőrzés pontossága | **RESOLVED**: Az ügyfél állampolgársága és a lakcím szerinti ország is ellenőrzésre kerül a tranzakció indításakor. |
| 4 | Kötelező-e a körlevél elolvasása belépéskor (blokkoló hatás)? | Compliance kényszerítése | **RESOLVED**: Igen, az olvasatlan körlevél blokkolja a tranzakciós felület elérését a visszaigazolás megtörténtéig. |
| 5 | A bankkártyás-csalás gyanú eszkaláció csatornája? | Riasztási út | **RESOLVED**: A rendszerben a pénztáros felfüggesztheti a tranzakciót és a gyanús jelek megjelölésével rögzíti azt, a közvetlen eszkaláció a körlevél szerint telefonon történik a területi vezető felé. |
| 6 | Tanús magánokirat elfogadható-e 50M felett? | Compliance megfelelőség | **RESOLVED**: Nem, kizárólag ügyvéd vagy közjegyző által ellenjegyzett teljes bizonyító erejű magánokirat fogadható el. A tanús nyilatkozat szigorúan tiltott. |
| 7 | Hány évnél nem lehet régebbi a banki bizonylat? | Származás igazolás kora | **RESOLVED**: Legfeljebb 3 éves lehet a készpénzfelvételi bizonylat a tranzakció időpontjához képest. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (a Pmt. szigorítások és a körlevél blokkoló funkciói a backend Java kód alapján igazolva).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=5 db, TBD=7 db, érintett csomagok=backend, frontend-react, penztar-client.
</verification_checklist>
