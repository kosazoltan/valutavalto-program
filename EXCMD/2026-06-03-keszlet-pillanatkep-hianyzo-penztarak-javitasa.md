<system_context>
# EXCMD konverter — közös instrukció (SABLON 2, valutaváltó)

## Kontextus
Ezt a specifikációt az AI-ügynök a Készlet pillanatkép (Stock snapshot) modulban tapasztalt hiányzó pénztárak hibájának javításához használja fel.
A projekt helye: Valutaváltó Repo (`D:\repo\valutavalto-program`).

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: 3 Electron kliens (`penztar-client`, `kozponti-client`, `arfolyam-keszito-client`)
- **Adatbázis**: PostgreSQL + Flyway (szerver), SQLite offline mirror (kliens)

## Szerepkörök (Roles)
- Főértéktáros
- Főértéktáros helyettes
- Senior szoftverarchitekt (konvertáló szerep)

## Hatókör (Scope)

### IN
- **Készlet pillanatkép – Hiányzó pénztárak javítása**
  - A backend lekérdezés (`StockSnapshotService.java`) javítása, hogy a Készlet pillanatkép modul lekérdezésekor minden körzetnél (területnél) az értéktár mellett az összes hozzá tartozó aktív lakossági pénztár is megjelenjen oszlopként.
  - A hozzárendelés alapja az Irodák és körzetek törzsadatban rögzített területi besorolás: a `Branch` entitás `vault_territory_id` mezője.
  - A valódi fizikai irodák (8 értéktár + 65 pénztár) szűrése és a virtuális partnerek (inaktív / virtuális, `is_virtual = TRUE`) elrejtése a lekérdezésből.
  - A területeken belüli sorrend rögzítése: az első oszlop mindig a területi Értéktár (`isVault = TRUE`), amelyet a hozzá tartozó pénztárak követnek névsor szerint (`isVault DESC, name ASC`).
  - Dinamikus Excel-export és képernyős megjelenítés támogatása (ugyanabból a közös lekérdezési forrásból).

### OUT
- Új területek vagy pénztárak felvétele a törzsadatokba (Irodák és körzetek törzsadat-szerkesztő feladatkör).
- Készletértékek vagy napi forgalmi adatok számítási logikájának javítása (ha egyéb hibák vannak).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### [FR-01] Dinamikus területi iroda- és pénztár-lekérdezés
- **Leírás**: A készlet pillanatkép lekérdezésekor a backend az adott cég (`companyId`) összes olyan aktív, nem virtuális `Branch` rekordját lekéri, amely rendelkezik értéktári terület besorolással (`vault_territory_id` nem null).
- **Forrás**: FK-019_Keszlet_pillanatkep_Hianyzo_penztarak.md
- **Prio**: Must
- **Csomag/Komponens**: `backend` (service/[StockSnapshotService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java))
- **Acceptance**: A visszaadott snapshot adatokban minden régióhoz az összes hozzárendelt pénztár is szerepel a válaszban (például SZEGED fül esetén: Szeged Értéktár + Szeged Móra + összes többi Szeged-régiós pénztár).

### [FR-02] Irodák rendezési sorrendje a területi fülön
- **Leírás**: Egy adott területen belül a branch-ek (oszlopok) sorrendje fixen a következő legyen:
  1. Első helyen a területi Értéktár (`isVault = true`).
  2. Utána a lakossági pénztárak (`isVault = false`) ábécérendben név szerint.
- **Forrás**: FK-019_Keszlet_pillanatkep_Hianyzo_penztarak.md
- **Prio**: Must
- **Csomag/Komponens**: `backend` (service/[StockSnapshotService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java))
- **Acceptance**: A `RegionSnapshotDto.branches` lista első eleme a körzeti Értéktár, a további elemek pedig ábécérendbe rendezett pénztárak.

### [FR-03] Üres területek kezelése
- **Leírás**: Ha egy területhez a törzsadatban nem tartozik lakossági pénztár (kizárólag az értéktár van hozzárendelve), a rendszer nem dobhat hibát: az adott területi fülön csak az értéktár oszlop és a Területi összesen oszlop jelenik meg.
- **Forrás**: FK-019_Keszlet_pillanatkep_Hianyzo_penztarak.md
- **Prio**: Should
- **Csomag/Komponens**: `backend` / `frontend-react`
- **Acceptance**: Ha a Szekszárdi körzetben nincs pénztár, a SZEKSZARD fül betölt, nem crash-el, és csak a Szekszárd Értéktár oszlop látható.

