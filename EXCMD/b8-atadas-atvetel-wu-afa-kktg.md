# Modul: Átadás-átvétel, Western Union, ÁFA, kezelési költség, haszon

<system_context>
## Rendszerkontextus és Cél
A régi program "egyéb havi adatai" riportjának STRUKTÚRÁJÁT és üzleti szabályait leírni: napi bontású Western Union, e-kereskedelem, ÁFA-visszatérítés, kezelési költség, értéktár befizetés/átvétel (pénzátadás), valamint a kezelési költség jelentés és haszonszámítás logikája.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Pénztáros | WU napi mozgás rögzítés saját pénztárra, kezelési díj rögzítés | CASHIER |
| Értéktáros / Főértéktáros | Kezelési költség befizetés/átvétel, körzet egyéb-adatok, pénzszállítás indítása | VAULT_KEEPER / HEAD_VAULT_KEEPER |
| Ügyvezető / Belsőellenőr | ÁFA, haszon, cég-szintű egyéb-adatok | EXECUTIVE / INTERNAL_AUDITOR |
| Adminisztrátor | Minden | ADMIN |

## Hatókör (Scope)
### IN
- "EGYÉB HAVI ADATAI" riport: napi soros (1–31. nap) WU + e-kereskedelem + ÁFA-visszatérítés + kezelési költség mozgások irodánként/körzetenként/cégenként.
- Western Union al-blokk: NYITÓ, BEVÉTEL, KIADÁS, ZÁRÓ kézi rögzítése.
- Kezelési költség al-blokk: BEFIZETÉS ÉRTÉKTÁRNAK, BEVÉTEL ÜGYFÉLTŐL, ÁTVÉTEL PÉNZTÁRTÓL.
- Elektromos kereskedés al-blokk: NYITÓ, BEVÉTEL BANKTÓL, KIADÁS PÉNZTÁRNAK, VISSZATÉRÍTÉS (USD/HUF), ZÁRÓ.
- ÁFA-visszatérítés, MATRICA, TELEFON, ÁTADÁS, ÁTVÉTEL napi mezők.
- Kezelési költség jelentés bizonylat (napi/dekád) "K-" prefix sorszámozással.
- Pénzszállítás / Átadás-Átvétel tranzakciós metaadatok (Plomba azonosító és Szállító rögzítése).

### OUT
- Western Union közvetlen API integráció (nincs API kapcsolat, a rendszer kizárólag manuális egyenleg- és forgalomrögzítést támogat).
- Automatikus banki kivonat feldolgozás az e-kereskedelemhez.

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | WU/elektromos záró-egyenleg napi folytonosság (előző nap záró = következő nap nyitó) | invariáns-teszt nem bukik |
| NFR-2 | Multi-tenant + multi-currency (USD/HUF) az elektromos kereskedés blokkban | minden összeg currency-vel dimenzionált |
| NFR-3 | HUF 5 Ft kerekítés | minden HUF mező roundHuf |
</system_context>

<functional_spec>
## Funkcionális Követelmények

### FR-1 "EGYÉB HAVI ADATAI" riport fejléc cég + hónap
- **Leírás**: Riport fejléc cég és hónap szerint (pl. "EXCLUSIVE BEST CHANGE KFT 2024 FEBRUÁR EGYÉB HAVI ADATAI").
- **Forrás**: `WU...xlsx`
- **Prio**: M
- **Csomag/Komponens**: kozponti-client, frontend-react
- **Bemenő adatok**: Cég kiválasztása, Hónap/Év
- **Kimenet / Visszajelzés**: Megjelenített fejléc szövege a riportban

### FR-2 Napi soros bontás
- **Leírás**: Napi soros bontás: minden iroda alatt 1 sor / nap (DÁTUM 1-től 28/29/30/31-ig).
- **Forrás**: `WU...xlsx`
- **Prio**: M
- **Csomag/Komponens**: frontend-react

