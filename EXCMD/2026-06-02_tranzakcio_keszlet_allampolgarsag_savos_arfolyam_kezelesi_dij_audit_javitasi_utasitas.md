# 2026-06-02 tranzakciós hibák - tényalapú kódaudit és javítási utasítás

## Cél és korlátok

Ez az audit a 2026-06-02-án jelzett pénztári hibákat vizsgálja:

- eladás/vétel készletmozgásának elvárt működése;
- két 06.02-i tétel hiánya a tranzakciólistából;
- állampolgárság mező korlátozott választéka;
- sávos árfolyam nem választható / Electron kliensben nem érvényesül;
- kezelési költség beállíthatósága és módosíthatósága, engedélyezési igényekkel.

Az audit kizárólag a repóban található kódból és migrációkból levont tényeket tartalmaz. Nem történt programkód-módosítás. A két konkrét, hiányzó 06.02-i tétel tényleges adatbázisbeli állapotát csak éles/lokális DB-lekérdezéssel lehet bizonyítani; ezt itt nem lehet kitalálni.

Kapcsolódó kép: `assets/c__Users_K_sa_Zolt_n_AppData_Roaming_Cursor_User_workspaceStorage_33d8e8848fe026066e1fba4dc2dca37a_images_signal-2026-06-02-163015_002-d35ff0e6-cbaa-49bb-9679-fa826ab3b411.png`.

## Rövid vezetői összefoglaló

A jelenlegi online backend `TransactionService` üzleti logikája a kódban nem egyezik a most megfogalmazott új üzleti elvárással. A backend jelenleg vételnél növeli a valuta készletet és csökkenti a HUF készletet, eladásnál csökkenti a valuta készletet és növeli a HUF készletet. A felhasználói kérés ezzel szemben azt írja elő, hogy eladásnál csak az eladott valuta csökkenjen, HUF ne változzon, vételnél pedig sem valuta, sem HUF készlet ne változzon.

A tranzakciólista hiánya nagy valószínűséggel nem egyetlen UI-listázási hiba, hanem a szerveres tranzakciótábla és az Electron `pending_transactions` / sync útvonal közötti állapotkülönbség lehet. A lista csak a még nem szinkronizált (`synced = 0`) helyi pending sorokat fűzi a szerveres listához; a már `synced = 1`, de szerveren hibásan vagy más branch alatt rögzült sorok nem látszanak helyi pendingként.

A kép és a kód alapján az állampolgárság dropdown valóban csak három opciót ad (`Magyar`, `EU-állampolgárság`, `Egyéb`), miközben az adatbázis már képes hosszabb állampolgárság-szöveget tárolni. A sávos árfolyam online API-val működhet, de Electron cache útvonalon a sávmezők elvesznek a renderer oldali mapperben. A kezelési díj konfiguráció backendje és oldala létezik, de a tranzakciós képernyőn nincs üzleti workflow felezésre/elengedésre/speciális díjra, ügyfélkártyára vagy vezetői/főértéktárosi jóváhagyásra.

## Bizonyított tények a kódból

### 1. Készletmozgás vétel/eladás esetén - P0 üzleti szabályütközés

Érintett kód:

- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- `frontend-react/src/pages/transactions/CashierTransactionPage.tsx`

Jelenlegi backend működés:

- `executeBuy`: készletellenőrzést végez HUF-ra, majd `updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount(), true)` és `updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false)` hívásokkal a valutát növeli, a HUF-ot csökkenti.
- `executeSell`: készletellenőrzést végez az eladott valutára, majd `updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount().negate(), false)` és `updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true)` hívásokkal a valutát csökkenti, a HUF-ot növeli.
- A frontend `CashierTransactionPage.tsx` is ezt a jelenlegi logikát tükrözi: sell ágon valuta-készletet ellenőriz, buy ágon HUF-készletet ellenőriz.

Ez nem véletlen mellékhatás, hanem tudatosan kódolt régi üzleti logika. A most kért új szabály:

- eladás: csak a valuta csökken, HUF nem változik;
- vétel: sem valuta, sem HUF nem változik.

Ez üzleti modellváltás, nem egyszerű bugfix. Javításkor a backend az elsődleges forrás: a frontend készletellenőrzését csak a backend módosítás után szabad hozzáigazítani.

