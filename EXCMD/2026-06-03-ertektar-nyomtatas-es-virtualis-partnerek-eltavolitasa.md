<system_context>
# EXCMD konverter — közös instrukció (SABLON 2, valutaváltó)

## Kontextus
Ezt a specifikációt az AI-ügynök az átadás-átvételi bizonylatnyomtatás, valamint a virtuális partnerek Központi Munkaállomás felületeiről történő eltávolításának megvalósításához használja fel. 
A projekt helye: Valutaváltó Repo (`D:\repo\valutavalto-program`).

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: 3 Electron kliens (`penztar-client`, `kozponti-client`, `arfolyam-keszito-client`)
- **Adatbázis**: PostgreSQL + Flyway (szerver), SQLite offline mirror (kliens)

## Szerepkörök (Roles)
- Pénztáros
- Értéktáros
- Értéktáros helyettes
- Főértéktáros
- Főértéktáros helyettes
- Belsőellenőr
- Ügyvezető
- Admin
- Senior szoftverarchitekt (konvertáló szerep)

## Hatókör (Scope)

### IN
- **Task 1: Értéktári felület – Bizonylat előnézet és nyomtatás az átadás-átvétel rögzítése után**
  - „Bizonylat Előnézet" modal megjelenítése sikeres rögzítés után a `ShipmentNewPage.tsx` felületén.
  - A bizonylat tartalmának pontos renderelése: cégfejléc (cégnév, cím, adószám a kiválasztott Best Change / Expressz cég szerint), kérő iroda (értéktár) neve, cél iroda (pénztár) neve, szállító neve, plombaszám, valuta és összeg, forintosított érték (5 Ft-ra kerekítve), kért kézbesítési dátum, megjegyzés.
  - Alul „Nyomtatás" gomb, amely az Electron `window.electronAPI.printReceipt` IPC metódusán keresztül nyomtatja a bizonylatot.
  - `@media print` CSS formázás a helyes nyomtatási képhez (gombok, modal keretek, háttér elrejtése).
  - A nyomtatás kizárólag frissen rögzített átadás-átvételnél érhető el (listából nem).
  
- **Task 2: Központi kliens – Virtuális partnerek eltávolítása a Központi Munkaállomás program összes felületéről**
  - Adatbázis szinten a valódi irodák (8 értéktár + 65 pénztár) és a virtuális partnerek (könyvelési entitások: ERB, FRB, RB, JRB, PRB, TRB, MNB, UPT, TH, FOP1) megkülönböztetése `is_virtual` logikai mezővel.
  - Flyway adatbázis-migráció (`V292__add_branch_virtual_flag.sql`) létrehozása, az érintett 10 kód virtual flagjének `TRUE`-ra állítása, index létrehozása.
  - A `Branch` entitás és `BranchDto` kiterjesztése az `isVirtual` mezővel, a `BranchMapper` frissítése.
  - A backend lekérdező végpontok (`/branches`, `/branches/my-territory`) kiegészítése a `clientType` paraméter szerinti szűréssel: ha `clientType=CENTRAL`, a virtuális partnerek nem jelenhetnek meg.
  - A frontend React API kliens (`client.ts` request interceptor és `settings.ts`) frissítése, hogy a Központi Munkaállomás program flavor esetén (`VITE_APP_FLAVOR === 'central-workstation'`) a `clientType=CENTRAL` paraméter automatikusan átadásra kerüljön.
  - Az értéktári és pénztári programok működésének érintetlenül hagyása (a virtuális partnerek az átadás-átvételi dropdownokban megmaradnak).

### OUT
- Nyomtatás korábbi, már listázott átadás-átvételeknél.
- PDF fájlba exportálás / emailben küldés.
- A virtuális partnerek tényleges fizikai törlése az adatbázisból.
</system_context>

<functional_spec>
## Funkcionális Követelmények

