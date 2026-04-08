# Legacy vs Modern — Összehasonlítás és Gap Analízis
> Dátum: 2026-04-08 02:45 | Forrás: Junior legacy + modern elemzés

---

## 1. TELJES LEFEDETTSÉGI MÁTRIX

| Legacy Modul | Legacy KB | Modern Service | Modern KB | Állapot | Gap |
|-------------|----------|----------------|----------|---------|-----|
| Adatgyűjtő (receptor) | 77 | DataCollectionService | 10 | MEGVAN | Receptor pattern nem kell (centralizált DB) |
| Forgalom összesítés | (unit29) | ConsolidatedReportService | 4 | MEGVAN | — |
| Fő szerver | 37 | ApplicationStartup | — | MEGVAN | — |
| Iroda TMK | 41 | BranchService | 14 | MEGVAN | — |
| Import | 38 | DataImportService | 7 | MEGVAN | — |
| MNB letöltő | 35 | MnbExchangeRateService | 11 | MEGVAN | — |
| Címletező | 28 | DenominationService | 20 | MEGVAN | — |
| Átlag/marge | 25 | ProfitCalculationService | 7 | MEGVAN | — |
| WU/WAFA | 20 | WesternUnionService | 26 | MEGVAN | — |
| ATADVET (átadás) | 135 | TransferService + VaultTransfer | 39 | MEGVAN | — |
| ELADAS | 134 | TransactionService.sell | 36 | MEGVAN | — |
| VASARLAS | 102 | TransactionService.buy | 36 | MEGVAN | — |
| UGYFEL | 111 | CustomerService + AmlService | 66 | MEGVAN | — |
| ESTIZAR | 91 | EveningClosingService | 26 | MEGVAN | — |
| WUNION | 89 | WesternUnionService | 26 | MEGVAN | — |
| FOGLALO | 81 | ReservationService | 30 | MEGVAN | — |
| METRO | 73 | WesternUnionService (WAFA) | — | MEGVAN | — |
| PILLKESZ | 64 | CashBalanceService + StockSnapshot | 31 | MEGVAN | — |
| Fő pénztár (IBVALTO) | 68 | frontend-react + penztar-client | 1724 | MEGVAN | — |
| Értéktár | 245 | Treasury* services | ~60 | MEGVAN | — |

---

## 2. HIÁNYZÓ/RÉSZLEGES MODULOK

| # | Terület | Legacy | Modern | Gap típus | Prioritás |
|---|---------|--------|--------|-----------|-----------|
| G1 | POS Borgun driver | Nem volt | TODO bridge | Nincs valódi driver | Ha irodákban Borgun van |
| G2 | POS Worldline driver | Nem volt | TODO bridge | Nincs valódi driver | Ha irodákban Worldline van |
| G3 | Darius transport | Nem volt legacy | Outbox stub | Tényleges külső küldés hiányzik | KÖZEPES |
| G4 | Import régi formátumok | unit5.pas | DataImportService | Régi Excel/DB formátumok importja | ALACSONY |

---

## 3. MODERN BŐVÍTÉSEK (amit a legacy NEM csinált)

| # | Modern funkció | Service | Megjegyzés |
|---|---------------|---------|------------|
| M1 | AML szankciólista | SanctionScreeningService | EU Financial Sanctions XML parser |
| M2 | Kamera evidencia | CameraExportService + 5 service | Hash-chain, encryption, Electron bridge |
| M3 | LED kijelző | LedDisplayService | Valós idejű árfolyam kijelzés |
| M4 | Email integráció | GmailApiService, EmailNotificationService | Gmail OAuth + SMTP |
| M5 | Szinkronizáció | SyncService, NeonReplicationService | Offline-first Electron sync |
| M6 | Dekád riport | DecadeReportService | 10 napos összesítés |
| M7 | Jutalék rendszer | CommissionCalculationService | Automatikus számítás |
| M8 | Seal tracking | SealTrackingService | Plomba nyilvántartás |
| M9 | NAV zárás | NavClosingService | NAV napi zárás egyeztetés |
| M10 | Backup pg_dump | BackupService | Valódi pg_dump (ma javítva!) |
| M11 | Licenc kezelés | LicenseService | Szoftver licenc validáció |
| M12 | QR kód | QrCodeService | Bizonylat QR |
| M13 | Profit kalkuláció | ProfitCalculationService | Részletes profitabilitás |

---

## 4. MAI JAVÍTÁSOK ÖSSZESÍTÉSE

| # | Javítás | Commit | Állapot |
|---|---------|--------|---------|
| F1 | Security: companyCode strict match | a92b463f | KÉSZ + DEPLOY |
| F2 | BackupService: valódi pg_dump | 35b10bc8 | KÉSZ + DEPLOY |
| F3 | VatRefund: AtomicLong sorszám | 35b10bc8 | KÉSZ + DEPLOY |
| F4 | LicenseService: tranzakció kényszerítés | 35b10bc8 | KÉSZ + DEPLOY |
| F5 | AML: magyar munkaszüneti napok | 35b10bc8 | KÉSZ + DEPLOY |
| F6 | EmailNotificationService | 526f4365 | KÉSZ + DEPLOY |
| F7 | Dashboard: tegnapi összehasonlítás | 526f4365 | KÉSZ + DEPLOY |
| F8 | EBC licenc: V142 Flyway migráció | c78ce355 | KÉSZ + DEPLOY |
| F9 | Invalid date param: 500→400 | cd5a05a1 | KÉSZ + DEPLOY |
| F10 | ESLint: unused err variable | b7419d05 | KÉSZ |
| F11 | VPS security hardening (5 feladat) | — | KÉSZ |
| F12 | Cloudflare proxy ON | — | KÉSZ |
| F13 | INS-140/141/142 szabályok | 4142af3 | KÉSZ |

---

## 5. VÉGSŐ ÉRTÉKELÉS

**Legacy lefedettség a modern rendszerben: ~95%**
- Minden fő üzleti modul implementálva (tranzakciók, zárás, WU, értéktár, riportok, címletezés, foglalás, készlet)
- A receptor pattern (irodánkénti DB) szándékosan nem portolva — centralizált DB ezt feleslegessé teszi
- 192 backend service vs legacy ~30 DLL/unit — a modern rendszer finomabb granuláltságú

**Tényleges gap: 4 pont (G1-G4)** — ezek közül G1-G2 csak akkor releváns ha Borgun/Worldline terminál van az irodákban.

**A rendszer production-ready állapotban van.**
