# Ertektari atadas-atvetel - szallito es plombaszam kodrevizio, javitasi utasitas

Forras-kerelem: `C:\Users\Kosa Zoltan\Downloads\fejlesztesi-keres-atadas-szallito-plomba (1) (1).md`

Cel: a kerelmezett `Szallito neve` es `Plombaszam` mezok tenyleges allapotanak ellenorzese kizarolag repo-kod alapjan, majd javitasi utasitas keszitese AI fejleszto ugynoknek. Uzleti kod ebben az auditban nem modosult.

## Osszefoglalo

A megoldas reszlegesen van implementalva. A `transfer` backend adatmodellben, DTO-ban, service mappingban, frontend `/transfers` oldalon, Electron bridge-ben, SQLite `pending_transfers` tablaban es sync payloadban mar letezik a `carrierName` / `sealNumber` vezetek. Ugyanakkor a kerelmezett mukodes nem tekintheto kesznek, mert:

1. a backend nem kenyszeriti ki, hogy a ket mezo kotelezo legyen;
2. a backend nem kenyszeriti ki a kert 128/64 hosszt es a plombaszam mintat;
3. a migracio/entity jelenleg 200/100 hosszt hasznal, nem a kerelmezett 128/64 szerzodest;
4. az ertektari `ShipmentNewPage` szallitmanyigeny/atadas-atvetel urlapon nincs szallito/plombaszam mezo;
5. nincs sikeres mentes utani `Nyomtatas` gomb a vizsgalt transfer flow-ban;
6. a nyomtatasi adattipus es sablon nem tartalmazza a `Szallito` mezot, a sima `transfer` sablon pedig a `Plombaszam` mezot sem irja ki;
7. nincs celzott backend/frontend/Electron teszt erre a kovetelmenyre.

## Kodtenyek

| Terulet | Kodteny | Erintett fajl |
|---|---|---|
| DB migracio | `transfer` tablaba bekerul `carrier_name VARCHAR(200)` es `seal_number VARCHAR(100)` | `backend/src/main/resources/db/migration/V208__transfer_carrier_seal_fields.sql` |
| Backend entity | `Transfer` entityben `carrierName` length 200, `sealNumber` length 100 | `backend/src/main/java/hu/puzzleir/valuta/entity/Transfer.java` |
| Backend request DTO | `CreateTransferDto` tartalmaz `carrierName` es `sealNumber`, de nincs rajtuk `@NotBlank`, `@Size`, `@Pattern` | `backend/src/main/java/hu/puzzleir/valuta/dto/transfer/CreateTransferDto.java` |
| Backend controller | `POST /api/v1/transfers` `@Valid @RequestBody CreateTransferDto`-t hasznal, tehat DTO annotaciokkal lehet szerzodest ervenyesiteni | `backend/src/main/java/hu/puzzleir/valuta/controller/TransferController.java` |
| Backend service | `TransferService.create` atmasolja `dto.getCarrierName()` es `dto.getSealNumber()` erteket az entitybe | `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java` |
| Backend response | `TransferService.toDto` visszaadja `carrierName` es `sealNumber` ertekeket | `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java` |
| Frontend API | `Transfer` es `CreateTransferRequest` tipusok tartalmazzak `carrierName?` es `sealNumber?` mezoket | `frontend-react/src/services/api/transactions.ts` |
| Frontend transfer oldal | `/transfers` oldalon van state, validacio es input `Szallito neve`, `Plombaszam` mezokre; ezek bekerulnek a backend requestbe es Electron queue-ba | `frontend-react/src/pages/transfers/TransferPage.tsx` |
| Frontend shipment oldal | `/shipments/new` oldalon a `FormState` nem tartalmaz `carrierName` / `sealNumber` mezot, a create payload csak from/to/date/currency/amount/notes/items mezoket kuld | `frontend-react/src/pages/shipments/ShipmentNewPage.tsx` |
| Electron preload/main | `savePendingTransfer` atveszi a ket uj argumentumot es tovabbitja SQLite fele | `penztar-client/electron/preload.ts`, `penztar-client/electron/main.ts` |
| SQLite offline | `pending_transfers` tartalmaz `carrier_name` es `seal_number` oszlopot, a mento fuggveny beszurja oket | `penztar-client/electron/sqlite.ts` |
| Electron sync | `sync-engine` `carrierName` es `sealNumber` payload mezoket kuld a `/transfers` endpointnak, ha az SQLite oszlop nem ures | `penztar-client/electron/sync-engine.ts` |
| Print tipus | `PrintReceiptData` csak `sealNumber?: string` mezot tartalmaz, `carrierName` nincs | `frontend-react/src/types/receipt.ts`, `penztar-client/electron/printer.ts` |
| Print preview | `ReceiptPreviewModal` transfer blokkban csak cel es megjegyzes jelenik meg | `frontend-react/src/components/electron/ReceiptPreviewModal.tsx` |
| Electron printer | `generateTransferLines` es `generateTransferHtml` sima `transfer` tipusnal nem ir `carrierName`-t es nem ir `sealNumber`-t | `penztar-client/electron/printer.ts` |
| Tesztek | Backend transfer tesztek vannak, de a keresett carrier/seal validacio/perzisztencia nem latszik lefedve; frontend tesztben nincs talalat `TransferPage` + `carrierName`/`sealNumber` mintara | `backend/src/test/java/...`, `frontend-react/src/**/*.test.tsx` keresesi eredmeny |
| Diagnosztika | A vizsgalt kulcsfajlok VS Code diagnostics szerint hibatlanok | `get_errors` celzott futas |

