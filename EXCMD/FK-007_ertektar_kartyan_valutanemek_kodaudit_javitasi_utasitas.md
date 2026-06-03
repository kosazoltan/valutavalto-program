# FK-007 kódaudit és javítási utasítás

**Modul:** Központi munkaállomás / Országos készlet  
**Téma:** Értéktár kártyákon valutanemek megjelenítése  
**Audit dátuma:** 2026-06-02  
**Kérés forrása:** `C:\Users\Kósa Zoltán\Downloads\FK-007_Ertektar_kartyan_valutanemek.md` és a mellékelt két képernyőkép  
**Fontos korlát:** Ez az audit kizárólag a jelenlegi forráskódban és migrációkban ellenőrzött tényekre épül. Nem történt adatbázis-lekérdezés futó környezet ellen.

## Vezetői összefoglaló

A jelenlegi kódbázisban az FK-007 célja részben már implementálva van: az Országos készlet oldal a `GET /inventory/stock` készletadat mellett meghívja a központi `GET /currencies` aktív valutanem-listát, és a kártyák sorait ebből a törzsből építi fel. Ez igazolja, hogy a kód már nem kizárólag a nyers készletsorokra támaszkodik.

Ugyanakkor a kódban maradt egy konkrét hiba: ha egy értéktár csak a `branchMeta` alapján kerül be a területi szekcióba, de nincs egyetlen sora sem a `/inventory/stock` válaszban, a frontend `items: []` üres kártyát injektál. Ilyenkor a kártyán `0 valuta` jelenik meg, nem a 22 aktív valutanem 0 egyenleggel. Ez közvetlenül magyarázza a mellékelt Békéscsaba képernyőképen látható `Békéscsaba Értéktár – 0 valuta` tünetet, ha az adott értéktárhoz nincs `cash_balance` sor.

## Mellékelt képernyőképekből ellenőrizhető tünetek

- A Szeged képernyőképen az értéktár kártya és a pénztárkártyák fejléce is `22 valuta` értéket mutat; a valutasorok látszanak.
- A Békéscsaba képernyőképen a `Békéscsaba Értéktár` kártya `0 valuta` értéket mutat, miközben a mellette lévő pénztárkártyák `22 valuta` sorral jelennek meg.
- A tünet nem általános valuta-törzs hiba: ugyanazon nézetben a pénztárkártyákon a 22 sor megjelenik.

## Kóddal igazolt jelenlegi adatút

### Frontend oldal

Az Országos készlet menüpont a jelenlegi kódban nem `kozponti-client/src/pages/OrszagosKeszlet/` útvonalra mutat, hanem a React frontend `CashierStocksPage` oldalára:

- `frontend-react/src/pages/central/CentralWorkstationPage.tsx`
  - `Országos készlet`
  - route: `/cashier-stocks`

Az oldal implementációja:

- `frontend-react/src/pages/inventory/CashierStocksPage.tsx`

Ebben a fájlban a készlet és a valutanem-törzs betöltése:

```tsx
const [stockResult, currencyResult] = await Promise.allSettled([
  api.get<InventoryItem[]>('/inventory/stock'),
  currencyApi.list(),
])
```

A `currencyApi.list()` a központi aktív valutanem-végpontot hívja:

- `frontend-react/src/services/api/exchange-rates.ts`
  - `GET /currencies`

A kártyák teljes listája `allItems` alatt a `currencies` tömbből épül:

```tsx
for (const branchName of branchNames) {
  const bal = balByBranch.get(branchName)
  for (const c of currencies) {
    result.push({
      id: `${branchName}|${c.code}`,
      branchName,
      currencyCode: c.code,
      currentBalance: bal?.get(c.code) ?? 0,
    })
  }
}
```

Ez helyes irány a pénztárakra és azokra az értéktárakra, amelyek legalább egy készletsorral szerepelnek a `/inventory/stock` válaszban.

### Backend oldal

A készletadat-végpont:

- `backend/src/main/java/hu/puzzleir/valuta/controller/InventoryController.java`
  - `GET /api/v1/inventory/stock`
  - szerepkörök: `MANAGER`, `ADMIN`, `FOERTEKTAR`, `UGYVEZETO`, `ERTEKTAR`
  - a service eredményét `CashBalanceDto` listára mapeli
  - `AccessScopeService` alapján további láthatósági szűrést alkalmaz

