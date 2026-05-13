---
title: Forrás-források és implementáció GAP elemzés (2026-05-13)
created: 2026-05-13
source_docs:
  - D:\repo\valutavalto-program\Anti\ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md (2026-03-20, 37 kB)
  - D:\repo\valutavalto-program\Anti\antivaluta.md (2026-04-02, 30 kB)
  - D:\repo\valutavalto-program\Felmérés\Valuta\v2.0\Markdown\ (45 fájl, 2025-04→2025-05)
  - D:\repo\valutavalto-program\Felmérés\Valuta\Kósa Tervezés és fejlesztés\Bank API\API_bank.docx
  - D:\repo\valutavalto-program\Felmérés\Valuta\Terrorlista2008.txt (184 kB, 2024-11)
  - D:\repo\valutavalto-program\Felmérés\Valuta\Árfolyam karbantartó hibalista.docx (219 kB, 2025-02)
qmd_collections_added:
  - valutavalto-anti-legacy (227 fájl indexelve)
  - valutavalto-felmeres-v2 (45 fájl indexelve)
implementation_version: v2.5.49 (2026-05-13)
backend_stats:
  - 240 entity
  - 211 service
  - 152 controller
  - 208 Flyway migration (V1..V214)
---

# Forrás-források VS jelenlegi implementáció — GAP elemzés

## Módszer

1. Beolvastam mindkét forrásrendszert:
   - `Anti/` — Legacy Delphi 7 + Java rendszer feltárása (32960 fájl, releváns: 2 fő md + alkönyvtárak)
   - `Felmérés/Valuta/` — 2025-ös v2.0 spec + szervezeti dokumentumok (416 fájl)
2. Indexeltem QMD-be (2 új kollekció, 272 fájl, 1153 vektor)
3. Összevetettem a v2.5.49 backend kódbázissal (240 entity / 211 service / 152 controller)

## Kulcsforrás-dokumentumok

### A) ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md (Anti/)
**2026-03-20, 37 KB, 20-fázisos masterplan.**

Fő követelmények:
- Offline-first, security-first, role-based, auditálható, telephelyi
- Stack: Java 21 + Spring Boot 3 + React + Electron + PostgreSQL ✅ (MEGVALÓSÍTVA)
- 50 valutaváltó iroda kiszolgálása
- 50 nap helyi videó retention
- AES-256-GCM + TPM/HSM
- Pénztári kamera + intim kamera
- Darius/Raiffeisen napi jelentés modul
- 10 RBAC szerepkör (CASHIER, CASHIER_SUPERVISOR, TREASURY_OPERATOR, TREASURY_MANAGER, MAIN_TREASURY, REGIONAL_MANAGER, COMPLIANCE_OFFICER, IT_ADMIN, SYSTEM_ADMIN, AUDITOR)
- 20+ permission (TRANSACTION_CREATE/CANCEL, CASHDESK_OPEN/CLOSE_DAY, EXCHANGE_RATE_PUBLISH, VIDEO_VIEW_LOCAL/REGION/GLOBAL, VIDEO_EXPORT, USER_MANAGE, ...)

### B) antivaluta.md (Anti/)
**2026-04-02, 30 KB, legacy Delphi 7 rendszer teljes katalógusa.**

Tartalom:
- IBVALTO.DPR projekt: 50+ Unit (Unit1=FORM1 főablak, Unit2=OPENKERDOFORM, ..., Unit47=FOMENUFORM)
- 109 egyedi DLL
- Főmenü 2 oldal × 8+ menüpont
  - 1. oldal: VÉTEL/ELADÁS/KONVERZIÓ/ÁTADÁS-ÁTVÉTEL/SZTORNÓ/NAPI FORGALOM/RÉGEBBI NAPZÁRÁS/PILLANATNYI ÁLLÁS/BEÁLLÍTÁSOK
  - 2. oldal: ÁRFOLYAM/PÉNZTÁR ÁLLÁS/BIZONYLATOK/LISTÁK/TÁRSPÉNZTÁRAK/VALUTA FORGALOM/NAPI-HAVIZÁRÁS/CÍMLETEZÉS