AI ügynöknek javasolt végrehajtás:

1. Írjon backend tesztet a kívánt új készletmozgásra `TransactionServiceBusinessLogicTest` környékén.
2. Módosítsa a `TransactionService.executeBuy` és `executeSell` készletmódosító ágait a jóváhagyott új szabály szerint.
3. Módosítsa a `CashierTransactionPage.tsx` pre-check logikáját, hogy vételnél ne ellenőrizzen HUF készletet, eladásnál csak valutát ellenőrizzen.
4. Ellenőrizze, hogy napzárás, riport, NGM/NAV és pénztár pillanatkép nem a régi HUF készletmozgásra épít-e.

Mintateszt irány:

```java
@Test
void executeBuy_doesNotMutateCashBalances_underNewStockPolicy() {
    transactionService.executeBuy(TransactionService.BuyRequest.builder()
        .currencyId(EUR_ID)
        .currencyAmount(new BigDecimal("100"))
        .customerId("CUST-1")
        .build());

    verify(cashBalanceRepository, never()).save(any(CashBalance.class));
}

@Test
void executeSell_decreasesOnlyForeignCurrency_underNewStockPolicy() {
    transactionService.executeSell(TransactionService.SellRequest.builder()
        .currencyId(EUR_ID)
        .currencyAmount(new BigDecimal("100"))
        .customerId("CUST-1")
        .build());

    verify(cashBalanceRepository, atLeastOnce())
        .findByBranchIdAndCurrencyIdForUpdate(eq(BRANCH_ID), eq(EUR_ID));
    // HUF cash_balance mentése ne történjen.
}
```

Megjegyzés: a fenti mintát a konkrét mockolási szerkezethez kell igazítani. A cél a viselkedés rögzítése, nem a pontos másolás.

### 2. Két 06.02-i tranzakció hiánya - P1 sync/lista diagnosztika szükséges

Érintett kód:

- `frontend-react/src/pages/transactions/TransactionListPage.tsx`
- `frontend-react/src/services/api/transactions.ts`
- `penztar-client/electron/sqlite.ts`
- `penztar-client/electron/sync-engine.ts`
- `backend/src/main/java/hu/puzzleir/valuta/controller/TransactionController.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java`

Jelenlegi lista működés:

- A frontend `transactionApi.list()` hívással lekéri a szerveres `GET /api/v1/transactions` oldalt.
- Electronban csak az első oldalon (`page === 0`) hozzáfűzi a helyi, még nem szinkronizált tételeket.
- A helyi pending tételek forrása: `getPendingTransactions()`, amely kizárólag `SELECT * FROM pending_transactions WHERE synced = 0 ORDER BY created_at ASC` eredményt ad.
- A backend lista branch-szűrt: `SecurityUtils.getCurrentBranchId()` alapján hívja a `transactionRepository.findWithFilters(companyId, branchId, ...)` lekérdezést.

Következmény:

- Ha egy tétel még `synced = 0`, akkor Electron lista tetején meg kell jelennie.
- Ha egy tétel `synced = 1`, de a szerveres `transaction` táblában nincs, rossz branch alatt van, vagy sync közben idempotency/cache állapot miatt nem jött létre, akkor a lista nem fogja mutatni.
- Ha a tétel `synced = 1`, a jelenlegi UI nem listázza a helyi sorból; a szervert tekinti igazságnak.

Az audit nem tudja megmondani, hogy a két konkrét 06.02-i tétel melyik állapotban van, mert ehhez adatbázis kell. A javító AI ügynök ne találgasson, hanem kérjen/nézzen diagnosztikát.

Kötelező diagnosztika:

```sql
-- Szerver DB: adott pénztár 2026-06-02-i tranzakciói
SELECT id, receipt_number, transaction_type, status, transaction_date, transaction_time,
       branch_id, worker_id, currency_id, currency_amount, huf_amount, created_at
FROM transaction
WHERE transaction_date = DATE '2026-06-02'
ORDER BY transaction_time DESC, id DESC;
```

```sql
-- Electron SQLite: lokális pending tételek állapota
SELECT id, local_reference_number, type, currency_code, foreign_amount, huf_amount,
       rounded_huf_amount, rate, synced, idempotency_key, created_at
FROM pending_transactions
WHERE date(created_at) = '2026-06-02'
ORDER BY created_at DESC;
```

