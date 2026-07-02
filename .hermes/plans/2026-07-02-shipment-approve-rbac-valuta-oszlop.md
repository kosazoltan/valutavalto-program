# Terv: Átadás-átvétel jóváhagyás saját-fiók RBAC + VALUTA oszlop kód-megjelenítés

Dátum: 2026-07-02 · Orchestrator: Claude (Fable 5) · Coder: gpt-5.5 · Reviewer: glm-5.2
Forrás: `hibajelentes-atadas-atvetel-jovahagyas-es-atveteli-visszaigazolas (1).md` (user-jóváhagyott spec)
Branch: `fix/shipment-approve-rbac-es-valuta-oszlop`

## Kontextus (a hibajelentésből, kódon verifikálva)

1. **Approve 403 (2.a):** `ShipmentController.java:96` `@PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO')")` — ERTEKTAR hiányzik.
   `ShipmentService.approve()` (320-328. sor) semmilyen "saját fiók" ellenőrzést nem végez.
   **Üzleti szabály (interjúban megerősítve):** a jóváhagyást KIZÁRÓLAG az átadó (kérő, `fromBranchId`) fiók
   felhasználója végezheti — az Értéktáros a sajátját igen, másét nem; a Főértéktárosnak ehhez a lépéshez nincs köze.
   **Kész minta:** `ShipmentStockBookingService.assertReceiver()` (157-173. sor) — ugyanez, csak `toBranchId`-ra.
2. **VALUTA oszlop (3. megfigyelés):** `ShipmentRequestItemResponseDto` NEM tartalmaz `currencyCode` mezőt (csak `currencyId`),
   a frontend `ShipmentListPage.tsx:643` `{item.currencyCode ?? item.currencyId}` fallbackja ezért nyers ID-t ("3") mutat.
   A `ShipmentStockBookingService`-ben már VAN `resolveCurrencyCode(item.getCurrencyId())` minta.

## Task 1 — assertRequester + ERTEKTAR az approve-on (backend)

Fájlok:
- `backend/src/main/java/hu/puzzleir/valuta/service/ShipmentStockBookingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ShipmentService.java`
- `backend/src/main/java/hu/puzzleir/valuta/controller/ShipmentController.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/ShipmentServiceTest.java` (bővítés)

Lépések (TDD: előbb a tesztek):
1. Tesztek a `ShipmentServiceTest`-be (a meglévő assertReceiver-tesztek mintájára):
   - `approve_deniedWhenCallerNotFromBranch` — SecurityUtils current branch ≠ `fromBranchId` → `AccessDeniedException`,
     státusz NEM változik, ACCESS_DENIED audit hívódik.
   - `approve_allowedWhenCallerIsFromBranch` — current branch == `fromBranchId` → APPROVED.
   - `approve_deniedWhenNoBranchInToken` — `getCurrentBranchIdOrNull()==null` → denied (fail-closed, mint assertReceiver).
2. `ShipmentStockBookingService`: új `assertRequester(ShipmentRequest req)` metódus — az `assertReceiver` PONTOS tükörképe,
   `req.getFromBranchId()`-vel; saját hibakód-konstans (pl. `ERR_NOT_REQUESTER = "VV-AUTH-002"`), ugyanaz az
   ACCESS_DENIED audit-minta (logInNewTransaction, KAT AUTH, from_branch_id + attempt_branch_id a JSON-ban), log.warn, magyar üzenet:
   "a szállítmány jóváhagyását kizárólag a kérő (átadó) fiók végezheti."
3. `ShipmentService.approve()`: a `validateStatusTransition` ELŐTT `stockBookingService.assertRequester(request);`
   (ugyanúgy, ahogy a `deliver()` hívja az `assertReceiver`-t a 342. sorban).
4. `ShipmentController.approve` `@PreAuthorize`: `ERTEKTAR` felvétele a listába:
   `hasAnyRole('SUPERVISOR','MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO','ERTEKTAR')`.
   A tényleges kapu a service-szintű assertRequester (defense-in-depth: role-réteg + branch-réteg) — ez a
   már dokumentált mintája a deliver-nek (ShipmentController.java:106 komment).
5. FONTOS: a MEGLÉVŐ approve-teszteknek, amelyek eddig branch-kontextus nélkül approvéltak, mockolni kell
   a SecurityUtils current-branch-et a from-branch-ra — a hibajelentés user-jóváhagyott spec-változás
   (a régi viselkedés volt a hiba). A meglévő teszt-asserteket NEM szabad gyengíteni: a státusz-átmenet
   (SUBMITTED→APPROVED), audit stb. elvárások változatlanok maradnak; kizárólag a hiányzó
   branch-kontextus setup kerül beléjük. Static-mock minta: a deliver/assertReceiver tesztjei már
   így mockolják a SecurityUtils-t — azt kell követni.

## Task 2 — currencyCode a Shipment item DTO-ban (backend)

Fájlok:
- `backend/src/main/java/hu/puzzleir/valuta/dto/shipment/ShipmentRequestItemResponseDto.java`
- a DTO-t feltöltő mapper (ShipmentService.toResponseDto vagy ahol az item-DTO épül — grep `ShipmentRequestItemResponseDto.builder`)
- `backend/src/test/java/hu/puzzleir/valuta/service/ShipmentServiceTest.java`

Lépések (TDD):
1. Teszt: `toResponseDto_itemsIncludeCurrencyCode` — item currencyId=EUR id → DTO `currencyCode=="EUR"`;
   ismeretlen/null currencyId → `currencyCode==null` (NEM exception).
2. DTO: `private String currencyCode;` mező.
3. Mapper: currencyCode feloldása a currencyId-ból. Ha a mapping a ShipmentService-ben van, használd a már
   létező feloldó mintát (CurrencyRepository / a StockBookingService `resolveCurrencyCode`-jának megfelelője),
   de N+1 NÉLKÜL: a kérés összes itemjének currencyId-it EGY batch lekérdezéssel (findAllById) oldd fel.
4. Frontend változtatás NEM kell — a `currencyCode ?? currencyId` fallback automatikusan a kódot mutatja.

## Nem-célok
- `ShipmentListPage.tsx` / bármely frontend fájl módosítása.
- A "Megérkezett" gomb logikája (canDeliver) — az helyes, élő build/adat-kérdés, nem kód.
- A deliver/assertReceiver útvonal bármilyen módosítása.
- Reject/cancel jogosultságok változtatása.

## Verifikáció
- `cd backend && mvn -q test -Dtest=ShipmentServiceTest` PASS
- `mvn -q compile` PASS
- Nincs `@Disabled/@Ignore/skip(` új kódon; meglévő teszt-assert nem gyengült.

## Kritikus invariánsok
- Multi-tenant: companyId-szűrés érintetlen (findById már szűr).
- Audit: ACCESS_DENIED független tranzakcióban (logInNewTransaction) — a minta kötelező.
- Fail-closed: branch-token nélkül DENY.
