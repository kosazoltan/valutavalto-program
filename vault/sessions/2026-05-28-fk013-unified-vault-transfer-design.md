# FK-013 — Egységes értéktári átadás-átvétel menü (design + spec)

**Forrás**: Kasza Helga + Bali Henriett (Szeged Értéktár) 2026-05-28 kérés (Downloads/FK-013_Ertektari_atadasatvétel_teruleti_szures.md).
**Prioritás**: Magas. **Megrendelő**: Főértéktár.

## Cél
A két jelenlegi értéktári menüpont (`Átadás-átvétel (pénztáraknak)` + `Átadás bank / másik értéktár`) egyetlen menüpontba vonva, a "Cél iroda" legördülő egy listában, **3 csoportban**:
- Területi pénztárak (saját régió)
- Társ értéktárak (másik 7)
- 10 fix banki/speciális partner (PRB/UPT/TRB/ERB/FRB/RB/JRB/MNB/TH/FOP1)

A pénztári oldal nem változik.

## Arch-döntések (brainstorming approved)
1. **DB-modellezés**: 10 fix partner speciális `Branch` entry-k (új `BRANCH_TYPE=VAULT_COUNTERPARTY` dictionary entry). A meglévő `shipment_request` flow változás nélkül kezeli őket.
2. **Régi menüpontok**: mindkettő eltávolítva az ÉRTÉKTÁR (lokál) szekcióból. EGY új menüpont marad.
3. **Partner-scope**: cégenként 1 példány, `region_code=NULL` (nem területi). Multi-tenant: `company_id` FK kötelező.
4. **Frontend route**: a régi `/shipments` URL megmarad (visszafelé-kompatibilis a pénztárosi oldalnak); az új egységes flow ezt használja kibővítve. Az értéktárosi menüpont label: "Átadás-átvétel".
5. **Régi `Transfer` flow**: érintetlen marad az értékszállító-role számára (`/transfers` route).

## DB (V277 migráció)
- `dictionary` új entry: `(category='BRANCH_TYPE', code='VAULT_COUNTERPARTY', name='Banki / speciális partner', name_hu='Banki / speciális partner')`
- `branch` táblába 10 fix partner seed-elve (EBC-re):
  | code | name_hu | leírás |
  |---|---|---|
  | PRB | POS Raiffeisen Bank | POS (bankkártyás) pénzek átvétele |
  | UPT | Úton lévő pénztár | Más értéktárnak küldött szállítás alatti valuta |
  | TRB | Területek közötti Raiffeisen Bank | Területek közti forint mozgás |
  | ERB | Egyedi Raiffeisen Bank | Egyedi banki valuta/forint ki/be |
  | FRB | Fixing Raiffeisen Bank | Fixingen kihozott/beszállított valuta |
  | RB | Raiffeisen Bank | Fixingen kihozott valuta forint ellenértéke |
  | JRB | Jutalék Raiffeisen Bank | Előző havi területi haszon befizetése |
  | MNB | Magyar Nemzeti Bank | Hamisgyanús valuta/forint |
  | TH | Többlet/Hiány pénztár | Területi többlet/hiány kezelés |
  | FOP1 | 1-es főpénztár | Visszapótlás, hó végi rendezés |

  Mindegyik: `branch_type_did=(VAULT_COUNTERPARTY)`, `is_active=true`, `is_vault=false`, `region_code=NULL`, `region='ORSZAGOS'`, `city='BUDAPEST'`, `address=name_hu` (default).

## Backend
- Új endpoint `GET /api/v1/branches/vault-counterparties` (auth: ÉRTÉKTÁR/FŐÉRTÉKTÁR + cég-szintű role-ok). Response:
  ```json
  {
    "territorialCashiers": [ BranchDto, ... ],   // saját régió aktív pénztárai
    "peerVaults": [ BranchDto, ... ],            // 7 másik értéktár (cég-scope)
    "fixedCounterparties": [ BranchDto, ... ]    // 10 VAULT_COUNTERPARTY branch
  }
  ```
- `BranchService.findVaultCounterparties()`:
  - `territorialCashiers` — a meglévő `findActiveByCompanyIdAndRegionCode` szerinti pénztárak (KESZLEX szerinti region_code)
  - `peerVaults` — `findByCompanyIdAndIsVaultTrueAndIsActiveTrue`-ból a saját branch kihagyva
  - `fixedCounterparties` — `findByCompanyIdAndBranchTypeCode("VAULT_COUNTERPARTY")` (új repo-metódus)
- Multi-tenant: SecurityUtils.getCurrentCompanyId(), Branch.company FK-szűrés mindenhol.
- LazyInit-védelem: a BranchMapper DTO-mappingje a service tx-ében fut (mint a többi finder).

## Frontend
- **Új típus** `VaultCounterpartiesResponse` (territorialCashiers / peerVaults / fixedCounterparties).
- **Új API**: `branchApi.listVaultCounterparties()`.
- **`ShipmentNewPage.tsx`** kibővítése: ha az user `branchType=VAULT` → a `Cél iroda` dropdown 3-csoportos `<optgroup>`:
  - `<optgroup label="Saját terület pénztárai">…</optgroup>`
  - `<optgroup label="Társ értéktárak">…</optgroup>`
  - `<optgroup label="Banki és speciális partnerek">…</optgroup>`
- **menuGroups.ts** (ÉRTÉKTÁR szekció):
  - ELTÁVOLÍTVA: `Átadás-átvétel (pénztáraknak)` + `Átadás bank / másik értéktár`
  - HOZZÁADVA: **`Átadás-átvétel`** → `/shipments` (egységes), egyetlen menüpont
- Az `Új ÁTADÁS` / `Új ÁTVÉTEL` 2 gomb (a docx A. pont, #887 megtéve) — érintetlen.
- A "Kérő iroda" auto-fill a saját értéktárral (B+C, #888 megtéve) — érintetlen.

## Tesztek
- Backend: `BranchServiceTest.findVaultCounterparties` — happy path 3 csoport-tartalom verifikálva.
- Frontend: `ShipmentNewPage.test.tsx` bővítés — 3 optgroup-szekció a dropdown-ban.

## Verzió
- v2.27.46 (4-way sync). Csak backend+frontend → nincs Electron-natív → telepítő-build nem kell.

## Konzisztencia-utánkövető scope
- A `/transfers` (TransferPage) az értékszállító-é marad. Az értéktáros már nem hozzáfér ezen az úton, csak az egységes `Átadás-átvétel`-en.
- A `Transfer` entitás működő-flow marad, nem törlünk semmit.

## Acceptance kritériumok
1. Bali Henriett (értéktáros, Szeged) a "Cél iroda" dropdown-ban LÁTJA: saját terület pénztárait + 7 másik értéktárat + 10 fix partnert (PRB/UPT/TRB/...).
2. A pénztárosi oldal (ShipmentListPage pénztárosi route-ja) NEM változik (Bali a docx-ben kifejezetten ezt kéri).
3. Új shipment-igény rögzítése a 10 fix partner valamelyikére **sikeresen elmentődik** (a meglévő `shipment_request` táblába, `to_branch_id` = a VAULT_COUNTERPARTY branch UUID-je).
4. A bal oldali ÉRTÉKTÁR menüben EGY menüpont marad a két régi helyett.