AI ügynök javítási irány:

1. A listanézetben külön, látható státuszt kell adni a `synced = 1` lokális, de szerveren vissza nem igazolt tételeknek, vagy külön „helyi bizonylatok / sync napló” nézetet kell adni.
2. A sync engine business validation hibáit felhasználói felületen is meg kell jeleníteni, nem csak logban. A `sync-engine.ts` most `abandonedTxIds` setbe teszi a 4xx üzleti hibás sorokat, de ez in-memory állapot; újraindítás után elveszhet.
3. A `pending_transactions` táblában érdemes tartós `sync_error`, `retry_count`, `last_attempt_at` mezőt bevezetni ugyanúgy, ahogy a `pending_stocktake_items` már rendelkezik `sync_error` mezővel.

Mintairány SQLite bővítésre:

```sql
ALTER TABLE pending_transactions ADD COLUMN sync_error TEXT;
ALTER TABLE pending_transactions ADD COLUMN retry_count INTEGER DEFAULT 0;
ALTER TABLE pending_transactions ADD COLUMN last_attempt_at TEXT;
```

### 3. Állampolgárság lista - P1 UI adatmodell hiány

Érintett kód:

- `frontend-react/src/pages/transactions/components/CustomerPanel.tsx`
- `backend/src/main/resources/db/migration/V236__widen_nationality_columns.sql`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Transaction.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transaction/BuyRequestDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transaction/SellRequestDto.java`

Bizonyított tények:

- A customer panelben a `customerNationality` alapértéke `Magyar`.
- A SIMPLE és a SIMPLIFIED/FULL űrlapban is fix három opció van: `Magyar`, `EU-állampolgárság`, `Egyéb`.
- Actor/képviselt fél állampolgárságánál is fix három opció szerepel.
- A backend DTO-k sima `String customerNationality` mezőt fogadnak, nem enumot.
- A DB migráció `V236__widen_nationality_columns.sql` már `VARCHAR(100)`-ra szélesítette a `customer.nationality` és `transaction.customer_nationality` oszlopokat, mert a korábbi háromkarakteres modell nem volt elég.

Következtetés:

A backend és DB már nem kényszerít három opciót; a korlát a frontend UI-ban van. A helyes javítás nem „EU/egyéb” mentése, hanem valódi ország/állampolgárság törzs használata.

AI ügynök javítási irány:

1. Keressen meglévő dictionary/törzs mechanizmust. A frontendben van `dictionaryApi.getByCategory(category)` a `frontend-react/src/services/api/settings.ts` fájlban.
2. Ha van backend dictionary kategória állampolgárságra, azt használja. Ha nincs, hozzon létre új kategóriát migrációval, például `NATIONALITY` vagy `COUNTRY`.
3. A `CustomerPanel.tsx` három fix `<option>` listáját cserélje törzsadat-alapú komponensre, kereshető selectre vagy autocomplete-ra.
4. A kiválasztott érték legyen stabil kód + megjelenített név. Ha a jelenlegi DB csak szöveget tárol, rövid távon a magyar megnevezés menthető, de hosszabb távon külön kódmező ajánlott.

Mintakód irány:

```tsx
const [nationalities, setNationalities] = useState<DictionaryEntry[]>([])

useEffect(() => {
  dictionaryApi.getByCategory('NATIONALITY')
    .then(setNationalities)
    .catch(() => setNationalities([]))
}, [])

<select
  className={fieldClass}
  style={fieldStyle}
  value={customerNationality}
  onChange={(e) => setCustomerNationality(e.target.value)}
>
  {nationalities.map((entry) => (
    <option key={entry.code} value={entry.nameHu || entry.name}>
      {entry.nameHu || entry.name}
    </option>
  ))}