A mögöttes service:

- `backend/src/main/java/hu/puzzleir/valuta/service/InventoryService.java`
  - `getAllStock()`
  - `SecurityUtils.getCurrentCompanyId()` alapján company-szűrt `cash_balance` sorokat kér
  - aktív branch szűrést végez
  - territory-scoped role esetén területi szűrést is alkalmaz

A valutanem-végpont:

- `backend/src/main/java/hu/puzzleir/valuta/controller/CurrencyController.java`
  - `GET /api/v1/currencies`
  - `currencyRepository.findAllActiveOrdered()` alapján csak aktív valutákat ad vissza
  - szerepkörök között szerepel: `PENZTAR`, `ERTEKTAR`, `FOERTEKTAR`, `UGYVEZETO`

A repository rendezés:

- `backend/src/main/java/hu/puzzleir/valuta/repository/CurrencyRepository.java`
  - `findByActiveTrueOrderByDisplayOrderAsc()`

## Kóddal igazolt migrációs állapot

### Központi valutanem-törzs

- `backend/src/main/resources/db/migration/V271__fk006_currency_master_central.sql`
  - a `currency` tábla a rendszerszintű igazságforrás
  - DKK/NOK/SEK inaktiválva
  - aktív sorrend: HUF + 21 valuta
  - `display_order` beállítás

- `backend/src/main/resources/db/migration/V272__fk007_deactivate_unknown_tst_currency.sql`
  - TST inaktiválása, törlés nélkül

- `backend/src/main/resources/db/migration/V274__fix_rsd_currency_active.sql`
  - RSD biztosítása aktívan, `display_order=16`

Következtetés: a forráskód alapján van központi, aktív, rendezett valutanem-törzs. A képernyőképen látott `0 valuta` hiba nem abból következik, hogy a frontend egyáltalán nem hívja a központi valutalistát.

### BR105

- `backend/src/main/resources/db/migration/V250__branch_sync_br105_and_name_corrections.sql`
  - `BR105` beszúrása/szinkronizálása: `Békéscsaba Belváros 2`
  - `is_vault = FALSE`
  - `region` a Békéscsaba sibling branch alapján
  - `region_code` a Békéscsaba értéktárból klónozva

Következtetés: a kódban már van BR105-et kezelő migráció. A mellékelt FK-007 dokumentum `vault_territory_id` pótlásra vonatkozó állítása nem igazolódott migrációval: a V250 nem állít `vault_territory_id` mezőt, hanem `region` és `region_code` mezőkkel dolgozik.

## Hibák és kockázatok

### P1 - Üresen injektált értéktár kártya nem kapja meg a központi valutanem-listát

**Érintett fájl:** `frontend-react/src/pages/inventory/CashierStocksPage.tsx`

**Tény:** A `territories` számításban a frontend üres kártyát ad hozzá, ha egy területnek van ismert értéktára, de a `branchGroups` között nincs ilyen branch:

```tsx
if (!terr.groups.some(g => g.branchName === terr.vaultName)) {
  terr.groups.push({ branchName: terr.vaultName, items: [], hufTotal: 0, nonZeroCount: 0 })
}
```

**Miért hiba:** A `BranchCard` a `group.items.length` értéket írja ki. Ha `items` üres, a kártya `0 valuta` lesz. Ez megkerüli az `allItems` master-valuta mátrixát, mert az csak a `/inventory/stock` branch-neveiből épülő `branchNames` halmazon iterál.

**Felhasználói tünet:** Pontosan ilyen látszik a mellékelt Békéscsaba képernyőképen: `Békéscsaba Értéktár – 0 valuta`.

**Javítási irány:** Az üresen injektált értéktár kártyát is a központi `currencies` listából kell feltölteni 0 egyenlegű sorokkal.

Minimális mintakód az AI fejlesztő ügynöknek:

```tsx
function buildZeroCurrencyItems(branchName: string, currencies: Currency[]): InventoryItem[] {
  return currencies.map((currency) => ({
    id: `${branchName}|${currency.code}`,
    branchName,
    currencyCode: currency.code,
    currentBalance: 0,
  }))
}
```

Majd az üres értéktár injektálásánál:

```tsx
if (!terr.groups.some(g => g.branchName === terr.vaultName)) {
  const zeroItems = buildZeroCurrencyItems(terr.vaultName, currencies)
  terr.groups.push({
    branchName: terr.vaultName,
    items: zeroItems,
    hufTotal: 0,
    nonZeroCount: 0,
  })
}
```

