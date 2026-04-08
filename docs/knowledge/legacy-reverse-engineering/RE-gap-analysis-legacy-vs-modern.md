---
type: analysis
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Gap Analysis — Legacy vs Modern Implementacio"
load: on-demand
---

# Gap Analysis — Legacy vs Modern Implementáció

> **Dátum:** 2026-04-05
> **Cél:** Megtalálni, ami a legacy elemzésekben van, de a modern rendszerből hiányzik


---

## S1 IMPLEMENTALT_MODERN_RENDSZERBEN_MEGVAN

| Legacy terület | Modern implementáció | Sprint |
|---|---|---|
| Devizavásárlás/eladás | TransactionService + SellBuy UI | Sprint 1-2 |
| Árfolyam-kezelés (ARFVALT) | RateService + Rate UI | Sprint 1 |
| Sztornó (STORNO) | TransactionService.reverse() | Sprint 2 |
| Napzárás (NAPZAR) | DailyClosingService | Sprint 3 |
| Havi zárás (HAVIZAR) | MonthlyClosingService | Sprint 4 |
| Év-nyitó (EVNYITO/NEWYEAR) | YearOpeningService | Sprint 5 C4 |
| Címletkezelés (CIMLET) | BanknoteBreakdown UI + backend | Sprint 3 |
| Készletkezelés (PTARKESZ) | BanknoteInventory backend | Sprint 3 |
| Ügyfél-azonosítás (UGYFEL) | CustomerService + KYC flow | Sprint 2 |
| AML/terror szűrés (TERROR) | AmlService + screening | Sprint 2 |
| AML bejelentés + OVERDUE | AmlService + deadline scheduler | Sprint 5 C5 |
| Bizonylat nyomtatás (BLOKNYOM) | ReceiptPrintService + ElectronPrint | Sprint 3 |
| Pénztáros belépés (PROSBE) | AuthService + JWT | Sprint 1 |
| Supervisor auth (SUPER) | Role-based @PreAuthorize | Sprint 1 |
| Körlevél (KORLEV) | CircularService | Sprint 4 |
| Átadólap (ATADOLAP) | TransferService | Sprint 2 |
| Audit log | AuditLogService | Sprint 1 |
| Napi könyv (NAPKONYV) | (riport alapok) | Sprint 3 |
| Kezelési díj (KEZDIJ) | HandlingFeeService | Sprint 4 |


---

## S2 HIANYZIK_LEGACY_BEN_VAN_MODERN_RENDSZERBOL_KIMARADT

### P0 — Kritikus (jogszabályi/üzleti kötelező)

| # | Legacy funkció | Legacy modul | Miért kritikus |
|---|---|---|---|
| G1 | **Foglalás rendszer** | FOGLALO.dll, FOGLREND.dll | Ügyfél devizafoglalás, kifizetés, visszafizetés — aktív üzleti funkció |
| G2 | **NAV zárás / hatósági jelentés** | NAVZARO.dll | Törvényi kötelezettség — adóhatósági export |
| G3 | **Közszereplő (PEP) nyilatkozat** | KozszerepNyilatkozat (BLOKNYOM) | 300k+ tranzakciónál jogszabályi kötelezettség |
| G4 | **Jogcím nyilatkozat** nyomtatás | Jogcimnyilatkozat (BLOKNYOM) | Jogszabályi bizonylat |
| G5 | **Dekádzárás** | DEKRUTIN.dll | 10 napos időszaki zárás — lehet, hogy már nem kötelező, de a legacy csinálja |

### P1 — Fontos (üzleti funkció)

| # | Legacy funkció | Legacy modul | Megjegyzés |
|---|---|---|---|
| G6 | **Western Union integráció** | WUNION.dll | Kérdés: a modern rendszer is támogatja-e a WU-t? |
| G7 | **OTP POS terminál** | OTP.dll, OTPLOG.dll | Bankkártya-elfogadás POS-on — ha az irodákban kell |
| G8 | **FTP szinkronizáció** (központi szerver) | COPY2FTP.dll | Modern: REST API helyettesíti? Ellenőrizni |
| G9 | **Verziófrissítés** (auto-update) | VERZFRIS.dll | Electron auto-update a modern megfelelő |
| G10 | **Napi mentés** (DB backup) | MENTES.dll | Hetzner backup? Helyi gép backup? |
| G11 | **Napi forgalom összesítő** | NAPIFORG.dll, MAIFORG.dll | Lehet, hogy a riport modul lefedi |
| G12 | **Bizonylat keresés/megjelenítés** | BIZODISP.dll | Archivált bizonylatok keresése |