</select>
```

### 4. Sávos árfolyam - P1 Electron cache adatvesztés és UX-hiány

Érintett kód:

- `frontend-react/src/pages/transactions/CashierTransactionPage.tsx`
- `frontend-react/src/utils/rateBands.ts`
- `frontend-react/src/utils/electronTransactions.ts`
- `frontend-react/src/services/api/exchange-rates.ts`
- `penztar-client/electron/sync-engine.ts`
- `penztar-client/electron/sqlite.ts`
- `backend/src/main/java/hu/puzzleir/valuta/entity/ExchangeRate.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionCalculationService.java`

Bizonyított tények:

- A backend `ExchangeRate` entity támogatja a `limit1/2/3` összeghatárokat és vételi/eladási árfolyamokat.
- A frontend `ExchangeRate` típus is tartalmazza a limitmezőket.
- A `CashierTransactionPage.tsx` a `getBandForAmount()` alapján automatikusan választ sávot, és csak információs sávként jeleníti meg a sávokat.
- A kép szerint a felületen `EUR sávok: Alap: 408.00`, `Pénztárosi sáv: 5/5 (400k+ Ft)` látszik. Ez nem interaktív sávválasztó, hanem információ.
- Az Electron `sync-engine.ts` letölti és SQLite-ba írja a `official_rate`, `limit1_amount`, `limit1_buy_rate`, `limit1_sell_rate`, stb. mezőket.
- A `penztar-client/electron/sqlite.ts` `cached_rates` táblája tartalmazza a sávmezőket.
- A renderer oldali `frontend-react/src/utils/electronTransactions.ts` `ElectronCachedRate` típusa és `mapCachedRatesToExchangeRates()` függvénye csak `buy_rate`, `sell_rate`, `unit`, `updated_at` mezőket mappel, a sávmezőket nem.

Következtetés:

Online API útvonalon a sávos árfolyam mezők elvileg rendelkezésre állnak. Electron cache útvonalon viszont a sávos mezők eldobódnak, ezért a pénztári képernyő nem tudja megjeleníteni/alkalmazni a valós sávokat, hiába tárolja őket a helyi SQLite.

AI ügynök javítási irány:

1. Bővítse az `ElectronCachedRate` interfészt a limitmezőkkel.
2. Bővítse a `mapCachedRatesToExchangeRates()` függvényt, hogy minden limitmezőt átadjon.
3. A UI-ban dönteni kell: automatikus sávválasztás marad, vagy kézi sávválasztót kér az üzlet. A felhasználói kérés „sávos árfolyam nem választható” kézi választási igényre utal.
4. Backend oldalon ellenőrizze, hogy a `TransactionCalculationService.resolveBuyRate/resolveSellRate` ne tekintse hibás egyedi árfolyamnak azt, ha a kliens a sávárfolyamot küldi `customExchangeRate` mezőben.

Mintakód a cache-mapper javítására:

```ts
export interface ElectronCachedRate {
  currency_code: string
  buy_rate: number
  sell_rate: number
  unit: number
  updated_at: string
  official_rate?: number | null
  limit1_amount?: number | null
  limit1_buy_rate?: number | null
  limit1_sell_rate?: number | null
  limit2_amount?: number | null
  limit2_buy_rate?: number | null
  limit2_sell_rate?: number | null
  limit3_amount?: number | null
  limit3_buy_rate?: number | null
  limit3_sell_rate?: number | null
}
```

```ts
return {
  id: -(index + 1),
  currencyId: matchedCurrency?.id ?? -(index + 1),
  currencyCode: rate.currency_code,
  currencyName: matchedCurrency?.name ?? rate.currency_code,
  validDate: rate.updated_at?.slice(0, 10) ?? '',
  validTime: rate.updated_at ?? '',
  baseBuyRate: rate.buy_rate,
  baseSellRate: rate.sell_rate,
  officialRate: rate.official_rate ?? undefined,
  limit1Amount: rate.limit1_amount ?? undefined,
  limit1BuyRate: rate.limit1_buy_rate ?? undefined,
  limit1SellRate: rate.limit1_sell_rate ?? undefined,
  limit2Amount: rate.limit2_amount ?? undefined,
  limit2BuyRate: rate.limit2_buy_rate ?? undefined,
  limit2SellRate: rate.limit2_sell_rate ?? undefined,
  limit3Amount: rate.limit3_amount ?? undefined,
  limit3BuyRate: rate.limit3_buy_rate ?? undefined,
  limit3SellRate: rate.limit3_sell_rate ?? undefined,
  active: true,
  createdAt: rate.updated_at,
}
```

### 5. Kezelési költség beállítása - P1 részben létezik, de jogosultság/UX ellenőrzendő

Érintett kód:

- `frontend-react/src/pages/fees/HandlingFeeConfigPage.tsx`
- `frontend-react/src/services/api/settings.ts`
- `backend/src/main/java/hu/puzzleir/valuta/controller/HandlingFeeConfigController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandlingFeeService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandlingFeeCalculator.java`
- `backend/src/main/resources/db/migration/V46__seal_numbers.sql`
- `backend/src/main/resources/db/migration/V75__missing_secondary_tables.sql`
- `backend/src/main/resources/db/migration/V227__handling_fee_bracket_is_active_defensive.sql`

Bizonyított tények:

- Létezik kezelési költség konfigurációs frontend oldal: `HandlingFeeConfigPage.tsx`.
- Létezik API wrapper: `handlingFeeConfigApi.get()` és `handlingFeeConfigApi.update()`, útvonal: `/handling-fee-config`.
- Létezik backend controller: `HandlingFeeConfigController`, amely `HANDLING_FEE_TYPE`, `HANDLING_FEE_PER_MILLE`, `HANDLING_FEE_PER_MILLE_MAX` system paramétereket és `handling_fee_bracket` sávokat kezel.
- A controller `@PreAuthorize("hasAnyRole('MANAGER','ADMIN')")` alatt van. Főértéktáros/ügyvezető normalizált szerepek itt nem szerepelnek.
- A díj számítás autoritatív backend oldalon történik: `HandlingFeeCalculator` nem fogadja el vakon a kliens `handlingFee` értékét, hanem újraszámolja a `HandlingFeeService.calculateHandlingFee()` alapján.

Következtetés:

A „kezelési ktg nem állítható be” panasz lehet jogosultsági vagy menü/UX elérési probléma, nem teljes backend hiány. A kódban a beállítási képesség létezik, de csak `MANAGER` és `ADMIN` role számára engedélyezett a config controller. Ha a főértéktáros/ügyvezető szerepkörnek is kell állítania, a backend role-kaput és a menüt is hozzá kell igazítani.

AI ügynök javítási irány:

1. Ellenőrizze a menüben, hogy `HandlingFeeConfigPage` elérhető-e a cél szerepköröknek.
2. Ha üzleti döntés szerint főértéktáros/ügyvezető állíthatja, bővítse a backend `@PreAuthorize` szerepkörlistát a projekt kanonikus role-konstansaihoz igazítva.
3. Adjon controller tesztet a cél role-okra.
4. Ne engedje pénztárosi szerepkörnek a díjszabás konfigurálását.

Mintairány:

```java
@PreAuthorize("hasAnyRole('MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO')")
```

Ezt csak akkor szabad alkalmazni, ha a projektben a JWT authority ténylegesen ezeket a kanonikus neveket használja az adott app módban.

### 6. Kezelési költség módosítása tranzakció közben - P0 üzleti workflow hiányos

Érintett kód:

- `frontend-react/src/pages/transactions/CashierTransactionPage.tsx`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandlingFeeCalculator.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionCalculationService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DiscountApprovalService.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/DiscountApprovalController.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Transaction.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transaction/BuyRequestDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transaction/SellRequestDto.java`