Fontos: a helper csak akkor építsen master-listát, ha `currencies.length > 0`. Ha a `/currencies` hívás sikertelen és `currencies` üres, maradhat az üres fallback, mert a kód jelenlegi kommentje szerint a valuta-törzs best-effort.

### P2 - A jelenlegi frontend teszt nem fedi a tényleges `0 valuta` esetet

**Érintett fájl:** `frontend-react/src/pages/inventory/CashierStocksPage.test.tsx`

**Tény:** A meglévő FK-007/008 tesztben az értéktárnak van legalább egy stock sora:

```ts
{ id: 's4', branchName: 'Szekszard Ertektar', currencyCode: 'HUF', currentBalance: 0 }
```

Ezért a teszt azt bizonyítja, hogy ha az értéktár benne van a `/inventory/stock` válaszban, akkor a master-valuta mátrix kitölti a hiányzó valutákat. Nem bizonyítja azt az esetet, amikor az értéktárnak egyetlen stock sora sincs, és csak a `branchMeta`/`vaultByRegion` alapján kerül be üres kártyaként.

**Javítási irány:** Legyen külön teszt arra, hogy a vault branch nincs benne a `STOCK` listában, de benne van a `BRANCHES` listában `isVault: true` értékkel. Az elvárt eredmény: az értéktár kártyán megjelenik az összes aktív valuta 0-val.

Mintateszt:

```tsx
it('FK-007: stock-sor nélküli értéktár-kártya is a teljes aktív valutalistát mutatja', async () => {
  mocks.apiGet.mockResolvedValue({
    data: [
      { id: 's1', branchName: 'Baja Tesco', currencyCode: 'EUR', currentBalance: 1910 },
    ],
  })
  mocks.branchListActive.mockResolvedValue([
    { name: 'Baja Tesco', region: 'SZEKSZARD', isVault: false },
    { name: 'Szekszard Ertektar', region: 'SZEKSZARD', isVault: true },
  ])
  mocks.currencyList.mockResolvedValue(MASTER_CURRENCIES)

  render(<CashierStocksPage />)

  await waitFor(() => {
    expect(screen.getByText('Szekszard Ertektar')).toBeInTheDocument()
  })

  const card = screen.getByText('Szekszard Ertektar').closest('[data-testid="branch-card"]') as HTMLElement
  const scope = within(card)

  expect(scope.getByText('HUF')).toBeInTheDocument()
  expect(scope.getByText('AUD')).toBeInTheDocument()
  expect(scope.getByText('EUR')).toBeInTheDocument()
  expect(scope.getByText('3 valuta')).toBeInTheDocument()
})
```

A valós törzsben a szám 22, a teszt fixture-ben a `MASTER_CURRENCIES.length` szerinti darabszámot kell ellenőrizni.

### P2 - BR105 `vault_territory_id` feltételezés nincs kóddal igazolva

**Érintett fájlok:**

- `backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java`
- `backend/src/main/resources/db/migration/V250__branch_sync_br105_and_name_corrections.sql`
- `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java`

**Tények:**

- A `Branch` entitásban létezik `vaultTerritoryId` mező.
- A V250 migráció BR105-re `region` és `region_code` mezőket állít, de `vault_territory_id` mezőt nem.
- A jelenlegi Országos készlet frontend csoportosítás a `branch.region` értéket használja, nem közvetlenül `vault_territory_id`-t.
- Az `InventoryService.getAllStock()` régebbi/alternatív területi szűrése `vaultTerritoryId` alapján is tartalmaz logikát territory-scoped role esetére.
- Az `InventoryController.getAllStock()` további `AccessScopeService` szűrést is alkalmaz, amelyet ebben az auditban nem bontottunk végig.

**Következtetés:** Nem szabad automatikusan kijelenteni, hogy a BR105 hiányának oka `vault_territory_id IS NULL`. A kódban meglévő V250 szerint a BR105 megjelenéséhez legalább `region` és `region_code` is releváns. Adatbázis-lekérdezés nélkül a BR105 aktuális production értékei nem igazoltak.

**AI ügynöknek végrehajtási utasítás:** Ha BR105 továbbra is hiányzik, először adatdiagnosztika kell, nem vak migráció.

Javasolt ellenőrző SQL:

