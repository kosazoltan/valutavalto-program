# Modul: Értéktári Kliens — VAULT_COUNTERPARTY (TRB stb.) célú/forrású szállítmányok javítása

## 1. Cél
Az értéktár és egy technikai partner (TRB, ERB, PRB stb.) közötti készpénz-szállítmányok (`shipment_request`) ma két irányban hibásak: kimenő (értéktár→partner) irányban a küldő készlete azonnal csökken, de a tétel soha nem tud "megérkezett" állapotba kerülni (nincs dolgozó a partnernél) — örökre SUBMITTED marad. Bejövő (partner→értéktár) irányban a rögzítés azonnal hibával elutasításra kerül, mert a partnernek nincs pénz-egyenlege, amiből a rendszer levonna.

## 2. Scope

### IN
- Kimenő irány: automatikus DELIVERED a submit sikeres lezárásakor, partner-oldali könyvelés kihagyásával (FR-1).
- Bejövő irány: a hibát okozó partner-oldali könyvelés kihagyása, de a tétel SUBMITTED marad — az értéktári dolgozó a meglévő "Megérkezett" gombbal maga zárja le (FR-2).
- A sztornó (visszavonás) lehetőségének megőrzése mindkét irányra (FR-3).

### OUT
- **TILOS** a bejövő irány automatikus (emberi jóváhagyás nélküli) lezárása.
- **TILOS** a partner-fiókoknak valódi `cash_balance` sort adni.
- **TILOS** a `deliveryDate` mező kezelésének átalakítása (ismert, ettől független mellékkörülmény).
- **TILOS** a Transfer-alapú (`FK-113`) mechanizmus módosítása — ez egy külön vertikum (`shipment_request`), saját diszkriminátorral.

## 3. RBAC
Változatlan — a `/shipments/submit`, `/cancel`, `/reject` végpontok jogköre nem módosul.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Csomag | Acceptance |
|---|---|---|---|---|
| FR-1 | Kimenő irány automatikus lezárása | FELTERKEPEZES_288 3. pont | backend | Adott: értéktár→VAULT_COUNTERPARTY célú szállítmány submit után örökre SUBMITTED marad, miközben a küldő készlete már csökkent. Amikor: a `submit`-ben egy null-safe `isCounterparty(toBranch)` ágon a partner-oldali `bookStockIn` kimarad, és a tétel közvetlenül `DELIVERED` állapotba kerül, dedikált `SHIPMENT_AUTO_DELIVERED` audittal. Akkor: a tétel azonnal lezárt, a küldő oldal könyvelése változatlan (már a submit-kor megtörtént). |
| FR-2 | Bejövő irány hibájának javítása, félig-kézi lezárással | FELTERKEPEZES_288 4. pont, Helga döntése | backend | Adott: VAULT_COUNTERPARTY→értéktár irányú submit ma azonnal 422 hibával elutasításra kerül, mert a partner-oldali `bookStockOut` nem talál egyenleget. Amikor: `isCounterparty(fromBranch)` esetén ez a lépés kimarad. Akkor: a submit sikeresen SUBMITTED státuszba kerül; az értéktári dolgozó a meglévő "Megérkezett" (`deliver`) funkcióval maga zárja le, emberi megerősítéssel — nincs automatikus lezárás ezen az irányon. |
| FR-3 | Sztornó megőrzése mindkét irányra | FELTERKEPEZES_288 5. pont | backend | Adott: a mai `CANCELLABLE_STATUSES` nem tartalmazza a DELIVERED-et, és bejövő irányban a sztornó-guard a partner (nem a vault) tokenjét követeli — a vault-dolgozó ma sem tudná visszavonni. Amikor: (a) counterparty-érintett, FR-1 szerint auto-DELIVERED tételre a sztornó engedélyezett, saját-oldali (nem partner-oldali) készlet-visszaforgatással (új "reverseStockIn" a bejövő mintára, ha releváns); (b) bejövő irányon a sztornó-guard a saját (vault) oldal tokenjét nézi, nem a partnerét. Akkor: mindkét irány tétele hiba nélkül visszavonható marad. |

## 5. Adatmodell-érintettség
Nincs új tábla/migráció.

## 6. Kockázatok / TBD
| # | Kérdés |
|---|---|
| 1 | Nincs perzisztált jelzés az "automatikusan lezárt" tételre az entitáson (csak audit-logból visszakereshető) — a sztornó-diszkriminátort a from/to branch típusából kell újraszámolni. |
| 2 | A Pénzforgalom riport és a naplókönyv shipment-ága ma is státusz-vak (csak CANCELLED-et zár ki) — a beragadt SUBMITTED-tételek már ma is szerepelnek bennük a submit napján; ez a javítás ezen nem változtat, csak a státusz-higiénián. |

## 7. Végrehajtási utasítás
1. `cd D:\repo\valutavalto-program`, `git checkout -b feature/trb-shipment-javitas`
2. `git log --all --grep="FK-116"` + `git branch -a | grep -i fk116` — kollízió-ellenőrzés **még nem történt meg**, futtasd le küldés előtt.
3. Fázis 1: FR-1 (kimenő auto-DELIVERED). Fázis 2: FR-2 (bejövő hiba javítása). Fázis 3: FR-3 (sztornó kiterjesztés).
4. DoD: lint, `mvn verify`, `npm run test`, code review, merge/push/deploy.

---
FR-ek száma: 3 db | Csomagok: backend