Bizonyított tények:

- A tranzakciós oldalon `F9` egy egyszerű dialogot nyit: kezelési díj HUF és kedvezmény százalék mezőkkel.
- A dialog nem tartalmaz okot, engedélyezőt, engedélyazonosítót, ügyfélkártya-számot, felezés/elengedés/speciális díj típust.
- A `BuyRequestDto` és `SellRequestDto` nem tartalmaz ilyen mezőket.
- A `Transaction` entityben van `handlingFee`, `discountPercent`, `discountAmount`, `discountTypeCode`, de nincs külön mező kezelési díj módosítás okára, ügyfélkártya számára, approval azonosítóra vagy fee override típusra.
- A backend `HandlingFeeCalculator.calculate()` újraszámolja a szerver szerinti díjat, és kliens eltérés esetén figyelmeztető logot ír, de a szerver oldali érték érvényesül.
- Van `DiscountApprovalService` és `DiscountApprovalController`, de ez kedvezmény százalék jóváhagyási szintet számol, nem a kezelési díj felezés/elengedés/speciális díj workflow-t kezeli.

Következtetés:

A kért üzleti funkció nincs teljesen implementálva. A jelenlegi F9 dialog csak lokális input, a backend pedig autoritatívan felülírhatja a kezelési díjat. Nincs auditálható, szerver-oldali workflow az alábbiakra:

- ügyvezető/főértéktáros jóváhagyás;
- felezés;
- elengedés;
- speciális díj;
- ügyfélkártyás felezés;
- ügyfélkártya-szám bekérése és mentése;
- akció keretében alkalmazott felezés.

AI ügynök javítási irány:

1. Vezessen be explicit kezelési díj módosítási modellt, ne a `discountPercent` mezőt terhelje túl.
2. Backend DTO-ba és entitybe kerüljenek auditálható mezők:
   - `handlingFeeOverrideType`: `NONE`, `HALF`, `WAIVED`, `SPECIAL`
   - `handlingFeeOverrideReason`: `MANAGER_APPROVAL`, `CHIEF_VAULT_APPROVAL`, `CUSTOMER_CARD`, `PROMOTION`, `OTHER`
   - `handlingFeeOverrideAmount`
   - `handlingFeeApprovalId`
   - `customerCardNumber`
3. A szerver `HandlingFeeCalculator` kapjon olyan bemenetet, amely validált override-ot tartalmaz. Tilos kliensoldali puszta szám alapján elfogadni az eltérést.
4. A jóváhagyást szerver oldalon kell validálni a jelenlegi dolgozó szerepköre vagy külön approval token alapján.
5. A frontend F9 dialogot át kell alakítani üzleti választóvá, nem szabad csak számmezőként hagyni.

Mintairány DTO bővítéshez:

```java
public enum HandlingFeeOverrideType {
    NONE,
    HALF,
    WAIVED,
    SPECIAL
}

public enum HandlingFeeOverrideReason {
    MANAGER_APPROVAL,
    CHIEF_VAULT_APPROVAL,
    CUSTOMER_CARD,
    PROMOTION,
    OTHER
}
```

```java
private HandlingFeeOverrideType handlingFeeOverrideType;
private HandlingFeeOverrideReason handlingFeeOverrideReason;
private BigDecimal handlingFeeOverrideAmount;
private String handlingFeeApprovalId;
private String customerCardNumber;
```

Szerveroldali validációs irány:

```java
if (overrideType == HandlingFeeOverrideType.HALF
        && overrideReason == HandlingFeeOverrideReason.CUSTOMER_CARD
        && (customerCardNumber == null || customerCardNumber.isBlank())) {
    throw new ValidationException("Ügyfélkártyás felezéshez kártyaszám kötelező.");
}

if (overrideType == HandlingFeeOverrideType.SPECIAL
        && !SecurityUtils.hasAnyRole("UGYVEZETO", "FOERTEKTAR", "ADMIN")) {
    throw new ValidationException("Speciális kezelési díjhoz ügyvezető/főértéktáros jóváhagyás szükséges.");
}
```

### 7. Kedvezmény és kezelési díj fogalmak keveredése - P1 terméklogikai kockázat

Jelenlegi kódban több, egymástól részben független kedvezmény/díj fogalom él:

- `discountPercent` a tranzakciós árfolyam/HUF összeg kedvezménye;
- `DiscountApprovalService` százalékos kedvezmény jóváhagyási szintje;
- `DiscountThresholdService` automatikus kezelési díj kedvezmény/felár nagy/kis összeg alapján;
- `HandlingFeeTransactionService` külön kezelési díj riport és discount kezelés;
- `HandlingFeeCalculator` autoritatív díjszámítás.

AI ügynöknek tilos ezek közül véletlenszerűen kiválasztani egyet. A kezelési díj felezése/elengedése nem azonos a valutaárfolyam/HUF tranzakció kedvezményével. Külön domainmodellt és auditnyomot igényel.

## Javasolt javítási sorrend

1. **Készletmozgás üzleti döntés véglegesítése és backend tesztelése.** A régi backend logika szándékosan módosít HUF-ot is. A kért új szabály pénzügyi/napzárási hatása nagy.
2. **06.02-i hiányzó tételek diagnosztikája.** Szerver `transaction` és Electron `pending_transactions` összevetése nélkül nem szabad javítást kezdeni.
3. **Sávos árfolyam Electron cache javítása.** Ez jól körülhatárolható, alacsonyabb kockázatú adatvesztési hiba.
4. **Állampolgárság törzsadat alapúvá tétele.** Backend már képes hosszabb értéket fogadni, UI cseréje szükséges.
5. **Kezelési díj konfiguráció jogosultsági/menü ellenőrzés.**
6. **Kezelési díj módosítás workflow újratervezése.** Ez külön feature: backend DTO, entity/migráció, approval service, frontend dialog, audit log és tesztek kellenek.

