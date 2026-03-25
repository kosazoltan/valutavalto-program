# PRD: Neon-központú Szinkronizáció Architektúra

**Dátum:** 2026-03-24
**Szerző:** Junior (koordinátor)
**Státusz:** DRAFT — Zoltán jóváhagyására vár

---

## 1. Célok

A Neon (PostgreSQL) közös adatbázisra való átállás **radikálisan egyszerűsíti** a szinkronizációt:
- Minden fiók (branch) ugyanazt a DB-t használja → nincs szükség FTP/file-alapú adatcserére
- Az árfolyamok, pénztáros törzsadatok, valuta törzsek **azonnal** elérhetők mindenhol
- A legacy pk-file és FTP-szinkronizáció **kiváltható** egyszerű DB-írás + WebSocket push-sal

## 2. Scope

### ✅ Benne van (Must Have)
1. **Árfolyam publikálás** → DB-be ír + WebSocket push az Electron klienseknek
2. **Pénztáros (Worker) törzsadatok** → központi CRUD, real-time elérés
3. **Pénztár (Branch) törzsadatok** → központi CRUD
4. **Valuta (Currency) törzsadatok** → központi CRUD
5. **Készlet-szinkronizáció** → `InventorySummary` materialized nézet, Neon-ból közvetlenül

### ⛔ Nem cél (Out of Scope)
- Legacy FTP kompatibilitás megtartása (deprecated, kiváltjuk)
- Multi-DB replikáció (nem kell, 1 Neon DB = single source of truth)
- Offline mód (későbbi fázis, ha igény lesz rá)

## 3. Jelenlegi állapot (As-Is)

### Legacy (Delphi 7)
```
Szerver ←→ FTP (pk file-ok, 737 byte/iroda) ←→ Pénztár kliensek
         Firebird DB-k (irodánként külön)
```

### Jelenlegi új rendszer
```
Spring Boot backend (Neon DB)
  ├── SyncOutboxEvent → OutboxSyncWorkerService (scheduled, 5s polling)
  ├── SyncInboxEvent (idempotens fogadás)
  ├── FtpSyncService (bridge: FTP formátumú fájlok → REST artifact)
  ├── SyncService (branch-szintű szinkronizáció: rates/transactions/inventory)
  └── WebSocket (SimpMessagingTemplate → RATE_PUBLISHED broadcast)
```

**Probléma:** Az Outbox/Inbox minta és az FtpSyncService **felesleges komplexitás**, ha minden branch ugyanazt a Neon DB-t használja.

## 4. Célállapot (To-Be)

### Architektúra
```
┌──────────────────────────────────────────────────────────┐
│                    Neon PostgreSQL                        │
│  (Single Source of Truth — ep-polished-morning)           │
│                                                          │
│  exchange_rate  ─┬─ branch_id (opcionális, NULL=globális) │
│  worker         ─┤─ company_id (multi-tenant)            │
│  branch         ─┤─ company_id                           │
│  currency       ─┘                                       │
│  inventory_summary ── branch × currency mátrix           │
└───────────────────────────┬──────────────────────────────┘
                            │ JDBC (HikariCP)
┌───────────────────────────┴──────────────────────────────┐
│              Spring Boot Backend (Render)                  │
│                                                          │
│  RatePublishService ──→ DB write + WebSocket broadcast   │
│  WorkerService ──→ CRUD (azonnali, nincs sync)           │
│  BranchService ──→ CRUD (azonnali, nincs sync)           │
│  InventorySummaryService ──→ materialized view refresh   │
└───────────────────────────┬──────────────────────────────┘
                            │ WebSocket (STOMP)
┌───────────────────────────┴──────────────────────────────┐
│         Electron kliensek (pénztárak)                     │
│                                                          │
│  /topic/rates ──→ árfolyam frissítés (real-time)         │
│  /topic/workers ──→ pénztáros változás                   │
│  /topic/branches ──→ fiók változás                       │
│  REST API polling ──→ fallback ha WS megszakad           │
└──────────────────────────────────────────────────────────┘
```