## Findingok

### F1 - Backend szerzodes nincs kikényszeritve

Sulyossag: P1

A keres szerint a `Szallito neve` es `Plombaszam` kotelezo, tovabba a `Szallito neve` max. 128 karakter, a `Plombaszam` max. 64 karakter, es csak alfanumerikus + kotőjel + per jel engedett. A jelenlegi `CreateTransferDto` csak a transfer alapmezoket validalja, a ket uj mezo sima `String`.

Kovetkezmeny: REST API-n es offline sync-en keresztul ures, tul hosszu vagy tiltott karakteres plombaszam is mentheto, ha a kliens oldali ellenorzes kikerul vagy hibas.

Javitasi utasitas:

```java
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@NotBlank(message = "A szallito neve kotelezo")
@Size(max = 128, message = "A szallito neve legfeljebb 128 karakter lehet")
private String carrierName;

@NotBlank(message = "A plombaszam kotelezo")
@Size(max = 64, message = "A plombaszam legfeljebb 64 karakter lehet")
@Pattern(regexp = "^[A-Za-z0-9\\-/]+$", message = "A plombaszam csak betut, szamot, kotőjelet es per jelet tartalmazhat")
private String sealNumber;
```

Megjegyzes: ha magyar ekezetes szallito nevek elofordulhatnak, a `carrierName`-re ne tegyel ASCII pattern-t. A plombaszam mintaja a kerelmi dokumentumbol jon, ezt a kodban kell ervenyesiteni.

### F2 - DB/entity hossz szerzodes elter a kert 128/64-tol

Sulyossag: P2

A migracio `carrier_name VARCHAR(200)` es `seal_number VARCHAR(100)`, az entity pedig length 200/100. A keres 128/64-et ir. Ez nem kozvetlen adatvesztes, de szerzodes-eltérés, es backend annotacio nelkul a DB jelenleg nem segit.

Javitasi utasitas:

1. Uj Flyway migracioban szukitsd a tipusokat csak akkor, ha nincs tul hosszu meglevo adat. Vedett migraciot irj.
2. Entity annotaciokat igazitsd 128/64-re.
3. A DTO validacio legyen az elso vedelmi vonal.

Mintamigracio:

```sql
-- Vxxx__transfer_carrier_seal_contract.sql
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM transfer WHERE length(carrier_name) > 128 OR length(seal_number) > 64) THEN
    RAISE EXCEPTION 'transfer carrier/seal mezokben tul hosszu meglevo adat van';
  END IF;
END $$;

ALTER TABLE transfer ALTER COLUMN carrier_name TYPE VARCHAR(128);
ALTER TABLE transfer ALTER COLUMN seal_number TYPE VARCHAR(64);
```

Entity minta:

```java
@Column(name = "carrier_name", length = 128, nullable = false)
private String carrierName;

@Column(name = "seal_number", length = 64, nullable = false)
private String sealNumber;
```

Ha a mezok csak uj rekordokra kotelezok, a `NOT NULL` DB constraint bevezetese elott regi sorokat migrálni kell vagy reszleges/domain checket kell alkalmazni.

### F3 - Ertektari `ShipmentNewPage` flow-ban nincs ket mezo

Sulyossag: P1

A kerelmi dokumentum modulcime `Ertektari felulet - Szallito es plombaszam rogzitese az atadas-atvetelnel`. A kodban ket kulon flow van:

- `/transfers` (`TransferPage`) tartalmazza a ket mezot;
- `/shipments/new` (`ShipmentNewPage`) nem tartalmazza oket.

A `ShipmentNewPage` `FormState` csak `fromBranchId`, `toBranchId`, `deliveryDate`, `currencyId`, `amount`, `notes` mezoket tartalmaz, a `shipmentRequestApi.create` payloadban sincs `carrierName` vagy `sealNumber`.

Kovetkezmeny: ha a felhasznalo az ertektari menu `Atadas-atvetel` / szallitmanyigeny flow-jat hasznalja, a kert adatokat nem tudja megadni.

Javitasi utasitas:

1. Dontsd el domain szinten, hogy a kerelmi dokumentum melyik endpointot jelenti:
   - `POST /api/v1/transfers`, vagy
   - shipment request endpoint (`shipmentRequestApi.create`).
