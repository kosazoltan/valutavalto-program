---
title: "Stratégiai fejlesztési terv — legacy parity végrehajtás v2.5.64+"
created: 2026-05-19
implementation_version: v2.5.64
source_docs:
  - docs/LEGACY-FULL-AUDIT.md (243 modul audit, 2026-03-05)
  - docs/LEGACY_PARITY_EVIDENCE_MATRIX.md (parity bizonyítékok, 2026-04-17)
  - docs/LEGACY_PARITY_P1_ACTION_PLAN.md (8 P1 task, 2026-03-15)
  - vault/references/source-vs-implementation-gap-analysis-20260513.md
  - Anti/ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md
  - Anti/antivaluta.md
  - Felmérés/Valuta/v2.0/Markdown/ (45 fájl, 2025-04→2025-05)
  - Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx
parity_aktualizalas:
  weighted_2026_03_15: 81.5%
  becsult_2026_05_19: ~88% (Sprint 1 + 3 + V234 immutable audit + DiscountReason kész)
---

# Stratégiai fejlesztési terv — v2.5.64 → "kész állapot"

## 1. Frissített állapot összevetés (v2.5.64-re aktualizált)

A 2026-05-13-i gap analysis óta **mergelve** a következő legacy-parity feature-ök:

| Sprint a 2026-05-13 tervből | Státusz v2.5.64-ben | Bizonyíték |
|---|---|---|
| Sprint 1 — Címletezés v2 (P1-A, P1-B, P2-E) | ⚠️ ENTITY KÉSZ, stratégia enum hiányzik | `DenominationOptimization*` (4 fájl) — de csak 1 stratégia (GREEDY?) említve |
| Sprint 2 — Bank API (P1-C) | ❌ NEM KEZDŐDÖTT | csak `BankIntegrationStatusController` (read-only status) |
| Sprint 3 — MFA + Device Cert (P2-A, P2-B) | ✅ MFA KÉSZ; ❌ Device cert nem | `WorkerMfa`, `TotpService`, `MfaController` jelen — mTLS hiányzik |
| Sprint 4 — Export 4-eyes (P2-C) + Discount granular (P2-D) | ⚠️ DiscountReason + ApprovalLevel ENTITY kész; ❌ ExportApproval hiányzik | `DiscountReason.java`, `ApprovalLevel.java` |
| Sprint 5 — Mobile/PWA (P3-A) | ✅ MANIFEST + SW KÉSZ | `manifest.webmanifest`, `service-worker.js` |
| Plus 2026-05-18 V234 audit log immutable hash chain | ✅ KÉSZ | `V234__audit_log_immutable_hash_chain.sql` |

**Becsült parity-ugrás:** 81.5% (2026-03-15) → **~88%** (2026-05-19, v2.5.64).

## 2. A maradék hiányok — strukturált terv

### 🔴 P0 — Production-blocking / üzleti működésre kritikus

#### P0.1 — Címletezés v2 BEFEJEZÉS (Sprint 1 close-out)
**Mi van:** `DenominationOptimization` entity + service + controller létezik, de a 7 stratégia (GREEDY, DYNAMIC, MIN_COINS, MIN_BANKNOTES, MIN_TOTAL, CUSTOM, BRANCH_SPECIFIC) közül csak 1 implementált.
**Mi kell:**
1. `OptimizationStrategy` enum 7 értékkel
2. `DenominationOptimizationService.optimize(strategy, amount)` 7 ágával
3. `DenominationRule` entity (8 típus: FIXED, AMOUNT_BASED, CUSTOMER_TYPE, TRANSACTION_TYPE, BRANCH_DEFAULT, TIME_BASED, AVAILABILITY, PRIORITY) + admin UI
4. `DenominationTransactionLog` entity + service hook (P2-E)
5. TransactionService integráció: optimize hook a vétel/eladás után
6. Flyway V241, V242, V243

**Becsült idő:** 2-3 nap. **Forrás:** `Felmérés/Valuta/v2.0/Markdown/valuta_folyamatok/07_cimletkezeles.md`.

#### P0.2 — NAV integráció valódi adapter (P1-06 from 2026-03-15)
**Mi van:** `NavIntegrationService` placeholder/mock, NavClosingService a 2007. évi CXVII. tv. zárást generál.
**Mi kell:**
1. **Üzleti döntés** (Kósa Zoltán): kötelező-e a NAV Online Számla API integráció?
   - Ha IGEN: új `NavOnlineSzlaService` + valódi ÁNYK XML export + szervlet
   - Ha NEM: formális N/A döntés a vault-ban → P1-06 lezárva
2. NAV pénztárgép integráció (NAVZARO legacy modul, 25K, 53f) — döntés ugyanaz
3. Compliance rögzítés a `vault/feedback/`-ban

