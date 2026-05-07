---
date: 2026-04-29
session_type: foertektar-teljes-audit
context: 33 főértéktáros menüpont production audit (excvaluta.com v2.3.12)
priority: P1 — UX bugok dokumentálása
---

# 2026-04-29 — Főértéktáros teljes menüpont-audit (33/33 elemes)

## Setup

- **URL:** https://excvaluta.com (Hetzner production v2.3.12)
- **Tool:** `mcp__Claude_in_Chrome__*` (felhasználó saját Chrome browser, auto-login cookie)
- **Mode:** `full` + `foertektar`/`ugyvezeto` role (sidebar 37 link, 33 egyedi URL)
- **Time:** 2026-04-29 20:05 → 20:25 CEST

## Audit-eredmény áttekintés

| Kategória | Db | Példa |
|---|---|---|
| ✅ Tisztán működő | **14** | /foertektar, /rate-management, /rates, /rates/creation, /audit-log, /workers, /settings, /reports, /reports/extended, /daily-turnover, /customers, /inventory (E-B11 fix), /rate-management/workflow, /mnb/reports, /dashboard |
| 🐛 Ékezet hiány | **19** | /statistics/cashier-kpi, /stock-snapshot, /vault-stocktake, /rates/history, /rates/categories, /reports/mnb, /profit, /booking-export, /police-requests, /sanction, /seal-tracking, /compliance, /employees, /attendance, /licenses, /settings/permission-matrix, /scheduler, /email-settings |
| ❌ Hiba / hiányzó funkció | 0 | (nincs) |

## Részletes bug-lista (F-B1..F-B19, mind ékezet-hiány)

### 🐛 F-B1 — `/statistics/cashier-kpi` Pénztáros KPI Dashboard
- h1: "Penztaros KPI Dashboard" → "Pénztáros KPI Dashboard"
- Oszlopok: "Penztaros / Tranzakcio / Vetel / Eladas / Sztorno / Forgalom / Atlag tx" → ékezetes
- Gombok: "Frissit / Utolso 7 nap / Ez a honap / Egyeni" → "Frissítés / Utolsó 7 nap / Ez a hónap / Egyéni"

### 🐛 F-B3 — `/stock-snapshot` Készlet pillanatkép
- h1: "Keszlet pillanatkep" → "Készlet pillanatkép"
- Oszlopok: "Keszlet / HUF ertek" → "Készlet / HUF érték"
- Gomb: "Excel letoltes" → "Excel letöltés"

### 🐛 F-B4 — `/vault-stocktake` Értéktár leltár
- h1: "Ertektar leltar" → "Értéktár leltár"
- Oszlopok: "Inditotta / Inditva / Elteres / Muvelet" → "Indította / Indítva / Eltérés / Művelet"
- Gomb: "Uj leltar" → "Új leltár"

### 🐛 F-B5 — `/rates/history` Árfolyam történelem
- h1: "Arfolyam tortenelem" → "Árfolyam történelem"
- Oszlopok: "Veteli arf. / Eladasi arf. / Ervenyes / Modositotta" → "Vételi árf. / Eladási árf. / Érvényes / Módosította"

### 🐛 F-B6 — `/rates/categories` Árfolyam kategóriák
- h1: "Arfolyam kategoriak" → "Árfolyam kategóriák"
- Oszlopok: "Nev / Leiras / Prioritas / Aktiv / Muveletek" → "Név / Leírás / Prioritás / Aktív / Műveletek"

### 🐛 F-B7 — `/reports/mnb` MNB jelentések
- h1: "MNB jelentesek" → "MNB jelentések"
- Oszlopok: "Tipus / Riport datum / Tranzakcio db / Allapot / Bekuldes" → "Típus / Riport dátum / Tranzakció db / Állapot / Beküldés"

### 🐛 F-B8 — `/profit` Haszon kimutatás
- h1: "Haszon kimutatas" → "Haszon kimutatás"
- Oszlopok: "Vetel db / Eladas db / Vetel HUF / Eladas HUF" → "Vétel db / Eladás db / Vétel HUF / Eladás HUF"

### 🐛 F-B9 — `/booking-export` Könyvelés export
- h1: "Konyveles export (CSV)" → "Könyvelés export (CSV)"
- Gombok: "Keszlet export" → "Készlet export"

### 🐛 F-B10 — `/police-requests` Rendőrségi megkeresések
- h1: "Rendorsegi megkeresesek" → "Rendőrségi megkeresések"
- Oszlopok: "Iktatoszam / Datum / Tipus / Allapot / Eloado / Muveletek" → "Iktatószám / Dátum / Típus / Állapot / Előadó / Műveletek"

