# FK-113 (backend): Banki tételek automatikus lezárása (A2 javítás) + záráskori duplán-levonás javítása

## 1. Cél
Az ERB/FRB/TRB/PRB típusú, VAULT_COUNTERPARTY (banki partner / technikai állomás) célú átadások ma véglegesen PENDING státuszban ragadnak, mert a célfióknak nincs dolgozója, aki visszaigazolhatná. Emellett a banki adat (`bank_in`/`bank_out`) kiszámítása egy olyan zárási útra lett annak idején bekötve, amit az értéktár a gyakorlatban soha nem használ — a két probléma együtt azt eredményezi, hogy a BANK+/BANK− oszlop a Napi ellenőrző listán gyakorlatilag mindig nulla, akkor is, ha valós banki forgalom történt. Ez a kérés mindkét okot megszünteti (a tételek automatikus lezárása mindkét irányban, és a banki adat bekötése az értéktár tényleges zárási útjába), biztosítja a lezárt tételek visszavonhatóságát, és javít egy ezzel összefüggésben feltárt, a záráskori egyenleg-számítást torzító duplán-levonási hibát.

## 2. Scope

### IN
- Automatikus, dolgozói közreműködés nélküli lezárás létrehozáskor, mindkét irányra (bankból felvett és bankba befizetett), VAULT_COUNTERPARTY célú, ERB/FRB/TRB/PRB típusú tételekre (FR-1).
- A lezárt (COMPLETED) banki tételek sztornó-útvonalának kiigazítása, hogy a visszavonás ne hibázzon (FR-2).
- A napi zárás számított egyenlegében fellépő duplán-levonás javítása VAULT_COUNTERPARTY célú F-irányú tételekre (FR-3).
- A banki adat (`bank_in`/`bank_out`) bekötése az értéktár tényleges napi zárási útjába, hogy a fenti javítások eredménye ténylegesen meg is jelenjen a `daily_balance` táblában (FR-4).

### OUT
- **TILOS** a VAULT_COUNTERPARTY partner-fiókoknak valódi `cash_balance` sort adni (elvetett megoldási irány — nagyobb, migrációt igénylő, korábbi dokumentált tervezési döntést [FK-032] visszavonó változtatás lenne).
- **TILOS** a peer-vault célú (`is_vault=true`) átadások viselkedésének bármilyen módosítása — ott az emberi visszaigazolás (receive) változatlanul szükséges és működik.
- **TILOS** a nem-RB típusú (pl. `CURRENCY`, `CORRECTION`) átadások automatikus lezárása bármilyen célra.
- **TILOS** a `createCounterTransactions` UF-ágának módosítása partner-célra (ismert, ettől független hiányosság — ha a jövőben szükséges, külön kérés).
- **TILOS** a COMPLETED-sztornó tranzakció-szintű "REVERSED" jelölésének bevezetése (ismert, ettől független hiányosság a `stornoCompleted` útvonalon — külön kérés tárgya, ha szükséges).
- **TILOS** a Pénzforgalom riport (FR-8) és a BANK+/BANK− riport közötti TRB-besorolási eltérés javítása — külön téma.
- **TILOS** a visszamenőleges (retroaktív) zárás útjának (FKH-050, `RetroactiveClosingService`) módosítása — ott ugyanez a hiányosság fennáll, de külön kérés tárgya, ha szükséges.
- **TILOS** dolgozó VAULT_COUNTERPARTY partner-fiókhoz rendelésének tiltása vagy bármilyen guard bevezetése erre.

