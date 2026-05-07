---
name: Pénztár regisztrálás + offline/online mód különválasztása
description: Penztar-client telepítés első dolga a szerver-regisztráció; offline módban a SyncEngine nem spamelhet
type: feedback
---

# Szabály
A penztar-client telepítés időben **online módban kell**, hogy regisztrálja a pénztárat
a szerveren. Később, ha offline módba kerül (vagy azon marad), a SyncEngine NE
próbáljon tranzakciókat uploadolni — ez HTTP 400 / Network Error spam-et okoz a logban.

**Why:** A pénztárak forgalmait + bizonylatait a szerver adatbázisban kell nyilvántartani
(ERP követelmény — iroda szintű összesítő jelentések, NGM compliance, AML audit).
Ha a pénztár nem létezik a szerveren, a tranzakció-uploadok mind elhasalnak. A
SetupWizard-nak online regisztrációt kell végeznie, különben az eszköz "orphan"
(se szerver nem tud róla, se nem tudja pótolni a hiányzó referenciákat).

**How to apply:**
- SetupWizard első lépése az online regisztráció legyen (branch, cash register, szerver URL)
- Sikertelen regisztráció → FIGYELMEZTETŐ üzenet, ne engedjen tovább offline-csak módba ha "full" telepítést kér
- Az offline mód csak **későbbi** állapot — a regisztráció UTÁN
- A SyncEngine olvassa a SQLite config-ot: ha `app_mode=offline` vagy `server_url=null`
  → ne indítson sync ciklust
- A backend cash_register táblája tárolja: branch_id, cashier_worker_id, installed_at,
  last_seen_at, app_version, device_fingerprint