**Becsült idő:** 1 nap döntés + 3-5 nap implementáció (ha IGEN).

#### P0.3 — `companyId` formalis multi-tenant audit (P1-07)
**Mi van:** `@PreAuthorize` 100% (124/124 controller), de companyId-szűrés formális reportja open.
**Mi kell:**
1. Scriptelt audit: minden Repository query-ben `WHERE company_id = ?`
2. Riport export (`docs/companyId-coverage-2026-05-19.md`)
3. Hiányok javítása (ha van)
4. Test: cross-tenant access → 403

**Becsült idő:** 1 nap. **Forrás:** CLAUDE.md B.3 P0 (multi-tenant isolation).

---

### 🟠 P1 — Riport-parity + UAT bizonyítékok

#### P1.1 — Dekád riport tartalmi parity UAT (P1-04)
**Mi van:** `DecadeReportController` + `DecadeReportService` kód kész, endpoint működik.
**Mi kell:** UAT — 3 dekád (1-10, 11-20, hó vége), legacy KESZLEX riport-mintával összevetés:
- Időszakhatárok
- Tranzakciószám
- Összegek (HUF, deviza-bontás)
- Formátum (header, footer, oszlopok)

**Becsült idő:** 2 nap (legacy mintaadat-gyűjtés + futtatás + diff).

#### P1.2 — Foglaló keszlet-elkulonites UAT (P1-05)
**Mi van:** `ReservationService` + `ReservationStatus` enum (FULFILLED, CANCELLED_BY_CUSTOMER, CANCELLED_BY_COMPANY) ✓.
**Mi kell:**
1. UAT: foglaló-leadás → keszlet elkülönítés → fulfillment vagy lejárat
2. Edge case: részleges teljesítés
3. Visszafizetés `_visszatipus` 1/2/3 logika
4. Lejárati cron job verifikáció

**Becsült idő:** 1-2 nap.

#### P1.3 — Treasury 3-szintű parity UAT (P1-01, P1-02)
**Mi van:** `TreasuryDashboardService.getCompanyAggregation` + `getBranchGroupAggregation` kód kész, controller endpoint van.
**Mi kell:** UAT — Branch / BranchGroup (körzet) / Company (KFT) szinten ugyanazon adat 3 nézettel ugyanazon végösszeggel.
**Forrás:** Legacy `KeszletKorzetSummazas`, `KeszletKftSummazas`, `KeszletCegSummazas`.

**Becsült idő:** 1 nap.

#### P1.4 — Bizonylat fizikai nyomtatás (legacy COM-port → ESC/POS)
**Mi van:** `Receipt` entity + `EscPosReceiptService` (v2.5.60), `ReceiptPdfService`. Penztar-client `electron-pos-printer` dependency.
**Mi kell:**
1. ESC/POS commands végigtesztelve a 3 leggyakoribb thermal printer-rel (Star TSP100, Epson TM-T20, Bixolon SRP-350)
2. Helyi cikltesztek (vétel/eladás/storno/konverzió 4 bizonylat-típus)
3. PDF fallback validáció (nyomtató nincs → A4 PDF)

**Becsült idő:** 2 nap (hardver + manual teszt).

---

### 🟡 P2 — Fontos, de nem blokkoló

#### P2.1 — Bank API integráció (Sprint 2 close-out)
**Mi van:** Csak `BankIntegrationStatusController` (read-only). `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx` még FELDOLGOZANDÓ státuszban.
**Mi kell:**
1. **API_bank.docx beolvasás** + `docs/integration/bank-api-spec.md` generálás
2. Adapter-pattern: `BankIntegrationService` + bank-specifikus adapter-ok
3. Új entity-k: `BankApiCredential` (encrypted), `BankApiTransaction`
4. Mock + integration teszt
5. Admin UI bank-státusz monitoringhoz

**Becsült idő:** 3 nap (docx beolvasás + spec + adapter + teszt).

#### P2.2 — ExportApproval 4-eyes dual approval (Sprint 4 part C)
**Mi van:** `CameraExportRequest` + `CameraExportStatus` jelen, de explicit dual approval workflow hiányzik.
**Mi kell:**
1. Új `ExportApproval` entity: `requestId`, `approver1Id`, `approver2Id`, `approver1Timestamp`, `approver2Timestamp`, status
2. Service: dual approval gate (mindkét approver kell, különböző worker)
3. Admin UI: lista a pending export request-eknek + approve gomb
4. Audit-log minden approval-action-höz (V234 hash chain)

**Becsült idő:** 2 nap.

