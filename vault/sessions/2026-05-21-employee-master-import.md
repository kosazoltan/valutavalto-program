---
date: 2026-05-21
type: session
tags: [employee-master, hr-torzs, dolgozoi-torzs, pii-safe, hetzner, worker-link]
---

# 2026-05-21 — Dolgozói törzs (employee) HR-import Hetznerre

## Kontextus
A "ki mit csinál" vita (Borsi/Bali szerepkör/hozzáférés) kapcsán kiderült: a `worker`
tábla csak login/RBAC, a tényleges **munkakör** a hivatalos személyi-adat Excelben van.
A user átadta a teljes törzs Excelt (`Másolat - Személyi adatok összes 2026.01.14 - EBC
Zrt.xls`, 207 sor × 75 oszlop) és kérte a `employee` HR-tábla feltöltését + worker-linket,
**érzékeny adat nélkül**.

## Mit csináltunk
- **Direktíva:** a program szándékosan NEM kezel érzékeny PII-t. KIMARAD: TAJ, adóazonosító,
  anyja neve, születési hely/dátum, szig.szám, lakcímek, bankszámla, SZÉP, bér, kedvezmények.
  BEKERÜL: név, szervezeti egység (munkahely), FEOR, munkakör, jogviszony-dátumok, is_active.
- **Tooling (repóban, PII-mentes):** `scripts/import-employees/generate_employee_import.py`
  + README. A generált SQL + worker-export **gitignore-olt** (nevet tartalmaz).
- **Import Hetznerre (root SSH + psql, tranzakcionálisan):** 196 dolgozó, **193 worker-linkelt**
  (név-egyezés + Bali alias), 3 linkeletlen (Varga Viktória, Szabóné Mihály Babett, Virág Éva —
  nincs aktív worker-fiók). A temp SQL `shred`-elve a szerverről.
- A `employee` tábla érzékeny oszlopai NULL-ok maradnak (sosem töltjük).

## Hiteles munkakörök (a vitát lezárja)
- **Borsi Tamás → Főértéktáros** (Szeged, BORSI)
- **Kasza Helga → Főértéktáros** (Szeged, KASZA) — ő küldte az FK-kéréseket
- **Bali (Borossebesiné Bali Henriett Anita) → Értéktáros** (Szeged, BALI) — NEM
  "főértéktárhelyettes", ahogy a migráció-kommentek állították
- **Kósa Zoltán → ügyvezető igazgató** (Iroda, KOSA)
- Eloszlás: Valutapénztáros 128, Értékszállító 22, Értéktáros 10, Hivatalsegéd 4,
  Területi vezető 3, Főértéktáros 2. 8 terület + Iroda.

## Tanulság / nyitott
- **A worker-szerepkörből (V228 7-role) levont munkakör félrevezető volt.** A hiteles forrás
  az employee.job_title. Bali tényleges munkaköre Értéktáros — a V228 over-provisioning
  (foertektar+ugyvezeto a BALI-n) NEM egyezik a tényleges munkakörrel. Ha a hozzáférést a
  munkakörhöz akarjuk igazítani, ezt külön kell rendezni (üzleti döntés: a user korábban
  jelezte, hogy Bali mindhárom modulhoz férjen — ez ELLENTÉTBEN áll az Értéktáros munkakörrel).
- **Séma-drift:** V53 migráció `active` oszlop, prod `is_active`. Külön rendezendő.
- **Reprodukálhatóság:** az employee-adat NINCS migrációban (PII-kerülés) → DB-újraépítéskor
  a generátort újra kell futtatni (README dokumentálja).
- Commit: `e8999e271` (tooling). Adat: csak Hetzner prod (gitben nincs).