### [FR-04] Excel export konzisztencia
- **Leírás**: Az Excel letöltés funkció ugyanabból a backend lekérdezésből táplálkozik, mint a képernyős nézet. A letöltött `.xlsx` fájl minden területi lapján az értéktár mellett az összes hozzá tartozó pénztár is megjelenik oszlopként, a helyes rendezés szerint.
- **Forrás**: FK-019_Keszlet_pillanatkep_Hianyzo_penztarak.md
- **Prio**: Must
- **Csomag/Komponens**: `backend` (service/[StockSnapshotExcelService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotExcelService.java))
- **Acceptance**: A letöltött Excel fájl területi fülein a fejléc és az adatsorok oszlopai megegyeznek a képernyőn látható elrendezéssel.

### [FR-05] Virtuális partnerek és más tenantok kizárása
- **Leírás**: A készlet pillanatkép kizárólag a valódi fizikai irodák adatait összesíti. Más tenantok adatai, valamint a virtuális partnerek (például `ERB`, `FRB` stb. könyvelési entitások) nem szerepelhetnek az adatok között.
- **Forrás**: FK-019_Keszlet_pillanatkep_Hianyzo_penztarak.md / FK-016
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Acceptance**: A lekérdezés kizárja a `is_virtual = TRUE` rekordokat és a `company_id` szűréssel garantálja a multi-tenant izolációt.
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok
Nincs közvetlen sémamódosítás, a javítás meglévő adatmezőkre és kapcsolatokra épül:
- `Branch.vaultTerritoryId` (`Integer`): Kapcsolat a területi törzsadathoz.
- `Branch.isVault` (`Boolean`): Jelzi, hogy az iroda Értéktár-e.
- `Branch.isVirtual` (`Boolean`): Jelzi, hogy az iroda virtuális partner-e (FK-016 módosítás alapján).
- `Branch.isActive` (`Boolean`): Jelzi, hogy az iroda aktív-e.
</data_structure>

<integration_points>
## Integrációs Pontok
Nincs külső integráció. A `StockSnapshotController` és a `StockSnapshotExcelService` a `StockSnapshotService` által biztosított `StockSnapshotDto` struktúrát használja fel.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Feltérképezés és Kódvizsgálat (Preparation)
1. Vizsgáld meg a [StockSnapshotService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java) fájlt és annak `getFullSnapshot(UUID companyId)` metódusát.
2. A jelenlegi implementáció a `branchRepository.findActiveWithRegionByCompanyId(companyId)` metódust hívja, amely csak azokat az irodákat adja vissza, amelyek `regionCode` mezője nem null (ezért maradtak ki a pénztárak, amelyeknél a `regionCode` mező null értékű).

### Phase 2: Backend javítás (Backend)
1. **Repository Dependency**: Injectáld a `VaultTerritoryRepository`-t a [StockSnapshotService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java) osztályba:
   ```java
   private final VaultTerritoryRepository vaultTerritoryRepository;
   ```
2. **Branch-ek lekérdezése és szűrése**: Cseréld le a `findActiveWithRegionByCompanyId` hívást az összes aktív cég-szintű branch lekérésére, majd szűrd ki a virtuális partnereket és rendezd őket (`isVault DESC, name ASC`):
   ```java
   List<Branch> activeRealBranches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId).stream()
           .filter(b -> !Boolean.TRUE.equals(b.getIsVirtual()))
           .collect(Collectors.toList());

   // Értéktárak kerülnek előre (isVault=true), utána a pénztárak névsorban
   activeRealBranches.sort(Comparator.comparing((Branch b) -> b.getIsVault() != null && b.getIsVault(), Comparator.reverseOrder())
           .thenComparing(Branch::getName));
   ```
