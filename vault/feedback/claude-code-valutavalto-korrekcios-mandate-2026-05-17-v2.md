# Claude Code korrekciós mandate v2 — Valutaváltó program (EXZ-tanulságok alapján)

**Készítette:** Perplexity Computer (Kósa Zoltán kérésére)
**Készült:** 2026-05-17
**Forrás:** Az "EXZ Codex működési korrekciós dokumentum (2026-05-17)" elvi felépítésének és módszertani gondolatainak átültetése a Valutaváltó programra.
**Cél:** A Claude Code Valutaváltóhoz írt módszertanának azon hiányosságainak pótlása, amelyek az EXZ-korrekciónál már explicit módon megfogalmazódtak, de a Valutaváltó-kontextusban még nincsenek lefedve.
**Felhasználás:** A 2026-05-17-i első korrekciós mandate (`claude-code-korrekcios-mandate-2026-05-17.md`) **kiegészítése**, NEM helyettesítése. Ahol ütközés lenne, az ELVI-erősebb-mint-MÓD logika érvényes: a `valutavalto-program-mukodes-leiras-2026-05-16.md` (a Valutaváltó "ELVI" megfelelője) **mindig erősebb**, mint a Claude Code önleírása.

---

## 0. Mit hozott az EXZ-doksi olvasata

Az EXZ Codex korrekciós dokumentum a Valutaváltó-projekten kívülről érkezett, de **ugyanazt az alapproblémát** írja le, amit a Valutaváltó mandate v1 is megfogalmazott — csak **strukturáltabban, élesebben, és új technikai eszközöket is javasol**:

> "A mérnöki módszertan (CI, lint, build, smoke, AI review) önmagában nem garantálja az üzleti / jogi / számviteli helyességet. Az AI ügynök zöld CI-vel be tud mergelni olyan változást, amely **mérnökileg helyes, de üzletileg sérelmes**."

Az EXZ-doksi 7 módszertani innovációja a Valutaváltóra:

1. **ELVI-MÓD szétválasztás** formálisan: a VV-ELVI mindig erősebb.
2. **Különbözeti audit státusz-rendszer** (OK / RÉSZBEN / HIÁNY / ELTÉRÉS) minden ELVI-pontra.
3. **ELVI-compliance gate** mint új, kötelező PR-kapu, checklist-tel.
4. **VV-ELVI tükör memóriafájl** (`vault/elvi/vv-elvi-mirror.md`).
5. **Capability map** (`docs/CAPABILITIES.md`) — IMPLEMENTED/PARTIAL/MISSING/BLOCKED státusszal.
6. **"Üzleti review" mint a kódreview párja** — `business-review-required` címke + üzleti felelős "approve".
7. **Tiltott minták kodifikálása** debt-scan szabályként, blokkoló CI lépésként.

---

## 1. ELVI-MÓD formalizálás

### 1.1 A doksi-páros nevesítése

| Dokumentum | Szerep | Erősség |
|---|---|---|
| `valutavalto-program-mukodes-leiras-2026-05-16.md` | **VV-ELVI** | **Erősebb** |
| `claude-code-mukodes-leiras-2026-05-16.md` | **VV-MÓD** | Gyengébb |
| `claude-code-korrekcios-mandate-2026-05-17.md` | **VV-KORR-v1** | VV-MÓD-ot kiegészíti |
| Jelen dokumentum | **VV-KORR-v2** | VV-MÓD-ot és VV-KORR-v1-et kiegészíti |

**Konfliktusoldás:** Ha a Claude Code bármely heurisztikája ütközik a VV-ELVI-vel → **jelzés + nem végrehajt**, felhasználói döntés.

### 1.2 Új session-start kötelező olvasmány (6 elem)

```markdown
## SESSION-START KÖTELEZŐ OLVASMÁNY (sorrendben, ELVI elsőbbség)

1. vault/elvi/vv-elvi-mirror.md                 ← VV-ELVI rövid tükre
2. vault/feedback/_active_mandates.md           ← aktív mandate-index
3. vault/feedback/claude-code-korrekcios-mandate-2026-05-17.md       ← v1
4. vault/feedback/claude-code-valutavalto-korrekcios-mandate-2026-05-17-v2.md  ← v2 (jelen)
5. CLAUDE.md                                     ← VV-MÓD
6. ~/.claude/projects/<project-hash>/memory/MEMORY.md       ← auto-memory
```