#### P2.3 — Discount granular workflow (Sprint 4 part D — befejezés)
**Mi van:** `DiscountReason` + `ApprovalLevel` entity LÉTEZIK.
**Mi kell:**
1. Service: `RateApprovalService` bővítés `discountReason` + `approvalLevel` kombinációkkal
2. Workflow: CASHIER szinthez auto-approve, SUPERVISOR/MANAGER/DIRECTOR szinthez kötelező jóváhagyás
3. Frontend: VIP discount dialog 3 lépéses (ok → szint → indoklás)
4. Riport: ki-mikor-mennyit discount-olt

**Becsült idő:** 1-2 nap.

#### P2.4 — Napkönyv PDF generálás (legacy NAPKONYV 33K, 65f)
**Mi van:** Receipt entity van, de napi forgalom összesítő nyomtatható formátum HIÁNYZIK.
**Mi kell:**
1. Új `DailyJournalService.generatePdf(date, branchId)` (`PDFBox` vagy `iText`)
2. Tartalom: nyitó-záró, bevétel, kiadás, jutalék, dekád-link, AML események
3. PDF cron a napzárás után
4. Email küldés főértéktárosnak (opcionális)

**Becsült idő:** 2 nap.

#### P2.5 — Átlag árfolyam riport (legacy ATLAGARF 46K, 71f)
**Mi van:** NEM IMPLEMENTÁLT (ReportService general purpose, de átlag-árfolyam endpoint nincs).
**Mi kell:**
1. Új `AverageRateReportService` — időszak + iroda + valuta szerint súlyozott átlag
2. Súlyozási logika: tranzakciók forintösszege szerinti súly
3. Endpoint: `GET /reports/average-rate?from=YYYY-MM-DD&to=YYYY-MM-DD&branchId=...&currency=...`
4. Frontend riport-oldal

**Becsült idő:** 1-2 nap.

#### P2.6 — Device cert / mTLS (Sprint 3 part B)
**Mi van:** `CashRegisterDevice` entity LÉTEZIK, de cert + mTLS hiányzik.
**Mi kell:**
1. Per-device X.509 cert generálás SetupWizard-ben (egyszer)
2. nginx mTLS verifikáció a backend előtt (`ssl_client_certificate`)
3. Backend: cert-hash → worker mapping (revocation lista)
4. Telepítő integráció (cert install Windows cert store)

**Becsült idő:** 3 nap (Windows cert store + nginx + backend).

---

### 🟢 P3 — Long-term / nice-to-have

#### P3.1 — NAV CXC kompatibilis riport (P0.2 alternatívája ha "kötelező")
Lásd P0.2 (NAV decision).

#### P3.2 — Hardware inventory digitalizálás (37 docx)
**Forrás:** `Felmérés/Valuta/Hálózati és számítógép felmérés/` (37 iroda).
**Akció:** PowerShell + docx-parser → struktúrált JSON → új `HardwareInventory` entity + admin UI.
**Becsült idő:** 2 nap.

#### P3.3 — Időszakos ügyfél monitoring (legacy ugyfelcontrol/idoszakos 34K)
**Akció:** Cron job ami havonta összevet — visszatérő ügyfelek listája + flag-elés ha gyakoribb mint X.

**Becsült idő:** 1 nap.

#### P3.4 — Tiltólista import (legacy ugyfelcontrol/tiltasok 79K, 174f)
**Mi van:** `BlacklistService` van (token-blacklist). Customer-blacklist hiányzik.
**Akció:** Új `CustomerBlacklist` entity + import-script (CSV/legacy DB) + screening hook a tranzakció előtt.

**Becsült idő:** 2 nap.

#### P3.5 — Terror/szankciós lista periodikus frissítés
**Mi van:** `SanctionListScheduler` LÉTEZIK + `SanctionScreeningController`.
**Akció:** Verify — OFAC SDN list napi update OK? UN/EU sanctions API él? Logot ellenőrizni.

**Becsült idő:** 0.5 nap (verify).

#### P3.6 — QR kód bővítés (legacy QRDEPUTY 25K, QRGENER 22K)
**Mi van:** `QrCodeService` alapok.
**Akció:** Bizonylat QR-kód (tranz. azonosító) + ügyfél-azonosító QR (Pmt. AML auto-fill).

**Becsült idő:** 1 nap.

#### P3.7 — Hangfelvételek katalógus (4 db, Cégcsoport felmérése)
**Akció:** Whisper átirat → markdown → QMD kollekcióba.
**Becsült idő:** 0.5 nap.

---

## 3. Sprint javaslat (prioritás + sorrend)

Az alábbi sprint-sorrend a **P0 → P1 → P2** prioritás + **legkisebb függőség** alapján:

### Sprint A — P0 close-out (3-5 nap)
1. **P0.1** Címletezés v2 befejezés (2-3 nap) — *core funkcionalitás, transaction flow érintve*
2. **P0.3** companyId audit (1 nap) — *security, gyors win*
3. **P0.2** NAV döntés (1 nap) — *üzleti döntés Kósa Zoltántól, KÖTELEZŐ vagy formális N/A*

