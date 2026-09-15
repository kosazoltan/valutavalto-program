# FK-114: "Banki forgalmi adatok" fül — Beérkezett adatok (kozponti-client / backend)

## 1. Cél
A "Beérkezett adatok" oldalon ma két fül van (Átadólap-egyeztetés, Készletek/címletek). Ez a kérés egy harmadik fület ad hozzá, ami a legacy "Időszaki banki forgalom" képernyő mintájára, dátum-tartományra és cég/terület/fiók szintre bontva mutatja a bankból felvett (Felvett-KP) és bankba befizetett (Befizetett-KP) összegeket, valutánként.

**Fontos előfeltétel:** ez a fül kizárólag az FK-113 (különösen annak FR-4-e, az esti zárásba való bekötés) leszállítása és verifikálása UTÁN mutat valós adatot — enélkül minden érték nulla marad.

## 2. Scope

### IN
- Új, önálló, csak-olvasó backend végpont, dátum-tartományra és cég/terület/fiók hatókörre bontva (FR-1).
- Nem zárt napok jelzése az időszakon belül (FR-2).
- Terület-hatókör a `vault_territory_id` mezőre építve (FR-3).
- Harmadik fül a `ReceivedDataOverviewPage.tsx`-en (FR-4).

### OUT
- **TILOS** a mai, még nyitott nap adatainak megjelenítése — kizárólag már lezárt napok tartozhatnak a lekérdezhető időszakba.
- **TILOS** a meglévő két fül (Átadólap-egyeztetés, Készletek/címletek) tartalmának vagy viselkedésének bármilyen módosítása.
- **TILOS** a `Branch.region_code` mező felhasználása ehhez a fülhöz — kizárólag a `vault_territory_id` a terület-forrás.
- **TILOS** bármilyen regionális vagy más hozzáférés-korlátozás bevezetése — minden, FOERTEKTAR/BELSO_ELLENOR/ADMIN jogosultsággal rendelkező felhasználó a teljes cég adatát látja, a "Készletek, címletek" fül mintájára.
- **TILOS** a visszamenőleges (retroaktív) zárás (FKH-050) hiányosságának javítása — ismert, ettől független probléma, külön kérés tárgya, ha szükséges.
- **TILOS** új route/menüpont létrehozása — ez egy fül a meglévő `/central/received-data` oldalon belül.
- **TILOS** automatikus lekérdezés betöltéskor — csak explicit gombnyomásra fut, a meglévő két fül mintáját követve.

## 3. RBAC
Megegyezik a meglévő fülekkel: Főértéktáros, Belső ellenőr, Admin.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Csomag | Acceptance |
|---|---|---|---|---|
| FR-1 | Backend végpont — bulk, dátum-tartományos banki forgalom | FELTERKEPEZES_282 1/2. pont | backend | Adott: nincs meglévő végpont, ami dátum-tartományra, cég/terület/fiók szinten összesítve adná vissza a banki forgalmat. Amikor: új `GET /api/v1/central/received-data/bank-turnover?fromDate&toDate&branchId?&vaultTerritoryId?` végpont készül, a meglévő, eddig sehol nem hívott `DailyBalanceRepository.findByBranchIdsAndDateRange` bulk+tartományos lekérdezésre építve, kiegészítve egy DB-oldali, valutánkénti SUM projekcióval (teljes entitás-betöltés helyett), kizárólag az `is_vault=true` fiókok sorait összegezve; `toDate < ma` kötelező validáció; a tartomány hossza max. 92 nap. Akkor: a válasz valutánkénti bontásban adja vissza a Felvett-KP (`bank_in`) és Befizetett-KP (`bank_out`) összegeket, a kért hatókörre összesítve; `@Transactional(readOnly = true)`; `@PreAuthorize("hasAnyRole('FOERTEKTAR','BELSO_ELLENOR','ADMIN')")`. |
| FR-2 | Nem zárt napok jelzése | FELTERKEPEZES_282 2.c pont | backend | Adott: egy adott fiók egy adott napja lehet, hogy nem volt zárva; értéktárra ennek jelzője a `closing_control.evening_closing_done` (nem a `daily_closing_done`, ami vaultra sosem íródik). Amikor: a végpont egy új, tartományos `closing_control` lekérdezéssel megállapítja, mely (fiók, nap) kombinációk nem zártak a kért hatókörön és időszakon belül. Akkor: a válasz tartalmaz egy `missingClosingDays` listát (fiók + dátum párokkal); üres lista = a teljes időszak lefedett. |
| FR-3 | Terület-hatókör — `vault_territory_id` | FELTERKEPEZES_282 3. pont | backend | Adott: a "Vizsgált egység" választónak fiók- és terület-szintű szűrést is kell támogatnia. Amikor: a terület-hatókör a `Branch.vault_territory_id` mezőre épül, a `DailyBalanceGridService.resolveBranchScope` mintáját követve. Akkor: a választó három módot támogat — teljes cég összesítve / egy terület összesítve / egy fiók — konzisztensen a Napi ellenőrző lista terület-szűrőjével. |
| FR-4 | Harmadik fül a felületen | FELTERKEPEZES_282 4.d pont | kozponti-client (frontend-react) | Adott: a "Beérkezett adatok" oldalon ma két fül van. Amikor: egy harmadik fül ("Banki forgalmi adatok") kerül a `ReceivedDataOverviewPage.tsx`-re, saját `ReceivedBankTurnoverView.tsx` komponensben, a `ReceivedDenominationsView.tsx` mintáját követve (nem a közös API-barrelből importál, kézi "Lekérdezés" gombbal, nincs auto-betöltés). Akkor: a fül egy dátum-tól/-ig választót, egy "Vizsgált egység" választót (cég/terület/fiók), egy Valutanem/Felvett-KP/Befizetett-KP táblázatot, és — ha van hiányzó nap — egy figyelmeztető sávot mutat; a meglévő két fül tartalma és tesztjei változatlanok maradnak; a táblázat a meglévő alternáló sorszínezést használja (`.data-grid` osztály, FK-050 minta). |

## 5. Adatmodell-érintettség
Nincs új tábla/migráció.

## 6. Kockázatok / TBD
| # | Kérdés / kockázat |
|---|---|
| 1 | Ez a fül csak akkor mutat valós adatot, ha az FK-113 (különösen annak FR-4-e) már leszállításra és verifikálásra került — enélkül minden érték nulla marad. Javasolt: ezt a fület csak FK-113 sikeres verifikációja után kiadni/bekapcsolni. |
| 2 | A retroaktív zárás (FKH-050) ma sem tölti a banki mezőket — egy utólag zárt napon a banki adat hiányozhat, de a `closing_control` szerint a nap mégis zártnak tűnhet, tehát a "hiányzó nap" jelzés (FR-2) ezt nem fogja észlelni (csendes alulszámolás lehetséges). Ismert, dokumentált korlát, nem ennek az FK-nak a tárgya. |

## 7. Végrehajtási utasítás
1. `cd D:\repo\valutavalto-program`, `git checkout -b feature/banki-forgalmi-adatok-ful`
2. `git log --all --grep="FK-114"` + `git branch -a | grep -i fk114` — kollízió-ellenőrzés már megtörtént (2026-09-14, tiszta eredmény), de commit előtt ismételd meg.
3. Fázis 1: backend (FR-1 végpont + bulk projekció, FR-2 hiányzó-nap lekérdezés, FR-3 terület-hatókör). Fázis 2: frontend (FR-4, harmadik fül).
4. DoD: lint, `mvn verify`, `npm run test`, code review, merge/push/deploy.

---
FR-ek száma: 4 db | Csomagok: backend, kozponti-client