```sql
SELECT
  code,
  name,
  is_active,
  is_vault,
  region,
  region_code,
  vault_territory_id
FROM branch
WHERE code IN ('BR075', 'BR076', 'BR105')
ORDER BY code;
```

Javasolt készletoldali ellenőrzés:

```sql
SELECT
  b.code,
  b.name,
  b.region,
  b.region_code,
  b.vault_territory_id,
  COUNT(cb.id) AS cash_balance_rows
FROM branch b
LEFT JOIN cash_balance cb ON cb.branch_id = b.id
WHERE b.code IN ('BR075', 'BR076', 'BR105')
GROUP BY b.code, b.name, b.region, b.region_code, b.vault_territory_id
ORDER BY b.code;
```

Csak akkor készüljön új Flyway migráció `vault_territory_id` pótlásra, ha a tényleges adatdiagnosztika bizonyítja, hogy az adott hozzáférési út ezt használja és emiatt esik ki a fiók.

## Ajánlott javítási sorrend AI fejlesztő ügynöknek

1. Írj frontend regressziós tesztet a `stock-sor nélküli értéktár` esetre a `CashierStocksPage.test.tsx` fájlban.
2. Futtasd a tesztet, és ellenőrizd, hogy a jelenlegi kódon elbukik-e a `0 valuta` viselkedés miatt.
3. Javítsd a `CashierStocksPage.tsx` üres vault injektálását úgy, hogy a központi `currencies` listából építsen 0 egyenlegű `items` sorokat.
4. Ellenőrizd, hogy a meglévő TST/DKK nem-nulla árva egyenleg tesztek továbbra is átmennek. Ne rejts el nem-nulla inaktív valuta egyenleget.
5. Ha BR105 továbbra is hiányzik, csak adatdiagnosztika után nyúlj migrációhoz. Ne feltételezd automatikusan a `vault_territory_id` hibát.
6. Backend módosítás csak akkor szükséges, ha a futó adatdiagnosztika bizonyítja, hogy a `/inventory/stock` vagy `AccessScopeService` szűrése hibásan zár ki branch-et.

## Definition of Done

- Az értéktár kártya akkor is `22 valuta` sort mutat, ha az adott értéktárnak nincs egyetlen `/inventory/stock` sora sem.
- A pénztárkártyák jelenlegi viselkedése nem romlik: aktív valuta törzs alapján sorok, nullás sorokkal együtt.
- A `TST` nem jelenik meg 0 egyenlegű aktív sorok között.
- Nem-nulla árva inaktív valuta egyenleg továbbra sem tűnik el némán.
- BR105 ügyben nincs vak migráció: minden adatjavítás előtt SQL-lel igazolt aktuális állapot szerepel a fejlesztői jegyben vagy PR leírásban.

## Javasolt célzott ellenőrzések

Frontend:

```powershell
cd frontend-react
npm test -- CashierStocksPage.test.tsx
```

Opcionális frontend typecheck:

```powershell
cd frontend-react
npm run typecheck
```

Backend csak akkor szükséges, ha backend kód vagy migráció is változik:

```powershell
cd backend
.\mvnw.cmd test
```

## Nem igazolt vagy kerülendő állítások

- Nem igazolt, hogy a jelenlegi production adatbázisban BR105 `vault_territory_id` mezője NULL.
- Nem igazolt, hogy BR105 hiánya kizárólag `vault_territory_id` miatt történik.
- Nem igaz, hogy a jelenlegi kód egyáltalán nem használ központi valutanem-törzset az Országos készlet oldalon; a frontend ténylegesen hívja a `GET /currencies` végpontot.
- Nem igazolt, hogy új adattábla szükséges.
- Nem szabad dokumentáció alapján átírni kódot vagy migrációt, ha a kód és az adatdiagnosztika mást mutat.

## Audit eredmény

Az FK-007 kérés fő felhasználói tünete kódból igazolható javítási ponttal rendelkezik: az üresen injektált értéktár kártyának is a központi aktív valutanem-törzsből kell megkapnia a sorait. A meglévő implementáció már jó irányba indult, de nem fedi azt az esetet, amikor az értéktárnak nincs készletsora. A BR105 témában a kód alapján óvatos, adatdiagnosztika-első megközelítés szükséges; a dokumentumban szereplő `vault_territory_id` ok nem tekinthető bizonyítottnak.
