# FK02-C - Irodák listájának szűrése: kódrevízió és javítási utasítás

Dátum: 2026-06-01  
Repo: `valutavalto-program`  
Téma: Az Árfolyamkészítő „Irodák kezelése” dialógjában csak pénztár típusú egységek jelenhetnek meg.

Ez a dokumentum kizárólag a mellékelt specifikációk és a jelenlegi kód tényei alapján készült. Nem tartalmaz feltételezésre épített állítást. Programkód-módosítás most nem történt; ez egy AI-fejlesztő ügynöknek átadható javítási útmutató.

## Beolvasott követelményforrások

- `C:\Users\Kósa Zoltán\Downloads\FK02-C_irodak_lista_szures.md`
- `C:\Users\Kósa Zoltán\Downloads\arfolyamkeszito_FK_02_strukturalt.md`

A releváns FK02-C követelmények:

- FR-1: Az „Irodák kezelése” lista kizárólag pénztár típusú egységeket tartalmazhat.
- FR-2: A szűrés az értéktári modulban már meglévő típus-megkülönböztetési logikára épüljön.
- FR-3: A keresés is csak pénztárakon működhet.
- NFR-1: A szűrés backend oldalon történjen, ne frontend-elrejtésként.
- Új végpont nem kell.
- Flyway migráció nem kell.

## Jelenlegi hívási útvonal

A frontend Árfolyamkészítő oldalon az „Irodák kezelése” dialógot a `RateCreationPage.tsx` nyitja meg.

Tényleges hívási lánc:

1. `frontend-react/src/pages/rates/RateCreationPage.tsx`
   - `openBranchPicker()` meghívja: `rateCreationApi.getBranches(selectedWg.id)`.
2. `frontend-react/src/services/api/exchange-rates.ts`
   - `getBranches(workgroupId)` meghívja: `GET /rate-creation/branches?workgroupId=${workgroupId}`.
3. `backend/src/main/java/hu/puzzleir/valuta/controller/RateCreationController.java`
   - `GET /api/v1/rate-creation/branches` meghívja: `rateCreationService.getAllBranchesForWorkgroup(workgroupId)`.
4. `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`
   - `getAllBranchesForWorkgroup()` jelenleg ezt használja: `branchRepository.findByCompanyIdAndIsActiveTrue(companyId)`.

Ez a végpont tehát nem új végpontot igényel. A meglévő `/api/v1/rate-creation/branches` backend lekérdezést kell szűkíteni.

## Meglévő típuslogika a kódban

A kódbázisban már létezik a szükséges típusmegkülönböztetés:

- `Branch.branchType` mező: `backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java`
- DTO mapping: `BranchMapper` kitölti a `branchTypeCode` mezőt a sima `BranchDto` esetén.
- Repository metódus: `BranchRepository.findByCompanyIdAndBranchTypeCode(companyId, typeCode)`.
- A migrációkban a pénztár típuskódja: `PENZTAR`.
- A banki/speciális értéktári partnerek típuskódja: `VAULT_COUNTERPARTY`.
- A V277 migráció rögzíti a 10 fix partnert: `PRB`, `UPT`, `TRB`, `ERB`, `FRB`, `RB`, `JRB`, `MNB`, `TH`, `FOP1`.

A legfontosabb meglévő referencia az értéktári logikában:

- `BranchService.findVaultCounterparties()` a `territorialCashiers` listát így szűri:
  - `branchType.code == "PENZTAR"`
  - `isVault != true`
  - aktív egység
  - cég- és jogosultsági scope szerint szűrt alaplistából

Ez pontosan az a domain logika, amelyből az FK02-C javításnak ki kell indulnia: az árfolyamot kapó egység pénztár, nem értéktár és nem `VAULT_COUNTERPARTY`.

## Findingok

### P0 - A `/rate-creation/branches` backend jelenleg minden aktív céges branch-et visszaad

Érintett fájl: `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`

A jelenlegi `getAllBranchesForWorkgroup(UUID workgroupId)` metódus a workgroup tenant-ellenőrzése után ezt futtatja:

```java
List<Branch> allActiveBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
```