---

## 2. Különbözeti audit — VV-ELVI vs. VV-MÓD

| VV-ELVI fejezet | Tartalom | Státusz | Korrekció |
|---|---|---|---|
| 1. Áttekintés | Multi-tenant, 66 iroda, 28 valuta, offline, AML | RÉSZBEN | v1-DONE; v2-NEW: 4-kontextus diszkriminátor |
| 2.3 4 kliens-stack | Penztar/Központi/RFM/Eltávolító | HIÁNY | v2-NEW: appMode PR-leírás kötelező |
| 2.4 Production infra | Hetzner/Scaleway/Cloudflare/B2/Tailscale/Azure HSM | OK | — |
| 3. Multi-tenant | Company/Branch/Worker, JWT, BCrypt, Idempotency | RÉSZBEN | v1-DONE; v2-NEW: cross-tenant test mandate |
| 4. Domain modell | 13 entitás | RÉSZBEN | v2-NEW: kanonikus enum-ok |
| 5. Pénztár vétel/eladás/konverzió | 100k / 300k küszöbök | RÉSZBEN | v1-DONE; v2-NEW: ELVI-compliance gate |
| 5.6 Sztornó | 5 üzleti szabály | RÉSZBEN | v1-DONE; v2-NEW: állapotgép tiltás |
| 5.7 Napzárás | Címletezés, reconciliation | RÉSZBEN | v1-DONE; v2-NEW: kettős dimenzió invariáns |
| 5.8 Offline/Sync | Local-first, outbox, heartbeat | RÉSZBEN | v1-DONE; v2-NEW: debt-scan |
| 6. Központi modul | Lát, összegez, ellenőriz | HIÁNY | **v2-NEW: "központ aggregál, nem vezérel"** |
| 7. RFM (árfolyamkészítő) | 28 valuta, A-I, lock-out | HIÁNY | **v2-NEW: árfolyam-állapotgép + optimistic lock** |
| 9. AML / NGM / MNB / NAV | 4 szabályozási vonal | RÉSZBEN | v1-DONE; v2-NEW: compliance validated-by |
| 10. Security | Rate limit, JWT, SQL/log injection | OK | — |
| 11. Telepítő-stack | 4-way version sync | RÉSZBEN | v1-DONE; v2-NEW: 4-way drift tiltó CI step |
| 12. HA + failover | Hetzner→Scaleway | OK | — |
| 13. Code signing | DigiCert EV CS | RÉSZBEN | v1-DONE |
| 14. Magyar specifikumok | HUF kerekítés, sorszámozás | RÉSZBEN | v1-DONE; v2-NEW: magyar domain enum |
| 16. Adatintegritás | 10 invariáns | RÉSZBEN | v1-DONE; v2-NEW: capability map |

---

## 3. ELVI-compliance gate

**Új, kötelező PR-kapu**, ellenőrző lista alapú, minden PR leírásban:

```text
ELVI-compliance gate (VV-ELVI hivatkozással)

[ ] Érintett kliens: penztar-cashier / kozponti-treasury / rfm-rate-maker / admin-web / backend / multi
[ ] Érintett kontextus: vetel / eladas / konverzio / sztorno / napzaras / arfolyam / hq-monitoring / admin / cross
[ ] Local-first: működik offline a pénztár-kliensben? (igen / N/A)
[ ] Outbox / sync: idempotens? replay tesztelt?  (igen / N/A)
[ ] Multi-tenant: companyId szűrés minden új repo-n?  (igen / N/A)
[ ] Jogosultság: @PreAuthorize + frontend visibility + roles-matrix.yaml egyeznek?  (igen / N/A)
[ ] Audit: az érintett mutáció audit log-ot ír?  (igen / N/A)
[ ] Pénztár/készlet: készlet = SUM(tranzakciók) invariáns sértetlen?  (igen / N/A)
[ ] Bizonylat: V-prefix, monoton iroda-szintű, NO physical delete?  (igen / N/A)
[ ] AML / Pmt.: 100k/300k, PEP, sanction, SAR backend-szinten?  (igen / N/A)
[ ] Árfolyam-validity: Rate.validTo > now() tranzakció elején?  (igen / N/A)
[ ] HUF kerekítés: roundHuf minden HUF display/print előtt?  (igen / N/A)
[ ] Szabályozási kimenetek (MNB/NGM/NAV): határidő-monitor érintetlen?  (igen / N/A)
[ ] Code-signing: signed-only mandate betartva?  (igen / N/A)
[ ] Production-first: NEM vezet be lokál-only seed-adatot?  (igen / N/A)
[ ] VV-ELVI fejezet hivatkozás: melyik VV-ELVI pontot teljesíti vagy érinti
[ ] Üzleti review szükséges? (címke: business-review-required ha igen)
```