### P2 — Alacsony prioritás / elavult

| # | Legacy funkció | Legacy modul | Megjegyzés |
|---|---|---|---|
| G13 | Telefon feltöltés | TELEFONFORM (TRADE EXE) | Valószínűleg már nem releváns |
| G14 | Autópálya e-matrica | AUTOPALYAFORM (TRADE EXE) | Valószínűleg már nem releváns |
| G15 | CitySim SIM kártya | SQL séma | Valószínűleg már nem releváns |
| G16 | HRK (horvát kuna) modulok | HRKATADO, HRKZARO | HRK→EUR konverzió lezárult |
| G17 | QR kód generátor | QRGENER, QRDEPUTY | Specifikus használat, lehet hogy kell |
| G18 | Log XOR kódolás | LOGIRO, LOGDISP | Már nincs szükség — modern audit log |
| G19 | Matrica pénztár/regeneráló | MATPTAR, MATREGEN | Elavult |


---

## S3 GABOR_UIUX_JAVASLATAI_IMPLEMENTALANDOK

| # | Javaslat | Prioritás | Megjegyzés |
|---|---|---|---|
| U1 | **Keyboard-first navigáció** (End/Escape/Tab/Enter) | P0 | Részben kész (Sprint 5 BACKLOG-001/002) |
| U2 | **Design token rendszer** (Inter font, egységes színek) | P1 | Gábor terve kész |
| U3 | **Offline-first architektúra** | P1 | IndexedDB + szinkronizáció |
| U4 | **VFD ügyfélkijelző** (customer display) | P2 | Electron second window |
| U5 | **Supervisor PIN-kód** (jelszó helyett) | P2 | Modern UX javaslat |
| U6 | **Bizonylat HTML→ESC/POS** hibrid nyomtatás | P1 | Template alapú |


---

## S4 ESZTER_KODMINOSEGI_MEGALLAPITASOK_ELLENORIZNI

| # | Legacy probléma | Modern állapot | Szükséges |
|---|---|---|---|
| Q1 | SQL injection (chr(39) + string concat) | ✅ JPQL paraméteres query | OK |
| Q2 | Hardcoded FTP credentials | ✅ Environment config | OK |
| Q3 | XOR "titkosítás" | ✅ Standard kriptográfia | OK |
| Q4 | Magic number-ök (pénztárszám < 151) | ⚠️ Ellenőrizni | Lehet, hogy van hasonló |
| Q5 | Globális állapot (VTEMP tábla) | ✅ Stateless REST | OK |


---

## S5 TAMAS_TESZTELHETOSEGI_JAVASLATAI

| # | Javaslat | Állapot |
|---|---|---|
| T1 | DLL interface contract tesztek → API contract tesztek | ✅ Unit tesztek (886 db) |
| T2 | Integration tesztek DB-vel | ✅ Repository tesztek |
| T3 | E2E workflow tesztek | ⚠️ Részleges (Playwright) |
| T4 | Performance tesztek (napi/havi zárás) | ❌ Hiányzik |
| T5 | Bizonylat-nyomtatás vizuális regresszió | ❌ Hiányzik |

---


---

## S6 STATUSZ_2026_04_05_FRISSITVE

**MINDEN P0 és P1 gap IMPLEMENTÁLVA:**

| Gap | Funkció | Állapot | Megjegyzés |
|-----|---------|---------|------------|
| G1 | Foglalás rendszer | ✅ KÉSZ | `ReservationController` + `ReservationService` |
| G2 | NAV zárás | ✅ KÉSZ | `NavClosingService` + `NavReportService` + `NavAbevXmlGenerator` |
| G3 | PEP nyilatkozat | ✅ KÉSZ | Commit `2e47d562` — deploy 2026-04-05 |
| G4 | Jogcím nyilatkozat | ✅ KÉSZ | Commit `2e47d562` — deploy 2026-04-05 |
| G5 | Dekádzárás | ✅ KÉSZ | `DecadeReportService` + `DecadeReportPage` |
| G6 | Western Union | ✅ KÉSZ | `WesternUnionController` + `WesternUnionService` |
| G7 | OTP POS terminál | ✅ KÉSZ | `PosTerminalController` + `PosTerminalService` |

**P2 (elavult) gap-ek:** G13-G19 — nem releváns (telefon feltöltés, autópálya matrica, HRK konverzió stb.)