Ez a repository lekérdezés minden aktív céges branch-et visszaad. Nem szűr `branchType.code = 'PENZTAR'` értékre, és nem zárja ki az `isVault = true` értéktári egységeket sem. Emiatt az FK02-C-ben említett belső banki/special partner egységek, például `ERB`, `FRB`, `RB`, `MNB`, `TH`, `UPT`, bekerülhetnek az „Irodák kezelése” listába, ha aktívak és ugyanahhoz a céghez tartoznak.

Ez sérti:

- FR-1: csak pénztárak jelenhetnek meg;
- FR-2: nem az értéktári modul pénztár-vs-banki egység típuslogikája van használva;
- NFR-1: nincs backend oldali pénztárszűrés.

### P0 - A mentési endpoint is elfogad nem-pénztár branch ID-ket

Érintett fájl: `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`

Az `updateWorkgroupBranches(UUID workgroupId, List<UUID> branchIds)` metódus jelenleg csak ezt ellenőrzi minden beküldött branch-re:

```java
if (!branch.getCompany().getId().equals(companyId)) { ... }
if (!Boolean.TRUE.equals(branch.getIsActive())) { ... }
```

Nem ellenőrzi, hogy a branch típusa `PENZTAR`, és nem ellenőrzi, hogy `isVault` hamis-e. Ez azt jelenti, hogy még akkor is bekerülhetne `VAULT_COUNTERPARTY` vagy `ERTEKTAR` típusú egység egy árfolyam-munkacsoportba, ha a listaoldali lekérdezést később kijavítják. Ez backend-szintű adatintegritási hiba.

Következmény: egy stale frontend állapot, manuális API-hívás vagy korábbról megmaradt kliensverzió továbbra is hozzá tudna rendelni nem pénztár egységet a csoporthoz.

### P1 - A már meglévő `findByCompanyIdAndIsActiveTrueExcludingCounterparties` nem elég FK02-C-hez

Érintett fájl: `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java`

Van már egy hasonló repository metódus:

```java
findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId)
```

Ez csak a `VAULT_COUNTERPARTY` típusú banki/speciális partnereket zárja ki. Az FK02-C követelmény viszont ennél szigorúbb: az „Irodák kezelése” listában kizárólag pénztár típusú egységek lehetnek. Ez azt jelenti, hogy az `ERTEKTAR` típusú vagy `isVault=true` egységek sem maradhatnak a listában.

Ezért az FK02-C javításnál nem elég az `ExcludingCounterparties` metódust újrahasználni. Pénztár-only lekérdezés kell.

### P1 - A frontend keresés jelenleg helyes irányban működik, de csak akkor, ha a backend listája már szűrt

Érintett fájl: `frontend-react/src/pages/rates/RateCreationPage.tsx`

A `groupedBranches` memo a `branchFilter` alapján a `allBranches` tömböt szűri név, kód és város szerint:

```typescript
const filtered = branchFilter
  ? allBranches.filter(b =>
      b.name.toLowerCase().includes(branchFilter.toLowerCase()) ||
      b.code.toLowerCase().includes(branchFilter.toLowerCase()) ||
      b.city.toLowerCase().includes(branchFilter.toLowerCase())
    )
  : allBranches
```

Ez önmagában rendben van, de csak akkor teljesíti FR-3-at, ha `allBranches` backendből eleve csak pénztárakat tartalmaz. Frontend oldali extra `excludeBankPartners()` használata itt nem lenne megfelelő elsődleges javítás, mert az FK02-C NFR-1 backend oldali szűrést ír elő.

### P2 - A `BranchListDTO` nem hordoz `branchTypeCode` mezőt