### FR-3 Western Union manuális egyenlegek
- **Leírás**: Western Union napi adatok manuális bevitele: NYITÓ, BEVÉTEL, KIADÁS, ZÁRÓ (Záró = Nyitó + Bevétel - Kiadás). Nincs közvetlen API kapcsolat a Western Union rendszerével.
- **Forrás**: `WU...xlsx`, `WUNION.md`
- **Prio**: M
- **Csomag/Komponens**: penztar-client, frontend-react
- **Bemenő adatok**: Nyitó, napi bevétel, napi kiadás
- **Kimenet / Visszajelzés**: Kiszámolt és mentett záró egyenleg

### FR-4 Kezelési költség blokk
- **Leírás**: Kezelési költség (kktg) rögzítése és riportálása: BEFIZETÉS ÉRTÉKTÁRNAK, BEVÉTEL ÜGYFÉLTŐL, ÁTVÉTEL PÉNZTÁRTÓL.
- **Forrás**: `WU...xlsx`
- **Prio**: M
- **Csomag/Komponens**: penztar-client

### FR-5 Elektromos kereskedés (E-ker) egyenlegek
- **Leírás**: E-kereskedelem egyenlegeinek vezetése USD és HUF devizákban: NYITÓ, BEVÉTEL BANKTÓL, KIADÁS PÉNZTÁRNAK, VISSZATÉRÍTÉS, ZÁRÓ.
- **Forrás**: `WU...xlsx`
- **Prio**: S
- **Csomag/Komponens**: frontend-react

### FR-6 ÁFA VISSZATÉRÍTÉS napi mezők
- **Leírás**: ÁFA-visszatérítések kezelése. A rendszer támogatja a Tesco (V- bizonylatprefix) és a Metro Cash & Carry (AV- bizonylatprefix) ÁFA-visszatérítési bizonylatokat standard magyar ÁFA-kulcsokkal (5%, 18%, 27%). A kifizetés minden esetben HUF-ban történik.
- **Forrás**: `WU...xlsx`, `METRO.md`, `TESCO.md`
- **Prio**: M
- **Csomag/Komponens**: frontend-react

### FR-7 Pénzszállítás / Átadás-Átvétel metaadatok
- **Leírás**: Irodák közötti vagy értéktári átadás-átvételi bizonylat rögzítésekor kötelező a biztonsági zárókupak/szállítózsák plomba metaadatainak megadása (`plombaszam` - pl. "PL-998822") és a szállító/kísérő nevének (`szallito`) rögzítése a bizonylaton.
- **Forrás**: `ATADVET.md`, `unit2.pas`
- **Prio**: M
- **Csomag/Komponens**: penztar-client, backend
- **Bemenő adatok**: Szállító neve, plomba azonosítója
- **Validációk és Kényszerek**: Plombaszám nem lehet üres értéktári átadásoknál.

### FR-8 Haszon riport és számítás
- **Leírás**: Pénztárankénti realized és WAC (Weighted Average Cost) alapú haszonszámítás.
- **Formula**:
  - `Realized Profit = (Sale Price - Acquisition WAC Cost) * Quantity`
  - A haszonszámítás tranzakciónként történik, a valutakészlet súlyozott átlagos bekerülési értékét a `currency_stock` tábla követi, a realized profit pedig a `profit_log`-ba íródik.
- **Forrás**: `ProfitCalculationService.java`, `WacService.java`
- **Prio**: M
- **Csomag/Komponens**: backend, kozponti-client

### FR-9 Pénzszállítás szállító és plomba validációja
- **Leírás**: Pénztárak és értéktárak közötti szállításoknál (mind a `/transfers` oldali átadásoknál, mind a `/shipments/new` szállítási igénynél) kötelező megadni a szállítót és a plombaszámot:
  - **Szállító neve** (`carrierName` / `szallito`): kötelező, max 128 karakter.
  - **Plombaszám** (`sealNumber` / `plombaszam`): kötelező, max 64 karakter, formátuma csak betűket, számokat, kötőjelet és perjelet tartalmazhat: `^[A-Za-z0-9\-/]+$`.
  - A backend `CreateTransferDto` szintjén `@NotBlank`, `@Size` és `@Pattern` annotációkkal kell kényszeríteni a validációt. A `transfer` adatbázis-táblában a mezőkhöz `VARCHAR(128)` és `VARCHAR(64)` típus és a fenti formátumot lefedő `CHECK` constraint tartozik.