2. Ha a `ShipmentNewPage` az erintett flow, akkor a shipment backend DTO/entity/migracio is bovitesre szorul, nem eleg a `transfer` tabla.
3. Ne keverd a ket flow-t. A javitas csak akkor helyes, ha az UI menupont altal hivott konkret API is tarolja es visszaadja a mezoket.

Frontend minta `ShipmentNewPage` iranyhoz:

```ts
type FormState = {
  fromBranchId: string
  toBranchId: string
  deliveryDate: string
  currencyId: string
  amount: string
  notes: string
  carrierName: string
  sealNumber: string
}
```

```ts
if (!form.carrierName.trim()) {
  setError('A szallito nevenek megadasa kotelezo.')
  return
}
if (!/^[A-Za-z0-9\-/]+$/.test(form.sealNumber.trim())) {
  setError('A plombaszam csak betut, szamot, kotőjelet es per jelet tartalmazhat.')
  return
}
```

### F4 - Sikeres mentes utan nincs bizonyithato `Nyomtatas` gomb a transfer flow-ban

Sulyossag: P1

A `TransferPage` sikeres mentes utan csak `setSuccess(...)`, modal bezaras, form reset es `loadData()` tortenik. A file-ban nincs `printReceipt`, `ReceiptPreviewModal`, `PrintReceiptData`, `handoverPrinted` vagy `receiptPrinted` hasznalat.

Kovetkezmeny: a kerelmi FR-4 (`Nyomtatas` gomb sikeres rogzitest kovetoen) nincs teljesitve a vizsgalt transfer flow-ban.

Javitasi utasitas:

1. Sikeres `transferApi.create` utan tartsd meg a letrehozott `Transfer` valaszt egy `createdTransferForPrint` state-ben.
2. Jelenits meg `Nyomtatas` gombot vagy receipt preview modalt.
3. A print payloadba vidd at `carrierName` es `sealNumber` mezoket is.
4. Döntsd el, hogy a `handoverPrinted` / `receiptPrinted` backend flag-eket kell-e allitani. Jelenleg latszanak DTO-ban, de nincs bizonyitott controller endpoint a print flag frissitesere.

Minta:

```ts
const [createdTransferForPrint, setCreatedTransferForPrint] = useState<Transfer | null>(null)

const result = await transferApi.create(request)
setCreatedTransferForPrint(result)
setSuccess(`Atadas letrehozva: ${result.transferNumber}`)
```

```tsx
{createdTransferForPrint && (
  <button type="button" onClick={() => printTransfer(createdTransferForPrint)}>
    Nyomtatas
  </button>
)}
```

### F5 - Print adatmodellbol hianyzik a szallito, sima transfer sablonbol hianyzik a plomba is

Sulyossag: P1

A frontend `PrintReceiptData` es az Electron `PrintReceiptData` csak `sealNumber?: string` mezot tartalmaz, `carrierName` nincs. A `ReceiptPreviewModal` transfer blokk csak `transferTarget` es `transferNote` adatokat ir ki. Az Electron `generateTransferLines` es `generateTransferHtml` sima `transfer` tipusnal csak cel, valutanem, osszeg, megjegyzes mezoket ir.

Kovetkezmeny: a kerelmi FR-3 (`Szallito: [nev]`, `Plombaszam: [szam]` a bizonylaton) nincs teljesitve.

Javitasi utasitas:

1. Bovitendő tipusok:
   - `frontend-react/src/types/receipt.ts`
   - `penztar-client/electron/printer.ts`
   - ha hasznalt: `penztar-client/electron/serial-printer.ts`
2. Bovitendő preview:
   - `frontend-react/src/components/electron/ReceiptPreviewModal.tsx`
3. Bovitendő Electron text es HTML sablon:
   - `generateTransferLines`
   - `generateTransferHtml`

Minta:

```ts
export interface PrintReceiptData {
  // ...
  carrierName?: string
  sealNumber?: string
}
```

```ts
lines.push(`Szallito:    ${data.carrierName ?? '—'}`)
if (data.sealNumber) lines.push(`Plombaszam:  ${data.sealNumber}`)
```

```ts
<div class="amount-row"><span>Szallito:</span><span>${escHtml(data.carrierName ?? '—')}</span></div>
${data.sealNumber ? `<div class="amount-row"><span>Plombaszam:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
```

### F6 - Offline SQLite resz kesz, de input-validacio es teszt nincs ra

Sulyossag: P2

Az SQLite `pending_transfers` tabla es mento fuggveny tarolja a mezoket, a sync-engine tovabbitja oket. Ez jo alap. Viszont a lokalis queue oldal nem validal 128/64 hosszt es plombamintat; jelenleg a frontend uressegellenorzesen tul nem latszik kozos validator.

Javitasi utasitas:

1. Hozz letre kozos frontend validatort, pl. `validateTransferCarrierSeal(carrierName, sealNumber)`.
2. Hasznald `TransferPage`-en es ha erintett, `ShipmentNewPage`-en is.
3. Electron queue tesztben ellenorizd, hogy a `savePendingTransfer` beszurja, `getPendingTransfers` visszaadja, es a sync body tartalmazza a ket mezot.

### F7 - Tesztlefedettseg hianyos

Sulyossag: P2

Kereses alapjan:

- backend `TransferServiceTest` es `TransferCounterTransactionTest` letezik, de nem talalhato carrier/seal validacio/perzisztencia assert;
- frontend tesztekben nincs `TransferPage` + `carrierName`/`sealNumber` talalat;
- Electron printer tesztben csak altalanos transfer detail teszt latszik, nem carrier/seal tartalom.

Javitasi utasitas: legalabb ezek a tesztek kellenek:

Backend:

```java
@Test
void create_rejectsMissingCarrierName() { /* POST/validator vagy service-controller teszt */ }