Érintett fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/ratecreation/BranchListDTO.java`

A DTO jelenleg csak ezeket tartalmazza:

```java
private UUID id;
private String code;
private String name;
private String city;
private boolean assignedToCurrentWorkgroup;
```

Ez nem önmagában hiba, ha a backend szűrés garantált. Viszont diagnosztika és tesztelhetőség szempontjából hasznos lehet opcionálisan `branchTypeCode` mezőt hozzáadni. Az FK02-C teljesítéséhez nem kötelező, és ha minimális javítás a cél, elhagyható.

## Javítási utasítás AI-fejlesztő ügynöknek

### Cél

A meglévő `/api/v1/rate-creation/branches?workgroupId=...` végpont úgy működjön, hogy:

- csak aktív, az aktuális céghez tartozó pénztárakat ad vissza;
- `branchType.code == 'PENZTAR'` legyen;
- `isVault != true` legyen;
- `VAULT_COUNTERPARTY` egységek biztosan ne kerüljenek vissza;
- `ERTEKTAR`/értéktár egységek se kerüljenek vissza;
- új végpont ne készüljön;
- adatmodell és Flyway migráció ne változzon.

### 1. Repository-szintű pénztár-only lekérdezés létrehozása

Fájl: `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java`

Adj hozzá egy külön, explicit FK02-C célú metódust:

```java
/**
 * FK02-C: Árfolyamkészítő munkacsoporthoz választható irodák.
 * Csak aktív, cégen belüli, lakossági pénztár típusú egységek.
 * Nem tartalmaz értéktárat és nem tartalmaz VAULT_COUNTERPARTY banki/speciális partnert.
 */
@Query("""
    SELECT b FROM Branch b
    JOIN b.branchType bt
    WHERE b.company.id = :companyId
      AND b.isActive = true
      AND bt.code = 'PENZTAR'
      AND (b.isVault IS NULL OR b.isVault = false)
    ORDER BY b.name
""")
List<Branch> findRateCreationAssignableCashierBranches(@Param("companyId") UUID companyId);
```

Miért nem elég a meglévő `findByCompanyIdAndBranchTypeCode(companyId, "PENZTAR")`?

- Az használható lenne kiindulásként, de nem szűr explicit `isActive = true` feltételre.
- Nem zárja ki explicit az `isVault = true` anomáliát.
- Az FK02-C követelmény üzletileg külön felülethez tartozik, ezért olvashatóbb és biztonságosabb egy célzott repository metódus.

### 2. Lista endpoint javítása

Fájl: `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`

A `getAllBranchesForWorkgroup()` metódusban ezt:

```java
List<Branch> allActiveBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
```

cseréld erre:

```java
List<Branch> allActiveBranches = branchRepository.findRateCreationAssignableCashierBranches(companyId);
```

A további mapping maradhat:

```java
return allActiveBranches.stream()
        .map(b -> BranchListDTO.builder()
                .id(b.getId())
                .code(b.getCode())
                .name(b.getName())
                .city(b.getCity())
                .assignedToCurrentWorkgroup(assignedBranchIds.contains(b.getId()))
                .build())
        .collect(Collectors.toList());
```

### 3. Mentési endpoint validációjának szigorítása

Fájl: `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`

Az `updateWorkgroupBranches()` metódusban a meglévő tenant és aktív ellenőrzés mellé add hozzá a pénztár-only validációt.

Mintakód:

```java
private boolean isRateCreationAssignableCashierBranch(Branch branch) {
    return branch != null
            && branch.getBranchType() != null
            && "PENZTAR".equals(branch.getBranchType().getCode())
            && !Boolean.TRUE.equals(branch.getIsVault())
            && Boolean.TRUE.equals(branch.getIsActive());
}
```

A ciklusban:

```java
for (Branch branch : branches) {
    if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
        throw new ValidationException("Iroda nem tartozik az aktuális céghez: " + branch.getCode());
    }
    if (!Boolean.TRUE.equals(branch.getIsActive())) {
        throw new ValidationException("Inaktív iroda nem rendelhető hozzá: " + branch.getCode());
    }
    if (!isRateCreationAssignableCashierBranch(branch)) {
        throw new ValidationException(
                "Árfolyam-munkacsoporthoz csak pénztár típusú iroda rendelhető: " + branch.getCode());
    }
}
```

Fontos: ezt a validációt ne csak a listázásnál oldd meg. A POST endpointnak is védenie kell az adatot.

### 4. Opcionális: `BranchListDTO` diagnosztikai bővítés

Nem kötelező az FK02-C teljesítéséhez, de teszteléshez hasznos lehet:

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/ratecreation/BranchListDTO.java`

```java
private String branchTypeCode;
```

Mapping:

```java
.branchTypeCode(b.getBranchType() != null ? b.getBranchType().getCode() : null)
```

Ha ezt bevezeted, a frontend `BranchListItem` típust is frissíteni kell:

```typescript
export interface BranchListItem {
  id: string
  code: string
  name: string
  city: string
  assignedToCurrentWorkgroup: boolean
  branchTypeCode?: string
}
```

Ez csak diagnosztikai kényelmi elem. A backend szűrés marad a lényeg.

### 5. Frontendhez nem kell üzleti szűrés

Ne tedd át a javítást ide:

- `frontend-react/src/pages/rates/RateCreationPage.tsx`
- `frontend-react/src/pages/rates/components/BranchPickerModal.tsx`
- `frontend-react/src/utils/bankPartners.ts`

A `bankPartners.ts` hasznos meglévő frontend segéd, de FK02-C-re nem elégséges elsődleges javítás, mert:

- csak `VAULT_COUNTERPARTY` banki/speciális partnereket szűr;
- nem zárja ki önmagában az `ERTEKTAR` / `isVault=true` egységeket;
- a követelmény backend oldali szűrést ír elő.

A frontend keresés maradhat változatlan. Ha a backend csak pénztárakat ad, akkor a keresés is csak pénztárakon működik.

## Tesztelési utasítás

### Backend unit tesztek

Fájl: `backend/src/test/java/hu/puzzleir/valuta/service/RateCreationServiceTest.java`

Adj hozzá legalább ezeket a teszteket.

#### 1. `getAllBranchesForWorkgroup` csak pénztárakat kér a repositoryból

Cél: a service ne hívja többé a széles `findByCompanyIdAndIsActiveTrue()` metódust.

Mintateszt irány:

```java
@Test
@DisplayName("FK02-C: getAllBranchesForWorkgroup csak PENZTAR típusú hozzárendelhető irodákat listáz")
void getAllBranchesForWorkgroup_listsOnlyAssignableCashierBranches() {
    Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
    RateWorkgroup wg = RateWorkgroup.builder()
            .id(UUID.randomUUID())
            .company(company)
            .branches(Set.of())
            .build();

    Branch cashier = Branch.builder()
            .id(UUID.randomUUID())
            .company(company)
            .code("BR100")
            .name("Kalocsa")
            .city("Kalocsa")
            .isActive(true)
            .isVault(false)
            .branchType(Dictionary.builder().category("BRANCH_TYPE").code("PENZTAR").build())
            .build();

    when(rateWorkgroupRepository.findById(wg.getId())).thenReturn(Optional.of(wg));
    when(branchRepository.findRateCreationAssignableCashierBranches(COMPANY_ID)).thenReturn(List.of(cashier));

    List<BranchListDTO> result = service.getAllBranchesForWorkgroup(wg.getId());

    assertThat(result).extracting(BranchListDTO::getCode).containsExactly("BR100");
    verify(branchRepository).findRateCreationAssignableCashierBranches(COMPANY_ID);
    verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(COMPANY_ID);
}
```

A fenti mintához importok kellhetnek: `Dictionary`, `BranchListDTO`, `Optional`, valamint Mockito `verify`, `never`.

#### 2. `updateWorkgroupBranches` elutasítja a `VAULT_COUNTERPARTY` egységet

Mintateszt irány:

```java
@Test
@DisplayName("FK02-C: updateWorkgroupBranches elutasítja a VAULT_COUNTERPARTY egységet")
void updateWorkgroupBranches_rejectsVaultCounterparty() {
    Company company = Company.builder().id(COMPANY_ID).code("EBC").name("Test").build();
    UUID workgroupId = UUID.randomUUID();
    UUID branchId = UUID.randomUUID();

    RateWorkgroup wg = RateWorkgroup.builder()
            .id(workgroupId)
            .company(company)
            .branches(new java.util.HashSet<>())
            .build();

    Branch erb = Branch.builder()
            .id(branchId)
            .company(company)
            .code("ERB")
            .name("Egyedi Raiffeisen")
            .isActive(true)
            .isVault(false)
            .branchType(Dictionary.builder().category("BRANCH_TYPE").code("VAULT_COUNTERPARTY").build())
            .build();

    when(rateWorkgroupRepository.findById(workgroupId)).thenReturn(Optional.of(wg));
    when(branchRepository.findAllById(List.of(branchId))).thenReturn(List.of(erb));

    assertThatThrownBy(() -> service.updateWorkgroupBranches(workgroupId, List.of(branchId)))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("csak pénztár típusú");
}
```