3. **Régió (regionCode) leképezése vaultTerritoryId alapján**:
   Mivel a pénztárak `regionCode` mezője null, a területi csoportosítást a `vaultTerritoryId` alapján kell megoldani. Töltsd be az aktív területeket, és készíts egy map-et a `vaultTerritoryId` -> legacy `regionCode` leképzéshez a terület nevének normalizálásával:
   ```java
   List<VaultTerritory> territories = vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId);
   Map<Integer, String> territoryIdToRegionCode = new HashMap<>();

   // Normalizáló segédtömb a REGION_NAMES map értékeihez való illesztéshez
   Map<String, String> regionNameToCode = new HashMap<>();
   for (Map.Entry<String, String> entry : REGION_NAMES.entrySet()) {
       regionNameToCode.put(entry.getValue(), entry.getKey());
   }

   for (VaultTerritory vt : territories) {
       String normalizedName = vt.getName().toUpperCase()
           .replace("Á", "A").replace("É", "E").replace("Í", "I")
           .replace("Ó", "O").replace("Ö", "O").replace("Ő", "O")
           .replace("Ú", "U").replace("Ü", "U").replace("Ű", "U")
           .trim();
       String code = regionNameToCode.get(normalizedName);
       if (code != null) {
           territoryIdToRegionCode.put(vt.getId(), code);
       }
   }
   ```
4. **Csoportosítás módosítása**:
   A `getFullSnapshot` csoportosító ciklusában használd a fenti leképezést a `regionCode` meghatározásához:
   ```java
   Map<String, List<BranchSnapshotDto>> branchesByRegion = new LinkedHashMap<>();
   for (Branch branch : activeRealBranches) {
       BranchSnapshotDto branchDto = buildBranchSnapshot(branch, stockByBranch, wuByBranch, today, codes);
       String regionCode = null;
       if (branch.getVaultTerritoryId() != null) {
           regionCode = territoryIdToRegionCode.get(branch.getVaultTerritoryId());
       }
       if (regionCode == null) {
           regionCode = branch.getRegionCode(); // fallback a legacy mezőre
       }
       if (regionCode != null) {
           branchesByRegion.computeIfAbsent(regionCode, k -> new ArrayList<>()).add(branchDto);
       }
   }
   ```

### Phase 3: Tesztek frissítése
Mivel a `StockSnapshotService` már a `branchRepository.findByCompanyIdAndIsActiveTrue(companyId)` metódust hívja, frissíteni kell az egységteszteket:
1. Módosítsd a [StockSnapshotServiceTest.java](file:///d:/repo/valutavalto-program/backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotServiceTest.java) fájlt.
2. Cseréld le az összes `when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID)).thenReturn(...)` hívást a következőre:
   ```java
   when(branchRepository.findByCompanyIdAndIsActiveTrue(COMPANY_ID)).thenReturn(...);
   ```
3. Szükség esetén mockold a `vaultTerritoryRepository` hívásokat is a tesztben, hogy a tesztágakban használt branch-eknél a `vaultTerritoryId` helyes `regionCode`-ra képződjön le (vagy hagyd, hogy a legacy `regionCode` fallback ág fusson le a teszt-branch-eknél).

### Phase 4: Ellenőrzés és verifikáció (Verification)
1. Futtasd a backend teszteket: `mvn -pl backend test`
2. Ellenőrizd a frontend képernyős megjelenítését és győződj meg róla, hogy az Excel letöltés is helyesen generálja le a pénztárakat az oszlopok között.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)

| # | Kérdés | Kockázat / Hatás | Mit kell tudni |
|---|---|---|---|
| 1 | Van-e olyan aktív pénztár, amelynél sem a `vault_territory_id`, sem a legacy `region_code` nincs kitöltve? | Az ilyen iroda teljesen kimarad a területi fülekről, csak a cégösszesítőben fog megjelenni | Az Irodák és körzetek törzsadatban minden valódi pénztárhoz hozzá kell rendelni a megfelelő területi értéktárat. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist

### 1. Backend ellenőrzések
- [ ] A `StockSnapshotServiceTest` egységtesztek sikeresen lefutnak.
- [ ] A `getFullSnapshot` endpoint válasza tartalmazza a lakossági pénztárakat is a megfelelő területi fül alatt.
- [ ] A JUnit integrációs tesztek megerősítik a rendezést (értéktár az első helyen, pénztárak utána ábécérendben).
- [ ] Más tenant adatai nem szivárognak át.

### 2. Kliens oldali verifikáció
- [ ] A Készlet pillanatkép képernyőn a területi füleken (pl. SZEGED) megjelenik az Értéktár mellett az összes pénztár is oszlopként.
- [ ] Az Excel letöltés gombra kattintva a generált `.xlsx` fájl lapjain a táblázat szerkezete megegyezik a képernyőn láthatóval, a pénztárak adatai a helyükön szerepelnek.
</verification_checklist>
