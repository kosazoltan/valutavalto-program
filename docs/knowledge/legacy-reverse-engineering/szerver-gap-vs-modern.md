---
type: analysis
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Szerver Legacy vs Modern — Gap Elemzes"
load: on-demand
---

# Szerver Legacy vs Modern — Gap Elemzés
> Utolsó frissítés: 2026-04-05
> A modern backend: `D:\repo\valutavalto-program\backend\`
> Az Electron kliens: `D:\repo\valutavalto-program\penztar-client\`
> A web frontend: `D:\repo\valutavalto-program\frontend-react\`


---

## S1 OSSZEFOGLALO

A legacy központi szerver (~95 modul, ~5MB Delphi kód) funkcionalitásának **~90%-a implementálva van** a modern rendszerben. A maradék 10% vagy elavult (Metro/Tesco/TRADE), vagy alacsony prioritású (jelenlét, DayBook nézet).


---

## S2 TELJES_LEFEDETTSEG_KESZ

| Legacy funkció | Modern service | Megjegyzés |
|----------------|---------------|------------|
| Tranzakció (vétel/eladás) | `TransactionService` | REST API, offline queue (SyncEngine) |
| Sztornó | `StornoService` | Jóváhagyás flow-val |
| Árfolyam kezelés | `RateService`, `ExchangeRateScheduler` | MNB + manuális |
| Napzárás | `DailyClosingService` | 9 lépéses wizard |
| Havizárás | `MonthlyClosingService` | — |
| Évnyitás | `YearOpeningService` | — |
| Dekádzárás | `DecadeReportService` | — |
| NAV zárás | `NavClosingService`, `NavReportService` | Eltérés-kezelés is |
| NAV PTGSZLAH | `NavAbevXmlGenerator` | XML generálás |
| Foglalás | `ReservationService` | Bevételezés/kifizetés/visszafizetés |
| Western Union | `WesternUnionService` | — |
| OTP POS terminál | `PosTerminalService` | — |
| Ügyfél kezelés | `CustomerService` | AML, azonosítás |
| AML/Terror lista | `AmlService`, `BlacklistService` | — |
| Bizonylat nyomtatás | `EscPosReceiptService`, `ReceiptPdfService` | ESC/POS + PDF |
| PEP nyilatkozat | `ReceiptGeneratorService` | 300k+ Ft |
| Jogcím nyilatkozat | `ReceiptGeneratorService` | 300k+ Ft |
| Körlevél | `CircularService` | — |
| Átadólap | `HandoverSheetService` | — |
| Készlet kezelés | `StockService` | — |
| Címlet kezelés | `DenominationService` | — |
| Kezelési díj | `HandlingFeeService` | — |
| Iroda nyilvántartás | `BranchService` | — |
| Dolgozó nyilvántartás | `WorkerService` | — |
| Jogosultságok | Spring Security RBAC | — |
| Versenytárs árf. | `CompetitorRateService` | — |
| Rendőrségi jelzés | `SuspiciousActivityService` | — |
| Bank forgalom | `BankTransactionService` | — |
| Pénztárközi transzfer | `TransferService` | — |
| Adatmentés | Hetzner backup cron | — |
| Jelentések/export | `ReportService`, `NbReportGenerator` | — |
| Kommunikáció (FTP) | REST API + SyncEngine | **Kiváltva** |


---

## S3 RESZLEGES_LEFEDETTSEG_MIND_KESZ

| # | Legacy funkció | Modern | Eredmény |
|---|----------------|--------|----------|
| SG-1 | DayBook (irodai napi státusz áttekintés) | `DailySession` entity + query | ✅ Query-vel elérhető: `SELECT branch_id, status FROM daily_session WHERE closing_date = ?` |
| SG-3 | MNB árfolyam automatikus letöltés | `ExchangeRatePollingService` | ✅ `@Scheduled(cron="0 30 8 * * MON-FRI")` + `@Scheduled(cron="0 0 14 * * MON-FRI")` — MNB→ECB→CACHED fallback |
| SG-4 | Haszon számítási képlet | `ProfitCalculationService` | ✅ `revenue = totalSellHuf - totalBuyHuf` — ekvivalens a legacy spread-képlettel |
| SG-7 | Rendőrségi jelentés formátum | `PoliceRequestService` + `PoliceRequestController` | ✅ Teljes implementáció |
| SG-9 | WU ÁFA kezelés | `DailyWuAfaTransaction` + `DailyClosingArchiveService` | ✅ Napzárás snapshot + havi PDF |


---

## S4 KORABBI_GAP_EK_FELULVIZSGALVA

| # | Legacy funkció | Eredmény | Megjegyzés |
|---|----------------|----------|------------|
| SG-2 | Jelenlét nyilvántartás | ✅ Backend kész (`WorkerAttendance` entity + repo + service + controller). Frontend oldal P3. | Frontend attendance page hiányzik, de az üzleti logika+API kész |
| SG-5 | Helga alrendszer | ✅ NEM GAP | Helga = lokális szerver (körzeti iroda DLL-ek: arftmk, beerk, dolgozok, import, mnbhibak, tranzdij, westforg, zarasok). A modern centrális backend + SyncEngine teljes egészében kiváltja. |


---

## S5 ELAVULT_NEM_IMPLEMENTALANDO

| Legacy modul | Ok |
|-------------|-----|
| TRADE (telefon feltöltés, matrica, kupon) | Szolgáltatás megszűnt |
| METRO bérelt pénzváltó | Üzleti kapcsolat megszűnt? |
| TESCO bérelt pénzváltó | Üzleti kapcsolat megszűnt? |
| HRK (horvát kuna) | EUR-ra váltott 2023-ban |
| FTP kommunikáció | REST API-val kiváltva |

---


---

## S6 BACKEND_ELECTRON_FRONTEND_KAPCSOLODASI_MATRIX

### Electron → Backend (SyncEngine REST hívások)

| SyncEngine metódus | Backend endpoint | Státusz |
|-------------------|-----------------|---------|
| `syncTransaction` | `POST /transactions/sell` vagy `/buy` | ✅ |
| `syncConversion` | `POST /transactions/conversion` | ✅ |
| `syncBankTransaction` | `POST /ertektar/bank-transactions` | ✅ |
| `syncStorno` | `POST /stornos/execute` | ✅ |
| `syncDistribution` | `POST /ertektar/distribution` | ✅ |
| `syncTransfer` | `POST /transfers` | ✅ |
| `syncCollection` | `POST /ertektar/collections` | ✅ |
| `syncHandoverOperation` | `POST /handover-sheets/*` | ✅ |
| `syncRates` | `GET /exchange-rates/pos-current` | ✅ |
| `syncCirculars` | `GET /circulars` | ✅ |
| `cacheBranchStatus` | `GET /ertektar/branches/status` | ✅ |
| `syncCashDeskMasterData` | `GET /branches?activeOnly=true` | ✅ |
| `syncWorkerMasterData` | `GET /workers/active` | ✅ |
| `bootstrapAuthSession` | `POST /auth/login` + `/auth/login/select-role` | ✅ |
| `validateToken` | `GET /workers/me` | ✅ |

### Frontend → Backend (React Axios)

| API modul | Fájl | Lefedettség |
|-----------|------|-------------|
| Auth | `api/auth.ts` | Login, role selection, logout |
| Transactions | `api/transactions.ts` (37K) | Buy, sell, storno, conversion, bank, reports |
| Exchange rates | `api/exchange-rates.ts` (13K) | CRUD, MNB, limit rates |
| Settings | `api/settings.ts` (43K) | System params, branches, workers, currencies |
| Reports | `api/reports.ts` (14K) | Daily, monthly, decade, export |
| Decade reports | `api/decade-reports.ts` | Generate, close, list |
| Users | `api/users.ts` | Workers, roles |

### Frontend → Electron (IPC bridge)

| IPC handler | Funkció |
|-------------|---------|
| `print-receipt` | ESC/POS nyomtatás |
| `open-cash-drawer` | Pénztárfiók nyitás |
| `save-pending-*` | Offline queue (tranzakció, konverzió, bank, stornó, transfer, handover) |
| `get-pending-*` | Pending queue lekérdezés |
| `sync-offline` | Manuális sync trigger |
| `secure-store/load/clear-token` | DPAPI titkosított token kezelés |
| `camera-*` | Kamera/RTSP/videó kezelés |
| `scan-*` | Okmány scan |
| `get/set/delete-config` | SQLite config |
| `get-cached-*` | Branch/rate/worker cache |

---


---

## S7 IMPLEMENTACIOS_PRIORITASOK

### Azonnal (P0) — Mind KÉSZ ✅
Nincs P0 gap.

### Következő Sprint (P1) — Ellenőrizendő
1. **SG-3**: MNB árfolyam automatikus letöltés — van-e scheduler?
2. **SG-4**: Haszon képlet egyezés verify
3. **SG-9**: WU ÁFA logika teljessége

### Backlog (P2-P3)
4. **SG-1**: DayBook összesítő nézet (branch status dashboard)
5. **SG-2**: Jelenlét nyilvántartás
6. **SG-5**: Helga alrendszer tartalom
7. **SG-7**: Rendőrségi jelentés formátum

### Nem szükséges
- TRADE, Metro, Tesco, HRK, FTP