### Kulcs változások

| Komponens | Régi | Új |
|-----------|------|----|
| Árfolyam szinkron | FTP + pk file + polling | DB write + WS push |
| Pénztáros törzsadat | FTP + Firebird replikáció | Közös Neon tábla |
| Készlet összesítő | pk file begyűjtés (737 byte) | SQL VIEW/materialized view |
| Fiók közötti kommunikáció | FTP szerver | Nincs szükség rá (közös DB) |
| Outbox/Inbox pattern | Szükséges (elosztott DB) | **Deprecated** (1 DB) |

## 5. Implementáció Terv

### Fázis 1: FtpSyncService deprecation (kis kockázat)
- `@Deprecated` annotáció a `FtpSyncService`-re
- `SyncService.syncRatesDown()` → egyszerű DB query-re cserélés
- `SyncService.syncTransactionsUp()` → felesleges (közös DB), noop-ra
- `SyncController` endpointok megtartása API kompatibilitásra, de belülről egyszerűsítés

### Fázis 2: WebSocket broadcast bővítés (közepes kockázat)
- `RatePublishService` már broadcast-ol `/topic/rates`-re → **megvan**
- Új topicok: `/topic/workers`, `/topic/branches`, `/topic/currencies`
- Electron kliens subscriber bővítés

### Fázis 3: Outbox leegyszerűsítés (kis kockázat)
- `OutboxSyncWorkerService` → csak audit-log célra marad (opcionális)
- `SyncOutboxEvent`/`SyncInboxEvent` → soft-deprecate, ne töröljük a táblákat
- A scheduled polling (`@Scheduled fixedDelay=5000`) kikapcsolható

### Fázis 4: InventorySummary real-time (közepes kockázat)
- PostgreSQL materialized view VAGY trigger-alapú frissítés
- `/api/v1/inventory/summary?branchId=X` → real-time készlet
- WebSocket push: `/topic/inventory/{branchId}`

## 6. Elfogadási Kritériumok

1. ✅ Árfolyam módosítás < 1 sec-en belül látható minden Electron kliensen
2. ✅ Pénztáros CRUD azonnal érvényes minden branch-ben
3. ✅ Nincs FTP/file-alapú szinkronizáció futás a rendszerben
4. ✅ Készlet összesítő real-time (< 5 sec késleltetés)
5. ✅ Nincs adatvesztés a régi Outbox event-ekből (soft-deprecate, nem törlés)
6. ✅ WebSocket reconnect/fallback működik (REST polling backup)

## 7. Kockázatok

| Kockázat | Hatás | Mitigáció |
|----------|-------|-----------|
| Neon cold start latency | Első query lassabb | Connection pooling (HikariCP max=40) |
| WebSocket elvesztés | Kliens nem kap frissítést | REST polling fallback (30s) |
| Neon free tier limit | Compute timeout 5 min inaktivitás után | Scale to paid plan ha éles |
| Legacy kliens kompatibilitás | Régi Delphi kliensek FTP-t várnak | Bridge endpoint megtartás, fokozatos leválasztás |

## 8. Nem szükséges módosítások

A következő entity-k és service-ek **már helyesen működnek** Neon-nal:
- `ExchangeRate` (branch-specifikus vagy globális, multi-tenant)
- `Worker` (company_id szintű multi-tenant)
- `Branch` (UUID PK, company kapcsolat)
- `Currency` (globális, 27 valuta)
- `ExchangeRateMaster` (központi árfolyam sablon)
- `RatePublishService` (WebSocket broadcast)

## 9. Javasolt Prioritás

1. **Most:** Fázis 1 (FTP deprecation) — 2-3 óra munka
2. **Következő sprint:** Fázis 2 (WS bővítés) — 4-6 óra
3. **Utána:** Fázis 3+4 (Outbox cleanup + Inventory) — 6-8 óra

**Teljes becsült ráfordítás:** ~15 óra (3-4 nap)

---

> **Döntés szükséges:** Zoltán, elfogadod ezt a tervet? Indítsam a Fázis 1-et?