@Test
void create_rejectsInvalidSealNumber() { /* pl. ABC 123 vagy ABC_123 */ }

@Test
void create_persistsAndReturnsCarrierAndSeal() { /* DTO -> entity -> response */ }
```

Frontend:

```ts
it('requires carrier name and seal number before creating transfer', async () => {})
it('sends carrierName and sealNumber in transfer create payload', async () => {})
it('shows print action after successful save', async () => {})
```

Electron/print:

```ts
it('prints carrier name and seal number on transfer receipt', () => {})
it('stores and syncs pending transfer carrier/seal fields', () => {})
```

## Javitasi sorrend AI ugynoknek

1. Pontositsd a domain utvonalat: a kovetelmeny a `TransferPage` / `/api/v1/transfers` flow-ra vagy a `ShipmentNewPage` / shipment request flow-ra vonatkozik-e. A kodtenyek szerint jelenleg csak a transfer flow-ban van reszleges mezoimplementacio.
2. Backend DTO validacio: `CreateTransferDto` annotaciok + controller/validator teszt.
3. DB/entity szerzodes: 128/64 hossz igazitas vedett Flyway migracioval, ha ez tenyleg kotelezo domain szerzodes.
4. Frontend validacio: ne csak `trim()` uresseg, hanem hossz es plombaminta.
5. Ha `ShipmentNewPage` erintett: add hozza ugyanazokat a mezoket, payloadot, backend DTO/entity tarolast a shipment request domainhez.
6. Print flow: sikeres mentes utan `Nyomtatas` gomb, `PrintReceiptData.carrierName`, receipt preview, Electron text/HTML/serial printer sablonok.
7. Offline teszt: SQLite ment, get, sync body.
8. Regresszios tesztek futtatasa.

## Minimalis elfogadasi kriteriumok

- `POST /api/v1/transfers` 400-at ad ures `carrierName`, ures `sealNumber`, 129+ karakteres `carrierName`, 65+ karakteres `sealNumber`, illetve invalid plombaszam eseten.
- Ervenyes `carrierName` es `sealNumber` bekerul a `transfer` rekordba es visszajon a `TransferDto` valaszban.
- Offline Electron modban a `pending_transfers` rekord `carrier_name` es `seal_number` oszlopai kitoltodnek, majd sync soran `carrierName` es `sealNumber` mezokkel kerulnek a backend requestbe.
- A felhasznalo sikeres mentes utan lat `Nyomtatas` gombot.
- A nyomtatott/preview bizonylaton szerepel:
  - `Szallito: <nev>`
  - `Plombaszam: <szam>`
- Ha az ertektari `/shipments/new` flow az uzleti cel, ott is latszik es mentodik a ket mezo; ha nem az a cel, ezt dokumentaltan ki kell zarni a javitas scope-jabol.

## Ellenorzesek ebben az auditban

- Celzott kodkereses: carrier/seal/plomba/szallito/transfer/shipment/print/SQLite utvonalak.
- Celzott fajlolvasas: backend DTO/entity/service/controller/migracio, frontend transfer/shipment/API/receipt tipusok, Electron SQLite/sync/printer.
- VS Code diagnostics: nincs hiba a vizsgalt kulcsfajlokban.
- Uzleti kod modositas nem tortent.
# Ertektari atadas-atvetel: szallito neve es plombaszam - teny alapu kodrevizio es javitasi utasitas

Forras kerelmi fajl: `C:\Users\Kosa Zoltan\Downloads\fejlesztesi-keres-atadas-szallito-plomba (1) (1).md`

Vizsgalat ideje: 2026-06-02

Fontos korlat: ez a dokumentum nem a kerelmi fajl allitasait fogadja el tenynek, hanem a repository aktualis kodjat ellenorizte. Uzleti kod nem lett modositva.

## Rovid eredmeny

A keres reszlegesen van implementalva.

- A `transfer` backend modellben, DTO-ban es migracioban mar vannak `carrierName` / `sealNumber` mezok.
- A `/api/v1/transfers` letrehozas menti es visszaadja ezeket a mezoket.
- A penztar Electron offline `pending_transfers` tablan, preload/main bridge-en es sync-engine payloadon a ket mezo atmegy.
- A `/transfers` React oldalon az uj atadas modalban lathato es kliensoldalon kotelezo a `Szallito neve` es `Plombaszam`.

De a teljes kovetelmeny nincs kesz:

- A backend nem validalja kotelezokent a ket mezot.
- A backend hosszhatarai elternek a kert 128/64-tol: DB/entity 200/100, DTO-n nincs `@Size`.
- A backend nem ellenorzi a plombaszam mintat `[A-Za-z0-9\-/]+`.
- A kerelmi dokumentum szerinti ertektari `ShipmentNewPage` utvonalon nincs szallito/plomba mezo.
- Sikeres mentes utan nincs bizonyitott `Nyomtatas` gomb a transfer letrehozas flow-ban.
- A nyomtatasi adatmodellben nincs `carrierName`, es a sima transfer nyomtatasi sablon nem irja ki a `Plombaszam` mezot sem.
- Nincs celzott teszt a carrier/seal validaciora, UI kotelezosegre, offline payloadra es nyomtatasi tartalomra.

## Kodtenyek

| Terulet | Kodteny | Kovetkezmeny |
| --- | --- | --- |
| DB migracio | `backend/src/main/resources/db/migration/V208__transfer_carrier_seal_fields.sql` hozzaadja: `carrier_name VARCHAR(200)`, `seal_number VARCHAR(100)` | A tabla nem a kert 128/64 limitet koveti. |
| Backend entity | `backend/src/main/java/hu/puzzleir/valuta/entity/Transfer.java` tartalmaz `carrierName` length 200 es `sealNumber` length 100 mezot | Perzisztencia letezik, de limit elter. |
| Backend create DTO | `backend/src/main/java/hu/puzzleir/valuta/dto/transfer/CreateTransferDto.java` tartalmazza a ket String mezot, de nincs rajtuk `@NotBlank`, `@Size`, `@Pattern` | Backendrol kuldheto ures/null/ervenytelen adat. |
| Backend controller | `backend/src/main/java/hu/puzzleir/valuta/controller/TransferController.java` a `POST /api/v1/transfers` endpointon `@Valid @RequestBody CreateTransferDto`-t fogad | A validacio csak akkor vedene, ha a DTO-n megvannak az annotaciok. |
| Backend service | `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java` create mapping: `.carrierName(dto.getCarrierName())`, `.sealNumber(dto.getSealNumber())`; response mapping: `.carrierName(t.getCarrierName())`, `.sealNumber(t.getSealNumber())` | A backend menti es visszaadja a mezoket. |
| Frontend API | `frontend-react/src/services/api/transactions.ts` `Transfer` es `CreateTransferRequest` tipusa tartalmazza `carrierName?: string`, `sealNumber?: string` mezoket | API tipusvezetek reszben megvan. |
| Frontend `/transfers` UI | `frontend-react/src/pages/transfers/TransferPage.tsx` state: `carrierName`, `sealNumber`; kliensvalidacio: trim ures ellenorzes; payloadba bekerul mindket mezo | A penztar/ertekszallito atadas-alairas oldalon lathato es kuldott a ket mezo. |
| Frontend `/shipments/new` UI | `frontend-react/src/pages/shipments/ShipmentNewPage.tsx` form state-ben es submit payloadban nincs carrier/seal | A kerelmi fajl cim szerinti ertektari szallitmanyigeny/atadas oldal nem teljesiti a kovetelmenyt. |
| Electron SQLite | `penztar-client/electron/sqlite.ts` `pending_transfers` tartalmaz `carrier_name`, `seal_number`; `savePendingTransfer` menti oket | Offline tarolas megvan. |
| Electron sync | `penztar-client/electron/sync-engine.ts` pending transfer sync payloadba teszi: `body['carrierName'] = tx.carrier_name`, `body['sealNumber'] = tx.seal_number` | Offline -> backend sync reszben megvan. |
| Nyomtatasi tipus | `frontend-react/src/types/receipt.ts` es `penztar-client/electron/printer.ts` `PrintReceiptData` csak `sealNumber?: string` mezot tartalmaz, `carrierName` nincs | A szallito neve nem tud szabalyosan bekerulni a nyomtatasi payloadba. |
| Transfer print sablon | `penztar-client/electron/printer.ts` `generateTransferLines` es `generateTransferHtml` csak cel, valutanem, osszeg, megjegyzes mezoket ir ki | Sima transfer bizonylaton nincs szallito es nincs plombaszam. |
| Preview modal | `frontend-react/src/components/electron/ReceiptPreviewModal.tsx` transfer resz csak cel es megjegyzes | Elonezeten sincs szallito/plomba. |
| Diagnosztika | VS Code diagnostics: nincs hiba a vizsgalt kulcsfajlokban | Nem LSP/typecheck hiba, hanem funkcionális hiany. |

## Findingok

### P1 - Backend validacio nincs kikényszerítve

A kerelmi fajl szerint a `Szallito neve` es `Plombaszam` kotelezo, a szallito max 128 karakter, a plombaszam max 64 karakter es csak alfanumerikus/kotojel/perjel lehet.

Aktualis kodteny:

```java
private String carrierName;
private String sealNumber;
```

Ez a `CreateTransferDto`-ban annotacio nelkuli mezopar. A controller `@Valid`-je emiatt nem tudja megfogni a hibat.

Javitas:

```java
@NotBlank(message = "A szallito neve kotelezo")
@Size(max = 128, message = "A szallito neve legfeljebb 128 karakter lehet")
private String carrierName;