### 🐛 F-B11 — `/sanction` Szankciós lista (AML)
- h1: "Szankcios Lista (AML / KYC)" → "Szankciós Lista (AML / KYC)"
- Gombok: "Allapot frissit / Szures / Listazas / Szures inditasa" → "Állapot frissítés / Szűrés / Listázás / Szűrés indítása"

### 🐛 F-B12 — `/seal-tracking` Plomba nyilvántartás
- h1: "Plomba nyilvantartas" → "Plomba nyilvántartás"
- Oszlopok: "Plomba szam / Penztar / Allapot / Felhelyezve / Eltavolitva / Muveletek" → ékezetes

### 🐛 F-B13 — `/compliance` Compliance Dashboard
- h1 OK ("Compliance Dashboard" — angol)
- Gombok: "Frissites / Frissit" → "Frissítés"

### 🐛 F-B14 — `/employees` Alkalmazottak
- h1 OK ("Alkalmazottak" — ékezetes)
- Oszlopok: "Nev / Beosztas / Penztar / Beleptetve / Aktiv / Muveletek" → "Név / Beosztás / Pénztár / Beléptetve / Aktív / Műveletek"

### 🐛 F-B15 — `/attendance` Munkaidő nyilvántartás
- h1: "Munkaido nyilvantartas" → "Munkaidő nyilvántartás"
- Oszlopok: "Bejelentkezes / Kijelentkezes / Idotartam" → ékezetes
- Gombok: "Sajat naplom / Frissit" → "Saját naplóm / Frissítés"

### 🐛 F-B16 — `/licenses` Licenc
- h1: "Licenc (aktualis)" → "Licenc (aktuális)"

### 🐛 F-B17 — `/settings/permission-matrix` Jogosultság mátrix
- h1: "Jogosultsag matrix" → "Jogosultság mátrix"
- Oszlopok: "Szerepkor" → "Szerepkör"
- Gombok: "Frissit / Nincs valtozas" → "Frissítés / Nincs változás"

### 🐛 F-B18 — `/scheduler` Ütemezések
- h1: "Utemezesek" → "Ütemezések"
- Oszlopok: "Feladat / Utemezes / Utolso futatas / Kovetkezo futatas / Aktiv / Muveletek" → ékezetes

### 🐛 F-B19 — `/email-settings` Email beállítások
- h1: "Email beallitasok" → "Email beállítások"
- Oszlopok: "Email cim / Szolgaltato / Alapertelmezett / Aktiv / Muveletek" → ékezetes

## Pozitív megerősítések (production-on élesedett v2.3.12 fix-ek)

- ✅ **E-B11 InventoryPage**: 1188 sor pénztár+valuta egyenleggel (CashBalanceDto fix élesedve!)
- ✅ **E-B7 ShipmentListPage**: h1 "Átadás-átvétel (szállítmányigények)" + "Új szállítmányigény"
- ✅ **E-B8 TransferPage**: h1 "Átadás bank / másik értéktár" + 3-soros info-banner
- ✅ **E-B6.4 window.error catcher**: production-ban is fut (test-trigger igazolta)
- ✅ **E-B15 customerApi.getActive()**: 0 customer (heurisztika eltávolítva, valódi szám)
- ✅ **E-B5 formatMillions**: "Mai forgalom: 0 Ft" (NEM "0.0M Ft")
- ✅ **E-B1 NaN guard**: "0% tegnap" (NEM "46870%")
- ✅ **E-B2 audit fallback**: "Ügyfél" oszlop `[BALI]/[BORSI]` workerCode (NEM "Rendszer Admin")
- ✅ **E-B12 Daybook 404-only retry** (PR #275)
- ✅ **react-router Link** (PR #275)

## v2.3.13 sprint javasolt scope

**Összesen 19 ékezet-bug** + **HEARTBEAT-1 logger.info → warn** + **E-B8 teljes banki workflow** = 21 ticket.

### Stratégia: 2 PR

**PR-A: Bulk ékezet-fix (19 file)** — gépelési hiba-tip, könnyen javítható, nincs üzleti logikai változás. Egy jól megírt regex-replace-szel ~30 perc alatt mind a 19 file fix-elhető. ~150 sor változás.

**PR-B: HEARTBEAT-1 + E-B8 banki workflow** — funkcionális változás, önálló sprint.

## Audit-eredmény összegzés

- **33 menüpont** vizsgálva ✓
- **14 működik tisztán** (42%)
- **19 ékezet-hiány** (58%) — UX bug, NEM funkcionális hiba
- **0 hibás funkció** (működik mind, csak ékezet-hiányos megjelenítéssel)
- **0 console error** (kritikus)
- **0 broken navigation** (mind az URL-ek elérhetők)

A v2.3.12 production-tisztaság-szintje **MAGAS**: minden funkcionális fix élesedett, csak az ékezet-policy hiányos. Ez egy egyszerű find-replace fix, nem architecture-blocker.