#### 3. `updateWorkgroupBranches` elutasítja az értéktárat

Ugyanaz a tesztminta, de:

```java
.branchType(Dictionary.builder().category("BRANCH_TYPE").code("ERTEKTAR").build())
.isVault(true)
```

Elvárt: `ValidationException`.

#### 4. `updateWorkgroupBranches` elfogadja a valódi aktív pénztárat

Elvárt:

- nem dob kivételt;
- a workgroup branches tartalmazza a pénztárt;
- `rateWorkgroupRepository.save(workgroup)` meghívódik.

### Repository/integrációs teszt

Ha van `@DataJpaTest` infrastruktúra, érdemes külön ellenőrizni:

- `PENZTAR + active + isVault=false` visszajön;
- `VAULT_COUNTERPARTY + active` nem jön vissza;
- `ERTEKTAR + isVault=true` nem jön vissza;
- másik company pénztára nem jön vissza;
- inaktív pénztár nem jön vissza.

### Frontend teszt

A frontend unit teszt csak azt rögzítse, hogy a dialog a backend által adott listát jeleníti meg és azon keres. Ne mockolj bele banki egységet úgy, mintha a frontendnek kellene kiszűrnie.

Fájlok, ahol meglévő minták vannak:

- `frontend-react/src/pages/ratemanagement/WorkgroupManager.test.tsx`
- `frontend-react/src/pages/rates/components/BranchPickerModal.tsx`

Egy minimális frontend teszt cél:

- mockolt `rateCreationApi.getBranches()` csak pénztárakat ad;
- keresés `BR100`-ra talál;
- keresés `ERB`-re nincs találat, mert az már a backend válaszban sincs jelen.

## Ellenőrzési parancsok fejlesztői környezetben

Backend célzott teszt:

```powershell
cd backend
.\mvnw.cmd -Dtest=RateCreationServiceTest test
```

Ha repository integrációs teszt is készült:

```powershell
cd backend
.\mvnw.cmd -Dtest=RateCreationServiceTest,BranchRepositoryTest test
```

Frontend célzott teszt, ha módosult frontend teszt:

```powershell
cd frontend-react
npm test -- BranchPickerModal
```

Teljesebb ellenőrzés, ha a backend service/repository és frontend teszt is változott:

```powershell
cd backend
.\mvnw.cmd test

cd ..\frontend-react
npm run typecheck
npm test
```

## Acceptance checklist

A javítás akkor tekinthető késznek, ha:

- `GET /api/v1/rate-creation/branches?workgroupId=...` csak `PENZTAR` típusú, aktív, nem értéktári branch-eket ad vissza.
- A válaszban nincs `ERB`, `FRB`, `RB`, `MNB`, `TH`, `UPT`, `TRB`, `PRB`, `JRB`, `FOP1`.
- A válaszban nincs `ERTEKTAR` típusú vagy `isVault=true` branch.
- A `POST /api/v1/rate-creation/workgroups/{workgroupId}/branches` nem fogad el nem-pénztár branch ID-t.
- Cross-tenant védelem változatlanul megmarad.
- Új végpont nem jön létre.
- Flyway migráció nem jön létre.
- Frontend üzleti szűrő nem helyettesíti a backend szűrést.

## Rövid konklúzió

A jelenlegi implementáció hibája nem a dialog renderelésében van, hanem a backend rate-creation branch-listázó és branch-hozzárendelő logikájában. A lista endpoint túl szélesen kérdez: minden aktív céges branch-et visszaad. Az FK02-C javítás gyökere ezért a `RateCreationService` és a `BranchRepository` szintjén van: pénztár-only lekérdezést és pénztár-only mentési validációt kell bevezetni a meglévő `/rate-creation/branches` és `/rate-creation/workgroups/{id}/branches` végpontok mögött.