## Minimális tesztterv

Backend:

- `TransactionServiceBusinessLogicTest`: vétel/eladás új készletmozgási szabályai.
- `TransactionCalculationServiceTest`: sávárfolyam + custom rate validáció, külön buy/sell irányban.
- Új `HandlingFeeOverrideServiceTest`: felezés, elengedés, speciális díj, ügyfélkártya-szám kötelezőség, role-alapú jóváhagyás.
- `HandlingFeeConfigController` controller/security teszt: `MANAGER`, `ADMIN`, opcionálisan `FOERTEKTAR`, `UGYVEZETO`, illetve pénztáros tiltása.

Frontend:

- `CashierTransactionPage` teszt jelenleg nem található a `frontend-react/src` alatt. Kell új teszt a sávos árfolyam megjelenítésére/alkalmazására és F9 díj workflow-ra.
- `CustomerPanel.test.tsx` bővítése: állampolgárság lista törzsből, nem csak három fix opció.
- Electron mapper unit teszt: `mapCachedRatesToExchangeRates()` adja át a `limit1/2/3` és `officialRate` mezőket.

Electron:

- `sync-engine` teszt vagy integrációs ellenőrzés: `cached_rates` limitmezők letöltése, tárolása és rendererbe jutása.
- Pending tranzakció sync hibák tartós tárolása és UI-ban láthatósága.

## Nyitott kérdések, amelyeket a javító AI ügynöknek nem szabad kitalálnia

- A készletmozgás új szabálya csak pénztári UI-ra vonatkozik, vagy minden backend `BUY/SELL` tranzakcióra?
- Ha vételnél sem valuta, sem HUF nem változik, melyik modulban történik a tényleges készletre vétel?
- Eladásnál miért nem nőhet HUF készlet, ha az ügyfél HUF-ot fizet? Ez külön banki/elszámolási készletben jelenik meg?
- A „két 06.02-i tétel” bizonylatszáma, helyi referencia száma vagy pénztárosa ismert-e?
- Az állampolgárságot magyar névként, ISO országkódként vagy állampolgárságkódként kell tárolni?
- Ügyfélkártya létezik-e már külön táblában/rendszerben, vagy most kell létrehozni?
- A főértéktáros/ügyvezető jóváhagyás online tokennel, jelszóval, challenge-response kóddal vagy utólagos approval queue-val történjen?

## Érintett fő fájlok

- `frontend-react/src/pages/transactions/CashierTransactionPage.tsx`
- `frontend-react/src/pages/transactions/TransactionListPage.tsx`
- `frontend-react/src/pages/transactions/components/CustomerPanel.tsx`
- `frontend-react/src/utils/electronTransactions.ts`
- `frontend-react/src/utils/rateBands.ts`
- `frontend-react/src/pages/fees/HandlingFeeConfigPage.tsx`
- `frontend-react/src/services/api/transactions.ts`
- `frontend-react/src/services/api/settings.ts`
- `backend/src/main/java/hu/puzzleir/valuta/controller/TransactionController.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/HandlingFeeConfigController.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/DiscountApprovalController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionCalculationService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandlingFeeService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandlingFeeCalculator.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DiscountApprovalService.java`
- `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Transaction.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/ExchangeRate.java`
- `penztar-client/electron/sqlite.ts`
- `penztar-client/electron/sync-engine.ts`

## Végrehajtási tilalmak a javító AI ügynöknek

- Ne írjon át készletmozgást csak frontendben. A backend az autoritatív pénzügyi logika.
- Ne töröljön vagy gyengítsen AML/Pmt. validációt a tranzakciók átengedéséért.
- Ne használjon kliens által küldött `handlingFee` értéket szerveroldali validált override nélkül.
- Ne vezessen be ügyfélkártyás kedvezményt kártyaszám és auditnyom nélkül.
- Ne tekintse a `Magyar/EU/Egyéb` értékeket teljes állampolgárság-törzsnek.
- Ne állítsa, hogy a két 06.02-i tétel elveszett vagy megvan, amíg a szerver és Electron adatbázis állapota nincs összevetve.