- F1-F12 gyorsgombok: History, Előleg, Terminal, ÁFA, Mai forgalom, Tesco ÁFA, Supervisor, Készlet, Átadólap, ÁFA, WU, Escape, Főmenü, Futófény, Körlevél, Reprint

### C) Felmérés/Valuta/v2.0/Markdown/ (2025-04 → 2025-05)
**45 markdown fájl, 6 fő funkcionális dokumentáció.**

valuta_folyamatok/ (8 fájl):
- 01_alapfolyamatok.md — devizanem, árfolyam, fiók
- 02_penztarkezeles.md — banknote_inventory, kasszanyitás-zárás
- 03_tranzakciok.md — vétel/eladás/konverzió/sztornó folyamat, jutalék, ügyfél-azonosítás
- 05_ugyfelkezeles.md — Customer + AML + KYC
- 07_cimletkezeles.md — címletezési stratégiák + szabályok
- README, crud_komponensek, modulstruktura

modulstruktura.md főmodulok:
1. Alapadatok (currency, exchange_rate, branch, worker, cashier)
2. Pénztár (transaction, banknote_inventory, daily_closing, denomination_optimization)
3. Ügyfélkezelés (customer, customer_type)
4. Szállítmány
5. Jelentés és elemzés
6. Adminisztráció

### D) Egyéb fontos források
- **API_bank.docx** (Bank API specifikáció) — még nem feldolgozva
- **Terrorlista2008.txt** (184 kB AML lista) — beolvasandó
- **Árfolyam karbantartó hibalista.docx** (219 kB) — régi hibalista
- **Telephelyi hardver dokumentumok** (37 docx, irodánként)
- **Hangfelvételek és képernyőképek** (binárisok, csak meta-szinten)

## Megvalósítva v2.5.49-ben (verifikálva)

### ✅ Backend entitások (240 db, releváns kivonat)