## 3. RBAC
Változatlan — az érintett create/receive/storno végpontok jogosultsági köre nem módosul, kizárólag a belső feldolgozási logika változik.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Csomag | Acceptance |
|---|---|---|---|---|
| FR-1 | Automatikus lezárás létrehozáskor, mindkét irányra | FELTERKEPEZES_278 3-5. pont; FELTERKEPEZES_281 1/2/4. pont | backend | Adott: az ERB/FRB/TRB/PRB típusú, VAULT_COUNTERPARTY célú átadások ma PENDING-ben maradnak. Amikor: a `createCounterTransactions` U és F ágába egy null-safe `isCounterpartyTarget(transfer)` feltétel (`toBranch.branchType != null && "VAULT_COUNTERPARTY".equals(code)`) mellett egy, a meglévő UF-ág mintáját követő lezárás kerül: `markLinesReceived`, `status=COMPLETED`, `receivedAmount=amount`, `receivedDate`/`receivedTime=now()`, `difference=ZERO`, `toWorker` marad null; a partner-oldali kassza-módosítás és TRANSFER_IN/OUT tranzakció-létrehozás (amit egy emberi F-receive egyébként megtenne) **nem** fut le — kizárólag a saját (vault) oldali könyvelés marad, ami már a create-ben megtörténik. Akkor: mind a bankból felvett (U), mind a bankba befizetett (F) VAULT_COUNTERPARTY célú tétel azonnal `COMPLETED` státusszal jön létre, dolgozói visszaigazolás nélkül, és bekerül a BANK+/BANK− napi riportba; egy dedikált `TRANSFER_AUTO_COMPLETED` audit-bejegyzés rögzíti a rögzítő dolgozót és az irányt, "igazoló dolgozó: NINCS" jelzéssel; peer-vault célú (`is_vault=true`) tételek viselkedése változatlan. |
| FR-2 | Sztornó-útvonal kiterjesztése lezárt banki tételekre | FELTERKEPEZES_281 2. pont | backend | Adott: a `reverseCounterTransactions` (COMPLETED-sztornó) F/UF ága ma feltétel nélkül megpróbálja visszafordítani a partner-oldali kasszát és tranzakciót is, ami VAULT_COUNTERPARTY célra hibával elszállna. Amikor: ugyanazzal a null-safe diszkriminátorral, mint FR-1, VAULT_COUNTERPARTY célú tételeknél a partner-oldali (toBranch) lépések kimaradnak, kizárólag a saját (fromBranch) oldali visszafordítás fut le — pontosan úgy, ahogy a már ma is működő PENDING-sztornó (`reversePendingCounterTransactions`) teszi. Akkor: egy FR-1 szerint automatikusan lezárt banki tétel a jövőben is hiba nélkül sztornózható. |
| FR-3 | Duplán levonás javítása a napi zárás számításában | FELTERKEPEZES_281 3. pont, Anomália A1 | backend | Adott: a `sumTransfersOutExcludingTh` ma kód-alapú egyezéssel (`toBranch.code <> 'TH'`) kizárólag a "TH" kódú célfiókot zárja ki az "általános átadások" (`transfers_out`) napi összegéből — minden más VAULT_COUNTERPARTY célú F-irányú tétel benne marad, ezért ha egy ilyen tétel egyúttal a BANK+/BANK− riportban (`bank_out`) is szerepel, a záráskori számított egyenlegből **kétszer** vonódik le. Amikor: a kód-alapú "TH" kizárást lecseréljük a strukturális, null-safe `VAULT_COUNTERPARTY` branch-type diszkriminátorra (ugyanaz a minta, mint FR-1/FR-2). Akkor: minden VAULT_COUNTERPARTY célú (nem csak TH) F-irányú tétel kimarad a "transfers_out" összegből, a napi zárás számított egyenlege egyszeres levonással, helyesen alakul; a meglévő TH-viselkedés változatlan marad (TH maga is VAULT_COUNTERPARTY típusú, tehát a régi és új logika rá nézve egyenértékű). |
| FR-4 | Az értéktári zárás tényleges útjába kötés | FELTERKEPEZES_283 4. pont (A opció) | backend | Adott: a banki adat kiszámítása és a `daily_balance.bank_in/bank_out` feltöltése (`DailyBalanceService.recordVaultBankAdjustments`) ma kizárólag a `DailyClosingService.startDailyClosing` útján érhető el — ezt az utat viszont az értéktár a gyakorlatban soha nem használja; az értéktár tényleges napi zárása az `/evening-closing/send` végponton (`EveningClosingController.sendPackage`) keresztül történik, ami ezt a lépést nem hívja, ezért a banki adat kódszinten soha nem íródik be. Amikor: a `sendPackage` sikeres ágába, a meglévő `closingControlService.markClosingDone(..., EVENING)` hívás mellé bekerül egy hívás a `dailyBalanceService.recordVaultBankAdjustments(branchId, date)`-re. Akkor: minden sikeres értéktári esti zárás után a banki adat ténylegesen beíródik a `daily_balance` táblába; a metódus már ma is vault-guardolt, idempotens, önálló tranzakcióban fut (`REQUIRES_NEW`) — nem-vault fiókra változatlanul no-op; ha a HQ-küldés sikertelen, a banki adat nem íródik, összhangban a `sendPackage` jelenlegi hibakezelésével. |