- **Forrás**: 2026-06-02 plomba audit
- **Prio**: Magas (P1)
- **Csomag/Komponens**: backend / penztar-client / frontend-react

### FR-10 Szállítási bizonylat nyomtatása és adattartalma
- **Leírás**: A szállítás/átadás sikeres rögzítése után közvetlenül elérhetővé kell tenni egy "Nyomtatás" gombot. A nyomtatott/preview bizonylaton kötelezően meg kell jelennie a megadott szállítónak és plombának:
  - `Szállító: <szállító neve>`
  - `Plombaszám: <plombaszám>`
  - A bizonylat-adatszerkezet (`PrintReceiptData` mind React frontend, mind Electron szinten) bővül `carrierName?: string` és `sealNumber?: string` mezőkkel.
  - A nyomtatást végző text/HTML sablonok (`generateTransferLines`, `generateTransferHtml`) és a `ReceiptPreviewModal` előnézeti modal is megjeleníti ezeket a mezőket.
- **Forrás**: 2026-06-02 plomba audit
- **Prio**: Magas (P1)
- **Csomag/Komponens**: penztar-client / frontend-react
</functional_spec>

<data_structure>
## Legacy és Jelenlegi Adatmodell Mappings

### Legacy Adatbázis Táblák (InterBase)
- `WUAFAADATOK`: Western Union napi egyenlegek és kezelési költségek táblája.
- `METROAFAMOZGAS`: Metro Cash & Carry ÁFA visszatérítési tranzakciók táblája.
- `WUMOZGAS`: Western Union napi forgalmi és jutalék adatai.
- `EKERESKEDELEM` / `EKERDATA`: Elektromos kereskedés tranzakciói és napi egyenlegei (USD/HUF).
- `WPENZSZALLITAS`: Pénzszállítások és plombák adatai (pl. `DATUM`, `BIZONYLATSZAM`, `PLOMBASZAM`, `SZALLITO`).
- `BLOKKFEJ` / `BLOKKTETEL`: Pénzátadási bizonylat fej- és tételsor adatai.

### Jelenlegi Postgres Adatmodell
- `western_union_daily_balances` (legacy `WUAFAADATOK` megfelelője):
  - `id` (bigserial primary key)
  - `company_id` (uuid)
  - `branch_id` (uuid)
  - `date` (date)
  - `opening_balance` (numeric(15,2))
  - `income` (numeric(15,2))
  - `expense` (numeric(15,2))
  - `closing_balance` (numeric(15,2))
- `handling_fee_transactions` (kezelési költség tranzakciók):
  - `id` (bigserial primary key)
  - `receipt_number` (varchar(50)) -- Pl. "K-000675"
  - `transaction_type` (varchar(30)) -- 'VAULT_DEPOSIT', 'CLIENT_INCOME', 'CASHIER_TRANSFER'
  - `amount` (numeric(15,2))
  - `direction` (varchar(3)) -- 'IN' / 'OUT'
  - `bank_vault_code` (varchar(10)) -- Pl. "RB"
- `cash_transfer` (átadás-átvételi bizonylat):
  - `id` (uuid primary key)
  - `source_branch_id` (uuid)
  - `target_branch_id` (uuid)
  - `amount` (numeric(15,2))
  - `currency_id` (bigint)
  - `seal_number` / `plombaszam` (varchar(50)) -- Pénzszállítási plomba kódja
  - `carrier_name` / `szallito` (varchar(100)) -- Szállító személy neve