### [FR-01] Sikeres rögzítés utáni Bizonylat Előnézet Modal
- **Leírás**: Az átadás-átvételi igény sikeres beküldése (`POST /shipments` és sikeres `/submit`) után nem történik azonnali navigáció, hanem megnyílik a „Bizonylat Előnézet" modal.
- **Forrás**: fejlesztesi-keres-atadas-nyomtatas.md
- **Prio**: Must
- **Csomag/Komponens**: `frontend-react` (pages/shipments/[ShipmentNewPage.tsx](file:///d:/repo/valutavalto-program/frontend-react/src/pages/shipments/ShipmentNewPage.tsx))
- **Bemenő adatok**: A mentett és beküldött `ShipmentRequest` válaszobjektum.
- **Kimenet / Visszajelzés**: A `ReceiptPreviewModal` megjelenése a képernyőn.

### [FR-02] Bizonylat tartalom renderelése
- **Leírás**: A modal görgethetően jeleníti meg a bizonylatot a meglévő hőpapíros (80mm) elrendezésben. Tartalmaznia kell:
  - Cégfejléc: a tranzakciót végző cég neve, címe, adószáma (a nyugtán szereplő logikával megegyezően, BEST_CHANGE vagy EXPRESSZ szerint).
  - Kérő iroda neve és kódja (értéktár).
  - Cél iroda neve és kódja (pénztár).
  - Szállító neve (`carrierName`).
  - Plombaszám (`sealNumber`).
  - Valutanem és összeg (`currencyCode`, `foreignAmount`).
  - Forintosított érték 5 HUF-ra kerekítve (`roundedHufAmount` / `hufAmount`).
  - Kért kézbesítési dátum (`date` / `requestedDeliveryDate`).
  - Megjegyzés (`transferNote` / `notes`), amennyiben ki lett töltve (üres megjegyzés esetén nem jelenik meg üres sor).
- **Forrás**: fejlesztesi-keres-atadas-nyomtatas.md
- **Prio**: Must
- **Csomag/Komponens**: `frontend-react` (components/electron/[ReceiptPreviewModal.tsx](file:///d:/repo/valutavalto-program/frontend-react/src/components/electron/ReceiptPreviewModal.tsx))
- **Acceptance**: A megnyitott modalban az összes fenti adat pontosan olvasható és megfelel a beküldött adatoknak.

### [FR-03] Bizonylat nyomtatási lehetőség (Electron print)
- **Leírás**: A modal alján található „Nyomtatás" gomb kattintásra meghívja az Electron IPC réteget (`window.electronAPI.printReceipt(JSON.stringify(receiptData))`).
- **Forrás**: fejlesztesi-keres-atadas-nyomtatas.md
- **Prio**: Must
- **Csomag/Komponens**: `frontend-react` / `penztar-client`
- **Acceptance**: Electron környezetben a gombra kattintva a nyomtatási parancs kiküldésre kerül, sikeres nyomtatás esetén zöld toast értesítés jelenik meg és a modal bezáródik. Webes környezetben a nyomtatás nem engedélyezett (figyelmeztető toast).

### [FR-04] Nyomtatás korlátozása (Csak friss rögzítéskor)
- **Leírás**: A bizonylat előnézet és nyomtatás gomb kizárólag a sikeres űrlap-beküldés után érhető el. A korábbi szállítmányok listájából (például a Szállítólevelek menüpont alatt) megnyitott részleteknél a nyomtatás nem érhető el.
- **Forrás**: fejlesztesi-keres-atadas-nyomtatas.md
- **Prio**: Must
- **Csomag/Komponens**: `frontend-react`
- **Acceptance**: A listanézetből megnyitott korábbi szállítmányok részleteinél a nyomtatás és a bizonylat előnézet modal nem érhető el.

### [FR-05] Adatbázis szintű virtuális partner megkülönböztetés
- **Leírás**: A `branch` tábla kiegészül egy `is_virtual` boolean mezővel, amely alapértelmezetten `FALSE`. A seedelt 10 virtuális partner kódja (`ERB`, `FRB`, `RB`, `JRB`, `PRB`, `TRB`, `MNB`, `UPT`, `TH`, `FOP1`) esetén a mező értéke `TRUE`-ra módosul.
- **Forrás**: FK-016_Virtualis_partnerek_eltavolitasa (1).md
- **Prio**: Must
- **Csomag/Komponens**: `backend` (Flyway migráció, `Branch` entitás)
- **Acceptance**: A Flyway migráció lefutása után a `branch` táblában létezik az `is_virtual` oszlop és index, az érintett 10 sor értéke `true`.

### [FR-06] Virtuális partnerek elrejtése a Központi kliens felületeiről
- **Leírás**: A Központi Munkaállomás program (`VITE_APP_FLAVOR === 'central-workstation'`) felületein (Országos dashboard, Kezelési díj dekád riport, Átlag árfolyam riport, Napkönyv stb.) a virtuális partnerek nem szerepelhetnek. A frontend a `/branches` végpontok lekérdezésekor átadja a `clientType=CENTRAL` query paramétert, aminek hatására a backend kizárólag a valódi irodákat (8 értéktár + 65 pénztár, `is_virtual = false`) adja vissza.
- **Forrás**: FK-016_Virtualis_partnerek_eltavolitasa (1).md
- **Prio**: Must
- **Csomag/Komponens**: `backend` / `frontend-react`
- **Acceptance**: A Központi klienssel bejelentkezve az Országos dashboardon, a riportok iroda-választóiban az ERB, FRB, RB, JRB, PRB, TRB, MNB, UPT, TH, FOP1 kódú irodák egyáltalán nem jelennek meg.

### [FR-07] Értéktári átadás-átvétel regressziós mentessége
- **Leírás**: A virtuális partnerek kiszűrése kizárólag a Központi Munkaállomásra vonatkozik. Az Értéktári program átadás-átvételi és bizonylat-kezelési menüiben (ahol a `/branches/vault-counterparties` vagy nem central paraméterezett `/branches` hívások futnak) a 10 könyvelési entitás továbbra is megjelenik.
- **Forrás**: FK-016_Virtualis_partnerek_eltavolitasa (1).md
- **Prio**: Must
- **Csomag/Komponens**: `frontend-react` (vault-context)
- **Acceptance**: Az értéktári kliensbe lépve az Átadás-átvétel cél iroda legördülőjében a virtuális partnerek (például ERB, FRB) továbbra is választhatóak.

## Nem-funkcionális követelmények (NFR)
- **[NFR-01] Kód újrafelhasználás**: A bizonylat rendereléséhez a meglévő [ReceiptPreviewModal.tsx](file:///d:/repo/valutavalto-program/frontend-react/src/components/electron/ReceiptPreviewModal.tsx) komponenst kell kiterjeszteni a `transfer` típusra vonatkozó részletes adatokkal, elkerülve a külön bizonylat-megjelenítő fájl duplikálását.
- **[NFR-02] Forintosított kerekítés**: A bizonylaton szereplő forint értéket a magyar kerekítési szabályoknak megfelelően 5 Ft-ra kerekítve kell megjeleníteni.
- **[NFR-03] Dátum formázás**: A kézbesítési dátumot `yyyy. MM. dd.` formátumban kell renderelni a bizonylaton.
- **[NFR-04] Nyomtatási CSS**: A modal `@media print` stíluslapja biztosítsa, hogy nyomtatáskor csak a Courier New betűtípussal formázott bizonylat-tartalom jelenjen meg, a modal fejléc, bezáró gomb és az alsó nyomtatás/mégse gombok rejtve maradjanak.
- **[NFR-05] Offline képesség**: A bizonylat adatai offline módban történő rögzítéskor is megjeleníthetőek kell legyenek a helyi SQLite adatbázis adatai alapján (csak a Pénztári/Értéktári kliens esetén érintett).
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

### 1. Adatbázis sémamódosítás (PostgreSQL / Flyway)
Hozd létre a következő migrációs fájlt: `backend/src/main/resources/db/migration/V292__add_branch_virtual_flag.sql`

```sql
-- backend/src/main/resources/db/migration/V292__add_branch_virtual_flag.sql
-- Új mező hozzáadása a branch táblához a valódi iroda és a virtuális partner megkülönböztetésére

ALTER TABLE branch ADD COLUMN is_virtual BOOLEAN NOT NULL DEFAULT FALSE;

-- A 10 darab virtuális partner (könyvelési entitás) megjelölése
UPDATE branch SET is_virtual = TRUE
WHERE code IN ('ERB', 'FRB', 'RB', 'JRB', 'PRB', 'TRB', 'MNB', 'UPT', 'TH', 'FOP1');

-- Index létrehozása a szűrések gyorsítására
CREATE INDEX idx_branch_is_virtual ON branch (is_virtual);
```

### 2. JPA Entitás módosítás
Bővítsd a [Branch.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java) entitást az `is_virtual` oszloppal:

```java
    @Column(name = "is_virtual", nullable = false)
    @Builder.Default
    private Boolean isVirtual = false;
```

### 3. DTO és Mapper módosítások
- **BranchDto.java**: adj hozzá egy `private Boolean isVirtual;` mezőt a [BranchDto.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/dto/BranchDto.java) fájlhoz.
- **BranchMapper.java**: egészítsd ki a `.isVirtual(entity.getIsVirtual())` leképzést a [BranchMapper.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/mapper/BranchMapper.java) `toDto` metódusában.
</data_structure>

<integration_points>
## Integrációs Pontok

### 1. Electron IPC Nyomtatás
A frontend és az Electron kliens a `window.electronAPI.printReceipt` IPC csatornán kommunikál. A `ReceiptPreviewModal` a bizonylat adatait JSON string-ként adja át a kliensnek:
```typescript
const ok = await window.electronAPI.printReceipt(JSON.stringify(printReceiptData));
```

### 2. HTTP GET query paraméter (`clientType`)
A `/branches` és `/branches/my-territory` végpontok kiegészülnek egy opcionális `clientType` query paraméterrel:
- `clientType=CENTRAL`: Aktiválja a virtuális partnerek elrejtését a backend oldalon.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
1. Hozd létre a Flyway migrációs fájlt a `V292__add_branch_virtual_flag.sql` névvel.
2. Futtasd a helyi migrációt: `mvn -pl backend flyway:migrate` (vagy a környezetnek megfelelő parancsot).

### Phase 2: Backend entitások és lekérdezések (Backend)
1. Egészítsd ki a [Branch.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java) entitást és a [BranchDto.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/dto/BranchDto.java)-t az `isVirtual` mezővel.
2. Frissítsd a [BranchMapper.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/mapper/BranchMapper.java)-t.
3. Egészítsd ki a [BranchRepository.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java) fájlt a szűrt lekérdezésekkel:
   ```java
   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.isVirtual = false")
   List<Branch> findByCompanyIdAndIsVirtualFalse(@Param("companyId") UUID companyId);

   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.isActive = true AND b.isVirtual = false ORDER BY b.name")
   List<Branch> findByCompanyIdAndIsActiveTrueAndIsVirtualFalse(@Param("companyId") UUID companyId);

   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.isVirtual = false AND (" +
          "LOWER(b.name) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
          "LOWER(b.code) LIKE LOWER(CONCAT('%', :search, '%')))")
   List<Branch> searchByCompanyIdAndNameOrCodeAndIsVirtualFalse(
       @Param("companyId") UUID companyId,
       @Param("search") String search
   );

   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.branchType.code = :typeCode AND b.isVirtual = false")
   List<Branch> findByCompanyIdAndBranchTypeCodeAndIsVirtualFalse(
       @Param("companyId") UUID companyId,
       @Param("typeCode") String typeCode
   );

   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.branchStatus.code = :statusCode AND b.isVirtual = false")
   List<Branch> findByCompanyIdAndBranchStatusCodeAndIsVirtualFalse(
           @Param("companyId") UUID companyId, @Param("statusCode") String statusCode);

   @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.parentBranch IS NULL AND b.isVirtual = false")
   List<Branch> findRootBranchesByCompanyIdAndIsVirtualFalse(@Param("companyId") UUID companyId);
   ```
4. Egészítsd ki a [BranchService.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/BranchService.java) fájlt:
   - A `findAll`, `findAllActive`, `search`, `findByType`, `findByStatus`, `findRootBranches` metódusok kapjanak egy `boolean excludeVirtual` paramétert. Ha ez `true`, akkor a repository új, szűrt metódusait hívják meg, különben az eredeti metódusokat.
   - Hozz létre paraméter nélküli kompatibilitási overloadokat (amelyek `excludeVirtual = false` értéket adnak át).
5. Egészítsd ki a [BranchController.java](file:///d:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java) fájlt:
   - A `getAllBranches` és a `getMyTerritoryBranches` végpontok fogadjanak egy opcionális `@RequestParam(required = false) String clientType` query paramétert.
   - Határozd meg a szűrési feltételt: `boolean excludeVirtual = "CENTRAL".equalsIgnoreCase(clientType);`
   - Add át ezt a logikai paramétert a Service hívásoknak.

### Phase 3: Frontend kliens oldali módosítások (Frontend/Client)
1. **Frontend-react Axios kliens**: A [client.ts](file:///d:/repo/valutavalto-program/frontend-react/src/services/api/client.ts) request interceptorában automatikusan add hozzá a `clientType=CENTRAL` query paramétert a `/branches` kezdetű GET requestekhez, ha az alkalmazás Központi Munkaállomás flavorben fut:
   ```typescript
   api.interceptors.request.use((config) => {
     if (config.url?.startsWith('/branches') && import.meta.env.VITE_APP_FLAVOR === 'central-workstation') {
       config.params = { ...config.params, clientType: 'CENTRAL' };
     }
     return config;
   });
   ```
2. **Settings API**: Módosítsd a [settings.ts](file:///d:/repo/valutavalto-program/frontend-react/src/services/api/settings.ts) fájlt, hogy ha a config paraméterek expliciten nincsenek átírva, a `clientType` paraméter ott is átadásra kerüljön (defenzív redundancia).
3. **ReceiptPreviewModal.tsx frissítése**: Egészítsd ki a [ReceiptPreviewModal.tsx](file:///d:/repo/valutavalto-program/frontend-react/src/components/electron/ReceiptPreviewModal.tsx) `receiptData.type === 'transfer'` ágát a részletes adatok megjelenítéséhez:
   ```typescript
   {receiptData.type === 'transfer' && (
     <div className="space-y-1">
       <p className="font-semibold text-center mt-1">ÁTADÁSI BIZONYLAT</p>
       <p><span className="font-semibold">Kérő iroda:</span> {receiptData.branchCode}</p>
       {receiptData.transferTarget && (
         <p><span className="font-semibold">Cél iroda:</span> {receiptData.transferTarget}</p>
       )}
       {receiptData.carrierName && (
         <p><span className="font-semibold">Szállító:</span> {receiptData.carrierName}</p>
       )}
       {receiptData.sealNumber && (
         <p><span className="font-semibold">Plombaszám:</span> {receiptData.sealNumber}</p>
       )}
       {receiptData.currencyCode && (
         <p><span className="font-semibold">Valuta:</span> {receiptData.currencyCode}</p>
       )}
       {receiptData.foreignAmount !== undefined && (
         <p><span className="font-semibold">Összeg:</span> {formatAmount(receiptData.foreignAmount)}</p>
       )}
       {(receiptData.roundedHufAmount !== undefined || receiptData.hufAmount !== undefined) && (
         <p><span className="font-semibold">Forint érték:</span> {formatInt(receiptData.roundedHufAmount ?? receiptData.hufAmount)} HUF</p>
       )}
       {receiptData.date && (
         <p><span className="font-semibold">Kézbesítési dátum:</span> {receiptData.date}</p>
       )}
       {receiptData.transferNote && (
         <p><span className="font-semibold">Megjegyzés:</span> {receiptData.transferNote}</p>
       )}
     </div>
   )}
   ```
4. **ShipmentNewPage.tsx módosítása**:
   - Helyezd el a `ReceiptPreviewModal` komponenst az oldal alján.
   - Vegyél fel állapotokat: `showReceiptModal` (boolean) és `printReceiptData` (`PrintReceiptData | null`).
   - A `submit` metódusban a sikeres mentés (`shipmentRequestApi.submit(created.id)`) után ne navigálj el azonnal. Ehelyett állítsd be a `printReceiptData` értékét a válaszobjektum alapján, és nyisd meg a modalt:
     ```typescript
     setPrintReceiptData({
       type: 'transfer',
       companyType: worker?.companyCode?.toUpperCase().includes('BEST') ? 'BEST_CHANGE' : 'EXPRESSZ',
       receiptNumber: created.requestNumber || created.id,
       branchCode: created.requestingBranchName || created.requestingBranchId,
       cashierName: created.requestedByWorkerName || worker?.fullName || '',
       date: created.requestedDeliveryDate || created.requestedAt?.slice(0, 10) || '',
       time: created.requestedAt ? new Date(created.requestedAt).toTimeString().slice(0, 8) : '',
       currencyCode: created.items?.[0]?.currencyCode || '',
       foreignAmount: created.items?.[0]?.requestedAmount || 0,
       transferTarget: created.targetBranchName || created.targetBranchId,
       transferNote: created.notes,
       carrierName: created.carrierName,
       sealNumber: created.sealNumber,
     });
     setShowReceiptModal(true);
     ```
   - A modal bezárásakor (`onClose`) navigálj el a `/shipments` oldalra.

### Phase 4: Ellenőrzés és verifikáció (Verification)
1. Futtasd a backend teszteket: `mvn -pl backend test`
2. Futtasd a frontend teszteket: `npm run test`
3. Győződj meg a linter futásáról és a warning-mentességről.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)

| # | Kérdés | Kockázat / Hatás | Mit kell tudni |
|---|---|---|---|
| 1 | Hogyan jelenjen meg a cégfejléc Best Change vs Expressz esetén az átadási bizonylaton? | Ha nem egyezik meg a nyugtával, szabálytalansági kockázatot jelent | Az automatikus cégfejléc választást a bejelentkezett worker cégkódja alapján kell beállítani (Best Change Zrt. adószám: 32313332-2-02, Expressz Kft. adószám: 14040535-2-02). |
| 2 | Van-e olyan Központi kliens felület, amely nem axioson keresztül hívja a `/branches` végpontot? | Ha van közvetlen natív fetch hívás, ott nem érvényesül a request interceptor | A frontend átvizsgálása alapján minden API kommunikáció a megosztott Axios kliensen (`api.get`) fut, de a regressziók megelőzésére a teszteket le kell futtatni. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist

### 1. Adatbázis és Backend tesztek
- [ ] Flyway migráció hibamentesen lefut local környezetben.
- [ ] `Branch` entitás JPA lekérdezései sikeresek, a virtuális partnerek lekérdezhetőek a vault contextusban, de rejtettek central contextusban.
- [ ] A JUnit tesztek igazolják a `clientType=CENTRAL` szerinti helyes elrejtést és cross-tenant védelmet.

### 2. Frontend és Kliens tesztek
- [ ] `ReceiptPreviewModal` sikeresen rendereli az átadási bizonylatot kérő és cél irodával, szállítóval, plombaszámmal, valutával, kerekített forintösszeggel.
- [ ] `@media print` stílusok működnek, a nyomtatási kép tiszta, nem tartalmaz felesleges gombokat.
- [ ] A Központi kliens dashboardján és minden legördülőjében (Kezelési díj dekád riport, Átlag árfolyam riport, Napkönyv) az ERB, FRB stb. partnerek eltűntek.
- [ ] Az Értéktári kliens átadás-átvétel felületén a virtuális partnerek továbbra is láthatóak és választhatóak (regressziós ellenőrzés).
</verification_checklist>