@NotBlank(message = "A plombaszam kotelezo")
@Size(max = 64, message = "A plombaszam legfeljebb 64 karakter lehet")
@Pattern(regexp = "^[A-Za-z0-9\\-/]+$", message = "A plombaszam csak betut, szamot, kotojelet es perjelet tartalmazhat")
private String sealNumber;
```

Megjegyzes: ha regi adatok miatt visszamenoleg nem lehet `NOT NULL` constraintet azonnal bevezetni, akkor is a create endpointon kotelezo legyen a validacio. DB-szinten kulon migracioban legalabb hosszhatar-korrigalas kell.

### P1 - DB/entity hosszhatar elter a kert szerzodestol

Aktualis kodteny:

```sql
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS carrier_name VARCHAR(200);
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS seal_number VARCHAR(100);
```

Entity:

```java
@Column(name = "carrier_name", length = 200)
private String carrierName;

@Column(name = "seal_number", length = 100)
private String sealNumber;
```

Javitas:

- Uj Flyway migracio, nem a regi V208 atirasa.
- Entity length igazodjon a DB-hez.
- DTO `@Size` is ugyanazt a szerzodest hasznalja.

Mintamigracio:

```sql
ALTER TABLE transfer
  ALTER COLUMN carrier_name TYPE VARCHAR(128),
  ALTER COLUMN seal_number TYPE VARCHAR(64);

