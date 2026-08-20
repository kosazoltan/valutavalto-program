# Spec: FK-091 HQ vészkijárat + bridged jelzés, FK-092 transzfer-riasztás idempotencia

> Dátum: 2026-08-20 · Forrás: jóváhagyott hibajegyek (Downloads FK-091, FK-092) · Állapot: JÓVÁHAGYVA (a jegyek)

## 1. Cél

A napzárás HQ-küldése üres URL mellett ne blokkoljon: a meglévő artifact-vészkijárat élesben bekapcsolva, `evening_sync_log.is_bridged` megkülönbözteti a helyi fájlba írást a valódi HQ 2xx-től. A transzfer-egyeztetés riasztása ne némuljon el örökre egy átadólapra: az idempotencia-kulcs legyen `cég:átadólapszám:mai dátum` (Europe/Budapest).

## 2. NEM cél

- Valós HQ HTTP végpont, auth, timeout, RestTemplate-csere
- `status` új értéke, EveningClosingPage badge, backfill, `company_id` / UNIQUE az `evening_sync_log`-on
- `audit_log` idempotencia-minta, foglaló-értesítés `userId`, unique constraint a notification táblán
- Frontend, pénztár/értéktár SQLite, telepítő

## 3. Érintett területek

- `EveningSyncLog`, Flyway `V381__evening_sync_log_is_bridged.sql`
- `EveningClosingService.sendToHeadquarters` bridged vs HTTP 2xx ág
- `application-production.properties` (`EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED` default `true`)
- `TransferReconciliationService.notifyDiscrepancy` + `Clock`
- `EveningClosingServiceTest`, `TransferReconciliationServiceTest`

## 4. Rögzített döntések

- Flyway: `ALTER TABLE evening_sync_log ADD COLUMN is_bridged BOOLEAN NOT NULL DEFAULT false` (aktuális max V380 → V381)
- Bridged ág: `status=EVENING_SYNC_DONE` + `is_bridged=true`; HTTP 2xx: `is_bridged=false` explicit
- PENDING / ARTIFACT_PENDING / FAILED: `status` értékkészlet nem bővül; `is_bridged` ezeken az
  kimeneteken explicit `false` (újrafelhasznált sor korábbi bridged sikerét is visszaállítja)
- Production default `true`; visszaállítás: env `EVENING_CLOSING_ARTIFACT_SUCCESS_ENABLED=false` (kód nélkül)
- entityId: `companyId + ":" + transferNumber + ":" + LocalDate.now(clock)` ; `Clock.system(Europe/Budapest)`
- Legacy: memória-query üres — Delphi ESTIZAR/FTP, nincs `evening_sync_log.is_bridged`. Szándékos modern eltérés.

## 5. Edge case-ek

- Üres HQ URL + kapcsoló ki → ARTIFACT_PENDING, is_bridged=false (helyi/dev)
- Üres HQ URL + kapcsoló be → DONE + is_bridged=true
- HQ 2xx → DONE + is_bridged=false
- Ugyanaz a nap, ugyanaz az átadólap: azonos entityId (NotificationService dedup)
- Következő nap: új entityId
- Két cég, azonos transferNumber: különböző entityId
- UTC vs Budapest dátumhatár

## 6. Elfogadási kritériumok (EARS)

- WHEN a migráció lefut THEN the system SHALL have `evening_sync_log.is_bridged NOT NULL DEFAULT false`
- WHEN HQ URL üres AND artifact-success enabled THEN SHALL persist `EVENING_SYNC_DONE` AND `is_bridged=true`
- WHEN HQ HTTP 2xx THEN SHALL persist `EVENING_SYNC_DONE` AND `is_bridged=false`
- WHEN production profile starts without env override THEN artifact-success SHALL be true
- WHEN notifyDiscrepancy runs THEN entityId SHALL be `{companyId}:{transferNumber}:{yyyy-MM-dd}` in Europe/Budapest
- WHEN the same discrepancy is reconciled twice on the same local date THEN both calls SHALL use the same entityId
- WHEN the discrepancy persists on the next local date THEN entityId SHALL differ by date
- WHEN two companies share a transfer number THEN their entityIds SHALL differ by companyId

## 7. Tesztterv

- `EveningClosingServiceTest`: bridged `isBridged=true`; fail-closed ARTIFACT_PENDING `false`; HTTP 2xx `false`; FAILED `false`
- `TransferReconciliationServiceTest`: Clock-injektálás; meglévő notify-assert composite key; FR-3/4/5 új tesztek