PR akkor mergelhető, ha minden sor "igen" vagy explicit indokolt "N/A". A `.github/PULL_REQUEST_TEMPLATE.md` ezt kötelezően tartalmazza.

---

## 4. VV-ELVI tükör memóriafájl

`vault/elvi/vv-elvi-mirror.md` — a VV-ELVI rövid, kereshető tükre, session-start kötelező olvasmány. **Csak felhasználói approve-pal frissíthető.**

---

## 5. Új kanonikus enumok és állapotgépek

### 5.1 `TransactionStatus` enum

```java
public enum TransactionStatus {
    DRAFT,         // local SQLite-ban, még nem outbox-szal
    PENDING_SYNC,  // outbox-ban, backend még nem visszaigazolta
    COMMITTED,     // backend rögzítette, audit-log + WS broadcast
    REVERSED,      // sztornózva (ugyanazon a napon)
    VOIDED         // utólag érvénytelenített (manager override)
}
```

### 5.2 `RateStatus` enum

```java
public enum RateStatus {
    DRAFT,        // RFM operátor szerkeszti
    REVIEW,       // spread-kapu (>5% diff) jóváhagyás vár
    PUBLISHED,    // élő, pénztár-kliensek használják
    EXPIRED,      // validTo lejárt
    SUPERSEDED    // új rate publish, régi audit-archív
}
```

### 5.3 Állapotgép-megkerülés tilalom

**Közvetlen `UPDATE ... SET status = ...` TILOS.** Minden átmenet:

```java
TransactionStateMachine.transition(transaction, TransactionStatus.COMMITTED);
RateStateMachine.transition(rate, RateStatus.PUBLISHED);
```

Az állapotgép-függvény kötelezően: validál + audit-log + sync outbox + WebSocket broadcast.

---

## 6. Tiltott minták kodifikálása — debt-scan workflow

`.github/workflows/business-invariant-guard.yml`. 15 blokkoló minta, lásd a workflow file-t.

**Allowlist a #1 mintához (cash counter mező):** materialized view / aggregátum entitások (`*Summary`, `*View`, `*Aggregate`, `*MaterializedView` végződésű osztályok) **megengedettek**, mert ezek **denormalizált aggregátum-cache** (NEM source-of-truth). A `készlet = SUM(tranzakciók)` invariáns érvényben marad: a materialized view periódikusan refresh-elődik a `transaction` táblából, NEM külön mutáció. Tipikus példa: `InventorySummary.currentStock`.

**Tilos a Claude Code-nak kikapcsolni / kommentelni / if:false-ra állítani.**

---

## 7. Capability map — `docs/CAPABILITIES.md`

A VV-ELVI minden elvárását kódbeli helyre, tesztre és státuszra (IMPLEMENTED/PARTIAL/MISSING/BLOCKED) képezi le. Minden capability-érintő PR frissíti.

---

## 8. Üzleti review

### 8.1 `business-review-required` címke
Kötelező kihelyezés ha érintett: AML, bizonylat-sorszám, HUF kerekítés, sztornó, napzárás, készlet, RFM, multi-tenant, MNB/NGM/NAV, code-signing.

### 8.2 Üzleti felelős approve
Kósa Zoltán (CEO) vagy delegált. **AI bot review NEM helyettesíti.**

### 8.3 Branch protection
`main` rule: "Required reviews: 1 from CODEOWNERS + 1 from business owner if `business-review-required` label present" (user-konfigurálandó UI-on).

---

## 9. AI review határainak explicit kimondása

Záró jelentés kötelező mondata:

> "**FIGYELEM:** AI review (Sourcery + Copilot + Codex + CodeQL) zöld = technikai minőség OK. **Üzleti helyességet NEM garantál.** Ha `business-review-required` címkével van jelölve, üzleti felelős (Kósa Zoltán) approve-ja szükséges merge előtt."

---

## 10. "Product-ready" pontos jelentése

**Mérnöki Product Ready** (CI zöld) ≠ **Üzleti Product Ready** (VV-ELVI minden capability IMPLEMENTED). Csak akkor "kész", ha **mindkettő** zöld.

Státusz-formátum: `MERNOKILEG-KESZ-DE-UZLETILEG-NYITOTT` ha capability map PARTIAL/MISSING.

---

## 11. Session-indítási + PR-előtti checklist (v2 összevont)

### Session-start (8 lépés)
1. vv-elvi-mirror.md
2. _active_mandates.md
3. v1 mandate
4. v2 mandate (jelen)
5. CLAUDE.md
6. docs/CAPABILITIES.md
7. MEMORY.md
8. production health check (`curl bootstrap-status`)

### PR-előtti (10 lépés)
1. Lokál kapuk zöld (lint, typecheck, test, build)
2. 9-fázisú + 2.5 + 8.5 lefutott
3. ELVI-compliance gate minden sor "igen" vagy indokolt "N/A"
4. `business-invariant-guard.yml` zöld
5. AI review feldolgozva (P0/P1/P2 fixelve)
6. `docs/CAPABILITIES.md` frissítve
7. `business-review-required` címke ha érintett
8. Üzleti approve ha címke
9. Záró jelentés AI-review-nem-garantál figyelmeztetés ha érintett
10. Branch delete + state.yaml frissítés

---

## 12. Új mandate-ek (E.1–E.10)

| # | Mandate | Forrás | Hatály | P-szint |
|---|---|---|---|---|
| E.1 | ELVI-MÓD szétválasztás | v2 1. | always | P0 |
| E.2 | ELVI-compliance gate | v2 3. | always | P0 |
| E.3 | VV-ELVI tükör session-start | v2 4. | always | P0 |
| E.4 | Kanonikus TransactionStatus + RateStatus | v2 5.1, 5.2 | always | P0 |
| E.5 | Állapotgép-megkerülés tilalom | v2 5.3 | always | P0 |
| E.6 | Tiltott minták debt-scan | v2 6. | always | P0 |
| E.7 | Capability map fenntartás | v2 7. | always | P1 |
| E.8 | business-review-required + üzleti approve | v2 8. | always | P0 |
| E.9 | "AI review NEM garantál üzleti helyességet" | v2 9. | always | P1 |
| E.10 | Mérnöki vs üzleti product-ready | v2 10. | always | P1 |

---

## 13. Konkrét műveletek (sorrendben — már elvégzett a jelen PR-ben)

1. ✅ Jelen fájl mentve a `vault/feedback/`-be
2. ✅ `vault/elvi/` mappa létrehozva
3. ✅ `vv-elvi-mirror.md` kitöltve (4. szakasz Javasolt tartalom alapján)
4. ✅ `_active_mandates.md` index frissítve (E.1–E.10 új sorok)
5. ✅ `CLAUDE.md` 6-elemű session-start lista
6. ✅ `docs/CAPABILITIES.md` 7.1 táblázat-minta szerint
7. ✅ `.github/workflows/business-invariant-guard.yml` 6.2 YAML váz
8. ⏳ Branch protection rule **user-action** (UI-on, NEM én)
9. ⏳ Próba-PR **user-action** (a 13. szakasz 9. pontja kéri, validation step)

---

## 14. 4 kontrollkérdés válasz (jelen PR session-jegyzete tartalmazza)

K1, K2, K3, K4 válaszok: lásd `vault/sessions/2026-05-17-v2-mandate-load.md`

---

## 15. KPI-k (v2, 60 napra)

7. 0 db merge ELVI-compliance gate "N/A" hamis indokkal
8. 100% `business-review-required` címke a 8.1 listán szereplő területeken
9. 0 db merge üzleti approve nélkül ha címke jelen
10. `business-invariant-guard.yml` 100% blokkolás minden szándékos tiltott minta esetén
11. `docs/CAPABILITIES.md` frissítési arány capability-érintő PR-eken: 100%
12. VV-ELVI tükör soha NEM frissül felhasználói approve nélkül

---

**Vége.**