- `currency_stock` (WAC készletnyilvántartás):
  - `id` (bigserial primary key)
  - `company_id` (uuid)
  - `currency_id` (bigint)
  - `total_quantity` (numeric(15,4))
  - `total_acquisition_cost_huf` (numeric(19,4)) -- Súlyozott átlagos HUF bekerülési érték
- `profit_log` (realizált haszon napló):
  - `id` (bigserial primary key)
  - `transaction_id` (bigint)
  - `realized_profit_huf` (numeric(15,2))
</data_structure>

<integration_points>
## Integrációs Pontok és API-k
- **Western Union**: Nincs külső API integráció. A pénztáros a Western Union különálló kliensén végzett napi zárás adatait (nyitó, bevételek, kiadások, záró) manuálisan rögzíti a valutaváltó kliensben.
- **ÁFA Visszatérítés**: A Tesco (V- prefix) és Metro (AV- prefix) számlákat a rendszer a kassza-kliensben rögzíti, és a napi zárás során a NAV online pénztárgép driveren keresztül küldi be a NAV felé.
- **Szinkronizáció**: A `penztar-client` offline üzemmódot támogat. A napi WU balances és kktg tranzakciók az SQLite lokális adatbázisba kerülnek mentésre, és hálózati kapcsolat esetén a Sync Agent automatikusan felszinkronizálja azokat a központi Postgres szerverre.
</integration_points>

<execution_workflow>
## Végrehajtási Folyamat
1. **Pénzátadás / Pénzszállítás**: Az iroda indítja az átadást, megadva az összeget, valutát, kísérő nevét és a plombaszámot. A fogadó iroda az átvételkor ellenőrzi a plomba épségét, majd jóváhagyja a tranzakciót.
2. **WU Napi Zárás**: A nap végén a pénztáros lekéri a WU terminál összesítőjét, beírja a napi WU bevételeket/kiadásokat a valutaváltó szoftverbe, amely ellenőrzi az egyenleg-folytonosságot.
3. **Haszonszámítás**: Tranzakció lezárásakor a `WacService` és `ProfitCalculationService` frissíti a `currency_stock` táblát, és kiszámítja a realized profitot a `profit_log` táblába.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| 1 | ÁFA-visszatérítés számítási szabálya (kulcs, alap) | Helyes ÁFA összeg számítása | **RESOLVED**: Metro (AV-) és Tesco (V-) bizonylatok HUF-ban kerülnek kifizetésre a standard 5%, 18%, 27%-os ÁFA kulcsok szerint, a tranzakciókat a `METROAFAMOZGAS` és `TESCO` táblák rögzítik. |
| 2 | Haszonszámítás képlete pénztáranként | Profitabilitás mérése | **RESOLVED**: WAC haszonszámítás tranzakciónként: realized profit = `(sale_price - acquisition_wac_cost) * quantity`, a `currency_stock` és `profit_log` segítségével. |
| 3 | Western Union külső integráció vs manuális rögzítés | Adatforrás pontos meghatározása | **RESOLVED**: Kizárólag manuális napi egyenleg bevitel támogatott (Nyitó, Bevétel, Kiadás, Záró), nincs közvetlen API integráció. |
| 4 | "VISSZA TÉRITÉS" USD/HUF jelentése az e-ker blokkban | Dimenzionálás | **RESOLVED**: Az elektromos kereskedelmi tranzakciók (USD és HUF egyenlegek) visszatérítéseit a `EKERESKEDELEM` és `EKERDATA` táblák kezelik. |
| 5 | Külön átadás-átvétel havi kimutatás struktúrája | Igényelt funkció | **RESOLVED**: A havi irodák közötti átadás-átvétel (pénzszállítás) bizonylatok listája a `cash_transfer` táblából készül, tartalmazva a plomba és szállító kísérő metaadatokat. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva.
- [x] Nincsenek kitalált vagy hallucinált követelmények (az integrációs és plombaszám részletek Pascal/Java kód alapján verifikálva).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=8 db, TBD=5 db, érintett csomagok=penztar-client, frontend-react, kozponti-client, backend.
</verification_checklist>