| Domain | Entitás | Megvalósítva |
|---|---|---|
| Camera | CameraConfig, CameraRecording, CameraAccessLog, CameraExportRequest, CameraSegmentHash, CameraTransactionLink, ChainOfCustodyRecord | ✅ |
| Camera service | CameraRecordingService, CameraEncryptionService, CameraHashChainService, CameraExportService, CameraStorageService, CameraTransactionLinker, CameraCleanupService, CameraUploadService | ✅ |
| Darius | DariusDailyReport, DariusReportLine, DariusReportStatus, DariusReportService | ✅ |
| Denomination | Denomination, DenominationBalance, DenominationCategory, DenominationCount, DenominationType, DailyDenominationSnapshot, RoundingRule, CommissionRule | ✅ |
| AML | AmlReport, AmlReportStatus, AmlReportType, AmlRiskLevel, AmlThreshold | ✅ |
| Customer | Customer, CustomerType, CustomerRestriction, CustomerScreeningLog | ✅ |
| Approval | RateApproval, RateApprovalStatus, StornoApproval, SupervisorPinAttempt | ✅ |
| Sync | SyncOutboxEvent, SyncInboxEvent, SyncLog, FtpSyncLog, NeonSyncLog, EveningSyncLog | ✅ |
| Western Union | WesternUnionService, WesternUnionStubService | ✅ |
| Transaction | TransactionType (BUY/SELL/REVERSAL/CONVERSION/TRANSFER_OUT/IN/WU_SEND/RECEIVE/MG/VIGNETTE/PHONE_TOPUP/OTHER), ForeignStatus enum (v2.5.50+) | ✅ |
| Cashier band | CASHIER_CUSTOM_RATE_MIN_AMOUNT/DAILY_LIMIT SystemParameter (v2.5.49+) + backend enforce (PR #564) | ✅ |
| 4-installer | Penztar + Kozponti + RFM + Eltavolito mind v2.5.49 | ✅ |
| HA + failover | Hetzner primary + Scaleway warm standby + runbook + GitHub Actions workflow | ✅ |

### ✅ Frontend / Client részek

| Modul | Megvalósítva |
|---|---|
| `frontend-react` admin web | ✅ teljes |
| `penztar-client` Electron (penztar + ertektar appMode) | ✅ |
| `kozponti-client` Electron (full appMode) | ✅ |
| `arfolyam-keszito-client` Electron (rate-maker appMode) | ✅ |
| SetupWizard 5 lépés | ✅ |
| Pénztárosi sáv admin UI (Beállítások tab) | ✅ |

## GAP-ek — HIÁNYZÓ vagy RÉSZLEGES funkciók

### 🟠 Prioritás 1 (P1) — Üzleti kritikus

#### P1-A. Címletezési optimalizációs stratégiák (v2.0 spec 07_cimletkezeles.md)
**Spec:** 7 stratégia (GREEDY, DYNAMIC, MIN_COINS, MIN_BANKNOTES, MIN_TOTAL, CUSTOM, BRANCH_SPECIFIC)
**Megvalósítva:** Alap Denomination + DenominationCount entitás, de **NINCS** stratégia-választó algoritmus.
**Akció:** `DenominationOptimizationService` + `DenominationStrategy` enum + 7 implementáció + SystemParameter konfigurálható.

#### P1-B. Címletezési szabályok (v2.0 spec)
**Spec:** 8 szabálytípus (FIXED, AMOUNT_BASED, CUSTOMER_TYPE, TRANSACTION_TYPE, BRANCH_DEFAULT, TIME_BASED, AVAILABILITY, PRIORITY)
**Megvalósítva:** `RoundingRule` van, de granular denomination rule **NINCS**.
**Akció:** Új `DenominationRule` entity + admin UI + tranzakció-szintű alkalmazás.

#### P1-C. Bank API integráció
**Spec:** `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx`
**Megvalósítva:** Részleges (Darius és Western Union van), de Bank API integráció **HIÁNYZÓ**.
**Akció:** API_bank.docx dekódolása → konkrét endpoint-ok → BankIntegrationService.

### 🟡 Prioritás 2 (P2) — Fontos, de nem blokkoló

#### P2-A. MFA / Két-faktoros hitelesítés
**Spec:** A masterplan kötelezőként kéri vezetői/admin/export szerepkörökhöz.
**Megvalósítva:** Username+password + JWT, **MFA nincs**.
**Akció:** TOTP (Google Authenticator kompatibilis) + admin UI a felhasználói MFA enrollment-hez.

#### P2-B. Device certificate / mTLS device trust
**Spec:** Telephelyi kliens-szerver kommunikáció mTLS-szel.
**Megvalósítva:** `CashRegisterDevice` entitás van, de cert + mTLS nincs.
**Akció:** Per-device cert + nginx mTLS verifikáció + telepítő integráció.

#### P2-C. Hatósági export dual approval (4-eyes)
**Spec:** Videó export 2 emberi jóváhagyás után küldhető ki.
**Megvalósítva:** `CameraExportRequest` + `CameraExportStatus` van, de explicit dual approval workflow nincs (csak 1 approve).
**Akció:** ExportApproval entity + 2-szintű jóváhagyás + admin UI.

#### P2-D. VIP / törzsügyfél kedvezmény granular approval
**Spec:** SPECIAL_CUSTOMER / BUSINESS_NEED / MANAGEMENT_APPROVAL ok + CASHIER/SUPERVISOR/MANAGER/DIRECTOR szintek.
**Megvalósítva:** `discountPercent` és `RateApproval` van, de granular reason+level kombináció nincs.
**Akció:** DiscountReason enum + ApprovalLevel enum + service.

#### P2-E. Címletezési napló (denomination_transaction_log)
**Spec:** Minden címletezési döntés naplózása.
**Megvalósítva:** transaction_banknote van, de a stratégia + javasolt/elfogadott/módosított döntés **NINCS** logolva.
**Akció:** Új `DenominationTransactionLog` entity + service hook.

### 🟢 Prioritás 3 (P3) — Long-term / opcionális

#### P3-A. Mobile / PWA hozzáférés vezetőknek
**Spec:** Területi vezető dashboardok + kamera visszanézés mobile-on.
**Megvalósítva:** **NINCS** mobile-szerű UI.
**Akció:** PWA verzió a frontend-react-ből + push notification + mobile UX.

#### P3-B. Immutable audit trail (append-only DB)
**Spec:** Audit log soha ne módosítható.
**Megvalósítva:** `AuditLog` van, de DB szinten csak `@CreatedDate` van — törölhető.
**Akció:** PostgreSQL trigger NO UPDATE/DELETE + parallel append-only tábla.

#### P3-C. NAV CXC kompatibilis riport
**Spec:** NAV CXC (online számla) export.
**Megvalósítva:** NavClosingService van, de a NAV Online Számla API-val való integráció részleges.
**Akció:** NAV Online Számla API integráció (FELDERÍTVE: jelenleg NavClosingService a NAV 2007. évi CXVII. tv. zárást generálja, de Online Számla NEM).

#### P3-D. Telephelyi hardverleltár digitalizálás
**Spec:** A "Hálózati és számítógép felmérés" 37 docx (iroda-szintű hardver leltár).
**Megvalósítva:** **NINCS** digitalizálva.
**Akció:** Egyszer beolvasni docx-ekből + admin UI a hardver inventárhoz (kis prioritás).

#### P3-E. Hangfelvételek katalógus (4 db, Cégcsoport felmérése)
**Spec:** A "Cégcsoport felmérése/Hangfelvételek" — interjúk hanganyaga.
**Megvalósítva:** Csak metadata-szinten.
**Akció:** Átirat (Whisper) → markdown + QMD-be indexel.

## Új implementációs tervek (2026-05-14+ sprint)

### Sprint 1 — Címletezés v2 (P1-A + P1-B + P2-E) — ~3 nap
1. Új entity-k: `DenominationOptimization`, `DenominationRule`, `DenominationTransactionLog`
2. Új enum-ok: `OptimizationStrategy`, `DenominationRuleType`
3. Új service: `DenominationOptimizationService` + 7 stratégia implementáció
4. TransactionService integráció: stratégia kiválasztás → optimalizálás → log
5. Frontend admin UI: stratégia + szabály karbantartó
6. Teszt: minden stratégia + edge case
7. V215, V216, V217 migrációk

### Sprint 2 — Bank API integráció (P1-C) — ~2-3 nap
1. API_bank.docx beolvasás (PowerShell + docx-parser)
2. Új doc: `docs/integration/bank-api-spec.md`
3. Új service: `BankIntegrationService` + adapter
4. Új entity-k szükség szerint
5. Mock + integration teszt
6. Admin UI a bank API státusz monitoringhoz

### Sprint 3 — MFA + Device Cert (P2-A + P2-B) — ~3 nap
1. TOTP integráció (Google Authenticator)
2. MFA enrollment UI + admin
3. Új entity: `WorkerMfa`, `DeviceCertificate`
4. nginx mTLS konfig + telepítő integráció
5. Sprint 4 follow-up: per-device cert rotáció

### Sprint 4 — Hatósági export 4-eyes (P2-C) + Discount granular (P2-D) — ~2 nap
1. `ExportApproval` entity + dual approval workflow
2. `DiscountReason` + `ApprovalLevel` enum
3. Admin UI a 2 jóváhagyási folyamathoz
4. Audit trail a jóváhagyási döntésekhez

### Sprint 5 — Mobile/PWA (P3-A) — ~5 nap
1. frontend-react PWA manifest + service worker
2. Mobile-optimalizált dashboard (területi vezető)
3. Push notification a kritikus eseményekhez
4. Mobile auth flow (egyszerűsített, biometrikus)

## Elavult dokumentumok kategorizálása (hierarchikus elhelyezés)

### Visszamenőlegesen referencia, de NEM aktív implementáció:

| Mappa | Tartalom | Státusz |
|---|---|---|
| `Anti/VALUTA/` | Delphi 7 IBVALTO forrás | 🔵 HISTORIKUS — már átírva v2.5.49-re |
| `Anti/SZERVER/` | Régi szerveroldali Delphi | 🔵 HISTORIKUS |
| `Anti/ARFOLYAM/`, `KESZLEX/`, `KORLEVEL_ZIP/` | Delphi 7 modulok | 🔵 HISTORIKUS |
| `Anti/camera/`, `camera2/`, `camera3/` | Java legacy kamera | 🟡 RÉSZLEGES — az új CameraService új implementáció, de mintáknak megőrzendő |
| `Anti/firebird/` | Firebird DB-k | 🔵 HISTORIKUS |
| `Felmérés/Valuta/Cégcsoport felmérése/` | Interjúk + screenshot-ok | 🟢 AKTÍV REFERENCIA — üzleti igényfelmérés |
| `Felmérés/Valuta/Hálózati és számítógép felmérés/` | 37 iroda hardver | 🟢 AKTÍV — telepítés tervezésében |
| `Felmérés/Valuta/v2.0/Markdown/` | 2025-ös v2.0 spec | 🟢 AKTÍV — most is irányadó dokumentum |
| `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/` | API_bank.docx | 🟠 FELDOLGOZANDÓ — Sprint 2 |

### QMD indexelés átláthatósági szabály

A `valutavalto-anti-legacy` és `valutavalto-felmeres-v2` kollekciók context-jébe beírtam, hogy ezek **historikus referencia**. A jelenlegi fejlesztés a `valutavalto-vault`, `valutavalto-memory`, `valutavalto-docs`, `valutavalto-source` kollekciókat használja az aktív tudásnak.

## Implementációs prioritás-javaslat

A user "valutaváltó + központi modul + szerver" prioritása alapján, sorrendben:

1. **Sprint 1 — Címletezés v2** (P1-A + P1-B + P2-E) → valutaváltó core érintve
2. **Sprint 4 — Discount granular + Export 4-eyes** (P2-C + P2-D) → szerver + központi modul
3. **Sprint 2 — Bank API** (P1-C) → szerver integráció
4. **Sprint 3 — MFA + Device Cert** (P2-A + P2-B) → security
5. **Sprint 5 — Mobile/PWA** (P3-A) → opcionális

**Becsült teljes idő:** ~13-15 napos fejlesztés a 5 sprint-re.

## Memóriarendszer-állapot (2026-05-13 końcowy)

| Kollekció | Fájlok | Vektorok | Cél |
|---|---|---|---|
| `valutavalto-vault` | 105 | ~2000 | Aktív session-jegyzetek + runbook + procedure |
| `valutavalto-memory` | 18 | ~500 | Globális auto-memory (Claude Code) |
| `valutavalto-docs` | 253 | ~5000 | Aktív projekt-dokumentáció |
| `valutavalto-source` | 11 | ~200 | CLAUDE.md, AGENTS.md, AI_CONTRACT.md |
| `valutavalto-yaml-memory` | 29 | ~163 | Régi yaml session-jegyzetek |
| `valutavalto-anti-legacy` (ÚJ) | 227 | ~700 | Historikus referencia (Delphi + Java legacy) |
| `valutavalto-felmeres-v2` (ÚJ) | 45 | ~450 | 2025-ös v2.0 spec (irányadó) |
| **ÖSSZESEN** | **688** | **~9000** | Teljes ismeretkör indexelve |