## 5. Adatmodell-érintettség
Nincs új tábla/migráció.

## 6. Kockázatok / TBD
| # | Kérdés / kockázat |
|---|---|
| 1 | Ha a DB-ben mégis létezne olyan, e javítás előtt létrejött COMPLETED F/UF partner-célú tétel, aminek a partner-oldala kivételesen könyvelődött, annak sztornója az FR-2 után hiányosan futhatna le — implementáció közben egy védő log/ellenőrzés javasolt erre az esetre. |
| 2 | A COMPLETED-sztornó ma nem állítja az eredeti tranzakciókat "REVERSED"-re (ezt csak a PENDING-sztornó teszi) — ez egy ettől független, meglévő hiányosság; egy automatikusan lezárt, majd sztornózott banki tétel emiatt "Feltöltve" állapotban maradhat a Tranzakciólistán "Sztornózva" helyett. Nem ennek az FK-nak a tárgya, de dokumentálva van. |
| 3 | Ha a jövőben dolgozót rendelnének egy VAULT_COUNTERPARTY partner-fiókhoz, az FR-1 utáni automatikus lezárás megelőzi az emberi receive-et — ez nem hibás működés, de érdemes tudni róla. |
| 4 | Az értéktárra a "lezárt nap" jelzője a `closing_control.evening_closing_done` (nem a `daily_closing_done`, ami vaultra sosem íródik) — ha egy jövőbeli funkció (pl. a tervezett "Banki forgalmi adatok" fül) a lezárt napokat akarja azonosítani, ezt a jelzőt kell néznie értéktárra. |
| 5 | A visszamenőleges zárás (FKH-050) ma sem hívja a banki adat kiszámítását — egy utólag zárt értéktári napon a `bank_in`/`bank_out` emiatt 0 marad. Ez ennek az FK-nak nem tárgya, de érdemes tudni róla. |

## 7. Végrehajtási utasítás
1. `cd D:\repo\valutavalto-program`, `git checkout -b feature/banki-tetelek-auto-lezaras`
2. `git log --all --grep="FK-113"` + `git branch -a | grep -i fk113` — kollízió-ellenőrzés már megtörtént (2026-09-14, tiszta eredmény), de commit előtt ismételd meg.
3. Fázis 1: FR-1 (automatikus lezárás, `TransferService.createCounterTransactions`). Fázis 2: FR-2 (sztornó-kiigazítás, `reverseCounterTransactions`). Fázis 3: FR-3 (`sumTransfersOutExcludingTh` diszkriminátor-csere, `TransferRepository`). Fázis 4: FR-4 (`recordVaultBankAdjustments` bekötése az `EveningClosingController.sendPackage`-be).
4. DoD: lint, `mvn verify`, `npm run test`, code review, merge/push/deploy.

---
FR-ek száma: 4 db | Csomagok: backend
