# VV-ELVI tükör (rövid, kanonikus)

> **Session-start kötelező olvasmány #1.** Ezt a rövid, kereshető tükröt **legelőször** olvasd be minden új session-kezdéskor.
> **Forrás:** `valutavalto-program-mukodes-leiras-2026-05-16.md` (VV-ELVI, "Erősebb" kanonikus dokumentum)
> **Utolsó tükrözés:** 2026-05-17
> **Frissítési szabály:** kizárólag a felhasználó (Kósa Zoltán) explicit "approve"-jára. A Claude Code **egyedül NEM frissítheti**.

---

## Kontextusok (4)

- **CASHIER** — pénztár, front-office, local-first SQLite, offline-képes
- **TREASURY_HQ** — központi irányítóközpont, 100% backend-szolgáltatott, WebSocket
- **RFM** — árfolyamkészítő (Rate Forex Manager), optimistic locking, 1 operátor egyszerre
- **ADMIN** — webes vezetői dashboard, NEM pénztáros

## Multi-tenant invariáns

- `Company → Branch → Worker → Role+Permission`
- `companyId` minden repository-n kötelező szűrés
- `SecurityContextHolder`-ből, **NEM** kliens paraméterből
- `companyId` típusa: **`UUID`** (NEM `Long`)

## AML / Pmt. küszöbök (backend-szinten enforced)

| Küszöb | Akció |
|---|---|
| **100 000 HUF** | identifikáció (név + szül.hely + szül.idő + anyja neve + okmány) |
| **300 000 HUF** | + PEP nyilatkozat + saját-név (own benefit / third-party) |
| napi aggregáció 1 ügyfél / 1 nap > 100k | visszamenőleges identification |
| sanction-list (EU/OFAC/ENSZ) | valós idejű revalidáció commit előtt |
| SAR auto-flag | cyclic customer / sanction hit → manager review |

A backend `AmlService.java`-ban a küszöbök jelenleg **konstansok** (`SIMPLIFIED_IDENTIFICATION_LIMIT = 100000`, `IDENTIFICATION_LIMIT = 300000`). A jövőbeli `@Value` migráció külön sprint.

## Pénzügyi invariánsok (7 db)

1. **`készlet = SUM(tranzakciók)`** — soha külön counter (`cashCounter`, `inventoryCount`, `currentStock` mező TILOS)
2. **Idempotency-Key** kötelező minden write-on (kivéve whitelist: `/auth/`, `/public/`, `/health/`, `/actuator/`, OAuth callback, `/diagnostics/`, `/ws/`, swagger)
3. **Bizonylat-sorszám:** `V<3-jegyű iroda><6-jegyű seq>`, atomic, monoton, no-skip, iroda-scope
4. **HUF kerekítés (`roundHuf`)** — minden display/print/bizonylat előtt, magyar 5 Ft-os egység
5. **Árfolyam-validity** — `Rate.validTo > now()` tranzakció **belépésekor**
6. **`@Transactional`** minden write servicen
7. **Készlet-korrekció** — csak MAIN_TREASURY + audit-log + indoklás kötelező

## Sztornó szabályok (mind az 5 invariáns)

1. **Csak ugyanazon a napon** — `transaction.createdAt::date = today()`
2. **Csak ugyanazzal a worker-rel** — vagy SUPERVISOR_PIN override
3. **Csak napzárás ELŐTT** — `dailyClosing.status != 'CLOSED'`
4. **Bizonylat-sorszám marad** — audit trail integritás (NEM törlés, csak status = REVERSED)
5. **Készlet atomic visszaáll** — `SUM(tranzakciók)` invariáns alapján

## Központi modul elve

- **LÁT, ÖSSZEGEZ, ELLENŐRIZ, POLICY-T KEZEL, PARANCSOT KÜLD**
- **NEM** vezérli a fióki tranzakciókat közvetlenül
- Készlet a központban = **aggregáció**, NEM forrás
- **TILOS:** "központi készletből vonok le fióki eladást"
- `lastSyncedAt` mező minden aggregált nézeten kötelező
- Aggregált nézet API-ja **read-only** (csak `@GetMapping`, NEM `@PostMapping`/`@PutMapping`/`@DeleteMapping`)

## RFM (árfolyamkészítő)

- 28 valuta, A-I oszlopok (`Currency`, MNB, spread%, vételi, eladási, kereszt, validFrom, validTo)
- Spread default 1.5%, állítható
- **Optimistic locking + version check** (1 RFM operátor egyszerre)
- **Spread-kapu:** max 5% diff előző naphoz → különben jóváhagyás
- Publish → backend WebSocket → minden pénztár refresh
- Minden korábbi rate-set **immutable**, audit-log

## Local-first + offline + outbox

- **Local SQLite write FIRST**, csak utána outbox
- **Outbox 3× retry** (ESET TLS proxy)
- **Heartbeat 60s**, Zod-validált config
- **Last-write-wins** CSAK ha timestamp-ek 5s-en belül; egyébként **manual review queue**

## Szabályozási határidők

| Jelentés | Határidő | Hibakor |
|---|---|---|
| MNB napi árfolyam | minden munkanap **14:30** | P0 escalation, manuális |
| NGM havi | tárgyhó+15. munkanap | P1, batch retry |
| NAV NPG real-time | folyamatos | P0, fallback off-line |
| SAR | 5 munkanap | P0, manager review |

## Code-signing állapot (2026-05-17)

- DigiCert EV CS rendelve (Order #1524362467, vendor CS-BNYK)
- Azure Key Vault Premium HSM ($55/hó)
- Phone verification scheduled **2026-05-18 16:30 CEST**
- Cert kiadás várható: 2026-05-19 — 2026-05-21
- **Addig:** unsigned bináris CSAK `internal-test` channel, NEM kollégának (SmartScreen + nem-informatikus user mandate)

## Magyar specifikumok (kanonikus enum kódban)

- `vétel`, `eladás`, `sztornó`, `napzárás`, `címletezés`, `árfolyam`
- `iroda`, `ügyfél`, `dolgozó`, `pénztáros`, `értéktáros`, `főértéktáros`
- `főpénztár`, `irányítóközpont`, `bizonylat`, `címlet`, `készlet`

## Production-first elv

- Frontend + Electron → `excvaluta.com` (production API URL)
- Lokál DB seed **TILOS**, ami nincs production-ön
- Flyway migráció a séma forrása
- Manuális `INSERT psql` csak fejlesztő lokál DB-n, utána ROLLBACK / DROP
- Lokál Postgres CSAK Hetzner-replikából (anonimizált dump)

---

**Vége.** Ezt a tükröt session-kezdéskor olvasd be. Ha bármi ütközik a VV-ELVI tükör tartalmával vs. a kódban talált tényekkel, a **kód** erősebb — de jelezni kell a felhasználónak.