ALTER TABLE transfer
  ADD CONSTRAINT chk_transfer_seal_number_format
  CHECK (seal_number IS NULL OR seal_number ~ '^[A-Za-z0-9\-/]+$');
```

Ha a mezok mostantol kotelezoek minden uj rekordra, de regi rekordok lehetnek nullak, ne tegyel azonnal globalis `NOT NULL` constraintet adatfeltoltes nelkul. A create endpoint validacioja legyen az elso vedelmi vonal.

### P1 - A kerelmi fajl szerinti ertektari `ShipmentNewPage` nem kapta meg a mezoket

A kerelmi dokumentum cime: `Ertektari felulet - Szallito es plombaszam rogzitese az atadas-atvetelnel`.

Aktualis kodteny:

- `frontend-react/src/pages/shipments/ShipmentNewPage.tsx` `FormState` nem tartalmaz `carrierName` / `sealNumber` mezot.
- A `shipmentRequestApi.create(...)` payload sem kuldi ezeket.
- A formon nincs `Szallito neve` / `Plombaszam` input.

Kozben `frontend-react/src/pages/transfers/TransferPage.tsx` mar tartalmazza a mezoket. Tehat a javito agentnek eloszor dontenie kell domain alapon, melyik flow a valodi atadas-atvetel a user kerese szerint:

- Ha a kovetelmeny a `/transfers` flow-ra vonatkozik: ott a mezo lathato, de backend/print/test hianyokat kell javitani.
- Ha a kovetelmeny a `/shipments/new` ertektari szallitmanyigeny flow-ra vonatkozik: ott teljes frontend/API/backend DTO/domain bovites kell, mert az jelenleg `shipmentRequestApi.create` utvonalon megy, nem `transferApi.create` utvonalon.

Javitas a `/shipments/new` flow eseten:

```ts
type FormState = {
  fromBranchId: string
  toBranchId: string
  deliveryDate: string
  currencyId: string
  amount: string
  notes: string
  carrierName: string
  sealNumber: string
}
```

Submit elott:

```ts
if (!form.carrierName.trim()) {
  setError('A szallito nevenek megadasa kotelezo.')
  return
}
if (!/^[A-Za-z0-9\-/]+$/.test(form.sealNumber.trim())) {
  setError('A plombaszam csak betut, szamot, kotojelet es perjelet tartalmazhat.')
  return
}
```

De csak akkor implementald ezt, ha a backend `shipment_request` modell es API is megfeleloen bovul. Ne keverd ossze a `transfer` es `shipment_request` aggregate-et.

### P1 - Sikeres mentes utan nincs bizonyitott nyomtatas gomb a transfer flow-ban

Aktualis kodteny:

- `frontend-react/src/pages/transfers/TransferPage.tsx` nem tartalmaz `printReceipt`, `ReceiptPreviewModal`, `PrintReceiptData`, `Nyomtat` hivatkozast.
- Sikeres mentes utan csak success uzenet all be: `Atadas letrehozva: ...` vagy offline queue uzenet.

Javitas:

- Sikeres `transferApi.create(request)` utan a kapott `Transfer` DTO-bol epuljon `PrintReceiptData`.
- Electron kornyezetben jelenjen meg `ReceiptPreviewModal`, majd `window.electronAPI.printReceipt(JSON.stringify(receiptData))`.
- Browser fallback csak fejlesztoi/preview celra mehet, de production penztar kliensben Electron print legyen az autoritativ.
- Offline letrehozaskor is hasznalhato legyen a lokalis `local_reference_number` mint bizonylatszam, ne varjon szerver-szinkronra a nyomtatas.

Mintairany:

```ts
const transferReceipt: PrintReceiptData = {
  type: 'transfer',
  companyType,
  receiptNumber: result.transferNumber,
  branchCode: worker?.branchCode ?? '',
  cashierName: workerName,
  date: result.transferDate,
  time: result.transferTime,
  currencyCode: result.currencyCode,
  foreignAmount: result.amount,
  transferTarget: `${result.toBranchCode} - ${result.toBranchName}`,
  transferNote: result.notes,
  carrierName: result.carrierName,
  sealNumber: result.sealNumber,
}
```

A `carrierName` mezot elotte hozza kell adni a `PrintReceiptData` tipushoz.

### P1 - A nyomtatott bizonylaton nincs teljes adattartalom

Aktualis kodteny:

- `frontend-react/src/types/receipt.ts` `PrintReceiptData` nem tartalmaz `carrierName` mezot.
- `penztar-client/electron/printer.ts` `PrintReceiptData` nem tartalmaz `carrierName` mezot.
- `generateTransferLines` es `generateTransferHtml` sima transfer sablonban nincs `carrierName`, es nincs `sealNumber` megjelenites.
- `frontend-react/src/components/electron/ReceiptPreviewModal.tsx` transfer reszben nincs `carrierName` es `sealNumber`.

Javitas:

1. Add hozza mindket tipushoz:

```ts
carrierName?: string
sealNumber?: string
```

2. Electron text sablon:

```ts
if (data.carrierName) {
  lines.push(`Szallito:    ${data.carrierName}`)
}
if (data.sealNumber) {
  lines.push(`Plombaszam:  ${data.sealNumber}`)
}
```

3. Electron HTML sablon:

```ts
${data.carrierName ? `<div class="amount-row"><span>Szallito:</span><span>${escHtml(data.carrierName)}</span></div>` : ''}
${data.sealNumber ? `<div class="amount-row"><span>Plombaszam:</span><span>${escHtml(data.sealNumber)}</span></div>` : ''}
```

4. Preview modal:

```tsx
{receiptData.carrierName && (
  <p><span className="font-semibold">Szallito:</span> {receiptData.carrierName}</p>
)}
{receiptData.sealNumber && (
  <p><span className="font-semibold">Plombaszam:</span> {receiptData.sealNumber}</p>
)}
```

Magyar UI-ban az eles szoveg lehet ekezetes (`Szallito`, `Plombaszam` helyett `Szállító`, `Plombaszám`), ha a fajl jelenlegi i18n/literal-string szabalyai engedik vagy megfelelo fordítási kulcsot hasznal.

### P2 - Offline tabla neve elter a kerelmi dokumentumtol, de a kodban ez nem hiba

A dokumentum `pending_transfer` tablat emlit. A kodteny szerint a tabla neve `pending_transfers`.

Ez nem onmagaban hiba, mert:

- `penztar-client/electron/sqlite.ts` ezt hozza letre.
- `getPendingTransfers`, `markTransferSynced` es a sync-engine is ezt hasznalja.

Javito agent ne nevezze at a tablat csak a dokumentum miatt. A helyes teendo: a meglevo `pending_transfers` semat es szinkront tartsa konzisztensen.

### P2 - Tesztlefedettseg hianyos

Kodteny:

- Backend `TransferServiceTest` es `TransferCounterTransactionTest` letezik, de a grep nem talalt carrier/seal validacios esetet.
- `frontend-react/src/**/*.test.tsx` alatt nem talaltam `TransferPage` carrier/seal tesztet.
- `penztar-client/electron/__tests__/printer.test.ts` csak `should show transfer details` esetet tartalmaz, carrier/seal tartalomra nincs talalat.

Kotelezo javitas utan hozzaadando tesztek:

Backend:

- `POST /api/v1/transfers` vagy DTO validation test: `carrierName` hianyzik -> 400.
- `sealNumber` hianyzik -> 400.
- `sealNumber = "ABC/12-3"` -> siker.
- `sealNumber = "ABC 12"` vagy `ABC_12` -> 400.
- `carrierName` 129 karakter -> 400.
- `sealNumber` 65 karakter -> 400.
- Sikeres create utan response tartalmazza a ket mezot.

Frontend:

- `TransferPage` uj atadas modalban lathato `Szallito neve` es `Plombaszam` input.
- Ures mezokkel submit nem hivja az API-t es hibat mutat.
- Ervenyes mezokkel a payload tartalmazza `carrierName` es `sealNumber` mezoket.
- Sikeres mentes utan megjelenik a nyomtatasi lehetoseg.

Electron/offline:

- `savePendingTransfer` menti `carrier_name` es `seal_number` mezoket.
- Sync-engine `/transfers` payload tartalmazza `carrierName` es `sealNumber` mezoket.
- Printer text es HTML output tartalmazza `Szallito` es `Plombaszam` sorokat transfer bizonylatnal.

## Javasolt javitasi sorrend AI agentnek

1. Ne kezdj uj endpointot. Eloszor dontsd el, hogy a keres a meglevo `/api/v1/transfers` aggregate-et vagy a `shipmentRequestApi.create` flow-t erinti. A jelenlegi kodbazisban a carrier/seal mezok a `transfer` aggregate-ben vannak.
2. Backend szerzodes:
   - `CreateTransferDto` validacio.
   - `Transfer` entity length 128/64.
   - Uj Flyway migracio a hosszhatarokhoz es opcionális CHECK constrainthez.
   - Tesztek a validaciora es response mappingra.
3. Frontend szerzodes:
   - Ha `/transfers`: tartsd meg a jelenlegi inputokat, adj maxlength/pattern UI vedelmet, es kösd ra a nyomtatasi flow-ra.
   - Ha `/shipments/new`: bovitsd a `FormState`-et, UI-t, API request tipust es backend shipment modellt. Ezt csak akkor csinald, ha a domain dontes szerint ez a valodi cel flow.
4. Nyomtatasi adatmodell:
   - `PrintReceiptData` mind frontend, mind Electron oldalon kapjon `carrierName` mezot.
   - `generateTransferLines`, `generateTransferHtml`, `ReceiptPreviewModal` jelenitse meg mindket mezot.
5. Offline:
   - Ne nevezd at `pending_transfers` tablat.
   - Tartsd a meglevo `carrier_name` / `seal_number` mezoket.
   - Egeszitsd ki teszttel, hogy a sync payload nem vesziti el oket.
6. Ellenorzes:
   - Celzott backend tesztek.
   - Celzott frontend tesztek.
   - Electron printer/sqlite/sync tesztek.
   - VS Code diagnostics/typecheck a modositott fajlokra.

## Minimalis elfogadasi kriterium

A javitas akkor tekintheto kesznek, ha mind igaz:

- Uj transfer letrehozas backendrol `carrierName` nelkul 400-at ad.
- Uj transfer letrehozas backendrol `sealNumber` nelkul 400-at ad.
- Ervenytelen plombaszam (`ABC 12`, `ABC_12`, tul hosszu string) 400-at ad.
- Ervenyes payload mentodik, es `GET /api/v1/transfers/{id}` visszaadja `carrierName` es `sealNumber` mezoket.
- A felhasznalo altal hasznalt atadas-atvetel oldalon lathato es kotelezo a ket mezo.
- Sikeres mentes utan nyomtathato bizonylat elerheto.
- A nyomtatott/preview bizonylaton szerepel:
  - `Szallito: <nev>`
  - `Plombaszam: <szam>`
- Offline letrehozott transfernel a ket mezo bekerul SQLite-ba, majd sync utan a backend rekordban is megjelenik.
- A celzott tesztek es diagnostics zold eredmenyt adnak.

## Ellenorzott, de nem modositott fajlok

- `backend/src/main/resources/db/migration/V208__transfer_carrier_seal_fields.sql`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transfer/CreateTransferDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transfer/TransferDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Transfer.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/TransferController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`
- `frontend-react/src/services/api/transactions.ts`
- `frontend-react/src/pages/transfers/TransferPage.tsx`
- `frontend-react/src/pages/shipments/ShipmentNewPage.tsx`
- `frontend-react/src/types/receipt.ts`
- `frontend-react/src/components/electron/ReceiptPreviewModal.tsx`
- `frontend-react/src/utils/electronTransactions.ts`
- `penztar-client/electron/sqlite.ts`
- `penztar-client/electron/sync-engine.ts`
- `penztar-client/electron/printer.ts`

## Futtatott ellenorzesek

VS Code diagnostics futott az alabbi fajlokra, hibatalalat nelkul:

- `frontend-react/src/pages/transfers/TransferPage.tsx`
- `frontend-react/src/pages/shipments/ShipmentNewPage.tsx`
- `frontend-react/src/components/electron/ReceiptPreviewModal.tsx`
- `frontend-react/src/types/receipt.ts`
- `penztar-client/electron/sqlite.ts`
- `penztar-client/electron/sync-engine.ts`
- `penztar-client/electron/printer.ts`
- `backend/src/main/java/hu/puzzleir/valuta/dto/transfer/CreateTransferDto.java`
- `backend/src/main/java/hu/puzzleir/valuta/entity/Transfer.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`

Nem futott teljes build vagy teljes tesztcsomag, mert a feladat kifejezetten audit MD keszites volt, uzleti kodmodositas nelkul.