### Sprint B — P1 UAT batch (4-5 nap)
4. **P1.1** Dekád riport parity UAT (2 nap)
5. **P1.2** Foglaló UAT (1-2 nap)
6. **P1.3** Treasury 3-szintű UAT (1 nap)
7. **P1.4** Bizonylat fizikai nyomtatás teszt (2 nap, párhuzamosan a többivel)

### Sprint C — P2 feature drop (5-7 nap)
8. **P2.1** Bank API integráció (3 nap) — *API_bank.docx beolvasás után*
9. **P2.2** ExportApproval 4-eyes (2 nap)
10. **P2.3** Discount granular workflow (1-2 nap) — *entities már megvannak*
11. **P2.4** Napkönyv PDF (2 nap)
12. **P2.5** Átlag árfolyam riport (1-2 nap)
13. **P2.6** Device cert / mTLS (3 nap) — *security, infrastruktúra-igényes*

### Sprint D — P3 long-tail (3-5 nap)
14. **P3.2** Hardware inventory (2 nap)
15. **P3.3** Időszakos ügyfél (1 nap)
16. **P3.4** Tiltólista import (2 nap)
17. **P3.5–P3.7** verify + QR + hang-katalógus (~2 nap összesen)

**Becsült teljes idő:** 15-22 nap fókuszált fejlesztés (egyedül). Párhuzamosítva (frontend + backend külön ügynök) 10-14 nap.

---

## 4. Definíció a "kész állapotra"

A program **akkor mondható késznek**, ha:

1. ✅ Mind a 6 P1 parity-bizonyíték (LEGACY_PARITY_EVIDENCE_MATRIX.md §4) lezárva
2. ✅ LEGACY_PARITY_EXEC_STATUS.md = **GO** (nem `CONDITIONAL GO`)
3. ✅ Weighted parity ≥ 95% (jelenleg ~88%)
4. ✅ NAV-döntés rögzítve (vagy implementálva, vagy formális N/A)
5. ✅ 4 telepítő SIGNED (DigiCert EV CS cert kiadása után)
6. ✅ Production-on 3 hónap rendszeres használat 0 P0/P1 bug-gal
7. ✅ Helga könyvelés / Western Union / Metro/Tesco/OTP NEM kell (deprecated, formális)
8. ✅ User-acceptance test 8 értéktár + 66 pénztáros iroda mind a 3 mode-ban (Penztar, Kozponti, Arfolyamkeszito)

---

## 5. Kockázatok és figyelemfelhívások

1. **NAV integráció üzleti döntés** — ha kötelező, +3-5 nap.
2. **Hardver E2E** — nyomtató, NAV pénztárgép, kamera, POS — fizikai eszközhozzáférés szükséges.
3. **API_bank.docx tartalom** — még nem dekódolt; lehet hogy a Bank API spec külső entitást és credential-kezelést igényel.
4. **Cégkivonat / DigiCert phone callback** — 3-5 nap pending; SIGNED build csak utána.
5. **Sourcery weekly rate-limit** — folyamatos hatás, nem blokkoló.

---

## 6. Mit ELÉG ETÁPI BEN nem csinálni

A `LEGACY-FULL-AUDIT.md` 38 db "N/A" modult azonosított — **formális deprecated lista**:

- Western Union (4 modul) — partnerség megszűnt
- Metro/Tesco/OTP (6 modul) — áruházi pénzváltók
- Helga könyvelés (9 modul) — külön rendszer
- FNYUJSAG (15 variáns) — pénztár-specifikus árfolyam táblák
- COPY2FTP — FTP másolás (REST API kiváltja)
- GEPSETUP / VERZFRIS — hardver setup / verzió frissítés (telepítő kiváltja)
- pk fájlok, MATREGEN — bináris Firebird → PostgreSQL átállás

Mind a 38 modulra megvan a "WHY NOT" indoklás a LEGACY-FULL-AUDIT.md-ben.

---

## 7. Következő konkrét akció (mai dönthető)

**Választás Kósa Zoltántól:**

A) **P0.1 Címletezés v2 befejezés** (most azonnal kezdek — 2-3 nap autonomous mode)
B) **P0.2 NAV döntés** — kötelező vagy N/A? (1 mondat válasz elég)
C) **Sprint A teljes egyben** (P0.1 + P0.3 + P0.2 ha N/A; 3-5 nap autonomous)
D) **API_bank.docx beolvasás** (Sprint C előkészítése, 1 nap)
E) **Saját választás** — másik prioritás

A javaslatom: **C) Sprint A teljes egyben**, mert ezzel a P0 → P1 átmenet teljes lesz, és utána a Sprint B (UAT batch) önállóan futtatható.
